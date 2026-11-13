Extension { #name : 'MCPMethodRewriteRuleSpec' }

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPMethodRewriteRuleSpec >> validatePatterns [
	"Before Pharo 12, the parser signals a syntax error as SyntaxErrorNotification, which is not an Error."

	[ StRewriterRBApplier rewriter: { self asStRewriterRuleHolder } ]
		on: Error , SyntaxErrorNotification
		do: [ :error | self signalInvalidPatternError: error ]
]
