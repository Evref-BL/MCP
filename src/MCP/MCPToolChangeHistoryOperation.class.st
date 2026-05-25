Class {
	#name : 'MCPToolChangeHistoryOperation',
	#superclass : 'MCPToolManageChangeHistory',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolChangeHistoryOperation class >> isAbstract [

	^ self = MCPToolChangeHistoryOperation
]

{ #category : 'defaults' }
MCPToolChangeHistoryOperation >> changeHistoryOperation [

	self subclassResponsibility
]

{ #category : 'defaults' }
MCPToolChangeHistoryOperation >> defaultDescription [

	^ self operationDescription
]

{ #category : 'defaults' }
MCPToolChangeHistoryOperation >> defaultInputSchema [

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
MCPToolChangeHistoryOperation >> operationDescription [

	^ 'Run the fixed change-history operation '
	  , self changeHistoryOperation
	  , ' without requiring an operation field.'
]

{ #category : 'private - request' }
MCPToolChangeHistoryOperation >> parsedRequestFromToolRequest: request [

	^ super parsedRequestFromToolRequest:
		  (self
			   toolRequest: request
			   withOperation: self changeHistoryOperation)
]

{ #category : 'defaults' }
MCPToolChangeHistoryOperation >> requiredInputPropertyNames [

	^ #(  )
]

{ #category : 'private - request' }
MCPToolChangeHistoryOperation >> toolRequest: request withOperation: operationName [

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
MCPToolChangeHistoryOperation >> validateRequest: request [

	self requiredInputPropertyNames do: [ :each |
			(request argumentNamed: each ifAbsent: [ nil ]) ifNil: [
					MCPInvalidToolInput
						signalMissingRequiredArgumentNamed: each
						forTool: self ] ]
]
