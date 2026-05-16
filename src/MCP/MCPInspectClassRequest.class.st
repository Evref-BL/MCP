"
Parsed inspect-class tool request derived from one validated MCPToolRequest.
"
Class {
	#name : 'MCPInspectClassRequest',
	#superclass : 'Object',
	#instVars : [
		'className',
		'includeComment',
		'upToSuperclassName',
		'subclassDepth'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPInspectClassRequest class >> fromRequest: aRequest tool: aTool [

	^ self new
		  initializeClassName: (aTool classNameFromRequest: aRequest)
		  includeComment:
		  (aRequest booleanArgumentNamed: 'includeComment' default: false)
		  upToSuperclassName:
		  (aRequest stringArgumentNamed: 'upToSuperclassName')
		  subclassDepth:
		  (aRequest
			   nonNegativeIntegerArgumentNamed: 'subclassDepth'
			   default: 0)
]

{ #category : 'accessing' }
MCPInspectClassRequest >> className [

	^ className
]

{ #category : 'accessing' }
MCPInspectClassRequest >> includeComment [

	^ includeComment
]

{ #category : 'initialization' }
MCPInspectClassRequest >> initializeClassName: aClassName includeComment: aBoolean upToSuperclassName: aSuperclassName subclassDepth: anInteger [

	className := aClassName.
	includeComment := aBoolean.
	upToSuperclassName := aSuperclassName.
	subclassDepth := anInteger.
	^ self
]

{ #category : 'accessing' }
MCPInspectClassRequest >> subclassDepth [

	^ subclassDepth
]

{ #category : 'accessing' }
MCPInspectClassRequest >> upToSuperclassName [

	^ upToSuperclassName
]
