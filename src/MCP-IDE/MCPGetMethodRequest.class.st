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
	#category : 'MCP-IDE-Requests',
	#package : 'MCP-IDE',
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
				message: (String streamContents: [ :stream |
						 stream << (text ifNil: [ 'A method' ] ifNotNil: [ :each | each ]) << ' does not name a method. ' << self helpText ])
				details: { (#selector -> text) } asDictionary ].
	^ MCPImageLookup className: className side: (aRequest stringArgumentNamed: 'side') do: [ :baseName :isClassSide :isSideGiven |
			  self new
				  initializeClassName: baseName
				  selectorString: text
				  classSide: isClassSide
				  includeVariableDetails: (aRequest booleanArgumentNamed: 'includeVariableDetails' default: false) ]
]

{ #category : 'accessing' }
MCPGetMethodRequest class >> helpText [
	"method_get, unlike the other tools that read a method's reference, has a class argument for a bare selector."

	^ MCPMethodReference helpText , ' A bare selector works too when class is given.'
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
