"
Tests for the load-repository tool and its Metacello command behavior. These tests use small recording doubles to verify Metacello interactions without loading remote code or an external mocking framework.
"
Class {
	#name : 'MCPToolLoadRepositoryTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolLoadRepositoryTest >> executeRecordingCommandForRequest: request [

	| command |
	MCPRecordingLoadBaselineCommand reset.
	command := MCPRecordingLoadRepositoryCommand
		           tool: MCPToolLoadRepository new
		           request: request.
	^ command execute
]

{ #category : 'private' }
MCPToolLoadRepositoryTest >> loadRepositoryRequestFromArguments: associations [

	| tool |
	tool := MCPToolLoadRepository new.
	^ tool parsedRequestFromToolRequest:
		  (tool requestFromToolCallArguments: associations asDictionary)
]

{ #category : 'private' }
MCPToolLoadRepositoryTest >> recordedMetacello [

	^ MCPRecordingLoadBaselineCommand lastMetacello
]

{ #category : 'tests' }
MCPToolLoadRepositoryTest >> testBaselineModeRejectsRemoteArguments [

	| error tool |
	tool := MCPToolLoadRepository new.
	error := [
	         tool parsedRequestFromToolRequest:
		         (tool requestFromToolCallArguments: {
				          (#mode -> 'baseline').
				          (#baseline -> 'ExampleBaseline').
				          (#owner -> 'ExampleOwner') } asDictionary) ]
		         on: MCPCommandError
		         do: [ :caught | caught ].
	self
		assert: error errorCode
		equals: #UnexpectedLoadRepositoryRemoteArguments
]

{ #category : 'tests' }
MCPToolLoadRepositoryTest >> testBaselineModeUsesBaselineDefaults [

	| request tool |
	tool := MCPToolLoadRepository new.
	request := tool parsedRequestFromToolRequest:
		           (tool requestFromToolCallArguments:
			            { (#baseline -> 'ExampleBaseline') } asDictionary).
	self assert: request mode equals: 'baseline'.
	self assert: request hostUrl isNil.
	self assert: request owner isNil.
	self assert: request project isNil.
	self assert: request commitish isNil.
	self assert: request sourceDirectory isNil.
	self assert: request groups equals: #(  ).
	self assert: request onWarning equals: 'log'.
	self assert: request onConflict equals: 'useLoaded'
]

{ #category : 'tests' }
MCPToolLoadRepositoryTest >> testCommandAppliesResumeWarningAndIncomingConflictPolicies [

	| metacello request |
	request := self loadRepositoryRequestFromArguments: {
			           (#owner -> 'ExampleOwner').
			           (#project -> 'ExampleProject').
			           (#baseline -> 'ExampleBaseline').
			           (#onWarning -> 'resume').
			           (#onConflict -> 'useIncoming') }.
	self executeRecordingCommandForRequest: request.
	metacello := self recordedMetacello.
	self assert: (metacello received: #onWarning:).
	self assert: (metacello received: #onConflictUseIncoming).
	self deny: (metacello received: #onWarningLog).
	self deny: (metacello received: #onConflictUseLoaded)
]

{ #category : 'tests' }
MCPToolLoadRepositoryTest >> testCommandConfiguresMetacelloAndLoadsDefaultGroup [

	| data load metacello repository request result |
	request := self loadRepositoryRequestFromArguments: {
			           (#owner -> 'ExampleOwner').
			           (#project -> 'ExampleProject').
			           (#baseline -> 'ExampleBaseline').
			           (#sourceDirectory -> 'src') }.
	result := self executeRecordingCommandForRequest: request.
	metacello := self recordedMetacello.
	data := result asDictionary.
	load := data at: #load.
	repository := data at: #repository.
	self assert: (metacello messageCountFor: #baseline:) equals: 1.
	self assert:
		(metacello received: #baseline: withArguments: { 'ExampleBaseline' }).
	self assert: (metacello
			 received: #repository:
			 withArguments: { 'github://ExampleOwner/ExampleProject:main/src' }).
	self assert: (metacello received: #onWarningLog).
	self assert: (metacello received: #onConflictUseLoaded).
	self assert: (metacello received: #load).
	self assert: result mode equals: 'remote'.
	self
		assert: result repositoryUrl
		equals: 'github://ExampleOwner/ExampleProject:main/src'.
	self
		assert: (repository at: #repositoryUrl)
		equals: result repositoryUrl.
	self assert: (load at: #baseline) equals: 'ExampleBaseline'.
	self assert: result newPackageNames isEmpty.
	self assert: result repositoryInfos isEmpty
]

{ #category : 'tests' }
MCPToolLoadRepositoryTest >> testCommandLoadsExistingBaselineWithoutRepository [

	| data load metacello request result |
	request := self loadRepositoryRequestFromArguments:
		           { (#baseline -> 'ExampleBaseline') }.
	result := self executeRecordingCommandForRequest: request.
	metacello := self recordedMetacello.
	data := result asDictionary.
	load := data at: #load.
	self assert: (metacello messageCountFor: #baseline:) equals: 1.
	self assert:
		(metacello received: #baseline: withArguments: { 'ExampleBaseline' }).
	self deny: (metacello received: #repository:).
	self assert: (metacello received: #onWarningLog).
	self assert: (metacello received: #onConflictUseLoaded).
	self assert: (metacello received: #load).
	self assert: result mode equals: 'baseline'.
	self deny: (data includesKey: #repository).
	self assert: (load at: #baseline) equals: 'ExampleBaseline'.
	self assert: result newPackageNames isEmpty.
	self assert: result repositoryInfos isEmpty
]

{ #category : 'tests' }
MCPToolLoadRepositoryTest >> testCommandLoadsRequestedGroups [

	| metacello request |
	request := self loadRepositoryRequestFromArguments: {
			           (#owner -> 'ExampleOwner').
			           (#project -> 'ExampleProject').
			           (#baseline -> 'ExampleBaseline').
			           (#groups -> #( 'Core' 'Tests' )) }.
	self executeRecordingCommandForRequest: request.
	metacello := self recordedMetacello.
	self assert:
		(metacello received: #load: withArguments: { #( 'Core' 'Tests' ) }).
	self deny: (metacello received: #load)
]

{ #category : 'tests' }
MCPToolLoadRepositoryTest >> testCommandPassPoliciesSkipMetacelloPolicyConfiguration [

	| metacello request |
	request := self loadRepositoryRequestFromArguments: {
			           (#owner -> 'ExampleOwner').
			           (#project -> 'ExampleProject').
			           (#baseline -> 'ExampleBaseline').
			           (#onWarning -> 'pass').
			           (#onConflict -> 'pass') }.
	self executeRecordingCommandForRequest: request.
	metacello := self recordedMetacello.
	self assert: (metacello received: #load).
	self deny: (metacello received: #onWarningLog).
	self deny: (metacello received: #onWarning:).
	self deny: (metacello received: #onConflictUseLoaded).
	self deny: (metacello received: #onConflictUseIncoming)
]

{ #category : 'tests' }
MCPToolLoadRepositoryTest >> testRemoteModeRequiresOwnerAndProject [

	| error tool |
	tool := MCPToolLoadRepository new.
	error := [
	         tool parsedRequestFromToolRequest:
		         (tool requestFromToolCallArguments: {
				          (#mode -> 'remote').
				          (#baseline -> 'ExampleBaseline') } asDictionary) ]
		         on: MCPCommandError
		         do: [ :caught | caught ].
	self
		assert: error errorCode
		equals: #MissingLoadRepositoryRemoteCoordinates
]

{ #category : 'tests' }
MCPToolLoadRepositoryTest >> testRemoteModeUsesGranularDefaults [

	| request tool |
	tool := MCPToolLoadRepository new.
	request := tool parsedRequestFromToolRequest:
		           (tool requestFromToolCallArguments: {
				            (#owner -> 'ExampleOwner').
				            (#project -> 'ExampleProject').
				            (#baseline -> 'ExampleBaseline') } asDictionary).
	self assert: request mode equals: 'remote'.
	self assert: request hostUrl equals: 'github'.
	self assert: request commitish equals: 'main'.
	self assert: request sourceDirectory equals: '.'.
	self assert: request groups equals: #(  ).
	self assert: request onWarning equals: 'log'.
	self assert: request onConflict equals: 'useLoaded'.
	self
		assert: request repositoryUrl
		equals: 'github://ExampleOwner/ExampleProject:main'
]

{ #category : 'tests' }
MCPToolLoadRepositoryTest >> testRepositoryUrlIncludesSourceDirectoryAndCustomHost [

	| request tool |
	tool := MCPToolLoadRepository new.
	request := tool parsedRequestFromToolRequest:
		           (tool requestFromToolCallArguments: {
				            (#hostUrl -> 'gitlab://git.example.com').
				            (#owner -> 'ExampleOwner').
				            (#project -> 'ExampleProject').
				            (#baseline -> 'ExampleBaseline').
				            (#commitish -> 'v1.0.0').
				            (#sourceDirectory -> '/src/') } asDictionary).
	self assert: request mode equals: 'remote'.
	self
		assert: request repositoryUrl
		equals:
		'gitlab://git.example.com:ExampleOwner/ExampleProject:v1.0.0/src'
]

{ #category : 'private - calling' }
MCPToolLoadRepositoryTest >> toolName [

	^ 'load-repository'
]
