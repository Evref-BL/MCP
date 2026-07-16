"
Renraku rule that warns about a redundant explicit return of self as the final top-level statement of a method when other statements precede it. A method consisting only of ^ self is accepted as an intentional no-op.
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

	^ 'In methods with preceding statements, an explicit final ^ self is redundant because methods implicitly return self. A method consisting only of ^ self can use that explicit return to communicate intentional no-op behavior.'
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
	statements size <= 1 ifTrue: [ ^ self ].
	returnNode := statements last.
	(returnNode isReturn and: [ returnNode value isSelfVariable ]) ifFalse: [ ^ self ].
	aCriticBlock cull:
		(self createTrivialCritiqueOn: aMethod intervalOf: returnNode hint: 'Remove the redundant final explicit return of self.')
]

{ #category : 'accessing' }
MCPRedundantExplicitSelfReturnRule >> name [

	^ self class ruleName
]
