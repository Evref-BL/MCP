Extension { #name : 'MCPSocketSafeZnServer' }

{ #category : '*MCP-Compatibility-Before12' }
MCPSocketSafeZnServer >> listensAsAsked: aSocket [
	"Before Pharo 12, listening binds and listens in one primitive, and on a port another socket holds the bind fails silently and listen picks a free port instead."

	^ aSocket isValid and: [ self port isZero or: [ aSocket port = self port ] ]
]
