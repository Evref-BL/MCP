"
Please describe the package using the class comment of the included manifest class. The manifest class also includes other additional metadata for the package. These meta data are used by other tools such as the SmalllintManifestChecker and the critics Browser
"
Class {
	#name : 'ManifestBaselineOfMCP',
	#superclass : 'PackageManifest',
	#category : 'BaselineOfMCP-Manifest',
	#package : 'BaselineOfMCP',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestBaselineOfMCP class >> formatter [

	^ EFFormatter new installNewContext: (EFContext new maxLineLength: 130)
]
