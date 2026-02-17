# 🐄 Guia de Instalação via Rancher

Este guia é específico para instalação do Wazuh Helm Chart através do Rancher.

## 🚨 Problema Comum: StorageClass já existe

Se você receber o erro:
```
Error: INSTALLATION FAILED: Unable to continue with install: StorageClass "gp2" in namespace "" exists 
and cannot be imported into the current release
```

**Solução:** O StorageClass já existe no cluster. Use o arquivo `values-rancher.yaml` que não tenta criar recursos que já existem.

## 📋 Pré-requisitos

1. ✅ Acesso ao Rancher UI
2. ✅ Cluster Kubernetes configurado
3. ✅ StorageClass "gp2" (ou outro) já disponível no cluster
4. ✅ Mínimo de 8GB RAM e 4 vCPUs disponíveis

## 🚀 Instalação via Rancher UI

### Opção 1: Via Rancher Apps & Marketplace

1. **Acesse seu cluster no Rancher**
   - Dashboard → Selecione seu cluster

2. **Vá para Apps & Marketplace**
   - Menu lateral → Apps & Marketplace

3. **Import Chart**
   - Click em "Chart Repositories"
   - Add Repository (se quiser hospedar)
   - Ou use "Install from Local File"

4. **Configure a instalação**
   - Name: `ngsoc-central` (ou o nome desejado)
   - Namespace: `default` (ou crie um novo)
   - Upload o arquivo: `wazuh-helm-chart-4.14.1.tgz`

5. **Configure os Values**
   - Cole o conteúdo de `values-rancher.yaml`
   - Ou edite os valores diretamente na UI

### Opção 2: Via Rancher CLI / kubectl

```bash
# 1. Fazer login no Rancher CLI
rancher login https://your-rancher-url --token your-token

# 2. Selecionar o cluster
rancher context switch

# 3. Instalar via Helm através do Rancher
helm install ngsoc-central ./wazuh-helm-chart-4.14.1.tgz \
  --namespace default \
  --values values-rancher.yaml \
  --timeout 10m \
  --wait
```

## 📝 Arquivo values-rancher.yaml

Use este arquivo que já está configurado para não criar recursos existentes:

```yaml
global:
  namespace: default          # Namespace onde instalar
  createNamespace: false      # Não criar namespace (já existe)
  storageClass: gp2          # Usar StorageClass existente
  createStorageClass: false   # Não tentar criar (já existe!)

wazuhManager:
  master:
    persistence:
      enabled: true
      size: 10Gi
  worker:
    replicas: 2
    persistence:
      enabled: true
      size: 10Gi

wazuhIndexer:
  replicas: 3
  persistence:
    enabled: true
    size: 50Gi

wazuhDashboard:
  service:
    type: LoadBalancer

# IMPORTANTE: Altere as senhas!
secrets:
  wazuhApi:
    password: "<SEU-PASSWORD-BASE64>"
  indexer:
    password: "<SEU-PASSWORD-BASE64>"
  # ... demais senhas
```

## 🔧 Solução de Problemas Comuns

### Erro: StorageClass já existe

**Causa:** O chart está tentando criar um StorageClass que já existe.

**Solução:**
```yaml
global:
  createStorageClass: false  # Adicione isso no values
  storageClass: gp2         # Use o StorageClass existente
```

### Erro: Namespace já existe

**Causa:** O chart está tentando criar um namespace que já existe.

**Solução:**
```yaml
global:
  createNamespace: false  # Adicione isso no values
  namespace: default      # Use namespace existente
```

### Erro: Timeout waiting for pods

**Causa:** Pods levam tempo para iniciar ou há problemas de recursos.

**Solução:**
```bash
# Aumentar timeout
--timeout 15m

# Verificar pods
kubectl get pods -n default -w

# Ver logs
kubectl logs -f <pod-name> -n default

# Ver eventos
kubectl get events -n default --sort-by='.lastTimestamp'
```

### Erro: PVC Pending

**Causa:** StorageClass não configurado ou sem provisioner.

