"
Extension methods on a class of MCP-Tests-Resources, so the tests can tell an extension method from a method of the class's own package.
"
Class {
	#name : 'ManifestMCPTestsResourcesExtensions',
	#superclass : 'PackageManifest',
	#category : 'MCP-Tests-Resources-Extensions-Manifest',
	#package : 'MCP-Tests-Resources-Extensions',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCPTestsResourcesExtensions class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
