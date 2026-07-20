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

	| activationRequirementsProperty examplesProperty inputSchemaProperty outputSchemaProperty schemaProperty toolProperty |
	schemaProperty := MCPStructureProperties new
		type: 'object';
		description: 'JSON Schema object.';
		additionalProperties: true;
		yourself.
	inputSchemaProperty := schemaProperty copy
		name: 'inputSchema';
		yourself.
	outputSchemaProperty := schemaProperty copy
		name: 'outputSchema';
		yourself.
	examplesProperty := (self
		schemaPropertyNamed: 'examples'
		type: 'array'
		description: 'Example calls.')
		items: (MCPStructureProperties new
			type: 'object';
			additionalProperties: true;
			yourself);
		yourself.
	activationRequirementsProperty := (self
		schemaPropertyNamed: 'activationRequirements'
		type: 'array'
		description: 'Requirements before calling tool.')
		items: (MCPStructureProperties new
			type: 'string';
			yourself);
		yourself.
	toolProperty := self
		schemaPropertyNamed: 'tool'
		type: 'object'
		description: 'Tool contract.'.
	toolProperty
		properties: {
				(self
					schemaPropertyNamed: 'name'
					type: 'string'
					description: 'Tool name.').
				(self
					schemaPropertyNamed: 'description'
					type: 'string'
					description: 'Tool description.').
				inputSchemaProperty.
				outputSchemaProperty.
				examplesProperty.
				activationRequirementsProperty };
		required: #( 'name' 'description' 'inputSchema' );
		additionalProperties: false.
	^ self
		standardOutputSchemaForDataProperties: { toolProperty }
		required: #( 'tool' )
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

{ #category : 'metadata' }
MCPToolGetTool >> mutability [

	^ 'read'
]

{ #category : 'private - request' }
MCPToolGetTool >> parsedRequestFromToolRequest: request [

	^ MCPGetToolRequest fromToolRequest: request
]

{ #category : 'metadata' }
MCPToolGetTool >> risk [

	^ 'low'
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
