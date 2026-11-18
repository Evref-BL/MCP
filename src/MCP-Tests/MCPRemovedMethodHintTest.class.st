"
Tests that a lookup finding no method says so when this session removed it, through method_get, method_search and method_reference_search. The method is removed while a change history monitor of the test's own logs it, as the session's would log an agent's mistake.
"
Class {
	#name : 'MCPRemovedMethodHintTest',
	#superclass : 'MCPToolAPITestCase',
	#instVars : [
		'originalMonitor',
		'originalMonitorWasEnabled',
		'temporaryMonitor',
		'memoryDirectory'
	],
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'testing' }
MCPRemovedMethodHintTest class >> shouldLogWithEpicea [
	"The removals these tests look up must be in a change history; setUp gives them one of their own."

	^ true
]

{ #category : 'private' }
MCPRemovedMethodHintTest >> hintFor: aSelector [

	^ String streamContents: [ :stream |
		  stream << self target name << '>>' << aSelector << ' was removed in this session: method_restore brings it back.' ]
]

{ #category : 'private' }
MCPRemovedMethodHintTest >> removeInThisSession: aSelector [
	"Compile aSelector into the target and remove it, both logged in the test's change history."

	self target compile: (String streamContents: [ :stream | stream << aSelector << ' ^ nil' ]) classified: 'testing'.
	self target removeSelector: aSelector
]

{ #category : 'private' }
MCPRemovedMethodHintTest >> selectorNamed: aString [
	"Built rather than written, so that no method refers to it and a reference search finds nothing."

	^ ('mcpRemovedHint' , aString) asSymbol
]

{ #category : 'running' }
MCPRemovedMethodHintTest >> setUp [

	super setUp.
	originalMonitor := EpMonitor current.
	originalMonitorWasEnabled := originalMonitor isEnabled.
	originalMonitor disable.
	memoryDirectory := (FileSystem memory / 'mcp-removed-method-hint-test') ensureCreateDirectory.
	temporaryMonitor := EpMonitor newWithLog: (EpLog newWithStore: (OmBlockFileStore named: 'log' inDirectory: memoryDirectory)).
	EpMonitor current: temporaryMonitor.
	temporaryMonitor enable
]

{ #category : 'private' }
MCPRemovedMethodHintTest >> target [

	^ MCPToolGetMethodTestTarget
]

{ #category : 'running' }
MCPRemovedMethodHintTest >> tearDown [

	temporaryMonitor ifNotNil: [ temporaryMonitor disable ].
	originalMonitor ifNotNil: [
			EpMonitor current: originalMonitor.
			originalMonitorWasEnabled
				ifTrue: [ originalMonitor enable ]
				ifFalse: [ originalMonitor disable ] ].
	memoryDirectory ifNotNil: [ memoryDirectory ensureDeleteAll ].
	super tearDown
]

{ #category : 'tests' }
MCPRemovedMethodHintTest >> testMethodGetSaysTheMethodWasRemovedInThisSession [

	| gone result |
	gone := self selectorNamed: 'Get'.
	self removeInThisSession: gone.
	result := self callToolNamed: 'method_get' withArguments: {
			          (#class -> self target name).
			          (#selector -> gone) } asDictionary.
	self assert: ((self errorFrom: result) at: #message) equals: (String streamContents: [ :stream |
				 stream << 'Method ' << self target name << '>>' << gone
				 << ' does not exist. It was removed in this session: method_restore brings it back.' ])
]

{ #category : 'tests' }
MCPRemovedMethodHintTest >> testMethodReferenceSearchForSendersSaysTheMethodWasRemoved [
	"Who sends a method is asked of one that is gone as well: the answer says it was removed."

	| gone result |
	gone := self selectorNamed: 'Senders'.
	self removeInThisSession: gone.
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#name -> gone).
			          (#kind -> 'senders') } asDictionary.
	self
		assert: (self summaryFrom: result)
		equals: (String streamContents: [ :stream | stream << 'No senders of ' << gone << ' in the image. ' << (self hintFor: gone) ])
]

{ #category : 'tests' }
MCPRemovedMethodHintTest >> testMethodReferenceSearchSaysNothingImplementsWhatWasRemoved [

	| gone result |
	gone := self selectorNamed: 'References'.
	self removeInThisSession: gone.
	result := self callToolNamed: 'method_reference_search' withArguments: { (#name -> gone) } asDictionary.
	self assert: (self summaryFrom: result) equals: (String streamContents: [ :stream |
			 stream << 'No implementors or senders of ' << gone << ' in the image. ' << (self hintFor: gone) ])
]

{ #category : 'tests' }
MCPRemovedMethodHintTest >> testMethodSearchForTheSelectorSaysItWasRemoved [

	| gone result |
	gone := self selectorNamed: 'Search'.
	self removeInThisSession: gone.
	result := self callToolNamed: 'method_search' withArguments: {
			          (#selector -> gone).
			          (self searchScope: { (#classes -> { self target name }) }) } asDictionary.
	self
		assert: (self summaryFrom: result)
		equals:
		(String streamContents: [ :stream | stream << 'No methods match in ' << self target name << '. ' << (self hintFor: gone) ])
]

{ #category : 'tests' }
MCPRemovedMethodHintTest >> testMethodSearchOutsideItsClassSaysNothingOfIt [

	| gone result |
	gone := self selectorNamed: 'Elsewhere'.
	self removeInThisSession: gone.
	result := self callToolNamed: 'method_search' withArguments: {
			          (#selector -> gone).
			          (self searchScope: { (#classes -> #( 'Object' )) }) } asDictionary.
	self assert: (self summaryFrom: result) equals: 'No methods match in Object.'
]
