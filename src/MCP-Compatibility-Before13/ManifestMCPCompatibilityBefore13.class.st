"
What MCP does the way Pharo 12 and earlier let it, under the selectors MCP-Compatibility-From13 answers from Pharo 13 on. The baseline loads this package before Pharo 13 only.
"
Class {
	#name : 'ManifestMCPCompatibilityBefore13',
	#superclass : 'PackageManifest',
	#category : 'MCP-Compatibility-Before13-Manifest',
	#package : 'MCP-Compatibility-Before13',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCPCompatibilityBefore13 class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
