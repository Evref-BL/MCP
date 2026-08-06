"
Test double for MCP that records image-save requests without snapshotting the image.
"
Class {
	#name : 'MCPSaveImageRecordingServer',
	#superclass : 'MCP',
	#instVars : [
		'didSaveImageSession'
	],
	#category : 'MCP-Tests-Resources-Internal',
	#package : 'MCP-Tests-Resources',
	#tag : 'Internal'
}

{ #category : 'private - saving' }
MCPSaveImageRecordingServer >> deferSaveImageAfterCurrentResponse [
	"Tests call MCP directly without an HTTP response boundary, so record the save request immediately."

	self saveImageSession
]

{ #category : 'testing' }
MCPSaveImageRecordingServer >> didSaveImageSession [

	^ didSaveImageSession ifNil: [ false ]
]

{ #category : 'initialization' }
MCPSaveImageRecordingServer >> initialize [

	super initialize.
	self useContentAndStructuredContentToolResponses
]

{ #category : 'private - calling' }
MCPSaveImageRecordingServer >> rpcToolCall: aToolName withParams: someArguments [

	(self toolRegistry isStaticToolNamed: aToolName) ifTrue: [ ^ super rpcToolCall: aToolName withParams: someArguments ].
	^ super rpcToolCall: 'tool_call' withParams: {
			  (#toolName -> aToolName).
			  (#arguments -> someArguments) } asDictionary
]

{ #category : 'private - saving' }
MCPSaveImageRecordingServer >> saveImageSession [

	didSaveImageSession := true.
	^ true
]
