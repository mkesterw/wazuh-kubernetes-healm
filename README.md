# Wazuh Helm Chart

Este Helm Chart permite a implantação do Wazuh - uma plataforma de segurança open source - em clusters Kubernetes.

## 📋 Pré-requisitos

- Kubernetes 1.19+
- Helm 3.0+
- PV provisioner support no cluster
- Storage Class configurado (ex: gp2 para AWS EKS)
- Mínimo de 8GB de RAM disponível no cluster
- Mínimo de 4 vCPUs

## 🚀 Instalação Rápida

### 1. Adicionar o repositório (se publicado)

```bash
helm repo add wazuh https://wazuh.github.io/helm-charts
helm repo update
```

### 2. Instalar o chart

```bash
# Instalação básica com valores padrão
helm install wazuh wazuh/wazuh --namespace wazuh --create-namespace

# Instalação com valores customizados
helm install wazuh wazuh/wazuh \
  --namespace wazuh \
  --create-namespace \
  --values custom-values.yaml
```

### 3. Instalar localmente (desenvolvimento)

```bash
# Clone o repositório
git clone https://github.com/seu-usuario/wazuh-helm-chart.git
cd wazuh-helm-chart

# Instalar o chart
helm install wazuh . --namespace wazuh --create-namespace
```

## 📦 Componentes

Este chart instala os seguintes componentes:

- **Wazuh Manager Master** (1 replica): Gerencia a infraestrutura, API e registro de agentes
- **Wazuh Manager Workers** (2 replicas padrão): Processa eventos dos agentes
- **Wazuh Indexer** (3 replicas padrão): Cluster OpenSearch para armazenamento de dados
- **Wazuh Dashboard** (1 replica): Interface web para visualização e análise

## ⚙️ Configuração

### Valores principais

| Parâmetro | Descrição | Valor Padrão |
|-----------|-----------|--------------|
| `global.namespace` | Namespace do Kubernetes | `wazuh` |
| `global.storageClass` | Storage class para PVs | `gp2` |
| `wazuhManager.master.replicas` | Número de replicas do master | `1` |
| `wazuhManager.worker.replicas` | Número de replicas dos workers | `2` |
| `wazuhIndexer.replicas` | Número de replicas do indexer | `3` |
| `wazuhDashboard.replicas` | Número de replicas do dashboard | `1` |

### Exemplo de customização

Crie um arquivo `custom-values.yaml`:

```yaml
global:
  namespace: wazuh-prod
  storageClass: fast-ssd

wazuhManager:
  worker:
    replicas: 3
    resources:
      limits:
        cpu: 800m
        memory: 1Gi
      requests:
        cpu: 400m
        memory: 512Mi

wazuhIndexer:
  replicas: 3
  resources:
    limits:
      cpu: 1000m
      memory: 2Gi
    requests:
      cpu: 500m
      memory: 2Gi
  opensearchConfig:
    javaOpts: "-Xms1g -Xmx1g"

wazuhDashboard:
  ingress:
    enabled: true
    className: nginx
    hosts:
      - host: wazuh.example.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - secretName: wazuh-tls
        hosts:
          - wazuh.example.com

secrets:
  # Altere as senhas padrão!
  wazuhApi:
    password: "<base64-encoded-password>"
  indexer:
    password: "<base64-encoded-password>"
```

Instale com seus valores customizados:

```bash
helm install wazuh . -f custom-values.yaml --namespace wazuh --create-namespace
```

## 🔐 Segurança

### Alterar senhas padrão

**IMPORTANTE**: Altere todas as senhas padrão antes de usar em produção!

```bash
# Gerar senha codificada em base64
echo -n "MinhaS3nh4F0rt3" | base64
```

Atualize no arquivo `custom-values.yaml`:

```yaml
secrets:
  wazuhApi:
    username: "wazuh-wui"
    password: "TWluaGFTM25oNEYwcnQz"  # base64 encoded
  wazuhAuthd:
    password: "U3VwM3JTM2N1cmUh"  # base64 encoded
  wazuhCluster:
    key: "YzM0OGUzZTJmNTZlNGY0MmE1YzQyZjE1Yjg3YTFiNzU="
  dashboard:
    username: "kibanaserver"
    password: "RGFzaGIwYXJkUGFzcyE="
  indexer:
    username: "admin"
    password: "SW5kM3hlclBhc3Mh"
```

### Certificados TLS

Por padrão, o chart gera certificados autoassinados. Para produção:

1. Gere certificados válidos usando suas ferramentas preferidas
2. Crie secrets do Kubernetes:

```bash
kubectl create secret generic indexer-certs \
  --from-file=node-key.pem \
  --from-file=node.pem \
  --from-file=root-ca.pem \
  --from-file=admin-key.pem \
  --from-file=admin.pem \
  -n wazuh

kubectl create secret generic dashboard-certs \
  --from-file=cert.pem \
  --from-file=key.pem \
  --from-file=root-ca.pem \
  -n wazuh
```

