// A humble replacement to the famous Python SimpleHTTPServer
package main

import (
    "flag"
    "fmt"
    "log"
    "net/http"
)

// HTTP Handler that logs the requested resources via the "log" module
func logHandler(handler http.Handler) http.Handler {
 return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
    log.Printf("%s %s ", r.Method, r.URL)
    handler.ServeHTTP(w, r)
 })
}

func main() {

 directoryOption := flag.String("directory", ".", "the directory to serve via HTTP (default is current directory)")
 portOption := flag.Int("port", 8080, "the listening port (default is 8080)")
 flag.Parse()

 var directory = http.Dir(*directoryOption)
 var fileServer = http.FileServer(directory)
 var port = *portOption

 var host = fmt.Sprintf(":%d", port)
 var handler = logHandler(fileServer)

 log.Printf("Staring HTTP server on http://127.0.0.1:%d/ in directory %v", port, directory)
 log.Fatal(http.ListenAndServe(host, handler))
}

