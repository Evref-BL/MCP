"
What MCP does the way Pharo 13 and later let it, under the selectors MCP-Compatibility-Before13 answers before Pharo 13. The baseline loads this package from Pharo 13 on.
"
Class {
	#name : 'ManifestMCPCompatibilityFrom13',
	#superclass : 'PackageManifest',
	#category : 'MCP-Compatibility-From13-Manifest',
	#package : 'MCP-Compatibility-From13',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCPCompatibilityFrom13 class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
