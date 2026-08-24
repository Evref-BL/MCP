Extension { #name : 'MCP' }

{ #category : '*MCP-OpenTelemetry' }
MCP >> useOpenTelemetryObservability [

	self observability: MCPOpenTelemetryObservabilityBackend new.
	^ self observability
]
