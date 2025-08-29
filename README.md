[![Pulls](https://img.shields.io/docker/pulls/rancherlabs/swiss-army-knife.svg)](https://hub.docker.com/r/rancherlabs/swiss-army-knife)

# swiss-army-knife v2

Packing any application with a tiny/bare minimal base image sounds like an awesome/cool/intelligent idea, until things break and there are no tools inside the container to debug the problem at hand.  
This repo/docker image solves this problem by providing a robust image equipped with a wide array of tools needed to debug the majority of issues in production environments.  

This image also includes a very small web application for testing/debugging purposes.

---

## Running

### Using Docker

```bash
# Run and attach to the network namespace of the container to debug
docker run --name swiss-army-knife --net=container:${CONTAINER_ID_TO_DEBUG} -itd ranchersupport/swiss-army-knife-v2

# Exec into the tools container
docker exec -it swiss-army-knife bash

# Show off your ninja skill!
tcpdump -i eth0 -vvv -nn -s0 -SS -XX
```

### Using Containerd

```bash
# Find the target container's PID
TARGET_CONTAINER_ID=<TARGET_CONTAINER_ID>
TARGET_CONTAINER_PID=$(crictl inspect --output go-template --template '{{.info.pid}}' $TARGET_CONTAINER_ID)

# Run swiss-army-knife and attach to the target container's network namespace
ctr run --rm --privileged \
    --mount type=bind,src=/proc/${TARGET_CONTAINER_PID}/ns/net,dst=/proc/self/ns/net,options=rbind:ro \
    ranchersupport/swiss-army-knife-v2 swiss-army-knife bash
```

---

## Included Tools

The `swiss-army-knife` image includes the following tools:

### Networking
- `tcpdump`
- `traceroute`
- `telnet`
- `netcat-openbsd`
- `ping` (via `iputils`)
- `dig` (via `bind-utils`)
- `nslookup` (via `bind-utils`)
- `ifconfig` (via `net-tools`)
- `ethtool`
- `iptables`
- `ipset`
- `iproute2`
- `conntrack-tools`
- `socat`

### File Management
- `curl`
- `wget`
- `tree`
- `vim-small`
- `less`
- `jq`

### System Utilities
- `kmod`
- `psmisc` (e.g., `killall`)
- `openssl`
- `ca-certificates`
- `tcpdump`

### Kubernetes Tools
- `kubectl` (multiple versions included from K3s images: `1.30`, `1.31`, `1.32`, `1.33`)

---

## Use Cases

1. **Debugging Network Issues**:
   - Use tools like `tcpdump`, `dig`, and `nslookup` to debug DNS and network traffic.
   
2. **Testing Web Applications**:
   - Use `curl`, `wget`, or `telnet` to test service availability.

3. **Kubernetes Troubleshooting**:
   - Multiple versions of `kubectl` are included for compatibility with different Kubernetes clusters.

4. **System Debugging**:
   - Utilize tools like `ps`, `ifconfig`, and `iptables` to debug issues at the OS level.

---

This container is your one-stop shop for debugging and testing in production environments. It eliminates the need to install extra tools during critical times, ensuring you are always prepared.

Happy debugging! 🚀
