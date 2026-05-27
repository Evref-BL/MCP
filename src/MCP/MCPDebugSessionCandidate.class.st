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
MCPDebugSessionCandidate class >> candidateRefForDebugSession: aDebugSession [

	^ 'debugger-candidate-' , aDebugSession identityHash asString
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

	^ self class candidateRefForDebugSession: self debugSession
]

{ #category : 'accessing' }
MCPDebugSessionCandidate >> debugSession [

	^ self valueOrNil: [ debugger session ]
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
	exception := self valueOrNil: [ self debugSession exception ].
	exception ifNil: [ ^ nil ].
	message := (exception respondsTo: #messageText)
		           ifTrue: [ exception messageText ]
		           ifFalse: [ nil ].
	^ {
		  (#className -> exception class name asString).
		  (#message
		   -> (message ifNil: [ '' ] ifNotNil: [ message asString ])).
		  (#printString -> (self limitedPrintStringOf: exception)) }
		  asDictionary
]

{ #category : 'private - stack' }
MCPDebugSessionCandidate >> frameInfoForContext: aContext [

	| receiverClass |
	aContext ifNil: [ ^ nil ].
	receiverClass := self valueOrNil: [
		                 aContext receiver class name asString ].
	^ {
		  (#displayString -> (self limitedPrintStringOf: aContext)).
		  (#method -> (self methodInfoForContext: aContext)).
		  (#pc -> (self valueOrNil: [ aContext pc ])).
		  (#receiverClassName -> receiverClass) } asDictionary
]

{ #category : 'testing' }
MCPDebugSessionCandidate >> isAttachable [

	| session |
	session := self debugSession.
	session ifNil: [ ^ false ].
	^ (self valueOrNil: [ session interruptedContext ]) notNil
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
	method := self valueOrNil: [ aContext method ].
	method ifNil: [ ^ Dictionary new ].
	methodClass := self valueOrNil: [ method methodClass ].
	selector := self valueOrNil: [ method selector ].
	^ {
		  (#className
		   ->
		   (methodClass
			    ifNil: [ nil ]
			    ifNotNil: [ methodClass name asString ])).
		  (#selector
		   -> (selector ifNil: [ nil ] ifNotNil: [ selector asString ])) }
		  asDictionary
]

{ #category : 'private' }
MCPDebugSessionCandidate >> processInfo [

	| process status |
	process := self valueOrNil: [ self debugSession interruptedProcess ].
	process ifNil: [ ^ nil ].
	status := (self valueOrNil: [ process isTerminated ]) = true
		          ifTrue: [ 'terminated' ]
		          ifFalse: [
				          (self valueOrNil: [ process isSuspended ]) = true
					          ifTrue: [ 'suspended' ]
					          ifFalse: [ 'active' ] ].
	^ {
		  (#name -> (self valueOrNil: [ process name ])).
		  (#status -> status).
		  (#priority -> (self valueOrNil: [ process priority ])) }
		  asDictionary
]

{ #category : 'accessing' }
MCPDebugSessionCandidate >> sessionName [

	^ (self valueOrNil: [ self debugSession name ]) ifNil: [ '' ]
]

{ #category : 'private - stack' }
MCPDebugSessionCandidate >> topContext [

	| contexts session |
	session := self debugSession.
	session ifNil: [ ^ nil ].
	contexts := (session respondsTo: #stackOfSize:)
		            ifTrue: [ self valueOrNil: [ session stackOfSize: 1 ] ]
		            ifFalse: [ nil ].
	contexts ifNil: [
			(session respondsTo: #stack) ifTrue: [
				contexts := self valueOrNil: [ session stack ] ] ].
	contexts ifNil: [ ^ nil ].
	contexts isEmpty ifTrue: [ ^ nil ].
	^ contexts asArray first
]

{ #category : 'private' }
MCPDebugSessionCandidate >> valueOrNil: aBlock [

	^ [ aBlock value ]
		  on: Error
		  do: [ :ignored | nil ]
]

{ #category : 'accessing' }
MCPDebugSessionCandidate >> windowTitle [

	^ (self valueOrNil: [ debugger windowTitle ]) ifNil: [ '' ]
]
