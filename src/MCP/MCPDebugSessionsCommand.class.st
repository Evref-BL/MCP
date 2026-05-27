"
Implements debug-sessions operations.

It lists and describes registered sessions, discovers unattached debugger candidates, attaches an external debugger to the MCP registry, and forgets sessions with the right ownership cleanup semantics.
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
	record := registry
		          recordForDebugSession: candidate debugSession
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
					 timeoutMilliseconds: 250
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

{ #category : 'private - candidates' }
MCPDebugSessionsCommand >> candidateForReference: aCandidateRef [

	aCandidateRef ifNil: [ ^ self signalMissingCandidateRef ].
	^ self debuggerCandidates
		  detect: [ :candidate |
		  candidate matchesCandidateRef: aCandidateRef ]
		  ifNone: [ self signalCandidateNotFound: aCandidateRef ]
]

{ #category : 'private - candidates' }
MCPDebugSessionsCommand >> debuggerCandidates [

	| candidates debuggerClass reversed |
	debuggerClass := Smalltalk globals
		                 at: #StDebugger
		                 ifAbsent: [ ^ #(  ) ].
	candidates := OrderedCollection new.
	debuggerClass allInstancesDo: [ :debugger |
			| candidate |
			candidate := MCPDebugSessionCandidate fromDebugger: debugger.
			candidate isAttachable ifTrue: [ candidates add: candidate ] ].
	reversed := OrderedCollection new.
	candidates reverseDo: [ :each | reversed add: each ].
	^ reversed asArray
]

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

{ #category : 'private' }
MCPDebugSessionsCommand >> discoverCandidates [

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

{ #category : 'executing' }
MCPDebugSessionsCommand >> execute [

	request operation = 'list' ifTrue: [ ^ self listSessions ].
	request operation = 'describe' ifTrue: [ ^ self describeSession ].
	request operation = 'forget' ifTrue: [ ^ self forgetSession ].
	request operation = 'discover' ifTrue: [ ^ self discoverCandidates ].
	request operation = 'attach' ifTrue: [ ^ self attachCandidate ].
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
		message: 'debug-sessions attach requires candidateRef.'
		details: { (#operation -> request operation) } asDictionary
]

{ #category : 'private' }
MCPDebugSessionsCommand >> terminateCapturedSessionForRecord: aRecord [

	aRecord continuation ifNotNil: [ :continuation |
		^ continuation terminateWorker ].
	(aRecord reason = 'capturedException' and: [
		 aRecord debugSession notNil ]) ifFalse: [ ^ false ].
	[ aRecord debugSession terminate ]
		on: Error
		do: [ :ignored | ^ false ].
	^ true
]

{ #category : 'private - candidates' }
MCPDebugSessionsCommand >> unattachedCandidates [

	^ self debuggerCandidates reject: [ :candidate |
		  registry hasDebugSession: candidate debugSession ]
]
