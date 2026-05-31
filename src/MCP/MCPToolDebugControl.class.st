"
Shared implementation for focused debugger-control tools. It dispatches resume, terminate, restart, and stepping actions, returning updated state when control pauses again.
"
Class {
	#name : 'MCPToolDebugControl',
	#superclass : 'MCPToolDebug',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolDebugControl class >> isAbstract [

	^ self = MCPToolDebugControl
]

{ #category : 'private - execution' }
MCPToolDebugControl >> commandForRequest: debugRequest [

	^ MCPDebugControlCommand tool: self request: debugRequest
]

{ #category : 'private' }
MCPToolDebugControl >> controlFailureMessageFor: anError operation: operationName [

	| message |
	message := anError messageText
		           ifNil: [ anError asString ]
		           ifNotNil: [ :text | text asString ].
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

{ #category : 'defaults' }
MCPToolDebugControl >> defaultOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties: {
				  (self
					   schemaPropertyNamed: 'sessionId'
					   type: 'string'
					   description: 'Debug session identifier.').
				  (self
					   schemaPropertyNamed: 'action'
					   type: 'string'
					   description: 'Control action that was applied.').
				  (self
					   schemaPropertyNamed: 'previousStateId'
					   type: 'string'
					   description: 'Debug state token before control was applied.').
				  (self
					   schemaPropertyNamed: 'stateId'
					   type: 'string'
					   description: 'Debug state token after control was applied.').
				  (self
					   schemaPropertyNamed: 'status'
					   type: 'string'
					   description: 'Debug session status after control.').
				  (self
					   schemaPropertyNamed: 'reason'
					   type: 'string'
					   description: 'Reason associated with the current status.').
				  (self
					   schemaPropertyNamed: 'frameRef'
					   type: 'string'
					   description:
					   'State-scoped frame reference returned after a frame-targeted control request.').
				  (self
					   schemaPropertyNamed: 'state'
					   type: 'object'
					   description:
					   'debug_state_get snapshot returned when control pauses and returnState=true.').
				  (self
					   stringArraySchemaNamed: 'warnings'
					   description: 'Control-specific warnings.'
					   itemDescription: 'A warning message.').
				  (self
					   schemaPropertyNamed: 'capabilities'
					   type: 'object'
					   description:
					   'Control capability gates used for this response.') }
		  required:
			  #( 'sessionId' 'action' 'previousStateId' 'stateId' 'status'
			     'reason' 'warnings' 'capabilities' )
]
