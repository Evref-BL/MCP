"
Result DTO produced by the screen reading command.

It holds one tree of nodes describing what was found, and the count of nodes in it.
"
Class {
	#name : 'MCPReadScreenResult',
	#superclass : 'MCPResult',
	#instVars : [
		'target',
		'nodeCount',
		'tree'
	],
	#category : 'MCP-IDE-Results',
	#package : 'MCP-IDE',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPReadScreenResult class >> target: aString nodeCount: anInteger tree: aDictionary [

	^ self new initializeTarget: aString nodeCount: anInteger tree: aDictionary
]

{ #category : 'converting' }
MCPReadScreenResult >> asDictionary [

	^ {
		  (#target -> self target).
		  (#nodes -> self nodeCount).
		  (#tree -> self tree) } asDictionary
]

{ #category : 'initialization' }
MCPReadScreenResult >> initializeTarget: aString nodeCount: anInteger tree: aDictionary [

	target := aString.
	nodeCount := anInteger.
	tree := aDictionary
]

{ #category : 'accessing' }
MCPReadScreenResult >> nodeCount [

	^ nodeCount
]

{ #category : 'accessing' }
MCPReadScreenResult >> target [

	^ target
]

{ #category : 'accessing' }
MCPReadScreenResult >> tree [

	^ tree
]
