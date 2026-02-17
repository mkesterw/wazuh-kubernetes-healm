# Guia de Instalação Rápida - Wazuh Helm Chart

## 📋 Pré-requisitos

```bash
# Verificar versão do Kubernetes
kubectl version --short

# Verificar versão do Helm
helm version --short

# Verificar nodes disponíveis
kubectl get nodes
```

## 🚀 Instalação

### 1. Clone ou baixe o Helm Chart

```bash
# Se estiver em um repositório Git
git clone <repository-url>
cd wazuh-helm-chart

# Ou extraia o arquivo .tgz se você recebeu um pacote
tar -xzf wazuh-4.14.1.tgz
cd wazuh
```

### 2. Escolha seus valores

```bash
# Para ambiente local (Minikube, Kind, k3s)
cp values-local.yaml my-values.yaml

# Para AWS EKS
cp values-eks.yaml my-values.yaml

# Para produção personalizada
cp values.yaml my-values.yaml
```

### 3. IMPORTANTE: Altere as senhas padrão

```bash
# Gerar nova senha
echo -n "MinhaS3nh4S3gur4" | base64

# Edite my-values.yaml e substitua os valores em secrets.*
nano my-values.yaml
```

### 4. Instale o Helm Chart

```bash
# Criar namespace (se não existir)
kubectl create namespace wazuh

# Instalar
helm install wazuh . \
  --namespace wazuh \
  --values my-values.yaml \
  --timeout 10m

# Ou para ambientes específicos:
# helm install wazuh . -f values-local.yaml -n wazuh --create-namespace
```

### 5. Verifique a instalação

```bash
# Ver todos os pods
kubectl get pods -n wazuh -w

# Aguardar até que todos estejam Running
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=wazuh -n wazuh --timeout=600s

# Ver todos os recursos
kubectl get all -n wazuh
```

## 🌐 Acessar o Dashboard

### Método 1: LoadBalancer (AWS EKS)

```bash
# Obter IP externo
kubectl get svc wazuh-dashboard -n wazuh

# Acessar
https://<EXTERNAL-IP>:443
```

### Método 2: NodePort (Local)

```bash
# Obter porta
export NODE_PORT=$(kubectl get svc wazuh-dashboard -n wazuh -o jsonpath='{.spec.ports[0].nodePort}')
export NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')

# Se não houver IP externo (Minikube)
export NODE_IP=$(minikube ip)

# Acessar
echo "https://$NODE_IP:$NODE_PORT"
```

### Método 3: Port Forward

```bash
# Criar túnel
kubectl port-forward svc/wazuh-dashboard 8443:443 -n wazuh

# Acessar
https://localhost:8443
```

## 🔑 Credenciais de Login

```bash
# Usuário padrão
Username: admin

# Obter senha (decodificar base64)
kubectl get secret indexer-cred -n wazuh -o jsonpath='{.data.password}' | base64 -d
echo
```

## 🔧 Troubleshooting

### Pods não estão iniciando

```bash
# Ver detalhes do pod
kubectl describe pod <pod-name> -n wazuh

# Ver logs
kubectl logs <pod-name> -n wazuh

# Ver eventos
kubectl get events -n wazuh --sort-by='.lastTimestamp'
```

### Erro de recursos insuficientes

```bash
# Ver uso de recursos
kubectl top nodes
kubectl top pods -n wazuh

# Reduzir recursos no values.yaml ou adicionar mais nodes ao cluster
```

### PVC pendente

```bash
# Verificar PVCs
kubectl get pvc -n wazuh

# Verificar StorageClass
kubectl get sc

# Se necessário, criar StorageClass
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF
```

### Indexer não conecta

```bash
# Verificar logs do indexer
kubectl logs wazuh-indexer-0 -n wazuh

# Verificar conectividade
kubectl exec -it wazuh-indexer-0 -n wazuh -- curl -k https://localhost:9200

# Verificar certificados
kubectl get secret indexer-certs -n wazuh -o yaml
```

## 📊 Comandos Úteis

```bash
# Status da release
helm status wazuh -n wazuh

# Ver valores aplicados
helm get values wazuh -n wazuh

# Ver todos os recursos criados
helm get manifest wazuh -n wazuh

# Upgrade
helm upgrade wazuh . -f my-values.yaml -n wazuh

# Rollback
helm rollback wazuh <revision> -n wazuh

# Histórico
helm history wazuh -n wazuh

# Desinstalar
helm uninstall wazuh -n wazuh

# Desinstalar e remover PVCs
helm uninstall wazuh -n wazuh
kubectl delete pvc -l app.kubernetes.io/instance=wazuh -n wazuh
```

## 🔗 Conectar Agentes

### Obter IP do Manager

```bash
# LoadBalancer
kubectl get svc wazuh-master-svc -n wazuh

# NodePort
kubectl get svc wazuh-master-svc -n wazuh -o jsonpath='{.spec.ports[0].nodePort}'
```

### Obter senha de enrollment

```bash
kubectl get secret wazuh-authd-pass -n wazuh -o jsonpath='{.data.authd\.pass}' | base64 -d
echo
```

### Comandos de registro do agente

```bash
# Linux
WAZUH_MANAGER="<MANAGER-IP>" \
WAZUH_REGISTRATION_PASSWORD="<PASSWORD>" \
apt-get install wazuh-agent

# Windows
Invoke-WebRequest -Uri https://packages.wazuh.com/4.x/windows/wazuh-agent-4.14.1-1.msi -OutFile wazuh-agent.msi
msiexec /i wazuh-agent.msi /q WAZUH_MANAGER="<MANAGER-IP>" WAZUH_REGISTRATION_PASSWORD="<PASSWORD>"
```

## 📖 Próximos Passos

1. Acesse o Dashboard e altere a senha do usuário admin
2. Configure agentes para conectar aos managers
3. Explore os dashboards e visualizações
4. Configure alertas e integrações
5. Revise a documentação oficial: https://documentation.wazuh.com/

## 🆘 Suporte

- Documentação: https://documentation.wazuh.com/
- GitHub Issues: https://github.com/wazuh/wazuh-kubernetes/issues
- Slack: https://wazuh.com/community/join-us-on-slack/
- Google Groups: https://groups.google.com/forum/#!forum/wazuh
