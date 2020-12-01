{{- define "elasticsearch.endpoints" -}}
{{- $replicas := int (toString (.Values.elk.elastic.replicas)) }}
{{- $uname := "elasticsearch"  }}
  {{- range $i, $e := untilStep 0 $replicas 1 -}}
{{ $uname }}-{{ $i }},
  {{- end -}}
{{- end -}}
