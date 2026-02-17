# ✅ CORREÇÃO: Namespace Dinâmico para Rancher

## 🎯 Problema Identificado

Quando você selecionava o namespace `ngsoc-central` no Rancher UI, mas o values.yaml tinha:

```yaml
global:
  namespace: wazuh  # ❌ FIXO
```

Isso causava conflitos porque o chart tentava usar o namespace "wazuh" enquanto o Rancher esperava usar "ngsoc-central".

## ✅ Solução Aplicada

### Mudança no values.yaml

**ANTES:**
```yaml
global:
  namespace: wazuh  # Namespace fixo
  createNamespace: true
```

**DEPOIS:**
```yaml
global:
  namespace: ""  # Vazio = usa namespace do Helm
  createNamespace: false  # Não criar - Rancher gerencia
```

### Mudança no _helpers.tpl

**ANTES:**
```go
{{- define "wazuh.namespace" -}}
{{- default .Release.Namespace .Values.global.namespace }}
{{- end }}
```

**DEPOIS:**
```go
{{- define "wazuh.namespace" -}}
{{- if .Values.global.namespace }}
{{- .Values.global.namespace }}  # Usa se especificado
{{- else }}
{{- .Release.Namespace }}  # Caso contrário, usa do Helm/Rancher
{{- end }}
{{- end }}
```

## 🚀 Como Funciona Agora

### 1. No Rancher UI

Quando você seleciona o namespace na interface:

```
Namespace: ngsoc-central  ← Você escolhe aqui
```

O chart automaticamente usa `ngsoc-central` em todos os recursos.

### 2. Via Helm CLI

```bash
# Instalar em qualquer namespace
helm install wazuh . --namespace meu-namespace --create-namespace

# O chart usa "meu-namespace" automaticamente
```

### 3. Forçar um Namespace Específico (Opcional)

Se por algum motivo você QUISER forçar um namespace, pode:

```yaml
global:
  namespace: "wazuh-producao"  # Força este namespace
```

Mas **não é recomendado** no Rancher UI!

## 📋 Comportamento em Diferentes Cenários

| Cenário | global.namespace | Resultado |
|---------|------------------|-----------|
| Rancher UI (namespace selecionado: `ngsoc-central`) | `""` (vazio) | ✅ Usa `ngsoc-central` |
| Helm CLI: `--namespace prod` | `""` (vazio) | ✅ Usa `prod` |
| Helm CLI: `--namespace dev` | `"custom"` | ⚠️ Usa `custom` (forçado) |
| Rancher UI | `"wazuh"` | ⚠️ Usa `wazuh` (ignora seleção UI) |

## ✅ Configuração Recomendada

### Para Rancher UI (RECOMENDADO):

```yaml
global:
  namespace: ""              # ← DEIXE VAZIO
  createNamespace: false     # Rancher gerencia
  storageClass: gp2
  createStorageClass: false  # Já existe
```

### Para Helm CLI em namespace específico:

```yaml
global:
  namespace: ""              # ← DEIXE VAZIO
  createNamespace: true      # Helm criará
  storageClass: gp2
  createStorageClass: false
```

## 🧪 Testando

### Verificar qual namespace foi usado:

```bash
# Ver onde os recursos foram criados
kubectl get all -A | grep wazuh

# Ver pods por namespace
kubectl get pods -n ngsoc-central

# Ver todos os namespaces com recursos Wazuh
kubectl get pods --all-namespaces -l app.kubernetes.io/name=wazuh
```

## 🔧 Se Precisar Migrar de Namespace

Se você já instalou com namespace errado:

```bash
# 1. Fazer backup dos PVCs
kubectl get pvc -n namespace-antigo

# 2. Desinstalar
helm uninstall wazuh -n namespace-antigo

# 3. Reinstalar no namespace correto
helm install wazuh . -n namespace-novo --create-namespace

# 4. Migrar dados se necessário (manual)
```

## 📝 Resumo das Mudanças

| Arquivo | Mudança | Por quê |
|---------|---------|---------|
| `values.yaml` | `namespace: ""` | Não força namespace |
| `values.yaml` | `createNamespace: false` | Rancher gerencia |
| `values-rancher.yaml` | `namespace: ""` | Específico para Rancher |
| `_helpers.tpl` | Lógica condicional | Prioriza Release.Namespace |
| `RANCHER-UI-INSTALL.md` | Novo guia | Instruções específicas |

## 💡 Boas Práticas

1. ✅ **Sempre deixe `namespace: ""` vazio** quando usar Rancher UI
2. ✅ **Não habilite `createNamespace`** - deixe Rancher gerenciar
3. ✅ **Verifique antes de instalar**: `kubectl get ns`
4. ✅ **Use labels para encontrar recursos**: `kubectl get all -l app.kubernetes.io/instance=wazuh -n seu-namespace`

## 🎯 Conclusão

Esta versão do chart está **otimizada para Rancher UI** e respeita automaticamente o namespace que você selecionar na interface, eliminando conflitos e facilitando a instalação.

**Não precisa mais se preocupar com namespace hardcoded!** 🎉
