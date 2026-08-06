"
Please describe the package using the class comment of the included manifest class. The manifest class also includes other additional metadata for the package. These meta data are used by other tools such as the SmalllintManifestChecker and the critics Browser
"
Class {
	#name : 'ManifestMCPUITests',
	#superclass : 'PackageManifest',
	#category : 'MCP-UI-Tests-Manifest',
	#package : 'MCP-UI-Tests',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestMCPUITests class >> formatter [

	^ ManifestBaselineOfMCP formatter
]
