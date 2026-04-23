Class {
	#name : 'MCPScopeQuery',
	#superclass : 'Object',
	#instVars : [
		'scope'
	],
	#category : 'MCP-Internal',
	#package : 'MCP',
	#tag : 'Internal'
}

{ #category : 'initialization' }
MCPScopeQuery >> initialize [

	super initialize.
	scope := 'image'
]

{ #category : 'private - normalization' }
MCPScopeQuery >> normalizedScopeString: aScope [

	^ aScope ifNil: [ 'image' ] ifNotNil: [ aScope asString asLowercase ]
]

{ #category : 'private - normalization' }
MCPScopeQuery >> normalizedStringCollection: aValue argumentName: anArgumentName [

	| normalized value values |
	aValue ifNil: [ ^ #(  ) ].
	value := aValue.
	(value isString or: [ value isSymbol ]) ifTrue: [ value := { value } ].
	(value isCollection and: [ value isString not ]) ifFalse: [
		Error signal: anArgumentName , ' must be an array of strings.' ].
	values := OrderedCollection new.
	value do: [ :each |
		normalized := each asString trimBoth.
		normalized isEmpty ifFalse: [ values add: normalized ] ].
	^ values asArray
]

{ #category : 'accessing' }
MCPScopeQuery >> scope [

	^ scope
]

{ #category : 'accessing' }
MCPScopeQuery >> scope: aScope [

	scope := self normalizedScopeString: aScope
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
