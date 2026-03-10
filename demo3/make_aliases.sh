alias sw="docker exec -it clab-mod1-devconfig-switch"
alias h1="docker exec -it clab-mod1-devconfig-host1"
alias h2="docker exec -it clab-mod1-devconfig-host2"



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

alias sw-tcpdump="_ns_tcpdump clab-mod1-devconfig-switch"
alias h1-tcpdump="_ns_tcpdump clab-mod1-devconfig-host1"
alias h2-tcpdump="_ns_tcpdump clab-mod1-devconfig-host2"

alias sw-tshark="_ns_tshark clab-mod1-devconfig-switch"
alias h1-tshark="_ns_tshark clab-mod1-devconfig-host1"
alias h2-tshark="_ns_tshark clab-mod1-devconfig-host2"

# onepkt.py uses scapy's AF_PACKET sockets which QEMU does not emulate properly
# (ENOPROTOOPT on SOL_PACKET/PACKET_ADD_MEMBERSHIP). Run the host's python3 via
# nsenter so scapy uses the real kernel socket interface instead of QEMU's stub.
# We resolve /lab-folder to its bind-mount source path on the host so the script
# is accessible from the host's filesystem perspective.
_ns_onepkt() {
    local container="$1"; shift
    local pid lab_folder_host
    pid=$(docker inspect "$container" --format '{{.State.Pid}}')
    lab_folder_host=$(docker inspect "$container" --format '{{range .Mounts}}{{if eq .Destination "/lab-folder"}}{{.Source}}{{end}}{{end}}')
    nsenter -t "$pid" -n -- python3 "${lab_folder_host}/onepkt.py" "$@"
}

alias h1-onepkt="_ns_onepkt clab-mod1-devconfig-host1"
alias h2-onepkt="_ns_onepkt clab-mod1-devconfig-host2"