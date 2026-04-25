"
MCP protocol structure for an error tool result.

It is a specialized tool call result that marks the response as an error while preserving normal content and structuredContent shape.
"
Class {
	#name : 'MCPStructureErrorToolResult',
	#superclass : 'MCPStructureCallToolResult',
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'accessing' }
MCPStructureErrorToolResult >> isError [

	^ true
]
