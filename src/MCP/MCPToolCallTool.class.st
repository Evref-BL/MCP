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

	| argumentsProperty nameProperty |
	nameProperty := self schemaPropertyNamed: 'name' type: 'string' description: 'Tool name to invoke.'.
	nameProperty minLength: 1.
	argumentsProperty := self schemaPropertyNamed: 'arguments' type: 'object' description: 'Arguments passed to the selected tool.'.
	argumentsProperty additionalProperties: true.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  nameProperty.
				  argumentsProperty };
		  required: #( 'name' );
		  additionalProperties: false;
		  yourself
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

	^ self
		  executeRequest: request
		  do: [ :ignored |
				  self
					  errorResultText: 'tool_call requires MCP server call context.'
					  details: { (#name -> (request stringArgumentNamed: 'name')) } asDictionary ]
		  onError: [ :error :ignored | self errorResultFor: error ]
]

{ #category : 'metadata' }
MCPToolCallTool >> title [

	^ 'Call Tool'
]
