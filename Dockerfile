# Build stage for Go application
FROM golang:1.24-alpine@sha256:8bee1901f1e530bfb4a7850aa7a479d17ae3a18beb6e09064ed54cfd245b7191 AS builder

# Set working directory for the build
WORKDIR /app

# Copy go mod and sum files
COPY main.go .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o echo-server main.go

# Final stage
FROM registry.suse.com/bci/bci-base:15.7

# Use buildx automatic platform args
ARG TARGETARCH

# Kubectl dependency versions and checksums (set via --build-arg from Makefile/CI)
ARG KUBECTL_VERSION
ARG KUBECTL_SUM_amd64
ARG KUBECTL_SUM_arm64

# Update all packages to latest versions to fix known vulnerabilities
RUN zypper -n refresh && \
    zypper -n update -y && \
    zypper -n clean -a

# Install required packages from standard repositories and perform cleanup
RUN zypper -n install --no-recommends \
    curl \
    ca-certificates \
    openssl \
    ethtool \
    iproute2 \
    ipset \
    iptables \
    iputils \
    jq \
    kmod \
    less \
    net-tools \
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

# Install additional networking tools that may require alternative packages
RUN zypper -n install --no-recommends \
    ncat \
    || zypper -n install --no-recommends netcat \
    || echo "Warning: netcat not available, using built-in networking tools"

# Install conntrack if available (may not be in all SUSE repositories)
RUN zypper -n install --no-recommends conntrack \
    || echo "Warning: conntrack not available"

# Install mtr and iperf if available 
RUN zypper -n install --no-recommends mtr iperf3 \
    || zypper -n install --no-recommends mtr iperf \
    || echo "Warning: mtr/iperf not available"

# Copy the compiled binary from builder stage
COPY --from=builder /app/echo-server /usr/local/bin/

# Download kubectl and verify checksum
RUN KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt) && \
    curl -sLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" && \
    curl -sLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl.sha256" && \
    echo "$(cat kubectl.sha256) kubectl" | sha256sum --check && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl*

# Set working directory
WORKDIR /root

# Create .kube directory
RUN mkdir /root/.kube

# Setup kubectl autocompletion, aliases, and profiles
RUN kubectl completion bash > /etc/bash_completion.d/kubectl

# Add logs collector script
ADD --chown=root:root --chmod=0755 \
    https://raw.githubusercontent.com/rancherlabs/support-tools/refs/heads/master/collection/rancher/v2.x/logs-collector/rancher2_logs_collector.sh \
    /usr/local/bin/rancher2_logs_collector.sh

# Default command
CMD ["/usr/local/bin/echo-server"]