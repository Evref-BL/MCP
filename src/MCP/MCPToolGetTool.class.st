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

{ #category : 'private - schema' }
MCPToolGetTool >> annotationsSchemaProperty [

	| property |
	property := self schemaPropertyNamed: 'annotations' type: 'object' description: 'Standard MCP tool behavior hints.'.
	property
		properties: {
				(self schemaPropertyNamed: 'title' type: 'string' description: 'Optional annotation title.').
				(self schemaPropertyNamed: 'readOnlyHint' type: 'boolean' description: 'Whether the tool leaves its environment unchanged.').
				(self
					 schemaPropertyNamed: 'destructiveHint'
					 type: 'boolean'
					 description: 'Whether a modifying tool may perform destructive updates.').
				(self schemaPropertyNamed: 'idempotentHint' type: 'boolean' description: 'Whether repeated calls have no additional effect.').
				(self
					 schemaPropertyNamed: 'openWorldHint'
					 type: 'boolean'
					 description: 'Whether the tool may interact with external entities.') };
		required: #( 'readOnlyHint' );
		additionalProperties: false.
	^ property
]

{ #category : 'metadata' }
MCPToolGetTool >> buildInputSchema [

	| toolNameProperty |
	toolNameProperty := self schemaPropertyNamed: 'toolName' type: 'string' description: 'Tool name.'.
	toolNameProperty minLength: 1.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: { toolNameProperty };
		  required: #( 'toolName' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'metadata' }
MCPToolGetTool >> buildOutputSchema [

	| inputSchemaProperty toolProperty |
	inputSchemaProperty := MCPStructureProperties new
		                       name: 'inputSchema';
		                       type: 'object';
		                       description: 'JSON Schema object.';
		                       additionalProperties: true;
		                       yourself.
	toolProperty := self schemaPropertyNamed: 'tool' type: 'object' description: 'Tool contract.'.
	toolProperty
		properties: {
				(self schemaPropertyNamed: 'name' type: 'string' description: 'Tool name.').
				(self schemaPropertyNamed: 'description' type: 'string' description: 'Tool description.').
				(self schemaPropertyNamed: 'group' type: 'string' description: 'Tool catalog group.').
				(self schemaPropertyNamed: 'exposure' type: 'string' description: 'Effective tool exposure.').
				self annotationsSchemaProperty.
				self keywordsSchemaProperty.
				inputSchemaProperty };
		required: #( 'name' 'description' 'group' 'exposure' 'annotations' 'keywords' 'inputSchema' );
		additionalProperties: false.
	^ self standardOutputSchemaForDataProperties: { toolProperty } required: #( 'tool' )
]

{ #category : 'private - execution' }
MCPToolGetTool >> commandForRequest: getRequest [

	^ MCPGetToolCommand tool: self request: getRequest toolRegistry: self toolRegistry
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

{ #category : 'metadata' }
MCPToolGetTool >> groupName [

	^ 'tool-catalog'
]

{ #category : 'private - schema' }
MCPToolGetTool >> keywordsSchemaProperty [

	^ (self schemaPropertyNamed: 'keywords' type: 'array' description: 'Search terms associated with the tool.')
		  items: (MCPStructureProperties new
				   type: 'string';
				   yourself);
		  yourself
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

	^ toolRegistry ifNil: [ toolRegistry := MCPToolRegistry new ]
]

{ #category : 'accessing' }
MCPToolGetTool >> toolRegistry: aToolRegistry [

	toolRegistry := aToolRegistry
]
