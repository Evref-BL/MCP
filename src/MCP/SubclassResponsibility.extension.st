Extension { #name : 'SubclassResponsibility' }

{ #category : '*MCP' }
SubclassResponsibility >> mcpDebugMethodUpdateKind [

	^ 'subclassResponsibility'
]

{ #category : '*MCP' }
SubclassResponsibility >> mcpDebugRepairActionsFor: aRepairAnalyzer [

	| action |
	action := aRepairAnalyzer subclassResponsibilityActionFor: self.
	^ action ifNil: [ #(  ) ] ifNotNil: [ { action } ]
]
