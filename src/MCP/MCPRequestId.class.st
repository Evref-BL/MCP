"
The id of the JSON-RPC request this process is handling, nil outside one and for a request without one. Whoever records a call reads it from here, as it reads MCPRequestMeta.
"
Class {
	#name : 'MCPRequestId',
	#superclass : 'DynamicVariable',
	#category : 'MCP-Observability',
	#package : 'MCP',
	#tag : 'Observability'
}
