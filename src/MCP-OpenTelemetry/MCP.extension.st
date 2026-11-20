Extension { #name : 'MCP' }

{ #category : '*MCP-OpenTelemetry' }
MCP >> useOpenTelemetryObservability [
	"Records this server's work through OpenTelemetry, configured by the OTEL_* environment or, when it has none, by the settings file the Pharo tools share, again at every image start. Nothing is recorded while neither asks for traces. The providers describe this server and nothing that identifies the machine, its user or the image."

	^ self useOpenTelemetryObservabilityWith: MCPOpenTelemetrySettings current
]

{ #category : '*MCP-OpenTelemetry' }
MCP >> useOpenTelemetryObservabilityWith: aSettings [
	"Records this server's work through OpenTelemetry, configured by aSettings."

	| backend |
	backend := MCPOpenTelemetryObservabilityBackend new.
	backend
		configureFor: ([ self serverIdentity ]
				 on: Error
				 do: [ nil ])
		settings: aSettings.
	self observability: backend.
	^ backend
]
