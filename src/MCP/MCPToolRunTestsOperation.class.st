Class {
	#name : 'MCPToolRunTestsOperation',
	#superclass : 'MCPToolRunTests',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolRunTestsOperation class >> isAbstract [

	^ self = MCPToolRunTestsOperation
]

{ #category : 'defaults' }
MCPToolRunTestsOperation >> defaultDescription [

	^ self operationDescription
]

{ #category : 'defaults' }
MCPToolRunTestsOperation >> defaultInputSchema [

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
MCPToolRunTestsOperation >> operationDescription [

	^ 'Run the fixed test operation ' , self testOperation
	  , ' without requiring an operation field.'
]

{ #category : 'private - request' }
MCPToolRunTestsOperation >> parsedRequestFromToolRequest: request [

	^ super parsedRequestFromToolRequest:
		  (self toolRequest: request withOperation: self testOperation)
]

{ #category : 'defaults' }
MCPToolRunTestsOperation >> requiredInputPropertyNames [

	^ #( 'tests' )
]

{ #category : 'defaults' }
MCPToolRunTestsOperation >> testOperation [

	self subclassResponsibility
]

{ #category : 'private - request' }
MCPToolRunTestsOperation >> toolRequest: request withOperation: operationName [

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
MCPToolRunTestsOperation >> validateRequest: request [

	self requiredInputPropertyNames do: [ :each |
			(request argumentNamed: each ifAbsent: [ nil ]) ifNil: [
					MCPInvalidToolInput
						signalMissingRequiredArgumentNamed: each
						forTool: self ] ]
]
