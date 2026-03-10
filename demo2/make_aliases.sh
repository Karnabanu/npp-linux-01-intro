alias host1="docker exec -it clab-lab1-part1-host1"
alias host2="docker exec -it clab-lab1-part1-host2"
alias host3="docker exec -it clab-lab1-part1-host3"
alias host4="docker exec -it clab-lab1-part1-host4"
alias sw="docker exec -it clab-lab1-part1-switch"

# tcpdump/tshark run via nsenter using the host's native binaries.
# This is needed on ARM hosts because the amd64 container image runs under QEMU
# emulation, and QEMU mis-handles the SIOCETHTOOL ioctl causing libpcap inside
# the container to fail. The host's libpcap (1.10.5+) handles this gracefully.
_ns_tcpdump() {
    local container="$1"; shift
    local pid
    pid=$(docker inspect "$container" --format '{{.State.Pid}}')
    nsenter -t "$pid" -n -- tcpdump "$@"
}
_ns_tshark() {
    local container="$1"; shift
    local pid
    pid=$(docker inspect "$container" --format '{{.State.Pid}}')
    nsenter -t "$pid" -n -- tshark "$@"
}

alias switch-tcpdump="_ns_tcpdump clab-lab1-part1-switch"
alias host1-tcpdump="_ns_tcpdump clab-lab1-part1-host1"
alias host2-tcpdump="_ns_tcpdump clab-lab1-part1-host2"
alias host3-tcpdump="_ns_tcpdump clab-lab1-part1-host3"
alias host4-tcpdump="_ns_tcpdump clab-lab1-part1-host4"

alias switch-tshark="_ns_tshark clab-lab1-part1-switch"
alias host1-tshark="_ns_tshark clab-lab1-part1-host1"
alias host2-tshark="_ns_tshark clab-lab1-part1-host2"
alias host3-tshark="_ns_tshark clab-lab1-part1-host3"
alias host4-tshark="_ns_tshark clab-lab1-part1-host4"
