"
Tests baseline-loading tool behavior.
"
Class {
	#name : 'MCPToolLoadBaselineTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolLoadBaselineTest >> baselineRequestFromArguments: associations [

	| tool |
	tool := MCPToolLoadBaseline new.
	^ tool parsedRequestFromToolRequest: (tool requestFromToolCallArguments: associations asDictionary)
]

{ #category : 'private' }
MCPToolLoadBaselineTest >> executeRecordingCommandForRequest: request [

	| command |
	MCPRecordingLoadBaselineCommand reset.
	command := MCPRecordingLoadBaselineCommand tool: MCPToolLoadBaseline new request: request.
	^ command execute
]

{ #category : 'private' }
MCPToolLoadBaselineTest >> recordedMetacello [

	^ MCPRecordingLoadBaselineCommand lastMetacello
]

{ #category : 'tests' }
MCPToolLoadBaselineTest >> testCommandAppliesProjectSpecificLoadPolicies [

	| metacello request |
	request := self baselineRequestFromArguments: {
			           (#baseline -> 'ExampleBaseline').
			           (#policy -> {
				            (#conflictUseIncoming -> #( 'IncomingProject' )).
				            (#conflictUseLoaded -> #( 'LoadedProject' )).
				            (#upgradeUseLoaded -> #( 'UpgradeProject' )).
				            (#downgradeUseIncoming -> #( 'DowngradeProject' )).
				            (#lockBreak -> #( 'LockedProject' )) } asDictionary) }.
	self executeRecordingCommandForRequest: request.
	metacello := self recordedMetacello.
	self assert: (metacello received: #onConflictUseIncoming:useLoaded: withArguments: {
				 #( 'IncomingProject' ).
				 #( 'LoadedProject' ) }).
	self assert: (metacello received: #onUpgradeUseLoaded: withArguments: { #( 'UpgradeProject' ) }).
	self assert: (metacello received: #onDowngradeUseIncoming: withArguments: { #( 'DowngradeProject' ) }).
	self assert: (metacello received: #onLockBreak: withArguments: { #( 'LockedProject' ) }).
	self deny: (metacello received: #onConflictUseLoaded)
]

{ #category : 'tests' }
MCPToolLoadBaselineTest >> testCommandAppliesResumeWarningAndIncomingConflictPolicies [

	| metacello request |
	request := self baselineRequestFromArguments: {
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
MCPToolLoadBaselineTest >> testCommandAppliesUpgradeDowngradeAndLockPolicies [

	| metacello request |
	request := self baselineRequestFromArguments: {
			           (#baseline -> 'ExampleBaseline').
			           (#policy -> {
				            (#upgrade -> 'useLoaded').
				            (#downgrade -> 'useIncoming').
				            (#lock -> 'break') } asDictionary) }.
	self executeRecordingCommandForRequest: request.
	metacello := self recordedMetacello.
	self assert: (metacello received: #onUpgradeUseLoaded).
	self assert: (metacello received: #onDowngradeUseIncoming).
	self assert: (metacello received: #onLockBreak)
]

{ #category : 'tests' }
MCPToolLoadBaselineTest >> testCommandLoadsExistingBaselineWithoutRepository [

	| data metacello request result |
	request := self baselineRequestFromArguments: { (#baseline -> 'ExampleBaseline') }.
	result := self executeRecordingCommandForRequest: request.
	metacello := self recordedMetacello.
	data := result asDictionary.
	self assert: (metacello messageCountFor: #baseline:) equals: 1.
	self assert: (metacello received: #baseline: withArguments: { 'ExampleBaseline' }).
	self deny: (metacello received: #repository:).
	self assert: (metacello received: #onWarningLog).
	self assert: (metacello received: #onConflictUseLoaded).
	self assert: (metacello received: #load).
	self assert: (data at: #baseline) equals: 'ExampleBaseline'.
	self assert: result newPackageNames isEmpty.
	self assert: result repositoryInfos isEmpty
]

{ #category : 'tests' }
MCPToolLoadBaselineTest >> testCommandLoadsRequestedGroups [

	| metacello request |
	request := self baselineRequestFromArguments: {
			           (#baseline -> 'ExampleBaseline').
			           (#groups -> #( 'Core' 'Tests' )) }.
	self executeRecordingCommandForRequest: request.
	metacello := self recordedMetacello.
	self assert: (metacello received: #load: withArguments: { #( 'Core' 'Tests' ) }).
	self deny: (metacello received: #load)
]

{ #category : 'tests' }
MCPToolLoadBaselineTest >> testUsesBaselineDefaults [

	| request |
	request := self baselineRequestFromArguments: { (#baseline -> 'ExampleBaseline') }.
	self assert: request groups equals: #(  ).
	self assert: request onWarning equals: 'log'.
	self assert: request onConflict equals: 'useLoaded'
]

{ #category : 'private - calling' }
MCPToolLoadBaselineTest >> toolName [

	^ 'baseline_load'
]
