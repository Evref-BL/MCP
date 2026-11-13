"
What MCP-IDE needs before Pharo 13, whose world loop steps the Transcript: MCPTranscriptRecorder stands in for it while an evaluation runs, so it takes that step. The baseline loads this package only before Pharo 13.
"
Class {
	#name : 'ManifestMCPIDECompatibilityBefore13',
	#superclass : 'PackageManifest',
	#category : 'MCP-IDE-Compatibility-Before13-Manifest',
	#package : 'MCP-IDE-Compatibility-Before13',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCPIDECompatibilityBefore13 class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
