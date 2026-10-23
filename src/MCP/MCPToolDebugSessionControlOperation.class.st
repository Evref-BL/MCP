"
Shared implementation for debugger-control operation tools.

It defines per-tool control inputs and dispatches resume, terminate, restart, and stepping actions, returning updated state when control pauses again.
"
Class {
	#name : 'MCPToolDebugSessionControlOperation',
	#superclass : 'MCPToolDebug',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolDebugSessionControlOperation class >> isAbstract [

	^ self = MCPToolDebugSessionControlOperation
]

{ #category : 'private - actions' }
MCPToolDebugSessionControlOperation >> actionName [

	^ self controlToolSpec at: #action
]

{ #category : 'metadata' }
MCPToolDebugSessionControlOperation >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: self inputProperties;
		  required: #( 'sessionId' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - execution' }
MCPToolDebugSessionControlOperation >> commandForRequest: debugRequest [

	^ MCPDebugControlCommand tool: self request: debugRequest
]

{ #category : 'private' }
MCPToolDebugSessionControlOperation >> controlFailureMessageFor: anError operation: operationName [

	| message |
	message := anError messageText ifNil: [ anError asString ] ifNotNil: [ :text | text asString ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Debug control ';
				  nextPutAll: operationName asString;
				  nextPutAll: ' failed (';
				  nextPutAll: anError class name;
				  nextPutAll: '): ';
				  nextPutAll: message.
			  anError signalerContext ifNotNil: [ :context |
					  stream
						  nextPutAll: ' Signaler context: ';
						  nextPutAll: context printString ] ]
]

{ #category : 'private - specs' }
MCPToolDebugSessionControlOperation >> controlToolSpec [

	self subclassResponsibility
]

{ #category : 'metadata' }
MCPToolDebugSessionControlOperation >> description [

	^ self controlToolSpec at: #description
]

{ #category : 'private - schema' }
MCPToolDebugSessionControlOperation >> frameRefSchemaProperty [

	^ self
		  schemaPropertyNamed: 'frameRef'
		  type: 'string'
		  description: 'Optional state-scoped frame reference. Defaults to the selected top frame.'
]

{ #category : 'private - schema' }
MCPToolDebugSessionControlOperation >> inputProperties [

	| properties |
	properties := OrderedCollection with: self sessionIdSchemaProperty.
	properties add: self stateIdSchemaProperty.
	self usesFrameReference ifTrue: [ properties add: self frameRefSchemaProperty ].
	self usesStateSnapshotOptions ifTrue: [ properties addAll: self stateSnapshotInputProperties ].
	^ properties asArray
]

{ #category : 'private - request' }
MCPToolDebugSessionControlOperation >> parsedRequestFromToolRequest: request [

	^ MCPDebugControlRequest fromRequest: request tool: self operation: self actionName
]

{ #category : 'private - schema' }
MCPToolDebugSessionControlOperation >> stateIdSchemaProperty [

	^ self schemaPropertyNamed: 'stateId' type: 'string' description: 'Optional state token to reject stale debug control requests.'
]

{ #category : 'private - schema' }
MCPToolDebugSessionControlOperation >> stateSnapshotInputProperties [

	^ {
		  (self
			   booleanSchemaPropertyNamed: 'returnState'
			   description: 'Return a debug_state_get snapshot when control stops.'
			   default: MCPDebugControlRequest defaultReturnState).
		  (self
			   sourceContextLinesSchemaPropertyWithDescription: 'Source lines around selected frame.'
			   default: MCPDebugRequest defaultSourceContextLines).
		  (self stackStartSchemaPropertyWithDescription: 'Zero-based stack offset.' default: MCPDebugRequest defaultStackStart).
		  (self stackLimitSchemaPropertyWithDescription: 'Maximum stack frames.' default: MCPDebugRequest defaultStackLimit).
		  (self variableDepthSchemaPropertyWithDescription: 'Inline preview depth.' default: MCPDebugRequest defaultVariableDepth).
		  (self variableLimitSchemaPropertyWithDescription: 'Maximum variables per scope.' default: MCPDebugRequest defaultVariableLimit).
		  (self
			   booleanSchemaPropertyNamed: 'includeReceiver'
			   description: 'Include receiver scope.'
			   default: MCPDebugRequest defaultIncludeReceiver) }
]

{ #category : 'metadata' }
MCPToolDebugSessionControlOperation >> title [

	^ self controlToolSpec at: #title
]

{ #category : 'private - specs' }
MCPToolDebugSessionControlOperation >> usesFrameReference [

	^ self controlToolSpec at: #usesFrameReference ifAbsent: [ false ]
]

{ #category : 'private - specs' }
MCPToolDebugSessionControlOperation >> usesStateSnapshotOptions [

	^ self controlToolSpec at: #usesStateSnapshotOptions ifAbsent: [ true ]
]
