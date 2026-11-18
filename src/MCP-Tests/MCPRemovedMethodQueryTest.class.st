"
Tests what the change history says about removed methods, over a history of the test's own: a method removed and still missing is named, one compiled again is not, and the hint names the history tools.
"
Class {
	#name : 'MCPRemovedMethodQueryTest',
	#superclass : 'MCPTestCase',
	#instVars : [
		'log',
		'compiled'
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
MCPRemovedMethodQueryTest >> logRemovalOf: aSelector [
	"Compile aSelector into the target and remove it, logging the removal as the session's history would."

	self compileInTarget: aSelector.
	log addEntryWith: (EpMethodRemoval method: self target >> aSelector) tags: [ :tags |  ].
	self target removeSelector: aSelector
]

{ #category : 'private' }
MCPRemovedMethodQueryTest >> query [

	^ MCPRemovedMethodQuery onLog: log
]

{ #category : 'private' }
MCPRemovedMethodQueryTest >> referenceTo: aSelector [

	^ String streamContents: [ :stream | stream << self target name << '>>' << aSelector ]
]

{ #category : 'private' }
MCPRemovedMethodQueryTest >> removedMethods [

	^ self query removedMethodsSelecting: [ :behavior :selector :protocol | true ]
]

{ #category : 'private' }
MCPRemovedMethodQueryTest >> selectorNamed: aString [
	"Built rather than written, so that no method refers to it."

	^ ('mcpRemovedQuery' , aString) asSymbol
]

{ #category : 'running' }
MCPRemovedMethodQueryTest >> setUp [

	super setUp.
	log := EpLog newWithStore: OmMemoryStore new.
	compiled := Set new
]

{ #category : 'private' }
MCPRemovedMethodQueryTest >> target [

	^ MCPToolGetMethodTestTarget
]

{ #category : 'running' }
MCPRemovedMethodQueryTest >> tearDown [

	compiled do: [ :each | (self target includesSelector: each) ifTrue: [ self target removeSelector: each ] ].
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
	self assert: self removedMethods equals: { (self referenceTo: gone) }
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
MCPRemovedMethodQueryTest >> testAnImageWithoutAHistoryRemovedNothing [

	self assert: ((MCPRemovedMethodQuery onLog: nil) hintSelecting: [ :behavior :selector :protocol | true ]) isNil
]

{ #category : 'tests' }
MCPRemovedMethodQueryTest >> testTheHintNamesTheMethodAndTheToolsThatBringItBack [

	| gone |
	gone := self selectorNamed: 'Hinted'.
	self logRemovalOf: gone.
	self assert: (self query hintSelecting: [ :behavior :selector :protocol | true ]) equals: (String streamContents: [ :stream |
				 stream << (self referenceTo: gone)
				 << ' was removed in this session: history_entry_list and history_entry_revert, through tool_call, can bring it back.' ]).
	self
		assert: (self query hintAfterNameSelecting: [ :behavior :selector :protocol | true ])
		equals: 'It was removed in this session: history_entry_list and history_entry_revert, through tool_call, can bring it back.'
]

{ #category : 'tests' }
MCPRemovedMethodQueryTest >> testTheHintNamesThreeMethodsNewestFirstAndCountsTheRest [

	| selectors |
	selectors := #( 'One' 'Two' 'Three' 'Four' ) collect: [ :each | self selectorNamed: each ].
	selectors do: [ :each | self logRemovalOf: each ].
	self assert: (self query hintSelecting: [ :behavior :selector :protocol | true ]) equals: (String streamContents: [ :stream |
				 stream << (self referenceTo: selectors fourth) << ', ' << (self referenceTo: selectors third) << ', '
				 << (self referenceTo: selectors second)
				 <<
				 ' and 1 more were removed in this session: history_entry_list and history_entry_revert, through tool_call, can bring them back.' ])
]

{ #category : 'tests' }
MCPRemovedMethodQueryTest >> testTheSelectionSeesTheBehaviorTheSelectorAndTheProtocol [

	| gone seen |
	gone := self selectorNamed: 'Seen'.
	self logRemovalOf: gone.
	seen := OrderedCollection new.
	self query removedMethodsSelecting: [ :behavior :selector :protocol |
			seen add: {
					behavior.
					selector.
					protocol asString }.
			false ].
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
