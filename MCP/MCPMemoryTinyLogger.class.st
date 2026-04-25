"
TinyLogger leaf used by MCP monitoring to retain recent log lines in memory for the dashboard.
"
Class {
	#name : 'MCPMemoryTinyLogger',
	#superclass : 'TinyLeafLogger',
	#instVars : [
		'entries',
		'maxEntries'
	],
	#category : 'MCP-Monitoring',
	#package : 'MCP',
	#tag : 'Monitoring'
}

{ #category : 'accessing' }
MCPMemoryTinyLogger class >> kind [

	^ 'mcpMemory'
]

{ #category : 'logging' }
MCPMemoryTinyLogger >> addEntry: aString [

	self entries add: aString.
	[ self entries size > self maxEntries ] whileTrue: [
		self entries removeFirst ]
]

{ #category : 'logging' }
MCPMemoryTinyLogger >> clearLog [

	self entries removeAll
]

{ #category : 'accessing' }
MCPMemoryTinyLogger >> entries [

	^ entries ifNil: [ entries := OrderedCollection new ]
]

{ #category : 'initialization' }
MCPMemoryTinyLogger >> initialize [

	super initialize.
	entries := OrderedCollection new.
	maxEntries := 200
]

{ #category : 'accessing' }
MCPMemoryTinyLogger >> maxEntries [

	^ maxEntries ifNil: [ 200 ]
]

{ #category : 'accessing' }
MCPMemoryTinyLogger >> maxEntries: anInteger [

	maxEntries := anInteger
]

{ #category : 'opening' }
MCPMemoryTinyLogger >> open [

	^ self
]

{ #category : 'accessing' }
MCPMemoryTinyLogger >> recentEntries [

	^ self entries asArray
]

{ #category : 'logging' }
MCPMemoryTinyLogger >> record: aString [

	self addEntry:
		(String streamContents: [ :stream | self record: aString on: stream ])
]
