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

# Download the stable kubectl binary
RUN VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt) && \
    curl -L https://dl.k8s.io/release/$VERSION/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    chmod a+x /usr/local/bin/kubectl

# Set working directory
WORKDIR /root

# Create .kube directory
RUN mkdir /root/.kube

# Setup kubectl autocompletion, aliases, and profiles
RUN kubectl completion bash > /etc/bash_completion.d/kubectl

# Default command
CMD ["bash"]