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
MCPDebugSessionRegistry >> forgetSessionId: aSessionId [

	^ sessions removeKey: aSessionId ifAbsent: [ nil ]
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
MCPDebugSessionRegistry >> sessionRecordAt: aSessionId ifAbsent: absentBlock [

	^ sessions at: aSessionId ifAbsent: absentBlock
]

{ #category : 'accessing' }
MCPDebugSessionRegistry >> sessionRecords [

	^ (sessions values asSortedCollection: [ :left :right |
		   left sessionId <= right sessionId ]) asArray
]

{ #category : 'accessing' }
MCPDebugSessionRegistry >> size [

	^ sessions size
]
