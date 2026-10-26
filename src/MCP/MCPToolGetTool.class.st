"
Static bridge tool for reading a tool contract from its owning registry.

Agents use it after tool_search and before tool_call when a discoverable tool requires exact schema details.
"
Class {
	#name : 'MCPToolGetTool',
	#superclass : 'MCPTool',
	#instVars : [
		'toolRegistry'
	],
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolGetTool class >> groupName [

	^ self toolCatalogGroupName
]

{ #category : 'instance creation' }
MCPToolGetTool class >> newForRegistry: aToolRegistry [

	^ self new
		  toolRegistry: aToolRegistry;
		  yourself
]

{ #category : 'metadata' }
MCPToolGetTool class >> toolName [

	^ 'tool_get'
]

{ #category : 'metadata' }
MCPToolGetTool >> annotations [

	^ MCPStructureToolAnnotations readOnly
]

{ #category : 'metadata' }
MCPToolGetTool >> buildInputSchema [

	| nameProperty |
	nameProperty := self schemaPropertyNamed: 'name' type: 'string' description: 'Name of the tool whose contract to return.'.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: { nameProperty };
		  required: #( 'name' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - execution' }
MCPToolGetTool >> commandForRequest: getRequest [

	^ MCPGetToolCommand tool: self request: getRequest toolRegistry: self toolRegistry
]

{ #category : 'private - results' }
MCPToolGetTool >> contentTextForStructuredContent: structuredContent [
	"A contract is read in order to build a call, so it is written as YAML rather than as plain lines: lines cannot say whether a value is a number or the text of one, whether a list holds one item or is a string containing a comma, or where a value with spaces ends."

	| data |
	data := structuredContent at: #data ifAbsent: [ ^ super contentTextForStructuredContent: structuredContent ].
	^ String streamContents: [ :stream |
			  self summaryAndWarningsOn: stream for: structuredContent.
			  stream nextPut: Character lf.
			  stream nextPutAll: (MCPYamlWriter yamlFor: data indent: '') ]
]

{ #category : 'metadata' }
MCPToolGetTool >> defaultExposure [

	^ 'static'
]

{ #category : 'metadata' }
MCPToolGetTool >> description [

	^ 'Return one tool contract with metadata and input schema.'
]

{ #category : 'executing' }
MCPToolGetTool >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :getRequest |
				  | contract data |
				  data := (self commandForRequest: getRequest) execute.
				  contract := data at: #tool.
				  self successResultText: 'Tool ' , (contract at: #name) , ' found.' data: data ]
		  onError: [ :error :parsedRequest | self errorResultFor: error ]
]

{ #category : 'private - request' }
MCPToolGetTool >> parsedRequestFromToolRequest: request [

	^ MCPGetToolRequest fromToolRequest: request
]

{ #category : 'metadata' }
MCPToolGetTool >> title [

	^ 'Get Tool'
]

{ #category : 'accessing' }
MCPToolGetTool >> toolRegistry [

	^ toolRegistry ifNil: [ toolRegistry := MCPToolRegistry default ]
]

{ #category : 'accessing' }
MCPToolGetTool >> toolRegistry: aToolRegistry [

	toolRegistry := aToolRegistry
]
