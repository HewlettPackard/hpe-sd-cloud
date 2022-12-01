
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
{{- define "monitoring.namespace" -}}
{{- if .Values.monitoringNamespace -}}
  {{- printf "%s" .Values.monitoringNamespace -}}
{{- else -}}
  {{- printf "%s" .Release.Namespace -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper storage class for elasticsearch, it can be defined in several parameters, this is the priority order:
1. global.storageClas
2. efk.elastic.storageClass
A volume is bound on /usr/share/elasticsearch/data so the data of your Elasticsearch node won’t be lost if the container is killed
*/}}
{{- define "sd-helm-chart.elastic.storageclass" -}}
{{- if .Values.global -}}
  {{- if .Values.global.storageClass -}}
    {{- printf "%s" .Values.global.storageClass -}}
  {{- end -}}
{{- end -}}
{{- if .Values.efk.elastic.storageClass -}}
    {{- printf "%s" .Values.efk.elastic.storageClass -}}
{{- end -}}
{{- end -}}

{{/*
Return a boolean that states if efk example is enabled, it can be defined in several parameters, this is the priority order:
1. global.efk.enabled
2. efk.enabled
3. false
*/}}
{{- define "efk.enabled" -}}
{{- if .Values.efk.enabled -}}
  {{- .Values.efk.enabled -}}
{{- end -}}

{{- if .Values.global -}}
  {{- if .Values.global.efk -}}
    {{- if .Values.global.efk.enabled -}}
      {{- .Values.global.efk.enabled -}}
    {{- else -}}
      {{- printf "false" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- end -}}

{{/*
Return a boolean that states if Prometheus example is enabled, it can be defined in several parameters, this is the priority order:
1. global.prometheus.enabled
2. prometheus.enabled
3. false
*/}}
{{- define "prometheus.enabled" -}}
{{- if .Values.prometheus.enabled -}}
  {{- .Values.prometheus.enabled -}}
{{- end -}}

{{- if .Values.global -}}
  {{- if .Values.global.prometheus -}}
    {{- if .Values.global.prometheus.enabled -}}
      {{- .Values.global.prometheus.enabled -}}
    {{- else -}}
      {{- printf "false" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "sd-cl.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Generate the full SD-SP or SD-CL repository url: registry + image name + tag(version)
It can be defined in several parameters, this is the priority order that will be used for registries:

1. global.sdimages.registry, affects only sd images
2. global.imageRegistry, affects all, including dependencies that support it
3. specific - StatefulSet or Deployment's .image.registry (for each case individually)
4. sdimages.registry

this is the priority order that will be used for tags:

1. global.sdimage.tag
2. specific - StatefulSet or Deployment's .image.registry
3. sdimage.tag
4. sdimages.tag

*/}}
{{- define "sdimage.fullpath" -}}
{{- $registry := "" -}}
{{- $name := "" -}}
{{- $tag := "" -}}
{{- $isAssurance := .Values.install_assurance | toString -}}

{{- if .Values.sdimages.registry -}}
  {{- $registry = .Values.sdimages.registry -}}
{{- end -}}

{{- if .Values.sdimages.tag -}}
  {{- $tag = .Values.sdimages.tag -}}
{{- end -}}

{{- if .Values.sdimage.tag -}}
  {{- $tag = .Values.sdimage.tag -}}
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

{{- if .Values.global -}}
  {{- if .Values.global.sdimage -}}
    {{- if .Values.global.sdimage.tag -}}
       {{- $tag = .Values.global.sdimage.tag -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- $tag = $tag | toString -}}
{{- if $tag -}}
{{- printf "%s%s:%s" $registry $name $tag -}}
{{- else -}}
{{- fail "Any of: sdimages.tag, global.sdimage.tag, statefulset_sdsp.image.tag or statufulset_sdcl.image.tag must be provided" -}}
{{- end -}}

{{- end -}}

