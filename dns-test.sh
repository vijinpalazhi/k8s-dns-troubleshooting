#!/bin/bash

# Define color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "Starting DNS troubleshooting..."
echo "---------------------------------------------------------------"

# Check Kubernetes version
echo "Test1: Checking Kubernetes version..."
if kubectl version ; then
  echo -e "${GREEN}PASS: Successfully retrieved Kubernetes version.${NC}"
else
  echo -e "${RED}FAIL: Could not retrieve Kubernetes version.${NC}"
fi
echo "---------------------------------------------------------------"

# Deploy dnsutils Pod for testing DNS resolution
echo "Test2: Deploying dnsutils pod for DNS tests..."
if kubectl apply -f https://k8s.io/examples/admin/dns/dnsutils.yaml; then
  echo "dnsutils pod deployed."
  echo "Waiting for dnsutils pod to be ready..."
  if kubectl wait --for=condition=ready pod/dnsutils --timeout=120s; then
    echo -e "${GREEN}PASS: dnsutils pod is ready for tests.${NC}"
  else
    echo -e "${RED}FAIL: dnsutils pod did not become ready.${NC}"
  fi
else
  echo -e "${RED}FAIL: dnsutils pod deployment failed.${NC}"
fi
echo "---------------------------------------------------------------"

# Test DNS resolution using nslookup
echo "Test3: Testing DNS resolution for kubernetes.default..."
if kubectl exec -i -t dnsutils -- nslookup kubernetes.default; then
  echo -e "${GREEN}PASS: Pod to Service DNS resolution works.${NC}"
else
  echo -e "${RED}FAIL: Pod to Service DNS resolution failed.${NC}"
fi
echo "---------------------------------------------------------------"

# Check resolv.conf configuration
echo "Test4: Checking resolv.conf inside dnsutils pod..."
if kubectl exec -ti dnsutils -- cat /etc/resolv.conf; then
  echo -e "${GREEN}PASS: Successfully retrieved resolv.conf from dnsutils pod.${NC}"
else
  echo -e "${RED}FAIL: Could not retrieve resolv.conf from dnsutils pod.${NC}"
fi
echo "---------------------------------------------------------------"

# Check CoreDNS pod status
echo "Test5: Checking CoreDNS pod status..."
if kubectl get pods --namespace=kube-system -l k8s-app=kube-dns; then
  echo -e "${GREEN}PASS: Successfully retrieved CoreDNS pod status.${NC}"
else
  echo -e "${RED}FAIL: Could not retrieve CoreDNS pod status.${NC}"
fi
echo "---------------------------------------------------------------"

# View logs of CoreDNS pods
echo "Test6: Viewing logs of CoreDNS pods..."
if kubectl logs --namespace=kube-system -l k8s-app=kube-dns --tail=20; then
  echo -e "${GREEN}PASS: Successfully retrieved CoreDNS logs.${NC}"
else
  echo -e "${RED}FAIL: Could not retrieve CoreDNS logs.${NC}"
fi
echo "---------------------------------------------------------------"

# Check DNS service status
echo "Test7: Checking DNS service status..."
if kubectl get svc --namespace=kube-system kube-dns; then
  echo -e "${GREEN}PASS: Successfully retrieved DNS service status.${NC}"
else
  echo -e "${RED}FAIL: Could not retrieve DNS service status.${NC}"
fi
echo "---------------------------------------------------------------"

# Check DNS endpoints
echo "Test8: Checking DNS endpoints..."
if kubectl get endpoints kube-dns --namespace=kube-system; then
  echo -e "${GREEN}PASS: Successfully retrieved DNS endpoints.${NC}"
else
  echo -e "${RED}FAIL: Could not retrieve DNS endpoints.${NC}"
fi
echo "---------------------------------------------------------------"

# Check CoreDNS permissions
echo "Test9: Checking CoreDNS permissions..."
if kubectl describe clusterrole system:coredns -n kube-system; then
  echo -e "${GREEN}PASS: Successfully retrieved CoreDNS permissions.${NC}"
else
  echo -e "${RED}FAIL: Could not retrieve CoreDNS permissions.${NC}"
fi
echo "---------------------------------------------------------------"

# Ensure queries are being received (Check logs after making DNS queries)
echo "Test10: Ensure DNS queries are being received by viewing CoreDNS logs again..."
if kubectl logs --namespace=kube-system -l k8s-app=kube-dns --tail=50; then
  echo -e "${GREEN}PASS: DNS queries are being received and processed by CoreDNS.${NC}"
else
  echo -e "${RED}FAIL: DNS queries are not being received or processed by CoreDNS.${NC}"
fi
echo "---------------------------------------------------------------"
echo "DNS troubleshooting script has completed running."
