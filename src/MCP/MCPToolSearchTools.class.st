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

	^ 'Search the MCP-Pharo tool catalog by group, keyword, title, or description and return compact metadata for matching tools.'
]

{ #category : 'defaults' }
MCPToolSearchTools >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   schemaPropertyNamed: 'query'
					   type: 'string'
					   description:
						   'Optional search text matched against tool names, titles, descriptions, groups, and keywords.').
				  (self
					   schemaPropertyNamed: 'group'
					   type: 'string'
					   description:
						   'Optional tool group filter such as tool-catalog, repositories, packages, classes, methods, history, tests, ui, debugging, or image-runtime.').
				  (self
					   booleanSchemaPropertyNamed: 'includeStatic'
					   description:
						   'Whether to include the statically advertised tool surface in search results.'
					   default: false).
				  (self
					   integerSchemaPropertyNamed: 'limit'
					   description:
						   'Maximum number of tool metadata entries to return.'
					   default: 100) };
		  required: #(  );
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolSearchTools >> defaultOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties: {
				  self toolsArraySchemaProperty.
				  (self
					   integerSchemaPropertyNamed: 'totalCount'
					   description: 'Number of returned tool metadata entries.').
				  (self
					   schemaPropertyNamed: 'query'
					   type: 'string'
					   description: 'The normalized query, or an empty string.').
				  (self
					   schemaPropertyNamed: 'group'
					   type: 'string'
					   description:
					   'The normalized group filter, or an empty string.').
				  (self
					   booleanSchemaPropertyNamed: 'includeStatic'
					   description: 'Whether static tools were included.') }
		  required:
		  #( 'tools' 'totalCount' 'query' 'group' 'includeStatic' )
]

{ #category : 'defaults' }
MCPToolSearchTools >> defaultTitle [

	^ 'Search Tool Catalog'
]

{ #category : 'executing' }
MCPToolSearchTools >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :searchRequest |
				  | data |
				  data := (self commandForRequest: searchRequest) execute.
				  data at: #query put: (searchRequest query ifNil: [ '' ]).
				  data at: #group put: (searchRequest group ifNil: [ '' ]).
				  self
					  successResultText:
					  (data at: #totalCount) asString , ' tools found.'
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
					   description: 'The MCP tool name.').
				  (self
					   schemaPropertyNamed: 'title'
					   type: 'string'
					   description: 'Human-readable tool title.').
				  (self
					   schemaPropertyNamed: 'description'
					   type: 'string'
					   description: 'Short tool description.').
				  (self
					   schemaPropertyNamed: 'group'
					   type: 'string'
					   description: 'Descriptive tool group identifier.').
				  (self
					   schemaPropertyNamed: 'exposure'
					   type: 'string'
					   description: 'Whether the tool is static or discoverable.').
				  (self
					   schemaPropertyNamed: 'mutability'
					   type: 'string'
					   description:
						   'Whether the tool reads, writes, or executes code.').
				  (self
					   schemaPropertyNamed: 'risk'
					   type: 'string'
					   description: 'Low, medium, or high operational risk.').
				  (self
					   stringArraySchemaNamed: 'keywords'
					   description: 'Search keywords for the tool.'
					   itemDescription: 'One search keyword.').
				  (self
					   booleanSchemaPropertyNamed: 'schemaInspectionRequired'
					   description:
						   'Whether callers should inspect the schema before calling the tool.') };
		  required:
			  #( 'name' 'title' 'description' 'group' 'exposure' 'mutability'
			     'risk' 'keywords' 'schemaInspectionRequired' );
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
