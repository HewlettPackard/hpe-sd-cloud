{{- define "elasticsearch.endpoints" -}}
{{- $replicas := int (toString (.Values.efk.elastic.replicas)) }}
{{- $uname := "elasticsearch"  }}
  {{- range $i, $e := untilStep 0 $replicas 1 -}}
{{ $uname }}-{{ $i }},
  {{- end -}}
{{- end -}}
