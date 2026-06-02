"
Renraku rule that warns when MCP-authored methods catch MessageNotUnderstood as normal control flow.

MessageNotUnderstood should model an actual exceptional send failure, not be used as a substitute for collaborator contracts, typed boundary adapters, or explicit MCP compatibility messages. When an external object has optional protocol, add a small dispatch point such as an mcp-prefixed extension method and let ordinary message dispatch express the variation.
"
Class {
	#name : 'MCPMessageNotUnderstoodHandlerRule',
	#superclass : 'ReAbstractRule',
	#category : 'MCP-Critiques',
	#package : 'MCP',
	#tag : 'Critiques'
}

{ #category : 'testing' }
MCPMessageNotUnderstoodHandlerRule class >> checksMethod [

	^ true
]

{ #category : 'accessing' }
MCPMessageNotUnderstoodHandlerRule class >> forbiddenExceptionName [

	^ #MessageNotUnderstood
]

{ #category : 'accessing' }
MCPMessageNotUnderstoodHandlerRule class >> group [

	^ self designFlawGroup
]

{ #category : 'accessing' }
MCPMessageNotUnderstoodHandlerRule class >> rationale [

	^ 'Avoid handling MessageNotUnderstood as ordinary control flow. Prefer explicit collaborator contracts, typed boundary adapters, or MCP compatibility messages; reserve MNU handling for true exception/debugger behavior.'
]

{ #category : 'accessing' }
MCPMessageNotUnderstoodHandlerRule class >> ruleName [

	^ 'Avoid MessageNotUnderstood handlers'
]

{ #category : 'accessing' }
MCPMessageNotUnderstoodHandlerRule class >> severity [

	^ #warning
]

{ #category : 'accessing' }
MCPMessageNotUnderstoodHandlerRule class >> uniqueIdentifierName [

	^ 'MCPMessageNotUnderstoodHandlerRule'
]

{ #category : 'running' }
MCPMessageNotUnderstoodHandlerRule >> check: aMethod forCritiquesDo: aCriticBlock [

	aMethod sendNodes do: [ :sendNode |
			(self isMessageNotUnderstoodHandlerSend: sendNode) ifTrue: [
					aCriticBlock cull: (self
							 createTrivialCritiqueOn: aMethod
							 intervalOf: sendNode
							 hint:
							 'Use explicit dispatch or an MCP compatibility message instead of catching MessageNotUnderstood.') ] ]
]

{ #category : 'private' }
MCPMessageNotUnderstoodHandlerRule >> isMessageNotUnderstoodHandlerSend: sendNode [

	| exceptionNode |
	sendNode selector = #on:do: ifFalse: [ ^ false ].
	exceptionNode := sendNode arguments first.
	^ exceptionNode isVariable and: [
		  exceptionNode name = self class forbiddenExceptionName ]
]

{ #category : 'accessing' }
MCPMessageNotUnderstoodHandlerRule >> name [

	^ self class ruleName
]
