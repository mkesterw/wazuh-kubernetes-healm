# 🐄 Instalação via Rancher UI - Guia Completo

## ✅ Problema Resolvido: Namespace

Esta versão do chart foi **especialmente ajustada** para funcionar perfeitamente com o Rancher UI, respeitando o namespace que você escolher na interface.

## 🎯 Características desta versão:

- ✅ **Respeita o namespace** escolhido no Rancher UI
- ✅ **Não cria recursos existentes** (StorageClass, Namespace)
- ✅ **Configuração padrão otimizada** para Rancher
- ✅ **Compatível com seleção de namespace** na UI

## 📋 Pré-requisitos

1. Acesso ao Rancher UI
2. Cluster Kubernetes ativo
3. StorageClass disponível (geralmente `gp2` na AWS)
4. Pelo menos 8GB RAM e 4 vCPUs disponíveis

## 🚀 Instalação Passo a Passo

### Passo 1: Upload do Chart

1. **Acesse o Rancher UI**
   - Faça login em seu Rancher
   - Selecione o cluster desejado

2. **Vá para Apps & Marketplace**
   - Menu lateral → **Apps** → **Charts**
   - Ou **Apps & Marketplace** → **Charts**

3. **Adicione o Chart**
   - Click em **⋮** (três pontos) no canto superior direito
   - Selecione **Import YAML** ou **Install from Local File**
   - Faça upload de: `wazuh-helm-chart-4.14.1-rancher.tgz`

### Passo 2: Configuração Inicial (Metadata)

Na tela "Install: Step 1 - Set App metadata":

**Namespace:**
- ✅ Selecione `ngsoc-central` (como na sua imagem)
- ✅ Ou qualquer outro namespace que desejar
- ⚠️ **IMPORTANTE**: Não precisa alterar nada no values sobre namespace!

**Name:**
- Digite: `wazuh` ou `ngsoc-central-wazuh`
- Qualquer nome único que desejar

**Customize Helm options:**
- ☐ Deixe **desmarcado** por enquanto
- Você vai customizar no próximo passo

### Passo 3: Configuração dos Values (YAML)

Click em **Next** e na aba **Values YAML**, cole esta configuração:

```yaml
global:
  # DEIXE VAZIO - o Rancher usa o namespace que você selecionou
  namespace: ""
  
  # Não criar - o Rancher já gerencia
  createNamespace: false
  
  # Usar StorageClass existente
  storageClass: gp2
  createStorageClass: false

wazuhManager:
  master:
    service:
      type: LoadBalancer
    resources:
      limits:
        cpu: 800m
        memory: 1Gi
      requests:
        cpu: 400m
        memory: 512Mi
    persistence:
      enabled: true
      size: 10Gi
  
  worker:
    enabled: true
    replicas: 2
    service:
      type: LoadBalancer
    resources:
      limits:
        cpu: 800m
        memory: 1Gi
      requests:
        cpu: 400m
        memory: 512Mi
    persistence:
      enabled: true
      size: 10Gi

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
  persistence:
    enabled: true
    size: 50Gi

wazuhDashboard:
  replicas: 1
  service:
    type: LoadBalancer
  resources:
    limits:
      cpu: 500m
      memory: 768Mi
    requests:
      cpu: 250m
      memory: 512Mi

# ⚠️ IMPORTANTE: ALTERE ESTAS SENHAS ANTES DE INSTALAR!
secrets:
  wazuhApi:
    username: "wazuh-wui"
    password: "d2F6dWg="  # Altere para sua senha em base64
  wazuhAuthd:
    password: "cGFzc3dvcmQ="  # Altere para sua senha em base64
  wazuhCluster:
    key: "YzM0OGUzZTJmNTZlNGY0MmE1YzQyZjE1Yjg3YTFiNzU="  # Altere
  dashboard:
    username: "kibanaserver"
    password: "a2liYW5hc2VydmVy"  # Altere
  indexer:
    username: "admin"
    password: "U2VjcmV0UGFzc3dvcmQ="  # Altere

serviceAccount:
  create: true

rbac:
  create: true
```

### Passo 4: Instalação

1. Click em **Install**
2. Aguarde a instalação (pode levar 5-10 minutos)
3. Monitore o progresso em **Workloads** → **Pods**

## 🔑 Gerar Senhas Seguras

Antes de instalar, gere senhas seguras:

```bash
# No PowerShell (Windows)
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("MinhaS3nh4F0rt3"))

# No Terminal (Linux/Mac)
echo -n "MinhaS3nh4F0rt3" | base64

# Ou use um gerador online
https://www.base64encode.org/
```

Substitua nos valores do YAML:
```yaml
secrets:
  wazuhApi:
    password: "U3VhU2VuaGFHZXJhZGE="  # Sua senha aqui
  indexer:
    password: "T3V0cmFTZW5oYUdlcmFkYQ=="  # Sua senha aqui
```

## 📊 Monitoramento no Rancher

### Via Rancher UI

1. **Workloads → Pods**
   - Veja todos os pods do Wazuh
   - Status, logs, e detalhes

2. **Service Discovery → Services**
   - Veja os LoadBalancers criados
   - Acesse endpoints externos

3. **Storage → PersistentVolumeClaims**
   - Veja os volumes de dados
   - Monitore uso de espaço

### Comandos CLI

```bash
# Ver pods
kubectl get pods -n ngsoc-central

# Ver services
kubectl get svc -n ngsoc-central

# Ver PVCs
kubectl get pvc -n ngsoc-central

# Logs do dashboard
kubectl logs -f deployment/wazuh-dashboard -n ngsoc-central
```

