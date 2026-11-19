Extension { #name : 'OCCompilationError' }

{ #category : '*MCP-IDE-Compatibility-From14' }
OCCompilationError >> mcpCompilationAst [

	^ self compilationResult ast
]

{ #category : '*MCP-IDE-Compatibility-From14' }
OCCompilationError >> mcpNoticeNode [

	^ self mcpCompilationAst variableNodes
		  detect: [ :node | node variable isNotNil and: [ node variable isUndeclaredVariable ] ]
		  ifNone: [ nil ]
]
