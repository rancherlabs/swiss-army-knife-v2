package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
)

type Response struct {
    Request    RequestInfo    `json:"request"`
    Kubernetes KubernetesInfo `json:"kubernetes"`
}

type RequestInfo struct {
    Method      string              `json:"method"`
    Headers     map[string][]string `json:"headers"`
    Path        string              `json:"path"`
    QueryParams map[string][]string `json:"query_params"`
    Body        string              `json:"body,omitempty"`
}

type KubernetesInfo struct {
    PodName       string `json:"pod_name"`
}

func echoHandler(w http.ResponseWriter, r *http.Request) {
    // Gather request information
    body := ""
    if r.Method == http.MethodPost {
        bodyBytes := make([]byte, r.ContentLength)
        if r.ContentLength > 0 {
            _, err := r.Body.Read(bodyBytes)
            if err != nil && err.Error() != "EOF" {
                http.Error(w, "Failed to read body", http.StatusInternalServerError)
                return
            }
        }
        body = string(bodyBytes)
    }

    requestInfo := RequestInfo{
        Method:      r.Method,
        Headers:     r.Header,
        Path:        r.URL.Path,
        QueryParams: r.URL.Query(),
        Body:        body,
    }

    // Gather Kubernetes pod information from environment variables
    k8sInfo := KubernetesInfo{
        PodName:       getEnv("HOSTNAME", "N/A"),
    }

    // Combine response
    response := Response{
        Request:    requestInfo,
        Kubernetes: k8sInfo,
    }

    // Serialize to JSON
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusOK)
    encoder := json.NewEncoder(w)
    encoder.SetIndent("", "  ")
    if err := encoder.Encode(response); err != nil {
        http.Error(w, "Failed to encode response", http.StatusInternalServerError)
    }
}

func getEnv(key, defaultVal string) string {
    if value, exists := os.LookupEnv(key); exists {
        return value
    }
    return defaultVal
}

func main() {
    http.HandleFunc("/", echoHandler)
    port := "8080"
    fmt.Printf("Starting server on port %s...\n", port)
    if err := http.ListenAndServe(":"+port, nil); err != nil {
        fmt.Fprintf(os.Stderr, "Failed to start server: %v\n", err)
        os.Exit(1)
    }
}