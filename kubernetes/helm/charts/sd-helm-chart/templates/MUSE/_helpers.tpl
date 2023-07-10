{{/*
Expand the name of the chart.
*/}}
{{- define "mychart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "mychart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Common labels
*/}}
{{- define "mychart.labels" -}}
app.kubernetes.io/name: {{ include "mychart.name" . }}
helm.sh/chart: {{ include "mychart.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}


{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "MUSE.fullname" -}}
{{- if .all.Values.fullnameOverride -}}
{{- printf "%s-%s" .all.Values.fullnameOverride .name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $chartname := default .all.Chart.Name .all.Values.nameOverride -}}
{{- if contains $chartname .all.Release.Name -}}
{{- printf "%s-%s" .all.Release.Name .name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s-%s" $chartname .all.Release.Name .name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "MUSE.service.fullname" -}}
{{- $name := (printf "%s%s" .all.Values.muse_container.servicePrefix .name) -}}
{{ include "MUSE.fullname" (dict "all" .all "name" $name ) }}
{{- end -}}


{{- define "MUSE.serviceAndDeployment" -}}
{{- if .muse_container.enabled }}
{{ include "MUSE.service"  (dict "all" .all "muse_container" .muse_container ) }}
---

{{- end }}
{{- if .muse_container.enabled }}
{{ include "MUSE.deployment"  (dict "all" .all "muse_container" .muse_container ) }}
{{- end }}
{{- end -}}

{{- define "MUSE.service" -}}
{{ include "MUSE.serviceWithName"  (dict "all" .all "muse_container" .muse_container  "name" .muse_container.name) }}
{{- end -}}


{{- define "MUSE.serviceWithName" -}}
{{- $serviceType := default .all.Values.muse_container.serviceType .muse_container.serviceType -}}
{{- $loadBalancerIP := default .all.Values.muse_container.loadBalancerIP .muse_container.loadBalancerIP -}}
{{- $sessionAffinity := default .all.Values.muse_container.sessionAffinity .muse_container.sessionAffinity -}}
{{- $clientTimeoutSeconds := default .all.Values.muse_container.clientTimeoutSeconds .muse_container.clientTimeoutSeconds -}}

apiVersion: v1
kind: Service
metadata:
  name: {{ include "MUSE.service.fullname" (dict "all" .all "name" .name ) }}
  labels:
    app: {{ .name }}
{{ include "mychart.labels" .all | indent 4 }}
{{- if .muse_container.serviceLabels }}
    {{- range $key, $val := .muse_container.serviceLabels }}
    {{ $key }}: {{ $val | quote }}
    {{- end }}
{{- end }}
spec:
  type: {{ $serviceType }}
  {{- if and (eq $serviceType "LoadBalancer") (not (empty $loadBalancerIP)) }}
  loadBalancerIP: {{ $loadBalancerIP }}
  {{- end }}
  {{- if and (eq $serviceType "ClusterIP") (.muse_container.isHeadlessService)}}
  clusterIP: None
  {{- end }}
  ports:
    - port: {{ include "MUSE.getPort" (dict "all" .all "port" .muse_container.port) }}
      targetPort: {{ include "MUSE.getPort" (dict "all" .all "port" .muse_container.port) }}
      {{- if and (eq $serviceType "NodePort") (.muse_container.nodePort) }}
      nodePort: {{ .muse_container.nodePort }}
      {{- end }}
  selector:
    app.kubernetes.io/name: {{ include "mychart.name" .all }}
    app.kubernetes.io/instance: {{ .all.Release.Name }}
    app: {{ .name }}
  {{- if eq  $sessionAffinity "ClientIP"  }}
  sessionAffinity: {{ $sessionAffinity }}
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: {{ $clientTimeoutSeconds }}
  {{- end }}

{{- end -}}

{{- define "MUSE.getImageName" -}}
{{ default .muse_container.name .imageName }}
{{- end -}}

{{- define "MUSE.getTag" -}}
{{ default .all.Values.muse_container.tag .tag }}
{{- end -}}


{{/*
Return the images registry to be use for MUSE.
This is the priority order:
1. global.sdimages
2. global.imageRegistry
3. sdimages
*/}}
{{- define "MUSE.getRegistry" -}}
{{- $registry := default "" .all.Values.sdimages.registry -}}
{{- if .all.Values.global -}}
  {{- if .all.Values.global.imageRegistry -}}
    {{- $registry = .all.Values.global.imageRegistry -}}
  {{- end -}}
  {{- if .all.Values.global.sdimages -}}
    {{- if .all.Values.global.sdimages.registry -}}
      {{- $registry = .all.Values.global.sdimages.registry -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- printf "%s" $registry -}}
{{- end -}}


{{- define "MUSE.deployment" -}}
{{- if .muse_container.enabled }}
apiVersion: apps/v1
kind: Deployment
{{ include "MUSE.deploymentWithName"  (dict "all" .all "muse_container" .muse_container "name" .muse_container.name ) }}
{{- end -}}
{{- end -}}


{{- define "MUSE.deploymentWithName" -}}
metadata:
  name: {{ .muse_container.name }}
  labels:
    app: {{ .name }}
{{ include "mychart.labels" .all | indent 4 }}
{{- if .muse_container.podLabels }}
    {{- range $key, $val := .muse_container.podLabels }}
    {{ $key }}: {{ $val | quote }}
    {{- end }}
{{- end }}
spec:
  replicas: {{ default .all.Values.muse_container.replicaCount  .muse_container.replicaCount }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ include "mychart.name" .all }}
      app.kubernetes.io/instance: {{ .all.Release.Name }}
      app: {{ .name }}
  {{- if .muse_container.affinity }}
  affinity: {{- toYaml .muse_container.affinity | nindent 8 }}
  {{- else if .all.Values.muse_container.podAntiAffinity.enabled }}
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchExpressions:
              - key: "app"
                operator: In
                values:
                - {{ .name }}
          topologyKey: "kubernetes.io/hostname"
  {{- end }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: {{ include "mychart.name" .all }}
        app.kubernetes.io/instance: {{ .all.Release.Name }}
        app: {{ .name }}
      {{- if .muse_container.envConfiguration }}
      annotations:
        rollme: {{ randAlphaNum 5 | quote }}
      {{- end }}
    spec:
      {{- if .all.Values.muse_container.nodeName }}
      nodeName:
{{ toYaml .all.Values.muse_container.nodeName | indent 8 }}
      {{- end }}
      {{- if .muse_container.nodeSelector }}
      nodeSelector:
{{ toYaml .muse_container.nodeSelector | indent 8 }}
      {{- end }}
      {{- if .muse_container.tolerations }}
      tolerations:
{{ toYaml .muse_container.tolerations | indent 8 }}
      {{- end }}
      {{- if .all.Values.securityContext.enabled }}
      securityContext:
        runAsUser: {{ .all.Values.securityContext.runAsUser }}
        runAsGroup: {{ .all.Values.securityContext.runAsGroup }}
        fsGroup: {{ .all.Values.securityContext.fsGroup }}
      {{- end }}
      {{- if .all.Values.serviceAccount.enabled }}
      serviceAccountName: {{ default ( include "MUSE.fullname" (dict "all" .all "name" .name ) ) .all.Values.serviceAccount.name }}
      {{- end }}
      {{- if (.all.Values.automountServiceAccountToken.enabled) }}
      automountServiceAccountToken: true
      {{- else }}
      automountServiceAccountToken: false
      {{- end }}
      containers:
{{ include "muse.containers.fluentdsidecar" . | indent 6 }}
      - name: {{ .name }}
        imagePullPolicy: {{ default .all.Values.muse_container.pullPolicy .muse_container.pullPolicy }}
{{ include "MUSE.securityContext.containers" . | indent 8 }}
        image: {{ include "MUSE.getRegistry" (dict "all" .all "registry" .muse_container.image.registry) }}{{ include "MUSE.getImageName" (dict "muse_container" .muse_container "imageName" .muse_container.image.name) }}:{{ include "MUSE.getTag" (dict "all" .all "tag" .muse_container.image.tag) }}
        ports:
        - containerPort: {{ include "MUSE.getPort" (dict "all" .all "port" .muse_container.port) }}
          name: service-port
{{ include "MUSE.resources"  (dict "all" .all "muse_container" .muse_container ) | indent 8 -}}
{{ include "MUSE.probes"  (dict "all" .all "muse_container" .muse_container ) | indent 8 -}}
{{- end -}}


{{- define "MUSE.getPort" -}}
{{ default .all.Values.muse_container.port .port }}
{{- end -}}

{{- define "MUSE.resources" -}}
{{- if .all.Values.muse_container.resources.enabled -}}
resources:
  requests:
    {{- if .muse_container.resources }}
    memory: {{ .muse_container.resources.requests.memory | quote}}
    {{- else }}
    memory: {{ .all.Values.muse_container.resources.requests.memory | quote}}
    {{- end }}
    {{- if .muse_container.resources }}
    cpu: {{ .muse_container.resources.requests.cpu | quote }}
    {{- else }}
    cpu: {{ .all.Values.muse_container.resources.requests.cpu | quote }}
    {{- end }}
  limits:
    {{- if .muse_container.resources }}
    memory: {{ .muse_container.resources.limits.memory | quote }}
    {{- else }}
    memory: {{ .all.Values.muse_container.resources.limits.memory | quote }}
    {{- end }}
    {{- if .muse_container.resources }}
    cpu: {{ .muse_container.resources.limits.cpu | quote }}
    {{- else }}
    cpu: {{ .all.Values.muse_container.resources.limits.cpu | quote }}
    {{- end }}
{{- end }}
{{- end }}



{{- define "MUSE.probes" -}}
{{- if .muse_container.disableProbes -}}
{{- else }}

{{- $StartupProbeFailureThreshold := .all.Values.muse_container.startupProbe.failureThreshold -}}
{{- if .muse_container.startupProbe }}
{{- $StartupProbeFailureThreshold = .muse_container.startupProbe.failureThreshold -}}
{{- end }}

{{- $StartupProbePeriodSeconds := .all.Values.muse_container.startupProbe.periodSeconds -}}
{{- if .muse_container.startupProbe }}
{{- $StartupProbePeriodSeconds = .muse_container.startupProbe.periodSeconds -}}
{{- end }}

{{- $StartupProbeInitialDelaySeconds := .all.Values.muse_container.startupProbe.initialDelaySeconds -}}
{{- if .muse_container.startupProbe }}
{{- $StartupProbeInitialDelaySeconds = .muse_container.startupProbe.initialDelaySeconds -}}
{{- end }}

{{- $StartupProbeTimeoutSeconds := .all.Values.muse_container.startupProbe.timeoutSeconds -}}
{{- if .muse_container.startupProbe }}
{{- $StartupProbeTimeoutSeconds = .muse_container.startupProbe.timeoutSeconds -}}
{{- end }}

{{- $readinessProbeFailureThreshold := .all.Values.muse_container.readinessProbe.failureThreshold -}}
{{- if .muse_container.readinessProbe }}
{{- $readinessProbeFailureThreshold = .muse_container.readinessProbe.failureThreshold -}}
{{- end }}

{{- $readinessProbePeriodSeconds := .all.Values.muse_container.readinessProbe.periodSeconds -}}
{{- if .muse_container.readinessProbe }}
{{- $readinessProbePeriodSeconds = .muse_container.readinessProbe.periodSeconds -}}
{{- end }}

{{- $readinessProbeInitialDelaySeconds := .all.Values.muse_container.readinessProbe.initialDelaySeconds -}}
{{- if .muse_container.readinessProbe }}
{{- $readinessProbeInitialDelaySeconds = .muse_container.readinessProbe.initialDelaySeconds -}}
{{- end }}

{{- $readinessProbeTimeoutSeconds := .all.Values.muse_container.readinessProbe.timeoutSeconds -}}
{{- if .muse_container.readinessProbe }}
{{- $readinessProbeTimeoutSeconds = .muse_container.readinessProbe.timeoutSeconds -}}
{{- end }}

{{- $livenessProbeFailureThreshold := .all.Values.muse_container.livenessProbe.failureThreshold -}}
{{- if .muse_container.livenessProbe }}
{{- $livenessProbeFailureThreshold = .muse_container.livenessProbe.failureThreshold -}}
{{- end }}

{{- $livenessProbePeriodSeconds := .all.Values.muse_container.livenessProbe.periodSeconds -}}
{{- if .muse_container.livenessProbe }}
{{- $livenessProbePeriodSeconds = .muse_container.livenessProbe.periodSeconds -}}
{{- end }}

{{- $livenessProbeInitialDelaySeconds := .all.Values.muse_container.livenessProbe.initialDelaySeconds -}}
{{- if .muse_container.livenessProbe }}
{{- $livenessProbeInitialDelaySeconds = .muse_container.livenessProbe.initialDelaySeconds -}}
{{- end }}

{{- $livenessProbeTimeoutSeconds := .all.Values.muse_container.livenessProbe.timeoutSeconds -}}
{{- if .muse_container.livenessProbe }}
{{- $livenessProbeTimeoutSeconds = .muse_container.livenessProbe.timeoutSeconds -}}
{{- end }}
startupProbe:
  exec:
    command:
      - /docker/healthcheck.sh
  failureThreshold: {{ $StartupProbeFailureThreshold }}
  periodSeconds: {{ $StartupProbePeriodSeconds }}
  initialDelaySeconds: {{ $StartupProbeInitialDelaySeconds }}
  timeoutSeconds: {{ $StartupProbeTimeoutSeconds }}
readinessProbe:
  exec:
    command:
      - /docker/healthcheck.sh
  failureThreshold: {{ $readinessProbeFailureThreshold }}
  periodSeconds: {{ $readinessProbePeriodSeconds }}
  initialDelaySeconds: {{ $readinessProbeInitialDelaySeconds }}
  timeoutSeconds: {{ $readinessProbeTimeoutSeconds }}
livenessProbe:
  exec:
    command:
      - /docker/healthcheck.sh
  failureThreshold: {{ $livenessProbeFailureThreshold }}
  periodSeconds: {{ $livenessProbePeriodSeconds }}
  initialDelaySeconds: {{ $livenessProbeInitialDelaySeconds }}
  timeoutSeconds: {{ $livenessProbeTimeoutSeconds }}
{{- end }}
{{- end -}}

{{- define "MUSE.headers" -}}
  {{- range $header, $url := default .all.Values.muse_container.headers .muse_container.headers }}
        - name: {{ $header }}
          value: {{ $url | quote }}
  {{- end -}}
{{- end }}


{{- define "MUSE-helm-chart.spec.containers.muse_gateway.volumes" -}}
{{- if eq .Values.muse_gateway.env.GATEWAY_PROTOCOL "https" }}
- name: muse-certificate-volume
  secret:
    secretName: secretstore
    items:
      - key: tls.crt
        path: gatewaycertificate.crt
- name: muse-privatekey-volume
  secret:
    secretName: secretstore
    items:
      - key: tls.key
        path: gatewayprivate.pem
{{- end }}
{{- end -}}

{{- define "MUSE-helm-chart.spec.containers.muse_shell.volumes" -}}
volumes:
- name: translations
  emptyDir: {}
- name: configuration
  emptyDir: {}
- name: tmp
  emptyDir: {}
{{- end -}}

{{- define "MUSE-helm-chart.spec.containers.log.volume" -}}
volumes:
- name: log
  emptyDir: {}
{{- end -}}

{{- define "MUSE-helm-chart.spec.containers.certs" -}}
volumes:
- name: certs
  emptyDir: {}
{{- end -}}

{{/*
Specific volumeMounts helper for muse_shell
*/}}
{{- define "MUSE-helm-chart.template.containers.muse_shell.volumeMounts" -}}
volumeMounts:
- name: translations
  mountPath: /usr/share/nginx/html/assets/i18n-custom
- name: configuration
  mountPath: /usr/share/nginx/html/assets/configuration
- name: tmp
  mountPath: /tmp
{{- end -}}

{{- define "MUSE-helm-chart.template.containers.muse_sd_ui.volumeMounts" -}}
volumeMounts:
- name: configuration
  mountPath: /usr/share/nginx/html/assets/configuration
- name: temp
  mountPath: /tmp
{{- end -}}

{{- define "MUSE-helm-chart.template.containers.volumeMountsLog" -}}
volumeMounts:
- name: log
  mountPath: /usr/src/app/log
{{- end -}}

{{- define "MUSE-helm-chart.spec.containers.muse_sd_ui.volumes" -}}
volumes:
- name: configuration
  emptyDir: {}
- name: temp
  emptyDir: {}
{{- end -}}

{{- define "MUSE-helm-chart.spec.containers.muse_fluentd.volumes" -}}
- name: fluentd-config
  configMap:
    defaultMode: 420
    name: fluentd-config
- name: buffer
  emptyDir: {}
{{- end -}}


{{- define "MUSE-helm-chart.template.containers.muse_sd_ui_plugin.volumeMounts" -}}
volumeMounts:
- name: certs
  mountPath: /certs
{{- end -}}

{{- define "muse.containers.fluentdsidecar" -}}
{{- if and ((eq (include "muse.efk.enabled" .) "true")) (.all.Values.efk.fluentd.enabled) }}
- name: fluentd
  image: "{{ include "muse.fluentd.fullpath" . }}"
  imagePullPolicy: {{ default .all.Values.muse_container.pullPolicy .muse_container.pullPolicy }}
  env:
  - name: POD_NAME
    valueFrom:
      fieldRef:
        apiVersion: v1
        fieldPath: metadata.name
  - name: FLUENTD_CONF
    value: fluentd.conf
  - name: FLUENTD_OPT
  ports:
  - containerPort: 24224
    name: tcp
    protocol: TCP
  - containerPort: 9880
    name: http
    protocol: TCP
  - containerPort: 24231
    name: metrics
  resources:
    requests:
      memory: {{ .all.Values.fluentd.memoryrequested }}
      cpu: {{ .all.Values.fluentd.cpurequested }}
    limits:
      {{- if (.all.Values.fluentd.memorylimit) }}
      memory: {{ .all.Values.fluentd.memorylimit }}
      {{- end }}
      {{- if (.all.Values.fluentd.cpulimit) }}
      cpu: {{ .all.Values.fluentd.cpulimit }}
      {{- end }}
  volumeMounts:
{{- if and (or (eq (include "muse.efk.enabled" .) "true") (eq (include "muse.prometheus.enabled" .) "true")) (.all.Values.efk.fluentd.enabled) }}
  - mountPath: /opt/bitnami/fluentd/conf/
    name: fluentd-config
  - mountPath: /opt/bitnami/fluentd/logs/buffers
    name: buffer
{{- end }}
{{- end -}}
{{- end -}}


{{/*
Generate the full repository url for Fluentd container:  registry + image name + tag(version)
*/}}
{{- define "muse.fluentd.fullpath" -}}
{{- if .all.Values.fluentd -}}
  {{- if .all.Values.fluentd.image.registry -}}
    {{- printf "%s" .all.Values.fluentd.image.registry -}}
  {{- end -}}
  {{- if .all.Values.fluentd.image.name -}}
    {{- printf "%s" .all.Values.fluentd.image.name -}}
  {{- end -}}
  {{- if .all.Values.fluentd.image.tag -}}
    {{- printf ":%s" .all.Values.fluentd.image.tag -}}
  {{- end -}}
{{- end -}}
{{- end -}}



{{/*
Return a boolean that states if efk example is enabled, it can be defined in several parameters. Adapted for MUSE chart context.
This is the priority order:
1. global.efk.enabled
2. efk.enabled
3. false
*/}}
{{- define "muse.efk.enabled" -}}
{{- if .all.Values.efk.enabled -}}
  {{- .all.Values.efk.enabled -}}
{{- end -}}

{{- if .all.Values.global -}}
  {{- if .all.Values.global.efk -}}
    {{- if .all.Values.global.efk.enabled -}}
      {{- .all.Values.global.efk.enabled -}}
    {{- else -}}
      {{- printf "false" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- end -}}


{{/*
Return a boolean that states if Prometheus example is enabled, it can be defined in several parameters. Adapted for MUSE chart context.
This is the priority order:
1. global.prometheus.enabled
2. prometheus.enabled
3. false
*/}}
{{- define "muse.prometheus.enabled" -}}
{{- if .all.Values.prometheus.enabled -}}
  {{- .all.Values.prometheus.enabled -}}
{{- end -}}

{{- if .all.Values.global -}}
  {{- if .all.Values.global.prometheus -}}
    {{- if .all.Values.global.prometheus.enabled -}}
      {{- .all.Values.global.prometheus.enabled -}}
    {{- else -}}
      {{- printf "false" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- end -}}


{{/*
Muse Database definition
*/}}
{{- define "MUSE.env.db" -}}
- name: DB_TYPE
  value: "{{ .all.Values.muse_container.env.DB_TYPE }}"
- name: DB_HOST
  value: "{{ .all.Values.muse_container.env.DB_HOST }}"
- name: DB_PORT
  value: "{{ .all.Values.muse_container.env.DB_PORT }}"
- name: DB_NAME
  value: "{{ .all.Values.muse_container.env.DB_NAME }}"
- name: DB_USER
  value: "{{ .all.Values.muse_container.env.DB_USER }}"
{{- include "MUSE.db.password" (dict "all" .all ) }}
- name: DB_SSL_ENABLED
  value: "{{ .all.Values.muse_container.env.DB_SSL_ENABLED }}"
{{- if .all.Values.muse_container.env.DB_SSL_STRICT }}
- name: DB_SSL_STRICT
  value: "{{ .all.Values.muse_container.env.DB_SSL_STRICT }}"
{{- end }}
{{- if .all.Values.muse_container.env.DB_SSL_CERTIFICATE }}
- name: DB_SSL_CERTIFICATE
  value: "{{ .all.Values.muse_container.env.DB_SSL_CERTIFICATE }}"
{{- end }}
{{- if .all.Values.muse_container.env.DB_SSL_SECURE_PROTOCOL }}
- name: DB_SSL_SECURE_PROTOCOL
  value: "{{ .all.Values.muse_container.env.DB_SSL_SECURE_PROTOCOL }}"
{{- end }}
{{- if .all.Values.muse_container.env.DB_RETRY_TRIES }}
- name: DB_RETRY_TRIES
  value: "{{ .all.Values.muse_container.env.DB_RETRY_TRIES }}"
{{- end }}
{{- if .all.Values.muse_container.env.DB_RETRY_TIMEOUT }}
- name: DB_RETRY_TIMEOUT
  value: "{{ .all.Values.muse_container.env.DB_RETRY_TIMEOUT }}"
{{- end }}
{{- end -}}


{{/*
Set redis env variables for Muse services to use Redis, if redis is enabled:
1. all
*/}}
{{- define "MUSE.env.redis" -}}
  {{- if .all.Values.redis.enabled -}}
- name: REDIS_ENABLED
  value: "y"
{{- if .all.Values.redis.fullnameOverride }}
- name: REDIS_HOST
  value: "{{ .all.Values.redis.fullnameOverride }}{{ printf "-master" }}"
{{- end -}}
{{/*
This is a required parameter used to encrypt session data.
It is not needed to be set by the user
*/}}
- name: REDIS_SECRET
  value: "{{ randAlphaNum 6 }}"
{{- if .all.Values.redis.redisPort }}
- name: REDIS_PORT
  value: "{{ .all.Values.redis.redisPort }}"
{{- end }}
{{- if .all.Values.muse_container.env.REDIS_TLS_ENABLED }}
- name: REDIS_TLS_ENABLED
  value: "{{ .all.Values.muse_container.env.REDIS_TLS_ENABLED }}"
{{- end }}
{{- if .all.Values.muse_container.env.REDIS_TLS_STRICT_SSL }}
- name: REDIS_TLS_STRICT_SSL
  value: "{{ .all.Values.muse_container.env.REDIS_TLS_STRICT_SSL }}"
{{- end }}
{{- if .all.Values.muse_container.env.REDIS_TLS_CERTIFICATE }}
- name: REDIS_TLS_CERTIFICATE
  value: "{{ .all.Values.muse_container.env.REDIS_TLS_CERTIFICATE }}"
{{- end }}
{{- if .all.Values.muse_container.env.REDIS_TLS_PRIVATE_KEY }}
- name: REDIS_TLS_PRIVATE_KEY
  value: "{{ .all.Values.muse_container.env.REDIS_TLS_PRIVATE_KEY }}"
{{- end }}
{{- if .all.Values.muse_container.env.REDIS_TLS_SECURE_PROTOCOL }}
- name: REDIS_TLS_SECURE_PROTOCOL
  value: "{{ .all.Values.muse_container.env.REDIS_TLS_SECURE_PROTOCOL }}"
{{- end }}
{{- if .all.Values.muse_container.env.REDIS_TLS_ROOT_CERTIFICATES }}
- name: REDIS_TLS_ROOT_CERTIFICATES
  value: "{{ .all.Values.muse_container.env.REDIS_TLS_ROOT_CERTIFICATES }}"
{{- end }}
    {{- if  not ( .all.Values.secrets_as_volumes) }}
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      {{- if and (.all.Values.redis.auth.existingSecret) (.all.Values.redis.auth.existingSecretPasswordKey) }}
      name: "{{ .all.Values.redis.auth.existingSecret }}"
      key: "{{ .all.Values.redis.auth.existingSecretPasswordKey }}"
      {{- else }}
      name: "{{ .all.Values.redis.fullnameOverride }}"
      key: "redis-password"
      {{- end }}
    {{- end }}
  {{- end }}
{{- end -}}

{{/*
Set redis volumes for Muse services to use Redis, if redis is enabled and secrets are in volumes
1. all
*/}}
{{- define "MUSE.volume.redis.secret" -}}
{{- if .all.Values.redis.enabled -}}
- secret:
  {{- if .all.Values.redis.auth.existingSecret }}
    name: "{{ .all.Values.redis.auth.existingSecret }}"
    items:
      - key: "{{ .all.Values.redis.auth.existingSecretPasswordKey }}"
        path: REDIS_PASSWORD
  {{- else }}
    name: "redis"
    items:
      - key: "redis-password"
        path: REDIS_PASSWORD
  {{- end }}
{{- end }}
{{- end -}}


{{/*
Set secrets volumes for Muse services
1. all
*/}}
{{- define "MUSE.volume.secrets" -}}
{{- if and (.all.Values.secrets_as_volumes) (or (.all.Values.muse_container.env.DB_SECRET_KEY) (.all.Values.muse_container.env.DB_SECRET_NAME) (.all.Values.redis.enabled)) -}}
- name: secrets
  projected:
    sources:
{{ include "MUSE.volume.redis.secret"  (dict "all" .all ) | indent 4 }}
{{ include "MUSE.add.volume.secrets.db" (dict "all" .all ) | indent 4 }}
{{- end }}
{{- end -}}

{{- define "MUSE.add.volume.secrets.db" -}}
{{- /*
Adds more secrets to output from function above wherever used
Usage: {{ include "MUSE.add.volume.secrets" (dict "all" .) }}
*/}}
{{- if and (.all.Values.muse_container.env.DB_SECRET_KEY) (.all.Values.muse_container.env.DB_SECRET_NAME) }}
- secret:
    name: "{{ .all.Values.muse_container.env.DB_SECRET_NAME }}"
    items:
      - key: "{{ .all.Values.muse_container.env.DB_SECRET_KEY }}"
        path: DB_PASSWORD
{{- else }}
{{- if or (.all.Values.muse_container.env.DB_SECRET_KEY) (.all.Values.muse_container.env.DB_SECRET_NAME) }}
{{- fail "muse_container.env.DB_SECRET_NAME and muse_container.env.DB_SECRET_KEY parameters both have to be set or left empty!" }}
{{- /*
Use default DB Password }}
*/}}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Set db password for Muse services
1. all
*/}}
{{- define "MUSE.db.password" -}}
{{- if not (.all.Values.secrets_as_volumes) }}
{{- if and (.all.Values.muse_container.env.DB_SECRET_KEY) (.all.Values.muse_container.env.DB_SECRET_NAME) }}
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: "{{ .all.Values.muse_container.env.DB_SECRET_NAME }}"
      key: "{{ .all.Values.muse_container.env.DB_SECRET_KEY }}"
{{- else }}
{{- if or (.all.Values.muse_container.env.DB_SECRET_KEY ) (.all.Values.muse_container.env.DB_SECRET_NAME) }}
{{- fail "muse_container.env.DB_SECRET_NAME and muse_container.env.DB_SECRET_KEY parameters both have to be set or left empty!" }}
{{- /*
Use default DB Password }}
*/}}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Mounts /secrets volume
*/}}
{{- define "MUSE.secrets.volumeMounts" -}}
{{- if and (.all.Values.secrets_as_volumes) (or (.all.Values.muse_container.env.DB_SECRET_KEY) (.all.Values.muse_container.env.DB_SECRET_NAME) (.all.Values.redis.enabled)) -}}
- name: secrets
  mountPath: "/secrets"
{{- end }}
{{- end -}}

