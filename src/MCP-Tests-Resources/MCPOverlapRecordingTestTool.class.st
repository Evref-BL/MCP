"
Test-only MCP tool that records how many of its calls run at once, saying it changes code or not as the test sets it, for the tests of what the server runs one call at a time.
"
Class {
	#name : 'MCPOverlapRecordingTestTool',
	#superclass : 'MCPTool',
	#instVars : [
		'changes',
		'running',
		'mostAtOnce',
		'counting'
	],
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'testing' }
MCPOverlapRecordingTestTool class >> shouldAutoRegister [
	"A fixture is not a tool anyone asked for, and an image that loads MCP's tests serves MCP too, so every fixture says so itself rather than relying on the package it sits in."

	^ false
]

{ #category : 'metadata' }
MCPOverlapRecordingTestTool class >> toolName [

	^ 'overlap_recording_test_tool'
]

{ #category : 'metadata' }
MCPOverlapRecordingTestTool >> buildInputSchema [

	^ MCPStructureInputSchema properties: #(  ) required: #(  )
]

{ #category : 'accessing' }
MCPOverlapRecordingTestTool >> changes: aBoolean [

	changes := aBoolean
]

{ #category : 'testing' }
MCPOverlapRecordingTestTool >> changesCode [

	^ changes
]

{ #category : 'metadata' }
MCPOverlapRecordingTestTool >> description [

	^ 'Records how many of its calls run at once.'
]

{ #category : 'executing' }
MCPOverlapRecordingTestTool >> executeWithRequest: aRequest [
	"The wait lets another call in, if the server lets it."

	counting critical: [
			running := running + 1.
			mostAtOnce := mostAtOnce max: running ].
	(Delay forMilliseconds: 20) wait.
	counting critical: [ running := running - 1 ].
	^ self successResultText: 'Ran.' data: Dictionary new
]

{ #category : 'metadata' }
MCPOverlapRecordingTestTool >> groupName [

	^ 'plugins'
]

{ #category : 'initialization' }
MCPOverlapRecordingTestTool >> initialize [

	super initialize.
	changes := false.
	running := 0.
	mostAtOnce := 0.
	counting := Mutex new
]

{ #category : 'accessing' }
MCPOverlapRecordingTestTool >> mostAtOnce [
	"The most calls that ran at once."

	^ mostAtOnce
]

{ #category : 'testing' }
MCPOverlapRecordingTestTool >> shouldRecordObservability [

	^ false
]

{ #category : 'metadata' }
MCPOverlapRecordingTestTool >> title [

	^ 'Overlap Recording Test Tool'
]
