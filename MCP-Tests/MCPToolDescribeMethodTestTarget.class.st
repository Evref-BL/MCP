Class {
	#name : 'MCPToolDescribeMethodTestTarget',
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
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'reading' }
MCPToolDescribeMethodTestTarget class >> readClassSide [

	| local |
	local := classCounter ifNil: [ SharedLimit ].
	^ Array
		  with: local
		  with: thisContext method selector
		  with: Smalltalk imagePath
]

{ #category : 'reading' }
MCPToolDescribeMethodTestTarget >> readInstanceWith: anArgument [

	| local |
	local := instanceCounter ifNil: [ SharedLimit ].
	^ OrderedCollection
		  with: anArgument
		  with: local
		  with: Smalltalk vm wordSize
		  with: self class name
]