{{/*
Generate the full SD-UI repository url:  registry + image name + tag(version)
It can be defined in several parameters, this is the priority order that will be used for registries:

1. global.sdimages.registry, affects only sd images
2. global.imageRegistry, affects all, including dependencies that support it
3. specific - StatefulSet or Deployment's .image.registry (for each case individually)
4. sdimages.registry

this is the priority order that will be used for tags:

1. global.sdimage.tag
2. specific - StatefulSet or Deployment's .image.registry
3. sdimages.tag

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

{{- if .Values.sdimages.registry -}}
  {{- $registry = .Values.sdimages.registry -}}
{{- end -}}

{{- if .Values.sdui_image.image.registry -}}
  {{- $registry = .Values.sdui_image.image.registry -}}
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

{{- $tag = $tag | toString -}}
{{- if $tag -}}
  {{- printf "%s%s:%s" $registry $name $tag -}}
{{- else -}}
  {{- fail "Any of: sdimages.tag or sdui_image.image.tag must be provided" -}}
{{- end -}}

{{- end -}}

{{/*
Generates the full SD SNMP repository url: registry + image name + tag(version)
It can be defined in several parameters, this is the priority order that will be used for registries:

1. global.sdimages.registry, affects only sd images
2. global.imageRegistry, affects all, including dependencies that support it
3. specific - StatefulSet or Deployment's .image.registry (for each case individually)
4. sdimages.registry

this is the priority order that will be used for tags:

1. global.sdimage.tag
2. specific - StatefulSet or Deployment's .image.registry
3. sdimages.tag

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

{{- if .Values.sdimages.registry -}}
  {{- $registry = .Values.sdimages.registry -}}
{{- end -}}

{{- if .Values.deployment_sdsnmp.image.registry -}}
  {{- $registry = .Values.deployment_sdsnmp.image.registry -}}
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

{{- $tag = $tag | toString -}}
{{- if $tag -}}
  {{- printf "%s%s:%s" $registry $name $tag -}}
{{- else -}}
  {{- fail "Any of: sdimages.tag or deployment_sdsnmp.image.tag must be provided" -}}
{{- end -}}

{{- end -}}

{{/*
Generate the full repository url for Envoy container:  registry + image name + tag(version)
*/}}
{{- define "envoy.fullpath" -}}
{{- if .Values.envoy -}}
  {{- if .Values.envoy.image.registry -}}
    {{- printf "%s" .Values.envoy.image.registry -}}
  {{- end -}}
  {{- if .Values.envoy.image.name -}}
    {{- printf "%s" .Values.envoy.image.name -}}
  {{- end -}}
  {{- if .Values.envoy.image.tag -}}
    {{- printf ":%s" .Values.envoy.image.tag -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Generate the full repository url for Fluentd container :  registry + image name + tag(version)
*/}}
{{- define "fluentd.fullpath" -}}
{{- if .Values.fluentd -}}
  {{- if .Values.fluentd.image.registry -}}
    {{- printf "%s" .Values.fluentd.image.registry -}}
  {{- end -}}
  {{- if .Values.fluentd.image.name -}}
    {{- printf "%s" .Values.fluentd.image.name -}}
  {{- end -}}
  {{- if .Values.fluentd.image.tag -}}
    {{- printf ":%s" .Values.fluentd.image.tag -}}
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
Generate the Service Account values for the SD-CL containers, values are taken from values.yaml file.
It will generate the parameters for the pod depending on the parameters included in values.yaml.
*/}}
{{- define "sd-cl.serviceAccount" -}}
{{- if .Values.serviceAccount.name -}}
{{- .Values.serviceAccount.name }}
{{- else -}}
{{- template "sd-cl.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Generate the metadata values for the SD-SP and SD-CL containers, values are taken from values.yaml file.
It will generate the parameters for the pod depending on the parameters included in values.yaml.
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
Generate the spec values for the SD-SP and SD-CL containers, values are taken from values.yaml file.
It will generate the parameters for the pod depending on the parameters included in values.yaml.
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
      {{- range $key, $val := .Values.sdimage.podLabels }}
      {{ $key }}: {{ $val | quote }}
      {{- end }}
{{- end -}}

{{/*
Generate the parameter values for the SD-SP and SD-CL containers, values are taken from values.yaml file.
It will generate the parameters for the pod depending on the parameters included in values.yaml.
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
{{- if and (.Values.securityContext.enabled) (.Values.securityContext.readOnlyRootFilesystem) }}
  securityContext:
    readOnlyRootFilesystem: true
{{- if (.Values.securityContext.dropAllCapabilities) }}
    capabilities:
      drop:
        - ALL
      {{- if (.Values.securityContext.addCapabilities) }}
      add: {{- toYaml .Values.securityContext.addCapabilities | nindent 8 }}
      {{- end }}
{{- end }}
{{- end }}
{{- if not (.Values.sdimage.metrics.proxy_enabled) }}
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
    initialDelaySeconds: {{ .Values.sdimage.livenessProbe.initialDelaySeconds }}
  readinessProbe:
    exec:
      command:
        - /docker/healthcheck.sh
        - --ready
    failureThreshold: {{ .Values.sdimage.readinessProbe.failureThreshold }}
    periodSeconds: {{ .Values.sdimage.readinessProbe.periodSeconds }}
    initialDelaySeconds: {{ .Values.sdimage.readinessProbe.initialDelaySeconds }}
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
  {{- if and (.Values.securityContext.enabled) (.Values.securityContext.readOnlyRootFilesystem) }}
  {{- range $key, $val := .Values.sdimage.emptydirs }}
  - name: {{ $key }}
    mountPath: {{ $val | quote }}
  {{- end }}
  - name: backup
    mountPath: /opt/OV/ServiceActivator/kit/backup
  - name: log
    mountPath: /opt/OV/ServiceActivator/kit/log
  - name: kit-tmp
    mountPath: /opt/OV/ServiceActivator/kit/tmp
  - name: spi-temp
    mountPath: /opt/OV/ServiceActivator/SPI/temp
  - name: temp
    mountPath: /tmp
  {{- end }}
  {{- if   ( .Values.secrets_as_volumes )  }}  
  - name: secrets
    mountPath: "/secrets"  
  {{- end }}  
  {{- if (.Values.sdimage.licenseEnabled) }}
  - name: sd-license
    mountPath: "/mnt"
    readOnly: true
  {{- end }}
  {{- if (eq (include "efk.enabled" .) "true") }}
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
Generate the Environments variable values for the SD-SP and SD-CL containers, values are taken from values.yaml file
It will generate the parameters for the pod depending on the parameters included in values.yaml
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
{{- if  not  (.Values.secrets_as_volumes )  }}   
- name: SDCONF_activator_db_password
  valueFrom:
    secretKeyRef:
      key: "{{ .Values.sdimage.env.SDCONF_activator_db_password_key }}"
      {{- if .Values.sdimage.env.SDCONF_activator_db_password_name }}
      name: "{{ template "sd-cl.name" . }}-{{ .Values.sdimage.env.SDCONF_activator_db_password_name }}"
      {{- else }}
      name: "{{ template "sd-cl.name" . }}-sdsecret"
      {{- end }}
{{- end }}      
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
{{- if (.Values.enable_rolling_upgrade) }}
- name: SDCONF_activator_rolling_upgrade
  value: "{{ .Values.enable_rolling_upgrade }}"
{{- end }}
{{- if (.Values.sdimage.env.SDCONF_activator_conf_jboss_log_max_days) }}
- name: SDCONF_activator_conf_jboss_log_max_days
  value: "{{ .Values.sdimage.env.SDCONF_activator_conf_jboss_log_max_days }}"
{{- end }}
{{- if (.Values.sdimage.env.SDCONF_activator_conf_resmgr_log_max_files) }}
- name: SDCONF_activator_conf_resmgr_log_max_files
  value: "{{ .Values.sdimage.env.SDCONF_activator_conf_resmgr_log_max_files }}"
{{- end }}
{{- if (.Values.sdimage.env.SDCONF_activator_conf_wfm_log_max_files) }}
- name: SDCONF_activator_conf_wfm_log_max_files
  value: "{{ .Values.sdimage.env.SDCONF_activator_conf_wfm_log_max_files }}"
{{- end }}
{{- end -}}

{{/*
Generate the Fluentd container's values for the SD-SP and SD-CL pods, values are taken from values.yaml file.
It will generate the parameters for the pod depending on the parameters included in values.yaml.
*/}}
{{- define "sd-helm-chart.sdsp.statefulset.spec.template.containers.fluentdsd" -}}
{{- if and (or (eq (include "prometheus.enabled" .) "true") (eq (include "efk.enabled" .) "true")) (.Values.efk.fluentd.enabled) }}
- name: fluentd
  image: "{{ include "fluentd.fullpath" . }}"
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
{{- if and (or (eq (include "efk.enabled" .) "true") (eq (include "prometheus.enabled" .) "true")) (.Values.efk.fluentd.enabled) }}
  - mountPath: /opt/bitnami/fluentd/conf/
    name: fluentd-config
  - mountPath: /opt/bitnami/fluentd/logs/buffers
    name: buffer
{{- end }}
{{- if (eq (include "efk.enabled" .) "true") }}
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
Generate the Fluentd container parameters for the UI pod, values are taken from values.yaml file.
It will generate output if the following parameter are set efk.enabled=true and .efk.fluentd.enabled=true.
*/}}
{{- define "sd-helm-chart.sdsp.statefulset.spec.template.containers.fluentdui" -}}
{{- if and (eq (include "efk.enabled" .) "true") (.Values.efk.fluentd.enabled) }}
- name: fluentd
  image: "{{ include "fluentd.fullpath" . }}"
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
Generate the Envoy container parameters for the SD-SP and SD-CL pod, values are taken from values.yaml file.
It will generate output if the following parameter are set to sdimage.metrics.proxy_enabled=true and (prometheus.enabled=true or sdimage.metrics.enabled=true)
*/}}
{{- define "sd-helm-chart.sdsp.statefulset.spec.template.containers.envoy" -}}
{{- if .Values.sdimage.metrics.proxy_enabled }}
{{- if or (eq (include "prometheus.enabled" .) "true") (.Values.sdimage.metrics.enabled) }}
- name: envoy
  image: "{{ include "envoy.fullpath" . }}"
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
Generate the mounting Volumes parameters for the SD-SP and SD-CL pod, values are taken from values.yaml file.
It will generate output for several containers inside the pod depending of the parameters included in values.yaml.
*/}}
{{- define "sd-helm-chart.sdsp.statefulset.spec.template.containers.volumes" -}}
{{- if and (.Values.securityContext.enabled) (.Values.securityContext.readOnlyRootFilesystem) }}
{{- range $key, $val := .Values.sdimage.emptydirs }}
- name: {{ $key }}
  emptyDir: {}
{{- end }}
- name: backup
  emptyDir: {}
