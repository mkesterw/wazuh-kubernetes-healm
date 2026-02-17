# 🔧 CORREÇÃO: Erro "failed to wait for roles to be populated"

## ❌ Erro Encontrado

```
failed to wait for roles to be populated
```

Este erro aparece no **Step 3** da instalação no Rancher UI.

## 🎯 Causas Comuns

1. **Timeout muito curto** - O Rancher tem timeout de 600 segundos padrão
2. **RBAC não criado a tempo** - ServiceAccount/Role/RoleBinding demoram para serem criados
3. **Permissões insuficientes** - Usuário não tem permissão para criar RBAC
4. **Cluster sobrecarregado** - Recursos insuficientes

## ✅ Soluções (em ordem de prioridade)

### Solução 1: Aumentar Timeout (RECOMENDADO)

No **Step 3** do Rancher:

1. Marque a opção **"Wait"** ✅
2. Altere o **Timeout** de `600` para `900` (15 minutos)
3. Click em **Install**

### Solução 2: Desabilitar Wait (instalação assíncrona)

No **Step 3** do Rancher:

1. **Desmarque** a opção "Wait" ☐
2. Click em **Install**
3. Monitore manualmente: Workloads → Pods

⚠️ **Aviso**: Com Wait desabilitado, o Rancher não aguarda a instalação completar.

### Solução 3: Instalar via Helm CLI (bypass do Rancher UI)

Se o Rancher UI continuar dando erro:

```bash
# 1. Conectar via kubectl ao cluster
# (use o kubeconfig do Rancher)

# 2. Instalar diretamente
helm install wazuh ./wazuh-helm-chart-final.tgz \
  --namespace ngsoc-central \
  --values values-rancher.yaml \
  --timeout 15m \
  --wait

# 3. Verificar instalação
kubectl get pods -n ngsoc-central -w
```

### Solução 4: Verificar Permissões RBAC

```bash
# Verificar se você tem permissão para criar RBAC
kubectl auth can-i create role -n ngsoc-central
kubectl auth can-i create rolebinding -n ngsoc-central
kubectl auth can-i create serviceaccount -n ngsoc-central

# Se retornar "no", você precisa de permissões de admin
```

### Solução 5: Desabilitar RBAC (NÃO RECOMENDADO)

⚠️ **Apenas para testes em ambientes não-produção**

Adicione nos values:

```yaml
serviceAccount:
  create: false  # Não criar ServiceAccount

rbac:
  create: false  # Não criar RBAC
```

Depois especifique uma ServiceAccount existente:

```yaml
serviceAccount:
  create: false
  name: "default"  # Usar SA padrão do namespace
```

## 🔍 Debug do Problema

### 1. Verificar se RBAC foi criado

```bash
# Ver ServiceAccounts
kubectl get sa -n ngsoc-central

# Ver Roles
kubectl get role -n ngsoc-central

# Ver RoleBindings
kubectl get rolebinding -n ngsoc-central
```

### 2. Ver eventos do namespace

```bash
kubectl get events -n ngsoc-central --sort-by='.lastTimestamp'
```

### 3. Ver logs do Helm

```bash
# Se instalou via Helm CLI
helm status wazuh -n ngsoc-central

# Ver histórico
helm history wazuh -n ngsoc-central
```

### 4. Ver status dos recursos

```bash
# Ver todos os recursos
kubectl get all -n ngsoc-central

# Ver recursos que falharam
kubectl get pods -n ngsoc-central | grep -v Running
```

## 📝 Configuração Recomendada para Rancher

### Step 3 - Helm Options

```
✅ Apply custom resource definitions
✅ Execute chart hooks
✅ Validate OpenAPI schema
✅ Wait                           ← IMPORTANTE!

Timeout: 900                      ← AUMENTAR!
(seconds)

Description: 
Wazuh SIEM Platform
```

### Values YAML

