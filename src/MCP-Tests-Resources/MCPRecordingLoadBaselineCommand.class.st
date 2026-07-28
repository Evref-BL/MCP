"
Load-baseline command test double that injects a recording Metacello object.
"
Class {
	#name : 'MCPRecordingLoadBaselineCommand',
	#superclass : 'MCPLoadBaselineCommand',
	#classInstVars : [
		'LastMetacello'
	],
	#category : 'MCP-Tests-Resources-Support',
	#package : 'MCP-Tests-Resources',
	#tag : 'Support'
}

{ #category : 'accessing' }
MCPRecordingLoadBaselineCommand class >> lastMetacello [

	^ LastMetacello
]

{ #category : 'accessing' }
MCPRecordingLoadBaselineCommand class >> lastMetacello: aMetacello [

	LastMetacello := aMetacello
]

{ #category : 'initialization' }
MCPRecordingLoadBaselineCommand class >> reset [

	LastMetacello := nil
]

{ #category : 'private - loading' }
MCPRecordingLoadBaselineCommand >> metacello [

	| metacello |
	metacello := MCPRecordingMetacello new.
	self class lastMetacello: metacello.
	^ metacello
]
