"
Request object for debugger control operations.

It extends the shared debugger request with the returnState flag that controls whether paused control results include a fresh debug_state_get snapshot.
"
Class {
	#name : 'MCPDebugControlRequest',
	#superclass : 'MCPDebugRequest',
	#instVars : [
		'returnState'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPDebugControlRequest class >> fromRequest: aRequest tool: aTool operation: operationName [

	(self supportedOperations includes: operationName) ifFalse: [
			MCPCommandError
				signalErrorCode: #DebugControlOperationUnsupported
				message:
				'Unsupported debug control operation: ' , operationName asString
				, '.'
				details: {
						(#operation -> operationName).
						(#supportedOperations -> self supportedOperations) }
						asDictionary ].
	^ self new
		  operation: operationName;
		  sessionId: (aRequest stringArgumentNamed: 'sessionId');
		  stateId: (aRequest stringArgumentNamed: 'stateId');
		  frameRef: (aRequest stringArgumentNamed: 'frameRef');
		  returnState:
			  (aRequest booleanArgumentNamed: 'returnState' default: true);
		  sourceContextLines: (aRequest
				   nonNegativeIntegerArgumentNamed: 'sourceContextLines'
				   default: 5);
		  stackStart:
			  (aRequest
				   nonNegativeIntegerArgumentNamed: 'stackStart'
				   default: 0);
		  stackLimit:
			  (aRequest
				   nonNegativeIntegerArgumentNamed: 'stackLimit'
				   default: 20);
		  variableDepth:
			  (aRequest
				   nonNegativeIntegerArgumentNamed: 'variableDepth'
				   default: 1);
		  variableLimit:
			  (aRequest
				   nonNegativeIntegerArgumentNamed: 'variableLimit'
				   default: 50);
		  includeReceiver:
			  (aRequest booleanArgumentNamed: 'includeReceiver' default: true);
		  yourself
]

{ #category : 'accessing' }
MCPDebugControlRequest class >> supportedOperations [

	^ #( 'stepInto' 'stepOver' 'stepThrough' 'restart' 'resume' 'terminate' )
]

{ #category : 'accessing' }
MCPDebugControlRequest >> returnState [

	^ returnState ifNil: [ true ]
]

{ #category : 'accessing' }
MCPDebugControlRequest >> returnState: aBoolean [

	returnState := aBoolean
]
