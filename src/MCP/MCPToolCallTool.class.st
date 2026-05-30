"
Static bridge tool that invokes tools from the discoverable catalog.

The tool keeps the advertised static surface small while still allowing agents to call less common tools after discovery and inspection.
"
Class {
	#name : 'MCPToolCallTool',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'icons' }
MCPToolCallTool class >> toolIconSpec [

	^ MCPToolIconSpec named: #go
]

{ #category : 'defaults' }
MCPToolCallTool class >> toolName [

	^ 'tool_call'
]

{ #category : 'private - execution' }
MCPToolCallTool >> commandForRequest: callRequest [

	^ MCPCallToolCommand tool: self request: callRequest
]

{ #category : 'defaults' }
MCPToolCallTool >> defaultDescription [

	^ 'Invoke one MCP-Pharo tool selected by name from the discoverable catalog. The target tool receives the nested arguments object and is validated through its own schema.'
]

{ #category : 'defaults' }
MCPToolCallTool >> defaultInputSchema [

	| argumentsProperty toolNameProperty |
	toolNameProperty := self
		                    schemaPropertyNamed: 'toolName'
		                    type: 'string'
		                    description: 'The MCP tool name to invoke.'.
	toolNameProperty minLength: 1.
	argumentsProperty := self
		                     schemaPropertyNamed: 'arguments'
		                     type: 'object'
		                     description:
		                     'Arguments passed to the selected tool.'.
	argumentsProperty additionalProperties: true.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  toolNameProperty.
				  argumentsProperty };
		  required: #( 'toolName' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolCallTool >> defaultOutputSchema [

	| resultProperty |
	resultProperty := self
		                  schemaPropertyNamed: 'result'
		                  type: 'object'
		                  description:
		                  'The target tool result when tool_call is executed outside the MCP server call path.'.
	resultProperty additionalProperties: true.
	^ self
		  standardOutputSchemaForDataProperties: {
				  (self
					   schemaPropertyNamed: 'targetToolName'
					   type: 'string'
					   description: 'The selected target tool name.').
				  resultProperty }
		  required: #( 'targetToolName' 'result' )
]

{ #category : 'defaults' }
MCPToolCallTool >> defaultTitle [

	^ 'Call Tool'
]

{ #category : 'executing' }
MCPToolCallTool >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :callRequest |
				  self
					  errorResultText: 'tool_call requires MCP server call context.'
					  details: { (#toolName -> callRequest toolName) } asDictionary ]
		  onError: [ :error :parsedRequest | self errorResultFor: error ]
]

{ #category : 'private - request' }
MCPToolCallTool >> parsedRequestFromToolRequest: request [

	^ MCPCallToolRequest fromToolRequest: request
]