3. Desabilite a geração automática:

```yaml
certificates:
  generate: false
```

## 🌐 Acesso ao Dashboard

### Via LoadBalancer

```bash
# Obter o endereço do LoadBalancer
kubectl get svc wazuh-dashboard -n wazuh

# Acessar via navegador
https://<EXTERNAL-IP>:443
```

### Via NodePort

```yaml
wazuhDashboard:
  service:
    type: NodePort
    port: 443
```

```bash
# Obter a porta
kubectl get svc wazuh-dashboard -n wazuh

# Acessar
https://<NODE-IP>:<NODE-PORT>
```

### Via Ingress

```yaml
wazuhDashboard:
  ingress:
    enabled: true
    className: nginx
    hosts:
      - host: wazuh.example.com
        paths:
          - path: /
            pathType: Prefix
```

### Credenciais padrão

- **Usuário**: admin
- **Senha**: A senha configurada em `secrets.indexer.password` (decodificada de base64)

## 📊 Monitoramento

### Verificar status dos pods

```bash
kubectl get pods -n wazuh
```

### Ver logs

```bash
# Manager Master
kubectl logs -f wazuh-manager-master-0 -n wazuh

# Manager Worker
kubectl logs -f wazuh-manager-worker-0 -n wazuh

# Indexer
kubectl logs -f wazuh-indexer-0 -n wazuh

# Dashboard
kubectl logs -f deployment/wazuh-dashboard -n wazuh
```

### Verificar recursos

```bash
kubectl top pods -n wazuh
kubectl describe pod <pod-name> -n wazuh
```

## 🔄 Upgrade

```bash
# Fazer upgrade para nova versão
helm upgrade wazuh . \
  --namespace wazuh \
  --values custom-values.yaml

# Verificar histórico
helm history wazuh -n wazuh

# Rollback se necessário
helm rollback wazuh <revision> -n wazuh
```

## 🗑️ Desinstalação

```bash
# Remover a instalação
helm uninstall wazuh -n wazuh

# Remover PVCs (dados persistentes)
kubectl delete pvc -l app.kubernetes.io/instance=wazuh -n wazuh

# Remover namespace
kubectl delete namespace wazuh
```

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────┐
│                 Wazuh Dashboard                  │
│                 (LoadBalancer)                   │
└────────────────────┬────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
┌────────▼──────────┐  ┌────────▼──────────┐
│  Wazuh Manager    │  │  Wazuh Indexer    │
│     Master        │  │   (Cluster 3x)    │
│   (StatefulSet)   │  │  (StatefulSet)    │
└────────┬──────────┘  └───────────────────┘
         │
         │ Cluster Communication
         │
┌────────▼──────────┐
│  Wazuh Manager    │
│     Workers       │
│  (StatefulSet 2x) │
└───────────────────┘
         │
         │ Agent Events
         │
    ┌────▼────┐
    │ Agents  │
    └─────────┘
```

## 🧪 Ambientes

### Desenvolvimento Local (Minikube/Kind)

```yaml
global:
  storageClass: standard

wazuhManager:
  worker:
    replicas: 1
  master:
    resources:
      limits:
        cpu: 200m
        memory: 256Mi

wazuhIndexer:
  replicas: 1
  resources:
    limits:
      cpu: 200m
      memory: 512Mi

wazuhDashboard:
  service:
    type: NodePort
```

### AWS EKS

```yaml
global:
  storageClass: gp2

wazuhManager:
  master:
    service:
      type: LoadBalancer
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
        service.beta.kubernetes.io/aws-load-balancer-internal: "true"

wazuhDashboard:
  service:
    type: LoadBalancer
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
```

## 📝 Notas Importantes

1. **Recursos mínimos**: Certifique-se de que seu cluster tem recursos suficientes
2. **Storage**: Configure um StorageClass apropriado antes da instalação
3. **Segurança**: Sempre altere as senhas padrão em ambientes de produção
4. **Backup**: Implemente estratégias de backup para os PVCs
5. **Monitoramento**: Configure alertas para os componentes críticos

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Fork o repositório
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📄 Licença

GPL-2.0 License - veja o arquivo LICENSE para detalhes

## 🔗 Links Úteis

- [Documentação Oficial do Wazuh](https://documentation.wazuh.com/)
- [Repositório Wazuh Kubernetes](https://github.com/wazuh/wazuh-kubernetes)
- [Wazuh Docker](https://github.com/wazuh/wazuh-docker)
- [Comunidade Wazuh](https://wazuh.com/community/)

## 💬 Suporte

- [Slack da Comunidade](https://wazuh.com/community/join-us-on-slack/)
- [Google Groups](https://groups.google.com/forum/#!forum/wazuh)
- [GitHub Issues](https://github.com/wazuh/wazuh-kubernetes/issues)
