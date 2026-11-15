"
MCPPostResponseActions holds the post-response action queue for the active MCP request process.

MCPSocketSafeZnServer binds an OrderedCollection while Zinc executes one request. Tools append actions that must run after the HTTP response is produced without sharing a queue across request processes.
"
Class {
	#name : 'MCPPostResponseActions',
	#superclass : 'DynamicVariable',
	#category : 'MCP-Transport',
	#package : 'MCP',
	#tag : 'Transport'
}

{ #category : 'deferring' }
MCPPostResponseActions class >> defer: aBlock [
	"Run after the response of the call being served, so that its caller does not wait for it; at once when no response is pending."

	self value ifNil: [ aBlock value ] ifNotNil: [ :actions | actions add: aBlock ]
]
