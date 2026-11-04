"
A fixture test class for the tests of the test-running tool, which run it by naming its package. It is alone in its package so that run holds nothing else.
"
Class {
	#name : 'ManifestMCPTestsRunResources',
	#superclass : 'PackageManifest',
	#category : 'MCP-Tests-RunResources-Manifest',
	#package : 'MCP-Tests-RunResources',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCPTestsRunResources class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
