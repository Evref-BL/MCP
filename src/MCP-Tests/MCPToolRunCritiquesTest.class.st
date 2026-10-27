"
Tests critique_run against temporary fixture code so results do not depend on unrelated image contents.
"
Class {
	#name : 'MCPToolRunCritiquesTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'running' }
MCPToolRunCritiquesTest >> callCritiqueRunWithArguments: arguments [

	^ self callToolNamed: MCPToolRunCritiques toolName withArguments: arguments
]

{ #category : 'running' }
MCPToolRunCritiquesTest >> compileFixtureMethodSource: source [

	self ensureMethodSource: source protocol: 'tests' on: self fixtureClass
]

{ #category : 'running' }
MCPToolRunCritiquesTest >> dataForArguments: arguments [

	^ self dataFrom: (self callCritiqueRunWithArguments: arguments)
]

{ #category : 'private' }
MCPToolRunCritiquesTest >> fixtureClass [

	^ self classNamed: self fixtureClassName
]

{ #category : 'private' }
MCPToolRunCritiquesTest >> fixtureClassName [

	^ 'MCPCritiqueRunFixture'
]

{ #category : 'running' }
MCPToolRunCritiquesTest >> removeFixtureClass [

	self removeClassNamed: self fixtureClassName
]

{ #category : 'running' }
MCPToolRunCritiquesTest >> ruleClassNamesFromData: data [

	^ (data at: #rules) collect: [ :each | each at: #ruleClass ]
]

{ #category : 'running' }
MCPToolRunCritiquesTest >> setUp [

	super setUp.
	self removeFixtureClass.
	self
		createClassNamed: self fixtureClassName
		superclassName: Object name
		slots: #(  )
		classSlots: #(  ).
	self compileFixtureMethodSource: 'assignmentInBlockProbe

	| value |
	[ value := 1 ] ensure: [  ].
	^ value'.
	self compileFixtureMethodSource: 'secondAssignmentInBlockProbe

	| value |
	[ value := 2 ] ensure: [  ].
	^ value'
]

{ #category : 'running' }
MCPToolRunCritiquesTest >> tearDown [

	self removeFixtureClass.
	super tearDown
]

{ #category : 'tests' }
MCPToolRunCritiquesTest >> testFlagsCascadedStreamWrites [
	"<< answers the stream, so a cascade of writes says the same thing with more punctuation."

	| data rule |
	self compileFixtureMethodSource: 'cascadedStreamWriteProbe

	^ String streamContents: [ :stream |
		stream
			<< ''first'';
			<< ''second'' ]'.

	data := self dataForArguments: {
			        (#scope -> { (#classes -> { self fixtureClassName }) } asDictionary).
			        (#ruleClasses -> { MCPStreamWriteCascadeRule name }) } asDictionary.

	rule := (data at: #rules) first.
	self assert: (rule at: #ruleClass) equals: MCPStreamWriteCascadeRule name.
	self assert: (rule at: #hits) size equals: 1.
	self assert: ((rule at: #hits) first at: #method) equals: self fixtureClassName , '>>cascadedStreamWriteProbe'
]

{ #category : 'tests' }
MCPToolRunCritiquesTest >> testLeavesChainedStreamWritesAlone [

	| data |
	self compileFixtureMethodSource: 'chainedStreamWriteProbe

	^ String streamContents: [ :stream | stream << ''first'' << ''second'' ]'.

	data := self dataForArguments: {
			        (#scope -> { (#classes -> { self fixtureClassName }) } asDictionary).
			        (#ruleClasses -> { MCPStreamWriteCascadeRule name }) } asDictionary.

	self
		assert: ((data at: #rules) allSatisfy: [ :each | (each at: #hits) isEmpty ])
		description: 'A chained write is not a cascade.'
]

{ #category : 'tests' }
MCPToolRunCritiquesTest >> testMarksTheRulesMethodRewriteCanApply [

	| mcpRule renrakuRule |
	mcpRule := (self dataForArguments: {
			            (#scope -> { (#classes -> { self fixtureClassName }) } asDictionary).
			            (#ruleClasses -> { MCPCollectionThenDoRule name }) } asDictionary) at: #rules.
	renrakuRule := (self dataForArguments: {
			              (#scope -> { (#classes -> { self fixtureClassName }) } asDictionary).
			              (#ruleClasses -> { ReAssignmentInBlockRule name }) } asDictionary) at: #rules.
	"A rule whose patterns method_rewrite can be given by name says so."
	mcpRule ifNotEmpty: [ :rules | self assert: (rules first at: #fixable) ].
	"One whose it cannot does not claim it."
	self deny: (renrakuRule first includesKey: #fixable)
]

{ #category : 'tests' }
MCPToolRunCritiquesTest >> testPaginatesIndividualCritiqueHits [
	"A page is the tool's own size, so what a caller sets is where it starts."

	| firstData firstRule secondData secondRule |
	firstData := self dataForArguments: {
		             (#scope -> { (#classes -> { self fixtureClassName }) } asDictionary).
		             (#ruleClasses -> { ReAssignmentInBlockRule name }) } asDictionary.
	firstRule := (firstData at: #rules) first.
	self deny: (firstData includesKey: #nextOffset).
	self assert: (firstRule at: #hits) size equals: 2.
	secondData := self dataForArguments: {
		              (#scope -> { (#classes -> { self fixtureClassName }) } asDictionary).
		              (#ruleClasses -> { ReAssignmentInBlockRule name }).
		              (#offset -> 1) } asDictionary.
	secondRule := (secondData at: #rules) first.
	self assert: (secondRule at: #hits) size equals: 1.
	self assert: ((secondRule at: #hits) first at: #method) equals: self fixtureClassName , '>>secondAssignmentInBlockProbe'
]

{ #category : 'tests' }
MCPToolRunCritiquesTest >> testReturnsScopeWarnings [

	| result warnings |
	result := self callCritiqueRunWithArguments: {
			          (#scope -> { (#classes -> { 'MCPDefinitelyMissingCritiqueRunClass' }) } asDictionary).
			          (#ruleClasses -> { ReAssignmentInBlockRule name }) } asDictionary.
	warnings := self warningsFrom: result.
	self assert: (warnings anySatisfy: [ :each | each includesSubstring: 'MCPDefinitelyMissingCritiqueRunClass' ])
]

{ #category : 'tests' }
MCPToolRunCritiquesTest >> testRunsAllCritiquesWhenRuleClassesAreOmitted [

	| data ruleClassNames |
	data := self dataForArguments: {
			        (#scope -> { (#classes -> { self fixtureClassName }) } asDictionary) } asDictionary.
	ruleClassNames := self ruleClassNamesFromData: data.
	self assert: (ruleClassNames includes: ReAssignmentInBlockRule name)
]

{ #category : 'tests' }
MCPToolRunCritiquesTest >> testRunsClassCritiqueWithClassHit [

	| data hit rule |
	data := self dataForArguments: {
			        (#scope -> { (#classes -> { self fixtureClassName }) } asDictionary).
			        (#ruleClasses -> { ReNoClassCommentRule name }) } asDictionary.
	rule := (data at: #rules) first.
	self assert: (rule at: #ruleClass) equals: ReNoClassCommentRule name.
	hit := (rule at: #hits) first.
	self assert: (hit at: #class) equals: self fixtureClassName
]

{ #category : 'tests' }
MCPToolRunCritiquesTest >> testRunsSelectedNodeCritiqueAndGroupsHitsByRule [

	| data hit hits rule rules |
	data := self dataForArguments: {
			        (#scope -> { (#classes -> { self fixtureClassName }) } asDictionary).
			        (#ruleClasses -> { ReAssignmentInBlockRule name }) } asDictionary.
	rules := data at: #rules.
	self assert: rules size equals: 1.
	rule := rules first.
	self assert: (rule at: #ruleClass) equals: ReAssignmentInBlockRule name.
	self assert: (rule at: #title) equals: ReAssignmentInBlockRule new name.
	self assert: (rule at: #severity) equals: ReAssignmentInBlockRule new severity asString.
	hits := rule at: #hits.
	self assert: hits size equals: 2.
	hit := hits first.
	self assert: (hit at: #method) equals: self fixtureClassName , '>>assignmentInBlockProbe'.
	self assert: (hit includesKey: #interval)
]
