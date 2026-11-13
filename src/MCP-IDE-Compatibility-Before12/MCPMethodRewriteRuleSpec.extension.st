Extension { #name : 'MCPMethodRewriteRuleSpec' }

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPMethodRewriteRuleSpec >> validatePatterns [
	"Before Pharo 12, the parser signals a syntax error as SyntaxErrorNotification, which is not an Error, and Pharo 10 has no StRewriter: the patterns are tried on the rewriter StRewriterRBApplier would build."

	[
	| rewriter |
	rewriter := RBParseTreeRewriter new.
	self isForMethod
		ifTrue: [ rewriter replaceMethod: self match with: self replacement ]
		ifFalse: [ rewriter replace: self match with: self replacement ] ]
		on: Error , SyntaxErrorNotification
		do: [ :error | self signalInvalidPatternError: error ]
]
