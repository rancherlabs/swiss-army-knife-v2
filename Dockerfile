# Build stage for Go application
FROM golang:1.24-alpine AS builder

# Set working directory for the build
WORKDIR /app

# Copy go mod and sum files
COPY main.go .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o echo-server main.go

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

# Copy the compiled binary from builder stage
COPY --from=builder /app/echo-server /usr/local/bin/

# Kubectl from k3s images - using latest patch versions for security fixes
COPY --from=rancher/k3s:v1.30.14-k3s2 \
    /bin/kubectl \
    /usr/local/bin/kubectl-1.30

COPY --from=rancher/k3s:v1.31.12-k3s1 \
    /bin/kubectl \
    /usr/local/bin/kubectl-1.31

COPY --from=rancher/k3s:v1.32.8-k3s1 \
    /bin/kubectl \
    /usr/local/bin/kubectl-1.32

COPY --from=rancher/k3s:v1.33.4-k3s1 \
    /bin/kubectl \
    /usr/local/bin/kubectl-1.33

## Create a symbolic link to the latest kubectl version
RUN ln -s /usr/local/bin/kubectl-1.33 /usr/local/bin/kubectl

# Set working directory
WORKDIR /root

# Create .kube directory
RUN mkdir /root/.kube

# Setup kubectl autocompletion, aliases, and profiles
RUN kubectl completion bash > /etc/bash_completion.d/kubectl

# Default command
CMD ["bash"]
