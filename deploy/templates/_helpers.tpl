{{/* vim: set filetype=mustache: */}}
{{/*
Create standard set of labels
*/}}
{{- define "standard-labels" }}
  labels:
    chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
    release: "{{ .Release.Name }}"
    heritage: "{{ .Release.Service }}"
{{- end }}
