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

{ #category : 'defaults' }
MCPToolLoadBaseline class >> toolName [

	^ 'baseline_load'
]

{ #category : 'private - execution' }
MCPToolLoadBaseline >> commandForRequest: loadBaselineRequest [

	^ MCPLoadBaselineCommand tool: self request: loadBaselineRequest
]

{ #category : 'defaults' }
MCPToolLoadBaseline >> defaultDescription [

	^ 'Load an existing Metacello baseline already available in the image. Omit groups to call Metacello>>load. Supports Metacello warning, conflict, upgrade, downgrade, and lock policies. onWarning defaults to log, onConflict defaults to useLoaded, and upgrade/downgrade/lock default to pass.'
]

{ #category : 'defaults' }
MCPToolLoadBaseline >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   nonEmptyStringSchemaPropertyNamed: 'baseline'
					   description:
						   'Metacello baseline name without the BaselineOf prefix, for example SmallDoc.').
				  self groupsSchemaProperty }
			  , self loadPolicyInputSchemaProperties;
		  required: #( 'baseline' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolLoadBaseline >> defaultOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties:
		  self loadBaselineDataProperties
		  required:
			  #( 'baseline' 'groups' 'onWarning' 'onConflict' 'policy' 'newPackageNames'
			     'repositories' )
]

{ #category : 'defaults' }
MCPToolLoadBaseline >> defaultTitle [

	^ 'Load Baseline'
]

{ #category : 'private - request' }
MCPToolLoadBaseline >> parsedRequestFromToolRequest: request [

	^ MCPLoadBaselineRequest fromRequest: request tool: self
]
