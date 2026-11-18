"
Tests what the change history says about removed methods, over a history of the test's own: a method removed and still missing is named, one compiled again is not, a removal from before the image was last saved is told apart from one of this session, and the hint names method_restore. The history is a session store in a directory of the test's own, which a restart moves to a new file, as an image saved and started again does.
"
Class {
	#name : 'MCPRemovedMethodQueryTest',
	#superclass : 'MCPTestCase',
	#instVars : [
		'log',
		'compiled',
		'directory'
	],
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPRemovedMethodQueryTest >> compileInTarget: aSelector [

	compiled add: aSelector.
	self target compile: (String streamContents: [ :stream | stream << aSelector << ' ^ nil' ]) classified: 'testing'
]

{ #category : 'private' }
MCPRemovedMethodQueryTest >> logAdditionOf: aSelector [

	self compileInTarget: aSelector.
	log addEntryWith: (EpMethodAddition method: self target >> aSelector) tags: [ :tags |  ]
]

{ #category : 'private' }
MCPRemovedMethodQueryTest >> logAdditionOf: aSelector following: aReference [
	"Log the addition of aSelector as the first entry of a session that an image saved at aReference started."

	self compileInTarget: aSelector.
	log
		addEntryWith: (EpMethodAddition method: self target >> aSelector)
		tags: [ :tags | tags at: EpLog priorReferenceKey put: aReference ]
]

{ #category : 'private' }
MCPRemovedMethodQueryTest >> logRemovalOf: aSelector [
	"Compile aSelector into the target and remove it, logging the removal as the session's history would."

	self compileInTarget: aSelector.
	log addEntryWith: (EpMethodRemoval method: self target >> aSelector) tags: [ :tags |  ].
	self target removeSelector: aSelector
]

{ #category : 'private' }
MCPRemovedMethodQueryTest >> query [
	"Over the session written out first, as the session in progress is for a tool."

	log store flush.
	^ MCPRemovedMethodQuery onLog: log directory: directory
]

{ #category : 'private' }
MCPRemovedMethodQueryTest >> referenceTo: aSelector [

	^ String streamContents: [ :stream | stream << self target name << '>>' << aSelector ]
]

{ #category : 'private' }
MCPRemovedMethodQueryTest >> removedMethods [
	"The methods the query names, with whether this session removed each."

	^ Array streamContents: [ :stream |
			  self query
				  removedMethodsSelecting: [ :behavior :selector :protocol | true ]
				  do: [ :reference :inThisSession | stream nextPut: reference -> inThisSession ] ]
]

{ #category : 'private' }
MCPRemovedMethodQueryTest >> restart [
	"Save the image at the session's last entry and start it again: the next session is a new file, which has logged nothing yet and continues from that entry."

	log store
		flush;
		resetWithNextStoreName
]

{ #category : 'private' }
MCPRemovedMethodQueryTest >> selectorNamed: aString [
	"Built rather than written, so that no method refers to it."

	^ ('mcpRemovedQuery' , aString) asSymbol
]

{ #category : 'running' }
MCPRemovedMethodQueryTest >> setUp [
	"A session store needs a file system that says it is writable, which a memory one does not."

	super setUp.
	compiled := Set new.
	directory := (FileLocator temp asFileReference / ('mcp-removed-method-query-test-' , UUID new asString36)) ensureCreateDirectory.
	log := EpLog newWithStore: (OmSessionStore newWithBaseLocator: directory)
]

{ #category : 'private' }
MCPRemovedMethodQueryTest >> target [

	^ MCPToolGetMethodTestTarget
]

{ #category : 'running' }
MCPRemovedMethodQueryTest >> tearDown [

	compiled do: [ :each | (self target includesSelector: each) ifTrue: [ self target removeSelector: each ] ].
	directory ifNotNil: [ directory ensureDeleteAll ].
	super tearDown
]

{ #category : 'tests' }
MCPRemovedMethodQueryTest >> testAMethodCompiledAgainAfterItsRemovalIsNotRemoved [

	| back |
	back := self selectorNamed: 'Back'.
	self logRemovalOf: back.
	self logAdditionOf: back.
	self assert: self removedMethods isEmpty
]

{ #category : 'tests' }
MCPRemovedMethodQueryTest >> testAMethodRemovedAndStillMissingIsNamed [

	| gone |
	gone := self selectorNamed: 'Gone'.
	self logRemovalOf: gone.
	self assert: self removedMethods equals: { ((self referenceTo: gone) -> true) }
]

{ #category : 'tests' }
MCPRemovedMethodQueryTest >> testAMethodRemovedBeforeTheImageWasLastSavedIsSaidToBe [
	"The session in progress continues the one in which the image was saved, and a removal there is the image's history too."

	| gone |
	gone := self selectorNamed: 'Earlier'.
	self logRemovalOf: gone.
	self restart.
	self assert: self removedMethods equals: { ((self referenceTo: gone) -> false) }.
	self assert: (self query hintSelecting: [ :behavior :selector :protocol | true ]) equals: (String streamContents: [ :stream |
			 stream << (self referenceTo: gone) << ' was removed before the image was last saved: method_restore brings it back.' ]).
	self
		assert: (self query hintAfterNameSelecting: [ :behavior :selector :protocol | true ])
		equals: 'It was removed before the image was last saved: method_restore brings it back.'
]

{ #category : 'tests' }
MCPRemovedMethodQueryTest >> testAMethodTheImageHasAgainIsNotRemoved [
	"Compiled again where the history did not see it, it is not missing, so nothing can bring it back."

	| again |
	again := self selectorNamed: 'Again'.
	self logRemovalOf: again.
	self compileInTarget: again.
	self assert: self removedMethods isEmpty
]

{ #category : 'tests' }
MCPRemovedMethodQueryTest >> testARemovalAfterTheLastSaveIsNotTheImages [
	"A change logged after the entry the image was saved at was lost with the session: the image never had it."

	| saved gone |
	self logAdditionOf: (self selectorNamed: 'Saved').
	saved := log headReference.
	gone := self selectorNamed: 'Lost'.
	self logRemovalOf: gone.
	self restart.
	self logAdditionOf: (self selectorNamed: 'Next') following: saved.
	self assert: self removedMethods isEmpty
]

{ #category : 'tests' }
MCPRemovedMethodQueryTest >> testAnEarlierRemovalOfAMethodThisSessionAddedIsNotRemoved [
	"The newest change decides across sessions too: one this session made to the method, though the image lacks it now, tells more than an earlier removal."

	| back |
	back := self selectorNamed: 'AddedLater'.
	self logRemovalOf: back.
	self restart.
	self logAdditionOf: back.
	self target removeSelector: back.
	self assert: self removedMethods isEmpty
]

{ #category : 'tests' }
MCPRemovedMethodQueryTest >> testAnImageWithoutAHistoryRemovedNothing [

	self assert: ((MCPRemovedMethodQuery onLog: nil directory: nil) hintSelecting: [ :behavior :selector :protocol | true ]) isNil
]

{ #category : 'tests' }
MCPRemovedMethodQueryTest >> testTheHintNamesTheMethodAndTheToolThatBringsItBack [

	| gone |
	gone := self selectorNamed: 'Hinted'.
	self logRemovalOf: gone.
	self assert: (self query hintSelecting: [ :behavior :selector :protocol | true ]) equals: (String streamContents: [ :stream |
			 stream << (self referenceTo: gone) << ' was removed in this session: method_restore brings it back.' ]).
	self
		assert: (self query hintAfterNameSelecting: [ :behavior :selector :protocol | true ])
		equals: 'It was removed in this session: method_restore brings it back.'
]

{ #category : 'tests' }
MCPRemovedMethodQueryTest >> testTheHintNamesThreeMethodsNewestFirstAndCountsTheRest [

	| selectors |
	selectors := #( 'One' 'Two' 'Three' 'Four' ) collect: [ :each | self selectorNamed: each ].
	selectors do: [ :each | self logRemovalOf: each ].
	self assert: (self query hintSelecting: [ :behavior :selector :protocol | true ]) equals: (String streamContents: [ :stream |
				 stream << (self referenceTo: selectors fourth) << ', ' << (self referenceTo: selectors third) << ', '
				 << (self referenceTo: selectors second) << ' and 1 more were removed in this session: method_restore brings them back.' ])
]

{ #category : 'tests' }
MCPRemovedMethodQueryTest >> testTheHintSaysWhichMethodsWereRemovedInThisSessionAndWhichBefore [

	| earlier now |
	earlier := self selectorNamed: 'Before'.
	now := self selectorNamed: 'Now'.
	self logRemovalOf: earlier.
	self restart.
	self logRemovalOf: now.
	self assert: (self query hintSelecting: [ :behavior :selector :protocol | true ]) equals: (String streamContents: [ :stream |
				 stream << (self referenceTo: now) << ' was removed in this session, and ' << (self referenceTo: earlier)
				 << ' was removed before the image was last saved: method_restore brings them back.' ])
]

{ #category : 'tests' }
MCPRemovedMethodQueryTest >> testTheSelectionSeesTheBehaviorTheSelectorAndTheProtocol [

	| gone seen |
	gone := self selectorNamed: 'Seen'.
	self logRemovalOf: gone.
	seen := OrderedCollection new.
	self query
		removedMethodsSelecting: [ :behavior :selector :protocol |
				seen add: {
						behavior.
						selector.
						protocol asString }.
				false ]
		do: [ :reference :inThisSession | self fail: 'The selection refused every method' ].
	self assert: seen asArray equals: { {
			self target.
			gone.
			'testing' } }
]

{ #category : 'tests' }
MCPRemovedMethodQueryTest >> testWhatTheSelectionRefusesIsNotHinted [

	self logRemovalOf: (self selectorNamed: 'Refused').
	self assert: (self query hintSelecting: [ :behavior :selector :protocol | false ]) isNil
]
