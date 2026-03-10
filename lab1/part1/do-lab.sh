#!/usr/bin/bash

# INCLUDE ALL COMMANDS NEEDED TO PERFORM THE LAB
# This file will get called from capture_submission.sh

docker exec -it clab-lab1-part1-switch ip link add name labbridge type bridge
docker exec -it clab-lab1-part1-switch ip link set labbridge up
docker exec -it clab-lab1-part1-switch ip link set eth1 master labbridge
docker exec -it clab-lab1-part1-switch ip link set eth2 master labbridge
docker exec -it clab-lab1-part1-switch ip link set eth3 master labbridge
docker exec -it clab-lab1-part1-switch ip link set eth4 master labbridge