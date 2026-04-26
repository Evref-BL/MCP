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

{ #category : 'private - saving' }
MCPSaveImageRecordingServer >> saveImageSession [

	didSaveImageSession := true.
	^ true
]
