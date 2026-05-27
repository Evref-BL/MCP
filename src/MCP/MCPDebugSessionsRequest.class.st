"
Request object for debug-sessions operations.

It extends the shared debugger request with the optional candidate reference used when attaching a discovered human-opened debugger.
"
Class {
	#name : 'MCPDebugSessionsRequest',
	#superclass : 'MCPDebugRequest',
	#instVars : [
		'candidateRef'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPDebugSessionsRequest class >> fromRequest: aRequest tool: aTool [

	| operationName |
	operationName := aRequest
		                 stringArgumentNamed: 'operation'
		                 default: 'list'.
	(self supportedOperations includes: operationName) ifFalse: [
			MCPCommandError
				signalErrorCode: #DebugSessionsOperationUnsupported
				message:
					'Unsupported debug sessions operation: ' , operationName asString
					, '.'
				details: {
						(#operation -> operationName).
						(#supportedOperations -> self supportedOperations) }
						asDictionary ].
	^ self new
		  operation: operationName;
		  sessionId: (aRequest stringArgumentNamed: 'sessionId');
		  candidateRef: (aRequest stringArgumentNamed: 'candidateRef');
		  yourself
]

{ #category : 'accessing' }
MCPDebugSessionsRequest class >> supportedOperations [

	^ #( 'list' 'describe' 'forget' 'discover' 'attach' )
]

{ #category : 'accessing' }
MCPDebugSessionsRequest >> candidateRef [

	^ candidateRef
]

{ #category : 'accessing' }
MCPDebugSessionsRequest >> candidateRef: aString [

	candidateRef := aString
]
