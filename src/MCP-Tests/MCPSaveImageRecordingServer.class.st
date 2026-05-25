"
Test double for MCP that records image-save requests without snapshotting the image.
"
Class {
	#name : 'MCPSaveImageRecordingServer',
	#superclass : 'MCP',
	#instVars : [
		'didSaveImageSession'
	],
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'testing' }
MCPSaveImageRecordingServer >> didSaveImageSession [

	^ didSaveImageSession ifNil: [ false ]
]

{ #category : 'private - calling' }
MCPSaveImageRecordingServer >> rpcToolCall: aToolName withParams: someArguments [

	(MCPToolRegistry isStaticTool: aToolName) ifTrue: [
		^ super rpcToolCall: aToolName withParams: someArguments ].
	^ super rpcToolCall: 'call-tool' withParams: {
			  (#toolName -> aToolName).
			  (#arguments -> someArguments) } asDictionary
]

{ #category : 'private - saving' }
MCPSaveImageRecordingServer >> saveImageSession [

	didSaveImageSession := true.
	^ true
]
