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

	| continuations previous process |
	process := aContinuation workerProcess.
	process ifNil: [ ^ aBlock value ].
	continuations := self activeContinuations.
	previous := OupsDebuggerSelectionStrategy debuggerSelectionStrategy.
	previous = self ifFalse: [ self previousStrategy: previous ].
	continuations at: process put: aContinuation.
	OupsDebuggerSelectionStrategy debuggerSelectionStrategy: self.
	^ aBlock ensure: [
			  continuations removeKey: process ifAbsent: [ nil ].
			  continuations isEmpty
				  ifTrue: [
						  | restore |
						  restore := PreviousStrategy ifNil: [ previous ].
						  restore = self ifTrue: [
								  restore := OupsDebuggerSelectionStrategy
									             defaultDebuggerSelectionStrategy ].
						  OupsDebuggerSelectionStrategy debuggerSelectionStrategy:
							  restore.
						  PreviousStrategy := nil ]
				  ifFalse: [
				  OupsDebuggerSelectionStrategy debuggerSelectionStrategy: self ] ]
]

{ #category : 'accessing' }
MCPDebugAttachedDebuggerSelectionStrategy class >> activeContinuations [

	ActiveContinuations ifNil: [
		ActiveContinuations := IdentityDictionary new ].
	^ ActiveContinuations
]

{ #category : 'accessing' }
MCPDebugAttachedDebuggerSelectionStrategy class >> continuationForProcess: aProcess ifPresent: presentBlock ifAbsent: absentBlock [

	| continuations |
	continuations := self activeContinuations.
	^ continuations at: aProcess ifPresent: presentBlock ifAbsent: [
			  continuations size = 1
				  ifTrue: [ presentBlock value: continuations values anyOne ]
				  ifFalse: [ absentBlock value ] ]
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

{ #category : 'controlling' }
MCPDebugAttachedDebuggerSelectionStrategy class >> reset [

	| fallback |
	fallback := PreviousStrategy ifNil: [
		            OupsDebuggerSelectionStrategy
			            defaultDebuggerSelectionStrategy ].
	fallback = self ifTrue: [
			fallback := OupsDebuggerSelectionStrategy
				            defaultDebuggerSelectionStrategy ].
	ActiveContinuations := IdentityDictionary new.
	PreviousStrategy := nil.
	OupsDebuggerSelectionStrategy debuggerSelectionStrategy = self
		ifTrue: [
		OupsDebuggerSelectionStrategy debuggerSelectionStrategy: fallback ].
	^ self
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
