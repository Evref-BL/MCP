"
Tests method_version_list and method_restore through the server, over a change history of the test's own: what the list shows, and what a restore puts back, as before the last change or as a version, from this session or from before the image was last saved, and what it refuses. The changes are made while a change history monitor of the test's own logs them, as the session's would log an agent's; its session store moves to a new file at a restart, as an image saved and started again does.
"
Class {
	#name : 'MCPMethodVersionToolsTest',
	#superclass : 'MCPChangeHistoryTestCase',
	#instVars : [
		'target'
	],
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPMethodVersionToolsTest >> compile: aSource [
	"Compile through method_compile, as an agent does: it logs the compile, then the change that formats it. Answers the source the method has then."

	self callToolNamed: 'method_compile' withArguments: {
			(#class -> self targetName).
			(#source -> aSource).
			(#protocol -> 'testing') } asDictionary.
	^ (target >> (RBParser parseMethod: aSource) selector) sourceCode
]

{ #category : 'private' }
MCPMethodVersionToolsTest >> fixtureClassNames [

	^ { self targetName }
]

{ #category : 'private' }
MCPMethodVersionToolsTest >> listVersionsOf: aSelector [

	^ self callToolNamed: 'method_version_list' withArguments: {
			  (#class -> self targetName).
			  (#selector -> aSelector) } asDictionary
]

{ #category : 'private' }
MCPMethodVersionToolsTest >> referenceTo: aSelector [

	^ String streamContents: [ :stream | stream << self targetName << '>>' << aSelector ]
]

{ #category : 'private' }
MCPMethodVersionToolsTest >> remove: aSelector [

	self callToolNamed: 'method_remove' withArguments: {
			(#class -> self targetName).
			(#selector -> aSelector) } asDictionary
]

{ #category : 'private' }
MCPMethodVersionToolsTest >> restore: someAssociations [

	^ self callToolNamed: 'method_restore' withArguments: ({ (#class -> self targetName) } , someAssociations) asDictionary
]

{ #category : 'private' }
MCPMethodVersionToolsTest >> sentence: aString about: aSelector [
	"aString with the reference to the target's method aSelector in place of {1}."

	^ aString format: { (self referenceTo: aSelector) }
]

{ #category : 'running' }
MCPMethodVersionToolsTest >> setUp [

	super setUp.
	target := self
		          createClassNamed: self targetName
		          superclassName: 'Object'
		          slots: #(  )
		          classSlots: #(  ).
	self logToASessionStore
]

{ #category : 'private' }
MCPMethodVersionToolsTest >> targetName [

	^ 'MCPMethodVersionToolsTestTarget'
]

{ #category : 'tests' }
MCPMethodVersionToolsTest >> testAMissNamesTheRestoreThatBringsTheMethodBack [
	"The way an agent meets it: method_get finds no method, its answer names method_restore, and the same class and selector bring it back."

	| source |
	source := self compile: 'probe ^ 1'.
	self remove: 'probe'.
	self assert: (((self errorFrom: (self callToolNamed: 'method_get' withArguments: {
					    (#class -> self targetName).
					    (#selector -> 'probe') } asDictionary)) at: #message) endsWith: 'method_restore brings it back.').
	self restore: { (#selector -> 'probe') }.
	self assert: (target >> #probe) sourceCode equals: source
]

{ #category : 'tests' }
MCPMethodVersionToolsTest >> testARestoreIsAVersionThatARestoreUndoes [

	| first second |
	first := self compile: 'probe ^ 1'.
	second := self compile: 'probe ^ 2'.
	self restore: { (#selector -> 'probe') }.
	self
		assert: (((self dataFrom: (self listVersionsOf: 'probe')) at: #versions) collect: [ :each | each at: #source ] as: Array)
		equals: {
				first.
				second.
				first }.
	self restore: { (#selector -> 'probe') }.
	self assert: (target >> #probe) sourceCode equals: second
]

{ #category : 'tests' }
MCPMethodVersionToolsTest >> testRestoreAnswersWhatItInstalled [

	| data result source |
	source := self compile: 'probe ^ 1'.
	self remove: 'probe'.
	result := self restore: { (#selector -> 'probe') }.
	data := self dataFrom: result.
	self assert: (data at: #source) equals: source.
	self assert: (data at: #protocol) equals: 'testing'.
	self assert: ((self textFrom: result) includesSubstring: source)
]

{ #category : 'tests' }
MCPMethodVersionToolsTest >> testRestoreBringsBackAMethodRemovedBeforeTheLastSave [
	"Removed, then the image saved and started again: the removal is in the file of the session before, which this one continues."

	| result source |
	source := self compile: 'probe ^ 1'.
	self remove: 'probe'.
	self restart.
	result := self restore: { (#selector -> 'probe') }.
	self assert: (self summaryFrom: result) equals: (self sentence: 'Restored {1} as it was before its removal.' about: 'probe').
	self assert: (target >> #probe) sourceCode equals: source.
	self assert: (target >> #probe) protocolName asString equals: 'testing'
]

{ #category : 'tests' }
MCPMethodVersionToolsTest >> testRestoreBringsBackARemovedMethodWithItsProtocol [

	| result source |
	source := self compile: 'probe ^ 1'.
	self remove: 'probe'.
	result := self restore: { (#selector -> 'probe') }.
	self assert: (self summaryFrom: result) equals: (self sentence: 'Restored {1} as it was before its removal.' about: 'probe').
	self assert: (target >> #probe) sourceCode equals: source.
	self assert: (target >> #probe) protocolName asString equals: 'testing'
]

{ #category : 'tests' }
MCPMethodVersionToolsTest >> testRestoreBringsBackSeveralRemovedMethods [

	| result |
	self compile: 'probe ^ 1'.
	self compile: 'other ^ 1'.
	self remove: 'probe'.
	self remove: 'other'.
	result := self restore: { (#selector -> #( 'probe' 'other' )) }.
	self assert: (self summaryFrom: result) equals: 'Restored 2 of 2 methods.'.
	self assert: (target includesSelector: #probe).
	self assert: (target includesSelector: #other)
]

{ #category : 'tests' }
MCPMethodVersionToolsTest >> testRestoreInstallsTheVersionItIsGivenAsRecorded [
	"A method compiled without method_compile keeps the source it was given, and a restore installs that source, unformatted, in its protocol."

	| result |
	target compile: 'probe ^1+2' classified: 'first'.
	self compile: 'probe ^ 3'.
	result := self restore: {
			          (#selector -> 'probe').
			          (#version -> 1) }.
	self assert: (self summaryFrom: result) equals: (self sentence: 'Restored {1} to version 1.' about: 'probe').
	self assert: (target >> #probe) sourceCode equals: 'probe ^1+2'.
	self assert: (target >> #probe) protocolName asString equals: 'first'
]

{ #category : 'tests' }
MCPMethodVersionToolsTest >> testRestorePutsBackTheSourceBeforeTheLastChange [

	| result source |
	source := self compile: 'probe ^ 1'.
	self compile: 'probe ^ 2'.
	result := self restore: { (#selector -> 'probe') }.
	self assert: (self summaryFrom: result) equals: (self sentence: 'Restored {1} as it was before its last change.' about: 'probe').
	self assert: (target >> #probe) sourceCode equals: source
]

{ #category : 'tests' }
MCPMethodVersionToolsTest >> testRestoreRefusesAMethodWithoutARecordedVersion [

	| error result |
	result := self restore: { (#selector -> 'absent') }.
	self assert: (self resultIndicatesError: result).
	error := self errorFrom: result.
	self assert: (error at: #errorCode) equals: 'MethodVersionNotFound'.
	self
		assert: (error at: #message)
		equals:
		(self sentence: 'The change history records no change to {1}, so there is no version to restore it from.' about: 'absent')
]

{ #category : 'tests' }
MCPMethodVersionToolsTest >> testRestoreRefusesAVersionForSeveralMethods [

	| result |
	self compile: 'probe ^ 1'.
	self compile: 'other ^ 1'.
	result := self restore: {
			          (#selector -> #( 'probe' 'other' )).
			          (#version -> 1) }.
	self assert: (self resultIndicatesError: result).
	self assert: ((self errorFrom: result) at: #errorCode) equals: 'VersionOfSeveralMethods'.
	self assert: (target includesSelector: #probe).
	self assert: (target includesSelector: #other)
]

{ #category : 'tests' }
MCPMethodVersionToolsTest >> testRestoreRefusesAVersionThatIsNotRecorded [

	| result |
	self compile: 'probe ^ 1'.
	result := self restore: {
			          (#selector -> 'probe').
			          (#version -> 3) }.
	self assert: (self resultIndicatesError: result).
	self
		assert: ((self errorFrom: result) at: #message)
		equals: (self sentence: '{1} has 1 version in the change history: there is no version 3.' about: 'probe').
	self assert: (target includesSelector: #probe)
]

{ #category : 'tests' }
MCPMethodVersionToolsTest >> testRestoreRemovesWhatTheLastChangeAdded [

	| result |
	self compile: 'probe ^ 1'.
	result := self restore: { (#selector -> 'probe') }.
	self
		assert: (self summaryFrom: result)
		equals: (self sentence: 'Removed {1}, as it was before its last change added it.' about: 'probe').
	self deny: (target includesSelector: #probe)
]

{ #category : 'tests' }
MCPMethodVersionToolsTest >> testTheListSaysWhenNoVersionIsRecorded [

	| result |
	result := self listVersionsOf: 'absent'.
	self assert: (self summaryFrom: result) equals: (self sentence: 'The change history records no version of {1}.' about: 'absent').
	self assert: ((self dataFrom: result) at: #versions) isEmpty
]

{ #category : 'tests' }
MCPMethodVersionToolsTest >> testTheListShowsARemovedMethod [

	| source versions |
	source := self compile: 'probe ^ 1'.
	self remove: 'probe'.
	versions := (self dataFrom: (self listVersionsOf: 'probe')) at: #versions.
	self assert: (versions collect: [ :each | each at: #change ] as: Array) equals: #( 'removed' 'added' ).
	self assert: (versions first at: #source) equals: source
]

{ #category : 'tests' }
MCPMethodVersionToolsTest >> testTheListShowsEachVersionNewestFirstWithItsSource [
	"Each method_compile is one version, with the source it left formatted."

	| first result second versions |
	first := self compile: 'probe ^1'.
	second := self compile: 'probe ^2'.
	result := self listVersionsOf: 'probe'.
	self assert: (self summaryFrom: result) equals: (self sentence: 'Listed 2 versions of {1}, newest first.' about: 'probe').
	versions := (self dataFrom: result) at: #versions.
	self assert: (versions collect: [ :each | each at: #version ] as: Array) equals: #( 2 1 ).
	self assert: (versions collect: [ :each | each at: #change ] as: Array) equals: #( 'modified' 'added' ).
	self assert: (versions collect: [ :each | each at: #source ] as: Array) equals: {
			second.
			first }.
	self assert: (versions allSatisfy: [ :each | (each at: #protocol) = 'testing' ])
]

{ #category : 'tests' }
MCPMethodVersionToolsTest >> testTheToolsAreMethodToolsTheCatalogServes [
	"Discoverable through the catalog, like the history tools, rather than listed."

	#( 'method_version_list' 'method_restore' ) do: [ :toolName |
			| tool |
			tool := self toolRegistry
				        toolNamed: toolName
				        ifAbsent: [ self fail: (String streamContents: [ :stream | stream << 'Missing tool ' << toolName ]) ].
			self assert: tool groupName equals: MCPTool methodsGroupName.
			self assert: tool defaultExposure equals: 'discoverable'.
			self deny: (self toolRegistry isToolAdvertisedNamed: toolName) ]
]
