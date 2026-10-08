"
Tests for the repository_load tool and its Metacello command behavior. These tests use small recording doubles to verify Metacello interactions without loading remote code or an external mocking framework.
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
	command := MCPRecordingLoadRepositoryCommand tool: MCPToolLoadRepository new request: request.
	^ command execute
]

{ #category : 'private' }
MCPToolLoadRepositoryTest >> loadRepositoryRequestFromArguments: associations [

	| tool |
	tool := MCPToolLoadRepository new.
	^ tool parsedRequestFromToolRequest: (tool requestFromToolCallArguments: associations asDictionary)
]

{ #category : 'private' }
MCPToolLoadRepositoryTest >> recordedMetacello [

	^ MCPRecordingLoadBaselineCommand lastMetacello
]

{ #category : 'tests' }
MCPToolLoadRepositoryTest >> testCommandAppliesResumeWarningAndIncomingConflictPolicies [

	| metacello request |
	request := self loadRepositoryRequestFromArguments: {
			           (#owner -> 'ExampleOwner').
			           (#project -> 'ExampleProject').
			           (#baseline -> 'ExampleBaseline').
			           (#policy -> {
				            (#warning -> 'resume').
				            (#conflict -> 'useIncoming') } asDictionary) }.
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
	self assert: (metacello received: #baseline: withArguments: { 'ExampleBaseline' }).
	self assert: (metacello received: #repository: withArguments: { 'github://ExampleOwner/ExampleProject:main/src' }).
	self assert: (metacello received: #onWarningLog).
	self assert: (metacello received: #onConflictUseLoaded).
	self assert: (metacello received: #load).
	self assert: result mode equals: 'remote'.
	self assert: result repositoryUrl equals: 'github://ExampleOwner/ExampleProject:main/src'.
	self assert: repository equals: { (#repositoryUrl -> result repositoryUrl) } asDictionary.
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
	self assert: (metacello received: #load: withArguments: { #( 'Core' 'Tests' ) }).
	self deny: (metacello received: #load)
]

{ #category : 'tests' }
MCPToolLoadRepositoryTest >> testCommandPassPoliciesSkipMetacelloPolicyConfiguration [

	| metacello request |
	request := self loadRepositoryRequestFromArguments: {
			           (#owner -> 'ExampleOwner').
			           (#project -> 'ExampleProject').
			           (#baseline -> 'ExampleBaseline').
			           (#policy -> {
				            (#warning -> 'pass').
				            (#conflict -> 'pass') } asDictionary) }.
	self executeRecordingCommandForRequest: request.
	metacello := self recordedMetacello.
	self assert: (metacello received: #load).
	self deny: (metacello received: #onWarningLog).
	self deny: (metacello received: #onWarning:).
	self deny: (metacello received: #onConflictUseLoaded).
	self deny: (metacello received: #onConflictUseIncoming)
]

{ #category : 'tests' }
MCPToolLoadRepositoryTest >> testRepositoryLoadAcceptsExplicitRepositoryUrl [

	| metacello repository request result |
	request := self loadRepositoryRequestFromArguments: {
			           (#repositoryUrl -> 'tonel:///tmp/ExampleProject/src').
			           (#baseline -> 'ExampleBaseline') }.
	result := self executeRecordingCommandForRequest: request.
	metacello := self recordedMetacello.
	repository := result asDictionary at: #repository.
	self assert: request mode equals: 'url'.
	self assert: request repositoryUrl equals: 'tonel:///tmp/ExampleProject/src'.
	self assert: (metacello received: #repository: withArguments: { 'tonel:///tmp/ExampleProject/src' }).
	self assert: result mode equals: 'url'.
	self assert: (repository at: #repositoryUrl) equals: 'tonel:///tmp/ExampleProject/src'
]

{ #category : 'tests' }
MCPToolLoadRepositoryTest >> testRepositoryLoadAcceptsLocalCheckoutPath [

	| request |
	request := self loadRepositoryRequestFromArguments: {
			           (#checkoutPath -> '/tmp/ExampleProject').
			           (#sourceDirectory -> '/src/').
			           (#baseline -> 'ExampleBaseline') }.
	self assert: request mode equals: 'local'.
	self assert: request repositoryUrl equals: 'tonel:///tmp/ExampleProject/src'
]

{ #category : 'tests' }
MCPToolLoadRepositoryTest >> testRepositoryLoadAcceptsRegisteredIcebergRepository [

	| repository request |
	repository := MCPTestIceRepository named: 'MCP Load Registered Repository' location: FileLocator imageDirectory pathString.
	self withRegisteredRepository: repository do: [
			request := self loadRepositoryRequestFromArguments: {
					           (#name -> repository name).
					           (#baseline -> 'MCP').
					           (#sourceDirectory -> 'src') }.
			self assert: request mode equals: 'iceberg'.
			self assert: (request repositoryUrl beginsWith: 'tonel://').
			self assert: (request repositoryUrl endsWith: '/src') ]
]

{ #category : 'tests' }
MCPToolLoadRepositoryTest >> testRepositoryLoadRejectsMixedRepositorySources [

	| tool toolRequest |
	tool := MCPToolLoadRepository new.
	toolRequest := tool requestFromToolCallArguments: {
			               (#repositoryUrl -> 'tonel:///tmp/ExampleProject/src').
			               (#owner -> 'ExampleOwner').
			               (#baseline -> 'ExampleBaseline') } asDictionary.
	self should: [ tool parsedRequestFromToolRequest: toolRequest ] raise: MCPCommandError
]

{ #category : 'tests' }
MCPToolLoadRepositoryTest >> testRepositoryLoadRequiresOwnerAndProject [

	| tool toolRequest |
	tool := MCPToolLoadRepository new.
	toolRequest := tool requestFromToolCallArguments: { (#baseline -> 'ExampleBaseline') } asDictionary.
	self should: [ tool parsedRequestFromToolRequest: toolRequest ] raise: MCPCommandError
]

{ #category : 'tests' }
MCPToolLoadRepositoryTest >> testRepositoryLoadUsesRemoteDefaults [

	| request tool |
	tool := MCPToolLoadRepository new.
	request := tool parsedRequestFromToolRequest: (tool requestFromToolCallArguments: {
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
	self assert: request repositoryUrl equals: 'github://ExampleOwner/ExampleProject:main'
]

{ #category : 'tests' }
MCPToolLoadRepositoryTest >> testRepositoryUrlEscapesCommitishSlashes [

	| request tool |
	tool := MCPToolLoadRepository new.
	request := tool parsedRequestFromToolRequest: (tool requestFromToolCallArguments: {
				            (#owner -> 'ExampleOwner').
				            (#project -> 'ExampleProject').
				            (#baseline -> 'ExampleBaseline').
				            (#commitish -> 'feature/load/slash').
				            (#sourceDirectory -> 'src') } asDictionary).
	self assert: request mode equals: 'remote'.
	self assert: request repositoryUrl equals: 'github://ExampleOwner/ExampleProject:feature\/load\/slash/src'
]

{ #category : 'tests' }
MCPToolLoadRepositoryTest >> testRepositoryUrlIncludesSourceDirectoryAndCustomHost [

	| request tool |
	tool := MCPToolLoadRepository new.
	request := tool parsedRequestFromToolRequest: (tool requestFromToolCallArguments: {
				            (#hostUrl -> 'gitlab://git.example.com').
				            (#owner -> 'ExampleOwner').
				            (#project -> 'ExampleProject').
				            (#baseline -> 'ExampleBaseline').
				            (#commitish -> 'v1.0.0').
				            (#sourceDirectory -> '/src/') } asDictionary).
	self assert: request mode equals: 'remote'.
	self assert: request repositoryUrl equals: 'gitlab://git.example.com:ExampleOwner/ExampleProject:v1.0.0/src'
]

{ #category : 'private - calling' }
MCPToolLoadRepositoryTest >> toolName [

	^ 'repository_load'
]

{ #category : 'private' }
MCPToolLoadRepositoryTest >> withRegisteredRepository: aRepository do: aBlock [

	| registry |
	registry := IceRepository registry.
	registry add: aRepository.
	[ aBlock value ] ensure: [ registry remove: aRepository ifAbsent: [ ] ]
]
