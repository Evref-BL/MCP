Extension { #name : 'MCP' }

{ #category : '*MCP-OpenTelemetry' }
MCP >> useOpenTelemetryObservability [
	"Records this server's work through OpenTelemetry, with providers that describe this server and nothing that identifies the machine, its user or the image."

	| backend |
	backend := MCPOpenTelemetryObservabilityBackend new.
	backend describeServer: ([ self serverIdentity ]
			 on: Error
			 do: [ nil ]).
	self observability: backend.
	^ backend
]
