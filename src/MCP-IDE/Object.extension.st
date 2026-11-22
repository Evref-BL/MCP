Extension { #name : 'Object' }

{ #category : '*MCP-IDE' }
Object >> mcpCompilationAst [

	^ nil
]

{ #category : '*MCP-IDE' }
Object >> mcpErrorPosition [

	^ nil
]

{ #category : '*MCP-IDE' }
Object >> mcpMethodNode [

	^ nil
]

{ #category : '*MCP-IDE' }
Object >> mcpMutationFailureErrorCodeSuffix [
	"A failure reported without being an exception is a notice the compiler handed on: Pharo 12 hands an evaluation's compile failures on so. Exceptions say for themselves what they are."

	^ 'SyntaxError'
]

{ #category : '*MCP-IDE' }
Object >> mcpNoticeNode [

	^ nil
]

{ #category : '*MCP-IDE' }
Object >> mcpTranscriptToRestore [

	^ self
]
