Extension { #name : 'MCPMethodRewriteRuleSpec' }

{ #category : '*MCP-IDE-Compatibility-From12' }
MCPMethodRewriteRuleSpec >> validatePatterns [

	[ self addToRewriter: RBParseTreeRewriter new ]
		on: Error
		do: [ :error | self signalInvalidPatternError: error ]
]
