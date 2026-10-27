Extension { #name : 'MessageNotUnderstood' }

{ #category : '*MCP' }
MessageNotUnderstood >> mcpAddToolErrorDetailsTo: aDictionary [
	"Name the selectors the receiver's class does understand that resemble the one it did not, the way the debugger would."

	| suggestions |
	suggestions := MCPSelectorSuggestion selectorsLike: self message selector understoodBy: self receiver class.
	suggestions ifNotEmpty: [ aDictionary at: #suggestedSelectors put: suggestions ].
	^ aDictionary
]
