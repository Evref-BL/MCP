"
Please describe the package using the class comment of the included manifest class. The manifest class also includes other additional metadata for the package. These meta data are used by other tools such as the SmalllintManifestChecker and the critics Browser
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
