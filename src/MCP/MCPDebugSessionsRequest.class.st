Class {
	#name : 'MCPDebugSessionsRequest',
	#superclass : 'MCPDebugRequest',
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
		  yourself
]

{ #category : 'accessing' }
MCPDebugSessionsRequest class >> supportedOperations [

	^ #( 'list' 'describe' 'forget' )
]
