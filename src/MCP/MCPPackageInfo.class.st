"
DTO for package metadata.

It records package name, project names, tag names, class and extension method counts, and whether the package is undefined.
"
Class {
	#name : 'MCPPackageInfo',
	#superclass : 'Object',
	#instVars : [
		'packageName',
		'projectNames',
		'tagNames',
		'definedClassCount',
		'extensionMethodCount',
		'isUndefined'
	],
	#category : 'MCP-DTOs',
	#package : 'MCP',
	#tag : 'DTOs'
}

{ #category : 'instance creation' }
MCPPackageInfo class >> fromPackage: aPackage projectNames: someProjectNames [

	^ self new
		  initializeFromPackage: aPackage
		  projectNames: someProjectNames
]

{ #category : 'converting' }
MCPPackageInfo >> asDictionary [

	^ {
		  (#packageName -> self packageName).
		  (#projectNames -> self projectNames).
		  (#tagNames -> self tagNames).
		  (#definedClassCount -> self definedClassCount).
		  (#extensionMethodCount -> self extensionMethodCount).
		  (#isUndefined -> self isUndefined) } asDictionary
]

{ #category : 'converting' }
MCPPackageInfo >> asQueryDictionary [

	^ {
		  (#packageName -> self packageName).
		  (#projectNames -> self projectNames).
		  (#tagNames -> self tagNames) } asDictionary
]

{ #category : 'accessing' }
MCPPackageInfo >> definedClassCount [

	^ definedClassCount
]

{ #category : 'accessing' }
MCPPackageInfo >> extensionMethodCount [

	^ extensionMethodCount
]

{ #category : 'initialization' }
MCPPackageInfo >> initializeFromPackage: aPackage projectNames: someProjectNames [

	packageName := aPackage name asString.
	projectNames := ((someProjectNames ifNil: [ #(  ) ])
		                 collect: [ :each | each asString ]
		                 as: Array) asSortedCollection asArray.
	tagNames := (aPackage tagNames collect: [ :each | each asString ])
		            asArray asSortedCollection asArray.
	definedClassCount := aPackage definedClasses size.
	extensionMethodCount := aPackage extensionMethods size.
	isUndefined := aPackage isUndefined.
	^ self
]

{ #category : 'accessing' }
MCPPackageInfo >> isUndefined [

	^ isUndefined
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
