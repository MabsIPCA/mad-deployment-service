{{/*
Helper templates for testing failures
*/}}

{{/*
Helper with undefined variable reference
*/}}
{{- define "helpers.undefinedVar" -}}
{{ .Values.nonExistentVariable.nested.value }}
{{- end -}}

{{/*
Helper with syntax error - unclosed action
*/}}
{{- define "helpers.syntaxError" -}}
{{ .Values.someValue
{{- end -}}

{{/*
Helper with type mismatch - trying to range over number
*/}}
{{- define "helpers.typeMismatch" -}}
{{- range .Values.port }}
item: {{ . }}
{{- end }}
{{- end -}}

{{/*
Helper with division by zero
*/}}
{{- define "helpers.divZero" -}}
{{ div 100 0 }}
{{- end -}}

{{/*
Helper with required function failure
*/}}
{{- define "helpers.requiredValue" -}}
{{ required "helperRequiredValue is required" .Values.helperRequiredValue }}
{{- end -}}

{{/*
Helper with nil pointer access
*/}}
{{- define "helpers.nilPointer" -}}
{{ .Values.nilHelper.nested.value }}
{{- end -}}

{{/*
Helper that calls a non-existent helper
*/}}
{{- define "helpers.callsMissing" -}}
{{ include "non.existent.helper" . }}
{{- end -}}

{{/*
Helper with invalid function call
*/}}
{{- define "helpers.invalidFunction" -}}
{{ nonExistentFunction "arg1" "arg2" }}
{{- end -}}