## 🌐 Acessar o Dashboard

### Método 1: Via Rancher UI

1. Vá para **Service Discovery** → **Services**
2. Encontre `wazuh-dashboard`
3. Click no ícone do link externo 🔗
4. Abrirá em: `https://<EXTERNAL-IP>:443`

### Método 2: Via kubectl

```bash
# Obter IP do LoadBalancer
kubectl get svc wazuh-dashboard -n ngsoc-central

# Obter senha de login
kubectl get secret indexer-cred -n ngsoc-central -o jsonpath='{.data.password}' | base64 -d
```

**Credenciais de Login:**
- Usuário: `admin`
- Senha: (decodificar o password do secret)

## ✅ Verificação de Instalação

### 1. Verificar Pods (Todos devem estar Running)

```bash
kubectl get pods -n ngsoc-central
```

Esperado:
```
NAME                               READY   STATUS    RESTARTS   AGE
wazuh-manager-master-0             1/1     Running   0          5m
wazuh-manager-worker-0             1/1     Running   0          5m
wazuh-manager-worker-1             1/1     Running   0          5m
wazuh-indexer-0                    1/1     Running   0          5m
wazuh-indexer-1                    1/1     Running   0          5m
wazuh-indexer-2                    1/1     Running   0          5m
wazuh-dashboard-xxxxxxxxxx-xxxxx   1/1     Running   0          5m
```

### 2. Verificar Services

```bash
kubectl get svc -n ngsoc-central
```

### 3. Verificar PVCs

```bash
kubectl get pvc -n ngsoc-central
```

Todos devem estar **Bound**.

## 🔧 Troubleshooting

### Pods ficam em Pending

**Causa:** Recursos insuficientes ou PVC não pode ser criado

**Solução:**
```bash
# Ver detalhes
kubectl describe pod <pod-name> -n ngsoc-central

# Ver eventos
kubectl get events -n ngsoc-central --sort-by='.lastTimestamp'

# Verificar nodes
kubectl top nodes
```

### PVC fica em Pending

**Causa:** StorageClass não existe ou sem provisioner

**Solução:**
```bash
# Verificar StorageClass
kubectl get sc

# Se gp2 não existir, verificar qual existe:
kubectl get sc
# Use o nome correto no values.yaml:
# storageClass: <nome-do-sc-disponivel>
```

### Dashboard não carrega

**Causa:** Indexer ainda não está pronto

**Solução:**
```bash
# Verificar logs do dashboard
kubectl logs -f deployment/wazuh-dashboard -n ngsoc-central

# Verificar se indexer está pronto
kubectl get pods -n ngsoc-central | grep indexer

# Aguardar todos indexers estarem Running
```

### Erro de certificados

**Causa:** Certificados não foram gerados corretamente

**Solução:**
```bash
# Ver secrets de certificados
kubectl get secrets -n ngsoc-central | grep cert

# Se necessário, regenerar usando o script:
./generate-certs.sh ngsoc-central
kubectl apply -f indexer-certs-secret.yaml
kubectl apply -f dashboard-certs-secret.yaml

# Reiniciar pods
kubectl rollout restart statefulset/wazuh-indexer -n ngsoc-central
kubectl rollout restart deployment/wazuh-dashboard -n ngsoc-central
```

## 🔄 Upgrade

1. **Via Rancher UI:**
   - Apps & Marketplace → Installed Apps
   - Selecione sua instalação
   - Click em **Upgrade**
   - Modifique values se necessário
   - Click em **Upgrade**

2. **Via CLI:**
```bash
helm upgrade wazuh ./wazuh-helm-chart-rancher \
  --namespace ngsoc-central \
  --values custom-values.yaml \
  --timeout 10m
```

## 🗑️ Desinstalação

### Via Rancher UI

1. Apps & Marketplace → Installed Apps
2. Selecione a instalação
3. Click em **Delete**
4. Confirme

### Via CLI

```bash
# Desinstalar app
helm uninstall wazuh -n ngsoc-central

# Remover PVCs (⚠️ APAGA DADOS!)
kubectl delete pvc -l app.kubernetes.io/instance=wazuh -n ngsoc-central
```

## 📝 Checklist de Instalação

- [ ] Chart carregado no Rancher
- [ ] Namespace `ngsoc-central` selecionado
- [ ] Values YAML configurado
- [ ] Senhas alteradas (não usar padrão!)
- [ ] StorageClass verificado (gp2 existe?)
- [ ] Instalação iniciada
- [ ] Pods todos em Running (aguardar 5-10min)
- [ ] LoadBalancers criados
- [ ] Dashboard acessível
- [ ] Login funcionando

## 💡 Dicas Importantes

1. ✅ **Namespace**: Deixe vazio no values - o Rancher gerencia
2. ✅ **StorageClass**: Verifique que existe antes: `kubectl get sc`
3. ✅ **Senhas**: Sempre altere antes de produção
4. ✅ **Recursos**: Ajuste conforme seu cluster
5. ✅ **Timeout**: Aumente se necessário: `--timeout 15m`

## 📞 Suporte

- Documentação Wazuh: https://documentation.wazuh.com/
- Rancher Docs: https://rancher.com/docs/
- Issues: Abra uma issue no repositório do chart

---

**Agora funciona perfeitamente com qualquer namespace selecionado no Rancher! 🎉**
