#!/bin/bash

# shared functions library

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


function pause(){
    read -p "$*"
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
        sed -i "" 's/channel = "stable"/channel = "alpha"/g' ~/kube-solo/settings/*.toml
        sed -i "" 's/channel = "beta"/channel = "alpha"/g' ~/kube-solo/settings/*.toml
        channel="Alpha"
        LOOP=0
    fi

    if [ $RESPONSE = 2 ]
    then
        VALID_MAIN=1
        sed -i "" 's/channel = "stable"/channel = "beta"/g' ~/kube-solo/settings/*.toml
        sed -i "" 's/channel = "alpha"/channel = "beta"/g' ~/kube-solo/settings/*.toml
        channel="Beta"
        LOOP=0
    fi

    if [ $RESPONSE = 3 ]
    then
        VALID_MAIN=1
        sed -i "" 's/channel = "beta"/channel = "stable"/g' ~/kube-solo/settings/*.toml
        sed -i "" 's/channel = "alpha"/channel = "stable"/g' ~/kube-solo/settings/*.toml
        channel="Stable"
        LOOP=0
    fi

    if [ $VALID_MAIN != 1 ]
    then
        continue
    fi
done
}


create_data_disk() {
# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-solo/bin:$PATH

# create persistent disk
cd ~/kube-solo/
echo "  "
echo "Please type Data disk size in GBs followed by [ENTER]:"
echo -n "[default is 10]: "
read disk_size
if [ -z "$disk_size" ]
then
    echo " "
    echo "Creating 10GB disk ..."
##    mkfile 10g data.img
    ~/kube-solo/bin/pv -s 10g -S < /dev/zero > data.img
    echo "Created 10GB Data disk"
else
    echo " "
    echo "Creating "$disk_size"GB disk (it could take a while for big disks)..."
##    mkfile "$disk_size"g data.img
    ~/kube-solo/bin/pv -s "$disk_size"g -S < /dev/zero > data.img
    echo "Created "$disk_size"GB Data disk"
fi

}


change_vm_ram() {
echo " "
echo " "
echo "Please type VM's RAM size in GBs followed by [ENTER]:"
echo -n "[default is 2]: "
read ram_size
if [ -z "$ram_size" ]
then
    ram_size=2
    echo "Changing VM's RAM to "$ram_size"GB..."
    ((new_ram_size=$ram_size*1024))
    sed -i "" 's/\(memory = \)\(.*\)/\1'$new_ram_size'/g' ~/kube-solo/settings/k8solo-01.toml
    echo " "
else
    echo "Changing VM's RAM to "$ram_size"GB..."
    ((new_ram_size=$ram_size*1024))
    sed -i "" 's/\(memory = \)\(.*\)/\1'$new_ram_size'/g' ~/kube-solo/settings/k8solo-01.toml
    echo " "
fi

}


start_vm() {
# get password for sudo
my_password=$(security find-generic-password -wa kube-solo-app)
# reset sudo
sudo -k > /dev/null 2>&1

# Start VM
cd ~/kube-solo
echo " "
echo "Starting VM ..."
echo -e "$my_password\n" | sudo -Sv > /dev/null 2>&1
#
sudo "${res_folder}"/bin/corectl load settings/k8solo-01.toml 2>&1 | tee ~/kube-solo/logs/vm_up.log
CHECK_VM_STATUS=$(cat ~/kube-solo/logs/vm_up.log | grep "started")
#
if [[ "$CHECK_VM_STATUS" == "" ]]; then
    echo " "
    echo "VM have not booted, please check '~/kube-solo/logs/vm_up.log' and report the problem !!! "
    echo " "
    pause 'Press [Enter] key to continue...'
    exit 0
else
    echo "VM successfully started !!!" >> ~/kube-solo/logs/vm_up.log
fi

# check if /Users/homefolder is mounted, if not mount it
"${res_folder}"/bin/corectl ssh k8solo-01 'source /etc/environment; if df -h | grep ${HOMEDIR}; then echo 0; else sudo systemctl restart ${HOMEDIR}; fi' > /dev/null 2>&1

# save VM's IP
"${res_folder}"/bin/corectl q -i k8solo-01 | tr -d "\n" > ~/kube-solo/.env/ip_address
# get VM IP
vm_ip=$("${res_folder}"/bin/corectl q -i k8solo-01)
#

}


function download_osx_clients() {
# download fleetctl file
FLEETCTL_VERSION=$("${res_folder}"/bin/corectl ssh k8solo-01 'fleetctl --version' | awk '{print $3}' | tr -d '\r')
FILE=fleetctl
if [ ! -f ~/kube-solo/bin/$FILE ]; then
    cd ~/kube-solo/bin
    echo "Downloading fleetctl v$FLEETCTL_VERSION for OS X"
    curl -L -o fleet.zip "https://github.com/coreos/fleet/releases/download/v$FLEETCTL_VERSION/fleet-v$FLEETCTL_VERSION-darwin-amd64.zip"
    unzip -j -o "fleet.zip" "fleet-v$FLEETCTL_VERSION-darwin-amd64/fleetctl" > /dev/null 2>&1
    rm -f fleet.zip
else
    # we check the version of the binary
    INSTALLED_VERSION=$(~/kube-solo/bin/$FILE --version | awk '{print $3}' | tr -d '\r')
    MATCH=$(echo "${INSTALLED_VERSION}" | grep -c "${FLEETCTL_VERSION}")
    if [ $MATCH -eq 0 ]; then
        # the version is different
        cd ~/kube-solo/bin
        echo "Downloading fleetctl v$FLEETCTL_VERSION for OS X"
        curl -L -o fleet.zip "https://github.com/coreos/fleet/releases/download/v$FLEETCTL_VERSION/fleet-v$FLEETCTL_VERSION-darwin-amd64.zip"
        unzip -j -o "fleet.zip" "fleet-v$FLEETCTL_VERSION-darwin-amd64/fleetctl" > /dev/null 2>&1
        rm -f fleet.zip
    else
        echo " "
        echo "fleetctl is up to date ..."
        echo " "
    fi
fi

# get lastest OS X helm version from bintray
cd ~/kube-solo/bin
# curl -s https://get.helm.sh | bash > /dev/null 2>&1
bin_version=$(curl -sI https://bintray.com/deis/helm/helm/_latestVersion | grep "Location:" | sed -n 's%.*helm/%%;s%/view.*%%p')
echo "Downloading latest version of helm for OS X"
curl -L "https://dl.bintray.com/deis/helm/helm-$bin_version-darwin-amd64.zip" -o helm.zip
unzip -o helm.zip > /dev/null 2>&1
rm -f helm.zip
echo " "
echo "Installed latest helm $bin_version to ~/kube-solo/bin ..."
#

}


function download_k8s_files() {
#
cd ~/kube-solo/tmp

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

# download latest version of kubectl for OS X
cd ~/kube-solo/tmp
echo "Downloading kubectl $K8S_VERSION for OS X"
curl -k -L https://storage.googleapis.com/kubernetes-release/release/$K8S_VERSION/bin/darwin/amd64/kubectl >  ~/kube-solo/kube/kubectl
chmod 755 ~/kube-solo/kube/kubectl
echo "kubectl was copied to ~/kube-solo/kube"
echo " "

# clean up tmp folder
rm -rf ~/kube-solo/tmp/*

# download latest version of k8s for CoreOS
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
echo "Bear in mind if the version you want is lower than the currently installed, "
echo "Kubernetes cluster migth not work, so you will need to destroy the cluster first "
echo " and boot VM again !!! "
echo " "
echo "Please type Kubernetes version you want to be installed e.g. v1.1.1 or v1.2.0-alpha.4"
echo "followed by [ENTER] to continue or press CMD + W to exit:"
read K8S_VERSION

url=https://github.com/kubernetes/kubernetes/releases/download/$K8S_VERSION/kubernetes.tar.gz

if curl --output /dev/null --silent --head --fail "$url"; then
    echo "URL exists: $url" > /dev/null
else
    echo " "
    echo "There is no such Kubernetes version to download !!!"
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
    exit 1
fi

k8s_upgrade=1

# download required version of Kubernetes
cd ~/kube-solo/tmp
echo " "
echo "Downloading Kubernetes $K8S_VERSION tar.gz from github ..."
curl -k -L https://github.com/kubernetes/kubernetes/releases/download/$K8S_VERSION/kubernetes.tar.gz >  kubernetes.tar.gz
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


function deploy_fleet_units() {
# deploy fleet units from ~/kube-solo/fleet
cd ~/kube-solo/fleet
echo "Starting all fleet units in ~/kube-solo/fleet:"
fleetctl start fleet-ui.service
fleetctl start kube-apiserver.service
fleetctl start kube-controller-manager.service
fleetctl start kube-scheduler.service
fleetctl start kube-kubelet.service
fleetctl start kube-proxy.service
echo " "
echo "fleetctl list-units:"
fleetctl list-units
echo " "

}


function install_k8s_files {
# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)

# get VM IP
vm_ip=$("${res_folder}"/bin/corectl q -i k8solo-01)

# install k8s files on to VM
echo " "
echo "Installing Kubernetes files on to VM..."
cd ~/kube-solo/kube
###scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet kube.tgz core@$vm_ip:/home/core
"${res_folder}"/bin/corectl scp kube.tgz k8solo-01:/home/core/
"${res_folder}"/bin/corectl ssh k8solo-01 'sudo /usr/bin/mkdir -p /opt/bin && sudo tar xzf /home/core/kube.tgz -C /opt/bin && sudo chmod 755 /opt/bin/*'
"${res_folder}"/bin/corectl ssh k8solo-01 'sudo /usr/bin/mkdir -p /opt/tmp && sudo mv /opt/bin/easy-rsa.tar.gz /opt/tmp'

echo "Done with k8solo-01 "
echo " "
}


function install_k8s_add_ons {
echo " "
echo "Creating kube-system namespace ..."
~/kube-solo/bin/kubectl create -f ~/kube-solo/kubernetes/kube-system-ns.yaml
#
sed -i "" "s/_MASTER_IP_/$1/" ~/kube-solo/kubernetes/skydns-rc.yaml
echo " "
echo "Installing SkyDNS ..."
~/kube-solo/bin/kubectl create -f ~/kube-solo/kubernetes/skydns-rc.yaml
~/kube-solo/bin/kubectl create -f ~/kube-solo/kubernetes/skydns-svc.yaml
#
echo " "
echo "Installing Kubernetes UI ..."
~/kube-solo/bin/kubectl create -f ~/kube-solo/kubernetes/kube-ui-rc.yaml
~/kube-solo/bin/kubectl create -f ~/kube-solo/kubernetes/kube-ui-svc.yaml
sleep 1
# clean up kubernetes folder
rm -f ~/kube-solo/kubernetes/kube-system-ns.yaml
rm -f ~/kube-solo/kubernetes/skydns-rc.yaml
rm -f ~/kube-solo/kubernetes/skydns-svc.yaml
rm -f ~/kube-solo/kubernetes/kube-ui-rc.yaml
rm -f ~/kube-solo/kubernetes/kube-ui-svc.yaml
echo " "
}


function save_password {
# save user's password to Keychain
echo "  "
echo "Your Mac user's password will be saved in to 'Keychain' "
echo "and later one used for 'sudo' command to start VM !!!"
echo " "
echo "This is not the password to access VM via ssh or console !!!"
echo " "
echo "Please type your Mac user's password followed by [ENTER]:"
read -s my_password
passwd_ok=0

# check if sudo password is correct
while [ ! $passwd_ok = 1 ]
do
    # reset sudo
    sudo -k
    # check sudo
    echo -e "$my_password\n" | sudo -Sv > /dev/null 2>&1
    CAN_I_RUN_SUDO=$(sudo -n uptime 2>&1|grep "load"|wc -l)
    if [ ${CAN_I_RUN_SUDO} -gt 0 ]
    then
        echo "The sudo password is fine !!!"
        echo " "
        passwd_ok=1
    else
        echo " "
        echo "The password you entered does not match your Mac user password !!!"
        echo "Please type your Mac user's password followed by [ENTER]:"
        read -s my_password
    fi
done

security add-generic-password -a kube-solo-app -s kube-solo-app -w $my_password -U
}


function clean_up_after_vm {
sleep 1

# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)

# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-solo/bin:$PATH

# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)

# get password for sudo
my_password=$(security find-generic-password -wa kube-solo-app)
# reset sudo
sudo -k
# enable sudo
echo -e "$my_password\n" | sudo -Sv > /dev/null 2>&1

# send halt to VM
sudo "${res_folder}"/bin/corectl halt k8solo-01

# kill all other scripts
pkill -f [K]ube-Solo.app/Contents/Resources/fetch_latest_iso.command
pkill -f [K]ube-Solo.app/Contents/Resources/update_k8s.command
pkill -f [K]ube-Solo.app/Contents/Resources/update_osx_clients_files.command
pkill -f [K]ube-Solo.app/Contents/Resources/change_release_channel.command

}
