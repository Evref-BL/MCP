"
Window sizes for MCP's presenters before Pharo 13, whose Spec sizes a window from its presenter's initialExtent rather than its defaultPreferredExtent. The baseline loads this package only before Pharo 13.
"
Class {
	#name : 'ManifestMCPUICompatibilityBefore13',
	#superclass : 'PackageManifest',
	#category : 'MCP-UI-Compatibility-Before13-Manifest',
	#package : 'MCP-UI-Compatibility-Before13',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCPUICompatibilityBefore13 class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
