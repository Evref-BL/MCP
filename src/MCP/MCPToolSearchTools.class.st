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
		  properties: { (self
				   schemaPropertyNamed: 'query'
				   type: 'string'
				   description:
					   'Space-separated search words matched against tool names, titles, descriptions, groups, and keywords. Tools are ranked by how many words they match, so the closest tools are answered even when none matches every word.') };
		  required: #(  );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - results' }
MCPToolSearchTools >> catalogTextForSummary: aSummary tools: toolMetadataEntries [
	"Separate entries with a line feed: a carriage return reaches the caller as an escaped character rather than a line break."

	^ String streamContents: [ :stream |
			  stream nextPutAll: aSummary.
			  toolMetadataEntries do: [ :each |
					  stream
						  nextPut: Character lf;
						  nextPutAll: (each at: #name);
						  nextPutAll: ' - ';
						  nextPutAll: (each at: #description) ] ]
]

{ #category : 'private - execution' }
MCPToolSearchTools >> commandForRequest: searchRequest [

	^ MCPSearchToolsCommand tool: self request: searchRequest toolRegistry: self toolRegistry
]

{ #category : 'private - results' }
MCPToolSearchTools >> contentTextForStructuredContent: structuredContent [
	"A catalog listing reads as prose and costs a third fewer characters than its JSON. Error results keep the default shape."

	^ structuredContent
		  at: #data
		  ifPresent: [ :data |
				  self
					  catalogTextForSummary: (structuredContent at: #summary ifAbsent: [ '' ])
					  tools: (data at: #tools) ]
		  ifAbsent: [ super contentTextForStructuredContent: structuredContent ]
]

{ #category : 'metadata' }
MCPToolSearchTools >> defaultExposure [

	^ 'static'
]

{ #category : 'metadata' }
MCPToolSearchTools >> description [

	^ 'Search available tools, best match first. Use to discover tool names before tool_get or tool_call.'
]

{ #category : 'executing' }
MCPToolSearchTools >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :searchRequest |
				  | command data |
				  command := self commandForRequest: searchRequest.
				  data := command execute.
				  self successResultText: command summaryText data: data ]
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

{ #category : 'accessing' }
MCPToolSearchTools >> toolRegistry [

	^ toolRegistry ifNil: [ toolRegistry := MCPToolRegistry default ]
]

{ #category : 'accessing' }
MCPToolSearchTools >> toolRegistry: aToolRegistry [

	toolRegistry := aToolRegistry
]

