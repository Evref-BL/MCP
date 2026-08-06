"
Please describe the package using the class comment of the included manifest class. The manifest class also includes other additional metadata for the package. These meta data are used by other tools such as the SmalllintManifestChecker and the critics Browser
"
Class {
	#name : 'ManifestMCPUI',
	#superclass : 'PackageManifest',
	#category : 'MCP-UI-Manifest',
	#package : 'MCP-UI',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCPUI class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
