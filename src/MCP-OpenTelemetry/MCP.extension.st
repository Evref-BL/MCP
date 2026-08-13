Extension { #name : 'MCP' }

{ #category : '*MCP-OpenTelemetry' }
MCP >> useOpenTelemetryObservability [

	self monitoring: MCPOpenTelemetryObservabilityBackend new.
	^ self monitoring
]
