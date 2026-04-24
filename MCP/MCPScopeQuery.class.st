Class {
	#name : 'MCPScopeQuery',
	#superclass : 'Object',
	#instVars : [
		'scope'
	],
	#category : 'MCP-Queries',
	#package : 'MCP',
	#tag : 'Queries'
}

{ #category : 'initialization' }
MCPScopeQuery >> initialize [

	super initialize.
	scope := 'image'
]

{ #category : 'accessing' }
MCPScopeQuery >> scope [

	^ scope
]

{ #category : 'accessing' }
MCPScopeQuery >> scope: aScope [

	scope := aScope ifNil: [ 'image' ] ifNotNil: [ aScope ]
]

{ #category : 'validating' }
MCPScopeQuery >> scopeValidationErrorMessageFor: supportedScopes [

	^ String streamContents: [ :stream |
		  stream nextPutAll: 'scope must be one of '.
		  supportedScopes doWithIndex: [ :each :index |
			  index > 1 ifTrue: [
				  index = supportedScopes size
					  ifTrue: [
						  supportedScopes size > 2
							  ifTrue: [ stream nextPutAll: ', or ' ]
							  ifFalse: [ stream nextPutAll: ' or ' ] ]
					  ifFalse: [ stream nextPutAll: ', ' ] ].
			  stream nextPutAll: each ].
		  stream nextPut: $. ]
]

{ #category : 'validating' }
MCPScopeQuery >> validateScopeIsOneOf: supportedScopes [

	(supportedScopes includes: scope) ifFalse: [
		Error signal: (self scopeValidationErrorMessageFor: supportedScopes) ]
]
