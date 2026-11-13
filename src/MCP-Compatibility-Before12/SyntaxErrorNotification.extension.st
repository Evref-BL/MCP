Extension { #name : 'SyntaxErrorNotification' }

{ #category : '*MCP-Compatibility-Before12' }
SyntaxErrorNotification >> mcpDefaultAction [
	"Left unhandled, a syntax error quits a headless image. It is signalled as an error instead, which the handlers written for the CodeError of later versions catch."

	^ (MCPSyntaxError
		   messageText: self messageText
		   position: self location) signal
]
