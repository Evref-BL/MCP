"
What MCP-IDE needs before Pharo 13, whose change manager has no performChanges: and whose world loop steps the Transcript: a rewrite's changes go to performChange: one by one, under the selector MCP-IDE-Compatibility-From13 answers from Pharo 13 on, and MCPTranscriptRecorder stands in for the Transcript while an evaluation runs, so it takes that step. The baseline loads this package only before Pharo 13.
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
