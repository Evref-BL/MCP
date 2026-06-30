"
Static bridge tool for reading a catalog tool's full contract.

Agents use it after tool_search and before tool_call when a discoverable tool requires exact schema details.
"
Class {
	#name : 'MCPToolGetTool',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolGetTool class >> toolName [

	^ 'tool_get'
]

{ #category : 'metadata' }
MCPToolGetTool >> buildInputSchema [

	| includeOutputSchemaProperty toolNameProperty |
	toolNameProperty := self
		                    schemaPropertyNamed: 'toolName'
		                    type: 'string'
		                    description: 'Tool name.'.
	toolNameProperty minLength: 1.
	includeOutputSchemaProperty := self
		                               booleanSchemaPropertyNamed:
		                               'includeOutputSchema'
		                               description:
		                               'Include response schema; use only for response validation.'
		                               default: false.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  toolNameProperty.
				  includeOutputSchemaProperty };
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

	^ MCPGetToolCommand tool: self request: getRequest
]

{ #category : 'metadata' }
MCPToolGetTool >> description [

	^ 'Return one tool contract with metadata and input schema. Set includeOutputSchema only when response validation needs it.'
]

{ #category : 'executing' }
MCPToolGetTool >> executeWithRequest: request [

	^ self
		  executeWithRequest: request
		  usingPolicy: MCPToolExposurePolicy default
]

{ #category : 'executing' }
MCPToolGetTool >> executeWithRequest: request usingPolicy: aToolExposurePolicy [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :getRequest |
				  | contract data |
				  data := (MCPGetToolCommand
					           tool: self
					           request: getRequest
					           toolExposurePolicy: aToolExposurePolicy) execute.
				  contract := data at: #tool.
				  self
					  successResultText: 'Tool ' , (contract at: #name) , ' found.'
					  data: data ]
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
