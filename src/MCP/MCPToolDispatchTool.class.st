Class {
	#name : 'MCPToolDispatchTool',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - execution' }
MCPToolDispatchTool >> commandForRequest: dispatchRequest [

	^ MCPDispatchToolCommand tool: self request: dispatchRequest
]

{ #category : 'defaults' }
MCPToolDispatchTool >> defaultDescription [

	^ 'Invoke one MCP-Pharo tool selected by name from the discoverable catalog. The target tool receives the nested arguments object and is validated through its own schema.'
]

{ #category : 'defaults' }
MCPToolDispatchTool >> defaultIcons [

	^ { (self pngIconNamed: #go) }
]

{ #category : 'defaults' }
MCPToolDispatchTool >> defaultInputSchema [

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
MCPToolDispatchTool >> defaultName [

	^ 'dispatch-tool'
]

{ #category : 'defaults' }
MCPToolDispatchTool >> defaultOutputSchema [

	| resultProperty |
	resultProperty := self
		                  schemaPropertyNamed: 'result'
		                  type: 'object'
		                  description:
		                  'The target tool result when dispatch-tool is executed outside MCP server fast-path dispatch.'.
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
MCPToolDispatchTool >> defaultTitle [

	^ 'Dispatch Tool'
]

{ #category : 'executing' }
MCPToolDispatchTool >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :dispatchRequest |
				  self
					  errorResultText:
					  'dispatch-tool requires MCP server dispatch context.'
					  details:
					  { (#toolName -> dispatchRequest toolName) } asDictionary ]
		  onError: [ :error :parsedRequest | self errorResultFor: error ]
]

{ #category : 'private - request' }
MCPToolDispatchTool >> parsedRequestFromToolRequest: request [

	^ MCPDispatchToolRequest fromToolRequest: request
]
