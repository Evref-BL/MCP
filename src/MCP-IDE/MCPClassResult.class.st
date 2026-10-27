"
Abstract result for operations that return a class snapshot.

Subclasses provide #classInfo and add operation-specific fields when needed.
"
Class {
	#name : 'MCPClassResult',
	#superclass : 'MCPResult',
	#category : 'MCP-IDE-Results',
	#package : 'MCP-IDE',
	#tag : 'Results'
}

{ #category : 'testing' }
MCPClassResult class >> isAbstract [

	^ self == MCPClassResult
]

{ #category : 'converting' }
MCPClassResult >> asDictionary [

	^ self newClassInfoDictionary
]

{ #category : 'accessing' }
MCPClassResult >> classInfo [

	self subclassResponsibility
]

{ #category : 'private' }
MCPClassResult >> newClassInfoDictionary [

	^ self classInfo asDictionary copy
]
