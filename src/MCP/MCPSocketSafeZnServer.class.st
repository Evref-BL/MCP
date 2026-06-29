"
Zinc server used by the MCP HTTP transport.

It treats socket errors while reading a request as connection termination. This matters after image restart because serialized connection processes can resume with invalid native sockets; they should close quietly instead of opening a debugger.
"
Class {
	#name : 'MCPSocketSafeZnServer',
	#superclass : 'ZnManagingMultiThreadedServer',
	#category : 'MCP-Server',
	#package : 'MCP',
	#tag : 'Server'
}

{ #category : 'private' }
MCPSocketSafeZnServer >> readRequestTerminationExceptionSet [

	^ super readRequestTerminationExceptionSet
	  , (self exceptionSet: #( #SocketError ))
]
