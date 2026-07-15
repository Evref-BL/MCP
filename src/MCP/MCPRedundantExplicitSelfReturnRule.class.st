"
Renraku rule that warns about a redundant explicit return of self as the final top-level statement of a method.
"
Class {
	#name : 'MCPRedundantExplicitSelfReturnRule',
	#superclass : 'ReAbstractRule',
	#category : 'MCP-Critiques',
	#package : 'MCP',
	#tag : 'Critiques'
}

{ #category : 'testing' }
MCPRedundantExplicitSelfReturnRule class >> checksMethod [

	^ true
]

{ #category : 'accessing' }
MCPRedundantExplicitSelfReturnRule class >> group [

	^ #'Design Flaws'
]

{ #category : 'accessing' }
MCPRedundantExplicitSelfReturnRule class >> rationale [

	^ 'Methods implicitly return self. Remove a final top-level ^ self; keep explicit self returns only when they exit a branch early.'
]

{ #category : 'accessing' }
MCPRedundantExplicitSelfReturnRule class >> ruleName [

	^ 'Remove redundant final explicit self return'
]

{ #category : 'accessing' }
MCPRedundantExplicitSelfReturnRule class >> severity [

	^ #warning
]

{ #category : 'accessing' }
MCPRedundantExplicitSelfReturnRule class >> uniqueIdentifierName [

	^ self name asString
]

{ #category : 'running' }
MCPRedundantExplicitSelfReturnRule >> check: aMethod forCritiquesDo: aCriticBlock [

	| returnNode statements |
	statements := aMethod ast body statements.
	statements ifEmpty: [ ^ self ].
	returnNode := statements last.
	(returnNode isReturn and: [ returnNode value isSelfVariable ])
		ifFalse: [ ^ self ].
	aCriticBlock cull: (self
			 createTrivialCritiqueOn: aMethod
			 intervalOf: returnNode
			 hint: 'Remove the redundant final explicit return of self.')
]

{ #category : 'accessing' }
MCPRedundantExplicitSelfReturnRule >> name [

	^ self class ruleName
]
