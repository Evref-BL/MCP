"
Registry record for one MCP-visible DebugSession.

The record owns the opaque session id, current DebugSession, optional attached debugger or continuation, lifecycle status, reason, state token, and creation time. State tokens make frame and variable references stale after control operations.
"
Class {
	#name : 'MCPDebugSessionRecord',
	#superclass : 'Object',
	#instVars : [
		'sessionId',
		'debugSession',
		'debugger',
		'name',
		'status',
		'reason',
		'stateId',
		'createdAt',
		'continuation'
	],
	#category : 'MCP-Debugging',
	#package : 'MCP',
	#tag : 'Debugging'
}

{ #category : 'instance creation' }
MCPDebugSessionRecord class >> sessionId: aSessionId debugSession: aDebugSession name: aName status: statusString reason: reasonString stateId: aStateId createdAt: aDateAndTime [

	^ self new
		  sessionId: aSessionId;
		  debugSession: aDebugSession;
		  name: aName;
		  status: statusString;
		  reason: reasonString;
		  stateId: aStateId;
		  createdAt: aDateAndTime;
		  yourself
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> advanceStateForStatus: statusString reason: reasonString [

	| nextNumber suffix |
	suffix := stateId
		          ifNil: [ '0' ]
		          ifNotNil: [ stateId copyAfterLast: $- ].
	nextNumber := (suffix notEmpty and: [
		               suffix allSatisfy: [ :character | character isDigit ] ])
		              ifTrue: [ suffix asInteger + 1 ]
		              ifFalse: [ 1 ].
	stateId := 'state-' , nextNumber asString.
	status := statusString.
	reason := reasonString
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> capabilities [

	^ {
		  (#stateInspection -> true).
		  (#variableExpansion -> true).
		  (#evaluation -> true).
		  (#control -> true).
		  (#breakpoints -> true).
		  (#capture -> true).
		  (#attachedDebugger -> debugger notNil) } asDictionary
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> continuation [

	^ continuation
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> continuation: aContinuation [

	continuation := aContinuation
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> createdAt [

	^ createdAt
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> createdAt: aDateAndTime [

	createdAt := aDateAndTime
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> debugSession [

	^ debugSession
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> debugSession: anObject [

	debugSession := anObject
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> debugger [

	^ debugger
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> debugger: aDebugger [

	debugger := aDebugger
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> name [

	^ name
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> name: aString [

	name := aString
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> reason [

	^ reason
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> reason: aString [

	reason := aString
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> sessionId [

	^ sessionId
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> sessionId: aString [

	sessionId := aString
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> stateId [

	^ stateId
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> stateId: aString [

	stateId := aString
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> status [

	^ status
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> status: aString [

	status := aString
]
