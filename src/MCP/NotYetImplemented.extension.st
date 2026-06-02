Extension { #name : 'NotYetImplemented' }

{ #category : '*MCP' }
NotYetImplemented >> mcpDebugMethodUpdateKind [

	^ 'notYetImplemented'
]

{ #category : '*MCP' }
NotYetImplemented >> mcpDebugRepairActionsFor: aRepairAnalyzer [

	| action |
	action := aRepairAnalyzer
		          stubActionFor: self
		          kind: 'notYetImplemented'.
	^ action ifNil: [ #(  ) ] ifNotNil: [ { action } ]
]
