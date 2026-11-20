Extension { #name : 'MCP' }

{ #category : '*MCP-OpenTelemetry' }
MCP >> useOpenTelemetryObservability [
	"Records this server's work through OpenTelemetry, with providers that describe this server and nothing about the machine, the user or the image."

	| backend |
	backend := MCPOpenTelemetryObservabilityBackend new.
	backend describeServer: self serverIdentity.
	self observability: backend.
	^ backend
]
