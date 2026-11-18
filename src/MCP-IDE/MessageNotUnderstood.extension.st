Extension { #name : 'MessageNotUnderstood' }

{ #category : '*MCP-IDE' }
MessageNotUnderstood >> mcpTestIssueNote [
	"What the message was most likely meant to be. A message sent to nil gets no note: the issue's place already names the method that sent it."

	^ (MCPNotUnderstoodNote on: self) meantText
]
