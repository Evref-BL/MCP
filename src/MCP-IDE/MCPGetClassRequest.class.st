"
Parsed class_get tool request derived from one validated MCPToolRequest.
"
Class {
	#name : 'MCPGetClassRequest',
	#superclass : 'Object',
	#instVars : [
		'className',
		'includeComment',
		'upToSuperclassName',
		'subclassDepth'
	],
	#category : 'MCP-IDE-Requests',
	#package : 'MCP-IDE',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPGetClassRequest class >> fromRequest: aRequest tool: aTool [

	^ self new
		  initializeClassName: (aTool classNameFromRequest: aRequest)
		  includeComment: (aRequest booleanArgumentNamed: 'includeComment' default: false)
		  upToSuperclassName: (aRequest stringArgumentNamed: 'upToSuperclass')
		  subclassDepth: (aRequest nonNegativeIntegerArgumentNamed: 'subclassDepth' default: 0 maximum: aTool maximumSubclassDepth)
]

{ #category : 'accessing' }
MCPGetClassRequest >> className [

	^ className
]

{ #category : 'accessing' }
MCPGetClassRequest >> includeComment [

	^ includeComment
]

{ #category : 'initialization' }
MCPGetClassRequest >> initializeClassName: aClassName includeComment: aBoolean upToSuperclassName: aSuperclassName subclassDepth: anInteger [

	className := aClassName.
	includeComment := aBoolean.
	upToSuperclassName := aSuperclassName.
	subclassDepth := anInteger
]

{ #category : 'accessing' }
MCPGetClassRequest >> subclassDepth [

	^ subclassDepth
]

{ #category : 'accessing' }
MCPGetClassRequest >> upToSuperclassName [

	^ upToSuperclassName
]
