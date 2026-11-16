Extension { #name : 'MessageNotUnderstood' }

{ #category : '*MCP' }
MessageNotUnderstood >> mcpAddToolErrorDetailsTo: aDictionary [
	"Say what the message was most likely meant to be, or, sent to nil, which method sent it; otherwise name the selectors the receiver's class understands that resemble it, the way the debugger would. nil's own selectors are nobody's guess, so a message sent to nil gets none."

	| suggestions |
	(MCPNotUnderstoodNote on: self) text ifNotNil: [ :note |
			aDictionary at: #note put: note.
			^ aDictionary ].
	self receiver ifNil: [ ^ aDictionary ].
	suggestions := MCPSelectorSuggestion selectorsLike: self message selector understoodBy: self receiver class.
	suggestions ifNotEmpty: [ aDictionary at: #suggestedSelectors put: suggestions ].
	^ aDictionary
]
