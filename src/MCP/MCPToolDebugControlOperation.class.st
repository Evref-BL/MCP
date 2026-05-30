Class {
	#name : 'MCPToolDebugControlOperation',
	#superclass : 'MCPToolDebugControl',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolDebugControlOperation class >> isAbstract [

	^ self = MCPToolDebugControlOperation
]

{ #category : 'private - operations' }
MCPToolDebugControlOperation >> controlOperationSpec [

	self subclassResponsibility
]

{ #category : 'defaults' }
MCPToolDebugControlOperation >> defaultDescription [

	^ self controlOperationSpec at: #description
]

{ #category : 'defaults' }
MCPToolDebugControlOperation >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: self inputProperties;
		  required: #( 'sessionId' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolDebugControlOperation >> defaultTitle [

	^ self controlOperationSpec at: #title
]

{ #category : 'private - schema' }
MCPToolDebugControlOperation >> frameRefSchemaProperty [

	^ self
		  schemaPropertyNamed: 'frameRef'
		  type: 'string'
		  description:
		  'Optional state-scoped frame reference. Defaults to the selected top frame.'
]

{ #category : 'private - schema' }
MCPToolDebugControlOperation >> inputProperties [

	| properties |
	properties := OrderedCollection with: self sessionIdSchemaProperty.
	properties add: self stateIdSchemaProperty.
	self usesFrameReference ifTrue: [
		properties add: self frameRefSchemaProperty ].
	self usesStateSnapshotOptions ifTrue: [
		properties addAll: self stateSnapshotInputProperties ].
	^ properties asArray
]

{ #category : 'private - operations' }
MCPToolDebugControlOperation >> operationName [

	^ self controlOperationSpec at: #operation
]

{ #category : 'private - request' }
MCPToolDebugControlOperation >> parsedRequestFromToolRequest: request [

	| arguments focusedRequest |
	arguments := request arguments copy.
	arguments at: #operation put: self operationName.
	focusedRequest := MCPToolRequest new
		                  tool: self;
		                  arguments: arguments;
		                  yourself.
	^ MCPDebugControlRequest fromRequest: focusedRequest tool: self
]

{ #category : 'private - schema' }
MCPToolDebugControlOperation >> sessionIdSchemaProperty [

	^ self
		  schemaPropertyNamed: 'sessionId'
		  type: 'string'
		  description:
		  'Opaque debug session identifier returned by debug_session_list, debug_capture, debug_test_run, or debug_candidate_attach.'
]

{ #category : 'private - schema' }
MCPToolDebugControlOperation >> stateIdSchemaProperty [

	^ self
		  schemaPropertyNamed: 'stateId'
		  type: 'string'
		  description:
		  'Optional state token to reject stale debug control requests.'
]

{ #category : 'private - schema' }
MCPToolDebugControlOperation >> stateSnapshotInputProperties [

	^ {
		  (self
			   booleanSchemaPropertyNamed: 'returnState'
			   description:
			   'Whether paused operations should include a post-action debug_state_get snapshot.'
			   default: true).
		  (self
			   integerSchemaPropertyNamed: 'sourceContextLines'
			   description:
			   'Number of source context lines requested in returned state.'
			   default: 5).
		  (self
			   integerSchemaPropertyNamed: 'stackStart'
			   description: 'Zero-based stack frame offset for returned state.'
			   default: 0).
		  (self
			   integerSchemaPropertyNamed: 'stackLimit'
			   description: 'Maximum number of stack frames in returned state.'
			   default: 20).
		  (self
			   integerSchemaPropertyNamed: 'variableDepth'
			   description: 'Inline variable preview depth in returned state.'
			   default: 1).
		  (self
			   integerSchemaPropertyNamed: 'variableLimit'
			   description:
			   'Maximum number of variables to preview in returned state.'
			   default: 50).
		  (self
			   booleanSchemaPropertyNamed: 'includeReceiver'
			   description:
			   'Whether returned state should include the receiver scope.'
			   default: true) }
]

{ #category : 'private - operations' }
MCPToolDebugControlOperation >> usesFrameReference [

	^ self controlOperationSpec
		  at: #usesFrameReference
		  ifAbsent: [ false ]
]

{ #category : 'private - operations' }
MCPToolDebugControlOperation >> usesStateSnapshotOptions [

	^ self controlOperationSpec
		  at: #usesStateSnapshotOptions
		  ifAbsent: [ true ]
]
