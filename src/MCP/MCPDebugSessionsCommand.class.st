"
Implements debug_session.

With no reference it answers what is open: the debuggers a person has that MCP has not attached, and the sessions it has. With one it attaches that debugger if it is not attached yet and answers its state, so reaching a frame is a single call.
"
Class {
	#name : 'MCPDebugSessionsCommand',
	#superclass : 'MCPDebugCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'private - actions' }
MCPDebugSessionsCommand >> attach: aCandidate [

	| record |
	record := self
		          recordForCandidate: aCandidate
		          ifFound: [ :existing | existing ]
		          ifAbsent: [
			          registry
				          registerDebugSession: aCandidate debugSession
				          named: aCandidate sessionName
				          status: 'paused'
				          reason: 'attachedDebugger' ].
	record debugger: aCandidate debugger.
	record continuation ifNil: [
			record continuation: (MCPDebugAttachedContinuation
					 debugger: aCandidate debugger
					 timeoutMilliseconds: self attachedContinuationTimeoutMilliseconds
					 resultPreviewCharacterLimit: 1000) ].
	^ record
]

{ #category : 'private - actions' }
MCPDebugSessionsCommand >> describeReference: aReference [
	"A reference names a debugger a person has open or a session already attached; either way the
	caller wants the frame, so attaching is not a separate call."

	| record state |
	record := registry sessionRecordAt: aReference ifAbsent: [ self attach: (self candidateForReference: aReference) ].
	state := (MCPDebugStateInfo fromRecord: record request: request) asDictionary.
	^ MCPDebugToolResult
		  okSummary: 'Debug session ' , record sessionId , ' at '
			  , ((state at: #selectedFrame ifAbsent: [ Dictionary new ]) at: #displayString ifAbsent: [ 'an unknown frame' ]) , '.'
		  data: state
		  warnings: (state at: #warnings ifAbsent: [ #(  ) ])
]

{ #category : 'executing' }
MCPDebugSessionsCommand >> execute [

	request candidateRef ifNotNil: [ :reference | ^ self describeReference: reference ].
	^ self listOpen
]

{ #category : 'private - actions' }
MCPDebugSessionsCommand >> listOpen [
	"One listing, because a debugger a person opened and a session MCP attached to it are the same
	thing at different moments."

	| attached unattached |
	attached := (registry sessionRecords collect: [ :each | (MCPDebugSessionInfo fromRecord: each) asDictionary ]) asArray.
	unattached := (self unattachedCandidates collect: [ :each | each asDictionary ]) asArray.
	^ MCPDebugToolResult okSummary: (self tool textForCount: attached size + unattached size noun: 'open debugger') , '.' data: {
			  (#sessions -> attached).
			  (#candidates -> unattached) } asDictionary
]

{ #category : 'private' }
MCPDebugSessionsCommand >> attachedContinuationTimeoutMilliseconds [

	^ 2000
]

{ #category : 'private - candidates' }
MCPDebugSessionsCommand >> candidateForReference: aCandidateRef [

	^ self debuggerCandidates
		  detect: [ :candidate | candidate matchesCandidateRef: aCandidateRef ]
		  ifNone: [ self signalCandidateNotFound: aCandidateRef ]
]

{ #category : 'private - candidates' }
MCPDebugSessionsCommand >> candidateIsAttached: aCandidate [

	^ (registry hasDebugger: aCandidate debugger) or: [ registry hasDebugSession: aCandidate debugSession ]
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

{ #category : 'private - candidates' }
MCPDebugSessionsCommand >> recordForCandidate: aCandidate ifFound: foundBlock ifAbsent: absentBlock [

	^ registry
		  recordForDebugger: aCandidate debugger
		  ifFound: foundBlock
		  ifAbsent: [ registry recordForDebugSession: aCandidate debugSession ifFound: foundBlock ifAbsent: absentBlock ]
]

{ #category : 'private - errors' }
MCPDebugSessionsCommand >> signalCandidateNotFound: aCandidateRef [

	MCPCommandError
		signalErrorCode: #DebugSessionCandidateNotFound
		message: 'Debug session candidate ' , aCandidateRef asString , ' was not found.'
		details: { (#candidateRef -> aCandidateRef) } asDictionary
]

{ #category : 'private - candidates' }
MCPDebugSessionsCommand >> unattachedCandidates [

	^ self debuggerCandidates reject: [ :candidate | self candidateIsAttached: candidate ]
]
