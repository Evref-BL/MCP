"
Abstract base for focused method editing tools. It defines per-tool method inputs while reusing MCPToolEditMethod request parsing and command dispatch internally.
"
Class {
	#name : 'MCPToolMethodOperation',
	#superclass : 'MCPToolEditMethod',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolMethodOperation class >> isAbstract [

	^ self = MCPToolMethodOperation
]

{ #category : 'defaults' }
MCPToolMethodOperation >> defaultDescription [

	^ self methodOperationSpec at: #description
]

{ #category : 'defaults' }
MCPToolMethodOperation >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: self inputProperties;
		  required: self requiredInputProperties;
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolMethodOperation >> defaultTitle [

	^ self methodOperationSpec at: #title
]

{ #category : 'private - schema' }
MCPToolMethodOperation >> inputProperties [

	^ self methodOperationSpec at: #inputProperties
]

{ #category : 'private - operations' }
MCPToolMethodOperation >> methodOperationSpec [

	self subclassResponsibility
]

{ #category : 'private - errors' }
MCPToolMethodOperation >> operationForErrorFromParsedRequest: editRequest rawRequest: rawRequest [

	editRequest ifNotNil: [ ^ editRequest operation ].
	^ self operationName
]

{ #category : 'private - operations' }
MCPToolMethodOperation >> operationName [

	^ self methodOperationSpec at: #operation
]

{ #category : 'private - operations' }
MCPToolMethodOperation >> operationSpecifications [

	^ { { (#name -> self operationName) } asDictionary }
]

{ #category : 'private - request' }
MCPToolMethodOperation >> parsedRequestFromToolRequest: request [

	| arguments focusedRequest |
	arguments := request arguments copy.
	arguments at: #operation put: self operationName.
	focusedRequest := MCPToolRequest new
		                  tool: self;
		                  arguments: arguments;
		                  yourself.
	^ super parsedRequestFromToolRequest: focusedRequest
]

{ #category : 'private - schema' }
MCPToolMethodOperation >> requiredInputProperties [

	^ self methodOperationSpec
		  at: #requiredProperties
		  ifAbsent: [ #( 'className' ) ]
]

{ #category : 'validating' }
MCPToolMethodOperation >> validateRequest: request [

	self requiredInputProperties do: [ :each |
			(request argumentNamed: each ifAbsent: [ nil ]) ifNil: [
					MCPInvalidToolInput
						signalMissingRequiredArgumentNamed: each
						forTool: self ] ]
]
