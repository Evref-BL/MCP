"
Parsed method_get tool request derived from one validated MCPToolRequest.
"
Class {
	#name : 'MCPGetMethodRequest',
	#superclass : 'Object',
	#instVars : [
		'className',
		'selectorString',
		'includeVariableDetails',
		'classSide'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPGetMethodRequest class >> fromRequest: aRequest tool: aTool [

	^ self new
		  initializeClassName: (aRequest stringArgumentNamed: 'className')
		  selectorString: (aTool selectorStringFromRequest: aRequest)
		  classSide:
		  (aRequest booleanArgumentNamed: 'classSide' default: false)
		  includeVariableDetails: (aRequest
				   booleanArgumentNamed: 'includeVariableDetails'
				   default: false)
]

{ #category : 'accessing' }
MCPGetMethodRequest >> className [

	^ className
]

{ #category : 'accessing' }
MCPGetMethodRequest >> classSide [

	^ classSide
]

{ #category : 'accessing' }
MCPGetMethodRequest >> classSide: anObject [

	classSide := anObject
]

{ #category : 'accessing' }
MCPGetMethodRequest >> includeVariableDetails [

	^ includeVariableDetails
]

{ #category : 'initialization' }
MCPGetMethodRequest >> initializeClassName: aClassName selectorString: aSelectorString classSide: aSide includeVariableDetails: aBoolean [

	className := aClassName.
	selectorString := aSelectorString.
	classSide := aSide.
	includeVariableDetails := aBoolean.
	^ self
]

{ #category : 'accessing' }
MCPGetMethodRequest >> selectorString [

	^ selectorString
]
