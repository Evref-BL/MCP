"
What MCP-IDE needs before Pharo 14, which has no enabledByDefault: MCP's critique rules are off by default through enabled instead. The baseline loads this package only before Pharo 14.
"
Class {
	#name : 'ManifestMCPIDECompatibilityBefore14',
	#superclass : 'PackageManifest',
	#category : 'MCP-IDE-Compatibility-Before14-Manifest',
	#package : 'MCP-IDE-Compatibility-Before14',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCPIDECompatibilityBefore14 class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
