"
DTO for package metadata.

It records package name, project names and tag names.
"
Class {
	#name : 'MCPPackageInfo',
	#superclass : 'MCPDataTransferObject',
	#instVars : [
		'packageName',
		'projectNames',
		'tagNames'
	],
	#category : 'MCP-IDE-DTOs',
	#package : 'MCP-IDE',
	#tag : 'DTOs'
}

{ #category : 'instance creation' }
MCPPackageInfo class >> fromPackage: aPackage projectNames: someProjectNames [

	^ self new initializeFromPackage: aPackage projectNames: someProjectNames
]

{ #category : 'converting' }
MCPPackageInfo >> asDictionary [

	^ {
		  (#package -> self packageName).
		  (#projects -> self projectNames).
		  (#tags -> self tagNames) } asDictionary
]

{ #category : 'initialization' }
MCPPackageInfo >> initializeFromPackage: aPackage projectNames: someProjectNames [

	packageName := aPackage name asString.
	projectNames := ((someProjectNames ifNil: [ #(  ) ]) collect: [ :each | each asString ] as: Array) sort.
	tagNames := (aPackage tagNames collect: [ :each | each asString ] as: Array) sort
]

{ #category : 'accessing' }
MCPPackageInfo >> packageName [

	^ packageName
]

{ #category : 'accessing' }
MCPPackageInfo >> projectNames [

	^ projectNames
]

{ #category : 'accessing' }
MCPPackageInfo >> tagNames [

	^ tagNames
]
