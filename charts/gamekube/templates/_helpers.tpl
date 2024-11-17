{{- define "gamekube.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "gamekube.labels" -}}
helm.sh/chart: {{  printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | replace "+" "-" | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "gamekube.image" -}}
{{- $tag := .Chart.AppVersion | replace "+" "-" }}
{{- $repo := "ghcr.io/gamekube/gamekube" }}
{{- printf "%s:%s" $repo $tag }}
{{- end }}

{{- define "gamekube.controller.name" -}}
{{- printf "%s-controller" (include "gamekube.name" .)}}
{{- end }}

{{- define "gamekube.controller.labels" -}}
{{ include "gamekube.labels" . }}
{{ include "gamekube.controller.selectorLabels" . }}
{{- end }}

{{- define "gamekube.controller.selectorLabels" -}}
app.kubernetes.io/name: {{ include "gamekube.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
gamekube.dev/component: controller
{{- end }}

{{- define "gamekube.server.name" -}}
{{- printf "%s-server" (include "gamekube.name" .)}}
{{- end }}

{{- define "gamekube.server.labels" -}}
{{ include "gamekube.labels" . }}
{{ include "gamekube.server.selectorLabels" . }}
{{- end }}

{{- define "gamekube.server.selectorLabels" -}}
app.kubernetes.io/name: {{ include "gamekube.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
gamekube.dev/component: server
{{- end }}
