"
Debugger selection strategy used only while MCP resumes an externally attached debugger. It captures debug sessions for registered processes and retargets the attached debugger instead of opening another debugger window.
"
Class {
	#name : 'MCPDebugAttachedDebuggerSelectionStrategy',
	#superclass : 'OupsDebuggerSelectionStrategy',
	#classVars : [
		'ActiveContinuations',
		'PreviousStrategy'
	],
	#category : 'MCP-Debugging',
	#package : 'MCP',
	#tag : 'Debugging'
}

{ #category : 'controlling' }
MCPDebugAttachedDebuggerSelectionStrategy class >> activate: aContinuation during: aBlock [

	| previous process |
	process := aContinuation workerProcess.
	process ifNil: [ ^ aBlock value ].
	previous := OupsDebuggerSelectionStrategy debuggerSelectionStrategy.
	previous = self ifFalse: [ self previousStrategy: previous ].
	self activeContinuations at: process put: aContinuation.
	OupsDebuggerSelectionStrategy debuggerSelectionStrategy: self.
	^ aBlock ensure: [
			  self activeContinuations removeKey: process ifAbsent: [ nil ].
			  OupsDebuggerSelectionStrategy debuggerSelectionStrategy: previous.
			  PreviousStrategy := nil ]
]

{ #category : 'accessing' }
MCPDebugAttachedDebuggerSelectionStrategy class >> activeContinuations [

	^ ActiveContinuations ifNil: [ ActiveContinuations := Dictionary new ]
]

{ #category : 'accessing' }
MCPDebugAttachedDebuggerSelectionStrategy class >> continuationForProcess: aProcess ifPresent: presentBlock ifAbsent: absentBlock [

	^ self activeContinuations
		  at: aProcess
		  ifPresent: presentBlock
		  ifAbsent: absentBlock
]

{ #category : 'accessing' }
MCPDebugAttachedDebuggerSelectionStrategy class >> previousStrategy [

	^ PreviousStrategy ifNil: [
		  OupsDebuggerSelectionStrategy defaultDebuggerSelectionStrategy ]
]

{ #category : 'accessing' }
MCPDebugAttachedDebuggerSelectionStrategy class >> previousStrategy: aStrategyClass [

	PreviousStrategy := aStrategyClass
]

{ #category : 'debuggers' }
MCPDebugAttachedDebuggerSelectionStrategy >> openDebuggerForSession: aDebugSession [

	^ self class
		  continuationForProcess: aDebugSession interruptedProcess
		  ifPresent: [ :continuation |
		  continuation captureDebugSession: aDebugSession ]
		  ifAbsent: [ self openFallbackDebuggerForSession: aDebugSession ]
]

{ #category : 'debuggers' }
MCPDebugAttachedDebuggerSelectionStrategy >> openFallbackDebuggerForSession: aDebugSession [

	| fallbackClass |
	fallbackClass := self class previousStrategy.
	fallbackClass = self class ifTrue: [
			fallbackClass := OupsDebuggerSelectionStrategy
				                 defaultDebuggerSelectionStrategy ].
	^ (fallbackClass with: self debuggers) openDebuggerForSession:
		  aDebugSession
]