**Solução:**
```bash
# Verificar StorageClass disponível
kubectl get sc

# Verificar PVCs
kubectl get pvc -n default

# Se necessário, usar outro StorageClass
global:
  storageClass: standard  # ou outro disponível
```

## 🔑 Alterar Senhas Padrão

**IMPORTANTE:** Sempre altere as senhas antes de produção!

```bash
# Gerar senha em base64
echo -n "MinhaS3nh4F0rt3" | base64
# Output: TWluaGFTM25oNEYwcnQz

# Atualizar no values-rancher.yaml
secrets:
  wazuhApi:
    password: "TWluaGFTM25oNEYwcnQz"
```

## 🌐 Acessar o Dashboard

### Pelo Rancher UI

1. Vá para **Workloads → Services**
2. Encontre `wazuh-dashboard`
3. Click no endpoint do LoadBalancer
4. Acesso via `https://<EXTERNAL-IP>:443`

### Via kubectl

```bash
# Obter IP do LoadBalancer
kubectl get svc wazuh-dashboard -n default

# Obter senha para login
kubectl get secret indexer-cred -n default -o jsonpath='{.data.password}' | base64 -d
```

**Credenciais:**
- Usuário: `admin`
- Senha: (decodificar o password do secret indexer-cred)

## 📊 Monitoramento via Rancher

1. **Workloads → Pods**
   - Ver status de todos os pods
   - Acessar logs diretamente

2. **Service Discovery → Services**
   - Ver endpoints dos serviços
   - Testar conectividade

3. **Storage → PersistentVolumeClaims**
   - Verificar uso de storage
   - Ver status dos volumes

## 🔄 Upgrade via Rancher

```bash
helm upgrade ngsoc-central ./wazuh-helm-chart-4.14.1.tgz \
  --namespace default \
  --values values-rancher.yaml \
  --timeout 10m \
  --wait
```

Ou via Rancher UI:
1. Apps & Marketplace → Installed Apps
2. Selecione `ngsoc-central`
3. Click em "Upgrade"
4. Modifique os values se necessário
5. Click em "Upgrade"

## 🗑️ Desinstalação

```bash
# Via Helm
helm uninstall ngsoc-central -n default

# Remover PVCs (cuidado - apaga dados!)
kubectl delete pvc -l app.kubernetes.io/instance=ngsoc-central -n default
```

Ou via Rancher UI:
1. Apps & Marketplace → Installed Apps
2. Selecione `ngsoc-central`
3. Click em "Delete"

## 📞 Comandos Úteis para Debug

```bash
# Ver todos os recursos criados
kubectl get all -l app.kubernetes.io/instance=ngsoc-central -n default

# Ver secrets
kubectl get secrets -n default | grep ngsoc

# Ver configmaps
kubectl get configmaps -n default | grep wazuh

# Ver logs de um pod específico
kubectl logs -f wazuh-manager-master-0 -n default

# Descrever um pod com problemas
kubectl describe pod <pod-name> -n default

# Ver uso de recursos
kubectl top pods -n default

# Port forward para testar localmente
kubectl port-forward svc/wazuh-dashboard 8443:443 -n default
```

## ✅ Checklist de Instalação

- [ ] StorageClass "gp2" existe no cluster
- [ ] Arquivo `values-rancher.yaml` configurado
- [ ] Senhas alteradas no values
- [ ] Chart instalado via Helm
- [ ] Todos os pods em estado Running
- [ ] Dashboard acessível via LoadBalancer
- [ ] Login funcionando com credenciais
- [ ] Agentes podem se conectar aos managers

## 📚 Próximos Passos

1. ✅ Acessar o Dashboard
2. ✅ Alterar senha do usuário admin
3. ✅ Configurar agentes
4. ✅ Configurar alertas
5. ✅ Integrar com suas ferramentas

## 🆘 Suporte

- Documentação Wazuh: https://documentation.wazuh.com/
- Rancher Docs: https://rancher.com/docs/
- GitHub Issues: https://github.com/wazuh/wazuh-kubernetes/issues
