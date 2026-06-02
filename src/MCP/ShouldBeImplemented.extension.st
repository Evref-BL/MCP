Extension { #name : 'ShouldBeImplemented' }

{ #category : '*MCP' }
ShouldBeImplemented >> mcpDebugMethodUpdateKind [

	^ 'shouldBeImplemented'
]

{ #category : '*MCP' }
ShouldBeImplemented >> mcpDebugRepairActionsFor: aRepairAnalyzer [

	| action |
	action := aRepairAnalyzer
		          stubActionFor: self
		          kind: 'shouldBeImplemented'.
	^ action ifNil: [ #(  ) ] ifNotNil: [ { action } ]
]
