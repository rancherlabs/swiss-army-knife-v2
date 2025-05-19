# Build stage for Go application
FROM golang:1.24-alpine AS builder

# Set working directory for the build
WORKDIR /src

# Copy go mod and sum files
COPY go.mod go.sum ./

# Download all dependencies
RUN go mod download

# Copy the source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o swiss-army-knife .

# Final stage
FROM registry.suse.com/bci/bci-base:15.7

# Install required packages and perform cleanup
RUN zypper -n install --no-recommends \
    curl \
    ca-certificates \
    openssl \
    conntrack-tools \
    ethtool \
    iproute2 \
    ipset \
    iptables \
    iputils \
    jq \
    kmod \
    less \
    net-tools \
    netcat-openbsd \
    bind-utils \
    psmisc \
    socat \
    tcpdump \
    telnet \
    traceroute \
    tree \
    vim-small \
    wget \
    bash-completion \
    gcc \
    gcc-c++ \
    make \
    automake \
    autoconf \
    gawk \
    libtool && \
    zypper -n clean -a && \
    rm -rf /tmp/* /var/tmp/* /usr/share/doc/packages/*

# Download and build iperf from source
RUN cd /tmp && \
    wget https://sourceforge.net/projects/iperf2/files/iperf-2.0.13.tar.gz/download -O iperf-2.0.13.tar.gz && \
    tar -xzf iperf-2.0.13.tar.gz && \
    cd iperf-2.0.13 && \
    ./configure && \
    make && \
    make install && \
    cd .. && \
    rm -rf iperf-2.0.13*

# Download and build iperf3 from source
RUN cd /tmp && \
    wget https://downloads.es.net/pub/iperf/iperf-3.13.tar.gz && \
    tar -xzf iperf-3.13.tar.gz && \
    cd iperf-3.13 && \
    ./configure && \
    make && \
    make install && \
    ldconfig && \
    cd .. && \
    rm -rf iperf-3.13*

# Pull mtr binary from jeschu/mtr
COPY --from=jeschu/mtr /usr/sbin/mtr /usr/local/bin/mtr

# Kubectl from k3s images
COPY --from=rancher/k3s:v1.28.15-k3s1 /bin/kubectl /usr/local/bin/kubectl-1.28
COPY --from=rancher/k3s:v1.29.10-k3s1 /bin/kubectl /usr/local/bin/kubectl-1.29
COPY --from=rancher/k3s:v1.30.6-k3s1 /bin/kubectl /usr/local/bin/kubectl-1.30
COPY --from=rancher/k3s:v1.31.2-k3s1 /bin/kubectl /usr/local/bin/kubectl-1.31

# Create a symbolic link to the latest kubectl version
RUN ln -s /usr/local/bin/kubectl-1.31 /usr/local/bin/kubectl

# Copy the compiled binary from builder stage
COPY --from=builder /src/swiss-army-knife /usr/local/bin/

# Set working directory
WORKDIR /root

# Create .kube directory
RUN mkdir /root/.kube

# Setup kubectl autocompletion, aliases, and profiles
RUN kubectl completion bash > /etc/bash_completion.d/kubectl

# Add Go Echo server
COPY <<EOF /root/echo-server.go
package main

import (
    "fmt"
    "net/http"
)

func handler(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintf(w, "Hello, you've hit %s\n", r.URL.Path)
}

func main() {
    http.HandleFunc("/", handler)
    fmt.Println("Starting server on :8080")
    http.ListenAndServe(":8080", nil)
}
EOF

# Build the Echo server binary
RUN echo "Installing Go..." && \
    wget https://go.dev/dl/go1.24.0.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.24.0.linux-amd64.tar.gz && \
    rm go1.24.0.linux-amd64.tar.gz && \
    export PATH="/usr/local/go/bin:$PATH" && \
    echo "Building echo server..." && \
    go build -o /usr/local/bin/echo-server /root/echo-server.go && \
    rm /root/echo-server.go

# Default command to run the main application
CMD ["/usr/local/bin/swiss-army-knife"]