- name: log
  emptyDir: {}
- name: kit-tmp
  emptyDir: {}
- name: spi-temp
  emptyDir: {}
- name: temp
  emptyDir: {}
{{- end }}
{{- if   (.Values.secrets_as_volumes )  }}  
- name: secrets
  secret:
    {{- if .Values.sdimage.env.SDCONF_activator_db_password_name }}
    secretName: {{ template "sd-cl.name" . }}-{{ .Values.sdimage.env.SDCONF_activator_db_password_name }}
    {{- else }}
    secretName: {{ template "sd-cl.name" . }}-sdsecret
    {{- end }}
    items:
    - key: {{ .Values.sdimage.env.SDCONF_activator_db_password_key }}
      path: activator_db_password
{{- end }}
{{- if .Values.sdimage.metrics.proxy_enabled }}
- name: envoy-config-metrics
  configMap:
    defaultMode: 420
    name: envoy-metrics
{{- end }}
{{- if or (and  (eq (include "efk.enabled" .) "true")  (.Values.efk.fluentd.enabled) ) (eq (include "prometheus.enabled" .) "true") }}
- name: fluentd-config
  configMap:
    defaultMode: 420
    name: fluentd-config
- name: buffer
  emptyDir: {}
{{- end }}
{{- if (.Values.sdimage.licenseEnabled) }}
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
{{- end }}
{{- if (eq (include "efk.enabled" .) "true") }}
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
Generate the services for SD-SP and SD-CL pods, values are taken from values.yaml file.
It will generate parameters for the pods depending of the parameters included in values.yaml.
*/}}
{{- define "sd-helm-chart.sdsp.service" -}}
apiVersion: v1
kind: Service
metadata:
  {{- if .Values.install_assurance }}
  name: {{ .Values.service_sdcl.name }}
  {{- if empty .Values.service_sdcl.labels }}
  labels: {{ include "sd.templateValue" ( dict "value" .Values.sdimage.serviceLabels "context" $) | nindent 4 }}
  {{- else }}
  labels: {{ include "sd.templateValue" ( dict "value" .Values.service_sdcl.labels "context" $) | nindent 4 }}
  {{- end }}
  {{- else }}
  name: {{ .Values.service_sdsp.name }}
  {{- if empty .Values.service_sdsp.labels }}
  labels: {{ include "sd.templateValue" ( dict "value" .Values.sdimage.serviceLabels "context" $) | nindent 4 }}
  {{- else }}
  labels: {{ include "sd.templateValue" ( dict "value" .Values.service_sdsp.labels "context" $) | nindent 4 }}
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
    targetPort: {{ .Values.service_sdcl.targetPort }}
    {{- else }}
    {{- if and (or (eq .Values.service_sdsp.servicetype "NodePort") (eq .Values.service_sdsp.servicetype "LoadBalancer")) (not (empty .Values.service_sdsp.nodePort)) }}
    nodePort: {{ .Values.service_sdsp.nodePort }}
    {{- end }}
    port: {{ .Values.service_sdsp.port }}
    targetPort: {{ .Values.service_sdsp.targetPort }}
    {{- end }}
    {{- if not .Values.install_assurance }}
    {{- if .Values.service_sdsp.extraPorts }}
    {{- include "sd.templateValue" (dict "value" .Values.service_sdsp.extraPorts "context" $) | nindent 2 }}
    {{- end }}
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
Generate the services for the Prometheus example's pods, values are taken from values.yaml file.
It will generate parameters for the pods depending of the parameters included in values.yaml.
*/}}
{{- define "sd-helm-chart.sdsp.service.prometheus" -}}
apiVersion: v1
kind: Service
metadata:
  {{- if .Values.install_assurance }}
  name: {{ .Values.service_sdcl.name }}-prometheus
  {{- if empty .Values.service_sdcl_prometheus.labels }}
  labels: {{ include "sd.templateValue" ( dict "value" .Values.prometheus.serviceLabels "context" $) | nindent 4 }}
  {{- else }}
  labels: {{ include "sd.templateValue" ( dict "value" .Values.service_sdcl_prometheus.labels "context" $) | nindent 4 }}
  {{- end }}
  {{- else }}
  name: {{ .Values.service_sdsp.name }}-prometheus
  {{- if empty .Values.service_sdsp_prometheus.labels }}
  labels: {{ include "sd.templateValue" ( dict "value" .Values.prometheus.serviceLabels "context" $) | nindent 4 }}
  {{- else }}
  labels: {{ include "sd.templateValue" ( dict "value" .Values.service_sdsp_prometheus.labels "context" $) | nindent 4 }}
  {{- end }}
  {{- end }}
  namespace: {{.Release.Namespace}}
