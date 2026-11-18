"
Tests that a lookup finding no method says so when the change history shows it removed, through method_get, method_search and method_reference_search, and says whether it was removed in this session or before the image was last saved. The method is removed while a change history monitor of the test's own logs it, as the session's would log an agent's mistake; its session store moves to a new file at a restart, as an image saved and started again does.
"
Class {
	#name : 'MCPRemovedMethodHintTest',
	#superclass : 'MCPToolAPITestCase',
	#instVars : [
		'originalMonitor',
		'originalMonitorWasEnabled',
		'temporaryMonitor',
		'directory'
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
	"What a search says of aSelector, removed in this session."

	^ self hintFor: aSelector removed: 'in this session'
]

{ #category : 'private' }
MCPRemovedMethodHintTest >> hintFor: aSelector removed: when [
	"What a search says of aSelector, removed when says."

	^ String streamContents: [ :stream |
		  stream << self target name << '>>' << aSelector << ' was removed ' << when << ': method_restore brings it back.' ]
]

{ #category : 'private' }
MCPRemovedMethodHintTest >> removeInThisSession: aSelector [
	"Compile aSelector into the target and remove it, both logged in the test's change history."

	self target compile: (String streamContents: [ :stream | stream << aSelector << ' ^ nil' ]) classified: 'testing'.
	self target removeSelector: aSelector
]

{ #category : 'private' }
MCPRemovedMethodHintTest >> restart [
	"Save the image at the session's last entry and start it again: the next session is a new file, which has logged nothing yet and continues from that entry."

	temporaryMonitor sessionStore
		flush;
		resetWithNextStoreName
]

{ #category : 'private' }
MCPRemovedMethodHintTest >> selectorNamed: aString [
	"Built rather than written, so that no method refers to it and a reference search finds nothing."

	^ ('mcpRemovedHint' , aString) asSymbol
]

{ #category : 'running' }
MCPRemovedMethodHintTest >> setUp [
	"The monitor logs to a session store, as the image's does, in a directory of the test's own: on disk, since a session store needs a file system that says it is writable, which a memory one does not."

	super setUp.
	originalMonitor := EpMonitor current.
	originalMonitorWasEnabled := originalMonitor isEnabled.
	originalMonitor disable.
	directory := (FileLocator temp asFileReference / ('mcp-removed-method-hint-test-' , UUID new asString36)) ensureCreateDirectory.
	temporaryMonitor := EpMonitor newWithLog: (EpLog newWithStore: (OmSessionStore newWithBaseLocator: directory)).
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
	directory ifNotNil: [ directory ensureDeleteAll ].
	super tearDown
]

{ #category : 'tests' }
MCPRemovedMethodHintTest >> testMethodGetSaysTheMethodWasRemovedBeforeTheImageWasLastSaved [
	"Removed, then the image saved and started again: the session the agent works in has logged nothing yet, and the removal is in the file of the one before."

	| gone result |
	gone := self selectorNamed: 'GetEarlier'.
	self removeInThisSession: gone.
	self restart.
	result := self callToolNamed: 'method_get' withArguments: {
			          (#class -> self target name).
			          (#selector -> gone) } asDictionary.
	self assert: ((self errorFrom: result) at: #message) equals: (String streamContents: [ :stream |
				 stream << 'Method ' << self target name << '>>' << gone
				 << ' does not exist. It was removed before the image was last saved: method_restore brings it back.' ])
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
MCPRemovedMethodHintTest >> testMethodSearchForTheSelectorSaysItWasRemovedBeforeTheImageWasLastSaved [

	| gone result |
	gone := self selectorNamed: 'SearchEarlier'.
	self removeInThisSession: gone.
	self restart.
	result := self callToolNamed: 'method_search' withArguments: {
			          (#selector -> gone).
			          (self searchScope: { (#classes -> { self target name }) }) } asDictionary.
	self assert: (self summaryFrom: result) equals: (String streamContents: [ :stream |
			 stream << 'No methods match in ' << self target name << '. '
			 << (self hintFor: gone removed: 'before the image was last saved') ])
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
