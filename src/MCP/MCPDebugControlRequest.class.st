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

{ #category : 'defaults' }
MCPDebugControlRequest class >> defaultReturnState [

	^ false
]

{ #category : 'instance creation' }
MCPDebugControlRequest class >> fromRequest: aRequest tool: aTool operation: operationName [

	(self supportedOperations includes: operationName) ifFalse: [
			MCPCommandError
				signalErrorCode: #DebugControlOperationUnsupported
				message:
				'Unsupported debug operation: ' , operationName asString , '.'
				details: {
						(#operation -> operationName).
						(#supportedOperations -> self supportedOperations) }
						asDictionary ].
	^ self new
		  operation: operationName;
		  sessionId: (aRequest stringArgumentNamed: 'sessionId');
		  stateId: (aRequest stringArgumentNamed: 'stateId');
		  frameRef: (aRequest stringArgumentNamed: 'frameRef');
		  returnState: (aRequest
				   booleanArgumentNamed: 'returnState'
				   default: self defaultReturnState);
		  sourceContextLines: (aRequest
				   nonNegativeIntegerArgumentNamed: 'sourceContextLines'
				   default: self defaultSourceContextLines
				   maximum: self maximumSourceContextLines);
		  stackStart: (aRequest
				   nonNegativeIntegerArgumentNamed: 'stackStart'
				   default: self defaultStackStart);
		  stackLimit: (aRequest
				   nonNegativeIntegerArgumentNamed: 'stackLimit'
				   default: self defaultStackLimit
				   maximum: self maximumStackLimit);
		  variableDepth: (aRequest
				   nonNegativeIntegerArgumentNamed: 'variableDepth'
				   default: self defaultVariableDepth
				   maximum: self maximumVariableDepth);
		  variableLimit: (aRequest
				   nonNegativeIntegerArgumentNamed: 'variableLimit'
				   default: self defaultVariableLimit
				   maximum: self maximumVariableLimit);
		  includeReceiver: (aRequest
				   booleanArgumentNamed: 'includeReceiver'
				   default: self defaultIncludeReceiver);
		  yourself
]

{ #category : 'accessing' }
MCPDebugControlRequest class >> supportedOperations [

	^ #( 'stepInto' 'stepOver' 'stepThrough' 'restart' 'resume' 'terminate' )
]

{ #category : 'accessing' }
MCPDebugControlRequest >> returnState [

	^ returnState ifNil: [ self class defaultReturnState ]
]

{ #category : 'accessing' }
MCPDebugControlRequest >> returnState: aBoolean [

	returnState := aBoolean
]
