"
The _meta of the request this process is handling, nil outside one. Whoever records a call reads it from here rather than through every signature between the transport and the tool: a caller's trace context travels in it (SEP-414).
"
Class {
	#name : 'MCPRequestMeta',
	#superclass : 'DynamicVariable',
	#category : 'MCP-Observability',
	#package : 'MCP',
	#tag : 'Observability'
}
