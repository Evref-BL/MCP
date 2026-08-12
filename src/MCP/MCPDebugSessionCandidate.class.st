"
Description of an open StDebugger that can be attached to MCP.

Candidates are discovered from live debugger instances, rendered with stable identifying details, and converted to DebugSession records only when a caller explicitly attaches them.
"
Class {
	#name : 'MCPDebugSessionCandidate',
	#superclass : 'Object',
	#instVars : [
		'debugger'
	],
	#category : 'MCP-Debugging',
	#package : 'MCP',
	#tag : 'Debugging'
}

{ #category : 'accessing' }
MCPDebugSessionCandidate class >> candidateRefForDebugger: aDebugger [

	^ 'debugger-candidate-' , aDebugger identityHash asString
]

{ #category : 'instance creation' }
MCPDebugSessionCandidate class >> fromDebugger: aDebugger [

	^ self new
		  debugger: aDebugger;
		  yourself
]

{ #category : 'converting' }
MCPDebugSessionCandidate >> asDictionary [

	| context session |
	session := self debugSession.
	context := self topContext.
	^ {
		  (#candidateRef -> self candidateRef).
		  (#debuggerClassName -> debugger class name asString).
		  (#sessionClassName -> session class name asString).
		  (#sessionName -> self sessionName).
		  (#windowTitle -> self windowTitle).
		  (#exception -> self exceptionInfo).
		  (#topFrame -> (self frameInfoForContext: context)).
		  (#process -> self processInfo) } asDictionary
]

{ #category : 'accessing' }
MCPDebugSessionCandidate >> candidateRef [

	^ self class candidateRefForDebugger: debugger
]

{ #category : 'accessing' }
MCPDebugSessionCandidate >> debugSession [

	^ debugger session
]

{ #category : 'accessing' }
MCPDebugSessionCandidate >> debugger [

	^ debugger
]

{ #category : 'accessing' }
MCPDebugSessionCandidate >> debugger: aDebugger [

	debugger := aDebugger.
	^ self
]

{ #category : 'private' }
MCPDebugSessionCandidate >> exceptionInfo [

	| exception message |
	exception := self debugSession exception.
	exception ifNil: [ ^ nil ].
	message := exception messageText.
	^ {
		  (#className -> exception class name asString).
		  (#message -> (message ifNil: [ '' ] ifNotNil: [ message asString ])).
		  (#printString -> (self limitedPrintStringOf: exception)) } asDictionary
]

{ #category : 'private - stack' }
MCPDebugSessionCandidate >> frameInfoForContext: aContext [

	aContext ifNil: [ ^ nil ].
	^ {
		  (#displayString -> (self limitedPrintStringOf: aContext)).
		  (#method -> (self methodInfoForContext: aContext)).
		  (#pc -> aContext pc).
		  (#receiverClassName -> aContext receiver class name asString) } asDictionary
]

{ #category : 'testing' }
MCPDebugSessionCandidate >> isAttachable [

	^ self debugSession interruptedContext notNil
]

{ #category : 'private' }
MCPDebugSessionCandidate >> limitedPrintStringOf: anObject [

	anObject ifNil: [ ^ 'nil' ].
	^ [ anObject printStringLimitedTo: 500 ]
		  on: Error
		  do: [ :ignored | anObject class name asString ]
]

{ #category : 'testing' }
MCPDebugSessionCandidate >> matchesCandidateRef: aString [

	^ self candidateRef = aString
]

{ #category : 'private - stack' }
MCPDebugSessionCandidate >> methodInfoForContext: aContext [

	| method methodClass selector |
	method := aContext method.
	method ifNil: [ ^ Dictionary new ].
	methodClass := method methodClass.
	selector := method selector.
	^ {
		  (#className -> methodClass name asString).
		  (#selector -> selector asString) } asDictionary
]

{ #category : 'private' }
MCPDebugSessionCandidate >> processInfo [

	| process status |
	process := self debugSession process.
	process ifNil: [ ^ nil ].
	status := process isTerminated
		          ifTrue: [ 'terminated' ]
		          ifFalse: [
				          process isSuspended
					          ifTrue: [ 'suspended' ]
					          ifFalse: [ 'active' ] ].
	^ {
		  (#name -> process name).
		  (#status -> status).
		  (#priority -> process priority) } asDictionary
]

{ #category : 'accessing' }
MCPDebugSessionCandidate >> sessionName [

	^ self debugSession name ifNil: [ '' ]
]

{ #category : 'private - stack' }
MCPDebugSessionCandidate >> topContext [

	^ self debugSession interruptedContext
]

{ #category : 'accessing' }
MCPDebugSessionCandidate >> windowTitle [

	^ self sessionName
]
