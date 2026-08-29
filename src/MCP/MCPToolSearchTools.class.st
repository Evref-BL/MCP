"
Static bridge tool for searching its owning registry's discoverable tool catalog.

It is intentionally kept on the fast path so agents can find optional or specialized tools without requiring those tools to be statically advertised.
"
Class {
	#name : 'MCPToolSearchTools',
	#superclass : 'MCPTool',
	#instVars : [
		'toolRegistry'
	],
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolSearchTools class >> groupName [

	^ self toolCatalogGroupName
]

{ #category : 'instance creation' }
MCPToolSearchTools class >> newForRegistry: aToolRegistry [

	^ self new
		  toolRegistry: aToolRegistry;
		  yourself
]

{ #category : 'metadata' }
MCPToolSearchTools class >> toolName [

	^ 'tool_search'
]

{ #category : 'metadata' }
MCPToolSearchTools >> annotations [

	^ MCPStructureToolAnnotations readOnly
]

{ #category : 'metadata' }
MCPToolSearchTools >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   schemaPropertyNamed: 'query'
					   type: 'string'
					   description:
						   'Space-separated search words matched against tool names, descriptions, groups, and keywords. Returns tools matching any word.').
				  (self schemaPropertyNamed: 'cursor' type: 'string' description: 'Continuation cursor.') };
		  required: #(  );
		  additionalProperties: false;
		  yourself
]

{ #category : 'metadata' }
MCPToolSearchTools >> buildOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties: {
				  self toolsArraySchemaProperty.
				  (self schemaPropertyNamed: 'nextCursor' type: 'string' description: 'Cursor for the next page.') }
		  required: #( 'tools' )
]

{ #category : 'private - execution' }
MCPToolSearchTools >> commandForRequest: searchRequest [

	^ MCPSearchToolsCommand tool: self request: searchRequest toolRegistry: self toolRegistry
]

{ #category : 'metadata' }
MCPToolSearchTools >> defaultExposure [

	^ 'static'
]

{ #category : 'metadata' }
MCPToolSearchTools >> description [

	^ 'Search available tools. Use to discover tool names before tool_get or tool_call.'
]

{ #category : 'executing' }
MCPToolSearchTools >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :searchRequest |
				  | data |
				  data := (self commandForRequest: searchRequest) execute.
				  self successResultText: (data at: #tools) size asString , ' tools found.' data: data ]
		  onError: [ :error :parsedRequest | self errorResultFor: error ]
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
		  description: 'Compact metadata for one tool.';
		  properties: {
				  (self schemaPropertyNamed: 'name' type: 'string' description: 'Tool name.').
				  (self schemaPropertyNamed: 'description' type: 'string' description: 'Short description.') };
		  required: #( 'name' 'description' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'accessing' }
MCPToolSearchTools >> toolRegistry [

	^ toolRegistry ifNil: [ toolRegistry := MCPToolRegistry new ]
]

{ #category : 'accessing' }
MCPToolSearchTools >> toolRegistry: aToolRegistry [

	toolRegistry := aToolRegistry
]

{ #category : 'private - schema' }
MCPToolSearchTools >> toolsArraySchemaProperty [

	^ (self schemaPropertyNamed: 'tools' type: 'array' description: 'Matching tool metadata entries.')
		  items: self toolMetadataObjectSchema;
		  yourself
]
