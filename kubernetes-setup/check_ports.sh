#!/bin/bash

ports=(6443 2379 2380 10250 10251 10252)
host="127.0.0.1"

for port in "${ports[@]}"; do
    if nc -zv $host $port 2>/dev/null; then
        echo "Port $port is in use"
    else
        echo "Port $port is available"
    fi
done
