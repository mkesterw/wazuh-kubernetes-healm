#!/bin/bash
# Script to generate SSL certificates for Wazuh

set -e

CERT_DIR="./wazuh-certificates"
NAMESPACE=${1:-wazuh}

echo "=== Wazuh Certificate Generator ==="
echo "Namespace: $NAMESPACE"
echo "Certificate directory: $CERT_DIR"
echo

# Create certificate directory
mkdir -p "$CERT_DIR"
cd "$CERT_DIR"

# Generate Root CA
echo "[1/5] Generating Root CA..."
openssl genrsa -out root-ca-key.pem 2048
openssl req -new -x509 -sha256 -key root-ca-key.pem -out root-ca.pem -days 3650 \
    -subj "/C=US/ST=California/L=California/O=Wazuh/OU=Wazuh/CN=root-ca"

# Generate Admin certificate
echo "[2/5] Generating Admin certificate..."
openssl genrsa -out admin-key.pem 2048
openssl req -new -key admin-key.pem -out admin.csr \
    -subj "/C=US/ST=California/L=California/O=Wazuh/OU=Wazuh/CN=admin"
openssl x509 -req -in admin.csr -CA root-ca.pem -CAkey root-ca-key.pem \
    -CAcreateserial -out admin.pem -days 3650 -sha256

# Generate Indexer node certificate
echo "[3/5] Generating Indexer node certificate..."
openssl genrsa -out node-key.pem 2048
openssl req -new -key node-key.pem -out node.csr \
    -subj "/C=US/ST=California/L=California/O=Wazuh/OU=Wazuh/CN=wazuh-indexer"

cat > node.ext << EOF
subjectAltName = DNS:wazuh-indexer,DNS:wazuh-indexer-0,DNS:wazuh-indexer-1,DNS:wazuh-indexer-2,DNS:wazuh-indexer.${NAMESPACE}.svc.cluster.local,DNS:wazuh-indexer-0.wazuh-indexer.${NAMESPACE}.svc.cluster.local,DNS:wazuh-indexer-1.wazuh-indexer.${NAMESPACE}.svc.cluster.local,DNS:wazuh-indexer-2.wazuh-indexer.${NAMESPACE}.svc.cluster.local,DNS:localhost,IP:127.0.0.1
EOF

openssl x509 -req -in node.csr -CA root-ca.pem -CAkey root-ca-key.pem \
    -CAcreateserial -out node.pem -days 3650 -sha256 -extfile node.ext

# Generate Filebeat certificate
echo "[4/5] Generating Filebeat certificate..."
openssl genrsa -out filebeat-key.pem 2048
openssl req -new -key filebeat-key.pem -out filebeat.csr \
    -subj "/C=US/ST=California/L=California/O=Wazuh/OU=Wazuh/CN=filebeat"
openssl x509 -req -in filebeat.csr -CA root-ca.pem -CAkey root-ca-key.pem \
    -CAcreateserial -out filebeat.pem -days 3650 -sha256

# Generate Dashboard certificate
echo "[5/5] Generating Dashboard certificate..."
openssl genrsa -out dashboard-key.pem 2048
openssl req -new -key dashboard-key.pem -out dashboard.csr \
    -subj "/C=US/ST=California/L=California/O=Wazuh/OU=Wazuh/CN=wazuh-dashboard"

cat > dashboard.ext << EOF
subjectAltName = DNS:wazuh-dashboard,DNS:wazuh-dashboard.${NAMESPACE}.svc.cluster.local,DNS:localhost,IP:127.0.0.1
EOF

openssl x509 -req -in dashboard.csr -CA root-ca.pem -CAkey root-ca-key.pem \
    -CAcreateserial -out dashboard.pem -days 3650 -sha256 -extfile dashboard.ext

# Clean up CSR and extension files
rm -f *.csr *.ext *.srl

echo
echo "=== Certificates generated successfully! ==="
echo
echo "Creating Kubernetes secrets..."

# Create indexer certificates secret
kubectl create secret generic indexer-certs \
    --from-file=root-ca.pem \
    --from-file=node.pem \
    --from-file=node-key.pem \
    --from-file=admin.pem \
    --from-file=admin-key.pem \
    --from-file=filebeat.pem \
    --from-file=filebeat-key.pem \
    --namespace "$NAMESPACE" \
    --dry-run=client -o yaml > ../indexer-certs-secret.yaml

echo "Created: indexer-certs-secret.yaml"

# Create dashboard certificates secret
kubectl create secret generic dashboard-certs \
    --from-file=cert.pem=dashboard.pem \
    --from-file=key.pem=dashboard-key.pem \
    --from-file=root-ca.pem \
    --namespace "$NAMESPACE" \
    --dry-run=client -o yaml > ../dashboard-certs-secret.yaml

echo "Created: dashboard-certs-secret.yaml"

cd ..

echo
echo "=== Setup complete! ==="
echo
echo "To apply the secrets to your cluster:"
echo "  kubectl apply -f indexer-certs-secret.yaml"
echo "  kubectl apply -f dashboard-certs-secret.yaml"
echo
echo "Or include them in your Helm installation."
