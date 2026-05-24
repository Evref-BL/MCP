Class {
	#name : 'MCPDebugSessionsCommand',
	#superclass : 'MCPDebugCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'private' }
MCPDebugSessionsCommand >> describeSession [

	| record |
	record := self sessionRecord.
	^ MCPDebugToolResult
		  okSummary: 'Debug session ' , record sessionId , ' found.'
		  data:
			  { (#session
			   -> (MCPDebugSessionInfo fromRecord: record) asDictionary) }
				  asDictionary
]

{ #category : 'executing' }
MCPDebugSessionsCommand >> execute [

	request operation = 'list' ifTrue: [ ^ self listSessions ].
	request operation = 'describe' ifTrue: [ ^ self describeSession ].
	request operation = 'forget' ifTrue: [ ^ self forgetSession ].
	^ self signalUnsupportedOperation: request operation
]

{ #category : 'private' }
MCPDebugSessionsCommand >> forgetSession [

	| record terminated |
	record := self sessionRecord.
	terminated := self terminateCapturedSessionForRecord: record.
	registry forgetSessionId: record sessionId.
	^ MCPDebugToolResult
		  okSummary: 'Forgot debug session ' , record sessionId , '.'
		  data: {
				  (#sessionId -> record sessionId).
				  (#forgotten -> true).
				  (#terminated -> terminated) } asDictionary
]

{ #category : 'private' }
MCPDebugSessionsCommand >> listSessions [

	| sessions |
	sessions := registry sessionRecords collect: [ :each |
		            (MCPDebugSessionInfo fromRecord: each) asDictionary ].
	^ MCPDebugToolResult
		  okSummary: sessions size asString , ' debug sessions found.'
		  data: {
				  (#sessions -> sessions).
				  (#totalCount -> sessions size) } asDictionary
]

{ #category : 'private' }
MCPDebugSessionsCommand >> terminateCapturedSessionForRecord: aRecord [

	(aRecord reason = 'capturedException' and: [
		 aRecord debugSession notNil ]) ifFalse: [ ^ false ].
	[ aRecord debugSession terminate ]
		on: Error
		do: [ :ignored | ^ false ].
	^ true
]
