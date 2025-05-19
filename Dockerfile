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
RUN zypper addrepo -G https://download.opensuse.org/repositories/network:utilities/SLE_15_SP5/network:utilities.repo && \
    zypper -n install --no-recommends \
    curl \
    ca-certificates \
    openssl \
    conntrack-tools \
    ethtool \
    iproute2 \
    ipset \
    iptables \
    iputils \
    mtr \
    iperf \
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

# Kubectl from k3s images
RUN VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt) && \
    curl -L https://dl.k8s.io/release/$VERSION/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    chmod a+x /usr/local/bin/kubectl

# Set working directory
WORKDIR /root

# Setup kubectl autocompletion, aliases, and profiles
RUN kubectl completion bash > /etc/bash_completion.d/kubectl

# Default command to run the main application
CMD ["/usr/local/bin/echo-server"]