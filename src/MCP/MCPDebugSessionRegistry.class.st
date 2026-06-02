"
In-image registry of DebugSession records exposed through MCP.

The registry assigns opaque session ids, tracks current records, deduplicates attached DebugSessions, and supports removing tracked sessions when callers are done.
"
Class {
	#name : 'MCPDebugSessionRegistry',
	#superclass : 'Object',
	#instVars : [
		'sessions',
		'nextSessionNumber'
	],
	#classVars : [
		'Default'
	],
	#category : 'MCP-Debugging',
	#package : 'MCP',
	#tag : 'Debugging'
}

{ #category : 'accessing' }
MCPDebugSessionRegistry class >> default [

	Default ifNil: [ Default := self new ].
	^ Default
]

{ #category : 'accessing' }
MCPDebugSessionRegistry class >> resetDefault [

	Default := nil.
	^ self
]

{ #category : 'accessing' }
MCPDebugSessionRegistry >> hasDebugSession: aDebugSession [

	aDebugSession ifNil: [ ^ false ].
	^ sessions values anySatisfy: [ :record |
		  record debugSession == aDebugSession ]
]

{ #category : 'accessing' }
MCPDebugSessionRegistry >> hasDebugger: aDebugger [

	^ self
		  recordForDebugger: aDebugger
		  ifFound: [ :record | true ]
		  ifAbsent: [ false ]
]

{ #category : 'initialization' }
MCPDebugSessionRegistry >> initialize [

	super initialize.
	sessions := Dictionary new.
	nextSessionNumber := 0
]

{ #category : 'private' }
MCPDebugSessionRegistry >> nextSessionId [

	nextSessionNumber := nextSessionNumber + 1.
	^ 'debug-session-' , nextSessionNumber asString
]

{ #category : 'accessing' }
MCPDebugSessionRegistry >> recordForDebugSession: aDebugSession ifFound: foundBlock ifAbsent: absentBlock [

	sessions valuesDo: [ :record |
			record debugSession == aDebugSession ifTrue: [
				^ foundBlock value: record ] ].
	^ absentBlock value
]

{ #category : 'accessing' }
MCPDebugSessionRegistry >> recordForDebugger: aDebugger ifFound: foundBlock ifAbsent: absentBlock [

	aDebugger ifNil: [ ^ absentBlock value ].
	sessions valuesDo: [ :record |
		record debugger == aDebugger ifTrue: [ ^ foundBlock value: record ] ].
	^ absentBlock value
]

{ #category : 'registering' }
MCPDebugSessionRegistry >> registerDebugSession: aDebugSession named: aName [

	^ self
		  registerDebugSession: aDebugSession
		  named: aName
		  status: 'paused'
		  reason: 'unknown'
]

{ #category : 'registering' }
MCPDebugSessionRegistry >> registerDebugSession: aDebugSession named: aName status: statusString reason: reasonString [

	| record |
	record := MCPDebugSessionRecord
		          sessionId: self nextSessionId
		          debugSession: aDebugSession
		          name: aName
		          status: statusString
		          reason: reasonString
		          stateId: 'state-0'
		          createdAt: DateAndTime now.
	sessions at: record sessionId put: record.
	^ record
]

{ #category : 'accessing' }
MCPDebugSessionRegistry >> removeSessionId: aSessionId [

	^ sessions removeKey: aSessionId ifAbsent: [ nil ]
]

{ #category : 'accessing' }
MCPDebugSessionRegistry >> sessionRecordAt: aSessionId ifAbsent: absentBlock [

	^ sessions at: aSessionId ifAbsent: absentBlock
]

{ #category : 'accessing' }
MCPDebugSessionRegistry >> sessionRecords [

	^ sessions values asArray sort: [ :left :right |
		  left sessionId <= right sessionId ]
]

{ #category : 'accessing' }
MCPDebugSessionRegistry >> size [

	^ sessions size
]
