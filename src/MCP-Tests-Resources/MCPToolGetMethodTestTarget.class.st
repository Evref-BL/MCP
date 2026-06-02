"
Fixture class that supplies methods for method-get and mutation critique tests.
"
Class {
	#name : 'MCPToolGetMethodTestTarget',
	#superclass : 'Object',
	#instVars : [
		'instanceCounter'
	],
	#classVars : [
		'SharedLimit'
	],
	#classInstVars : [
		'classCounter'
	],
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'reading' }
MCPToolGetMethodTestTarget class >> readClassSide [

	| local |
	local := classCounter ifNil: [ SharedLimit ].
	^ Array
		  with: local
		  with: thisContext method selector
		  with: Smalltalk imagePath
]

{ #category : 'reading' }
MCPToolGetMethodTestTarget >> readInstanceWith: anArgument [

	| local |
	local := instanceCounter ifNil: [ SharedLimit ].
	^ OrderedCollection
		  with: anArgument
		  with: local
		  with: Smalltalk vm wordSize
		  with: self class name
]
