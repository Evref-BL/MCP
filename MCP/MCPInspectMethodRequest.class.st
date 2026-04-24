"
Parsed inspect-method tool request derived from one validated MCPToolRequest.
"
Class {
	#name : 'MCPInspectMethodRequest',
	#superclass : 'Object',
	#instVars : [
		'className',
		'selectorString',
		'side',
		'includeVariableDetails'
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
		  side: (aTool sideFromRequest: aRequest)
		  includeVariableDetails: (aRequest
				   booleanArgumentNamed: 'includeVariableDetails'
				   default: false)
]

{ #category : 'accessing' }
MCPInspectMethodRequest >> className [

	^ className
]

{ #category : 'accessing' }
MCPInspectMethodRequest >> includeVariableDetails [

	^ includeVariableDetails
]

{ #category : 'initialization' }
MCPInspectMethodRequest >> initializeClassName: aClassName selectorString: aSelectorString side: aSide includeVariableDetails: aBoolean [

	className := aClassName.
	selectorString := aSelectorString.
	side := aSide.
	includeVariableDetails := aBoolean.
	^ self
]

{ #category : 'accessing' }
MCPInspectMethodRequest >> selectorString [

	^ selectorString
]

{ #category : 'accessing' }
MCPInspectMethodRequest >> side [

	^ side
]
