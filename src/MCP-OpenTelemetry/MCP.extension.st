Extension { #name : 'MCP' }

{ #category : '*MCP-OpenTelemetry' }
MCP >> useOpenTelemetryObservability [
	"Records this server's work through OpenTelemetry, with providers that describe this server and nothing about the machine, the user or the image. When they cannot be made to, nothing goes through OpenTelemetry: the SDK's default resource would say who ran the image and where."

	| backend |
	backend := [
		           MCPOpenTelemetryObservabilityBackend new
			           describeServer: self serverIdentity;
			           yourself ]
		           on: Error
		           do: [ :error | MCPNoopObservabilityBackend new ].
	self observability: backend.
	^ backend
]
