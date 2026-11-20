Extension { #name : 'MessageNotUnderstood' }

{ #category : '*MCP-IDE' }
MessageNotUnderstood >> mcpAddNoteTo: aDictionary ifItLeavesOutSuggestions: aBlock [
	"Say what the message was most likely meant to be, or, sent to nil, the send in the caller's own code it came from. A message the other side of the class understands was not mistyped, so the selectors that resemble it are then beside the point."

	| note |
	note := MCPNotUnderstoodNote on: self.
	note text ifNotNil: [ :text | aDictionary at: #note put: text ].
	note leavesOutSuggestions ifTrue: [ aBlock value ]
]

{ #category : '*MCP-IDE' }
MessageNotUnderstood >> mcpTestIssueNote [
	"What the message was most likely meant to be. A message sent to nil gets no note: the issue's place already names the method that sent it."

	^ (MCPNotUnderstoodNote on: self) meantText
]
