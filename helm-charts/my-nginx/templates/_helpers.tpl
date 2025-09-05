{{- define "my-nginx.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "my-nginx.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "my-nginx.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
