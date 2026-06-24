"
Tool that loads an existing Metacello baseline already available in the image.
"
Class {
	#name : 'MCPToolLoadBaseline',
	#superclass : 'MCPToolLoadMetacello',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolLoadBaseline class >> toolName [

	^ 'baseline_load'
]

{ #category : 'metadata' }
MCPToolLoadBaseline >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   nonEmptyStringSchemaPropertyNamed: 'baseline'
					   description: 'Baseline name without BaselineOf prefix.').
				  self groupsSchemaProperty }
			  , self loadPolicyInputSchemaProperties;
		  required: #( 'baseline' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'metadata' }
MCPToolLoadBaseline >> buildOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties:
		  self loadBaselineDataProperties
		  required:
			  #( 'baseline' 'groups' 'onWarning' 'onConflict' 'policy' 'newPackageNames'
			     'repositories' )
]

{ #category : 'private - execution' }
MCPToolLoadBaseline >> commandForRequest: loadBaselineRequest [

	^ MCPLoadBaselineCommand tool: self request: loadBaselineRequest
]

{ #category : 'metadata' }
MCPToolLoadBaseline >> description [

	^ 'Load an existing Metacello baseline in the image.'
]

{ #category : 'private - request' }
MCPToolLoadBaseline >> parsedRequestFromToolRequest: request [

	^ MCPLoadBaselineRequest fromRequest: request tool: self
]

{ #category : 'metadata' }
MCPToolLoadBaseline >> title [

	^ 'Load Baseline'
]
