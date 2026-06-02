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

	^ 'Return the full callable contract, schema, and metadata for one MCP-Pharo tool selected from the catalog.'
]

{ #category : 'defaults' }
MCPToolGetTool >> defaultInputSchema [

	| toolNameProperty |
	toolNameProperty := self
		                    schemaPropertyNamed: 'toolName'
		                    type: 'string'
		                    description:
		                    'The MCP tool name whose contract should be returned.'.
	toolNameProperty minLength: 1.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: { toolNameProperty };
		  required: #( 'toolName' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolGetTool >> defaultOutputSchema [

	| examplesProperty requirementsProperty schemaProperty toolProperty |
	schemaProperty := MCPStructureProperties new
		                  type: 'object';
		                  description: 'A JSON Schema object.';
		                  additionalProperties: true;
		                  yourself.
	examplesProperty := (self
		                     schemaPropertyNamed: 'examples'
		                     type: 'array'
		                     description: 'Example calls for this tool.')
		                    items: (MCPStructureProperties new
				                     type: 'object';
				                     additionalProperties: true;
				                     yourself);
		                    yourself.
	requirementsProperty := (self
		                         schemaPropertyNamed:
			                         'activationRequirements'
		                         type: 'array'
		                         description:
			                         'Requirements that must be satisfied before calling the tool.')
		                        items: (MCPStructureProperties new
				                         type: 'string';
				                         yourself);
		                        yourself.
	toolProperty := self
		                schemaPropertyNamed: 'tool'
		                type: 'object'
		                description: 'Full tool metadata and schemas.'.
	toolProperty
		properties: {
				(self
					 schemaPropertyNamed: 'name'
					 type: 'string'
					 description: 'The MCP tool name.').
				(self
					 schemaPropertyNamed: 'title'
					 type: 'string'
					 description: 'Human-readable title.').
				(self
					 schemaPropertyNamed: 'description'
					 type: 'string'
					 description: 'Tool description.').
				(self
					 schemaPropertyNamed: 'group'
					 type: 'string'
					 description: 'Descriptive tool group.').
				(self
					 schemaPropertyNamed: 'exposure'
					 type: 'string'
					 description: 'Whether the tool is static or discoverable.').
				(self
					 schemaPropertyNamed: 'mutability'
					 type: 'string'
					 description: 'Mutability classification.').
				(self
					 schemaPropertyNamed: 'risk'
					 type: 'string'
					 description: 'Risk classification.').
				(self
					 stringArraySchemaNamed: 'keywords'
					 description: 'Search keywords.'
					 itemDescription: 'One keyword.').
				(self
					 booleanSchemaPropertyNamed: 'schemaInspectionRequired'
					 description: 'Whether schema inspection is expected before use.').
				(schemaProperty
					 name: 'inputSchema';
					 yourself).
				(schemaProperty copy
					 name: 'outputSchema';
					 yourself).
				examplesProperty.
				requirementsProperty };
		required:
			#( 'name' 'title' 'description' 'group' 'exposure' 'mutability'
			   'risk' 'keywords' 'schemaInspectionRequired'
			   'inputSchema' 'outputSchema' 'examples' 'activationRequirements' );
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
