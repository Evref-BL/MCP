"
Executes one tool selected from the discoverable MCP tool catalog.

This command is the dynamic dispatch path behind tool_call: it validates the requested catalog entry, invokes the selected MCPTool with nested arguments, and preserves the selected tool's normal output contract.
"
Class {
	#name : 'MCPCallToolCommand',
	#superclass : 'MCPToolRequestCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPCallToolCommand >> execute [

	Error signal: 'tool_call requires MCP server call context.'
]
