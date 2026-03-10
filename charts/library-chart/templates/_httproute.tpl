{{/* vim: set filetype=mustache: */}}

{{/* HTTPRoute annotations */}}
{{- define "library-chart.httproute.annotations" -}}
{{- with (.Values.httproute).annotations }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/* HTTPRoute hostname */}}
{{- define "library-chart.httproute.hostname" -}}
{{- if (.Values.httproute).generate }}
{{- .Values.httproute.userHostname }}
{{- else }}
{{- .Values.httproute.hostname }}
{{- end }}
{{- end }}

{{/* Template to generate a standard HTTPRoute */}}
{{- define "library-chart.httproute" -}}
{{- if (.Values.httproute).enabled -}}
{{- if or (.Values.autoscaling).enabled (not (.Values.global).suspend) }}
{{- $fullName := include "library-chart.fullname" . -}}
{{- $svcPort := .Values.networking.service.port -}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ $fullName }}-ui
  labels:
    {{- include "library-chart.labels" . | nindent 4 }}
  {{- with include "library-chart.httproute.annotations" . }}
  annotations:
    {{- . | nindent 4 }}
  {{- end }}
spec:
  parentRefs:
    {{- toYaml .Values.httproute.parentRefs | nindent 4 }}
  hostnames:
    - {{ include "library-chart.httproute.hostname" . | quote }}
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: {{ .Values.httproute.path | default "/" }}
      backendRefs:
        - name: {{ $fullName }}
          port: {{ $svcPort }}
{{- end }}
{{- end }}
{{- end }}

{{/* Template to generate a custom HTTPRoute for user ports */}}
{{- define "library-chart.httprouteUser" -}}
{{- if (.Values.httproute).enabled -}}
{{- if or (.Values.autoscaling).enabled (not (.Values.global).suspend) }}
{{- if ((.Values.networking).user).enabled -}}
{{- $userPorts := list -}}
{{- if or .Values.networking.user.ports .Values.networking.user.port -}}
{{- $userPorts = .Values.networking.user.ports | default (list .Values.networking.user.port) -}}
{{- end -}}
{{- if $userPorts -}}
{{- $fullName := include "library-chart.fullname" . -}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ $fullName }}-user
  labels:
    {{- include "library-chart.labels" . | nindent 4 }}
  {{- with include "library-chart.httproute.annotations" . }}
  annotations:
    {{- . | nindent 4 }}
  {{- end }}
spec:
  parentRefs:
    {{- toYaml .Values.httproute.parentRefs | nindent 4 }}
  hostnames:
  {{- range $userPort := $userPorts }}
    {{- if eq (len $userPorts) 1 }}
    - {{ $.Values.httproute.userHostname | quote }}
    {{- else }}
    - {{ regexReplaceAll "([^\\.]+)\\.(.*)" $.Values.httproute.userHostname (printf "${1}-%d.${2}" (int $userPort)) | quote }}
    {{- end }}
  {{- end }}
  rules:
  {{- range $userPort := $userPorts }}
  {{- with $ }}
    - matches:
        - path:
            type: PathPrefix
            value: {{ .Values.httproute.userPath | default "/" }}
      backendRefs:
        - name: {{ $fullName }}
          port: {{ $userPort }}
  {{- end }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/* Template to generate an HTTPRoute for the Spark UI */}}
{{- define "library-chart.httprouteSpark" -}}
{{- if and (.Values.httproute).enabled (.Values.spark).ui -}}
{{- $fullName := include "library-chart.fullname" . -}}
{{- $svcPort := .Values.networking.sparkui.port -}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ $fullName }}-sparkui
  labels:
    {{- include "library-chart.labels" . | nindent 4 }}
  {{- with include "library-chart.httproute.annotations" . }}
  annotations:
    {{- . | nindent 4 }}
  {{- end }}
spec:
  parentRefs:
    {{- toYaml .Values.httproute.parentRefs | nindent 4 }}
  hostnames:
    - {{ .Values.spark.hostname | quote }}
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: {{ .Values.spark.path | default "/" }}
      backendRefs:
        - name: {{ $fullName }}
          port: {{ $svcPort }}
{{- end }}
{{- end }}
