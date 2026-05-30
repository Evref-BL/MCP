"
MCPDebugAttachedDebuggerController controls a visible debugger presenter. It schedules UI-sensitive actions through the presenter so Spec and Morphic keep ownership of window and UI-process state.
"
Class {
	#name : 'MCPDebugAttachedDebuggerController',
	#superclass : 'MCPDebugController',
	#instVars : [
		'debugger',
		'debugSession',
		'failureBlock'
	],
	#category : 'MCP-Debugging',
	#package : 'MCP',
	#tag : 'Debugging'
}

{ #category : 'instance creation' }
MCPDebugAttachedDebuggerController class >> debugger: aDebugger debugSession: aDebugSession onFailure: aBlock [

	^ self new
		  debugger: aDebugger;
		  debugSession: aDebugSession;
		  failureBlock: aBlock;
		  yourself
]

{ #category : 'accessing' }
MCPDebugAttachedDebuggerController >> debugSession [

	^ debugSession
]

{ #category : 'accessing' }
MCPDebugAttachedDebuggerController >> debugSession: aDebugSession [

	debugSession := aDebugSession
]

{ #category : 'accessing' }
MCPDebugAttachedDebuggerController >> debugger [

	^ debugger
]

{ #category : 'accessing' }
MCPDebugAttachedDebuggerController >> debugger: aDebugger [

	debugger := aDebugger
]

{ #category : 'controlling' }
MCPDebugAttachedDebuggerController >> deferAction: aBlock [

	| deferredAction |
	deferredAction := [
		                  [ aBlock value ]
			                  on: Exception
			                  do: [ :error | failureBlock value: error ] ].
	^ debugger defer: deferredAction
]

{ #category : 'accessing' }
MCPDebugAttachedDebuggerController >> failureBlock [

	^ failureBlock
]

{ #category : 'accessing' }
MCPDebugAttachedDebuggerController >> failureBlock: aBlock [

	failureBlock := aBlock
]

{ #category : 'controlling' }
MCPDebugAttachedDebuggerController >> performOperation: selector context: aContext [

	^ self deferAction: [
		  self performVisibleDebuggerOperation: selector context: aContext ]
]

{ #category : 'controlling' }
MCPDebugAttachedDebuggerController >> performVisibleDebuggerOperation: selector context: aContext [

	selector = #resume ifTrue: [ ^ debugger proceedDebugSession ].
	selector = #terminate ifTrue: [ ^ debugger close ].
	selector = #restart: ifTrue: [
		^ debugger debuggerActionModel restartContext: aContext ].
	^ debugger debuggerActionModel perform: selector with: aContext
]
