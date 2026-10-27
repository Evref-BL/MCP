"
Parsed method_remove tool request derived from one validated MCPToolRequest.
"
Class {
	#name : 'MCPRemoveMethodsRequest',
	#superclass : 'Object',
	#instVars : [
		'className',
		'classSide',
		'selectors'
	],
	#category : 'MCP-IDE-Requests',
	#package : 'MCP-IDE',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRemoveMethodsRequest class >> fromRequest: aRequest tool: aTool [

	^ self new
		  initializeClassName: (aRequest stringArgumentNamed: 'class')
		  classSide: ((aRequest stringArgumentNamed: 'side' default: 'instance') = 'class')
		  selectors: (aTool selectorsFromRequest: aRequest)
]

{ #category : 'accessing' }
MCPRemoveMethodsRequest >> className [

	^ className
]

{ #category : 'accessing' }
MCPRemoveMethodsRequest >> classSide [

	^ classSide
]

{ #category : 'initialization' }
MCPRemoveMethodsRequest >> initializeClassName: aClassName classSide: aBoolean selectors: aCollection [

	className := aClassName.
	classSide := aBoolean.
	selectors := aCollection.
	^ self
]

{ #category : 'accessing' }
MCPRemoveMethodsRequest >> selectors [

	^ selectors
]
