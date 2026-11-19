Extension { #name : 'MessageNotUnderstood' }

{ #category : '*MCP' }
MessageNotUnderstood >> mcpAddToolErrorDetailsTo: aDictionary [
	"Name the selectors the receiver's class understands that resemble the message, the way the debugger would, unless they are beside the point: nil's own are nobody's guess, nor are they when a note says what was meant instead."

	| suggestions |
	self mcpAddNoteTo: aDictionary ifItLeavesOutSuggestions: [ ^ aDictionary ].
	self receiver ifNil: [ ^ aDictionary ].
	suggestions := MCPSelectorSuggestion selectorsLike: self message selector understoodBy: self receiver class.
	suggestions ifNotEmpty: [ aDictionary at: #suggestedSelectors put: suggestions ].
	^ aDictionary
]
