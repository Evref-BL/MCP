"
A W3C trace context propagator that warns before it extracts, as an SDK running into a deprecation does, so a test can check that a warning does not stop a recording.
"
Class {
	#name : 'MCPOpenTelemetryWarningPropagator',
	#superclass : 'OTW3CTraceContextPropagator',
	#category : 'MCP-OpenTelemetry-Tests',
	#package : 'MCP-OpenTelemetry-Tests'
}

{ #category : 'extracting' }
MCPOpenTelemetryWarningPropagator >> extract: aContext from: aCarrier [

	Warning signal: 'A propagator warned.'.
	^ super extract: aContext from: aCarrier
]