spec:
  type: ClusterIP
  ports:
  {{- if .Values.sdimage.metrics.proxy_enabled }}
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
Generate the headless service for the SD-SP and SD-CL pod, values are taken from values.yaml file.
It will generate parameters for the pods depending of the parameters included in values.yaml.
*/}}
{{- define "sd-helm-chart.sdsp.service.headless" -}}
apiVersion: v1
kind: Service
metadata:
  {{- if .Values.install_assurance }}
  name: headless-{{ .Values.service_sdcl.name }}
  {{- if empty .Values.service_sdcl.labels }}
  labels: {{ include "sd.templateValue" ( dict "value" .Values.sdimage.serviceLabels "context" $) | nindent 4 }}
  {{- else }}
  labels: {{ include "sd.templateValue" ( dict "value" .Values.service_sdcl.labels "context" $) | nindent 4 }}
  {{- end }}
  {{- else }}
  name: headless-{{ .Values.service_sdsp.name }}
  {{- if empty .Values.service_sdsp.labels }}
  labels: {{ include "sd.templateValue" ( dict "value" .Values.sdimage.serviceLabels "context" $) | nindent 4 }}
  {{- else }}
  labels: {{ include "sd.templateValue" ( dict "value" .Values.service_sdsp.labels "context" $) | nindent 4 }}
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
Generate the Deployment file for the SD-UI pod (UI container and Envoy container), values are taken from values.yaml file.
It will generate the parameters for the pod depending on the parameters included in values.yaml.
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
        {{- range $key, $val := .Values.sdui_image.podLabels }}
        {{ $key }}: {{ $val | quote }}
        {{- end }}
    spec:
      {{- if .Values.serviceAccount.enabled }}
      serviceAccountName: {{ template "sd-cl.serviceAccount" . }}
      {{- end }}
      {{- if (.Values.automountServiceAccountToken.enabled) }}
      automountServiceAccountToken: true
      {{- else }}
      automountServiceAccountToken: false
      {{- end }}
      {{- if .Values.securityContext.enabled }}
      securityContext:
        fsGroup: {{ .Values.securityContext.fsGroup }}
        runAsUser: {{ .Values.sdui_image.securityContext.runAsUser | default .Values.securityContext.runAsUser }}
      {{- end }}
      affinity: {{- include "sd.templateValue" ( dict "value" .Values.sdui_image.affinity "context" $ ) | nindent 8 }}
      {{- if and (.Values.securityContext.enabled) (.Values.securityContext.readOnlyRootFilesystem) }}
      initContainers:
      - name: {{.Values.sdui_image.name}}-initvolumes
        image: "{{ template "sdui_image.fullpath" . }}"
        imagePullPolicy: {{ include "resolve.imagePullPolicy" (dict "top" . "specificPullPolicy" .Values.sdimages.pullPolicy) }}
        {{- if and (.Values.securityContext.enabled) (.Values.securityContext.readOnlyRootFilesystem) }}
        securityContext:
          readOnlyRootFilesystem: true
        {{- if (.Values.securityContext.dropAllCapabilities )}}
          capabilities:
            drop:
              - ALL
            {{- if (.Values.securityContext.addCapabilities) }}
            add: {{- toYaml .Values.securityContext.addCapabilities | nindent 14 }}
            {{- end }}
        {{- end }}
        {{- end }}
        command: ['sh', '-c', '/docker/initvolumes.sh']
        volumeMounts:
        {{- range $key, $val := .Values.sdui_image.emptydirs }}
        - name: {{ $key }}
          mountPath: /initvolumes{{ $val }}
        {{- end }}
      {{- end }}
      containers:
      - name: {{.Values.sdui_image.name}}
        image: "{{ template "sdui_image.fullpath" . }}"
        imagePullPolicy: {{ include "resolve.imagePullPolicy" (dict "top" . "specificPullPolicy" .Values.sdimages.pullPolicy) }}
        {{- if (.Values.securityContext.enabled) }}
        securityContext:
        {{- if (.Values.securityContext.readOnlyRootFilesystem) }}
          readOnlyRootFilesystem: true
        {{- end }}
        {{- if (.Values.securityContext.dropAllCapabilities) }}
          capabilities:
            drop:
              - ALL
            {{- if (.Values.securityContext.addCapabilities) }}
            add: {{- toYaml .Values.securityContext.addCapabilities | nindent 14 }}
            {{- end }}
        {{- end }}
        {{- end }}
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
        {{- if   not ( .Values.secrets_as_volumes)  }}       
        - name: SDCONF_sdui_provision_password
          valueFrom:
            secretKeyRef:
              key: "{{ .Values.sdui_image.env.SDCONF_sdui_provision_password_key }}"
              {{- if .Values.sdui_image.env.SDCONF_sdui_provision_password_name }}
              name: "{{ template "sd-cl.name" . }}-{{ .Values.sdui_image.env.SDCONF_sdui_provision_password_name }}"
              {{- else }}
              name: "{{ template "sd-cl.name" . }}-sdsecret"
              {{- end }}
        {{- end }}
        - name: SDCONF_sdui_provision_protocol
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_provision_protocol }}"
        - name: SDCONF_sdui_provision_tenant
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_provision_tenant }}"
        - name: SDCONF_sdui_provision_use_real_user
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_provision_use_real_user }}"
        - name: SDCONF_sdui_provision_username
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_provision_username }}"
        {{- if .Values.sdui_image.env.SDCONF_sdui_provision_idp }}
        - name: SDCONF_sdui_provision_idp
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_provision_idp }}"
        {{- end }}
        {{- if .Values.sdui_image.env.SDCONF_sdui_provision_idp_reuse_token }}
        - name: SDCONF_sdui_provision_idp_reuse_token
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_provision_idp_reuse_token }}"
        {{- end }}
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
          value: {{ .Values.couchdb.fullnameOverride }}{{ printf "-couchdb" }}
        - name: SDCONF_uoc_couchdb_admin_username
          valueFrom:
            secretKeyRef:
              key: "{{ .Values.sdui_image.env.SDCONF_uoc_couchdb_admin_username_key }}"
              name: {{ .Values.couchdb.fullnameOverride }}{{ printf "-couchdb" }}
        {{- if   not ( .Values.secrets_as_volumes )  }}                  
        - name: SDCONF_uoc_couchdb_admin_password
          valueFrom:
            secretKeyRef:
              key: "{{ .Values.sdui_image.env.SDCONF_uoc_couchdb_admin_password_key }}"
              name: {{ .Values.couchdb.fullnameOverride }}{{ printf "-couchdb" }}
        {{- end }}
        - name: SDCONF_sdui_redis
          value: "yes"
        - name: SDCONF_sdui_redis_host
          value: "{{ .Values.redis.fullnameOverride }}{{ printf "-master" }}"
        - name: SDCONF_sdui_redis_port
          value: "{{ .Values.redis.redisPort }}"
        {{- if   not ( .Values.secrets_as_volumes)  }}  
        - name: SDCONF_sdui_redis_password
          valueFrom:
            secretKeyRef:
            {{- if and (.Values.redis.auth.existingSecret) (.Values.redis.auth.existingSecretPasswordKey) }}
              name: "{{ .Values.redis.auth.existingSecret }}"
              key: "{{ .Values.redis.auth.existingSecretPasswordKey }}"
            {{- else }}
              name: "{{ .Values.redis.fullnameOverride }}"
              key: "redis-password"
            {{- end }}
        {{- end }}
        {{- if ( .Values.sdui_image.uoc_certificate_secret ) }}
        - name: SDCONF_sdui_uoc_certificate
          value: "uoc/tls.crt"
        - name: SDCONF_sdui_uoc_private_key
          value: "uoc/tls.key"
        {{- end }}
        {{- if ( .Values.sdui_image.idp_certificate_secret ) }}
        - name: SDCONF_sdui_idp_certificate
          value: "idp/tls.crt"
        {{- end }}
        {{- if ( .Values.sdui_image.env.SDCONF_sdui_uoc_protocol ) }}
        - name: SDCONF_sdui_uoc_protocol
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_uoc_protocol }}"
        {{- end }}
        {{- if ( .Values.sdui_image.env.SDCONF_sdui_idp ) }}
        - name: SDCONF_sdui_idp
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_idp }}"
        {{- end }}
        {{- if ( .Values.sdui_image.env.SDCONF_sdui_idp_entry_point ) }}
        - name: SDCONF_sdui_idp_entry_point
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_idp_entry_point }}"
        {{- end }}
        {{- if ( .Values.sdui_image.env.SDCONF_sdui_idp_identifier_format ) }}
        - name: SDCONF_sdui_idp_identifier_format
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_idp_identifier_format }}"
        {{- end }}
        {{- if ( .Values.sdui_image.env.SDCONF_sdui_idp_identifier_format ) }}
        - name: SDCONF_sdui_idp_accepted_clock_skew_ms
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_idp_accepted_clock_skew_ms }}"
        {{- end }}
        {{- if ( .Values.sdui_image.env.SDCONF_sdui_idp_issuer ) }}
        - name: SDCONF_sdui_idp_issuer
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_idp_issuer }}"
        {{- end }}
        {{- if ( .Values.sdui_image.env.SDCONF_sdui_oidc ) }}
        - name: SDCONF_sdui_oidc
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_oidc }}"
        {{- end }}
        {{- if ( .Values.sdui_image.env.SDCONF_sdui_oidc_issuer ) }}
        - name: SDCONF_sdui_oidc_issuer
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_oidc_issuer }}"
        {{- end }}
        {{- if ( .Values.sdui_image.env.SDCONF_sdui_oidc_authorization_endpoint ) }}
        - name: SDCONF_sdui_oidc_authorization_endpoint
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_oidc_authorization_endpoint }}"
        {{- end }}
        {{- if ( .Values.sdui_image.env.SDCONF_sdui_oidc_token_endpoint ) }}
        - name: SDCONF_sdui_oidc_token_endpoint
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_oidc_token_endpoint }}"
        {{- end }}
        {{- if ( .Values.sdui_image.env.SDCONF_sdui_oidc_user_info_endpoint ) }}
        - name: SDCONF_sdui_oidc_user_info_endpoint
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_oidc_user_info_endpoint }}"
        {{- end }}
        {{- if ( .Values.sdui_image.env.SDCONF_sdui_oidc_jwks_uri ) }}
        - name: SDCONF_sdui_oidc_jwks_uri
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_oidc_jwks_uri }}"
        {{- end }}
        {{- if ( .Values.sdui_image.env.SDCONF_sdui_oidc_end_session_endpoint ) }}
        - name: SDCONF_sdui_oidc_end_session_endpoint
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_oidc_end_session_endpoint }}"
        {{- end }}
        {{- if ( .Values.sdui_image.env.SDCONF_sdui_oidc_check_session_endpoint ) }}
        - name: SDCONF_sdui_oidc_check_session_endpoint
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_oidc_check_session_endpoint }}"
        {{- end }}
        {{- if ( .Values.sdui_image.env.SDCONF_sdui_oidc_client_id ) }}
        - name: SDCONF_sdui_oidc_client_id
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_oidc_client_id }}"
        {{- end }}
        {{- if ( .Values.sdui_image.env.SDCONF_sdui_oidc_client_secret ) }}
        - name: SDCONF_sdui_oidc_client_secret
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_oidc_client_secret }}"
        {{- end }}
        {{- if ( .Values.sdui_image.env.SDCONF_sdui_oidc_redirect_uri ) }}
        - name: SDCONF_sdui_oidc_redirect_uri
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_oidc_redirect_uri }}"
        {{- end }}
        {{- if ( .Values.sdui_image.env.SDCONF_sdui_oidc_post_logout_redirect_uri ) }}
        - name: SDCONF_sdui_oidc_post_logout_redirect_uri
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_oidc_post_logout_redirect_uri }}"
        {{- end }}
        {{- if ( .Values.sdui_image.env.SDCONF_sdui_oidc_silent_redirect_uri ) }}
        - name: SDCONF_sdui_oidc_silent_redirect_uri
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_oidc_silent_redirect_uri }}"
        {{- end }}
        {{- if ( .Values.sdui_image.env.SDCONF_sdui_oidc_token_endpoint_auth_method ) }}
        - name: SDCONF_sdui_oidc_token_endpoint_auth_method
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_oidc_token_endpoint_auth_method }}"
        {{- end }}
        {{- if ( .Values.sdui_image.env.SDCONF_sdui_oidc_id_token_signed_response_alg ) }}
        - name: SDCONF_sdui_oidc_id_token_signed_response_alg
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_oidc_id_token_signed_response_alg }}"
        {{- end }}
        {{- if ( .Values.sdui_image.env.SDCONF_sdui_oidc_user_info_signed_response_alg ) }}
        - name: SDCONF_sdui_oidc_user_info_signed_response_alg
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_oidc_user_info_signed_response_alg }}"
        {{- end }}
        {{- if ( .Values.sdui_image.env.SDCONF_sdui_oidc_response_type ) }}
        - name: SDCONF_sdui_oidc_response_type
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_oidc_response_type }}"
        {{- end }}
        {{- if ( .Values.sdui_image.env.SDCONF_sdui_oidc_post_auth_callback ) }}
        - name: SDCONF_sdui_oidc_post_auth_callback
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_oidc_post_auth_callback }}"
        {{- end }}
        {{- if ( .Values.sdui_image.env.SDCONF_sdui_oidc_scope ) }}
        - name: SDCONF_sdui_oidc_scope
          value: "{{ .Values.sdui_image.env.SDCONF_sdui_oidc_scope }}"
        {{- end }}
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
          initialDelaySeconds: {{ .Values.sdui_image.livenessProbe.initialDelaySeconds }}
        readinessProbe:
          exec:
            command:
              - /docker/healthcheck.sh
          failureThreshold: {{ .Values.sdui_image.readinessProbe.failureThreshold }}
          periodSeconds: {{ .Values.sdui_image.readinessProbe.periodSeconds }}
          initialDelaySeconds: {{ .Values.sdui_image.readinessProbe.initialDelaySeconds }}
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
        volumeMounts:
        {{- if and (.Values.securityContext.enabled) (.Values.securityContext.readOnlyRootFilesystem) }}
        {{- range $key, $val := .Values.sdui_image.emptydirs }}
        - name: {{ $key }}
          mountPath: {{ $val | quote }}
        {{- end }}
        - name: l10n
          mountPath: /opt/uoc2/client/l10n
        - name: database-logs
          mountPath: /opt/uoc2/install/database/logs
        - name: tmp
          mountPath: /tmp
        - name: var-tmp
          mountPath: /var/tmp
        {{- end }}
        {{- if    (.Values.secrets_as_volumes)  }}   
        - name: secrets
          mountPath: "/secrets"        
        {{- end }}      
        {{- if and (eq (include "efk.enabled" .) "true") (eq (.Values.securityContext.enabled | toString) "false") (eq (.Values.securityContext.readOnlyRootFilesystem | toString) "false") }}
        - name: uoc-log
          mountPath: /var/opt/uoc2/logs
        {{- end }}  
        {{- if (.Values.sdui_image.uoc_certificate_secret) }}
        - name: uoc
          mountPath: "/opt/uoc2/server/public/ssl/uoc"
          readOnly: true
        {{- end }}
        {{- if (.Values.sdui_image.idp_certificate_secret) }}
        - name: idp
          mountPath: "/opt/uoc2/server/public/ssl/idp"
          readOnly: true
        {{- end }}
      {{- if (.Values.sdui_image.loadbalancer) }}
      - name: envoy
        image: "{{ include "envoy.fullpath" . }}"
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
      {{- if (eq (include "efk.enabled" .) "true") }}
{{ include "sd-helm-chart.sdsp.statefulset.spec.template.containers.fluentdui" . | indent 6 }}
      {{- end }}
      volumes:
      {{- if and (.Values.securityContext.enabled) (.Values.securityContext.readOnlyRootFilesystem) }}
      {{- range $key, $val := .Values.sdui_image.emptydirs }}
      - name: {{ $key }}
        emptyDir: {}
      {{- end }}
      - name: l10n
        emptyDir: {}
      - name: database-logs
        emptyDir: {}
      - name: tmp
        emptyDir: {}
      - name: var-tmp
        emptyDir: {}
      {{- end }}
      {{- if   (.Values.secrets_as_volumes)  }}    
      - name: secrets
        projected:
          sources:
          - secret:
              {{- if .Values.sdui_image.env.SDCONF_sdui_provision_password_name }}
              name: "{{ template "sd-cl.name" . }}-{{ .Values.sdui_image.env.SDCONF_sdui_provision_password_name }}"
              {{- else }}
              name: "{{ template "sd-cl.name" . }}-sdsecret"
              {{- end }}
              items:
                - key: "{{ .Values.sdui_image.env.SDCONF_sdui_provision_password_key }}"
                  path: sdui_provision_password
          - secret:
              name: {{ .Values.couchdb.fullnameOverride }}{{ printf "-couchdb" }}
              items:
                - key: "{{ .Values.sdui_image.env.SDCONF_uoc_couchdb_admin_password_key }}"
                  path: uoc_couchdb_admin_password 
          - secret:
            {{- if .Values.redis.auth.existingSecret }}
              name: "{{ .Values.redis.auth.existingSecret }}"
              items:
                - key: "{{ .Values.redis.auth.existingSecretPasswordKey }}"
                  path: sdui_redis_password
            {{- else }}
              name: "redis"
              items:
                - key: "redis-password"
                  path: sdui_redis_password
            {{- end }}
      {{- end }}         
      {{- if (.Values.sdui_image.uoc_certificate_secret) }}
      - name: uoc
        secret:
          secretName: {{ .Values.sdui_image.uoc_certificate_secret }}
          items:
            - key: tls.crt
              path: tls.crt
            - key: tls.key
              path: tls.key
      {{- end }}
      {{- if (.Values.sdui_image.idp_certificate_secret) }}
      - name: idp
        secret:
          secretName: {{ .Values.sdui_image.idp_certificate_secret }}
          items:
            - key: tls.crt
              path: tls.crt
      {{- end }}
      {{- if (eq (include "efk.enabled" .) "true") }}      
      - name: fluentd-config-ui
        configMap:
          defaultMode: 420
          name: fluentd-config-ui
      {{- end }}          
      - name: buffer
        emptyDir: {}
      {{- if and (eq (.Values.securityContext.enabled | toString) "false") (eq (.Values.securityContext.readOnlyRootFilesystem | toString) "false") }}
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
Generate the Service file for the SD-UI pod, values are taken from values.yaml file.
It will generate the parameters for the pod depending on the parameters included in values.yaml.
*/}}
{{- define "sd-helm-chart.sdui.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.service_sdui.name }}
  namespace: {{.Release.Namespace}}
  {{- if empty .Values.service_sdui.labels }}
  labels: {{ include "sd.templateValue" ( dict "value" .Values.sdui_image.serviceLabels "context" $) | nindent 4 }}
  {{- else }}
  labels: {{ include "sd.templateValue" ( dict "value" .Values.service_sdui.labels "context" $) | nindent 4 }}
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
Generate the container values for the Fluentd image included in the SNMP pod, values are taken from values.yaml file.
It will generate the parameters for the pod depending on the parameters included in values.yaml.
*/}}
{{- define "sd-helm-chart.snmp.deployment.spec.template.containers.fluentdsd" -}}
{{- if and (or (eq (include "prometheus.enabled" .) "true") (eq (include "efk.enabled" .) "true")) (.Values.efk.fluentd.enabled) }}
- name: fluentd
  image: "{{ include "fluentd.fullpath" . }}"
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
{{- if and (or (eq (include "efk.enabled" .) "true") (eq (include "prometheus.enabled" .) "true")) (.Values.efk.fluentd.enabled) }}
  - mountPath: /opt/bitnami/fluentd/conf/
    name: fluentd-config
  - mountPath: /opt/bitnami/fluentd/logs/buffers
    name: buffer
{{- end }}
{{- if (eq (include "efk.enabled" .) "true") }}
  - name: snmp-log
    mountPath: /snmp-log
{{- end }}
{{- end -}}
{{- end -}}

