
{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "sd-cl.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "sd-cl.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper monitoring namespace
*/}}
{{- define "tplvalues.render" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}

{{/*
Return the proper monitoring namespace
*/}}
{{- define "monitoring.namespace" -}}
{{- if .Values.monitoringNamespace -}}
  {{- printf "%s" .Values.monitoringNamespace -}}
{{- else -}}
  {{- printf "%s" .Release.Namespace -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper storage class for elasticsearch
*/}}
{{- define "sd-helm-chart.elastic.storageclass" -}}
{{- if .Values.elk.elastic.storageClass -}}
  {{- printf "%s" .Values.elk.elastic.storageClass -}}
{{- else if .Values.global -}}
  {{- if .Values.global.storageClass -}}
    {{- printf "%s" .Values.global.storageClass -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper elk value
*/}}
{{- define "elk.enabled" -}}
{{- if .Values.elk.enabled -}}
  {{- .Values.elk.enabled -}}
{{- else if .Values.global -}}
  {{- if .Values.global.elk -}}
    {{- if .Values.global.elk.enabled -}}
      {{- .Values.global.elk.enabled -}}
    {{- end -}}
  {{- end -}}
{{- else -}}
    {{- printf "false" -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper prometheus value
*/}}
{{- define "prometheus.enabled" -}}
{{- if .Values.prometheus.enabled -}}
  {{- .Values.prometheus.enabled -}}
{{- else if .Values.global -}}
  {{- if .Values.global.prometheus -}}
    {{- if .Values.global.prometheus.enabled -}}
      {{- .Values.global.prometheus.enabled -}}
    {{- end -}}
  {{- end -}}
{{- else -}}
    {{- printf "false" -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "sd-cl.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Generate the full sdsp or sdcl repository url
*/}}
{{- define "sdimage.fullpath" -}}
{{- $registry := "" -}}
{{- $name := "" -}}
{{- $tag := "" -}}
{{- $isAssurance := .Values.install_assurance | toString -}}
{{- if .Values.global -}}
  {{- if .Values.global.sdimage -}}
    {{- if .Values.global.sdimage.tag -}}
       {{- $tag = .Values.global.sdimage.tag -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- if .Values.sdimages.tag -}}
  {{- $tag = .Values.sdimages.tag -}}
{{- end -}}
{{- if .Values.sdimage.tag -}}
  {{- $tag = .Values.sdimage.tag -}}
{{- end -}}

{{- if .Values.global -}}
  {{- if .Values.global.imageRegistry -}}
    {{- $registry = .Values.global.imageRegistry -}}
  {{- end -}}
{{- end -}}

{{- if .Values.global -}}
  {{- if .Values.global.sdimages -}}
    {{- if .Values.global.sdimages.registry -}}
      {{- $registry = .Values.global.sdimages.registry -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- if .Values.sdimages.registry -}}
  {{- $registry = .Values.sdimages.registry -}}
{{- end -}}

{{- if eq $isAssurance "true" -}}
  {{- $name = .Values.statefulset_sdcl.image.name -}}
  {{- if .Values.statefulset_sdcl.registry -}}
    {{- $registry = .Values.statefulset_sdcl.registry -}}
  {{- end -}}
  {{- if .Values.statefulset_sdcl.image.tag -}}
    {{- $tag = .Values.statefulset_sdcl.image.tag -}}
  {{- end -}}
{{- else -}}
  {{- $name = .Values.statefulset_sdsp.image.name -}}
  {{- if .Values.statefulset_sdsp.registry -}}
    {{- $registry = .Values.statefulset_sdsp.registry -}}
  {{- end -}}
  {{- if .Values.statefulset_sdsp.image.tag -}}
    {{- $tag = .Values.statefulset_sdsp.image.tag -}}
  {{- end -}}
{{- end -}}

{{- $tag = $tag | toString -}}
{{- printf "%s%s:%s" $registry $name $tag -}}
{{- end -}}

{{/*
Generate the full sdui repository url
*/}}
{{- define "sdui_image.fullpath" -}}
{{- $registry := "" -}}
{{- $name := "" -}}
{{- $tag := "" -}}

{{- if .Values.sdui_image.image.name -}}
  {{- $name = .Values.sdui_image.image.name -}}
{{- end -}}

{{- if .Values.sdimages.tag -}}
  {{- $tag = .Values.sdimages.tag -}}
{{- end -}}
{{- if .Values.sdui_image.image.tag -}}
  {{- $tag = .Values.sdui_image.image.tag -}}
{{- end -}}

{{- if .Values.global -}}
  {{- if .Values.global.imageRegistry -}}
    {{- $registry = .Values.global.imageRegistry -}}
  {{- end -}}
{{- end -}}

{{- if .Values.global -}}
  {{- if .Values.global.sdimages -}}
    {{- if .Values.global.sdimages.registry -}}
      {{- $registry = .Values.global.sdimages.registry -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- if .Values.sdimages.registry -}}
  {{- $registry = .Values.sdimages.registry -}}
{{- end -}}

{{- if .Values.sdui_image.image.registry -}}
  {{- $registry = .Values.sdui_image.image.registry -}}
{{- end -}}

{{- $tag = $tag | toString -}}
{{- printf "%s%s:%s" $registry $name $tag -}}
{{- end -}}

{{/*
Generate the full sd snmp repository url
*/}}
{{- define "sdsnmp_image.fullpath" -}}
{{- $registry := "" -}}
{{- $name := "" -}}
{{- $tag := "" -}}

{{- if .Values.deployment_sdsnmp.image.name -}}
  {{- $name = .Values.deployment_sdsnmp.image.name -}}
{{- end -}}

{{- if .Values.sdimages.tag -}}
  {{- $tag = .Values.sdimages.tag -}}
{{- end -}}
{{- if .Values.deployment_sdsnmp.image.tag -}}
  {{- $tag = .Values.deployment_sdsnmp.image.tag -}}
{{- end -}}

{{- if .Values.global -}}
  {{- if .Values.global.imageRegistry -}}
    {{- $registry = .Values.global.imageRegistry -}}
  {{- end -}}
{{- end -}}

{{- if .Values.global -}}
  {{- if .Values.global.sdimages -}}
    {{- if .Values.global.sdimages.registry -}}
      {{- $registry = .Values.global.sdimages.registry -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- if .Values.sdimages.registry -}}
  {{- $registry = .Values.sdimages.registry -}}
{{- end -}}

{{- if .Values.deployment_sdsnmp.image.registry -}}
  {{- $registry = .Values.deployment_sdsnmp.image.registry -}}
{{- end -}}

{{- $tag = $tag | toString -}}
{{- printf "%s%s:%s" $registry $name $tag -}}
{{- end -}}

{{/*
Generate the full fluentd repository url
*/}}
{{- define "fluentdrepository.fullpath" -}}
{{- if .Values.fluentd -}}
{{- if .Values.fluentd.fluentd_repository -}}
{{- printf "%s" .Values.fluentd.fluentd_repository -}}
{{- end -}}
{{- printf "%s" .Values.fluentd.fluentd_name -}}
{{- if .Values.fluentd.fluentd_tag -}}
{{- printf ":%s" .Values.fluentd.fluentd_tag -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "sd-cl.labels" -}}
app.kubernetes.io/name: {{ include "sd-cl.name" . }}
helm.sh/chart: {{ include "sd-cl.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
If serviceAccount.name is specified, use that, else use the sd-cl instance name
*/}}
{{- define "sd-cl.serviceAccount" -}}
{{- if .Values.serviceAccount.name -}}
{{- .Values.serviceAccount.name }}
{{- else -}}
{{- template "sd-cl.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
SD-SP and SD-CL metadata helper
*/}}
{{- define "sd-helm-chart.sdsp.statefulset.metadata" -}}
labels:
  {{- if .Values.install_assurance }}
  app: {{.Values.statefulset_sdcl.app}}
  {{- else }}
  app: {{.Values.statefulset_sdsp.app}}
  {{- end }}
  app.kubernetes.io/component: sd
namespace: {{.Release.Namespace}}
{{- end -}}

{{/*
SD-SP and SD-CL spec helper
*/}}
{{- define "sd-helm-chart.sdsp.statefulset.spec" -}}
selector:
  matchLabels:
    {{- if .Values.install_assurance }}
    app: {{.Values.statefulset_sdcl.app}}
    {{- else }}
    app: {{.Values.statefulset_sdsp.app}}
    {{- end }}
template:
  metadata:
    labels:
      {{- if .Values.install_assurance }}
      app: {{.Values.statefulset_sdcl.app}}
      {{- else }}
      app: {{.Values.statefulset_sdsp.app}}
      {{- end }}
      {{- range $key, $val := .Values.sdimage.labels }}
      {{ $key }}: {{ $val | quote }}
      {{- end }}
{{- end -}}

{{/*
SD-SP and SD-CL spec template container sd helper
*/}}
{{- define "sd-helm-chart.sdsp.statefulset.spec.template.containers.sd" -}}
{{- if (.Values.install_assurance) }}
- name: {{.Values.statefulset_sdcl.name}}
{{- else }}
- name: {{.Values.statefulset_sdsp.name}}
{{- end }}
  image: "{{ template "sdimage.fullpath" . }}"
  imagePullPolicy: {{ include "resolve.imagePullPolicy" (dict "top" . "specificPullPolicy" .Values.sdimages.pullPolicy) }}
  ports:
  - containerPort: {{ .Values.sdimage.ports.containerPort }}
    name: {{ .Values.sdimage.ports.name }}
{{- if not (.Values.sdimage.metrics_proxy.enabled) }}
  - containerPort: 9990
    name: metrics
{{- end }}
  startupProbe:
    exec:
      command:
        - /docker/healthcheck.sh
    failureThreshold: {{ .Values.sdimage.startupProbe.failureThreshold }}
    periodSeconds: {{ .Values.sdimage.startupProbe.periodSeconds }}
  livenessProbe:
    exec:
      command:
        - /docker/healthcheck.sh
    failureThreshold: {{ .Values.sdimage.livenessProbe.failureThreshold }}
    periodSeconds: {{ .Values.sdimage.livenessProbe.periodSeconds }}
  readinessProbe:
    exec:
      command:
        - /docker/healthcheck.sh
    failureThreshold: {{ .Values.sdimage.readinessProbe.failureThreshold }}
    periodSeconds: {{ .Values.sdimage.readinessProbe.periodSeconds }}
  resources:
    requests:
      memory: {{ .Values.sdimage.memoryrequested }}
      cpu: {{ .Values.sdimage.cpurequested }}
    limits:
  {{- if (.Values.sdimage.memorylimit ) }}
      memory: {{ .Values.sdimage.memorylimit }}
  {{- end }}
  {{- if (.Values.sdimage.cpulimit ) }}
      cpu: {{ .Values.sdimage.cpulimit }}
  {{- end }}
  {{- with .Values.sdimage.topologySpreadConstraints }}
  topologySpreadConstraints:
  {{ tpl (toYaml .) $ | indent 10 }}
  {{- end }}
  {{- if (.Values.sdimage.licenseEnabled) }}
  lifecycle:
    postStart:
      exec:
        command:
          - /bin/sh
          - -c
          - cp /mnt/license /license
  {{- end }}
  volumeMounts:
  {{- if (.Values.sdimage.licenseEnabled) }}
  - name: sd-license
    mountPath: "/mnt"
    readOnly: true
  {{- end }}
  {{- if (eq (include "elk.enabled" .) "true") }}
  - name: jboss-log
    mountPath: /opt/HP/jboss/standalone/log/
  - name: sa-log
    mountPath: /var/opt/OV/ServiceActivator/log/
  - name: snmp-log
    mountPath: /opt/sd-asr/adapter/log/
  {{- end }}
  {{- if (eq (include "prometheus.enabled" .) "true") }}
  - name: wfconfig
    mountPath: /etc/opt/OV/ServiceActivator/config/mwfm/config-selfmonitor.xml
    readOnly: true
    subPath: config.xml
  - name: alarms-log
    mountPath: /var/opt/OV/ServiceActivator/alarms/
  - name: public-mng-interface
    mountPath: /docker/scripts/startup/02_public_ifaces.sh
    subPath: 02_public_ifaces.sh
  {{- end }}
  {{- if (.Values.sdimage.sshEnabled) }}
  - name: ssh-identity
    mountPath: "/ssh"
    readOnly: true
  {{- end }}
  {{- if .Values.sdimage.env_configmap_name }}
  envFrom:
  - configMapRef:
      name: {{ .Values.sdimage.env_configmap_name }}
  {{- end }}
{{- end -}}

{{/*
SD-SP and SD-CL spec template container sd helper
*/}}
{{- define "sd-helm-chart.sdsp.statefulset.spec.template.containers.sd.env" -}}
- name: SDCONF_activator_db_vendor
  value: "{{ .Values.sdimage.env.SDCONF_activator_db_vendor }}"
- name: SDCONF_activator_db_hostname
  value: "{{- tpl .Values.sdimage.env.SDCONF_activator_db_hostname $ }}"
{{- if (.Values.sdimage.env.SDCONF_activator_db_port) }}
- name: SDCONF_activator_db_port
  value: "{{ .Values.sdimage.env.SDCONF_activator_db_port }}"
{{- end }}
- name: SDCONF_activator_db_instance
  value: "{{ .Values.sdimage.env.SDCONF_activator_db_instance }}"
- name: SDCONF_activator_db_user
  value: "{{ .Values.sdimage.env.SDCONF_activator_db_user }}"
- name: SDCONF_activator_db_password
  valueFrom:
    secretKeyRef:
      key: "{{ .Values.sdimage.env.SDCONF_activator_db_password_key }}"
      name: "{{ .Values.sdimage.env.SDCONF_activator_db_password_name }}"
{{- if .Values.kafka.enabled }}
- name: SDCONF_asr_kafka_brokers
  value: {{ .Values.statefulset_sdcl.env.SDCONF_asr_kafka_brokers | quote}}
- name: SDCONF_asr_zookeeper_nodes
  value: {{ .Values.statefulset_sdcl.env.SDCONF_asr_zookeeper_nodes | quote }}
{{- end }}
{{- if (.Values.sdimage.env.SDCONF_activator_rolling_upgrade ) }}
- name: SDCONF_activator_rolling_upgrade
  value: "{{ .Values.sdimage.env.SDCONF_activator_rolling_upgrade }}"
{{- end }}
{{- if (.Values.sdimage.env.SDCONF_install_om ) }}
- name: SDCONF_install_om
  value: "{{ .Values.sdimage.env.SDCONF_install_om }}"
{{- end }}
{{- if (.Values.sdimage.env.SDCONF_install_omtmfgw ) }}
- name: SDCONF_install_omtmfgw
  value: "{{ .Values.sdimage.env.SDCONF_install_omtmfgw }}"
{{- end }}
{{- if (.Values.sdimage.env.SDCONF_activator_conf_jvm_max_memory ) }}
- name: SDCONF_activator_conf_jvm_max_memory
  value: "{{ .Values.sdimage.env.SDCONF_activator_conf_jvm_max_memory }}"
{{- end }}
{{- if (.Values.sdimage.env.SDCONF_activator_conf_jvm_min_memory ) }}
- name: SDCONF_activator_conf_jvm_min_memory
  value: "{{ .Values.sdimage.env.SDCONF_activator_conf_jvm_min_memory }}"
{{- end }}
{{- if (.Values.sdimage.env.SDCONF_activator_conf_activation_max_threads ) }}
- name: SDCONF_activator_conf_activation_max_threads
  value: "{{ .Values.sdimage.env.SDCONF_activator_conf_activation_max_threads }}"
{{- end }}
{{- if (.Values.sdimage.env.SDCONF_activator_conf_activation_min_threads ) }}
- name: SDCONF_activator_conf_activation_min_threads
  value: "{{ .Values.sdimage.env.SDCONF_activator_conf_activation_min_threads }}"
{{- end }}
{{- if (.Values.sdimage.env.SDCONF_activator_conf_pool_defaultdb_max ) }}
- name: SDCONF_activator_conf_pool_defaultdb_max
  value: "{{ .Values.sdimage.env.SDCONF_activator_conf_pool_defaultdb_max }}"
{{- end }}
{{- if (.Values.sdimage.env.SDCONF_activator_conf_pool_defaultdb_min ) }}
- name: SDCONF_activator_conf_pool_defaultdb_min
  value: "{{ .Values.sdimage.env.SDCONF_activator_conf_pool_defaultdb_min }}"
{{- end }}
{{- if (.Values.sdimage.env.SDCONF_activator_conf_pool_inventorydb_max ) }}
- name: SDCONF_activator_conf_pool_inventorydb_max
  value: "{{ .Values.sdimage.env.SDCONF_activator_conf_pool_inventorydb_max }}"
{{- end }}
{{- if (.Values.sdimage.env.SDCONF_activator_conf_pool_inventorydb_min ) }}
- name: SDCONF_activator_conf_pool_inventorydb_min
  value: "{{ .Values.sdimage.env.SDCONF_activator_conf_pool_inventorydb_min }}"
{{- end }}
{{- if (.Values.sdimage.env.SDCONF_activator_conf_pool_mwfmdb_max ) }}
- name: SDCONF_activator_conf_pool_mwfmdb_max
  value: "{{ .Values.sdimage.env.SDCONF_activator_conf_pool_mwfmdb_max }}"
{{- end }}
{{- if (.Values.sdimage.env.SDCONF_activator_conf_pool_mwfmdb_min ) }}
- name: SDCONF_activator_conf_pool_mwfmdb_min
  value: "{{ .Values.sdimage.env.SDCONF_activator_conf_pool_mwfmdb_min }}"
{{- end }}
{{- if (.Values.sdimage.env.SDCONF_activator_conf_pool_resmgrdb_max ) }}
- name: SDCONF_activator_conf_pool_resmgrdb_max
  value: "{{ .Values.sdimage.env.SDCONF_activator_conf_pool_resmgrdb_max }}"
{{- end }}
{{- if (.Values.sdimage.env.SDCONF_activator_conf_pool_resmgrdb_min ) }}
- name: SDCONF_activator_conf_pool_resmgrdb_min
  value: "{{ .Values.sdimage.env.SDCONF_activator_conf_pool_resmgrdb_min }}"
{{- end }}
{{- if (.Values.sdimage.env.SDCONF_activator_conf_pool_servicedb_max ) }}
- name: SDCONF_activator_conf_pool_servicedb_max
  value: "{{ .Values.sdimage.env.SDCONF_activator_conf_pool_servicedb_max }}"
{{- end }}
{{- if (.Values.sdimage.env.SDCONF_activator_conf_pool_servicedb_min ) }}
- name: SDCONF_activator_conf_pool_servicedb_min
  value: "{{ .Values.sdimage.env.SDCONF_activator_conf_pool_servicedb_min }}"
{{- end }}
{{- if (.Values.sdimage.env.SDCONF_activator_conf_pool_uidb_max ) }}
- name: SDCONF_activator_conf_pool_uidb_max
  value: "{{ .Values.sdimage.env.SDCONF_activator_conf_pool_uidb_max }}"
{{- end }}
{{- if (.Values.sdimage.env.SDCONF_activator_conf_pool_uidb_min ) }}
- name: SDCONF_activator_conf_pool_uidb_min
  value: "{{ .Values.sdimage.env.SDCONF_activator_conf_pool_uidb_min }}"
{{- end }}
{{- if (.Values.sdimage.sshEnabled) }}
- name: SDCONF_activator_conf_ssh_identity
  value: /ssh/identity
{{- end }}
{{- if (.Values.sdimage.env.SDCONF_activator_conf_file_log_pattern ) }}
- name: SDCONF_activator_conf_file_log_pattern
  value: "{{ squote .Values.sdimage.env.SDCONF_activator_conf_file_log_pattern }}"
{{- end }}
{{- end -}}

{{/*
SD-SP and SD-CL spec template container fluentd helper
*/}}
{{- define "sd-helm-chart.sdsp.statefulset.spec.template.containers.fluentdsd" -}}
{{- if and (or (eq (include "prometheus.enabled" .) "true") (eq (include "elk.enabled" .) "true")) (.Values.elk.fluentd.enabled) }}
- name: fluentd
  image: "{{ include "fluentdrepository.fullpath" . }}"
  imagePullPolicy: {{ include "resolve.imagePullPolicy" (dict "top" . "specificPullPolicy" "") }}
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
  - containerPort: 9144
    name: 9144tcp01
  - containerPort: 24231
    name: metrics
  resources:
    requests:
      memory: {{ .Values.fluentd.memoryrequested }}
      cpu: {{ .Values.fluentd.cpurequested }}
    limits:
      {{- if (.Values.fluentd.memorylimit) }}
      memory: {{ .Values.fluentd.memorylimit }}
      {{- end }}
      {{- if (.Values.fluentd.cpulimit) }}
      cpu: {{ .Values.fluentd.cpulimit }}
      {{- end }}
  volumeMounts:
{{- if and (or (eq (include "elk.enabled" .) "true") (eq (include "prometheus.enabled" .) "true")) (.Values.elk.fluentd.enabled) }}
  - mountPath: /opt/bitnami/fluentd/conf/
    name: fluentd-config
  - mountPath: /opt/bitnami/fluentd/logs/buffers
    name: buffer
{{- end }}
{{- if (eq (include "prometheus.enabled" .) "true") }}
  - name: alarms-log
    mountPath: /alarms-log/
    subPathExpr: $(POD_NAME)
{{- end }}
{{- if (eq (include "elk.enabled" .) "true") }}
  - name: jboss-log
    mountPath: /jboss-log
  - name: sa-log
    mountPath: /sa-log
    subPathExpr: $(POD_NAME)
  - name: snmp-log
    mountPath: /snmp-log
{{- end }}
{{- end -}}
{{- end -}}

{{/*
UI spec template container fluentd helper
*/}}
{{- define "sd-helm-chart.sdsp.statefulset.spec.template.containers.fluentdui" -}}
{{- if and (eq (include "elk.enabled" .) "true") (.Values.elk.fluentd.enabled) }}
- name: fluentd
  image: "{{ include "fluentdrepository.fullpath" . }}"
  imagePullPolicy: {{ include "resolve.imagePullPolicy" (dict "top" . "specificPullPolicy" "") }}
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
  - containerPort: 9144
    name: 9144tcp01
  - containerPort: 24231
    name: metrics
  resources:
    requests:
      memory: {{ .Values.fluentd.memoryrequested }}
      cpu: {{ .Values.fluentd.cpurequested }}
    limits:
      {{- if (.Values.fluentd.memorylimit ) }}
      memory: {{ .Values.fluentd.memorylimit }}
      {{- end }}
      {{- if (.Values.fluentd.cpulimit ) }}
      cpu: {{ .Values.fluentd.cpulimit }}
      {{- end }}
  volumeMounts:
  - mountPath: /opt/bitnami/fluentd/conf/
    name: fluentd-config-ui
  - mountPath: /opt/bitnami/fluentd/logs/buffers
    name: buffer
  - name: uoc-log
    mountPath: /uoc-log

{{- end -}}
{{- end -}}

{{/*
SD-SP and SD-CL spec template container envoy helper
*/}}
{{- define "sd-helm-chart.sdsp.statefulset.spec.template.containers.envoy" -}}
{{- if (.Values.sdimage.metrics_proxy.enabled) }}
{{- if or (eq (include "prometheus.enabled" .) "true") (.Values.sdimage.metrics.enabled) }}
- name: envoy
  image: bitnami/envoy:1.16.5
  imagePullPolicy: {{ include "resolve.imagePullPolicy" (dict "top" . "specificPullPolicy" "") }}
  ports:
  - containerPort: 9991
    name: frontend
    protocol: TCP
  volumeMounts:
  - mountPath: /opt/bitnami/envoy/conf/envoy.yaml
    name: envoy-config-metrics
    readOnly: true
    subPath: envoy.yaml
{{- end }}
{{- end }}
{{- end -}}

{{/*
SD-SP and SD-CL spec template container filebeat helper
*/}}
{{- define "sd-helm-chart.filebeat.container" -}}
- name: filebeat
  image: docker.elastic.co/beats/filebeat:{{.Values.elk.version}}
  imagePullPolicy: {{ include "resolve.imagePullPolicy" (dict "top" . "specificPullPolicy" "") }}
  env:
  - name: POD_NAME
    valueFrom:
      fieldRef:
        apiVersion: v1
        fieldPath: metadata.name
  args: [
    "-c", "/etc/filebeat.yml",
    "-e",
  ]
  ports:
  - name: filebeat-http
    containerPort: 5066
    protocol: TCP
  startupProbe:
    exec:
      command:
        - sh
        - -c
        - |
          #!/usr/bin/env bash -e
          filebeat test config
    failureThreshold: 10
    periodSeconds: 10
    timeoutSeconds: 10
  livenessProbe:
    exec:
      command:
        - sh
        - -c
        - |
          #!/usr/bin/env bash -e
          curl --fail 127.0.0.1:5066
    failureThreshold: 10
    periodSeconds: 10
    timeoutSeconds: 10
  readinessProbe:
    exec:
      command:
        - sh
        - -c
        - |
          #!/usr/bin/env bash -e
          filebeat test config
    failureThreshold: 10
    periodSeconds: 10
    timeoutSeconds: 10
  resources:
    requests:
      memory: {{ .Values.sdimage.filebeat.memoryrequested }}
      cpu: {{ .Values.sdimage.filebeat.cpurequested }}
    limits:
      {{- if (.Values.sdimage.filebeat.memorylimit ) }}
      memory: {{ .Values.sdimage.filebeat.memorylimit }}
      {{- end }}
      {{- if (.Values.sdimage.filebeat.cpulimit ) }}
      cpu: {{ .Values.sdimage.filebeat.cpulimit }}
      {{- end }}
{{- end -}}

{{/*
SD-SP and SD-CL spec template container filebeat helper
*/}}
{{- define "sd-helm-chart.sdsp.statefulset.spec.template.containers.filebeat" -}}
{{- if and (eq (include "elk.enabled" .) "true") (.Values.elk.filebeat.enabled) (not .Values.elk.fluentd.enabled) }}
{{ include "sd-helm-chart.filebeat.container" . }}
  volumeMounts:
  - name: jboss-log
    mountPath: /jboss-log
  - name: sa-log
    mountPath: /sa-log
    subPathExpr: $(POD_NAME)
  - name: snmp-log
    mountPath: /snmp-log
   # needed to access additional informations about containers
  - name: filebeatconfig
    mountPath: /etc/filebeat.yml
    readOnly: true
    subPath: filebeat.yml
  - name: data
    mountPath: /usr/share/filebeat/data
  - name: varlog
    mountPath: /var/log/filebeat
{{- end }}
{{- end -}}

{{/*
SD-SP and SD-CL spec template container volumes helper
*/}}
{{- define "sd-helm-chart.sdsp.statefulset.spec.template.containers.volumes" -}}
{{- if (.Values.sdimage.metrics_proxy.enabled) }}
- name: envoy-config-metrics
  configMap:
    defaultMode: 420
    name: envoy-metrics
{{- end }}
{{- if or (and  (eq (include "elk.enabled" .) "true")  (.Values.elk.fluentd.enabled) ) (eq (include "prometheus.enabled" .) "true") }}
- name: fluentd-config
  configMap:
    defaultMode: 420
    name: fluentd-config
- name: buffer
  emptyDir: {}
{{- end }}
{{- if (.Values.licenseEnabled) }}
- name: sd-license
  secret:
    secretName: sd-license-secret
{{- end }}
{{- if (eq (include "prometheus.enabled" .) "true") }}
- name: wfconfig
  configMap:
    defaultMode: 0644
    name: wf-config
- name: public-mng-interface
  configMap:
    defaultMode: 0644
    name: public-mng-interface
- name: alarms-log
  emptyDir: {}
{{- end }}
{{- if and (eq (include "elk.enabled" .) "true") (.Values.elk.filebeat.enabled) (not .Values.elk.fluentd.enabled) }}
- name: filebeatconfig
  configMap:
    defaultMode: 0644
    name: filebeat-config
- name: varlog
  emptyDir: {}
- name: data
  emptyDir: {}
{{- end }}
{{- if (eq (include "elk.enabled" .) "true") }}
- name: jboss-log
  emptyDir: {}
- name: sa-log
  emptyDir: {}
- name: snmp-log
  emptyDir: {}
{{- end }}
{{- if (.Values.sdimage.sshEnabled) }}
- name: ssh-identity
  secret:
    secretName: ssh-identity
    defaultMode: 0600
{{- end }}
{{- end -}}

{{/*
SD-SP and SD-CL service helper
*/}}
{{- define "sd-helm-chart.sdsp.service" -}}
apiVersion: v1
kind: Service
metadata:
  {{- if .Values.install_assurance }}
  name: {{ .Values.service_sdcl.name }}
  {{- if empty .Values.service_sdcl.labels }}
  labels: {{ include "tplvalues.render" ( dict "value" .Values.sdimage.serviceLabels "context" $) | nindent 4 }}
  {{- else }}
  labels: {{ include "tplvalues.render" ( dict "value" .Values.service_sdcl.labels "context" $) | nindent 4 }}
  {{- end }}
  {{- else }}
  name: {{ .Values.service_sdsp.name }}
  {{- if empty .Values.service_sdsp.labels }}
  labels: {{ include "tplvalues.render" ( dict "value" .Values.sdimage.serviceLabels "context" $) | nindent 4 }}
  {{- else }}
  labels: {{ include "tplvalues.render" ( dict "value" .Values.service_sdsp.labels "context" $) | nindent 4 }}
  {{- end }}
  {{- end }}
  namespace: {{.Release.Namespace}}

spec:
  {{- if .Values.install_assurance }}
  type: {{ .Values.service_sdcl.servicetype | quote }}
  {{- if and (eq .Values.service_sdcl.servicetype "LoadBalancer") (not (empty .Values.service_sdcl.loadBalancerIP)) }}
  loadBalancerIP: {{ .Values.service_sdcl.loadBalancerIP }}
  {{- end }}
  {{- else }}
  type: {{ .Values.service_sdsp.servicetype | quote }}
  {{- if and (eq .Values.service_sdsp.servicetype "LoadBalancer") (not (empty .Values.service_sdsp.loadBalancerIP)) }}
  loadBalancerIP: {{ .Values.service_sdsp.loadBalancerIP }}
  {{- end }}
  {{- end }}
  ports:
  - name: entrypoint
    protocol: TCP
    {{- if .Values.install_assurance }}
    {{- if and (or (eq .Values.service_sdcl.servicetype "NodePort") (eq .Values.service_sdcl.servicetype "LoadBalancer")) (not (empty .Values.service_sdcl.nodePort)) }}
    nodePort: {{ .Values.service_sdcl.nodePort }}
    {{- end }}
    port: {{ .Values.service_sdcl.port }}
    protocol: TCP
    targetPort: {{ .Values.service_sdcl.targetPort }}
    {{- else }}
    {{- if and (or (eq .Values.service_sdsp.servicetype "NodePort") (eq .Values.service_sdsp.servicetype "LoadBalancer")) (not (empty .Values.service_sdsp.nodePort)) }}
    nodePort: {{ .Values.service_sdsp.nodePort }}
    {{- end }}
    port: {{ .Values.service_sdsp.port }}
    protocol: TCP
    targetPort: {{ .Values.service_sdsp.targetPort }}
    {{- end }}
  selector:
    {{- if .Values.install_assurance }}
    app: {{ .Values.statefulset_sdcl.app }}
    {{- else }}
    app: {{ .Values.statefulset_sdsp.app }}
    {{- end }}
  sessionAffinity: ClientIP
{{- end -}}

{{/*
SD-SP and SD-CL prometheus service helper
*/}}
{{- define "sd-helm-chart.sdsp.service.prometheus" -}}
apiVersion: v1
kind: Service
metadata:
  {{- if .Values.install_assurance }}
  name: {{ .Values.service_sdcl.name }}-prometheus
  {{- if empty .Values.service_sdcl_prometheus.labels }}
  labels: {{ include "tplvalues.render" ( dict "value" .Values.prometheus.serviceLabels "context" $) | nindent 4 }}
  {{- else }}
  labels: {{ include "tplvalues.render" ( dict "value" .Values.service_sdcl_prometheus.labels "context" $) | nindent 4 }}
  {{- end }}
  {{- else }}
  name: {{ .Values.service_sdsp.name }}-prometheus
  {{- if empty .Values.service_sdsp_prometheus.labels }}
  labels: {{ include "tplvalues.render" ( dict "value" .Values.prometheus.serviceLabels "context" $) | nindent 4 }}
  {{- else }}
  labels: {{ include "tplvalues.render" ( dict "value" .Values.service_sdsp_prometheus.labels "context" $) | nindent 4 }}
  {{- end }}
  {{- end }}
  namespace: {{.Release.Namespace}}
spec:
  type: ClusterIP
  ports:
  - name: 9144tcp01
    port: 9144
    targetPort: 9144
  {{- if .Values.sdimage.metrics_proxy.enabled }}
  - name: 9991tcp01
    port: 9991
    targetPort: 9991
  {{- else }}
  - name: 9990tcp01
    port: 9990
    targetPort: 9990
  {{- end }}
  selector:
    {{- if .Values.install_assurance }}
    app: {{ .Values.statefulset_sdcl.app }}
    {{- else }}
    app: {{ .Values.statefulset_sdsp.app }}
    {{- end }}
  sessionAffinity: ClientIP
{{- end -}}

{{/*
SD-SP and SD-CL headless service helper
*/}}
{{- define "sd-helm-chart.sdsp.service.headless" -}}
apiVersion: v1
kind: Service
metadata:
  {{- if .Values.install_assurance }}
  name: headless-{{ .Values.service_sdcl.name }}
  {{- if empty .Values.service_sdcl.labels }}
  labels: {{ include "tplvalues.render" ( dict "value" .Values.sdimage.serviceLabels "context" $) | nindent 4 }}
  {{- else }}
  labels: {{ include "tplvalues.render" ( dict "value" .Values.service_sdcl.labels "context" $) | nindent 4 }}
  {{- end }}
  {{- else }}
  name: headless-{{ .Values.service_sdsp.name }}
  {{- if empty .Values.service_sdsp.labels }}
  labels: {{ include "tplvalues.render" ( dict "value" .Values.sdimage.serviceLabels "context" $) | nindent 4 }}
  {{- else }}
  labels: {{ include "tplvalues.render" ( dict "value" .Values.service_sdsp.labels "context" $) | nindent 4 }}
  {{- end }}
  {{- end }}
  namespace: {{.Release.Namespace}}
spec:
  clusterIP: None
  selector:
    {{- if .Values.install_assurance }}
    app: {{ .Values.statefulset_sdcl.app }}
    {{- else }}
    app: {{ .Values.statefulset_sdsp.app }}
    {{- end }}
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
      name: http
{{- end -}}

{{/*
SD-UI container helper
*/}}
{{- define "sd-helm-chart.sdui.deployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{.Values.sdui_image.name}}
  labels:
    app: {{.Values.sdui_image.app}}
  namespace: {{.Release.Namespace}}
spec:
  replicas: {{ .Values.sdui_image.replicaCount }}
  selector:
    matchLabels:
      app: {{.Values.sdui_image.app}}
  template:
    metadata:
      labels:
        app: {{.Values.sdui_image.app}}
        {{- range $key, $val := .Values.sdui_image.labels }}
        {{ $key }}: {{ $val | quote }}
        {{- end }}
    spec:
      {{- if .Values.serviceAccount.enabled }}
      serviceAccountName: {{ template "sd-cl.serviceAccount" . }}
      {{- end }}
      {{- if .Values.securityContext.enabled }}
      securityContext:
        fsGroup: {{ .Values.securityContext.fsGroup }}
        runAsUser: {{ .Values.sdui_image.securityContext.runAsUser | default .Values.securityContext.runAsUser }}
      {{- end }}
      affinity: {{- include "sd.templateValue" ( dict "value" .Values.sdui_image.affinity "context" $ ) | nindent 8 }}
      containers:
      - name: {{.Values.sdui_image.name}}
        image: "{{ template "sdui_image.fullpath" . }}"
        imagePullPolicy: {{ include "resolve.imagePullPolicy" (dict "top" . "specificPullPolicy" .Values.sdimages.pullPolicy) }}
        env:
        - name: SDCONF_sdui_async_host
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        {{- if (.Values.sdui_image.loadbalancer) }}
        - name: SDCONF_sdui_provision_host
          value: "envoy"
        - name: SDCONF_sdui_provision_port
          value: "30636"
        {{- else }}
        {{- if .Values.install_assurance }}
        - name: SDCONF_sdui_provision_host
          value: "{{ .Values.service_sdcl.name }}"
        - name: SDCONF_sdui_provision_port
          value: "{{ .Values.service_sdcl.port }}"
        {{- else }}
        - name: SDCONF_sdui_provision_host
          value: "{{ .Values.service_sdsp.name }}"
        - name: SDCONF_sdui_provision_port
          value: "{{ .Values.service_sdsp.port }}"
        {{- end }}
        {{- end }}
        - name: SDCONF_sdui_provision_password
          valueFrom:
            secretKeyRef:
              key: "{{ .Values.sdui_image.env.SDCONF_sdui_provision_password_key }}"
              name: "{{ .Values.sdui_image.env.SDCONF_sdui_provision_password_name }}"
        - name: SDCONF_sdui_provision_protocol
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_provision_protocol }}"
        - name: SDCONF_sdui_provision_tenant
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_provision_tenant }}"
        - name: SDCONF_sdui_provision_use_real_user
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_provision_use_real_user }}"
        - name: SDCONF_sdui_provision_username
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_provision_username }}"
        {{- if (.Values.sdui_image.env.SDCONF_sdui_log_format_pattern ) }}
        - name: SDCONF_sdui_log_format_pattern
          value: "{{ squote .Values.sdui_image.env.SDCONF_sdui_log_format_pattern }}"
        {{- end }}
        {{- if .Values.install_assurance }}
        - name: SDCONF_sdui_assurance_host
          value: "{{ .Values.service_sdcl.name }}"
        {{- end }}
        - name: SDCONF_sdui_install_assurance
          value: "{{ .Values.install_assurance }}"
        {{- if .Values.sdui_image.env.SDCONF_install_omui }}
        - name: SDCONF_install_omui
          value: "{{ .Values.sdui_image.env.SDCONF_install_omui }}"
        {{- end }}
        - name: SDCONF_uoc_couchdb_host
          value: "{{ .Values.couchdb.fullnameOverride }}{{ printf "-couchdb" }}"
        - name: SDCONF_uoc_couchdb_admin_username
          valueFrom:
            secretKeyRef:
              key: "{{ .Values.sdui_image.env.SDCONF_uoc_couchdb_admin_username_key }}"
              name: "{{ .Values.couchdb.fullnameOverride }}{{ printf "-couchdb" }}"
        - name: SDCONF_uoc_couchdb_admin_password
          valueFrom:
            secretKeyRef:
              key: "{{ .Values.sdui_image.env.SDCONF_uoc_couchdb_admin_password_key }}"
              name: "{{ .Values.couchdb.fullnameOverride }}{{ printf "-couchdb" }}"
        - name: SDCONF_sdui_redis
          value: "yes"
        - name: SDCONF_sdui_redis_host
          value: "{{ .Values.redis.fullnameOverride }}{{ printf "-master" }}"
        - name: SDCONF_sdui_redis_port
          value: "{{ .Values.redis.redisPort }}"
        - name: SDCONF_sdui_redis_password
          valueFrom:
            secretKeyRef:
              name: "{{ .Values.redis.existingSecret }}"
              key: "{{ .Values.redis.existingSecretPasswordKey }}"
        {{- if .Values.sdui_image.env_configmap_name }}
        envFrom:
        - configMapRef:
            name: {{ .Values.sdui_image.env_configmap_name }}
        {{- end }}
        ports:
        - containerPort: {{ .Values.sdui_image.ports.containerPort }}
          name: {{ .Values.sdui_image.ports.name }}
        startupProbe:
          exec:
            command:
              - /docker/healthcheck.sh
          failureThreshold: {{ .Values.sdui_image.startupProbe.failureThreshold }}
          periodSeconds: {{ .Values.sdui_image.startupProbe.periodSeconds }}
        livenessProbe:
          exec:
            command:
              - /docker/healthcheck.sh
          failureThreshold: {{ .Values.sdui_image.livenessProbe.failureThreshold }}
          periodSeconds: {{ .Values.sdui_image.livenessProbe.periodSeconds }}
        readinessProbe:
          exec:
            command:
              - /docker/healthcheck.sh
          failureThreshold: {{ .Values.sdui_image.readinessProbe.failureThreshold }}
          periodSeconds: {{ .Values.sdui_image.readinessProbe.periodSeconds }}
        resources:
          requests:
            memory: {{ .Values.sdui_image.memoryrequested }}
            cpu: {{ .Values.sdui_image.cpurequested }}
          limits:
            {{- if (.Values.sdui_image.memorylimit) }}
            memory: {{ .Values.sdui_image.memorylimit }}
            {{- end }}
            {{- if (.Values.sdui_image.cpulimit) }}
            cpu: {{ .Values.sdui_image.cpulimit }}
            {{- end }}
        {{- if (eq (include "elk.enabled" .) "true") }}
        volumeMounts:
        - name: uoc-log
          mountPath: /var/opt/uoc2/logs
        {{- end }}
      {{- if (.Values.sdui_image.loadbalancer) }}
      - name: envoy
        image: bitnami/envoy:{{ .Values.sdui_image.envoy_version }}
        imagePullPolicy: {{ include "resolve.imagePullPolicy" (dict "top" . "specificPullPolicy" "") }}
        livenessProbe:
          failureThreshold: 3
          initialDelaySeconds: 15
          periodSeconds: 20
          successThreshold: 1
          tcpSocket:
            port: frontend
          timeoutSeconds: 1
        ports:
        - containerPort: 30636
          name: frontend
          protocol: TCP
        volumeMounts:
        - mountPath: /opt/bitnami/envoy/conf/
          name: envoy-config
      {{- end }}
      {{- if and (eq (include "elk.enabled" .) "true") (.Values.elk.fluentd.enabled) }}
{{ include "sd-helm-chart.sdsp.statefulset.spec.template.containers.fluentdui" . | indent 6 }}
      {{- else if (eq (include "elk.enabled" .) "true") }}
{{ include "sd-helm-chart.filebeat.container" . | indent 6 }}
        volumeMounts:
        # needed to access additional informations about containers
        - name: config
          mountPath: /etc/filebeat.yml
          readOnly: true
          subPath: filebeat.yml
        - name: data
          mountPath: /usr/share/filebeat/data
          subPathExpr: $(POD_NAME)
        - name: varlog
          mountPath: /var/log/filebeat
        - name: uoc-log
          mountPath: /uoc-log
      {{- end }}
      volumes:
      {{- if and (eq (include "elk.enabled" .) "true") (.Values.elk.fluentd.enabled) }}
      - name: fluentd-config-ui
        configMap:
          defaultMode: 420
          name: fluentd-config-ui
      - name: buffer
        emptyDir: {}
      - name: uoc-log
        emptyDir: {}
      {{- else }}
      - name: config
        configMap:
          defaultMode: 0644
          name: filebeat-config-ui
      - name: varlog
        emptyDir: {}
      # data folder stores a registry of read status for all files, so we dont send everything again on a Filebeat pod restart
      - name: data
        emptyDir: {}
      - name: uoc-log
        emptyDir: {}
      {{- end }}
      {{- if (.Values.sdui_image.loadbalancer) }}
      - configMap:
          defaultMode: 420
          name: envoy
        name: envoy-config
      {{- end }}
{{- end -}}

