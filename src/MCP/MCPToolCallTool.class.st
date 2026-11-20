"
Static bridge tool that invokes tools from the discoverable catalog.

The tool keeps the advertised static surface small while still allowing agents to call less common tools after discovery and contract lookup.
"
Class {
	#name : 'MCPToolCallTool',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolCallTool class >> groupName [

	^ self toolCatalogGroupName
]

{ #category : 'metadata' }
MCPToolCallTool class >> toolName [

	^ 'tool_call'
]

{ #category : 'metadata' }
MCPToolCallTool >> buildInputSchema [

	^ MCPStructureInputSchema
		  properties: {
				  ((self schemaPropertyNamed: 'name' type: 'string' description: 'Tool name to invoke.')
					   minLength: 1;
					   yourself).
				  ((self schemaPropertyNamed: 'arguments' type: 'object' description: 'Arguments passed to the selected tool.')
					   additionalProperties: true;
					   yourself) }
		  required: #( 'name' )
]

{ #category : 'metadata' }
MCPToolCallTool >> defaultExposure [

	^ 'static'
]

{ #category : 'metadata' }
MCPToolCallTool >> description [

	^ 'Call a tool not in your list by name, with its arguments. tool_search finds such tools.'
]

{ #category : 'executing' }
MCPToolCallTool >> executeWithRequest: request [
	"The server dispatches a tool_call itself, so a call that reaches the tool did not come through one."

	^ self executeRequest: request do: [
			  self
				  errorResultText: 'tool_call requires MCP server call context.'
				  details: { (#name -> (request stringArgumentNamed: 'name')) } asDictionary ]
]

{ #category : 'metadata' }
MCPToolCallTool >> title [

	^ 'Call Tool'
]