{{/*
Generate the Volume mapping included in the SNMP pod, values are taken from values.yaml file.
It will generate the parameters for the pod depending on the parameters included in values.yaml.
*/}}
{{- define "sd-helm-chart.snmp.deployment.spec.template.containers.volumes" -}}
{{- if or (eq (include "efk.enabled" .) "true") (eq (include "prometheus.enabled" .) "true") }}
{{- if (.Values.efk.fluentd.enabled) }}
- name: fluentd-config
  configMap:
    defaultMode: 420
    name: fluentd-config
{{- end }}
- name: buffer
  emptyDir: {}
- name: snmp-log
  emptyDir: {}
{{- end }}
{{- if and (.Values.securityContext.enabled) (.Values.securityContext.readOnlyRootFilesystem) }}
{{- range $key, $val := .Values.deployment_sdsnmp.emptydirs }}
- name: {{ $key }}
  emptyDir: {}
{{- end }}
- name: tmp
  emptyDir: {}
- name: run
  emptyDir: {}
{{- end }}
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

  {{- if (not (empty $spcPullPolicy)) -}}
    {{- $result = $spcPullPolicy -}}
  {{- end -}}

{{/* If a global value exists, it takes precedence over the specific value */}}
  {{- if $top.Values.global -}}
    {{- if $top.Values.global.pullPolicy -}}
      {{- $result = $top.Values.global.pullPolicy -}}
    {{- end -}}
  {{- end -}}

  {{ print $result }}
{{- end -}}

