"
The tests of the OpenTelemetry observability backend. They read what it exported back from an exporter that records it.
"
Class {
	#name : 'ManifestMCPOpenTelemetryTests',
	#superclass : 'PackageManifest',
	#category : 'MCP-OpenTelemetry-Tests-Manifest',
	#package : 'MCP-OpenTelemetry-Tests',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCPOpenTelemetryTests class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
