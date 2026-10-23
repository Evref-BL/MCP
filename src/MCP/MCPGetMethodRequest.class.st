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

	| text reference className |
	text := aTool selectorStringFromRequest: aRequest.
	reference := MCPMethodReference fromString: text.
	reference ifNotNil: [
			^ self new
				  initializeClassName: reference className
				  selectorString: reference selector
				  classSide: reference classSide
				  includeVariableDetails: (aRequest booleanArgumentNamed: 'includeVariableDetails' default: false) ].
	className := aRequest stringArgumentNamed: 'class'.
	((MCPMethodReference looksLikeAReference: text) or: [ className isNil ]) ifTrue: [
		MCPCommandError
			signalErrorCode: #MethodReferenceUnreadable
			message: (text ifNil: [ 'A method' ] ifNotNil: [ :each | each ]) , ' does not name a method. ' , MCPMethodReference helpText
			details: { (#selector -> text) } asDictionary ].
	^ self new
		  initializeClassName: className
		  selectorString: text
		  classSide: (aRequest booleanArgumentNamed: 'classSide' default: false)
		  includeVariableDetails: (aRequest booleanArgumentNamed: 'includeVariableDetails' default: false)
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
