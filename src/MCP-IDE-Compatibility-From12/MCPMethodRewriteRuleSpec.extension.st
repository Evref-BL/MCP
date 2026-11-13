Extension { #name : 'MCPMethodRewriteRuleSpec' }

{ #category : '*MCP-IDE-Compatibility-From12' }
MCPMethodRewriteRuleSpec >> asStRewriterRuleHolder [

	^ StRewriterRuleHolder lhs: self match rhs: self replacement isForMethod: self isForMethod
]

{ #category : '*MCP-IDE-Compatibility-From12' }
MCPMethodRewriteRuleSpec >> validatePatterns [

	[ StRewriterRBApplier rewriter: { self asStRewriterRuleHolder } ]
		on: Error
		do: [ :error | self signalInvalidPatternError: error ]
]
