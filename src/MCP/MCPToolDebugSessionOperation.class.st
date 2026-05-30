Class {
	#name : 'MCPToolDebugSessionOperation',
	#superclass : 'MCPToolDebugSessions',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolDebugSessionOperation class >> isAbstract [

	^ self = MCPToolDebugSessionOperation
]

{ #category : 'private - schema' }
MCPToolDebugSessionOperation >> candidateRefSchemaProperty [

	^ self
		  schemaPropertyNamed: 'candidateRef'
		  type: 'string'
		  description:
		  'Opaque debugger candidate reference returned by debug_candidate_search.'
]

{ #category : 'defaults' }
MCPToolDebugSessionOperation >> defaultDescription [

	^ self sessionOperationSpec at: #description
]

{ #category : 'defaults' }
MCPToolDebugSessionOperation >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: self inputProperties;
		  required: self requiredInputProperties;
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolDebugSessionOperation >> defaultTitle [

	^ self sessionOperationSpec at: #title
]

{ #category : 'private - schema' }
MCPToolDebugSessionOperation >> inputProperties [

	^ self sessionOperationSpec at: #inputProperties ifAbsent: [ #(  ) ]
]

{ #category : 'private - operations' }
MCPToolDebugSessionOperation >> operationName [

	^ self sessionOperationSpec at: #operation
]

{ #category : 'private - request' }
MCPToolDebugSessionOperation >> parsedRequestFromToolRequest: request [

	| arguments focusedRequest |
	arguments := request arguments copy.
	arguments at: #operation put: self operationName.
	focusedRequest := MCPToolRequest new
		                  tool: self;
		                  arguments: arguments;
		                  yourself.
	^ MCPDebugSessionsRequest fromRequest: focusedRequest tool: self
]

{ #category : 'private - schema' }
MCPToolDebugSessionOperation >> requiredInputProperties [

	^ self sessionOperationSpec
		  at: #requiredProperties
		  ifAbsent: [ #(  ) ]
]

{ #category : 'private - schema' }
MCPToolDebugSessionOperation >> sessionIdSchemaProperty [

	^ self
		  schemaPropertyNamed: 'sessionId'
		  type: 'string'
		  description:
		  'Opaque debug session identifier returned by debug_session_list, debug_capture, debug_test_run, or debug_candidate_attach.'
]

{ #category : 'private - operations' }
MCPToolDebugSessionOperation >> sessionOperationSpec [

	self subclassResponsibility
]
