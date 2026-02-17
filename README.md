# Wazuh Kubernetes Helm

This repository contains Helm charts for deploying Wazuh in a Kubernetes cluster.

## Installation

To install the Wazuh module, use the following command:

```bash
helm install my-release wazuh/wazuh
```

## Configuration

Configure the Helm chart values in `values.yaml`. Here are some configuration options:

- `replicaCount`: The number of Wazuh Pods.
- `service.type`: The type of service (e.g., ClusterIP, LoadBalancer).

## Troubleshooting

If you run into issues, check the logs of the Wazuh Pods:

```bash
kubectl logs -f <pod-name>
```

For more information, please refer to the [Wazuh Documentation](https://documentation.wazuh.com/).