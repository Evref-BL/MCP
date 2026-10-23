"
MCP protocol structure for the completions capability.

The capability carries no flags: a server either answers completion/complete or it does not.
"
Class {
	#name : 'MCPStructureCompletionsCapabilities',
	#superclass : 'Object',
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'converting' }
MCPStructureCompletionsCapabilities >> asJRPCJSON [

	^ Dictionary new
]
