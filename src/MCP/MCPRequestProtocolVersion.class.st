"
The protocol version the HTTP request this process is handling names in its MCP-Protocol-Version header, nil outside one and for a request without it. A client sends it on every request after initialize from the 2025-06-18 revision on, so it names the version of a client whose requests do not declare one in their _meta. Whoever records a call reads it from here, as it reads MCPRequestMeta.
"
Class {
	#name : 'MCPRequestProtocolVersion',
	#superclass : 'DynamicVariable',
	#category : 'MCP-Observability',
	#package : 'MCP',
	#tag : 'Observability'
}
