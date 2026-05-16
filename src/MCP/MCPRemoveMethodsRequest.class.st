"
Parsed remove-methods tool request derived from one validated MCPToolRequest.
"
Class {
	#name : 'MCPRemoveMethodsRequest',
	#superclass : 'Object',
	#instVars : [
		'className',
		'classSide',
		'selectors'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRemoveMethodsRequest class >> fromRequest: aRequest tool: aTool [

	^ self new
		  initializeClassName: (aRequest stringArgumentNamed: 'className')
		  classSide:
		  (aRequest booleanArgumentNamed: 'classSide' default: false)
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
