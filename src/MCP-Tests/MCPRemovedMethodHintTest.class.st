"
Tests that a lookup finding no method says so when the change history shows it removed, through method_get, method_search and method_reference_search, and says whether it was removed in this session or before the image was last saved. The method is removed while a change history monitor of the test's own logs it, as the session's would log an agent's mistake; its session store moves to a new file at a restart, as an image saved and started again does.
"
Class {
	#name : 'MCPRemovedMethodHintTest',
	#superclass : 'MCPChangeHistoryTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

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
MCPRemovedMethodHintTest >> selectorNamed: aString [
	"Built rather than written, so that no method refers to it and a reference search finds nothing."

	^ ('mcpRemovedHint' , aString) asSymbol
]

{ #category : 'running' }
MCPRemovedMethodHintTest >> setUp [

	super setUp.
	self logToASessionStore
]

{ #category : 'private' }
MCPRemovedMethodHintTest >> target [

	^ MCPToolGetMethodTestTarget
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
			          (#query -> gone).
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
	result := self callToolNamed: 'method_reference_search' withArguments: { (#query -> gone) } asDictionary.
	self assert: (self summaryFrom: result) equals: (String streamContents: [ :stream |
			 stream << 'No implementors or senders of ' << gone << ' in the image. ' << (self hintFor: gone) ])
]

{ #category : 'tests' }
MCPRemovedMethodHintTest >> testMethodSearchForTheSelectorSaysItWasRemoved [

	| gone result |
	gone := self selectorNamed: 'Search'.
	self removeInThisSession: gone.
	result := self callToolNamed: 'method_search' withArguments: {
			          (#query -> gone).
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
			          (#query -> gone).
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
			          (#query -> gone).
			          (self searchScope: { (#classes -> #( 'Object' )) }) } asDictionary.
	self assert: (self summaryFrom: result) equals: 'No methods match in Object.'
]
