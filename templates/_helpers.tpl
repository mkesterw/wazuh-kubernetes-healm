{{/*
Expand the name of the chart.
*/}}
{{- define "wazuh.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "wazuh.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "wazuh.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "wazuh.labels" -}}
helm.sh/chart: {{ include "wazuh.chart" . }}
{{ include "wazuh.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "wazuh.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wazuh.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "wazuh.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "wazuh.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get the namespace
*/}}
{{- define "wazuh.namespace" -}}
{{- if .Values.global.namespace }}
{{- .Values.global.namespace }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }}

{{/*
Get the storage class name
*/}}
{{- define "wazuh.storageClass" -}}
{{- if .storageClass }}
{{- .storageClass }}
{{- else if .global }}
{{- .global.storageClass }}
{{- end }}
{{- end }}

{{/*
Wazuh Manager Master labels
*/}}
{{- define "wazuh.manager.master.labels" -}}
{{ include "wazuh.labels" . }}
app: wazuh-manager
node-type: master
{{- end }}

{{/*
Wazuh Manager Master selector labels
*/}}
{{- define "wazuh.manager.master.selectorLabels" -}}
{{ include "wazuh.selectorLabels" . }}
app: wazuh-manager
node-type: master
{{- end }}

{{/*
Wazuh Manager Worker labels
*/}}
{{- define "wazuh.manager.worker.labels" -}}
{{ include "wazuh.labels" . }}
app: wazuh-manager
node-type: worker
{{- end }}

{{/*
Wazuh Manager Worker selector labels
*/}}
{{- define "wazuh.manager.worker.selectorLabels" -}}
{{ include "wazuh.selectorLabels" . }}
app: wazuh-manager
node-type: worker
{{- end }}

{{/*
Wazuh Indexer labels
*/}}
{{- define "wazuh.indexer.labels" -}}
{{ include "wazuh.labels" . }}
app: wazuh-indexer
{{- end }}

{{/*
Wazuh Indexer selector labels
*/}}
{{- define "wazuh.indexer.selectorLabels" -}}
{{ include "wazuh.selectorLabels" . }}
app: wazuh-indexer
{{- end }}

{{/*
Wazuh Dashboard labels
*/}}
{{- define "wazuh.dashboard.labels" -}}
{{ include "wazuh.labels" . }}
app: wazuh-dashboard
{{- end }}

{{/*
Wazuh Dashboard selector labels
*/}}
{{- define "wazuh.dashboard.selectorLabels" -}}
{{ include "wazuh.selectorLabels" . }}
app: wazuh-dashboard
{{- end }}

{{/*
Return the appropriate apiVersion for StatefulSet
*/}}
{{- define "wazuh.statefulset.apiVersion" -}}
apps/v1
{{- end }}

{{/*
Return the appropriate apiVersion for Deployment
*/}}
{{- define "wazuh.deployment.apiVersion" -}}
apps/v1
{{- end }}

{{/*
Return the appropriate apiVersion for Ingress
*/}}
{{- define "wazuh.ingress.apiVersion" -}}
{{- if semverCompare ">=1.19-0" .Capabilities.KubeVersion.GitVersion }}
networking.k8s.io/v1
{{- else if semverCompare ">=1.14-0" .Capabilities.KubeVersion.GitVersion }}
networking.k8s.io/v1beta1
{{- else }}
extensions/v1beta1
{{- end }}
{{- end }}