{{- define "MUSE.secrets_gateway.volumeMounts" -}}
{{- if eq .Values.muse_gateway.env.GATEWAY_PROTOCOL "https" }}
- name: muse-certificate-volume
  mountPath: "/etc/apk/keys/gatewaycertificate.crt"
  readOnly: true
  subPath: gatewaycertificate.crt
- name: muse-privatekey-volume
  mountPath: "/etc/apk/keys/gatewayprivate.pem"
  readOnly: true
  subPath: gatewayprivate.pem
{{- end }}
{{- end -}}

{{/*
Set HPSA password for Muse services
1. all
*/}}
{{- define "MUSE.hpsa.password" -}}
{{- if not (.all.Values.secrets_as_volumes) }}
{{- if and (.all.Values.muse_sd_ui_plugin.env.HPSA_PASSWORD_SECRET_NAME) (.all.Values.muse_sd_ui_plugin.env.HPSA_PASSWORD_SECRET_NAME) }}
- name: HPSA_PASSWORD
  valueFrom:
    secretKeyRef:
      name: "{{ .all.Values.muse_sd_ui_plugin.env.HPSA_PASSWORD_SECRET_NAME }}"
      key: "{{ .all.Values.muse_sd_ui_plugin.env.HPSA_PASSWORD_SECRET_KEY }}"
{{- else }}
{{- if or (.all.Values.muse_sd_ui_plugin.env.HPSA_PASSWORD_SECRET_KEY) (.all.Values.muse_sd_ui_plugin.env.HPSA_PASSWORD_SECRET_NAME) }}
{{- fail "muse_sd_ui_plugin.env.HPSA_PASSWORD_SECRET_NAME and muse_sd_ui_plugin.env.HPSA_PASSWORD_SECRET_KEY parameters both have to be set or left empty!" }}
{{- /*
Use default HPSA Password }}
*/}}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}


{{/*
Set secrets as env variables for Muse services
1. all
*/}}
{{- define "MUSE.env.secrets" -}}
{{- if not (.all.Values.secrets_as_volumes)  }}
valueFrom:
  secretKeyRef:
    name: {{ .name }}
    key: {{ .key }}
{{- end }}
{{- end -}}


{{/*
Sets the security context at container scope https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container
*/}}
{{- define "MUSE.securityContext.containers" -}}
{{- if (.all.Values.securityContext.enabled) }}
securityContext:
{{- if (.all.Values.securityContext.readOnlyRootFilesystem) }}
  readOnlyRootFilesystem: true
{{- end }}
{{- if (.all.Values.securityContext.dropAllCapabilities) }}
  capabilities:
    drop:
      - ALL
    {{- if (.all.Values.securityContext.addCapabilities) }}
    add: {{- toYaml .all.Values.securityContext.addCapabilities | nindent 6 }}
    {{- end }}
{{- end }}
{{- end }}
{{- end -}}