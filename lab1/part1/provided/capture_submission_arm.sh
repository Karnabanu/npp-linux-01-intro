#!/usr/bin/bash

# ARM-compatible version: uses nsenter to run host's tshark and python3/scapy
# in container network namespaces, bypassing QEMU emulation issues.

if [ -d "./submission" ] || [ -f "submission.tgz" ]
then
    echo "Submission exists.  This script creates the submission directory and submission.tgz file.  Please remove or move and re-run this script." 
    exit 1
fi

if ! [ -f "./do-lab.sh" ]; then
    echo "do-lab.sh does not exist.  Please create and re-run this script."
    exit 1
fi

# check dirs (lab-host1, lab-host2, lab-host3, lab-host4, provided)
dirs=( lab-host1 lab-host2 lab-host3 lab-host4 provided)
for i in "${dirs[@]}"
do
   if ! [ -d $i ]; then
      echo "Directory $i does not exist.  Exiting."
      exit 2
   else
      if [ -f $i/*.pcap ]; then
	 echo "Directory $i has a pcap file.  Delete or move and re-run this script."
         exit 3
      fi
   fi 
done

sudo containerlab deploy
if [ $? -ne 0 ]; then
  echo "Containerlab deploy failed. Check if it is running 'sudo containerlab inspect'.  Check if the yaml file exits.  Please correct then re-run this script"
  exit 3
fi

chmod +x ./provided/change_mac_addrs.sh
./provided/change_mac_addrs.sh

./do-lab.sh

# copy onepkt.py and clear any stale pcap files
cp ./provided/onepkt.py ./lab-host1
cp ./provided/onepkt.py ./lab-host2
cp ./provided/onepkt.py ./lab-host3
cp ./provided/onepkt.py ./lab-host4
rm -f lab-host1/h1.pcap lab-host2/h2.pcap lab-host3/h3.pcap lab-host4/h4.pcap

# Helper: get the host-side path of /lab-folder for a given container
get_lab_folder() {
  docker inspect "$1" --format '{{range .Mounts}}{{if eq .Destination "/lab-folder"}}{{.Source}}{{end}}{{end}}'
}

# Helper to run tshark in container netns using host binary
# Writes pcap to the host bind-mount path so it survives after containerlab destroy
# Appends the background PID to /tmp/tshark_pids so the caller can kill them later.
run_tshark() {
  local cname="$1"
  local pcap_name="$2"
  local cnet_pid lab_folder_host
  cnet_pid=$(docker inspect "$cname" --format '{{.State.Pid}}')
  lab_folder_host=$(get_lab_folder "$cname")
  nsenter -t "$cnet_pid" -n -- tshark -i eth1 -f "host 1.1.1.1" -w "${lab_folder_host}/${pcap_name}" &
  echo $! >> /tmp/tshark_pids
}

# Helper to run onepkt.py in container netns using host python3/scapy
run_onepkt() {
  local cname="$1"; shift
  local cnet_pid lab_folder_host
  cnet_pid=$(docker inspect "$cname" --format '{{.State.Pid}}')
  lab_folder_host=$(get_lab_folder "$cname")
  nsenter -t "$cnet_pid" -n -- python3 "${lab_folder_host}/onepkt.py" "$@"
}

# Start packet captures in background
rm -f /tmp/tshark_pids
run_tshark clab-lab1-part1-host1 h1.pcap
run_tshark clab-lab1-part1-host2 h2.pcap
run_tshark clab-lab1-part1-host3 h3.pcap
run_tshark clab-lab1-part1-host4 h4.pcap

# Give tshark a moment to start listening
sleep 2s

# Packet tests
# host1 to host2
run_onepkt clab-lab1-part1-host1 host1 host2 test-pkt1

# host2 to host3
run_onepkt clab-lab1-part1-host2 host2 host3 test-pkt2

# host3 to host2
run_onepkt clab-lab1-part1-host3 host3 host2 test-pkt3

# host1 to host3
run_onepkt clab-lab1-part1-host1 host1 host3 test-pkt4

# host4 to all
run_onepkt clab-lab1-part1-host4 host4 all_hosts test-pkt5

sleep 10s

# Stop captures
kill $(cat /tmp/tshark_pids) 2>/dev/null
rm -f /tmp/tshark_pids

sudo containerlab destroy

mkdir submission
mv lab-host1/h1.pcap ./submission
mv lab-host2/h2.pcap ./submission
mv lab-host3/h3.pcap ./submission
mv lab-host4/h4.pcap ./submission
tar czf submission.tgz ./submission
