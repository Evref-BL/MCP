"
Parsed inspect-method tool request derived from one validated MCPToolRequest.
"
Class {
	#name : 'MCPInspectMethodRequest',
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
MCPInspectMethodRequest class >> fromRequest: aRequest tool: aTool [

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
MCPInspectMethodRequest >> className [

	^ className
]

{ #category : 'accessing' }
MCPInspectMethodRequest >> classSide [

	^ classSide
]

{ #category : 'accessing' }
MCPInspectMethodRequest >> classSide: anObject [

	classSide := anObject
]

{ #category : 'accessing' }
MCPInspectMethodRequest >> includeVariableDetails [

	^ includeVariableDetails
]

{ #category : 'initialization' }
MCPInspectMethodRequest >> initializeClassName: aClassName selectorString: aSelectorString classSide: aSide includeVariableDetails: aBoolean [

	className := aClassName.
	selectorString := aSelectorString.
	classSide := aSide.
	includeVariableDetails := aBoolean.
	^ self
]

{ #category : 'accessing' }
MCPInspectMethodRequest >> selectorString [

	^ selectorString
]
