Extension { #name : 'MCPSocketSafeZnServer' }

{ #category : '*MCP-Compatibility-From12' }
MCPSocketSafeZnServer >> listensAsAsked: aSocket [
	"From Pharo 12 on, listening on a port another socket holds fails to bind and leaves the socket invalid."

	^ aSocket isValid
]
