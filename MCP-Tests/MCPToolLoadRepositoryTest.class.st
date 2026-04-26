"
Tests for the load-repository tool and its Metacello command behavior. These tests use Mocketry to verify Metacello interactions without loading remote code.
"
Class {
	#name : 'MCPToolLoadRepositoryTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolLoadRepositoryTest >> loadRepositoryRequestFromArguments: associations [

	| tool |
	tool := MCPToolLoadRepository new.
	^ tool parsedRequestFromToolRequest:
		  (tool requestFromToolCallArguments: associations asDictionary)
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

	| command metacello request |
	request := self loadRepositoryRequestFromArguments: {
			           (#owner -> 'ExampleOwner').
			           (#project -> 'ExampleProject').
			           (#baseline -> 'ExampleBaseline').
			           (#onWarning -> 'resume').
			           (#onConflict -> 'useIncoming') }.
	[
	metacello := Mock named: 'metacello'.
	Metacello stub new willReturn: metacello.
	command := MCPLoadRepositoryCommand
		           tool: MCPToolLoadRepository new
		           request: request.
	command execute.
	metacello should receive onWarning: Any.
	metacello should receive onConflictUseIncoming.
	metacello should not receive onWarningLog.
	metacello should not receive onConflictUseLoaded ] ensure: [
		MockCurrentBehaviour value: nil ]
]

{ #category : 'tests' }
MCPToolLoadRepositoryTest >> testCommandConfiguresMetacelloAndLoadsDefaultGroup [

	| command data load metacello repository request result |
	request := self loadRepositoryRequestFromArguments: {
			           (#owner -> 'ExampleOwner').
			           (#project -> 'ExampleProject').
			           (#baseline -> 'ExampleBaseline').
			           (#sourceDirectory -> 'src') }.
	[
	metacello := Mock named: 'metacello'.
	Metacello stub new willReturn: metacello.
	command := MCPLoadRepositoryCommand
		           tool: MCPToolLoadRepository new
		           request: request.
	result := command execute.
	data := result asDictionary.
	load := data at: #load.
	repository := data at: #repository.
	Metacello should receive new once.
	metacello should receive baseline: 'ExampleBaseline'.
	metacello should receive repository:
		'github://ExampleOwner/ExampleProject:main/src'.
	metacello should receive onWarningLog.
	metacello should receive onConflictUseLoaded.
	metacello should receive load.
	self assert: result mode equals: 'remote'.
	self
		assert: result repositoryUrl
		equals: 'github://ExampleOwner/ExampleProject:main/src'.
	self
		assert: (repository at: #repositoryUrl)
		equals: result repositoryUrl.
	self assert: (load at: #baseline) equals: 'ExampleBaseline'.
	self assert: result newPackageNames isEmpty.
	self assert: result repositoryInfos isEmpty ] ensure: [
		MockCurrentBehaviour value: nil ]
]

{ #category : 'tests' }
MCPToolLoadRepositoryTest >> testCommandLoadsExistingBaselineWithoutRepository [

	| command data load metacello request result |
	request := self loadRepositoryRequestFromArguments:
		           { (#baseline -> 'ExampleBaseline') }.
	[
	metacello := Mock named: 'metacello'.
	Metacello stub new willReturn: metacello.
	command := MCPLoadRepositoryCommand
		           tool: MCPToolLoadRepository new
		           request: request.
	result := command execute.
	data := result asDictionary.
	load := data at: #load.
	Metacello should receive new once.
	metacello should receive baseline: 'ExampleBaseline'.
	metacello should not receive repository: Any.
	metacello should receive onWarningLog.
	metacello should receive onConflictUseLoaded.
	metacello should receive load.
	self assert: result mode equals: 'baseline'.
	self deny: (data includesKey: #repository).
	self assert: (load at: #baseline) equals: 'ExampleBaseline'.
	self assert: result newPackageNames isEmpty.
	self assert: result repositoryInfos isEmpty ] ensure: [
		MockCurrentBehaviour value: nil ]
]

{ #category : 'tests' }
MCPToolLoadRepositoryTest >> testCommandLoadsRequestedGroups [

	| command metacello request |
	request := self loadRepositoryRequestFromArguments: {
			           (#owner -> 'ExampleOwner').
			           (#project -> 'ExampleProject').
			           (#baseline -> 'ExampleBaseline').
			           (#groups -> #( 'Core' 'Tests' )) }.
	[
	metacello := Mock named: 'metacello'.
	Metacello stub new willReturn: metacello.
	command := MCPLoadRepositoryCommand
		           tool: MCPToolLoadRepository new
		           request: request.
	command execute.
	metacello should receive load: #( 'Core' 'Tests' ).
	metacello should not receive load ] ensure: [
		MockCurrentBehaviour value: nil ]
]

{ #category : 'tests' }
MCPToolLoadRepositoryTest >> testCommandPassPoliciesSkipMetacelloPolicyConfiguration [

	| command metacello request |
	request := self loadRepositoryRequestFromArguments: {
			           (#owner -> 'ExampleOwner').
			           (#project -> 'ExampleProject').
			           (#baseline -> 'ExampleBaseline').
			           (#onWarning -> 'pass').
			           (#onConflict -> 'pass') }.
	[
	metacello := Mock named: 'metacello'.
	Metacello stub new willReturn: metacello.
	command := MCPLoadRepositoryCommand
		           tool: MCPToolLoadRepository new
		           request: request.
	command execute.
	metacello should receive load.
	metacello should not receive onWarningLog.
	metacello should not receive onWarning: Any.
	metacello should not receive onConflictUseLoaded.
	metacello should not receive onConflictUseIncoming ] ensure: [
		MockCurrentBehaviour value: nil ]
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
