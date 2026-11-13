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

{ #category : 'private' }
MCPToolRunCritiquesTest >> compileReportsConcatenation [
	"Whether method_compile reports MCPStringConcatenationRule for the concatenation probe, compiled into the fixture."

	| result |
	result := self callToolNamed: 'method_compile' withArguments: {
			          (#class -> self fixtureClassName).
			          (#source -> self concatenationSource).
			          (#protocol -> 'tests') } asDictionary.
	^ ((self dataFrom: result) at: #critiques ifAbsent: [ #(  ) ]) anySatisfy: [ :each |
		  (each at: #ruleClass) = MCPStringConcatenationRule name ]
]

{ #category : 'private' }
MCPToolRunCritiquesTest >> concatenationHitsNamingTheRule: namesTheRule [
	"The hits of MCPStringConcatenationRule in the fixture, asking for it by name or for every rule."

	| arguments |
	arguments := Dictionary new.
	arguments at: #scope put: { (#classes -> { self fixtureClassName }) } asDictionary.
	namesTheRule ifTrue: [ arguments at: #ruleClasses put: { MCPStringConcatenationRule name } ].
	^ ((self dataForArguments: arguments) at: #rules) select: [ :each | (each at: #ruleClass) = MCPStringConcatenationRule name ]
]

{ #category : 'private' }
MCPToolRunCritiquesTest >> concatenationSource [

	^ 'concatenationProbe: aName ^ ''<'' , aName , ''>'''
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

{ #category : 'private' }
MCPToolRunCritiquesTest >> manifestBuilder [
	"A manifest for the fixture's package, made the way the browser makes one when a person bans a critique."

	^ TheManifestBuilder of: self fixtureClass
]

{ #category : 'running' }
MCPToolRunCritiquesTest >> removeFixtureClass [

	self removeClassNamed: self fixtureClassName
]

{ #category : 'private' }
MCPToolRunCritiquesTest >> removeFixtureManifest [

	(self packageOrganizer hasPackage: self generatedPackageName) ifFalse: [ ^ self ].
	(self packageOrganizer packageNamed: self generatedPackageName) packageManifestOrNil ifNotNil: [ :manifest |
		self removeClassNamed: manifest name ]
]

{ #category : 'running' }
MCPToolRunCritiquesTest >> ruleClassNamesFromData: data [

	^ (data at: #rules) collect: [ :each | each at: #ruleClass ]
]

{ #category : 'running' }
MCPToolRunCritiquesTest >> selectorsHitBy: aRuleClass [

	| data |
	data := self dataForArguments: {
			        (#scope -> { (#classes -> { self fixtureClassName }) } asDictionary).
			        (#ruleClasses -> { aRuleClass name }) } asDictionary.
	^ ((data at: #rules) flatCollect: [ :each | each at: #hits ])
		  collect: [ :each | ((each at: #method) copyAfterLast: $>) asSymbol ]
		  as: Set
]

{ #category : 'running' }
MCPToolRunCritiquesTest >> setUp [

	super setUp.
	self removeFixtureManifest.
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

	self removeFixtureManifest.
	self removeFixtureClass.
	super tearDown
]

{ #category : 'tests' }
MCPToolRunCritiquesTest >> testAsksANodeRuleWhetherItWantsTheMethod [
	"ReDoNotSendSuperInitializeInClassSideRule is about the class side and says so in shouldCheckMethod:. An instance-side initialize sending super initialize is what it exists to leave alone."

	| data hits |
	self compileFixtureMethodSource: 'initialize

	super initialize.
	self assignmentInBlockProbe'.
	self
		ensureMethodSource: 'initialize

	super initialize.
	self new'
		protocol: 'tests'
		on: self fixtureClass class.

	data := self dataForArguments: {
			        (#scope -> { (#classes -> { self fixtureClassName }) } asDictionary).
			        (#ruleClasses -> { ReDoNotSendSuperInitializeInClassSideRule name }) } asDictionary.
	hits := (data at: #rules) flatCollect: [ :each | each at: #hits ].
	self assert: (hits collect: [ :each | each at: #method ] as: Array) equals: { (self fixtureClassName , ' class>>initialize') }
]

{ #category : 'tests' }
MCPToolRunCritiquesTest >> testDeniesOnlyWhereDenyIsUnderstood [
	"Object answers assert: and has no deny:."

	self compileFixtureMethodSource: 'objectAssertProbe: aBoolean

	self assert: aBoolean not'.
	self compileFixtureMethodSource: 'testAssertProbe: aTest

	aTest assert: aTest isEmpty not'.

	self assert: (self selectorsHitBy: MCPDenyRule) equals: (Set with: #testAssertProbe:)
]

{ #category : 'tests' }
MCPToolRunCritiquesTest >> testDetectIfFoundOnlyWhereNothingReadsTheAnswer [
	"detect:ifFound: answers the collection, not what its block answers."

	self compileFixtureMethodSource: 'unusedAnswerProbe: aCollection

	(aCollection detect: [ :each | each odd ] ifNone: [ nil ]) ifNotNil: [ :found | found printString ]'.
	self compileFixtureMethodSource: 'returnedAnswerProbe: aCollection

	^ (aCollection detect: [ :each | each odd ] ifNone: [ nil ]) ifNotNil: [ :found | found printString ]'.
	self compileFixtureMethodSource: 'bothBranchesProbe: aCollection

	^ (aCollection detect: [ :each | each odd ] ifNone: [ nil ]) ifNil: [ 0 ] ifNotNil: [ :found | found ]'.

	self assert: (self selectorsHitBy: MCPDetectIfFoundRule) equals: (Set with: #unusedAnswerProbe: with: #bothBranchesProbe:)
]

{ #category : 'tests' }
MCPToolRunCritiquesTest >> testFlagsCascadedStreamWrites [
	"<< answers the stream, so a cascade of writes says the same thing with more punctuation. A cascade pattern matches a cascade of its own length and no other, so a cascade past two is its own case."

	self compileFixtureMethodSource: 'cascadedStreamWriteProbe

	^ String streamContents: [ :stream |
		stream
			<< ''first'';
			<< ''second'' ]'.
	self compileFixtureMethodSource: 'longCascadedStreamWriteProbe

	^ String streamContents: [ :stream |
		stream
			<< ''first'';
			<< ''second'';
			<< ''third'';
			<< ''fourth'';
			<< ''fifth'' ]'.

	self
		assert: (self selectorsHitBy: MCPStreamWriteCascadeRule)
		equals: (Set with: #cascadedStreamWriteProbe with: #longCascadedStreamWriteProbe)
]

{ #category : 'tests' }
MCPToolRunCritiquesTest >> testLeavesBooleanNilBranchesToPharo [
	"ReNilBranchRule says it of ifTrue:ifFalse: already."

	self compileFixtureMethodSource: 'booleanNilBranchProbe: aBoolean

	^ aBoolean ifTrue: [ 42 ] ifFalse: [ nil ]'.
	self compileFixtureMethodSource: 'nilBranchProbe: anObject

	^ anObject ifNil: [ nil ] ifNotNil: [ :present | present printString ]'.

	self assert: (self selectorsHitBy: MCPNilOnlyConditionalRule) equals: (Set with: #nilBranchProbe:)
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
MCPToolRunCritiquesTest >> testLeavesConcatenatedArraysAlone [
	"A literal array is a literal too, and a stream would turn its concatenation into a string."

	self compileFixtureMethodSource: 'arrayConcatenationProbe: aCollection

	^ #( 1 ) , aCollection , #( 2 )'.
	self compileFixtureMethodSource: 'stringConcatenationProbe: aString

	^ ''before '' , aString , '' after'''.

	self assert: (self selectorsHitBy: MCPStringConcatenationRule) equals: (Set with: #stringConcatenationProbe:)
]

{ #category : 'tests' }
MCPToolRunCritiquesTest >> testLeavesIndexedLookupAlone [
	"A sequenceable collection has no at:ifPresent:."

	self compileFixtureMethodSource: 'indexedLookupProbe: aCollection

	(aCollection at: 1 ifAbsent: [ nil ]) ifNotNil: [ :first | first printString ]'.
	self compileFixtureMethodSource: 'keyedLookupProbe: aDictionary

	(aDictionary at: #name ifAbsent: [ nil ]) ifNotNil: [ :name | name printString ]'.

	self assert: (self selectorsHitBy: MCPDictionaryAtIfPresentRule) equals: (Set with: #keyedLookupProbe:)
]

{ #category : 'tests' }
MCPToolRunCritiquesTest >> testLeavesNotEmptySentToAClassAlone [
	"notEmpty is a collection test. A class answering it is something else, and isNotEmpty is not what it means."

	self compileFixtureMethodSource: 'classReceiverProbe

	^ OrderedCollection notEmpty'.
	self compileFixtureMethodSource: 'selfReceiverProbe

	^ self notEmpty'.
	self compileFixtureMethodSource: 'collectionReceiverProbe: aCollection

	^ aCollection notEmpty'.

	self assert: (self selectorsHitBy: MCPIsNotEmptyRule) equals: (Set with: #collectionReceiverProbe:)
]

{ #category : 'tests' }
MCPToolRunCritiquesTest >> testLeavesOutAFalsePositiveTheManifestMarks [
	"Banning a critique for a method writes it in the package's manifest as a false positive, and no tool reports it there again."

	| builder |
	self withConcatenationRuleEnabled: true during: [
			self compileFixtureMethodSource: self concatenationSource.
			builder := self manifestBuilder.
			builder
				installFalsePositiveOf: MCPStringConcatenationRule uniqueIdentifierName
				version: MCPStringConcatenationRule identifierMinorVersionNumber.
			builder
				addFalsePositive: self fixtureClass >> #concatenationProbe:
				of: MCPStringConcatenationRule uniqueIdentifierName
				version: MCPStringConcatenationRule identifierMinorVersionNumber.
			self assertEmpty: (self concatenationHitsNamingTheRule: true).
			self deny: self compileReportsConcatenation ]
]

{ #category : 'tests' }
MCPToolRunCritiquesTest >> testLeavesOutAFalsePositiveTheManifestMarksForAClass [
	"A ban on a class holds for its methods, as it does in Renraku."

	| builder |
	self withConcatenationRuleEnabled: true during: [
			self compileFixtureMethodSource: self concatenationSource.
			builder := self manifestBuilder.
			builder
				installFalsePositiveOf: MCPStringConcatenationRule uniqueIdentifierName
				version: MCPStringConcatenationRule identifierMinorVersionNumber.
			builder
				addFalsePositive: self fixtureClass
				of: MCPStringConcatenationRule uniqueIdentifierName
				version: MCPStringConcatenationRule identifierMinorVersionNumber.
			self assertEmpty: (self concatenationHitsNamingTheRule: true).
			self deny: self compileReportsConcatenation ]
]

{ #category : 'tests' }
MCPToolRunCritiquesTest >> testLeavesOutARuleTheImageHasOff [
	"Turning a rule off, or banning it for the image or every image, turns it off for agents too. A caller that names it still gets it."

	self withConcatenationRuleEnabled: false during: [
			self deny: self compileReportsConcatenation.
			self assertEmpty: (self concatenationHitsNamingTheRule: false).
			self denyEmpty: (self concatenationHitsNamingTheRule: true) ]
]

{ #category : 'tests' }
MCPToolRunCritiquesTest >> testLeavesOutARuleThePackageRejects [
	"Renraku's live critiques do not read rejectRules, but the critique browser does, and so does MCP."

	self withConcatenationRuleEnabled: true during: [
			self compileFixtureMethodSource: self concatenationSource.
			self manifestBuilder addRejectRule: MCPStringConcatenationRule uniqueIdentifierName.
			self assertEmpty: (self concatenationHitsNamingTheRule: true).
			self deny: self compileReportsConcatenation ]
]

{ #category : 'tests' }
MCPToolRunCritiquesTest >> testLiftsOnlyWhatStaysReadable [
	"Lifting a send whose arguments are blocks leaves blocks inside a conditional, and lifting a return out of an assignment does not parse."

	self compileFixtureMethodSource: 'commonSendProbe: aBoolean

	aBoolean ifTrue: [ self inform: ''yes'' ] ifFalse: [ self inform: ''no'' ]'.
	self compileFixtureMethodSource: 'commonReturnProbe: aBoolean

	aBoolean ifTrue: [ ^ 1 ] ifFalse: [ ^ 2 ]'.
	self compileFixtureMethodSource: 'blockArgumentProbe: aBoolean

	aBoolean ifTrue: [ self in: [ :me | me ] ] ifFalse: [ self in: [ :me | me printString ] ]'.
	self compileFixtureMethodSource: 'assignedReturnProbe: aBoolean

	| value |
	value := aBoolean ifTrue: [ ^ 1 ] ifFalse: [ ^ 2 ].
	^ value'.

	self assert: (self selectorsHitBy: MCPLiftCommonSendRule) equals: (Set with: #commonSendProbe: with: #commonReturnProbe:)
]

{ #category : 'tests' }
MCPToolRunCritiquesTest >> testMCPRulesAnswerOnlyAnAgent [
	"The browser and Iceberg critique as Renraku does, outside MCPAgentCritiquing, so MCP's rules say nothing there."

	| isConcatenation method |
	isConcatenation := [ :each | each rule class = MCPStringConcatenationRule ].
	self withConcatenationRuleEnabled: true during: [
			self compileFixtureMethodSource: self concatenationSource.
			method := self fixtureClass >> #concatenationProbe:.
			self deny: (method critiques anySatisfy: isConcatenation).
			self assert: ((MCPAgentCritiquing value: true during: [ method critiques ]) anySatisfy: isConcatenation).
			self assert: self compileReportsConcatenation.
			self denyEmpty: (self concatenationHitsNamingTheRule: false) ]
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
MCPToolRunCritiquesTest >> testPrintsOnlyWhereNothingReadsTheWrite [
	"nextPutAll: answers what it wrote and print: the stream, and a print: inside a chain of << needs parentheses."

	self compileFixtureMethodSource: 'statementProbe: aStream

	aStream nextPutAll: 42 printString'.
	self compileFixtureMethodSource: 'cascadeProbe: aStream

	aStream
		nextPutAll: 42 printString;
		cr'.
	self compileFixtureMethodSource: 'chainProbe: aStream

	aStream << ''answer: '' << 42 printString'.
	self compileFixtureMethodSource: 'answeredProbe: aStream

	^ aStream nextPutAll: 42 printString'.

	self assert: (self selectorsHitBy: MCPPrintOnStreamRule) equals: (Set with: #statementProbe: with: #cascadeProbe:)
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
MCPToolRunCritiquesTest >> testRunsARuleThePackageForces [
	"A manifest's forcedRules run on its package though the image has them off."

	self withConcatenationRuleEnabled: false during: [
			self compileFixtureMethodSource: self concatenationSource.
			self manifestBuilder.
			self
				ensureMethodSource: 'forcedRules ^ #( #MCPStringConcatenationRule )'
				protocol: 'code-critics'
				on: self fixtureClass package packageManifestOrNil class.
			self assert: self compileReportsConcatenation.
			self denyEmpty: (self concatenationHitsNamingTheRule: false) ]
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

{ #category : 'private' }
MCPToolRunCritiquesTest >> withConcatenationRuleEnabled: aBoolean during: aBlock [

	| previous |
	previous := MCPStringConcatenationRule enabled.
	MCPStringConcatenationRule enabled: aBoolean.
	aBlock ensure: [ MCPStringConcatenationRule enabled: previous ]
]
