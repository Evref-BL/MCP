Extension { #name : 'MCP' }

{ #category : '*MCP-OpenTelemetry' }
MCP >> useOpenTelemetryObservability [
	"Records this server's work through OpenTelemetry, configured by the OTEL_* environment, again at every image start. Nothing is recorded while it does not ask for traces. The providers describe this server and nothing that identifies the machine, its user or the image."

	^ self useOpenTelemetryObservabilityWith: MCPOpenTelemetrySettings current
]

{ #category : '*MCP-OpenTelemetry' }
MCP class >> useOpenTelemetryObservabilityByDefault [
	"Makes every server of this image record locally and through OpenTelemetry, configured by the OTEL_* environment or MCP's settings file, from now on and in the image as saved; the servers it holds now change too. Nothing is sent while the settings ask for no traces."

	self observabilityBackendClass: MCPOpenTelemetryObservabilityBackend.
	self allServers do: [ :each |
		(each observability isKindOf: MCPOpenTelemetryObservabilityBackend) ifFalse: [ each useOpenTelemetryObservability ] ]
]

{ #category : '*MCP-OpenTelemetry' }
MCP >> useOpenTelemetryObservabilityWith: aSettings [
	"Records this server's work locally and through OpenTelemetry, configured by aSettings."

	| backend |
	backend := self newObservabilityBackend: MCPOpenTelemetryObservabilityBackend.
	backend
		configureFor: ([ self serverIdentity ]
				 on: Error
				 do: [ nil ])
		settings: aSettings.
	self observability: backend.
	^ backend
]
