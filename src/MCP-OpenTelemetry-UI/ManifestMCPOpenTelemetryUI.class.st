"
What the inspector shows of an MCP server beyond MCP-UI once OpenTelemetry is loaded: the call graph its spans build. It is a package of its own so that MCP-UI does not depend on OpenTelemetry, nor MCP-OpenTelemetry on Spec; the baseline loads it with the 'Telemetry UI' group.
"
Class {
	#name : 'ManifestMCPOpenTelemetryUI',
	#superclass : 'PackageManifest',
	#category : 'MCP-OpenTelemetry-UI-Manifest',
	#package : 'MCP-OpenTelemetry-UI',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCPOpenTelemetryUI class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
