Extension { #name : 'SyntaxErrorNotification' }

{ #category : '*MCP-IDE-Compatibility-Before12' }
SyntaxErrorNotification >> mcpErrorPosition [

	^ self location
]

{ #category : '*MCP-IDE-Compatibility-Before12' }
SyntaxErrorNotification >> mcpSyntaxNotice [

	^ MCPSyntaxError
		  messageText: self messageText
		  position: self location
]
