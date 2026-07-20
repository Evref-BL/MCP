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

{ #category : 'metadata' }
MCPToolSearchTools class >> toolName [

	^ 'tool_search'
]

{ #category : 'metadata' }
MCPToolSearchTools >> buildInputSchema [

	^ MCPStructureInputSchema new
		type: 'object';
		properties: {
				(self
					schemaPropertyNamed: 'query'
					type: 'string'
					description: 'Search text tool names, descriptions, groups.').
				(self
					schemaPropertyNamed: 'group'
					type: 'string'
					description: 'Optional tool group filter.').
				(self
					schemaPropertyNamed: 'cursor'
					type: 'string'
					description: 'Continuation cursor.') };
		required: #( );
		additionalProperties: false;
		yourself
]

{ #category : 'metadata' }
MCPToolSearchTools >> buildOutputSchema [

	^ self
		standardOutputSchemaForDataProperties: {
				self toolsArraySchemaProperty.
				(self
					schemaPropertyNamed: 'nextCursor'
					type: 'string'
					description: 'Cursor for the next page.') }
		required: #( 'tools' )
]

{ #category : 'private - execution' }
MCPToolSearchTools >> commandForRequest: searchRequest [

	^ MCPSearchToolsCommand tool: self request: searchRequest
]

{ #category : 'metadata' }
MCPToolSearchTools >> defaultExposure [

	^ 'static'
]

{ #category : 'metadata' }
MCPToolSearchTools >> description [

	^ 'Search all MCP-Pharo tools. Use to discover tool names before tool_get or tool_call.'
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

{ #category : 'metadata' }
MCPToolSearchTools >> groupName [

	^ 'tool-catalog'
]

{ #category : 'private - request' }
MCPToolSearchTools >> parsedRequestFromToolRequest: request [

	^ MCPSearchToolsRequest fromToolRequest: request
]

{ #category : 'metadata' }
MCPToolSearchTools >> title [

	^ 'Search Tool Catalog'
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
					description: 'Short description.') };
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
