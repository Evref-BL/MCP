"
Request object for debug session registry operations.
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
MCPDebugSessionsRequest class >> fromRequest: aRequest tool: aTool operation: operationName [

	(self supportedOperations includes: operationName) ifFalse: [
			MCPCommandError
				signalErrorCode: #DebugSessionsOperationUnsupported
				message: 'Unsupported debug sessions operation: ' , operationName asString , '.'
				details: {
						(#operation -> operationName).
						(#supportedOperations -> self supportedOperations) } asDictionary ].
	^ self new
		  operation: operationName;
		  sessionId: (aRequest stringArgumentNamed: 'sessionId');
		  candidateRef: (aRequest stringArgumentNamed: 'candidateRef');
		  yourself
]

{ #category : 'accessing' }
MCPDebugSessionsRequest class >> supportedOperations [

	^ #( 'list' 'get' 'remove' 'search' 'attach' )
]

{ #category : 'accessing' }
MCPDebugSessionsRequest >> candidateRef [

	^ candidateRef
]

{ #category : 'accessing' }
MCPDebugSessionsRequest >> candidateRef: aString [

	candidateRef := aString
]
