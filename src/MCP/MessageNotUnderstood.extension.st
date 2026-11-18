Extension { #name : 'MessageNotUnderstood' }

{ #category : '*MCP' }
MessageNotUnderstood >> mcpAddToolErrorDetailsTo: aDictionary [
	"Say what the message was most likely meant to be, or, sent to nil, the send in the caller's own code it came from; and name the selectors the receiver's class understands that resemble it, the way the debugger would, unless the note says they are beside the point: nil's own selectors are nobody's guess, and a message the other side of the class understands was not mistyped."

	| note suggestions |
	note := MCPNotUnderstoodNote on: self.
	note text ifNotNil: [ :text | aDictionary at: #note put: text ].
	note leavesOutSuggestions ifTrue: [ ^ aDictionary ].
	suggestions := MCPSelectorSuggestion selectorsLike: self message selector understoodBy: self receiver class.
	suggestions ifNotEmpty: [ aDictionary at: #suggestedSelectors put: suggestions ].
	^ aDictionary
]
