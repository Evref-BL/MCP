"
Test-only save tool that counts its saves instead of saving the image, or fails as a save that could not write the file does, so that the save tool's answers are tested without writing the image under test.
"
Class {
	#name : 'MCPSaveRecordingTestTool',
	#superclass : 'MCPToolSave',
	#instVars : [
		'saves',
		'failure',
		'restartedAfterFailing'
	],
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'metadata' }
MCPSaveRecordingTestTool class >> shouldAutoRegister [
	"A fixture is not a tool anyone asked for, and an image that loads MCP's tests serves MCP too, so every fixture says so itself rather than relying on the package it sits in."

	^ false
]

{ #category : 'metadata' }
MCPSaveRecordingTestTool class >> toolName [
	"Its own name, so that no server ever answers a call to save with it, nor a call to it with a real save."

	^ 'save_recording_test_tool'
]

{ #category : 'initialization' }
MCPSaveRecordingTestTool >> failWith: anError [
	"Fail every save as Pharo fails one: it signals the error as unhandled, then restarts what the save stopped, MCP's listener among them, once the signal returns."

	failure := anError
]

{ #category : 'initialization' }
MCPSaveRecordingTestTool >> initialize [

	super initialize.
	saves := 0.
	restartedAfterFailing := false
]

{ #category : 'accessing' }
MCPSaveRecordingTestTool >> restartedAfterFailing [

	^ restartedAfterFailing
]

{ #category : 'accessing' }
MCPSaveRecordingTestTool >> saves [

	^ saves
]

{ #category : 'private - saving' }
MCPSaveRecordingTestTool >> snapshot [

	failure ifNotNil: [ :error |
			error raiseUnhandledError.
			^ restartedAfterFailing := true ].
	saves := saves + 1
]
