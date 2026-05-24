Class {
	#name : 'MCPDebugSessionRecord',
	#superclass : 'Object',
	#instVars : [
		'sessionId',
		'debugSession',
		'name',
		'status',
		'reason',
		'stateId',
		'createdAt'
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
	nextNumber := [ suffix asInteger + 1 ]
		              on: Error
		              do: [ :error | 1 ].
	stateId := 'state-' , nextNumber asString.
	status := statusString.
	reason := reasonString.
	^ self
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> capabilities [

	^ {
		  (#stateInspection -> true).
		  (#variableExpansion -> true).
		  (#evaluation -> true).
		  (#control -> true).
		  (#breakpoints -> true).
		  (#capture -> true) } asDictionary
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> createdAt [

	^ createdAt
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> createdAt: aDateAndTime [

	createdAt := aDateAndTime.
	^ self
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> debugSession [

	^ debugSession
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> debugSession: anObject [

	debugSession := anObject.
	^ self
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> name [

	^ name
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> name: aString [

	name := aString.
	^ self
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> reason [

	^ reason
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> reason: aString [

	reason := aString.
	^ self
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> sessionId [

	^ sessionId
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> sessionId: aString [

	sessionId := aString.
	^ self
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> stateId [

	^ stateId
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> stateId: aString [

	stateId := aString.
	^ self
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> status [

	^ status
]

{ #category : 'accessing' }
MCPDebugSessionRecord >> status: aString [

	status := aString.
	^ self
]
