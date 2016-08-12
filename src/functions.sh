#!/bin/bash

# shared functions library

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

function pause(){
    read -p "$*"
}


function check_iso_offline_setting() {
# check if offline setting is present in settings file
check=$(cat ~/kube-solo/settings/k8solo-01.toml | grep "offline" )

if [[ "${check}" = "" ]]
then
    echo '   offline = "true"' >> ~/kube-solo/settings/k8solo-01.toml
fi
}

function check_corectld_server() {
# check corectld server
#
CHECK_SERVER_STATUS=$(~/bin/corectld status 2>&1 | grep "Uptime:")
if [[ "$CHECK_SERVER_STATUS" == "" ]]; then
    open -a /Applications/corectl.app
fi

if [[ "$CHECK_SERVER_STATUS" == "" ]]; then
    sleep 3
fi
}


function check_internet_from_vm(){
#
status=$(~/bin/corectl ssh k8solo-01 "curl -s -I https://coreos.com 2>/dev/null | head -n 1 | cut -d' ' -f2")

if [[ $(echo "${status//[$'\t\r\n ']}") = "200" ]]; then
    echo "Yes, internet is available ..."
    echo " "
else
    echo "There is no internet access from the VM !!!"
    echo " "
    echo "Please check your Mac's firewall, network setup, stop dnsmasq (if you have installed such) "
    echo "and try to fix the problem !!!"
    echo " "
    echo "k8solo-01 VM is still running, so you can troubleshoot the network problem "
    echo " "
    echo "When you done fixing it, do via menu 'Halt' and 'Up' and the installation will start again ... "
    echo " "
    pause 'Press [Enter] key to abort installation ...'
    # create file 'unfinished_setup' so on next boot fresh install gets triggered again !!!
    touch ~/kube-solo/logs/unfinished_setup > /dev/null 2>&1
    exit 1
fi
}


function sshkey(){
# add ssh key to *.toml files
echo " "
echo "Reading ssh key from $HOME/.ssh/id_rsa.pub  "
file="$HOME/.ssh/id_rsa.pub"

while [ ! -f "$file" ]
do
    echo " "
    echo "$file not found."
    echo "please run 'ssh-keygen -t rsa' before you continue !!!"
    pause 'Press [Enter] key to continue...'
done

echo " "
echo "$file found, updating configuration files ..."
echo "   sshkey = '$(cat $HOME/.ssh/id_rsa.pub)'" >> ~/kube-solo/settings/k8solo-01.toml
#
}