```yaml
global:
  namespace: ""
  createNamespace: false
  storageClass: gp2
  createStorageClass: false

# RBAC habilitado (recomendado)
serviceAccount:
  create: true
  name: ""

rbac:
  create: true

# Resto da configuração...
wazuhManager:
  master:
    persistence:
      size: 10Gi
  worker:
    replicas: 2

wazuhIndexer:
  replicas: 3
  persistence:
    size: 50Gi

wazuhDashboard:
  service:
    type: LoadBalancer
```

## 🎯 Passo a Passo Completo

### 1. Preparação

```bash
# Verificar StorageClass
kubectl get sc

# Verificar namespace existe
kubectl get ns ngsoc-central
# Se não existir:
kubectl create ns ngsoc-central
```

### 2. Instalação no Rancher UI

**Step 1 - Metadata:**
- Namespace: `ngsoc-central`
- Name: `wazuh`

**Step 2 - Values:**
- Cole o YAML do `values-rancher.yaml`

**Step 3 - Helm Options:**
- ✅ Wait: **MARCADO**
- Timeout: **900** (não 600!)
- Click: **Install**

### 3. Monitoramento

```bash
# Em outro terminal, monitore
watch kubectl get pods -n ngsoc-central

# Ver eventos em tempo real
kubectl get events -n ngsoc-central -w
```

### 4. Aguardar Conclusão

Tempo esperado:
- ServiceAccount/RBAC: ~30 segundos
- Indexer pods: ~3-5 minutos
- Manager pods: ~2-4 minutos
- Dashboard pod: ~2-3 minutos
- **Total: 5-10 minutos**

## ⚠️ Se Ainda Não Funcionar

### Opção A: Instalar em etapas

```bash
# 1. Criar apenas RBAC primeiro
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: wazuh
  namespace: ngsoc-central
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: wazuh
  namespace: ngsoc-central
rules:
  - apiGroups: [""]
    resources: ["endpoints", "pods", "services"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: wazuh
  namespace: ngsoc-central
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: wazuh
subjects:
  - kind: ServiceAccount
    name: wazuh
    namespace: ngsoc-central
EOF

# 2. Aguardar propagação
sleep 10

# 3. Instalar o chart (vai usar o SA já criado)
helm install wazuh ./wazuh-helm-chart.tgz \
  --namespace ngsoc-central \
  --values values-rancher.yaml \
  --timeout 15m
```

### Opção B: Usar namespace default

Se `ngsoc-central` tem problemas de permissão:

```bash
# Tentar no namespace default
helm install wazuh ./wazuh-helm-chart.tgz \
  --namespace default \
  --values values-rancher.yaml \
  --timeout 15m
```

### Opção C: Contatar Admin do Rancher

Se você não é administrador do cluster:

1. Peça permissões de **Project Owner** no Rancher
2. Ou peça que o admin instale com as permissões dele
3. Ou use um namespace onde você tenha permissões completas

## ✅ Checklist Final

Antes de instalar, verifique:

- [ ] Timeout configurado para 900 segundos (15 minutos)
- [ ] Opção "Wait" está marcada
- [ ] StorageClass `gp2` existe: `kubectl get sc`
- [ ] Você tem permissão no namespace: `kubectl auth can-i '*' '*' -n ngsoc-central`
- [ ] Namespace existe: `kubectl get ns ngsoc-central`
- [ ] Values YAML está correto (namespace vazio, createNamespace: false)
- [ ] RBAC está habilitado: `rbac.create: true`

## 💡 Dica Extra

Se tudo falhar, simplifique ao máximo:

```yaml
global:
  namespace: ""
  createNamespace: false
  storageClass: gp2
  createStorageClass: false

wazuhManager:
  worker:
    replicas: 1  # Reduzir para 1

wazuhIndexer:
  replicas: 1  # Reduzir para 1

# Resto padrão...
```

Depois que funcionar, faça upgrade aumentando replicas.

---

**Esta versão inclui as correções de RBAC e timeout! 🎉**