{{/*
SD-UI service helper
*/}}
{{- define "sd-helm-chart.sdui.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.service_sdui.name }}
  namespace: {{.Release.Namespace}}
  {{- if empty .Values.service_sdui.labels }}
  labels: {{ include "tplvalues.render" ( dict "value" .Values.sdui_image.serviceLabels "context" $) | nindent 4 }}
  {{- else }}
  labels: {{ include "tplvalues.render" ( dict "value" .Values.service_sdui.labels "context" $) | nindent 4 }}
  {{- end }}
spec:
  type: {{ .Values.service_sdui.servicetype | quote }}
  {{- if and (eq .Values.service_sdui.servicetype "LoadBalancer") (not (empty .Values.service_sdui.loadBalancerIP)) }}
  loadBalancerIP: {{ .Values.service_sdui.loadBalancerIP }}
  {{- end }}
  ports:
  - name: 3000tcp01
    {{- if and (or (eq .Values.service_sdui.servicetype "NodePort") (eq .Values.service_sdui.servicetype "LoadBalancer")) (not (empty .Values.service_sdui.nodePort)) }}
    nodePort: {{ .Values.service_sdui.nodePort }}
    {{- end }}
    port: {{ .Values.service_sdui.port }}
    protocol: TCP
    targetPort: {{ .Values.service_sdui.targetPort }}
  selector:
    app: {{ .Values.sdui_image.app }}
  sessionAffinity: ClientIP
{{- end -}}

{{/*

Renders a value that contains template.
{{ include "sd.templateValue" ( dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "sd.templateValue" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}


{{/*
Generate the proper ImagePullPolicy. Always by default for security reasons.
*/}}
{{- define "resolve.imagePullPolicy" -}}
  {{- $top := index . "top" -}} {{/* in order to extract the global value */}}
  {{- $spcPullPolicy := index . "specificPullPolicy" -}} {{/* specific value */}}
  {{- $result := "Always" -}} {{/* default value */}}

  {{- if $top.Values.global -}}
    {{- if $top.Values.global.pullPolicy -}}
      {{- $result = $top.Values.global.pullPolicy -}}
    {{- end -}}
  {{- end -}}

  {{/* If an specific value exists, then it overrides the global value */}}
  {{- if (not (empty $spcPullPolicy)) -}}
    {{- $result = $spcPullPolicy -}}
  {{- end -}}

  {{ print $result }}

{{- end -}}


{{/*
Generate the full healthcheck repository url
*/}}
{{- define "healthcheck.fullpath" -}}
{{- $registry := "" -}}
{{- $name := "" -}}
{{- $tag := "" -}}


{{- $name = .Values.healthcheck.name -}}

{{- if .Values.global -}}
  {{- if .Values.global.sdimage -}}
    {{- if .Values.global.sdimage.tag -}}
       {{- $tag = .Values.global.sdimage.tag -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- if .Values.sdimages.tag -}}
  {{- $tag = .Values.sdimages.tag -}}
{{- end -}}
{{- if .Values.healthcheck.tag -}}
  {{- $tag = .Values.healthcheck.tag -}}
{{- end -}}

{{- if .Values.global -}}
  {{- if .Values.global.imageRegistry -}}
    {{- $registry = .Values.global.imageRegistry -}}
  {{- end -}}
{{- end -}}
{{- if .Values.sdimages.registry -}}
  {{- $registry = .Values.sdimages.registry -}}
{{- end -}}
{{- if .Values.healthcheck.registry -}}
  {{- $registry = .Values.healthcheck.registry -}}
{{- end -}}


{{- $tag = $tag | toString -}}
{{- printf "%s%s:%s" $registry $name $tag -}}
{{- end -}}