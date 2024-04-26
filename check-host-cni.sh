#!/bin/bash

# Get the hostname of the node where the script is being run
current_node=$(hostname)

# Get the list of node names from the Kubernetes cluster
nodes=$(kubectl get nodes --no-headers -o custom-columns=":metadata.name")

echo "Gathering network information for all nodes..."
echo "--------------------------------------------------"

# Loop through each node to gather network information. Assumes passwordless ssh between the nodes
for node in $nodes; do
    echo "Node: $node"
    if [ "$node" == "$current_node" ]; then
        echo "Host Network Interfaces and IPs (local):"
        ip -brief addr
    else
        echo "Host Network Interfaces and IPs (remote):"
        ssh "$node" 'ip -brief addr'
    fi
    echo "Pod CIDR for $node:"
    kubectl get node "$node" -o jsonpath='{.spec.podCIDR}'
    echo ""
    echo "--------------------------------------------------"
done

echo "Kubernetes Cluster IP Information:"
echo "--------------------------------------------------"

# Fetch Service Network CIDR from the kube-apiserver component
svc_network_cidr=$(kubectl get pods -n kube-system -l component=kube-apiserver -o jsonpath='{.items[*].spec.containers[*].command}' | grep -o -- '--service-cluster-ip-range=[^ ]*' | cut -d= -f2 | tr -d '",')

# Get DNS service IP
dns_service_ip=$(kubectl get svc -n kube-system kube-dns -o jsonpath='{.spec.clusterIP}')
echo "Service Network CIDR: ${svc_network_cidr:-'Not Found'}"
echo "Cluster DNS Service IP: $dns_service_ip"

echo "--------------------------------------------------"
echo "Network information gathering complete."
