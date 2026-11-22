Extension { #name : 'JRPCError' }

{ #category : '*MCP' }
JRPCError >> mcpIsProtocolError [

	^ true
]

{ #category : '*MCP' }
JRPCError >> mcpJRPCResponseWithId: anId [
	"A protocol error answers as its class says."

	^ self asJRPCResponseWithId: anId
]
