# shellcheck disable=SC2006
package main

import (
    "fmt"
    "net/http"
)

func goChatHandler(w http.ResponseWriter, r *http.Request) {
    // Placeholder for Go service logic
    fmt.Fprintf(w, "Go Chat Service is running.")
}

func main() {
    http.HandleFunc("/go-chat", goChatHandler)
    fmt.Println("Go Chat Service is running on port 8081")
    if err := http.ListenAndServe(":8081", nil); err != nil {
        fmt.Println("Error starting Go service:", err)
    }
}
