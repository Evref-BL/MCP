"
Tests for how an image reads the OTEL_* environment, given as a Dictionary.
"
Class {
	#name : 'MCPOpenTelemetrySettingsTest',
	#superclass : 'TestCase',
	#category : 'MCP-OpenTelemetry-Tests',
	#package : 'MCP-OpenTelemetry-Tests'
}

{ #category : 'tests' }
MCPOpenTelemetrySettingsTest >> testTracesAreAskedForByAnEndpointOrAConfigurationFile [

	| configured |
	configured := [ :pairs | (MCPOpenTelemetrySettings environment: (Dictionary newFrom: pairs)) isConfigured ].
	self deny: (configured value: #(  )).
	self assert: (configured value: { ('OTEL_EXPORTER_OTLP_ENDPOINT' -> 'https://c.test') }).
	self assert: (configured value: { ('OTEL_EXPORTER_OTLP_TRACES_ENDPOINT' -> 'https://c.test/v1/traces') }).
	self assert: (configured value: { ('OTEL_CONFIG_FILE' -> '/etc/otel.yaml') }).
	self assert: (configured value: {
				 ('OTEL_EXPORTER_OTLP_ENDPOINT' -> 'https://c.test').
				 ('OTEL_TRACES_EXPORTER' -> 'console, otlp') }).
	self deny: (configured value: {
				 ('OTEL_EXPORTER_OTLP_ENDPOINT' -> 'https://c.test').
				 ('OTEL_TRACES_EXPORTER' -> 'none') }).
	self deny: (configured value: {
				 ('OTEL_EXPORTER_OTLP_ENDPOINT' -> 'https://c.test').
				 ('OTEL_SDK_DISABLED' -> 'TRUE') }).
	self deny: (configured value: { ('OTEL_EXPORTER_OTLP_ENDPOINT' -> '  ') })
]
