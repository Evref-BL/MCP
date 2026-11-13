Extension { #name : 'MCPMethodRewriteRuleSpec' }

{ #category : '*MCP-IDE-Compatibility-From12' }
MCPMethodRewriteRuleSpec >> validatePatterns [

	[ StRewriterRBApplier rewriter: { self asStRewriterRuleHolder } ]
		on: Error
		do: [ :error | self signalInvalidPatternError: error ]
]
