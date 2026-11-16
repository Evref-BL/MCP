Extension { #name : 'MCPTool' }

{ #category : '*MCP-IDE' }
MCPTool >> addLineAndCodeAt: anInterval flaggedBy: aRuleClassName in: aString to: data [
	"The line of aString a critique is on and the code there, shown the same way by every answer that shows a critique."

	| quoted |
	quoted := self quoteIntervalAt: anInterval flaggedBy: aRuleClassName in: aString.
	data at: #line put: (self lineNumberAt: quoted first in: aString).
	(self codeQuoteFor: quoted in: aString) ifNotEmpty: [ :code | data at: #code put: code ]
]

{ #category : '*MCP-IDE' }
MCPTool >> quoteIntervalAt: anInterval flaggedBy: aRuleClassName in: aString [
	"The part of aString a critique's line and code show: the code it flags, except for a send that will not be understood and is too long to quote whole. That one is shown from its first keyword, which the critique is about: from its receiver, the receiver and the first argument would push the other keywords out of the quote, and the formatter may put the receiver on a line of its own. A send written in parentheses leaves out the closing one, as its opening one goes with the receiver."

	(self unimplementedSendRuleNames includes: aRuleClassName) ifFalse: [ ^ anInterval ].
	(self codeQuoteFor: anInterval in: aString) = (self flaggedCodeFor: anInterval in: aString) ifTrue: [ ^ anInterval ].
	^ self
		  sendAt: anInterval
		  in: aString
		  ifFound: [ :send | send keywordsPositions first to: send stopWithoutParentheses ]
		  ifNone: [ anInterval ]
]

{ #category : '*MCP-IDE' }
MCPTool >> sendAt: anInterval in: aString ifFound: foundBlock ifNone: noneBlock [
	"foundBlock with the send in the method aString that spans anInterval, as a critique of a send gives it, or noneBlock when there is none or aString does not parse."

	^ (RBParser parseMethod: aString onError: [ :message :position | ^ noneBlock value ]) allChildren
		  detect: [ :each | each isMessage and: [ each sourceInterval = anInterval ] ]
		  ifFound: foundBlock
		  ifNone: noneBlock
]

{ #category : '*MCP-IDE' }
MCPTool >> unimplementedSendRuleNames [
	"The rules that flag a send that will not be understood: ReSentNotImplementedRule when nothing in the image implements its selector, the others when its receiver, self, super or a global, does not, which the first then says too. They are named rather than referenced, since older Pharo versions have no ReSentButNotUnderstoodBySuperRule."

	^ #( #ReSentNotImplementedRule #ReSelfSentNotImplementedRule #ReSendsUnknownMessageToGlobalRule
	     #ReSentButNotUnderstoodBySuperRule )
]
