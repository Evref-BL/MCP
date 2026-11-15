"
Tests method creation and update tools, including critique handling.
"
Class {
	#name : 'MCPToolMethodMutationTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private - calling' }
MCPToolMethodMutationTest >> aroundToolCall: aBlock [

	^ self withoutEpiceaDuring: aBlock
]

{ #category : 'private' }
MCPToolMethodMutationTest >> assertCompileForClass: aClass methodSource: aMethodSource protocol: aProtocol returnsSingleCritiqueRuleClass: aRuleClassName titledLike: aSubstring [

	| critique critiques data result |
	result := self callToolWith: (self
			           compileArgumentsForClass: aClass
			           classSide: false
			           methodSource: aMethodSource
			           protocol: aProtocol).
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	critiques := data at: #critiques.
	self assert: critiques class equals: Array.
	self assert: critiques size equals: 1.
	critique := critiques first.
	self assert: (critique at: #ruleClass) equals: aRuleClassName.
	self assert: ((critique at: #title) includesSubstring: aSubstring).
	self assert: (critique at: #description) isString.
	self deny: (critique at: #description) isEmpty
]

{ #category : 'private' }
MCPToolMethodMutationTest >> assertHeaderOf: aSource side: aSideOrNil isRefusedSaying: aText [

	| error result |
	result := self compileSource: aSource into: MCPToolMethodMutationTestTarget name side: aSideOrNil.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'MethodSourceHeader'.
	self assert: (error at: #header) equals: aSource lines first trimBoth.
	self assert: (error at: #class) equals: MCPToolMethodMutationTestTarget name.
	self assert: (self textFrom: result) equals: aText.
	#( #headerProbe #headerProbe:with: #headerProbe: #= #'>=' ) do: [ :each |
			self deny: (MCPToolMethodMutationTestTarget includesSelector: each).
			self deny: (MCPToolMethodMutationTestTarget classSide includesSelector: each) ].
	^ error
]

{ #category : 'private' }
MCPToolMethodMutationTest >> assertSuccessDataHasMethodShape: data [

	#( selector class package isExtension protocol source side action updateAction oldSelector newSelector
	   oldProtocol newProtocol ) do: [ :key | self deny: (data includesKey: key) ].
	(data includesKey: #changeKind) ifTrue: [ self assert: (#( 'created' 'replaced' ) includes: (data at: #changeKind)) ]
]

{ #category : 'private - calling' }
MCPToolMethodMutationTest >> callToolWith: someArguments [

	| arguments request result tool toolClass |
	arguments := someArguments copy.
	arguments removeKey: #action ifAbsent: [ ].
	toolClass := (arguments includesKey: #source)
		             ifTrue: [ MCPToolCompileMethod ]
		             ifFalse: [ MCPToolUpdateMethod ].
	tool := toolClass new.
	request := tool requestFromToolCallArguments: arguments.
	result := tool executeWithRequest: request.
	^ result asJRPCJSON
]

{ #category : 'private' }
MCPToolMethodMutationTest >> classChangeArguments [

	^ {
		  (#action -> 'update').
		  (#class -> MCPToolMethodMutationTestTarget name).
		  (#side -> 'class').
		  (#selector -> self classProtocolSelector asString).
		  (#protocol -> 'instance creation') } asDictionary
]

{ #category : 'private' }
MCPToolMethodMutationTest >> classProtocolSelector [

	^ #classProtocolTarget
]

{ #category : 'private' }
MCPToolMethodMutationTest >> classRenameArguments [

	^ {
		  (#action -> 'update').
		  (#class -> MCPToolMethodMutationTestTarget name).
		  (#side -> 'class').
		  (#selector -> self classSelector asString).
		  (#newSelector -> self renamedClassSelector asString) } asDictionary
]

{ #category : 'private' }
MCPToolMethodMutationTest >> classSelector [

	^ ('build' , 'Value:') asSymbol
]

{ #category : 'private' }
MCPToolMethodMutationTest >> compileArgumentsForClass: aClass classSide: aBoolean methodSource: aMethodSource protocol: aProtocol [

	^ {
		  (#action -> 'create').
		  (#class -> aClass name).
		  (#side -> (aBoolean ifTrue: [ 'class' ] ifFalse: [ 'instance' ])).
		  (#source -> aMethodSource).
		  (#protocol -> aProtocol) } asDictionary
]

{ #category : 'private - calling' }
MCPToolMethodMutationTest >> compileSource: aSource into: aClassName side: aSideOrNil [
	"method_compile as a caller writes it, with side left out when aSideOrNil is nil."

	| arguments |
	arguments := Dictionary new.
	arguments at: #class put: aClassName.
	arguments at: #source put: aSource.
	arguments at: #protocol put: 'tests'.
	aSideOrNil ifNotNil: [ arguments at: #side put: aSideOrNil ].
	^ self callToolNamed: 'method_compile' withArguments: arguments
]

{ #category : 'private' }
MCPToolMethodMutationTest >> compileProbe: aMethodSource [
	"Compile aMethodSource into the mutation target under tests, answering the result."

	^ self callToolWith: (self
			   compileArgumentsForClass: MCPToolMethodMutationTestTarget
			   classSide: false
			   methodSource: aMethodSource
			   protocol: 'tests')
]

{ #category : 'private' }
MCPToolMethodMutationTest >> createRenameScopeFixtureClassNamed: aClassName packageName: aPackageName [

	self withoutEpiceaDuring: [
			| builder |
			self packageOrganizer ensurePackage: aPackageName.
			builder := Object << aClassName asSymbol.
			builder package: aPackageName.
			builder install ]
]

{ #category : 'private' }
MCPToolMethodMutationTest >> droppedHeaderWarning [

	^ 'The source began with the method''s reference, which was dropped: a method''s source starts with its selector line.'
]

{ #category : 'private' }
MCPToolMethodMutationTest >> extensionChangeArguments [

	^ {
		  (#action -> 'update').
		  (#class -> MCPToolMethodMutationTestTarget name).
		  (#side -> 'instance').
		  (#selector -> self extensionProtocolSelector asString).
		  (#protocol -> 'tests') } asDictionary
]

{ #category : 'private' }
MCPToolMethodMutationTest >> extensionProtocolSelector [
	"Generated rather than committed: a test that rewrites a versioned fixture leaves its package modified, though the source it ends with is the source it started with."

	^ #generatedExtensionProtocolTarget
]

{ #category : 'private' }
MCPToolMethodMutationTest >> inferenceOutcomeSelectors [
	"Every selector the inference tests can leave behind, so setUp can clear them."

	^ {
		  ('probeMerge:' , 'and:') asSymbol.
		  ('probeCombine:with:' , 'extra:') asSymbol.
		  'probeCombine:' asSymbol }
]

{ #category : 'private' }
MCPToolMethodMutationTest >> inferenceSelector [
	"Built rather than written: a selector rename rewrites symbol literals across the image, this accessor included."

	^ ('probeCombine:' , 'with:') asSymbol
]

{ #category : 'private' }
MCPToolMethodMutationTest >> instanceChangeArguments [

	^ {
		  (#action -> 'update').
		  (#class -> MCPToolMethodMutationTestTarget name).
		  (#side -> 'instance').
		  (#selector -> self instanceProtocolSelector asString).
		  (#protocol -> 'accessing') } asDictionary
]

{ #category : 'private' }
MCPToolMethodMutationTest >> instanceProtocolSelector [
	"Built rather than written, like the other rename targets: a selector rename rewrites symbol literals across the image, this accessor included."

	^ ('instanceProtocol' , 'Target') asSymbol
]

{ #category : 'private' }
MCPToolMethodMutationTest >> instanceRenameArguments [

	^ {
		  (#action -> 'update').
		  (#class -> MCPToolMethodMutationTestTarget name).
		  (#side -> 'instance').
		  (#selector -> self instanceSelector asString).
		  (#newSelector -> self renamedInstanceSelector asString).
		  (#permutation -> #( 2 1 )) } asDictionary
]

{ #category : 'private' }
MCPToolMethodMutationTest >> instanceSelector [

	^ ('combine:' , 'with:') asSymbol
]

{ #category : 'private' }
MCPToolMethodMutationTest >> mcpPackageNames [

	^ #( 'BaselineOfMCP' 'MCP' 'MCP-UI' 'MCP-UI-Tests' 'MCP-Tests' 'MCP-Tests-Resources' 'MCP-Tests-Resources-Extensions' )
]

{ #category : 'private' }
MCPToolMethodMutationTest >> methodDefinitionsInPackageNamed: packageName [

	^ (MCPackage named: packageName) snapshot definitions select: [ :definition | definition isMethodDefinition ]
]

{ #category : 'private' }
MCPToolMethodMutationTest >> methodSourceLineFeedOffenderNameFor: aMethodDefinition [

	^ aMethodDefinition className asString , (aMethodDefinition classIsMeta
		   ifTrue: [ ' class>>' ]
		   ifFalse: [ '>>' ]) , aMethodDefinition selector asString
]

{ #category : 'private' }
MCPToolMethodMutationTest >> methodSourceLineFeedOffenders [

	| offenders |
	offenders := Array streamContents: [ :stream |
			             self mcpPackageNames do: [ :packageName |
				             self methodSourceLineFeedOffendersInPackageNamed: packageName do: [ :offender | stream nextPut: offender ] ] ].
	^ offenders sort
]

{ #category : 'private' }
MCPToolMethodMutationTest >> methodSourceLineFeedOffendersInPackageNamed: packageName do: aBlock [

	(self methodDefinitionsInPackageNamed: packageName) do: [ :definition |
		(definition source includes: Character lf) ifTrue: [ aBlock value: (self methodSourceLineFeedOffenderNameFor: definition) ] ]
]

{ #category : 'private' }
MCPToolMethodMutationTest >> removeHeaderProbes [

	#( #headerProbe #headerProbe: #headerProbeTwo #HeaderProbe #'>=' #> ) do: [ :each |
			self removeSelector: each from: MCPToolMethodMutationTestTarget.
			self removeSelector: each from: MCPToolMethodMutationTestTarget classSide ]
]

{ #category : 'private' }
MCPToolMethodMutationTest >> renamedClassSelector [

	^ ('make' , 'Value:') asSymbol
]

{ #category : 'private' }
MCPToolMethodMutationTest >> renamedInstanceProtocolSelector [
	"Built rather than written, like the other rename targets: a selector rename rewrites symbol literals across the image, this accessor included."

	^ ('renamedInstance' , 'ProtocolTarget') asSymbol
]

{ #category : 'private' }
MCPToolMethodMutationTest >> renamedInstanceSelector [

	^ ('with:' , 'combine:') asSymbol
]

{ #category : 'private' }
MCPToolMethodMutationTest >> restoreFixtureMethods [

	self removeSelector: #instanceAnswer from: MCPToolMethodMutationTestTarget.
	self removeSelector: #classAnswer from: MCPToolMethodMutationTestTarget classSide.
	self removeSelector: #multilineAnswer from: MCPToolMethodMutationTestTarget.
	self removeSelector: #multilineStringAnswer from: MCPToolMethodMutationTestTarget.
	self removeSelector: #uglyAnswer from: MCPToolMethodMutationTestTarget.
	self removeSelector: self instanceSelector from: MCPToolMethodMutationTestTarget.
	self removeSelector: self renamedInstanceSelector from: MCPToolMethodMutationTestTarget.
	self removeSelector: self classSelector from: MCPToolMethodMutationTestTarget classSide.
	self removeSelector: self renamedClassSelector from: MCPToolMethodMutationTestTarget classSide.
	self removeSelector: self instanceProtocolSelector from: MCPToolMethodMutationTestTarget.
	self removeSelector: self renamedInstanceProtocolSelector from: MCPToolMethodMutationTestTarget.
	self removeSelector: self classProtocolSelector from: MCPToolMethodMutationTestTarget classSide.
	self removeSelector: self extensionProtocolSelector from: MCPToolMethodMutationTestTarget.
	self removeSelector: self inferenceSelector from: MCPToolMethodMutationTestTarget.
	self inferenceOutcomeSelectors do: [ :each | self removeSelector: each from: MCPToolMethodMutationTestTarget ].
	self removeSelector: #callInstanceTarget from: MCPToolMethodMutationTestSender.
	self removeSelector: #callClassTarget from: MCPToolMethodMutationTestSender.
	self
		ensureMethodSource: 'combine: first with: second
	^ first , ''-'' , second'
		protocol: 'tests'
		on: MCPToolMethodMutationTestTarget.
	self
		ensureMethodSource: 'probeCombine: first with: second
	^ first , ''-'' , second'
		protocol: 'tests'
		on: MCPToolMethodMutationTestTarget.
	self
		ensureMethodSource: 'buildValue: aString
	^ ''Class-'' , aString'
		protocol: 'tests'
		on: MCPToolMethodMutationTestTarget classSide.
	self
		ensureMethodSource: 'instanceProtocolTarget
	^ 41'
		protocol: 'tests'
		on: MCPToolMethodMutationTestTarget.
	self
		ensureMethodSource: 'classProtocolTarget
	^ 7'
		protocol: 'tests'
		on: MCPToolMethodMutationTestTarget classSide.
	self
		ensureMethodSource: 'generatedExtensionProtocolTarget
	^ 99'
		protocol: self generatedExtensionProtocol
		on: MCPToolMethodMutationTestTarget.
	self
		ensureMethodSource: 'callInstanceTarget
	^ MCPToolMethodMutationTestTarget new combine: ''first'' with: ''second'''
		protocol: 'tests'
		on: MCPToolMethodMutationTestSender.
	self
		ensureMethodSource: 'callClassTarget
	^ MCPToolMethodMutationTestTarget buildValue: ''value'''
		protocol: 'tests'
		on: MCPToolMethodMutationTestSender
]

{ #category : 'private' }
MCPToolMethodMutationTest >> restoreTraitFixtureMethods [
	"The force test installs a method of its own over the copy MCPToolMethodSearchTraitUser got from its trait. Removing that one and setting the composition again installs the copy."

	| user |
	user := MCPToolMethodSearchTraitUser.
	((user includesSelector: #mcpTraitFixtureValue) and: [ (user >> #mcpTraitFixtureValue) isFromTrait ]) ifTrue: [ ^ self ].
	self withoutEpiceaDuring: [
			user removeSelector: #mcpTraitFixtureValue.
			user setTraitComposition: user traitComposition ]
]

{ #category : 'running' }
MCPToolMethodMutationTest >> setUp [

	super setUp.
	self removeSelector: #combine:with:separator: from: MCPToolMethodMutationTestTarget.
	self removeSelector: #buildValue:prefix: from: MCPToolMethodMutationTestTarget classSide.
	self restoreFixtureMethods.
	self restoreTraitFixtureMethods
]

{ #category : 'running' }
MCPToolMethodMutationTest >> tearDown [

	self removeSelector: #combine:with:separator: from: MCPToolMethodMutationTestTarget.
	self removeSelector: #buildValue:prefix: from: MCPToolMethodMutationTestTarget classSide.
	self restoreFixtureMethods.
	self restoreTraitFixtureMethods.
	self removeSelector: self extensionProtocolSelector from: MCPToolMethodMutationTestTarget.
	self removeGeneratedPackagesIfEmpty.
	super tearDown
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testABinaryHeaderKeepsItsSelector [
	"A binary selector may begin with >, as >= does. Only the header's separator, and the # after it, is dropped, never the selector's own >, so the method compiled is the one the header names and not = or a unary method named after the argument."

	| result |
	[
		result := self
			          compileSource: 'MCPToolMethodMutationTestTarget >> >= other
	^ true'
			          into: MCPToolMethodMutationTestTarget name
			          side: nil.
		self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
		self assert: (self summaryFrom: result) equals: 'Created MCPToolMethodMutationTestTarget>>>=.'.
		self assert: (self warningsFrom: result) first equals: self droppedHeaderWarning.
		self assert: MCPToolMethodMutationTestTarget new >= 1.
		self deny: (MCPToolMethodMutationTestTarget includesSelector: #=).

		result := self
			          compileSource: 'MCPToolMethodMutationTestTarget>>#> other
	^ false'
			          into: MCPToolMethodMutationTestTarget name
			          side: nil.
		self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
		self assert: (self summaryFrom: result) equals: 'Created MCPToolMethodMutationTestTarget>>>.'.
		self deny: MCPToolMethodMutationTestTarget new > 1.
		self deny: (MCPToolMethodMutationTestTarget includesSelector: #other) ] ensure: [ self removeHeaderProbes ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testAHeaderWithNothingAfterItIsRefused [
	"A source that is only a method's reference names the method and writes none of it. Dropping the header would compile an empty method, replacing the body of one that exists, so it is refused and nothing is compiled. A body on the header's own line is a body."

	| error result |
	[
		self ensureMethodSource: 'headerProbe ^ 1' protocol: 'tests' on: MCPToolMethodMutationTestTarget.
		result := self
			          compileSource: 'MCPToolMethodMutationTestTarget >> #headerProbe'
			          into: MCPToolMethodMutationTestTarget name
			          side: nil.
		error := self errorFrom: result.
		self assert: (result at: #isError).
		self assert: (error at: #errorCode) equals: 'MethodSourceHeader'.
		self assert: (error at: #header) equals: 'MCPToolMethodMutationTestTarget >> #headerProbe'.
		self
			assert: (self textFrom: result)
			equals:
			'The source holds only MCPToolMethodMutationTestTarget >> #headerProbe, a method''s reference with no body. Write the method itself: its selector line, headerProbe, then its body.'.
		self assert: (MCPToolMethodMutationTestTarget new perform: #headerProbe) equals: 1.

		result := self
			          compileSource: 'MCPToolMethodMutationTestTarget >> headerProbe ^ 2'
			          into: MCPToolMethodMutationTestTarget name
			          side: nil.
		self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
		self assert: (MCPToolMethodMutationTestTarget new perform: #headerProbe) equals: 2 ] ensure: [ self removeHeaderProbes ].
	self
		assertHeaderOf: 'MCPToolMethodMutationTestTarget class>>headerProbe: a
	'
		side: nil
		isRefusedSaying:
		'The source holds only MCPToolMethodMutationTestTarget class>>headerProbe: a, a method''s reference with no body. Write the method itself: its selector line, headerProbe: a, then its body, and pass side class.'.
	self
		assertHeaderOf: 'MCPToolMethodMutationTestTarget>>#headerProbe:with:'
		side: nil
		isRefusedSaying:
		'The source holds only MCPToolMethodMutationTestTarget>>#headerProbe:with:, a method''s reference with no body. Write the method itself: its selector line, the selector with its argument names, then its body.'
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testAddArgumentWithoutPermutationMatchesArgumentsByName [

	| result widened |
	widened := self inferenceOutcomeSelectors second.
	result := self callToolWith: {
			          (#class -> MCPToolMethodMutationTestTarget name).
			          (#selector -> self inferenceSelector asString).
			          (#newSelector -> widened asString).
			          (#arguments -> #( 'first' 'second' 'extra' )).
			          (#argumentValueExpressions -> #( '''z''' )) } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (MCPToolMethodMutationTestTarget includesSelector: widened).
	self assert: (MCPToolMethodMutationTestTarget new perform: widened withArguments: #( 'a' 'b' 'c' )) equals: 'a-b'
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testAddArgumentsUpdatesClassSideSenders [

	| data result senderSource |
	result := self callToolWith: {
			          (#action -> 'update').
			          (#class -> MCPToolMethodMutationTestTarget name).
			          (#side -> 'class').
			          (#selector -> 'buildValue:').
			          (#newSelector -> 'buildValue:prefix:').
			          (#arguments -> #( 'aString' 'prefix' )).
			          (#argumentValueExpressions -> #( 'nil' )) } asDictionary.
	data := self dataFrom: result.
	senderSource := (MCPToolMethodMutationTestSender >> #callClassTarget) sourceCode.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (MCPToolMethodMutationTestTarget classSide includesSelector: #buildValue:prefix:).
	self assert: (senderSource includesSubstring: 'prefix: nil').
	self assert: MCPToolMethodMutationTestSender new callClassTarget equals: 'Class-value'
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testAddArgumentsUpdatesSendersAndReportsAction [

	| data result senderSource targetSource |
	result := self callToolWith: {
			          (#action -> 'update').
			          (#class -> MCPToolMethodMutationTestTarget name).
			          (#side -> 'instance').
			          (#selector -> 'combine:with:').
			          (#newSelector -> 'combine:with:separator:').
			          (#arguments -> #( 'first' 'second' 'separator' )).
			          (#argumentValueExpressions -> (Array with: (String streamContents: [ :stream |
						             stream
							             nextPut: $';
							             nextPut: $|;
							             nextPut: $' ]))) } asDictionary.
	data := self dataFrom: result.
	targetSource := (MCPToolMethodMutationTestTarget >> #combine:with:separator:) sourceCode.
	senderSource := (MCPToolMethodMutationTestSender >> #callInstanceTarget) sourceCode.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (targetSource includesSubstring: 'separator: separator').
	self assert: (senderSource includesSubstring: 'separator: ''|''').
	self assert: MCPToolMethodMutationTestSender new callInstanceTarget equals: 'first-second'
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testBatchCompileWarnsOnlyTheMethodsWithoutProtocol [
	"A replaced method keeps its protocol, so a warning only some methods of a batch carry stays with them."

	| lines result selector |
	selector := #unclassifiedProbe.
	self removeSelector: selector from: MCPToolMethodMutationTestTarget.
	[
		result := self callToolNamed: 'method_compile' withArguments: {
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#source -> #( 'instanceProtocolTarget

	^ 41' 'unclassifiedProbe ^ 3' )) } asDictionary.
		self deny: (result at: #isError ifAbsent: [ false ]).
		lines := ((result at: #content) first at: #text) lines.
		self deny: (lines anySatisfy: [ :each | each beginsWith: 'Warning for each' ]).
		self assert: ((lines at: (lines indexOf: 'Created MCPToolMethodMutationTestTarget>>unclassifiedProbe.') + 1) beginsWith:
				 'Warning: No protocol was named') ] ensure: [ self removeSelector: selector from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testBatchCompileWithoutProtocolWarnsOnce [
	"Batching is the point of passing several sources, so a warning each method carries is said once rather than once per method."

	| contentText result selectors |
	selectors := #( #unclassifiedProbeOne #unclassifiedProbeTwo ).
	selectors do: [ :each | self removeSelector: each from: MCPToolMethodMutationTestTarget ].
	[
		result := self callToolNamed: 'method_compile' withArguments: {
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#source -> #( 'unclassifiedProbeOne ^ 1' 'unclassifiedProbeTwo ^ 2' )) } asDictionary.
		self deny: (result at: #isError ifAbsent: [ false ]).
		contentText := (result at: #content) first at: #text.
		self assert: (contentText allRangesOfSubstring: 'No protocol was named') size equals: 1.
		self assert: (contentText lines second beginsWith: 'Warning for each: No protocol was named').
		((self dataFrom: result) at: #results) do: [ :each | self assert: (each at: #warnings) size equals: 1 ] ] ensure: [
		selectors do: [ :each | self removeSelector: each from: MCPToolMethodMutationTestTarget ] ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testBlockedCompileNamesTheCritique [
	"A compile a critique blocks is refused with the critique in its text, its lines counting the source as sent, and what to do next."

	| error lines result title |
	self removeSelector: #deadBlockProbe from: MCPToolMethodMutationTestTarget.
	result := self compileProbe: 'deadBlockProbe [ self error: ''never run'' ]'.
	error := self errorFrom: result.
	title := (error at: #critiques) first at: #title.
	lines := (self textOf: result) lines.
	self assert: (lines first: 4) asArray equals: {
			'Did not compile MCPToolMethodMutationTestTarget>>deadBlockProbe, because a critique blocks compiling it:'.
			('line 1: ' , title).
			'  [ self error: ''never run'' ]'.
			'Correct the source and compile it again.' }.
	self assert: (error at: #howToProceed) equals: 'Correct the source and compile it again.'.
	result := self callToolWith: (self
			           compileArgumentsForClass: MCPToolMethodMutationTestTarget
			           classSide: true
			           methodSource: 'deadBlockProbe
	[ 1 ].
	[ 2 ]'
			           protocol: 'tests').
	lines := (self textOf: result) lines.
	self
		assert: lines first
		equals: 'Did not compile MCPToolMethodMutationTestTarget class>>deadBlockProbe, because 2 critiques block compiling it:'.
	self
		assert: (lines select: [ :each | each beginsWith: 'line ' ] thenCollect: [ :each | each copyUpTo: $: ])
		equals: #( 'line 2' 'line 3' ).
	self deny: (MCPToolMethodMutationTestTarget includesSelector: #deadBlockProbe).
	self deny: (MCPToolMethodMutationTestTarget classSide includesSelector: #deadBlockProbe)
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testBodyErrorAfterAHeaderIsReportedOnItsOwnLine [
	"The header is replaced by its selector line and the rest is kept as it is, so the lines keep their numbers."

	| error result |
	[
		result := self
			          compileSource: 'MCPToolMethodMutationTestTarget >> #headerProbe
	^ 1 +'
			          into: MCPToolMethodMutationTestTarget name
			          side: nil.
		error := self errorFrom: result.
		self assert: (result at: #isError).
		self assert: (error at: #errorCode) equals: 'CompileSyntaxError'.
		self assert: (error at: #line) equals: 2.
		self assert: (error at: #sourceLine) equals: '	^ 1 +'.
		self deny: (MCPToolMethodMutationTestTarget includesSelector: #headerProbe) ] ensure: [ self removeHeaderProbes ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testChangeProtocolReturnsStructuredErrorWhenMethodIsMissing [

	| error result structured |
	self removeSelector: self instanceProtocolSelector from: MCPToolMethodMutationTestTarget.
	result := self callToolWith: self instanceChangeArguments.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'changeProtocol'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'MethodNotFound'.
	self assert: (error at: #class) equals: MCPToolMethodMutationTestTarget name.
	self assert: (error at: #side) equals: 'instance'.
	self assert: (error at: #selector) equals: self instanceProtocolSelector asString.
	self assert: (error at: #protocol) equals: 'accessing'.
	self
		assert: error keys asSet
		equals: #( action updateAction errorClass errorCode message class side selector protocol ) asSet
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testChangesClassSideMethodProtocol [

	| data result |
	result := self callToolWith: self classChangeArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: (MCPToolMethodMutationTestTarget classSide >> self classProtocolSelector) protocolName asString
		equals: 'instance creation'.
	self assertSuccessDataHasMethodShape: data.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testChangesInstanceSideMethodProtocol [

	| data result |
	result := self callToolWith: self instanceChangeArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (MCPToolMethodMutationTestTarget >> self instanceProtocolSelector) protocolName asString equals: 'accessing'.
	self assertSuccessDataHasMethodShape: data.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testChangingExtensionMethodProtocolUpdatesPackageMetadata [

	| data result |
	result := self callToolWith: self extensionChangeArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (MCPToolMethodMutationTestTarget >> self extensionProtocolSelector) protocolName asString equals: 'tests'.
	self assertSuccessDataHasMethodShape: data
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCollectionStyleCritiquesProvideAutomaticChanges [

	| samples |
	samples := {
		           {
			           #nilOnlyConditionalProbe:.
			           'nilOnlyConditionalProbe: value ^ value ifNil: [ nil ] ifNotNil: [ :present | present asString ]'.
			           MCPNilOnlyConditionalRule }.
		           {
			           #dictionaryAtIfPresentProbe:.
			           'dictionaryAtIfPresentProbe: dictionary | result | result := OrderedCollection new. (dictionary at: #name ifAbsent: [ nil ]) ifNotNil: [ :value | result add: value ]. ^ result'.
			           MCPDictionaryAtIfPresentRule }.
		           {
			           #selectSizeProbe:.
			           'selectSizeProbe: collection ^ (collection select: [ :each | each odd ]) size'.
			           MCPSelectSizeCountRule }.
		           {
			           #filteredEmptinessProbe:.
			           'filteredEmptinessProbe: collection ^ (collection select: [ :each | each odd ]) isEmpty'.
			           MCPFilteredEmptinessRule }.
		           {
			           #filterThenCollectProbe:.
			           'filterThenCollectProbe: collection ^ (collection select: [ :each | each odd ]) collect: [ :each | each asString ]'.
			           MCPFilterThenCollectRule }.
		           {
			           #collectionThenDoProbe:.
			           'collectionThenDoProbe: collection | sum | sum := 0. (collection select: [ :each | each odd ]) do: [ :each | sum := sum + each ]. ^ sum'.
			           MCPCollectionThenDoRule }.
		           {
			           #collectConversionProbe:.
			           'collectConversionProbe: collection ^ (collection collect: [ :each | each asString ]) asArray'.
			           MCPCollectConversionRule }.
		           {
			           #sortedCollectionConversionProbe:.
			           'sortedCollectionConversionProbe: collection ^ collection asSortedCollection asArray'.
			           MCPSortedCollectionConversionRule }.
		           {
			           #stringConcatenationProbe:.
			           'stringConcatenationProbe: aName ^ ''before '' , aName , '' after'''.
			           MCPStringConcatenationRule }.
		           {
			           #streamWriteCascadeProbe:.
			           'streamWriteCascadeProbe: aStream aStream << ''first''; << ''second'''.
			           MCPStreamWriteCascadeRule }.
		           {
			           #isNotEmptyProbe:.
			           'isNotEmptyProbe: collection ^ collection notEmpty'.
			           MCPIsNotEmptyRule }.
		           {
			           #isNotNilProbe:.
			           'isNotNilProbe: anObject ^ anObject notNil'.
			           MCPIsNotNilRule }.
		           {
			           #denyProbe:.
			           'denyProbe: aTest aTest assert: aTest isEmpty not'.
			           MCPDenyRule }.
		           {
			           #liftCommonSendProbe:.
			           'liftCommonSendProbe: aBoolean aBoolean ifTrue: [ self inform: ''yes'' ] ifFalse: [ self inform: ''no'' ]'.
			           MCPLiftCommonSendRule }.
		           {
			           #printOnStreamProbe:.
			           'printOnStreamProbe: aStream aStream nextPutAll: 42 printString'.
			           MCPPrintOnStreamRule }.
		           {
			           #includesKeyProbe:.
			           'includesKeyProbe: dictionary ^ dictionary keys includes: #name'.
			           MCPIncludesKeyRule }.
		           {
			           #detectIfFoundProbe:.
			           'detectIfFoundProbe: collection (collection detect: [ :each | each odd ] ifNone: [ nil ]) ifNotNil: [ :found | found printString ]'.
			           MCPDetectIfFoundRule } }.
	samples do: [ :sample |
			| change critique method ruleClass selector source |
			selector := sample first.
			source := sample second.
			ruleClass := sample third.
			self removeSelector: selector from: MCPToolGetMethodTestTarget.
			[
				self ensureMethodSource: source protocol: 'tests' on: MCPToolGetMethodTestTarget.
				method := MCPToolGetMethodTestTarget >> selector.
				critique := (MCPToolCompileMethod new critiquesOfMethod: method)
					            detect: [ :each | each rule class = ruleClass ]
					            ifNone: [ self fail: 'Expected critique from ' , ruleClass name ].
				self assert: critique providesChange.
				change := critique change.
				self assert: (change class name asString includesSubstring: 'AddMethodChange') ] ensure: [
				self removeSelector: selector from: MCPToolGetMethodTestTarget ] ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileAcceptsExplicitSelfReturnAsOnlyStatement [

	| critiques data result selector |
	selector := #noopSelfReturnProbe.
	self removeSelector: selector from: MCPToolMethodMutationTestTarget.
	[
		result := self callToolWith: (self
				           compileArgumentsForClass: MCPToolMethodMutationTestTarget
				           classSide: false
				           methodSource: 'noopSelfReturnProbe ^ self'
				           protocol: 'tests').
		self deny: (self resultIndicatesError: result).
		data := self dataFrom: result.
		critiques := data at: #critiques ifAbsent: [ #(  ) ].
		self assert: critiques equals: #(  ) ] ensure: [ self removeSelector: selector from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileAcceptsExplicitSelfReturnInBranch [

	| critiques data result selector target |
	selector := #selfReturnInBranchProbe:.
	self removeSelector: selector from: MCPToolMethodMutationTestTarget.
	[
		result := self callToolWith: (self
				           compileArgumentsForClass: MCPToolMethodMutationTestTarget
				           classSide: false
				           methodSource: 'selfReturnInBranchProbe: aBoolean aBoolean ifTrue: [ ^ self ]. ^ 1'
				           protocol: 'tests').
		self deny: (self resultIndicatesError: result).
		data := self dataFrom: result.
		critiques := data at: #critiques ifAbsent: [ #(  ) ].
		self assert: critiques equals: #(  ).
		target := MCPToolMethodMutationTestTarget new.
		self assert: (target selfReturnInBranchProbe: true) identicalTo: target.
		self assert: (target selfReturnInBranchProbe: false) equals: 1 ] ensure: [
		self removeSelector: selector from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileAllowsExplicitlyReturnedBlock [

	| result selector |
	selector := #returnedBlockProbe.
	self removeSelector: selector from: MCPToolMethodMutationTestTarget.
	[
		result := self callToolWith: (self
				           compileArgumentsForClass: MCPToolMethodMutationTestTarget
				           classSide: false
				           methodSource: 'returnedBlockProbe ^ [ 1 ]'
				           protocol: 'tests').
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: MCPToolMethodMutationTestTarget new returnedBlockProbe value equals: 1 ] ensure: [
		self removeSelector: selector from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileBlocksDeadBlockBeforeInstallation [

	| critique critiques error result selector |
	selector := #deadBlockProbe.
	self removeSelector: selector from: MCPToolMethodMutationTestTarget.
	result := self callToolWith: (self
			           compileArgumentsForClass: MCPToolMethodMutationTestTarget
			           classSide: false
			           methodSource: 'deadBlockProbe [ self error: ''never run'' ]'
			           protocol: 'tests').
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'CompileBlockedByCritiques'.
	critiques := error at: #critiques.
	self assert: critiques size equals: 1.
	critique := critiques first.
	self assert: (critique at: #ruleClass) equals: 'ReDeadBlockRule'.
	self deny: (MCPToolMethodMutationTestTarget includesSelector: selector)
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileCanReplaceMethodOnToolClass [

	| data method result |
	method := MCPHaltingTestTool >> #title.
	result := self callToolNamed: 'method_compile' withArguments: {
			          (#class -> MCPHaltingTestTool name).
			          (#source -> method sourceCode).
			          (#protocol -> method protocolName asString) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #changeKind) equals: 'replaced'
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileCritiqueQuotesTheStoredCode [
	"A method sent on one line is stored reformatted, its body from the third line; its critique counts the stored lines and quotes the stored code, which method_get shows."

	| critique result storedLines |
	self removeSelector: #storedCodeProbe from: MCPToolMethodMutationTestTarget.
	[
		result := self compileProbe: 'storedCodeProbe ^ True = true'.
		critique := ((self dataFrom: result) at: #critiques) first.
		storedLines := (MCPToolMethodMutationTestTarget >> #storedCodeProbe) sourceCode lines.
		self assert: (critique at: #line) equals: 3.
		self assert: ((storedLines at: 3) includesSubstring: 'True = true').
		self assert: (critique at: #code) equals: 'True'.
		self assert: ((self textOf: result) lines includes: '    True') ] ensure: [
		self removeSelector: #storedCodeProbe from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileCritiquesReadAsLines [
	"A critique reads as the line it starts on and what it found, under a label saying how lines are counted, never as character offsets of a source the caller does not see."

	| lines result |
	self removeSelector: #critiqueLinesProbe from: MCPToolMethodMutationTestTarget.
	[
		result := self compileProbe: 'critiqueLinesProbe ^ ''a'' , self printString , ''b'''.
		lines := (self textOf: result) lines.
		self assert: lines first equals: 'Created MCPToolMethodMutationTestTarget>>critiqueLinesProbe.'.
		self assert: lines second equals: 'critiques (line numbers count the method as stored; method_get shows it):'.
		self assert: ((lines at: 3) beginsWith: '  line 3: ').
		self deny: (lines anySatisfy: [ :each | each matchesRegex: '.*\d+-\d+.*' ]).
		self removeSelector: #critiqueLinesProbe from: MCPToolMethodMutationTestTarget.
		result := self compileProbe: 'critiqueLinesProbe ^ 1'.
		self deny: (self resultIndicatesError: result).
		self deny: ((self textOf: result) includesSubstring: 'critiques') ] ensure: [
		self removeSelector: #critiqueLinesProbe from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileDefaultsToInstanceSideWhenClassSideIsOmitted [

	| data result |
	result := self callToolWith: {
			          (#action -> 'create').
			          (#class -> MCPToolMethodMutationTestTarget name).
			          (#source -> 'instanceAnswer ^ 42').
			          (#protocol -> 'tests') } asDictionary.
	data := self dataFrom: result.
	self assert: MCPToolMethodMutationTestTarget new instanceAnswer equals: 42.
	self deny: (MCPToolMethodMutationTestTarget classSide includesSelector: #instanceAnswer).
	self assertSuccessDataHasMethodShape: data.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileIntoAClassWrittenWithItsSideCompilesOnTheClassSide [
	"Foo class names the class side, as Pharo prints it, whether side is left out or says the same."

	#( nil 'class' ) do: [ :side |
			| result |
			self removeHeaderProbes.
			[
				result := self compileSource: 'headerProbe ^ 1' into: 'MCPToolMethodMutationTestTarget class' side: side.
				self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
				self assert: (MCPToolMethodMutationTestTarget classSide includesSelector: #headerProbe).
				self deny: (MCPToolMethodMutationTestTarget includesSelector: #headerProbe).
				self assert: (self summaryFrom: result) equals: 'Created MCPToolMethodMutationTestTarget class>>headerProbe.' ] ensure: [
				self removeHeaderProbes ] ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileIntoAClassWrittenWithItsSideRefusesSideInstance [
	"The two arguments contradict each other, and guessing would put the method on the wrong side."

	| error result |
	[
		result := self compileSource: 'headerProbe ^ 1' into: 'MCPToolMethodMutationTestTarget class' side: 'instance'.
		error := self errorFrom: result.
		self assert: (result at: #isError).
		self assert: (error at: #errorCode) equals: 'ClassSideConflict'.
		self assert: (error at: #class) equals: 'MCPToolMethodMutationTestTarget'.
		self assert: (error at: #name) equals: 'MCPToolMethodMutationTestTarget class'.
		self assert: (error at: #side) equals: 'instance'.
		self
			assert: (self textFrom: result)
			equals:
			'MCPToolMethodMutationTestTarget class names the class side, but side is instance. Pass class MCPToolMethodMutationTestTarget, with side class or instance.'.
		self deny: (MCPToolMethodMutationTestTarget includesSelector: #headerProbe).
		self deny: (MCPToolMethodMutationTestTarget classSide includesSelector: #headerProbe) ] ensure: [ self removeHeaderProbes ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileIntoAMissingClassSaysToCreateIt [
	"method_compile is the one tool that writes into the class it names, so a missing class says how to make one, rather than leaking the lookup's KeyNotFound."

	| error result |
	result := self compileSource: 'zzqxwProbe ^ 1' into: 'Zzqxw' side: nil.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #class) equals: 'Zzqxw'.
	self assert: (error at: #suggestions) equals: #(  ).
	self deny: (error includesKey: #scope).
	self assert: (self textFrom: result) equals: 'Class Zzqxw does not exist. Create it with class_create, then compile into it.'.
	self deny: (Smalltalk globals includesKey: #Zzqxw)
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileIntoAMisspeltClassSuggestsItAndClassCreate [

	| error result text |
	result := self compileSource: 'headerProbe ^ 1' into: 'MCPToolMethodMutationTestTargt' side: nil.
	error := self errorFrom: result.
	text := self textFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: ((error at: #suggestions) includes: 'MCPToolMethodMutationTestTarget').
	self assert: (text beginsWith: 'Class MCPToolMethodMutationTestTargt does not exist. Did you mean: ').
	self assert: (text includesSubstring: 'MCPToolMethodMutationTestTarget').
	self assert: (text endsWith: '. If it is a new class, create it with class_create first.').
	self deny: (MCPToolMethodMutationTestTarget includesSelector: #headerProbe)
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileMethodReportsCreatedChangeKind [

	| data result selector |
	selector := #directCreateProbe.
	self removeSelector: selector from: MCPToolMethodMutationTestTarget.
	[
		result := self callToolNamed: 'method_compile' withArguments: {
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#source -> 'directCreateProbe ^ 11').
				          (#protocol -> 'tests') } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (self summaryFrom: result) equals: 'Created MCPToolMethodMutationTestTarget>>directCreateProbe.'.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (data at: #changeKind) equals: 'created'.
		self assertSuccessDataHasMethodShape: data.
		self assert: MCPToolMethodMutationTestTarget new directCreateProbe equals: 11 ] ensure: [
		self removeSelector: selector from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileMethodReportsReplacedChangeKind [

	| data result selector |
	selector := #directReplaceProbe.
	self ensureMethodSource: 'directReplaceProbe ^ 1' protocol: 'tests' on: MCPToolMethodMutationTestTarget.
	[
		result := self callToolNamed: 'method_compile' withArguments: {
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#source -> 'directReplaceProbe ^ 2').
				          (#protocol -> 'tests') } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (self summaryFrom: result) equals: 'Replaced MCPToolMethodMutationTestTarget>>directReplaceProbe.'.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (data at: #changeKind) equals: 'replaced'.
		self assertSuccessDataHasMethodShape: data.
		self assert: MCPToolMethodMutationTestTarget new directReplaceProbe equals: 2 ] ensure: [
		self removeSelector: selector from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileNamesOnlyTheRulesMethodRewriteCanApply [
	"A critique names its rule class only where method_rewrite can apply the rule, since only there does the name give the caller something to do."

	| concatenation lines result usesTrue |
	self removeSelector: #fixableProbe from: MCPToolMethodMutationTestTarget.
	[
		result := self compileProbe: 'fixableProbe ^ True printString , '' of '' , self printString'.
		concatenation := ((self dataFrom: result) at: #critiques) detect: [ :each |
			                 (each at: #ruleClass) = MCPStringConcatenationRule name asString ].
		usesTrue := ((self dataFrom: result) at: #critiques) detect: [ :each | (each at: #ruleClass) = ReUsesTrueRule name asString ].
		self assert: (concatenation at: #fixable).
		self deny: (usesTrue includesKey: #fixable).
		lines := (self textOf: result) lines select: [ :each | each beginsWith: '  line ' ].
		self assert: lines size equals: 2.
		self assert: (lines anySatisfy: [ :each | each endsWith: ' (method_rewrite ruleClasses: MCPStringConcatenationRule)' ]).
		self deny: (lines anySatisfy: [ :each | each includesSubstring: 'ReUsesTrueRule' ]).
		self assert: (MCPMethodRewriteNamedRuleSpec canApplyRuleClass: MCPStringConcatenationRule).
		self deny: (MCPMethodRewriteNamedRuleSpec canApplyRuleClass: ReUsesTrueRule).
		self deny: (MCPMethodRewriteNamedRuleSpec canApplyRuleClass: Object) ] ensure: [
		self removeSelector: #fixableProbe from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReportsEachCritiqueOnce [
	"A rule that checks every node of a concatenation flags each part of it; only the whole is reported."

	| critiques result |
	self removeSelector: #concatenationOnceProbe from: MCPToolMethodMutationTestTarget.
	[
		result := self compileProbe: 'concatenationOnceProbe ^ ''A '' , self printString , '' of area '' , self hash printString'.
		critiques := (self dataFrom: result) at: #critiques.
		self assert: critiques size equals: 1.
		self assert: (critiques first at: #ruleClass) equals: MCPStringConcatenationRule name asString.
		self assert: ((self textOf: result) lines count: [ :each | each beginsWith: '  line ' ]) equals: 1 ] ensure: [
		self removeSelector: #concatenationOnceProbe from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsAllowlistedEquivalentSuperclassMethodCritique [

	| selector |
	selector := #hierarchyTarget.
	self removeSelector: selector from: MCPToolHierarchyTestChild.
	[
		self
			assertCompileForClass: MCPToolHierarchyTestChild
			methodSource: 'hierarchyTarget ^ ''base-target'''
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'ReEquivalentSuperclassMethodsRule'
			titledLike: 'Methods equivalently defined in superclass' ] ensure: [
		self removeSelector: selector from: MCPToolHierarchyTestChild ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsAllowlistedExcessiveArgumentsCritique [

	| selector |
	selector := #argumentHeavyMethod:with:with:with:with:.
	self removeSelector: selector from: MCPToolMethodMutationTestTarget.
	[
		self
			assertCompileForClass: MCPToolMethodMutationTestTarget
			methodSource:
			'argumentHeavyMethod: first with: second with: third with: fourth with: fifth ^ first + second + third + fourth + fifth'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'ReExcessiveArgumentsRule'
			titledLike: 'Excessive number of arguments' ] ensure: [ self removeSelector: selector from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsAllowlistedMissingSuperSendsCritique [

	self removeSelector: #initialize from: MCPToolHierarchyTestBase.
	self removeSelector: #initialize from: MCPToolHierarchyTestChild.
	[
		self ensureMethodSource: 'initialize super initialize. ^ 1' protocol: 'initialization' on: MCPToolHierarchyTestBase.
		self
			assertCompileForClass: MCPToolHierarchyTestChild
			methodSource: 'initialize 2 + 3'
			protocol: 'initialization'
			returnsSingleCritiqueRuleClass: 'ReMissingSuperSendsRule'
			titledLike: 'Missing super sends' ] ensure: [
			self removeSelector: #initialize from: MCPToolHierarchyTestBase.
			self removeSelector: #initialize from: MCPToolHierarchyTestChild ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsAllowlistedNotOptimizedIfCritique [

	| selector |
	(self class environment includesKey: #ReNotOptimizedIfRule) ifFalse: [
		^ self skip: 'This Pharo version has no ReNotOptimizedIfRule.' ].
	selector := #notOptimizedIf.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClass: MCPToolGetMethodTestTarget
			methodSource: 'notOptimizedIf [ true ] ifTrue: [ ^ 1 ]. ^ 2'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'ReNotOptimizedIfRule'
			titledLike: 'ifTrue:' ] ensure: [ self removeSelector: selector from: MCPToolGetMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsAllowlistedNotOptimizedIfNilCritique [

	| selector |
	(self class environment includesKey: #ReNotOptimizedIfNilRule) ifFalse: [
		^ self skip: 'This Pharo version has no ReNotOptimizedIfNilRule.' ].
	selector := #notOptimizedIfNil.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClass: MCPToolGetMethodTestTarget
			methodSource: 'notOptimizedIfNil [ nil ] ifNil: [ ^ 1 ]. ^ 2'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'ReNotOptimizedIfNilRule'
			titledLike: 'ifNil:' ] ensure: [ self removeSelector: selector from: MCPToolGetMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsAllowlistedReturnInEnsureCritique [

	| selector |
	selector := #returnInEnsure.
	self removeSelector: selector from: MCPToolMethodMutationTestTarget.
	[
		self
			assertCompileForClass: MCPToolMethodMutationTestTarget
			methodSource: 'returnInEnsure [ 1 ] ensure: [ ^ 2 ]'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'ReReturnInEnsureRule'
			titledLike: 'return in an ensure:' ] ensure: [ self removeSelector: selector from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsAllowlistedUnaryAccessingWithoutReturnCritique [

	| selector |
	selector := #counterValue.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClass: MCPToolGetMethodTestTarget
			methodSource: 'counterValue instanceCounter + 1'
			protocol: 'accessing'
			returnsSingleCritiqueRuleClass: 'ReUnaryAccessingMethodWithoutReturnRule'
			titledLike: 'without explicit return' ] ensure: [ self removeSelector: selector from: MCPToolGetMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsAllowlistedWarningCritiques [

	| selector source |
	selector := #shadowedCounter:.
	source := 'shadowedCounter: value | instanceCounter | instanceCounter := value. ^ instanceCounter + 1'.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self compilerRefusesShadowingTemporaries
			ifTrue: [
					self assert: ((self callToolWith: (self
								   compileArgumentsForClass: MCPToolGetMethodTestTarget
								   classSide: false
								   methodSource: source
								   protocol: 'tests')) at: #isError) ]
			ifFalse: [
					self
						assertCompileForClass: MCPToolGetMethodTestTarget
						methodSource: source
						protocol: 'tests'
						returnsSingleCritiqueRuleClass: 'ReTempVarOverridesInstVarRule'
						titledLike: 'Outer variable shadowed' ] ] ensure: [ self removeSelector: selector from: MCPToolGetMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsAssignmentInBlockCritique [

	| selector |
	selector := #assignmentInBlockProbe.
	self removeSelector: selector from: MCPToolMethodMutationTestTarget.
	[
		self
			assertCompileForClass: MCPToolMethodMutationTestTarget
			methodSource: 'assignmentInBlockProbe | value | [ value := 1 ] ensure: [ ] . ^ value'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'ReAssignmentInBlockRule'
			titledLike: 'Unnecessary assignment or return in block' ] ensure: [
		self removeSelector: selector from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsCollectionThenDoCritique [

	| selector |
	selector := #collectionThenDoProbe:.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClass: MCPToolGetMethodTestTarget
			methodSource:
			'collectionThenDoProbe: collection | sum | sum := 0. (collection select: [ :each | each odd ]) do: [ :each | sum := sum + each ]. ^ sum'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'MCPCollectionThenDoRule'
			titledLike: MCPCollectionThenDoRule ruleName ] ensure: [ self removeSelector: selector from: MCPToolGetMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsErrorSeverityCritiquesOnly [

	| critique critiques data result |
	result := self callToolWith: (self
			           compileArgumentsForClass: MCPToolMethodMutationTestTarget
			           classSide: false
			           methodSource: 'instanceProtocolTarget ^ True = true'
			           protocol: 'tests').
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	critiques := data at: #critiques.
	self assert: critiques class equals: Array.
	self assert: critiques size equals: 1.
	critique := critiques first.
	self assert: (critique at: #ruleClass) equals: 'ReUsesTrueRule'.
	self assert: ((critique at: #title) includesSubstring: 'Uses True/False instead of true/false').
	self assert: (critique at: #description) isString.
	self deny: (critique at: #description) isEmpty.
	self assert: (critique includesKey: #start).
	self assert: (critique includesKey: #stop).
	self assert: (critique at: #start) isInteger.
	self assert: (critique at: #stop) isInteger.
	self assert: (critique at: #start) < (critique at: #stop)
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsFilterThenCollectCritique [

	| selector |
	selector := #filterThenCollectProbe:.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClass: MCPToolGetMethodTestTarget
			methodSource:
			'filterThenCollectProbe: collection ^ (collection select: [ :each | each odd ]) collect: [ :each | each asString ]'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'MCPFilterThenCollectRule'
			titledLike: MCPFilterThenCollectRule ruleName ] ensure: [ self removeSelector: selector from: MCPToolGetMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsFilteredEmptinessCritique [

	| selector |
	selector := #filteredEmptinessProbe:.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClass: MCPToolGetMethodTestTarget
			methodSource: 'filteredEmptinessProbe: collection ^ (collection select: [ :each | each odd ]) isEmpty'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'MCPFilteredEmptinessRule'
			titledLike: MCPFilteredEmptinessRule ruleName ] ensure: [ self removeSelector: selector from: MCPToolGetMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsMessageNotUnderstoodHandlerCritique [

	| selector |
	selector := #messageNotUnderstoodProbe:.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClass: MCPToolGetMethodTestTarget
			methodSource: 'messageNotUnderstoodProbe: anObject ^ [ anObject class ] on: MessageNotUnderstood do: [ :ignored | nil ]'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'MCPMessageNotUnderstoodHandlerRule'
			titledLike: MCPMessageNotUnderstoodHandlerRule ruleName ] ensure: [
		self removeSelector: selector from: MCPToolGetMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsNilOnlyConditionalCritique [

	| selector |
	selector := #nilOnlyConditionalProbe:.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClass: MCPToolGetMethodTestTarget
			methodSource: 'nilOnlyConditionalProbe: value ^ value ifNil: [ nil ] ifNotNil: [ :present | present asString ]'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'MCPNilOnlyConditionalRule'
			titledLike: MCPNilOnlyConditionalRule ruleName ] ensure: [ self removeSelector: selector from: MCPToolGetMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsRedundantExplicitSelfReturnCritique [

	| selector |
	selector := #redundantSelfReturnProbe.
	self removeSelector: selector from: MCPToolMethodMutationTestTarget.
	[
		self
			assertCompileForClass: MCPToolMethodMutationTestTarget
			methodSource: 'redundantSelfReturnProbe self printString. ^ self'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'MCPRedundantExplicitSelfReturnRule'
			titledLike: MCPRedundantExplicitSelfReturnRule ruleName ] ensure: [
		self removeSelector: selector from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsRespondsToUsageCritique [

	| selector |
	selector := #respondsToProbe:.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClass: MCPToolGetMethodTestTarget
			methodSource: 'respondsToProbe: anObject ^ anObject respondsTo: #size'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'MCPRespondsToUsageRule'
			titledLike: MCPRespondsToUsageRule ruleName ] ensure: [ self removeSelector: selector from: MCPToolGetMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsSelectSizeCountCritique [

	| selector |
	selector := #selectSizeProbe:.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClass: MCPToolGetMethodTestTarget
			methodSource: 'selectSizeProbe: collection ^ (collection select: [ :each | each odd ]) size'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'MCPSelectSizeCountRule'
			titledLike: MCPSelectSizeCountRule ruleName ] ensure: [ self removeSelector: selector from: MCPToolGetMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsSortedCollectionConversionCritique [

	| selector |
	selector := #sortedCollectionConversionProbe:.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClass: MCPToolGetMethodTestTarget
			methodSource: 'sortedCollectionConversionProbe: collection ^ collection asSortedCollection asArray'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'MCPSortedCollectionConversionRule'
			titledLike: MCPSortedCollectionConversionRule ruleName ] ensure: [
		self removeSelector: selector from: MCPToolGetMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsStructuredCommandErrorForReadOnlyAssignment [

	| error result text |
	self removeSelector: #brokenMethod: from: MCPToolMethodMutationTestTarget.
	result := self callToolWith: (self
			           compileArgumentsForClass: MCPToolMethodMutationTestTarget
			           classSide: false
			           methodSource: 'brokenMethod: anInteger
	anInteger := anInteger + 1.
	^ anInteger'
			           protocol: 'tests').
	error := self errorFrom: result.
	text := (result at: #content) first at: #text.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'compile'.
	self compilerReportsReadOnlyAssignmentsAsSyntaxErrors ifTrue: [
		^ self deny: (MCPToolMethodMutationTestTarget includesSelector: #brokenMethod:) ].
	self assert: (error at: #errorCode) equals: 'CompileReadOnlyAssignment'.
	self assert: (error at: #selector) equals: 'brokenMethod:'.
	self assert: (error at: #variableName) equals: 'anInteger'.
	self assert: (error at: #line) equals: 2.
	self assert: (error at: #column) equals: 2.
	self assert: ((error at: #message) includesSubstring: 'Cannot assign to anInteger').
	self assert: ((error at: #message) includesSubstring: 'arguments are read-only').
	self deny: ((error at: #message) includesSubstring: 'OCErrorNotice').
	self assert: (text includesSubstring: 'Line 2:').
	self assert: (text includesSubstring: 'anInteger := anInteger + 1.').
	self deny: (MCPToolMethodMutationTestTarget includesSelector: #brokenMethod:)
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsStructuredCommandErrorForSyntaxError [

	| error result structured text |
	self removeSelector: #brokenMethod from: MCPToolMethodMutationTestTarget.
	result := self callToolWith: (self
			           compileArgumentsForClass: MCPToolMethodMutationTestTarget
			           classSide: false
			           methodSource: 'brokenMethod ^ 1 +'
			           protocol: 'tests').
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	text := (result at: #content) first at: #text.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'compile'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'CompileSyntaxError'.
	self assert: (error at: #class) equals: MCPToolMethodMutationTestTarget name.
	self assert: (error at: #side) equals: 'instance'.
	self assert: (error at: #position) equals: 19.
	self assert: (error at: #line) equals: 1.
	self assert: (error at: #column) equals: 19.
	self assert: (error at: #sourceLine) equals: 'brokenMethod ^ 1 +'.
	self assert: (text includesSubstring: (String streamContents: [ :stream |
					  stream
						  nextPutAll: 'Line 1:';
						  nextPut: Character lf;
						  nextPutAll: 'brokenMethod ^ 1 +';
						  nextPut: Character lf;
						  next: 18 put: Character space;
						  nextPut: $^ ])).
	self deny: (error includesKey: #variableName).
	self deny: (MCPToolMethodMutationTestTarget includesSelector: #brokenMethod)
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsStructuredCommandErrorForUndeclaredVariable [

	| error result structured |
	self removeSelector: #brokenMethod from: MCPToolMethodMutationTestTarget.
	result := self callToolWith: (self
			           compileArgumentsForClass: MCPToolMethodMutationTestTarget
			           classSide: false
			           methodSource: 'brokenMethod ^ missingVar'
			           protocol: 'tests').
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'compile'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'CompileUndeclaredVariable'.
	self assert: (self expectedUndeclaredVariableNoticeClassNames includes: (error at: #causeClass)).
	self assert: (error at: #class) equals: MCPToolMethodMutationTestTarget name.
	self assert: (error at: #side) equals: 'instance'.
	self assert: (error at: #selector) equals: 'brokenMethod'.
	self assert: (error at: #variableName) equals: 'missingVar'.
	self assert: (error at: #position) equals: 16.
	self assert: (error at: #line) equals: 1.
	self assert: (error at: #column) equals: 16.
	self assert: (error at: #sourceLine) equals: 'brokenMethod ^ missingVar'.
	self assert: ((error at: #message) includesSubstring: 'missingVar').
	self deny: (MCPToolMethodMutationTestTarget includesSelector: #brokenMethod)
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileSucceedsWhenACritiqueRuleRaisesAWarning [

	| result selector |
	selector := MCPWarningTestRule probeSelector.
	self removeSelector: selector from: MCPToolMethodMutationTestTarget.
	[
		result := self callToolWith: (self
				           compileArgumentsForClass: MCPToolMethodMutationTestTarget
				           classSide: false
				           methodSource: selector , ' ^ 1'
				           protocol: 'tests').
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (MCPToolMethodMutationTestTarget includesSelector: selector) ] ensure: [
		self removeSelector: selector from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileWithAnotherProtocolSaysTheMethodMoved [

	| result selector |
	selector := #moveProtocolProbe.
	self ensureMethodSource: 'moveProtocolProbe ^ 1' protocol: 'private' on: MCPToolMethodMutationTestTarget.
	[
		result := self callToolNamed: 'method_compile' withArguments: {
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#source -> 'moveProtocolProbe ^ 2').
				          (#protocol -> 'tests') } asDictionary.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self
			assert: (self summaryFrom: result)
			equals: 'Replaced MCPToolMethodMutationTestTarget>>moveProtocolProbe, moving it from private to tests.'.
		self assert: (MCPToolMethodMutationTestTarget >> selector) protocolName asString equals: 'tests' ] ensure: [
		self removeSelector: selector from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileWithoutProtocolKeepsAnExtensionMethodInItsPackage [
	"An extension method's protocol is what puts it in the package that extends the class."

	| method selector |
	selector := #keepExtensionProbe.
	self ensureMethodSource: 'keepExtensionProbe ^ 1' protocol: self generatedExtensionProtocol on: MCPToolMethodMutationTestTarget.
	[
		self callToolNamed: 'method_compile' withArguments: {
				(#class -> MCPToolMethodMutationTestTarget name).
				(#source -> 'keepExtensionProbe ^ 2') } asDictionary.
		method := MCPToolMethodMutationTestTarget >> selector.
		self assert: method protocolName asString equals: self generatedExtensionProtocol.
		self assert: method package name equals: self generatedExtensionPackageName ] ensure: [
			self removeSelector: selector from: MCPToolMethodMutationTestTarget.
			self removeGeneratedPackagesIfEmpty ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileWithoutProtocolKeepsTheProtocolOfTheMethodItReplaces [
	"Changing a method's body used to mean naming a protocol, and naming another one moved the method."

	| result selector |
	selector := #keepProtocolProbe.
	self ensureMethodSource: 'keepProtocolProbe ^ 1' protocol: 'private' on: MCPToolMethodMutationTestTarget.
	[
		result := self callToolNamed: 'method_compile' withArguments: {
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#source -> 'keepProtocolProbe ^ 2') } asDictionary.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (self summaryFrom: result) equals: 'Replaced MCPToolMethodMutationTestTarget>>keepProtocolProbe.'.
		self assert: (MCPToolMethodMutationTestTarget >> selector) protocolName asString equals: 'private'.
		self assert: (self warningsFrom: result) isEmpty.
		self assert: MCPToolMethodMutationTestTarget new keepProtocolProbe equals: 2 ] ensure: [
		self removeSelector: selector from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileWithoutProtocolWarnsThatANewMethodHasNone [

	| result selector warnings |
	selector := #unclassifiedProbe.
	self removeSelector: selector from: MCPToolMethodMutationTestTarget.
	[
		result := self callToolNamed: 'method_compile' withArguments: {
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#source -> 'unclassifiedProbe ^ 3') } asDictionary.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (MCPToolMethodMutationTestTarget >> selector) protocolName asString equals: Protocol unclassified asString.
		warnings := self warningsFrom: result.
		self assert: warnings size equals: 1.
		self assert: (warnings first beginsWith: 'No protocol was named') ] ensure: [
		self removeSelector: selector from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompilesClassSideMethod [

	| data result |
	result := self callToolWith: (self
			           compileArgumentsForClass: MCPToolMethodMutationTestTarget
			           classSide: true
			           methodSource: 'classAnswer ^ 7'
			           protocol: 'tests').
	data := self dataFrom: result.
	self assert: MCPToolMethodMutationTestTarget classAnswer equals: 7.
	self assert: (MCPToolMethodMutationTestTarget classSide >> #classAnswer) protocolName equals: #tests.
	self assertSuccessDataHasMethodShape: data.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompilesInstanceSideMethod [

	| data result |
	result := self callToolWith: (self
			           compileArgumentsForClass: MCPToolMethodMutationTestTarget
			           classSide: false
			           methodSource: 'instanceAnswer ^ 42'
			           protocol: 'tests').
	data := self dataFrom: result.
	self assert: MCPToolMethodMutationTestTarget new instanceAnswer equals: 42.
	self assert: (MCPToolMethodMutationTestTarget >> #instanceAnswer) protocolName equals: #tests.
	self assertSuccessDataHasMethodShape: data.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompilingOverAMethodInstalledFromATraitStopsAndNamesTheTrait [

	| error result |
	result := self callToolNamed: 'method_compile' withArguments: {
			          (#class -> 'MCPToolMethodSearchTraitUser').
			          (#protocol -> 'accessing').
			          (#source -> 'mcpTraitFixtureValue ^ ''from the user''') } asDictionary.
	error := self errorFrom: result.
	self assert: (self resultIndicatesError: result).
	self assert: (error at: #errorCode) equals: 'MethodInstalledFromTrait'.
	self assert: (error at: #trait) equals: 'TMCPToolMethodSearchFixture'.
	self assert: (error at: #origin) equals: 'TMCPToolMethodSearchFixture>>mcpTraitFixtureValue'.
	self assert: ((error at: #howToProceed) includesSubstring: 'resend with force').
	self assert: (MCPToolMethodSearchTraitUser >> #mcpTraitFixtureValue) isFromTrait
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testForceCompilesOverAMethodInstalledFromATrait [

	| data result |
	result := self callToolNamed: 'method_compile' withArguments: {
			          (#class -> 'MCPToolMethodSearchTraitUser').
			          (#protocol -> 'accessing').
			          (#force -> true).
			          (#source -> 'mcpTraitFixtureValue ^ ''from the user''') } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #changeKind) equals: 'replaced'.
	self deny: (MCPToolMethodSearchTraitUser >> #mcpTraitFixtureValue) isFromTrait.
	self assert: MCPToolMethodSearchTraitUser new mcpTraitFixtureValue equals: 'from the user'
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testForceDoesNotUpdateAMethodInstalledFromATrait [
	"Compiling over a copy is an override Pharo supports, so force carries it through. Renaming one lands in no source file at all, so nothing carries that through."

	| error result |
	result := self callToolNamed: 'method_update' withArguments: {
			          (#class -> 'MCPToolMethodSearchTraitUser').
			          (#selector -> 'mcpTraitFixtureValue').
			          (#newSelector -> 'mcpTraitFixtureValueRenamed').
			          (#force -> true) } asDictionary.
	error := self errorFrom: result.
	self assert: (self resultIndicatesError: result).
	self assert: (error at: #errorCode) equals: 'MethodInstalledFromTrait'.
	self assert: (MCPToolMethodSearchTraitUser includesSelector: #mcpTraitFixtureValue).
	self deny: (MCPToolMethodSearchTraitUser includesSelector: #mcpTraitFixtureValueRenamed)
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testHeaderNamingTheTargetIsDropped [
	"A source that begins with the reference of the method it compiles, as the agents copy it from a search result, says nothing the call does not say, so the reference is dropped with a warning."

	| result |
	[
		result := self
			          compileSource: 'MCPToolMethodMutationTestTarget >> #headerProbe
	^ 1'
			          into: MCPToolMethodMutationTestTarget name
			          side: nil.
		self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
		self assert: (self summaryFrom: result) equals: 'Created MCPToolMethodMutationTestTarget>>headerProbe.'.
		self assert: (self warningsFrom: result) equals: { self droppedHeaderWarning }.
		self assert: (MCPToolMethodMutationTestTarget new perform: #headerProbe) equals: 1.
		self deny: ((MCPToolMethodMutationTestTarget >> #headerProbe) sourceCode includesSubstring: '>>').
		self assert: ((MCPToolMethodMutationTestTarget >> #headerProbe) sourceCode beginsWith: 'headerProbe').

		result := self
			          compileSource: 'MCPToolMethodMutationTestTarget class >> #headerProbe
	^ 2'
			          into: MCPToolMethodMutationTestTarget name
			          side: nil.
		self assert: (self summaryFrom: result) equals: 'Created MCPToolMethodMutationTestTarget class>>headerProbe.'.
		self assert: (MCPToolMethodMutationTestTarget perform: #headerProbe) equals: 2.

		result := self
			          compileSource: 'MCPToolMethodMutationTestTarget >> headerProbe: a
	^ a'
			          into: MCPToolMethodMutationTestTarget name
			          side: nil.
		self assert: (self summaryFrom: result) equals: 'Created MCPToolMethodMutationTestTarget>>headerProbe:.'.
		self assert: (MCPToolMethodMutationTestTarget new perform: #headerProbe: with: 3) equals: 3 ] ensure: [ self removeHeaderProbes ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testHeaderThatCannotBeDroppedIsRefusedWithTheLineToWrite [
	"Dropping a header that names another class or side would compile somewhere the call did not say, a selector without its argument names would leave the body's arguments undeclared, and Tonel's brackets would leave a dead block. Each is refused, and nothing is compiled."

	| error |
	error := self
		         assertHeaderOf: 'MCPToolMethodMutationTestTarget class>>headerProbe:with:
	^ 1'
		         side: nil
		         isRefusedSaying:
		         'The source begins with MCPToolMethodMutationTestTarget class>>headerProbe:with:, a method''s reference rather than its first line. Start the source with the selector and its argument names, each keyword followed by the name the body uses for that argument, and pass side class.'.
	self assert: (error at: #side) equals: 'class'.
	self
		assertHeaderOf: 'MCPToolMethodMutationTestTarget>>>=
	^ true'
		side: nil
		isRefusedSaying:
		'The source begins with MCPToolMethodMutationTestTarget>>>=, a method''s reference rather than its first line. Start the source with the selector, followed by the name the body uses for its argument.'.
	self
		assertHeaderOf: 'MCPToolMethodMutationTestSender >> headerProbe
	^ 1'
		side: nil
		isRefusedSaying:
		'The source begins with MCPToolMethodMutationTestSender >> headerProbe, which names MCPToolMethodMutationTestSender, but the call''s class is MCPToolMethodMutationTestTarget. Start the source with its selector line, headerProbe, and name the class with class.'.
	error := self
		         assertHeaderOf: 'MCPToolMethodMutationTestTarget class >> #headerProbe
	^ 1'
		         side: 'instance'
		         isRefusedSaying:
		         'The source begins with MCPToolMethodMutationTestTarget class >> #headerProbe, which names the class side, but the call''s side is instance. Start the source with its selector line, headerProbe, and choose the side with side.'.
	self assert: (error at: #side) equals: 'instance'.
	self
		assertHeaderOf: 'MCPToolMethodMutationTestTarget class >> #headerProbe:with:
	^ 1'
		side: 'instance'
		isRefusedSaying:
		'The source begins with MCPToolMethodMutationTestTarget class >> #headerProbe:with:, which names the class side, but the call''s side is instance. Start the source with its selector line, the selector with its argument names, and choose the side with side.'.
	self
		assertHeaderOf: 'MCPToolMethodMutationTestTarget >> headerProbe [
	^ 1
]'
		side: nil
		isRefusedSaying:
		'The source begins with MCPToolMethodMutationTestTarget >> headerProbe [, Tonel''s form of a method. Write the method without Tonel''s brackets: its selector line, headerProbe, then its body.'
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testHeadersOfABatchWarnOnce [

	| result text |
	[
		result := self callToolNamed: 'method_compile' withArguments: {
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#protocol -> 'tests').
				          (#source -> #( 'MCPToolMethodMutationTestTarget >> #headerProbe
	^ 1' 'MCPToolMethodMutationTestTarget>>headerProbeTwo
	^ 2' )) } asDictionary.
		self deny: (result at: #isError ifAbsent: [ false ]).
		text := self textFrom: result.
		self assert: (text allRangesOfSubstring: self droppedHeaderWarning) size equals: 1.
		self assert: (MCPToolMethodMutationTestTarget includesSelector: #headerProbe).
		self assert: (MCPToolMethodMutationTestTarget includesSelector: #headerProbeTwo) ] ensure: [ self removeHeaderProbes ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testMCPPackageMethodSourcesDoNotContainLineFeeds [

	| offenders |
	offenders := self methodSourceLineFeedOffenders.
	self assert: offenders isEmpty description: 'MCP method source must not contain Character lf: ' , offenders printString
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testMethodToolSchemasDeclareExpectedInputs [

	| classSideProperty createPropertyNames updatePropertyNames |
	createPropertyNames := MCPToolCompileMethod new inputSchema properties collect: [ :each | each name ].
	updatePropertyNames := MCPToolUpdateMethod new inputSchema properties collect: [ :each | each name ].
	classSideProperty := MCPToolCompileMethod new inputSchema properties detect: [ :each | each name = 'side' ].
	self assert: createPropertyNames asArray equals: #( 'class' 'side' 'source' 'protocol' 'force' ).
	self
		assert: updatePropertyNames asArray
		equals:
		#( 'class' 'side' 'force' 'selector' 'protocol' 'newSelector' 'arguments' 'argumentValueExpressions' 'permutation' 'scope' ).
	self assert: MCPToolCompileMethod new inputSchema required asSet equals: #( 'class' 'source' ) asSet.
	self assert: MCPToolUpdateMethod new inputSchema required asSet equals: #( 'class' 'selector' ) asSet.
	self assert: (classSideProperty extraProperties at: #default) equals: 'instance'
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testProtocolChangeSaysFromAndTo [
	"A protocol change names the protocol the method left and the one it went to, in the words method_compile uses for a replace that moves a method; asking for the protocol it is in says so, and a method with none was in no protocol."

	| oldProtocol reference |
	reference := 'MCPToolMethodMutationTestTarget>>' , self instanceProtocolSelector.
	oldProtocol := (MCPToolMethodMutationTestTarget >> self instanceProtocolSelector) protocolName asString.
	self deny: oldProtocol equals: 'accessing'.
	self
		assert: (self summaryFrom: (self callToolWith: self instanceChangeArguments))
		equals: ('Moved {1} from {2} to accessing.' format: {
					 reference.
					 oldProtocol }).
	self
		assert: (self summaryFrom: (self callToolWith: self instanceChangeArguments))
		equals: ('{1} is already in accessing.' format: { reference }).
	self
		assert: (MCPUpdateMethodCommand new protocolChangeSummaryFor: 'EvalLedger>>audit' from: '' to: 'accounting')
		equals: 'Moved EvalLedger>>audit from no protocol to accounting.'
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testReformatsMethod [

	| reformattedSource result source |
	source := 'uglyAnswer   ^   1+2'.
	result := self callToolWith: (self
			           compileArgumentsForClass: MCPToolMethodMutationTestTarget
			           classSide: false
			           methodSource: source
			           protocol: 'tests').
	reformattedSource := (MCPToolMethodMutationTestTarget >> #uglyAnswer) sourceCode.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (reformattedSource includesSubstring: '1 + 2').
	self assert: MCPToolMethodMutationTestTarget new uglyAnswer equals: 3
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testReformatsWithTheFormatterOfTheMethodPackage [
	"The manifest of the method's package decides its formatting, not the manifest of the package that defines the AST."

	| method result target |
	self createGeneratedPackageManifestWithNarrowFormatter.
	target := self
		          createClassNamed: 'MCPToolMethodMutationTestFormatterTarget'
		          superclassName: 'Object'
		          slots: #(  )
		          classSlots: #(  ).
	[
		result := self callToolWith: (self
				           compileArgumentsForClass: target
				           classSide: false
				           methodSource: 'boundedAnswer ^ 1 between: 1000000 and: 2000000'
				           protocol: 'tests').
		method := target >> #boundedAnswer.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: method sourceCode equals: (method ast formattedCodeIn: target).
		self deny: method sourceCode equals: method ast formattedCode ] ensure: [
			self removeClassNamed: 'MCPToolMethodMutationTestFormatterTarget'.
			self removeGeneratedPackageManifest ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRemoveArgumentWithoutPermutationKeepsTheNamedArguments [

	| narrowed result |
	narrowed := self inferenceOutcomeSelectors third.
	self
		ensureMethodSource: 'probeCombine: first with: second
	^ first'
		protocol: 'tests'
		on: MCPToolMethodMutationTestTarget.
	result := self callToolWith: {
			          (#class -> MCPToolMethodMutationTestTarget name).
			          (#selector -> self inferenceSelector asString).
			          (#newSelector -> narrowed asString).
			          (#arguments -> #( 'first' )) } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (MCPToolMethodMutationTestTarget includesSelector: narrowed).
	self assert: (MCPToolMethodMutationTestTarget new perform: narrowed with: 'a') equals: 'a'
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRemoveArgumentsFailsWhenRemovedArgumentIsReferenced [

	| error newSelector oldSelector result structured |
	oldSelector := ('referencedRemove:' , 'unused:') asSymbol.
	newSelector := #referencedRemove:.
	[
		self
			ensureMethodSource: 'referencedRemove: first unused: ignored ^ ignored'
			protocol: 'tests'
			on: MCPToolMethodMutationTestTarget.
		result := self callToolWith: {
				          (#action -> 'update').
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#side -> 'instance').
				          (#selector -> oldSelector asString).
				          (#newSelector -> newSelector asString) } asDictionary.
		structured := self structuredContentFrom: result.
		error := self errorFrom: result.
		self assert: (result at: #isError).
		self assert: (error at: #action) equals: 'update'.
		self assert: (error at: #updateAction) equals: 'removeArguments'.
		self assert: (error at: #class) equals: MCPToolMethodMutationTestTarget name.
		self assert: (error at: #selector) equals: oldSelector asString.
		self assert: (error at: #newSelector) equals: newSelector asString.
		self assert: (MCPToolMethodMutationTestTarget includesSelector: oldSelector).
		self deny: (MCPToolMethodMutationTestTarget includesSelector: newSelector) ] ensure: [
			self removeSelector: oldSelector from: MCPToolMethodMutationTestTarget.
			self removeSelector: newSelector from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRemoveArgumentsUpdatesSendersAndReportsAction [

	| data newSelector oldSelector result senderSource |
	oldSelector := ('keep:' , 'unused:') asSymbol.
	newSelector := #keep:.
	[
		self ensureMethodSource: 'keep: first unused: ignored ^ first' protocol: 'tests' on: MCPToolMethodMutationTestTarget.
		self
			ensureMethodSource: 'callRemoveArgumentTarget ^ MCPToolMethodMutationTestTarget new keep: ''value'' unused: ''ignored'''
			protocol: 'tests'
			on: MCPToolMethodMutationTestSender.
		result := self callToolWith: {
				          (#action -> 'update').
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#side -> 'instance').
				          (#selector -> oldSelector asString).
				          (#newSelector -> newSelector asString) } asDictionary.
		data := self dataFrom: result.
		senderSource := (MCPToolMethodMutationTestSender >> #callRemoveArgumentTarget) sourceCode.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self deny: (MCPToolMethodMutationTestTarget includesSelector: oldSelector).
		self assert: (MCPToolMethodMutationTestTarget includesSelector: newSelector).
		self deny: (senderSource includesSubstring: 'unused:').
		self assert: MCPToolMethodMutationTestSender new callRemoveArgumentTarget equals: 'value' ] ensure: [
			self removeSelector: oldSelector from: MCPToolMethodMutationTestTarget.
			self removeSelector: newSelector from: MCPToolMethodMutationTestTarget.
			self removeSelector: #callRemoveArgumentTarget from: MCPToolMethodMutationTestSender ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenameCanLimitRefactoringToNamedClasses [

	self withRenameScopeFixturesDo: [ :fixtures |
			| data result senderAClass senderASource senderBClass senderBSource targetAClass targetBClass |
			result := self callToolWith: {
					          (#action -> 'update').
					          (#class -> (fixtures at: #targetAClassName)).
					          (#side -> 'instance').
					          (#selector -> 'scopeSharedTarget').
					          (#newSelector -> 'scopedSharedTarget').
					          (#scope -> { (#classes -> {
							            (fixtures at: #targetAClassName).
							            (fixtures at: #senderAClassName) }) } asDictionary) } asDictionary.
			data := self dataFrom: result.
			targetAClass := Smalltalk globals at: (fixtures at: #targetAClassName) asSymbol.
			targetBClass := Smalltalk globals at: (fixtures at: #targetBClassName) asSymbol.
			senderAClass := Smalltalk globals at: (fixtures at: #senderAClassName) asSymbol.
			senderBClass := Smalltalk globals at: (fixtures at: #senderBClassName) asSymbol.
			self deny: (result at: #isError ifAbsent: [ false ]).
			self deny: (targetAClass includesSelector: #scopeSharedTarget).
			self assert: (targetAClass includesSelector: #scopedSharedTarget).
			self assert: (targetBClass includesSelector: #scopeSharedTarget).
			self deny: (targetBClass includesSelector: #scopedSharedTarget).
			self assert: senderAClass new callScopedTarget equals: 'A'.
			self assert: senderBClass new callScopedTarget equals: 'B'.
			senderASource := (senderAClass >> #callScopedTarget) sourceCode.
			senderBSource := (senderBClass >> #callScopedTarget) sourceCode.
			self assert: (senderASource includesSubstring: 'scopedSharedTarget').
			self assert: (senderBSource includesSubstring: 'scopeSharedTarget').
			self deny: (senderBSource includesSubstring: 'scopedSharedTarget').
			self assertSuccessDataHasMethodShape: data ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenameCanLimitRefactoringToNamedPackages [

	self withRenameScopeFixturesDo: [ :fixtures |
			| data result senderAClass senderASource senderBClass senderBSource targetAClass targetBClass |
			result := self callToolWith: {
					          (#action -> 'update').
					          (#class -> (fixtures at: #targetAClassName)).
					          (#side -> 'instance').
					          (#selector -> 'scopeSharedTarget').
					          (#newSelector -> 'scopedSharedTarget').
					          (#scope -> { (#packages -> { (fixtures at: #packageAName) }) } asDictionary) } asDictionary.
			data := self dataFrom: result.
			targetAClass := Smalltalk globals at: (fixtures at: #targetAClassName) asSymbol.
			targetBClass := Smalltalk globals at: (fixtures at: #targetBClassName) asSymbol.
			senderAClass := Smalltalk globals at: (fixtures at: #senderAClassName) asSymbol.
			senderBClass := Smalltalk globals at: (fixtures at: #senderBClassName) asSymbol.
			self deny: (result at: #isError ifAbsent: [ false ]).
			self deny: (targetAClass includesSelector: #scopeSharedTarget).
			self assert: (targetAClass includesSelector: #scopedSharedTarget).
			self assert: (targetBClass includesSelector: #scopeSharedTarget).
			self deny: (targetBClass includesSelector: #scopedSharedTarget).
			self assert: senderAClass new callScopedTarget equals: 'A'.
			self assert: senderBClass new callScopedTarget equals: 'B'.
			senderASource := (senderAClass >> #callScopedTarget) sourceCode.
			senderBSource := (senderBClass >> #callScopedTarget) sourceCode.
			self assert: (senderASource includesSubstring: 'scopedSharedTarget').
			self assert: (senderBSource includesSubstring: 'scopeSharedTarget').
			self deny: (senderBSource includesSubstring: 'scopedSharedTarget').
			self assertSuccessDataHasMethodShape: data ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenameKeepsRenamedMethodCallable [

	| newSelector oldSelector result target |
	oldSelector := ('uglyRename:' , 'with:') asSymbol.
	newSelector := ('with:' , 'uglyRename:') asSymbol.
	[
		self
			ensureMethodSource: 'uglyRename: first with: second ^ first , ''-'' , second'
			protocol: 'tests'
			on: MCPToolMethodMutationTestTarget.
		result := self callToolWith: {
				          (#action -> 'update').
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#side -> 'instance').
				          (#selector -> oldSelector asString).
				          (#newSelector -> newSelector asString).
				          (#permutation -> #( 2 1 )) } asDictionary.
		target := MCPToolMethodMutationTestTarget new.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self deny: (MCPToolMethodMutationTestTarget includesSelector: oldSelector).
		self assert: (MCPToolMethodMutationTestTarget includesSelector: newSelector).
		self assert: (target perform: newSelector with: 'right' with: 'left') equals: 'left-right' ] ensure: [
			self removeSelector: oldSelector from: MCPToolMethodMutationTestTarget.
			self removeSelector: newSelector from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenameRefusesAScopeEntryThatNamesNoClassUnderItsKey [
	"A refactoring scope must be complete, so an entry that names no class refuses the rename before anything changes."

	#( #classes 'Class Zzqxw, in scope.classes, does not exist.' #hierarchyOf 'Class Zzqxw, in scope.hierarchyOf, does not exist.' )
		pairsDo: [ :key :text |
				| error result |
				result := self callToolWith: (self instanceRenameArguments copy
						           at: #scope put: { (key -> #( 'Zzqxw' )) } asDictionary;
						           yourself).
				error := self errorFrom: result.
				self assert: (result at: #isError).
				self assert: (error at: #errorCode) equals: 'ClassNotFound'.
				self assert: (error at: #scope) equals: 'scope.' , key.
				self assert: (self textFrom: result) equals: text.
				self assert: (MCPToolMethodMutationTestTarget includesSelector: self instanceSelector) ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenameReturnsStructuredErrorWhenMethodIsMissing [

	| error result structured |
	self removeSelector: self instanceSelector from: MCPToolMethodMutationTestTarget.
	result := self callToolWith: self instanceRenameArguments.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'rename'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'MethodNotFound'.
	self assert: (error at: #class) equals: MCPToolMethodMutationTestTarget name.
	self assert: (error at: #side) equals: 'instance'.
	self assert: (error at: #selector) equals: self instanceSelector asString.
	self assert: (error at: #newSelector) equals: self renamedInstanceSelector asString.
	self assert: (error at: #permutation) equals: #( 2 1 ).
	self
		assert: error keys asSet
		equals: #( action updateAction errorClass errorCode message class side selector newSelector permutation ) asSet
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenameReturnsStructuredErrorWhenScopeRequiresClassNames [

	| arguments |
	arguments := self instanceRenameArguments copy.
	arguments removeKey: #action ifAbsent: [ ].
	arguments at: #scope put: 'classes'.
	self
		assertResult: (self callDiscoveredToolNamed: 'method_update' withArguments: arguments)
		refusesArgumentsSaying: 'scope must be object, not string.'
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenameReturnsStructuredErrorWhenScopedPackageIsMissing [

	| error result structured |
	result := self callToolWith: (self instanceRenameArguments copy
			           at: #scope put: { (#packages -> #( 'DefinitelyMissingPackage' )) } asDictionary;
			           yourself).
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'PackageNotFound'.
	self assert: (error at: #package) equals: 'DefinitelyMissingPackage'.
	self assert: (error at: #scope) equals: 'scope.packages'.
	self assert: ((error at: #message) beginsWith: 'Package DefinitelyMissingPackage, in scope.packages, does not exist.').
	self assert: (error at: #selector) equals: self instanceSelector asString.
	self assert: (error at: #newSelector) equals: self renamedInstanceSelector asString
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenameUpdatesSendersAndPermutesArguments [

	| senderSource |
	self callToolWith: self instanceRenameArguments.
	self assert: MCPToolMethodMutationTestSender new callInstanceTarget equals: 'first-second'.
	senderSource := (MCPToolMethodMutationTestSender >> #callInstanceTarget) sourceCode.
	self assert: (senderSource includesSubstring: 'with: ''second'' combine: ''first''')
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenameWithoutPermutationKeepsArgumentsInPlace [

	| renamed result |
	renamed := self inferenceOutcomeSelectors first.
	result := self callToolWith: {
			          (#class -> MCPToolMethodMutationTestTarget name).
			          (#selector -> self inferenceSelector asString).
			          (#newSelector -> renamed asString) } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (MCPToolMethodMutationTestTarget includesSelector: renamed).
	self assert: (MCPToolMethodMutationTestTarget new perform: renamed with: 'a' with: 'b') equals: 'a-b'
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenamesClassSideMethodOfAClassWrittenWithItsSide [
	"Foo class with a bare selector names the class-side method, so the summary names the side once."

	| result |
	result := self callToolWith: {
			          (#class -> (MCPToolMethodMutationTestTarget name , ' class')).
			          (#selector -> self classSelector asString).
			          (#newSelector -> self renamedClassSelector asString) } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
	self deny: (MCPToolMethodMutationTestTarget classSide includesSelector: self classSelector).
	self assert: (MCPToolMethodMutationTestTarget classSide includesSelector: self renamedClassSelector).
	self assert: ((self summaryFrom: result) includesSubstring: 'MCPToolMethodMutationTestTarget class>>').
	self deny: ((self summaryFrom: result) includesSubstring: 'class class')
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenamesClassSideMethodWithDefaultPermutation [

	| data result |
	result := self callToolWith: self classRenameArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (MCPToolMethodMutationTestTarget classSide includesSelector: self classSelector).
	self assert: (MCPToolMethodMutationTestTarget classSide includesSelector: self renamedClassSelector).
	self assert: MCPToolMethodMutationTestSender new callClassTarget equals: 'Class-value'.
	self assertSuccessDataHasMethodShape: data.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenamesInstanceMethodAndReturnsStructuredData [

	| data result |
	result := self callToolWith: self instanceRenameArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (MCPToolMethodMutationTestTarget includesSelector: self instanceSelector).
	self assert: (MCPToolMethodMutationTestTarget includesSelector: self renamedInstanceSelector).
	self assertSuccessDataHasMethodShape: data.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testSourcesThatBeginWithTheirSelectorLineHaveNoHeader [
	"A header needs one capitalised word before its separator, so no method's own first line reads as one."

	[
		#( 'headerProbe ^ #bar' 'HeaderProbe
	^ 1' 'headerProbe: aStream
	aStream << #x' ) do: [ :each |
				| result |
				result := self compileSource: each into: MCPToolMethodMutationTestTarget name side: nil.
				self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
				self deny: ((self warningsFrom: result) includes: self droppedHeaderWarning) ].
		self assert: (MCPToolMethodMutationTestTarget new perform: #headerProbe) equals: #bar.
		self assert: (MCPToolMethodMutationTestTarget new perform: #HeaderProbe) equals: 1 ] ensure: [ self removeHeaderProbes ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testUpdateChangesProtocolAndSelectorInOneCall [

	| data renamed result |
	renamed := self renamedInstanceProtocolSelector.
	result := self callToolWith: {
			          (#class -> MCPToolMethodMutationTestTarget name).
			          (#side -> 'instance').
			          (#selector -> self instanceProtocolSelector asString).
			          (#protocol -> 'accessing').
			          (#newSelector -> renamed asString) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (MCPToolMethodMutationTestTarget includesSelector: self instanceProtocolSelector).
	self assert: (MCPToolMethodMutationTestTarget includesSelector: renamed).
	self assert: (MCPToolMethodMutationTestTarget >> renamed) protocolName asString equals: 'accessing'.
	self assert: ((data at: #updates) collect: [ :each | each at: #action ] as: Array) equals: #( 'changeProtocol' 'rename' )
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testUpdatingAMethodInstalledFromATraitStopsAndNamesTheTrait [
	"Changing the protocol of a copy recompiles it into the class as a method of its own, which the next export writes to the file of a class that never had it."

	| error result |
	result := self callToolNamed: 'method_update' withArguments: {
			          (#class -> 'MCPToolMethodSearchTraitUser').
			          (#selector -> 'mcpTraitFixtureValue').
			          (#protocol -> 'private') } asDictionary.
	error := self errorFrom: result.
	self assert: (self resultIndicatesError: result).
	self assert: (error at: #errorCode) equals: 'MethodInstalledFromTrait'.
	self assert: ((error at: #howToProceed) includesSubstring: 'Update TMCPToolMethodSearchFixture>>mcpTraitFixtureValue instead').
	self assert: (MCPToolMethodSearchTraitUser >> #mcpTraitFixtureValue) isFromTrait.
	self assert: (MCPToolMethodSearchTraitUser >> #mcpTraitFixtureValue) protocolName asString equals: 'accessing'
]

{ #category : 'private - results' }
MCPToolMethodMutationTest >> textFrom: aResult [

	^ (aResult at: #content) first at: #text
]

{ #category : 'private' }
MCPToolMethodMutationTest >> textOf: aResult [

	^ (aResult at: #content) first at: #text
]

{ #category : 'private - calling' }
MCPToolMethodMutationTest >> toolName [

	self shouldNotImplement
]

{ #category : 'private' }
MCPToolMethodMutationTest >> withRenameScopeFixturesDo: aBlock [

	| fixtures packageAName packageBName senderAClassName senderBClassName targetAClassName targetBClassName |
	packageAName := 'MCP-Tests-MethodMutationScope-A'.
	packageBName := 'MCP-Tests-MethodMutationScope-B'.
	targetAClassName := 'MCPToolMethodMutationScopeTargetA'.
	targetBClassName := 'MCPToolMethodMutationScopeTargetB'.
	senderAClassName := 'MCPToolMethodMutationScopeSenderA'.
	senderBClassName := 'MCPToolMethodMutationScopeSenderB'.
	{
		targetAClassName.
		targetBClassName.
		senderAClassName.
		senderBClassName } do: [ :eachName | self removeClassNamed: eachName ].
	{
		packageAName.
		packageBName } do: [ :eachName | self removePackageNamed: eachName ].
	[
		self createRenameScopeFixtureClassNamed: targetAClassName packageName: packageAName.
		self createRenameScopeFixtureClassNamed: targetBClassName packageName: packageBName.
		self createRenameScopeFixtureClassNamed: senderAClassName packageName: packageAName.
		self createRenameScopeFixtureClassNamed: senderBClassName packageName: packageBName.
		self ensureMethodSource: 'scopeSharedTarget ^ ''A''' protocol: 'tests' on: (Smalltalk globals at: targetAClassName asSymbol).
		self ensureMethodSource: 'scopeSharedTarget ^ ''B''' protocol: 'tests' on: (Smalltalk globals at: targetBClassName asSymbol).
		self
			ensureMethodSource: 'callScopedTarget ^ MCPToolMethodMutationScopeTargetA new scopeSharedTarget'
			protocol: 'tests'
			on: (Smalltalk globals at: senderAClassName asSymbol).
		self
			ensureMethodSource: 'callScopedTarget ^ MCPToolMethodMutationScopeTargetB new scopeSharedTarget'
			protocol: 'tests'
			on: (Smalltalk globals at: senderBClassName asSymbol).
		fixtures := {
			            (#packageAName -> packageAName).
			            (#packageBName -> packageBName).
			            (#targetAClassName -> targetAClassName).
			            (#targetBClassName -> targetBClassName).
			            (#senderAClassName -> senderAClassName).
			            (#senderBClassName -> senderBClassName) } asDictionary.
		aBlock value: fixtures ] ensure: [
			{
				targetAClassName.
				targetBClassName.
				senderAClassName.
				senderBClassName } do: [ :eachName | self removeClassNamed: eachName ].
			{
				packageAName.
				packageBName } do: [ :eachName | self removePackageNamed: eachName ] ]
]
