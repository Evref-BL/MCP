"
Implements debug session registry operations.
"
Class {
	#name : 'MCPDebugSessionsCommand',
	#superclass : 'MCPDebugCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'private' }
MCPDebugSessionsCommand >> attachCandidate [

	| alreadyAttached candidate record state |
	candidate := self candidateForReference: request candidateRef.
	alreadyAttached := false.
	record := self
		          recordForCandidate: candidate
		          ifFound: [ :existing |
				          alreadyAttached := true.
				          existing ]
		          ifAbsent: [
				          registry
					          registerDebugSession: candidate debugSession
					          named: candidate sessionName
					          status: 'paused'
					          reason: 'attachedDebugger' ].
	record debugger: candidate debugger.
	record continuation ifNil: [
			record continuation: (MCPDebugAttachedContinuation
					 debugger: candidate debugger
					 timeoutMilliseconds:
					 self attachedContinuationTimeoutMilliseconds
					 resultPreviewCharacterLimit: 1000) ].
	state := (MCPDebugStateInfo fromRecord: record request: request)
		         asDictionary.
	^ MCPDebugToolResult
		  okSummary:
		  'Attached debug session candidate ' , candidate candidateRef , '.'
		  data: {
				  (#candidateRef -> candidate candidateRef).
				  (#attached -> true).
				  (#alreadyAttached -> alreadyAttached).
				  (#session
				   -> (MCPDebugSessionInfo fromRecord: record) asDictionary).
				  (#sessionId -> record sessionId).
				  (#state -> state) } asDictionary
]

{ #category : 'private' }
MCPDebugSessionsCommand >> attachedContinuationTimeoutMilliseconds [

	^ 2000
]

{ #category : 'private - candidates' }
MCPDebugSessionsCommand >> candidateForReference: aCandidateRef [

	aCandidateRef ifNil: [ ^ self signalMissingCandidateRef ].
	^ self debuggerCandidates
		  detect: [ :candidate |
		  candidate matchesCandidateRef: aCandidateRef ]
		  ifNone: [ self signalCandidateNotFound: aCandidateRef ]
]

{ #category : 'private - candidates' }
MCPDebugSessionsCommand >> candidateIsAttached: aCandidate [

	^ (registry hasDebugger: aCandidate debugger) or: [
		  registry hasDebugSession: aCandidate debugSession ]
]

{ #category : 'private - candidates' }
MCPDebugSessionsCommand >> debuggerCandidates [

	| candidates reversed |
	candidates := OrderedCollection new.
	StDebugger allInstancesDo: [ :debugger |
			| candidate |
			candidate := MCPDebugSessionCandidate fromDebugger: debugger.
			candidate isAttachable ifTrue: [ candidates add: candidate ] ].
	reversed := OrderedCollection new.
	candidates reverseDo: [ :each | reversed add: each ].
	^ reversed asArray
]

{ #category : 'executing' }
MCPDebugSessionsCommand >> execute [

	request operation = 'list' ifTrue: [ ^ self listSessions ].
	request operation = 'get' ifTrue: [ ^ self getSession ].
	request operation = 'remove' ifTrue: [ ^ self removeSession ].
	request operation = 'search' ifTrue: [ ^ self searchCandidates ].
	request operation = 'attach' ifTrue: [ ^ self attachCandidate ].
	^ self signalUnsupportedOperation: request operation
]

{ #category : 'private' }
MCPDebugSessionsCommand >> getSession [

	| record |
	record := self sessionRecord.
	^ MCPDebugToolResult
		  okSummary: 'Debug session ' , record sessionId , ' found.'
		  data:
			  { (#session
			   -> (MCPDebugSessionInfo fromRecord: record) asDictionary) }
				  asDictionary
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

{ #category : 'private - candidates' }
MCPDebugSessionsCommand >> recordForCandidate: aCandidate ifFound: foundBlock ifAbsent: absentBlock [

	^ registry
		  recordForDebugger: aCandidate debugger
		  ifFound: foundBlock
		  ifAbsent: [
				  registry
					  recordForDebugSession: aCandidate debugSession
					  ifFound: foundBlock
					  ifAbsent: absentBlock ]
]

{ #category : 'private' }
MCPDebugSessionsCommand >> removeSession [

	| record terminated |
	record := self sessionRecord.
	terminated := self terminateCapturedSessionForRecord: record.
	registry removeSessionId: record sessionId.
	^ MCPDebugToolResult
		  okSummary: 'Removed debug session ' , record sessionId , '.'
		  data: {
				  (#sessionId -> record sessionId).
				  (#removed -> true).
				  (#terminated -> terminated) } asDictionary
]

{ #category : 'private' }
MCPDebugSessionsCommand >> searchCandidates [

	| candidates |
	candidates := self unattachedCandidates.
	^ MCPDebugToolResult
		  okSummary:
		  candidates size asString , ' debug session candidates found.'
		  data: {
				  (#candidates
				   -> (candidates collect: [ :each | each asDictionary ])).
				  (#totalCount -> candidates size) } asDictionary
]

{ #category : 'private - errors' }
MCPDebugSessionsCommand >> signalCandidateNotFound: aCandidateRef [

	MCPCommandError
		signalErrorCode: #DebugSessionCandidateNotFound
		message: 'Debug session candidate ' , aCandidateRef asString
			, ' was not found.'
		details: { (#candidateRef -> aCandidateRef) } asDictionary
]

{ #category : 'private - errors' }
MCPDebugSessionsCommand >> signalMissingCandidateRef [

	MCPCommandError
		signalErrorCode: #DebugSessionCandidateRefMissing
		message: tool name , ' requires candidateRef.'
		details: { (#operation -> request operation) } asDictionary
]

{ #category : 'private' }
MCPDebugSessionsCommand >> terminateCapturedSessionForRecord: aRecord [

	| session |
	aRecord continuation ifNotNil: [ :continuation |
		^ continuation terminateWorker ].
	aRecord reason = 'capturedException' ifFalse: [ ^ false ].
	session := aRecord debugSession.
	session ifNil: [ ^ false ].
	[ session terminate ]
		on: Error
		do: [ :ignored | ^ false ].
	^ true
]

{ #category : 'private - candidates' }
MCPDebugSessionsCommand >> unattachedCandidates [

	^ self debuggerCandidates reject: [ :candidate |
		  self candidateIsAttached: candidate ]
]
