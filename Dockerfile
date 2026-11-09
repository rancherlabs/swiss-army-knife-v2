# Build stage for Go application
FROM registry.suse.com/bci/golang:1.27 AS builder

# Set working directory for the build
WORKDIR /app

# Copy go mod and sum files
COPY main.go .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o echo-server main.go

# Build stage for network tools that are not shipped in the BCI
# repository. Building them from pinned upstream releases keeps the runtime
# image free of third-party repositories.
FROM registry.suse.com/bci/bci-base:15.7 AS nettools

ARG MTR_VERSION=0.96
ARG MTR_SHA256=ffd19a9f8d5f616c1ea2f0da9fbf9d1239bcecdf5a68912e831966d20929037a
ARG IPERF_VERSION=3.22
ARG IPERF_SHA256=1c0d0fb02c52626111d6e132db80edfbf27bbaff8bd9245df2a371dcb0b35a92

RUN set -eux; \
    zypper -n install --no-recommends \
        curl \
        gawk \
        gcc \
        make \
        ncurses-devel \
        libcap-devel; \
    mkdir -p /out; \
    curl -fsSL "https://www.bitwizard.nl/mtr/files/mtr-${MTR_VERSION}.tar.gz" -o /tmp/mtr.tar.gz; \
    echo "${MTR_SHA256}  /tmp/mtr.tar.gz" | sha256sum -c -; \
    tar -xzf /tmp/mtr.tar.gz -C /tmp; \
    cd "/tmp/mtr-${MTR_VERSION}"; \
    ./configure --prefix=/usr --without-jansson --without-gtk; \
    make -j"$(nproc)"; \
    make install DESTDIR=/out; \
    curl -fsSL "https://downloads.es.net/pub/iperf/iperf-${IPERF_VERSION}.tar.gz" -o /tmp/iperf.tar.gz; \
    echo "${IPERF_SHA256}  /tmp/iperf.tar.gz" | sha256sum -c -; \
    tar -xzf /tmp/iperf.tar.gz -C /tmp; \
    cd "/tmp/iperf-${IPERF_VERSION}"; \
    ./configure --prefix=/usr --disable-shared; \
    make -j"$(nproc)"; \
    make install DESTDIR=/out; \
    mkdir -p /stage/usr/sbin /stage/usr/bin /stage/usr/share/bash-completion/completions; \
    cp /out/usr/sbin/mtr /out/usr/sbin/mtr-packet /stage/usr/sbin/; \
    cp /out/usr/bin/iperf3 /stage/usr/bin/; \
    cp /out/usr/share/bash-completion/completions/mtr /stage/usr/share/bash-completion/completions/; \
    strip --strip-unneeded /stage/usr/sbin/mtr /stage/usr/sbin/mtr-packet /stage/usr/bin/iperf3

# Final stage
FROM registry.suse.com/bci/bci-base:15.7

# Use buildx automatic platform args
ARG TARGETARCH

# Update all packages to latest versions to fix known vulnerabilities.
# Everything comes from the SLE_BCI repository that ships with the image. Its
# URL is derived from the base image version, so no extra repository is needed.
RUN echo 'rpm.install.excludedocs = yes' >> /etc/zypp/zypp.conf && \
    zypper -n update -y && \
    zypper -n install --no-recommends \
        curl \
        ca-certificates \
        ethtool \
        iproute2 \
        ipset \
        iptables \
        iputils \
        jq \
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
        gawk \
        procps \
        lsof \
        strace \
        sysstat \
        iotop \
        nmap \
        netcat-openbsd \
        conntrack-tools \
        gpg2 && \
    zypper -n clean -a && \
    rm -rf /tmp/* /var/tmp/* /var/cache/zypp/* /var/cache/ldconfig/aux-cache \
           /var/log/* /usr/share/doc/* /usr/share/man/* /usr/share/info/* /usr/share/locale/*

# Copy the compiled binary from builder stage
COPY --from=builder /app/echo-server /usr/local/bin/

# Copy the network tools built from source (not available in SLE-BCI)
COPY --from=nettools /stage/ /

# Install kubectl from the Rancher RPM repository. RPM_PKGS_CHANNEL is
# "community" for public images and "prime" for Prime images; both channels are
# signed with the same key, whose fingerprint is verified before import. The
# repository is removed again after installation so the runtime image only
# references SLE_BCI.
ARG RPM_PKGS_CHANNEL=community
ARG RANCHER_PKGS_GPG_FPR=BB0BB4C670D8BE8B200024014C37995C0B74252A
ARG KUBECTL_MINOR=1.37
RUN set -eux; \
    curl -sfL -o /tmp/rancher-pkgs.key "https://rpm.rancher.io/pkgs/${RPM_PKGS_CHANNEL}/repodata/repomd.xml.key"; \
    gpg --show-keys --with-colons /tmp/rancher-pkgs.key | grep -qx "fpr:::::::::${RANCHER_PKGS_GPG_FPR}:"; \
    rpm --import /tmp/rancher-pkgs.key; \
    rm -f /tmp/rancher-pkgs.key; \
    zypper addrepo -f -c "https://rpm.rancher.io/pkgs/${RPM_PKGS_CHANNEL}" rancher-pkgs; \
    zypper -n install --no-recommends "kubectl-${KUBECTL_MINOR}"; \
    ln -s "/usr/bin/kubectl-${KUBECTL_MINOR}" /usr/local/bin/kubectl; \
    zypper removerepo rancher-pkgs; \
    zypper -n clean -a; \
    rm -rf /tmp/* /var/tmp/* /var/cache/zypp/* /var/log/*; \
    mkdir -p /root/.kube; \
    kubectl completion bash > /etc/bash_completion.d/kubectl; \
    for bin in curl jq ip ss tcpdump nmap socat strace tree vim lsof mtr mtr-packet iperf3 kubectl; do \
        command -v "${bin}" >/dev/null || { echo "missing required tool: ${bin}" >&2; exit 1; }; \
    done

# Set working directory
WORKDIR /root

# Add logs collector script
ADD --chown=root:root --chmod=0755 \
    https://raw.githubusercontent.com/rancherlabs/support-tools/refs/heads/master/collection/rancher/v2.x/logs-collector/rancher2_logs_collector.sh \
    /usr/local/bin/rancher2_logs_collector.sh

# Default command
CMD ["/usr/local/bin/echo-server"]