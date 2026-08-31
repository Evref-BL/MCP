"
Test fixture MCP subclass used to verify inherited JSON-RPC handler registration and subclass handler overrides.
"
Class {
	#name : 'MCPSubclassHandlerTestServer',
	#superclass : 'MCP',
	#category : 'MCP-Tests-Resources-Fixtures',
	#package : 'MCP-Tests-Resources',
	#tag : 'Fixtures'
}

{ #category : 'jrpc' }
MCPSubclassHandlerTestServer >> rpcPing [

	<jrpc: #ping>
	^ { (#source -> 'subclass') } asDictionary
]
