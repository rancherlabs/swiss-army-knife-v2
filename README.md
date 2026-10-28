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
docker run --name swiss-army-knife --net=container:${CONTAINER_ID_TO_DEBUG} -itd rancherlabs/swiss-army-knife

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
    rancherlabs/swiss-army-knife swiss-army-knife bash
```

---

## Included Tools

The `swiss-army-knife` image includes the following tools (plus standard
utilities from the SLE BCI base image):

### Networking
- `tcpdump`
- `traceroute`
- `telnet`
- `netcat-openbsd`
- `ping` (via `iputils`)
- `dig` / `nslookup` (via `bind-utils`)
- `ifconfig` (via `net-tools`)
- `ethtool`
- `iptables`
- `ipset`
- `iproute2` (`ip`, `ss`)
- `conntrack-tools`
- `socat`
- `mtr` / `mtr-packet`
- `iperf3`
- `nmap`

### File Management
- `curl`
- `wget`
- `tree`
- `vim-small`
- `less`
- `jq`

### System Utilities
- `ca-certificates`
- `psmisc` (e.g., `killall`)
- `procps`
- `lsof`
- `strace`
- `sysstat`
- `iotop`
- `gawk`
- `bash-completion`

### Kubernetes Tools
- `kubectl` — pinned to the version in `hack/make/deps.mk` (currently v1.37.1),
  updated via Renovate. Only one version is shipped per image.

### Test webserver
The image runs an "echo-server" as the entrypoint on port 80/TCP for testing use cases. Any requests will responds with the headers and body send in the request.

### Logs collector
- `rancher2_logs_collector.sh` is bundled at `/usr/local/bin/`.

---

## Use Cases

1. **Debugging Network Issues**:
   - Use tools like `tcpdump`, `dig`, and `nslookup` to debug DNS and network traffic.
   
2. **Testing Web Applications**:
   - Use `curl`, `wget`, or `telnet` to test service availability.

3. **Kubernetes Troubleshooting**:
   - A single pinned `kubectl` version (see `hack/make/deps.mk`) is included.

4. **System Debugging**:
   - Utilize tools like `ps`, `ifconfig`, and `iptables` to debug issues at the OS level.

---

This container is your one-stop shop for debugging and testing in production environments. It eliminates the need to install extra tools during critical times, ensuring you are always prepared.

---

## Building locally

```sh
# Multi-arch build (saved to ci/multiarch-image.oci)
make build-validate

# Build and load for the current platform only
make build-image

# Override the tag (defaults to the git tag on HEAD, or the commit SHA when untagged)
make build-image TAG=v0.0.0-dev
```

The `VERSION` and `TAG` values are derived from `scripts/version` (the git tag on
HEAD, falling back to the commit SHA plus a `-dirty` suffix).

## Releasing

Images are published to Docker Hub as `rancherlabs/swiss-army-knife` (the image
name keeps the original `swiss-army-knife` name even though the repository is
`swiss-army-knife-v2`).

### Tags
- `:latest` — the most recent **stable** (published) release. Never an RC.
- `:vX.Y.Z` — immutable per-version tag.
- `:vX.Y.Z-rcN` — release candidates, published to **GitHub only** (no registry
  push).

### Cutting a release
1. Push a tag: `git tag vX.Y.Z && git push origin vX.Y.Z`.
2. **Phase 1** of the `Release` workflow runs:
   - Builds and pushes `rancherlabs/swiss-army-knife:vX.Y.Z` to Docker Hub via
     `rancher/ecm-distro-tools/actions/publish-image` (skipped for `*-rc*` tags).
   - Creates a **Draft** GitHub release with auto-generated notes (`--prerelease`
     for RC tags).
3. Test the published image (`docker pull rancherlabs/swiss-army-knife:vX.Y.Z`).
4. Open the draft release in GitHub and click **Publish release**.
5. **Phase 2** runs and re-points `:latest` at the versioned manifest (no rebuild;
   identical digest).

### Notes
- The versioned tag is pushed exactly once and never overwritten; `:latest` is
  just a pointer that moves to the published version.
- Release candidates (and pre-release tags) are published to GitHub only and
  never reach Docker Hub.
- The workflow is defined in `.github/workflows/release.yml`.

Happy debugging! 🚀
