"
An observability backend that exports an MCP server's tool-call traces, metrics and logs through OpenTelemetry. It is a package of its own so MCP does not depend on OpenTelemetry; `MCP >> useOpenTelemetryObservability` switches a server to it.
"
Class {
	#name : 'ManifestMCPOpenTelemetry',
	#superclass : 'PackageManifest',
	#category : 'MCP-OpenTelemetry-Manifest',
	#package : 'MCP-OpenTelemetry',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCPOpenTelemetry class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
