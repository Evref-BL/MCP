"
Test fixture MCP subclass used to verify inherited JSON-RPC handler registration and subclass handler overrides.
"
Class {
	#name : 'MCPSubclassHandlerTestServer',
	#superclass : 'MCP',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'jrpc' }
MCPSubclassHandlerTestServer >> rpcPing [

	<jrpc: #ping>
	^ { (#source -> 'subclass') } asDictionary
]