{{/*
Generate the full healthcheck repository url: registry + image name + tag(version)

It can be defined in several parameters, this is the priority order that will be used for registries:

1. global.sdimages.registry, affects only sd images
2. global.imageRegistry, affects all, including dependencies that support it
3. specific - StatefulSet or Deployment's .image.registry (for each case individually)
4. sdimages.registry

this is the priority order that will be used for tags:

1. global.sdimage.tag
2. specific - StatefulSet or Deployment's .image.registry
3. sdimages.tag
*/}}
{{- define "healthcheck.fullpath" -}}
{{- $registry := "" -}}
{{- $name := "" -}}
{{- $tag := "" -}}

{{- $name = .Values.healthcheck.name -}}

{{- if .Values.healthcheck.registry -}}
  {{- $registry = .Values.healthcheck.registry -}}
{{- end -}}

{{- if .Values.sdimages.registry -}}
  {{- $registry = .Values.sdimages.registry -}}
{{- end -}}

{{- if .Values.global -}}
  {{- if .Values.global.imageRegistry -}}
    {{- $registry = .Values.global.imageRegistry -}}
  {{- end -}}
{{- end -}}

{{- if .Values.sdimages.tag -}}
  {{- $tag = .Values.sdimages.tag -}}
{{- end -}}
{{- if .Values.healthcheck.tag -}}
  {{- $tag = .Values.healthcheck.tag -}}
{{- end -}}

{{- if .Values.global -}}
  {{- if .Values.global.sdimage -}}
    {{- if .Values.global.sdimage.tag -}}
       {{- $tag = .Values.global.sdimage.tag -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- $tag = $tag | toString -}}
{{- printf "%s%s:%s" $registry $name $tag -}}
{{- end -}}

{{- define "SD.secret.fullname" -}}
{{- $name := (printf "secret-%s" .name) -}}
{{ include "sd-cl.fullname" (dict "all" .all "name" $name ) }}
{{- end -}}