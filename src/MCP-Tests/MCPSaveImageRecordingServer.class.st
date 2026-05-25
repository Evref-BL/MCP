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

{ #category : 'private - dispatch' }
MCPSaveImageRecordingServer >> argumentNamed: anArgumentName in: aDictionary default: defaultValue [

	aDictionary ifNil: [ ^ defaultValue ].
	^ aDictionary
		  at: anArgumentName asSymbol
		  ifAbsent: [
		  aDictionary at: anArgumentName asString ifAbsent: [ defaultValue ] ]
]

{ #category : 'testing' }
MCPSaveImageRecordingServer >> didSaveImageSession [

	^ didSaveImageSession ifNil: [ false ]
]

{ #category : 'private - dispatch' }
MCPSaveImageRecordingServer >> dispatchArgumentsFrom: someArguments [

	| normalized |
	normalized := someArguments
		              ifNil: [ Dictionary new ]
		              ifNotNil: [ someArguments copy ].
	normalized removeKey: #operation ifAbsent: [ ].
	normalized removeKey: 'operation' ifAbsent: [ ].
	^ normalized
]

{ #category : 'private - dispatch' }
MCPSaveImageRecordingServer >> repositoryDispatchToolNameForArguments: someArguments [

	| operation toolNames |
	operation := self
		             argumentNamed: 'operation'
		             in: someArguments
		             default: nil.
	toolNames := {
		             ('create' -> 'create-repository').
		             ('attach' -> 'attach-repository').
		             ('update' -> 'update-repository').
		             ('verifyIdentity' -> 'verify-repository').
		             ('diff' -> 'diff-repository').
		             ('export' -> 'export-repository').
		             ('commit' -> 'commit-repository').
		             ('adoptHead' -> 'adopt-repository-head').
		             ('fetch' -> 'fetch-repository').
		             ('pull' -> 'pull-repository').
		             ('push' -> 'push-repository').
		             ('createBranch' -> 'create-repository-branch').
		             ('switchBranch' -> 'switch-repository-branch') }
		             asDictionary.
	^ toolNames at: operation ifAbsent: [ 'edit-repository' ]
]

{ #category : 'private - dispatch' }
MCPSaveImageRecordingServer >> rpcToolCall: aToolName withParams: someArguments [

	| dispatchArguments dispatchToolName |
	(MCPToolRegistry isStaticTool: aToolName) ifTrue: [
		^ super rpcToolCall: aToolName withParams: someArguments ].
	dispatchToolName := aToolName = 'edit-repository'
		                    ifTrue: [
		                    self repositoryDispatchToolNameForArguments:
			                    someArguments ]
		                    ifFalse: [ aToolName ].
	dispatchArguments := aToolName = 'edit-repository'
		                     ifTrue: [
		                     self dispatchArgumentsFrom: someArguments ]
		                     ifFalse: [ someArguments ].
	^ super rpcToolCall: 'dispatch-tool' withParams: {
			  (#toolName -> dispatchToolName).
			  (#arguments -> dispatchArguments) } asDictionary
]

{ #category : 'private - saving' }
MCPSaveImageRecordingServer >> saveImageSession [

	didSaveImageSession := true.
	^ true
]
