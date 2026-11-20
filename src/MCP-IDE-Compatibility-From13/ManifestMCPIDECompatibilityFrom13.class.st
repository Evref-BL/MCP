"
What MCP-IDE does the way Pharo 13 and later let it: a rewrite's changes go to the change manager together, through the performChanges: those versions add, under the selector MCP-IDE-Compatibility-Before13 answers before Pharo 13; and compiler errors are read the way those versions raise them, through MCP's own mcp* selectors answered from their compiler classes. The baseline loads this package from Pharo 13 on.
"
Class {
	#name : 'ManifestMCPIDECompatibilityFrom13',
	#superclass : 'PackageManifest',
	#category : 'MCP-IDE-Compatibility-From13-Manifest',
	#package : 'MCP-IDE-Compatibility-From13',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCPIDECompatibilityFrom13 class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