function release_channel(){
# Set release channel
LOOP=1
while [ $LOOP -gt 0 ]
do
    VALID_MAIN=0
    echo " "
    echo "Set CoreOS Release Channel:"
    echo " 1)  Alpha (may not always function properly)"
    echo " 2)  Beta "
    echo " 3)  Stable (recommended)"
    echo " "
    echo -n "Select an option: "

    read RESPONSE
    XX=${RESPONSE:=Y}

    if [ $RESPONSE = 1 ]
    then
        VALID_MAIN=1
        /usr/bin/sed -i "" 's/channel = "stable"/channel = "alpha"/g' ~/kube-solo/settings/*.toml
        /usr/bin/sed -i "" 's/channel = "beta"/channel = "alpha"/g' ~/kube-solo/settings/*.toml
        channel="Alpha"
        LOOP=0
    fi

    if [ $RESPONSE = 2 ]
    then
        VALID_MAIN=1
        /usr/bin/sed -i "" 's/channel = "stable"/channel = "beta"/g' ~/kube-solo/settings/*.toml
        /usr/bin/sed -i "" 's/channel = "alpha"/channel = "beta"/g' ~/kube-solo/settings/*.toml
        channel="Beta"
        LOOP=0
    fi

    if [ $RESPONSE = 3 ]
    then
        VALID_MAIN=1
        /usr/bin/sed -i "" 's/channel = "beta"/channel = "stable"/g' ~/kube-solo/settings/*.toml
        /usr/bin/sed -i "" 's/channel = "alpha"/channel = "stable"/g' ~/kube-solo/settings/*.toml
        channel="Stable"
        LOOP=0
    fi

    if [ $VALID_MAIN != 1 ]
    then
        continue
    fi
done
}


function create_data_disk() {
# create persistent disk
cd ~/kube-solo/
echo "  "
echo "Please type Data disk size in GBs followed by [ENTER]:"
echo -n "[default is 30]: "
read disk_size
if [ -z "$disk_size" ]
then
    echo " "
    echo "Creating 30GB sparse disk (QCow2)..."
    ~/bin/qcow-tool create --size=30GiB data.img
    echo "-"
    echo "Created 30GB Data disk"
    # create file 'unfinished_setup' so on next boot fresh install gets triggered again !!!
    touch ~/kube-solo/logs/unfinished_setup > /dev/null 2>&1
else
    echo " "
    echo "Creating "$disk_size"GB sparse disk (QCow2)..."
    ~/bin/qcow-tool create --size="$disk_size"GiB data.img
    echo "-"
    echo "Created $disk_sizeGB Data disk"
    # create file 'unfinished_setup' so on next boot fresh install gets triggered again !!!
    touch ~/kube-solo/logs/unfinished_setup > /dev/null 2>&1
fi
#
}


function change_vm_ram() {
echo " "
echo " "
echo "Please type VM's RAM size in GBs followed by [ENTER]:"
echo -n "[default is 3]: "
read ram_size
if [ -z "$ram_size" ]
then
    ram_size=3
    echo " "
    echo "Setting VM's RAM to 3GB..."
    ((new_ram_size=$ram_size*1024))
    /usr/bin/sed -i "" 's/\(memory = \)\(.*\)/\1'$new_ram_size'/g' ~/kube-solo/settings/k8solo-01.toml
    echo " "
else
    echo " "
    echo "Changing VM's RAM to "$ram_size"GB..."
    ((new_ram_size=$ram_size*1024))
    /usr/bin/sed -i "" 's/\(memory = \)\(.*\)/\1'$new_ram_size'/g' ~/kube-solo/settings/k8solo-01.toml
    echo " "
fi

}


function start_vm() {

# Start VM
cd ~/kube-solo
echo " "
echo "Starting VM ..."
echo " "
#
~/bin/corectl load settings/k8solo-01.toml 2>&1 | tee ~/kube-solo/logs/vm_up.log
CHECK_VM_STATUS=$(cat ~/kube-solo/logs/vm_up.log | grep "started")
#
if [[ "$CHECK_VM_STATUS" == "" ]]; then
    echo " "
    echo "VM has not booted, please check '~/kube-solo/logs/vm_up.log' and report the problem !!! "
    echo " "
    # create file 'unfinished_setup' so on next boot fresh install gets triggered again !!!
    touch ~/kube-solo/logs/unfinished_setup > /dev/null 2>&1
    pause 'Press [Enter] key to continue...'
    exit 0
else
    echo "VM successfully started !!!" >> ~/kube-solo/logs/vm_up.log
fi
# save VM's IP
~/bin/corectl q -i k8solo-01 | tr -d "\n" > ~/kube-solo/.env/ip_address
#

}


function download_docker_client() {

# download docker client
# check docker server version
DOCKER_VERSION=$(~/bin/corectl ssh k8solo-01 'docker version' | grep 'Version:' | awk '{print $2}' | tr -d '\r' | /usr/bin/sed -n 2p )
# check if the binary exists
if [ ! -f ~/kube-solo/bin/docker ]; then
    cd ~/kube-solo/bin
    echo " "
    echo "Downloading docker $DOCKER_VERSION client for macOS"
    curl -o ~/kube-solo/bin/docker https://get.docker.com/builds/Darwin/x86_64/docker-$DOCKER_VERSION
    # Make it executable
    chmod +x ~/kube-solo/bin/docker
else
    # docker client version
    INSTALLED_VERSION=$(~/kube-solo/bin/docker version | grep 'Version:' | awk '{print $2}' | tr -d '\r' | head -1 )
    MATCH=$(echo "${INSTALLED_VERSION}" | grep -c "${DOCKER_VERSION}")
    if [ $MATCH -eq 0 ]; then
        # the version is different
        cd ~/kube-solo/bin
        echo " "
        echo "Downloading docker $DOCKER_VERSION client for macOS"
        curl -o ~/kube-solo/bin/docker https://get.docker.com/builds/Darwin/x86_64/docker-$DOCKER_VERSION
        # Make it executable
        chmod +x ~/kube-solo/bin/docker
    else
        echo " "
        echo "macOS docker client is up to date with VM's version ..."
    fi
fi
}


function download_osx_clients() {

# get lastest macOS helm cli version
echo " "
echo "Checking for latest Helm version..."
cd ~/kube-solo/tmp
LATEST_HELM=$(curl -s https://api.github.com/repos/kubernetes/helm/releases/latest | grep "tag_name" | awk '{print $2}' | sed -e 's/"\(.*\)"./\1/')

# check if the binary exists
if [ ! -f ~/kube-solo/bin/helm ]; then
    INSTALLED_HELM=v0.0.0
else
    INSTALLED_HELM=$(~/kube-solo/bin/helm version)
fi

#
MATCH=$(echo "${INSTALLED_HELM}" | grep -c "${LATEST_HELM}")
if [ $MATCH -ne 0 ]; then
    echo " "
    echo "Helm is up to date !!!"
else
    echo " "
    echo "Downloading latest ${LATEST_HELM} of helm cli for macOS"
    curl -k -L https://github.com/kubernetes/helm/releases/download/$LATEST_HELM/helm-$LATEST_HELM-darwin-amd64.tar > helm.tar
    tar xvf helm.tar -C ~/kube-solo/tmp --strip=1 darwin-amd64/helm > /dev/null 2>&1
    chmod +x helm
    mv -f helm ~/kube-solo/bin/helm
    rm -f helm.tar
    echo " "
    echo "Installed latest ${LATEST_HELM} of helm cli to ~/kube-solo/bin ..."
fi
#

# get lastest macOS helmc cli version
cd ~/kube-solo/bin
echo " "
echo "Downloading latest version of helmc cli for macOS"
curl -o helmc https://storage.googleapis.com/helm-classic/helmc-latest-darwin-amd64
chmod +x helmc
echo " "
echo "Installed latest helmc cli to ~/kube-solo/bin ..."
#

# get lastest macOS deis cli version
cd ~/kube-solo/bin
echo " "
echo "Downloading latest version of Deis Workflow 'deis' cli for macOS"
curl -o deis https://storage.googleapis.com/workflow-cli/deis-latest-darwin-amd64
chmod +x deis
echo " "
echo "Installed latest deis cli to ~/kube-solo/bin ..."
#
}


function download_k8s_files() {
#
cd ~/kube-solo/tmp

echo " "
echo "Checking for latest stable Kubernetes version..."
echo " "

# get latest stable k8s version
 function get_latest_version_number {
    local -r latest_url="https://storage.googleapis.com/kubernetes-release/release/stable.txt"
    curl -Ss ${latest_url}
}
K8S_VERSION=$(get_latest_version_number)

# we check the version of installed k8s cluster
INSTALLED_VERSION=$(~/kube-solo/bin/kubectl version | grep "Server Version:" | awk '{print $5}' | awk -v FS='(:"|",)' '{print $2}')
MATCH=$(echo "${INSTALLED_VERSION}" | grep -c "${K8S_VERSION}")
if [ $MATCH -ne 0 ]; then
    echo " "
    echo "You have already the latest stable ${K8S_VERSION} of Kubernetes installed !!!"
    pause 'Press [Enter] key to continue...'
    exit 1
fi

k8s_upgrade=1

# download latest version of kubectl for macOS
cd ~/kube-solo/tmp
echo "Downloading kubectl $K8S_VERSION for macOS"
curl -k -L https://storage.googleapis.com/kubernetes-release/release/$K8S_VERSION/bin/darwin/amd64/kubectl >  ~/kube-solo/kube/kubectl
chmod 755 ~/kube-solo/kube/kubectl
echo "kubectl was copied to ~/kube-solo/kube"
echo " "

# clean up tmp folder
rm -rf ~/kube-solo/tmp/*

# downloading latest version of k8s for CoreOS
echo "Downloading Kubernetes $K8S_VERSION"
bins=( kubectl kubelet kube-proxy kube-apiserver kube-scheduler kube-controller-manager )
for b in "${bins[@]}"; do
    curl -k -L https://storage.googleapis.com/kubernetes-release/release/$K8S_VERSION/bin/linux/amd64/$b > ~/kube-solo/tmp/$b
done
#
chmod 755 ~/kube-solo/tmp/*
#
curl -L https://storage.googleapis.com/kubernetes-release/easy-rsa/easy-rsa.tar.gz > ~/kube-solo/tmp/easy-rsa.tar.gz
#
tar czvf kube.tgz *
cp -f kube.tgz ~/kube-solo/kube/
# clean up tmp folder
rm -rf ~/kube-solo/tmp/*
echo " "

# install k8s files
install_k8s_files

}


function download_k8s_files_version() {
#
cd ~/kube-solo/tmp

# ask for k8s version
echo "You can install a particular version of Kubernetes you migh want to test..."
echo " "
echo "Bear in mind if the version you want is lower than the currently installed, "
echo "Kubernetes cluster migth not work, so you will need to destroy the cluster first "
echo "and boot VM again !!! "
echo " "
echo "Please type Kubernetes version you want to be installed e.g. v1.3.2 or v1.4.0-alpha.1"
echo " "
echo "Please type the word 'local' to use a local kubernetes.tar.gz file"
echo " "
echo "followed by [ENTER] to continue or press CMD + W to exit:"
read K8S_VERSION

if [[ $K8S_VERSION != "local" ]]; then
  url=https://github.com/kubernetes/kubernetes/releases/download/$K8S_VERSION/kubernetes.tar.gz

  if curl --output /dev/null --silent --head --fail "$url"; then
    echo "URL exists: $url" > /dev/null
  else
    echo "There is no such Kubernetes version to download !!!"
    echo "List of available Kubernetes versions:"
    curl -s https://api.github.com/repos/kubernetes/kubernetes/releases | grep "tag_name" | awk '{print $2}' | sed -e 's/"\(.*\)"./\1/' | sort -n
    pause 'Press [Enter] key to continue...'
    exit 1
  fi
  # we check the version of installed k8s cluster
  INSTALLED_VERSION=$(~/kube-solo/bin/kubectl version | grep "Server Version:" | awk '{print $5}' | awk -v FS='(:"|",)' '{print $2}')
  MATCH=$(echo "${INSTALLED_VERSION}" | grep -c "${K8S_VERSION}")
  if [ $MATCH -ne 0 ]; then
    echo " "
    echo "You have already the ${K8S_VERSION} of Kubernetes installed !!!"
    pause 'Press [Enter] key to continue...'
    exit
  fi
  # download required version of Kubernetes
  echo " "
  echo "Downloading Kubernetes $K8S_VERSION tar.gz from github ..."
  curl -k -L https://github.com/kubernetes/kubernetes/releases/download/$K8S_VERSION/kubernetes.tar.gz >  kubernetes.tar.gz
else
  if [ ! -f ~/kube-solo/tmp/kubernetes.tar.gz ]; then
    echo "Place Kubernetes file 'kubernetes.tar.gz' you want to be installed to ~/kube-solo/tmp/ "
    pause "Press [Enter] key to continue or press CMD + W to exit ..."
    if [ ! -f ~/kube-solo/tmp/kubernetes.tar.gz ]; then
      echo " "
      echo "There is no such Kubernetes file to install"
      pause 'Press [Enter] key to continue...'
      exit 1
    fi
    echo " "
    echo "Using locally installed file."
  fi
fi

k8s_upgrade=1

#
# extracting Kubernetes files
echo "Extracting Kubernetes $K8S_VERSION files ..."
tar xvf  kubernetes.tar.gz --strip=4 kubernetes/platforms/darwin/amd64/kubectl
mv -f kubectl ~/kube-solo/kube
chmod 755 ~/kube-solo/kube/kubectl
#
tar xvf kubernetes.tar.gz --strip=2 kubernetes/server/kubernetes-server-linux-amd64.tar.gz
bins=( kubectl kubelet kube-proxy kube-apiserver kube-scheduler kube-controller-manager )
for b in "${bins[@]}"; do
    tar xvf kubernetes-server-linux-amd64.tar.gz -C ~/kube-solo/tmp --strip=3 kubernetes/server/bin/$b
done
rm -f kubernetes.tar.gz
rm -f kubernetes-server-linux-amd64.tar.gz
#
curl -L https://storage.googleapis.com/kubernetes-release/easy-rsa/easy-rsa.tar.gz > easy-rsa.tar.gz
#
tar czvf kube.tgz *
mv -f kube.tgz ~/kube-solo/kube/
# clean up tmp folder
rm -rf ~/kube-solo/tmp/*
echo " "

# install k8s files
install_k8s_files

}


function install_k8s_files {
# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)

# get VM IP
vm_ip=$(~/bin/corectl q -i k8solo-01)

# check if file ~/kube-solo/kube/kube.tgz exists
if [ ! -f ~/kube-solo/kube/kube.tgz ]
then
    # copy k8s files
    cp -f "${res_folder}"/k8s/kubectl ~/kube-solo/kube
    chmod +x ~/kube-solo/kube/kubectl
    # linux binaries tar file
    cp -f "${res_folder}"/k8s/kube.tgz ~/kube-solo/kube
fi

# install k8s files on to VM
echo "Installing Kubernetes files on to VM..."
cd ~/kube-solo/kube
~/bin/corectl scp kube.tgz k8solo-01:/home/core/
echo "Files copied to VM..."
echo "Installing now ..."
~/bin/corectl ssh k8solo-01 'sudo /usr/bin/mkdir -p /data/opt/bin && sudo tar xzf /home/core/kube.tgz -C /data/opt/bin && sudo chmod 755 /data/opt/bin/*'
~/bin/corectl ssh k8solo-01 'sudo /usr/bin/mkdir -p /data/opt/tmp && sudo mv /data/opt/bin/easy-rsa.tar.gz /data/opt/tmp'
echo "Done..."
}


function install_k8s_add_ons() {
echo " "
echo "Creating kube-system namespace ..."
~/kube-solo/bin/kubectl create -f ~/kube-solo/kubernetes/kube-system-ns.yaml > /dev/null 2>&1
#
echo " "
echo "Installing SkyDNS ..."
~/kube-solo/bin/kubectl create -f ~/kube-solo/kubernetes/skydns-rc.yaml
~/kube-solo/bin/kubectl create -f ~/kube-solo/kubernetes/skydns-svc.yaml
#
echo " "
echo "Installing Kubernetes Dashboard ..."
~/kube-solo/bin/kubectl create -f ~/kube-solo/kubernetes/dashboard-controller.yaml
~/kube-solo/bin/kubectl create -f ~/kube-solo/kubernetes/dashboard-service.yaml
#
echo " "
echo "Installing Kubedash ..."
~/kube-solo/bin/kubectl create -f ~/kube-solo/kubernetes/kubedash.yaml
sleep 1
# clean up kubernetes folder
rm -f ~/kube-solo/kubernetes/kube-system-ns.yaml
rm -f ~/kube-solo/kubernetes/skydns-rc.yaml
rm -f ~/kube-solo/kubernetes/skydns-svc.yaml
rm -f ~/kube-solo/kubernetes/dashboard-controller.yaml
rm -f ~/kube-solo/kubernetes/dashboard-service.yaml
rm -f ~/kube-solo/kubernetes/kubedash.yaml
}


function install_k8s_add_ons_kubelet() {
# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)
#
echo " "
echo "Installing add-ons: SkyDNS, Kubernetes Dashboard and Kubedash ..."
~/bin/corectl scp "${res_folder}"/k8s/add-ons.tgz k8solo-01:/home/core/
~/bin/corectl ssh k8solo-01 'sudo tar xzf /home/core/add-ons.tgz -C /data/kubernetes/manifests'
}


function clean_up_after_vm() {
sleep 1

# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)

# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-solo/bin:$PATH

# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)

# send halt to VM
~/bin/corectl halt k8solo-01

# kill all other scripts
pkill -f [K]ube-Solo.app/Contents/Resources/fetch_latest_iso.command
pkill -f [K]ube-Solo.app/Contents/Resources/update_k8s.command
pkill -f [K]ube-Solo.app/Contents/Resources/update_osx_clients_files.command
pkill -f [K]ube-Solo.app/Contents/Resources/change_release_channel.command

}
