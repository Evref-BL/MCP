"
Static bridge tool for searching the discoverable tool catalog.

It is intentionally kept on the fast path so agents can find optional or specialized tools without requiring those tools to be statically advertised.
"
Class {
	#name : 'MCPToolSearchTools',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolSearchTools class >> toolName [

	^ 'tool_search'
]

{ #category : 'private - execution' }
MCPToolSearchTools >> commandForRequest: searchRequest [

	^ MCPSearchToolsCommand tool: self request: searchRequest
]

{ #category : 'defaults' }
MCPToolSearchTools >> defaultDescription [

	^ 'Search all MCP-Pharo tools. Use to discover tool names before tool_get or tool_call.'
]

{ #category : 'defaults' }
MCPToolSearchTools >> defaultInputSchema [

	| limitProperty |
	limitProperty := self
		                 integerSchemaPropertyNamed: 'limit'
		                 description: 'Maximum tools to return.'
		                 default: 25.
	limitProperty
		minimum: 0;
		maximum: 100.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   schemaPropertyNamed: 'query'
					   type: 'string'
					   description:
						   'Search text for tool names, descriptions, or groups.').
				  (self
					   schemaPropertyNamed: 'group'
					   type: 'string'
					   description: 'Optional tool group filter.').
				  limitProperty };
		  required: #(  );
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolSearchTools >> defaultOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties:
		  { self toolsArraySchemaProperty }
		  required: #( 'tools' )
]

{ #category : 'defaults' }
MCPToolSearchTools >> defaultTitle [

	^ 'Search Tool Catalog'
]

{ #category : 'executing' }
MCPToolSearchTools >> executeWithRequest: request [

	^ self
		  executeWithRequest: request
		  usingPolicy: MCPToolExposurePolicy default
]

{ #category : 'executing' }
MCPToolSearchTools >> executeWithRequest: request usingPolicy: aToolExposurePolicy [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :searchRequest |
				  | data |
				  data := (MCPSearchToolsCommand
					           tool: self
					           request: searchRequest
					           toolExposurePolicy: aToolExposurePolicy) execute.
				  self
					  successResultText:
					  (data at: #tools) size asString , ' tools found.'
					  data: data ]
		  onError: [ :error :parsedRequest | self errorResultFor: error ]
]

{ #category : 'private - request' }
MCPToolSearchTools >> parsedRequestFromToolRequest: request [

	^ MCPSearchToolsRequest fromToolRequest: request
]

{ #category : 'private - schema' }
MCPToolSearchTools >> toolMetadataObjectSchema [

	^ MCPStructureProperties new
		  type: 'object';
		  description: 'Compact metadata for one MCP-Pharo tool.';
		  properties: {
				  (self
					   schemaPropertyNamed: 'name'
					   type: 'string'
					   description: 'MCP tool name.').
				  (self
					   schemaPropertyNamed: 'description'
					   type: 'string'
					   description: 'Short description.').
				  (self
					   booleanSchemaPropertyNamed: 'schemaInspectionRequired'
					   description: 'Inspect schema before calling.') };
		  required: #( 'name' 'description' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - schema' }
MCPToolSearchTools >> toolsArraySchemaProperty [

	^ (self
		   schemaPropertyNamed: 'tools'
		   type: 'array'
		   description: 'Matching tool metadata entries.')
		  items: self toolMetadataObjectSchema;
		  yourself
]
