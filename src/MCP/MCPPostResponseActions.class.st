"
MCPPostResponseActions holds the post-response action queue for the active MCP request process.

MCPSocketSafeZnServer binds an OrderedCollection while Zinc executes one request. Tools append actions that must run after the HTTP response is produced without sharing a queue across request processes.
"
Class {
	#name : 'MCPPostResponseActions',
	#superclass : 'DynamicVariable',
	#category : 'MCP-Server',
	#package : 'MCP',
	#tag : 'Server'
}
