FROM registry.suse.com/bci/bci-base:15.6

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
    wget && \
    zypper -n clean -a && \
    rm -rf /tmp/* /var/tmp/* /usr/share/doc/packages/*

# Kubectl from k3s images
COPY --from=rancher/k3s:v1.28.15-k3s1 \
    /bin/kubectl \
    /usr/local/bin/kubectl-1.28

COPY --from=rancher/k3s:v1.29.10-k3s1 \
    /bin/kubectl \
    /usr/local/bin/kubectl-1.29

COPY --from=rancher/k3s:v1.30.6-k3s1 \
    /bin/kubectl \
    /usr/local/bin/kubectl-1.30

COPY --from=rancher/k3s:v1.31.2-k3s1 \
    /bin/kubectl \
    /usr/local/bin/kubectl-1.31

## Create a symbolic link to the latest kubectl version
RUN ln -s /usr/local/bin/kubectl-1.31 /usr/local/bin/kubectl

# Set working directory
WORKDIR /root

# Create .kube directory
RUN mkdir /root/.kube

# Default command
CMD ["bash"]
