Class {
	#name : 'MCPToolRepositoryOperation',
	#superclass : 'MCPToolEditRepository',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolRepositoryOperation class >> isAbstract [

	^ self = MCPToolRepositoryOperation
]

{ #category : 'defaults' }
MCPToolRepositoryOperation >> defaultDescription [

	^ self operationDescription
]

{ #category : 'defaults' }
MCPToolRepositoryOperation >> defaultInputSchema [

	| schema |
	schema := super defaultInputSchema.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties:
			  (schema properties reject: [ :each | each name = 'operation' ]);
		  required: self requiredInputPropertyNames;
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolRepositoryOperation >> operationDescription [

	^ 'Run the fixed repository operation ' , self repositoryOperation
	  , ' without requiring an operation field.'
]

{ #category : 'private - request' }
MCPToolRepositoryOperation >> parsedRequestFromToolRequest: request [

	^ super parsedRequestFromToolRequest:
		  (self toolRequest: request withOperation: self repositoryOperation)
]

{ #category : 'defaults' }
MCPToolRepositoryOperation >> repositoryOperation [

	self subclassResponsibility
]

{ #category : 'defaults' }
MCPToolRepositoryOperation >> requiredInputPropertyNames [

	^ #( 'repositoryName' )
]

{ #category : 'private - request' }
MCPToolRepositoryOperation >> toolRequest: request withOperation: operationName [

	| normalized |
	normalized := request arguments
		              ifNil: [ Dictionary new ]
		              ifNotNil: [ request arguments copy ].
	normalized at: #operation put: operationName.
	^ MCPToolRequest new
		  tool: self;
		  arguments: normalized;
		  yourself
]

{ #category : 'validating' }
MCPToolRepositoryOperation >> validateRequest: request [

	self requiredInputPropertyNames do: [ :each |
			(request argumentNamed: each ifAbsent: [ nil ]) ifNil: [
					MCPInvalidToolInput
						signalMissingRequiredArgumentNamed: each
						forTool: self ] ]
]
