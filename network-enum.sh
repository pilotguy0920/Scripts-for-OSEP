#!/bin/bash
# Purpose: Enumerate the network

# Usage check
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 scope.txt"
    exit 1
fi

# File existence check
FILE=$1
if [ ! -f "$FILE" ]; then
    echo "File not found: $FILE"
    exit 1
fi

# Ping sweep function
ping_sweep() {
    echo "Starting Ping Sweep - $(date)"
    > active_hosts.txt
    while read -r line; do
        sudo nmap -sn "$line" -oG - | awk '/Up$/{print $2}' | tee -a active_hosts.txt
    done < "$FILE"
}

# Port scanning function
port_scan() {
    local ip=$1
    echo # Newline
    echo "Starting Nmap -p- Scan on $ip - $(date)"
    local ports=$(sudo nmap -p- -Pn --open --min-rate=1000 -T4 $ip | grep '^[0-9]' | cut -d '/' -f 1 | tr '\n' ',' | sed s/,$//)
    
    if [ -z "$ports" ]; then
        echo "No open ports found on $ip"
        return
    fi

    # Create directory for Nmap scans if it doesn't exist
    [ ! -d "./data/nmap" ] && mkdir -p ./data/nmap

    sudo nmap -sCV -p$ports $ip -Pn -oA ./data/nmap/$ip-nmap-scan
}

# Function to process nmap XML files with gowitness
gowitness_process() {
    echo # Newline
    echo "Starting Gowitness Processing - $(date)"
    for xml_file in ./data/nmap/*.xml; do
        gowitness nmap -f "$xml_file" --service-contains http
    done
}

# Perform ping sweep
ping_sweep

# Check if any hosts are active
if [ ! -s active_hosts.txt ]; then
    echo "No Hosts Up"
    exit 1
fi

# Perform port scan on active hosts
while read -r ip; do
    port_scan "$ip"
done < active_hosts.txt

# Process the nmap XML files with gowitness
gowitness_process
