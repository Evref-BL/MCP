"
Please describe the package using the class comment of the included manifest class. The manifest class also includes other additional metadata for the package. These meta data are used by other tools such as the SmalllintManifestChecker and the critics Browser
"
Class {
	#name : 'ManifestMCPTestsResources',
	#superclass : 'PackageManifest',
	#category : 'MCP-Tests-Resources-Manifest',
	#package : 'MCP-Tests-Resources',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCPTestsResources class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
