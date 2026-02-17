# 🎯 INSTALAÇÃO DEFINITIVA - Sem Wait no Rancher

## ⚠️ IMPORTANTE: NÃO USE "WAIT" NO RANCHER UI

O erro "failed to wait for roles to be populated" acontece quando o Rancher tenta aguardar o RBAC ser criado. A solução é **não aguardar** e deixar a instalação acontecer de forma assíncrona.

## ✅ MÉTODO CORRETO DE INSTALAÇÃO

### Step 1: Metadata
```
Namespace: ngsoc-central
Name: wazuh
```

### Step 2: Values
Cole o conteúdo de `values-rancher.yaml`

### Step 3: Helm Options (CRÍTICO!)

**Configure EXATAMENTE assim:**

```
☐ Apply custom resource definitions    ← DESMARCAR
☐ Execute chart hooks                   ← DESMARCAR  
☐ Validate OpenAPI schema               ← DESMARCAR
☐ Wait                                   ← DESMARCAR (IMPORTANTE!)

Timeout: 600
(não importa, pois Wait está desmarcado)

Description: 
Wazuh Security Platform
```

### Step 4: Instalar

1. Click em **Install**
2. O Rancher vai mostrar sucesso **imediatamente**
3. **ISSO É NORMAL!** A instalação continua em background

## 📊 Monitoramento Manual (OBRIGATÓRIO)

Como não usamos Wait, você precisa monitorar:

### No Rancher UI:

1. **Vá para: Workloads → Pods**
2. Filtre por namespace: `ngsoc-central`
3. Aguarde **5-10 minutos**
4. Todos os pods devem ficar **"Running"**

Status esperado:
```
wazuh-manager-master-0        0/1  Init:0/1       → Running (3-5 min)
wazuh-manager-worker-0        0/1  Init:0/1       → Running (3-5 min)
wazuh-indexer-0               0/1  Init:0/2       → Running (2-4 min)
wazuh-indexer-1               0/1  Init:0/2       → Running (2-4 min)
wazuh-indexer-2               0/1  Init:0/2       → Running (2-4 min)
wazuh-dashboard-xxxxx         0/1  ContainerCreating → Running (2-3 min)
```

### Via kubectl (alternativo):

```bash
# Monitorar em tempo real
kubectl get pods -n ngsoc-central -w

# Ver eventos
kubectl get events -n ngsoc-central --sort-by='.lastTimestamp'

# Ver logs de um pod
kubectl logs -f wazuh-indexer-0 -n ngsoc-central
```

## 🔍 Ordem de Inicialização

1. **ServiceAccount/RBAC** (cria via hooks) - ~10 segundos
2. **Secrets e ConfigMaps** - ~5 segundos
3. **Services** - ~5 segundos
4. **Indexer Pods** - 2-4 minutos (init containers + start)
5. **Manager Pods** - 3-5 minutos (aguarda indexer)
6. **Dashboard Pod** - 2-3 minutos (aguarda indexer)

**Tempo total: 5-10 minutos**

## ✅ Como Saber que Funcionou

### 1. Todos os Pods Running

```bash
kubectl get pods -n ngsoc-central
```

Esperado: **7 pods** todos com status **Running** e **READY 1/1**

### 2. Services com Endpoints

```bash
kubectl get svc -n ngsoc-central
```

Dashboard deve ter **EXTERNAL-IP** (LoadBalancer)

### 3. Acessar Dashboard

```bash
# Pegar IP do LoadBalancer
kubectl get svc wazuh-dashboard -n ngsoc-central -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Ou IP direto
kubectl get svc wazuh-dashboard -n ngsoc-central -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Acesse: `https://<IP-ou-HOSTNAME>:443`

### 4. Fazer Login

```bash
# Pegar senha
kubectl get secret indexer-cred -n ngsoc-central -o jsonpath='{.data.password}' | base64 -d && echo
```

**Usuário:** `admin`  
**Senha:** (a senha decodificada acima)

## 🚨 Troubleshooting

### Pods ficam em "Pending"

**Causa:** PVC não pode ser criado

```bash
# Ver PVCs
kubectl get pvc -n ngsoc-central

# Ver detalhes
kubectl describe pvc wazuh-manager-master-wazuh-manager-master-0 -n ngsoc-central
```

**Solução:**
- Verificar se StorageClass existe: `kubectl get sc`
- Verificar se há espaço no cluster

### Pods ficam em "Init" muito tempo

**Causa:** Init containers falhando

```bash
# Ver logs do init container
kubectl logs wazuh-indexer-0 -c volume-mount-hack -n ngsoc-central
kubectl logs wazuh-indexer-0 -c increase-the-vm-max-map-count -n ngsoc-central
```

**Solução:** Aguardar ou verificar permissões

### Pod em "CrashLoopBackOff"

**Causa:** Aplicação falhando ao iniciar

```bash
# Ver logs
kubectl logs wazuh-indexer-0 -n ngsoc-central --previous

# Ver eventos
kubectl describe pod wazuh-indexer-0 -n ngsoc-central
```

**Soluções comuns:**
- Aguardar outros pods iniciarem
- Verificar configuração de memória/CPU
- Ver logs para erro específico

### Dashboard não carrega

**Causa:** Indexer ainda não está pronto

```bash
# Verificar indexer
kubectl get pods -n ngsoc-central | grep indexer

# Todos devem estar Running
# Aguardar alguns minutos
```

## 🔄 Se Precisar Reinstalar

### 1. Desinstalar

```bash
# Via Rancher UI
Apps & Marketplace → Installed Apps → wazuh → Delete

# Via Helm
helm uninstall wazuh -n ngsoc-central
```

### 2. Limpar PVCs (opcional - APAGA DADOS!)

```bash
kubectl delete pvc -l app.kubernetes.io/instance=wazuh -n ngsoc-central
```

### 3. Aguardar Limpeza

```bash
# Verificar que tudo foi removido
kubectl get all -n ngsoc-central
```

### 4. Reinstalar

Siga os passos deste guia novamente.

## 📝 Configuração Completa Step 3

```yaml
# Rancher UI - Step 3: Helm Options

Supply additional deployment options:

☐ Apply custom resource definitions
☐ Execute chart hooks
☐ Validate OpenAPI schema
☐ Wait                              ← DEIXAR DESMARCADO!

Timeout: 600 seconds

Description:
Wazuh Security Information and Event Management Platform
```

## 💡 Por Que Não Usar Wait?

O Rancher tem um bug/limitação onde:
1. Ele marca "Wait" por padrão
2. Tenta aguardar RBAC ser criado
3. Timeout ou falha antes dos recursos estarem prontos
4. Mas os recursos CONTINUAM sendo criados em background!

**Solução:** Não usar Wait e monitorar manualmente.

## ✅ Checklist Final

Antes de clicar em Install:

- [ ] Namespace `ngsoc-central` selecionado
- [ ] Values YAML colado (com namespace: "")
- [ ] **Wait está DESMARCADO** ☐
- [ ] Execute chart hooks está DESMARCADO ☐
- [ ] StorageClass `gp2` existe: `kubectl get sc`
- [ ] Preparado para monitorar: Workloads → Pods
- [ ] Terá paciência para aguardar 5-10 minutos

## 🎯 Resumo

1. **NÃO marque "Wait"** no Step 3
2. Click **Install**
3. Vá para **Workloads → Pods**
4. **Aguarde 5-10 minutos**
5. Todos pods devem ficar **Running**
6. Acesse o **Dashboard** via LoadBalancer

---

**Esta é a forma CORRETA de instalar no Rancher UI! 🎉**
