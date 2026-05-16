"
DTO for one package managed by an Iceberg repository.

It reports package metadata needed by repository management tools without exposing Iceberg package objects.
"
Class {
	#name : 'MCPRepositoryPackageInfo',
	#superclass : 'Object',
	#instVars : [
		'name',
		'directoryName',
		'isLoaded',
		'isModified'
	],
	#category : 'MCP-DTOs',
	#package : 'MCP',
	#tag : 'DTOs'
}

{ #category : 'instance creation' }
MCPRepositoryPackageInfo class >> fromPackage: anIcePackage [

	^ self new initializeFromPackage: anIcePackage
]

{ #category : 'converting' }
MCPRepositoryPackageInfo >> asDictionary [

	^ {
		  (#name -> self name).
		  (#directoryName -> self directoryName).
		  (#isLoaded -> self isLoaded).
		  (#isModified -> self isModified) } asDictionary
]

{ #category : 'private' }
MCPRepositoryPackageInfo >> booleanFrom: aBlock default: defaultBoolean [

	^ [ aBlock value ifNil: [ defaultBoolean ] ]
		  on: Error
		  do: [ :ignored | defaultBoolean ]
]

{ #category : 'accessing' }
MCPRepositoryPackageInfo >> directoryName [

	^ directoryName
]

{ #category : 'initialization' }
MCPRepositoryPackageInfo >> initializeFromPackage: anIcePackage [

	name := self stringFrom: [ anIcePackage name ] default: ''.
	directoryName := self
		                 stringFrom: [ anIcePackage directoryName ]
		                 default: ''.
	isLoaded := self
		            booleanFrom: [ anIcePackage isLoaded ]
		            default: false.
	isModified := self
		              booleanFrom: [ anIcePackage isModified ]
		              default: false.
	^ self
]

{ #category : 'accessing' }
MCPRepositoryPackageInfo >> isLoaded [

	^ isLoaded
]

{ #category : 'accessing' }
MCPRepositoryPackageInfo >> isModified [

	^ isModified
]

{ #category : 'accessing' }
MCPRepositoryPackageInfo >> name [

	^ name
]

{ #category : 'private' }
MCPRepositoryPackageInfo >> stringFrom: aBlock default: defaultString [

	^ [
	  aBlock value
		  ifNil: [ defaultString ]
		  ifNotNil: [ :value | value asString ] ]
		  on: Error
		  do: [ :ignored | defaultString ]
]
