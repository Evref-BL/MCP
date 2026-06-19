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

{ #category : 'defaults' }
MCPToolGetTool class >> toolName [

	^ 'tool_get'
]

{ #category : 'private - execution' }
MCPToolGetTool >> commandForRequest: getRequest [

	^ MCPGetToolCommand tool: self request: getRequest
]

{ #category : 'defaults' }
MCPToolGetTool >> defaultDescription [

	^ 'Return one tool contract with metadata and input schema. Set includeOutputSchema only when response validation needs it.'
]

{ #category : 'defaults' }
MCPToolGetTool >> defaultInputSchema [

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

{ #category : 'defaults' }
MCPToolGetTool >> defaultOutputSchema [

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
		                                   schemaPropertyNamed:
			                                   'activationRequirements'
		                                   type: 'array'
		                                   description:
			                                   'Requirements before calling tool.')
		                                  items:
			                                  (MCPStructureProperties new
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
					 schemaPropertyNamed: 'title'
					 type: 'string'
					 description: 'Tool title.').
				(self
					 schemaPropertyNamed: 'description'
					 type: 'string'
					 description: 'Tool description.').
				(self
					 schemaPropertyNamed: 'group'
					 type: 'string'
					 description: 'Tool group.').
				(self
					 schemaPropertyNamed: 'exposure'
					 type: 'string'
					 description: 'Tool exposure.').
				(self
					 schemaPropertyNamed: 'mutability'
					 type: 'string'
					 description: 'Tool mutability.').
				(self
					 schemaPropertyNamed: 'risk'
					 type: 'string'
					 description: 'Tool risk.').
				(self
					 booleanSchemaPropertyNamed: 'schemaInspectionRequired'
					 description: 'Inspect schema before calling.').
				inputSchemaProperty.
				outputSchemaProperty.
				examplesProperty.
				activationRequirementsProperty };
		required:
			#( 'name' 'title' 'description' 'group' 'exposure' 'mutability'
			   'risk' 'schemaInspectionRequired' 'inputSchema' );
		additionalProperties: false.
	^ self
		  standardOutputSchemaForDataProperties: { toolProperty }
		  required: #( 'tool' )
]

{ #category : 'defaults' }
MCPToolGetTool >> defaultTitle [

	^ 'Get Tool'
]

{ #category : 'executing' }
MCPToolGetTool >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :getRequest |
				  | contract data |
				  data := (self commandForRequest: getRequest) execute.
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
