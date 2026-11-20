"
What MCP-IDE needs before Pharo 14, whose compiler gives some of its verdicts on a source as notifications, an undeclared variable among them: method_compile fails on any exception there, where MCP-IDE-Compatibility-From14 fails it on an error. The baseline loads this package only before Pharo 14.
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
