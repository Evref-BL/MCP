"
Tests the method_compile and method_update tools.
"
Class {
	#name : 'MCPToolMethodMutationTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolMethodMutationTest >> assertClassSideHeaderIsRefusedIn: aSource side: aSideOrNil [
	"A header naming the class side is refused like any other, and, since the selector line that replaces it cannot name the side and the call did not, says to pass it."

	^ self
		  assertHeader: aSource lines first trimBoth
		  isRefusedIn: aSource
		  side: aSideOrNil
		  closingWith: ' The header named the class side, so pass side class.'
]

{ #category : 'private' }
MCPToolMethodMutationTest >> assertCompileForClass: aClass methodSource: aMethodSource protocol: aProtocol returnsSingleCritiqueRuleClass: aRuleClassName titledLike: aSubstring [

	| critique critiques data result |
	result := self callToolNamed: 'method_compile' withArguments: (self
			           compileArgumentsForClass: aClass
			           classSide: false
			           methodSource: aMethodSource
			           protocol: aProtocol).
	data := self dataFrom: result.
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
MCPToolMethodMutationTest >> assertHeader: aHeader isRefusedIn: aSource side: aSideOrNil closingWith: aSentence [
	"aSource, which begins with the method's reference aHeader, is refused and nothing is compiled. The answer ends with aSentence."

	| error result |
	result := self compileSource: aSource into: MCPToolMethodMutationTestTarget name side: aSideOrNil.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'MethodSourceHeader'.
	self assert: (error at: #header) equals: aHeader.
	self assert: (error at: #class) equals: MCPToolMethodMutationTestTarget name.
	self assert: (self textFrom: result) equals: 'The source begins with ' , aHeader
		,
		', a method''s reference. Start it with the method''s selector line, argument names included, then its body; class and side say where it goes.'
		, aSentence.
	#( #headerProbe #headerProbe:with: #headerProbe: #= #'>=' ) do: [ :each |
			self deny: (MCPToolMethodMutationTestTarget includesSelector: each).
			self deny: (MCPToolMethodMutationTestTarget classSide includesSelector: each) ].
	^ error
]

{ #category : 'private' }
MCPToolMethodMutationTest >> assertHeaderIsRefusedIn: aSource side: aSideOrNil [

	^ self
		  assertHeader: aSource lines first trimBoth
		  isRefusedIn: aSource
		  side: aSideOrNil
		  closingWith: ''
]

{ #category : 'private' }
MCPToolMethodMutationTest >> assertSuccessDataHasMethodShape: data [

	#( selector class package isExtension protocol source side action updateAction oldSelector newSelector
	   oldProtocol newProtocol ) do: [ :key | self deny: (data includesKey: key) ].
	(data includesKey: #changeKind) ifTrue: [ self assert: (#( 'created' 'replaced' ) includes: (data at: #changeKind)) ]
]

{ #category : 'private' }
MCPToolMethodMutationTest >> classChangeArguments [

	^ {
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
		  (#class -> aClass name).
		  (#side -> (aBoolean
			    ifTrue: [ 'class' ]
			    ifFalse: [ 'instance' ])).
		  (#source -> aMethodSource).
		  (#protocol -> aProtocol) } asDictionary
]

{ #category : 'private' }
MCPToolMethodMutationTest >> compileProbe: aMethodSource [
	"Compile aMethodSource into the mutation target under tests, answering the result."

	^ self callToolNamed: 'method_compile' withArguments: (self
			   compileArgumentsForClass: MCPToolMethodMutationTestTarget
			   classSide: false
			   methodSource: aMethodSource
			   protocol: 'tests')
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

{ #category : 'private - classes' }
MCPToolMethodMutationTest >> createProbeClassNamed: aClassName with: someArguments [
	"A class in the package tests generate, made by class_create, which takes shared variables and pools the same way in every Pharo."

	| arguments |
	arguments := someArguments asDictionary.
	arguments
		at: #name put: aClassName;
		at: #package put: self generatedPackageName;
		at: #tag put: self generatedTagName.
	self deny: (self resultIndicatesError: (self callToolNamed: 'class_create' withArguments: arguments))
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

{ #category : 'private - calling' }
MCPToolMethodMutationTest >> dataAnsweredThroughTheProtocolBy: aToolName arguments: someArguments [
	"The data a client reads from calling the tool with someArguments, the call and its answer written in JSON, so that their line endings are converted at the protocol boundary, as a client's are."

	| answer |
	answer := STONJSON fromString: (self handleJSON: (STONJSON toString: {
					            ('jsonrpc' -> '2.0').
					            ('id' -> 1).
					            ('method' -> 'tools/call').
					            ('params' -> {
						             ('name' -> aToolName).
						             ('arguments' -> someArguments) } asDictionary) } asDictionary)).
	^ ((answer at: 'result') at: 'structuredContent') at: 'data'
]

{ #category : 'private' }
MCPToolMethodMutationTest >> droppedHeaderWarning [

	^ 'The source began with the method''s reference, which was dropped: a method''s source starts with its selector line.'
]

{ #category : 'private' }
MCPToolMethodMutationTest >> extensionChangeArguments [

	^ {
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
MCPToolMethodMutationTest >> fixturePackageScope [
	"The fixtures and their senders are all in one package, so a refactoring scoped to it proves at a fraction of the cost what it proves image-wide. Two tests keep the image-wide default."

	^ self searchScope: { (#packages -> #( 'MCP-Tests-Resources' )) }
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
MCPToolMethodMutationTest >> lines: someLines [
	"someLines as one source, each line ending with a CR but the last, as a tool is handed a source a client wrote."

	^ String cr join: someLines
]

{ #category : 'private' }
MCPToolMethodMutationTest >> noteOnTheSendIn: aSource compiledInto: aClassName side: aSideOrNil [
	"Compile aSource, which sends one message that its receiver does not understand, and answer the note its critique adds after the rule's title, or nil when it adds none."

	| critiques result |
	result := self compileSource: aSource into: aClassName side: aSideOrNil.
	critiques := ((self dataFrom: result) at: #critiques) select: [ :each |
		             MCPToolCompileMethod new unimplementedSendRuleNames includes: (each at: #ruleClass) asSymbol ].
	self assert: critiques size equals: 1.
	^ critiques first at: #note ifPresent: [ :note |
			  self assert: ((self textFrom: result) includesSubstring:
					   (String streamContents: [ :stream | stream << (critiques first at: #title) << '. ' << note ])).
			  note ]
]

{ #category : 'private' }
MCPToolMethodMutationTest >> removeHeaderProbes [

	#( #headerProbe #headerProbe: #headerProbeTwo #HeaderProbe #'>=' #> #'>>' ) do: [ :each |
			self removeSelector: each from: MCPToolMethodMutationTestTarget.
			self removeSelector: each from: MCPToolMethodMutationTestTarget classSide ]
]

{ #category : 'private' }
MCPToolMethodMutationTest >> removeTonelProbes [

	#( #tonelProbe #tonelProbe: ) do: [ :each |
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
	"Remove what the tests add, and put back the fixture methods they change or remove."

	self removeSelector: #instanceAnswer from: MCPToolMethodMutationTestTarget.
	self removeSelector: #classAnswer from: MCPToolMethodMutationTestTarget classSide.
	self removeSelector: #multilineAnswer from: MCPToolMethodMutationTestTarget.
	self removeSelector: #multilineStringAnswer from: MCPToolMethodMutationTestTarget.
	self removeSelector: #uglyAnswer from: MCPToolMethodMutationTestTarget.
	self removeSelector: self renamedInstanceSelector from: MCPToolMethodMutationTestTarget.
	self removeSelector: self renamedClassSelector from: MCPToolMethodMutationTestTarget classSide.
	self removeSelector: self renamedInstanceProtocolSelector from: MCPToolMethodMutationTestTarget.
	self inferenceOutcomeSelectors do: [ :each | self removeSelector: each from: MCPToolMethodMutationTestTarget ].
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
MCPToolMethodMutationTest >> testACategoryLineAboveASourceGivesItsProtocol [
	"A Tonel category line kept above a method that begins with its selector line, or with its reference, gives the protocol, and the rest compiles as it would without it."

	| result |
	[
		result := self callToolNamed: 'method_compile' withArguments: {
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#source -> '{ #category : ''accessing'' }
tonelProbe
	^ 1') } asDictionary.
		self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
		self assert: (self warningsFrom: result) isEmpty.
		self assert: (MCPToolMethodMutationTestTarget >> #tonelProbe) protocolName asString equals: 'accessing'.

		result := self callToolNamed: 'method_compile' withArguments: {
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#source -> '{ #category : ''private'' }
MCPToolMethodMutationTestTarget >> tonelProbe
	^ 2') } asDictionary.
		self
			assert: (self summaryFrom: result)
			equals: 'Replaced MCPToolMethodMutationTestTarget>>tonelProbe, moving it from accessing to private.'.
		self assert: (self warningsFrom: result) equals: { self droppedHeaderWarning }.
		self assert: (MCPToolMethodMutationTestTarget new perform: #tonelProbe) equals: 2 ] ensure: [ self removeTonelProbes ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testAClassDefinitionIsRefusedForTheClassTools [
	"A class definition as a Tonel file writes it, its class comment above it and its methods after it, is refused before anything is compiled, saying which tools make and change a class."

	| error result |
	result := self callToolNamed: 'method_compile' withArguments: {
			          (#class -> MCPToolMethodMutationTestTarget name).
			          (#source -> '"
A target.
"
Class {
	#name : ''MCPToolMethodMutationTestTarget'',
	#superclass : ''Object'',
	#category : ''MCP-Tests-Resources''
}

{ #category : ''accessing'' }
MCPToolMethodMutationTestTarget >> tonelProbe [
	^ 5
]') } asDictionary.
	error := self errorFrom: result.
	self assert: (error at: #errorCode) equals: 'MethodSourceClassDefinition'.
	self assert: (error at: #definition) equals: 'Class {'.
	self
		assert: (self textFrom: result)
		equals:
		'The source is a class definition, as a Tonel file writes it, not a method. class_create makes a class and class_update changes one; compile its methods here.'.
	self deny: (MCPToolMethodMutationTestTarget includesSelector: #tonelProbe)
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testAHeaderWithNothingAfterItIsRefused [
	"A source that is only a method's reference names the method and writes none of it. Dropping the header would compile an empty method, replacing the body of one that exists, so it is refused and nothing is compiled. A body on the header's own line is a body."

	| result |
	[
		self ensureMethodSource: 'headerProbe ^ 1' protocol: 'tests' on: MCPToolMethodMutationTestTarget.
		result := self
			          compileSource: 'MCPToolMethodMutationTestTarget >> #headerProbe'
			          into: MCPToolMethodMutationTestTarget name
			          side: nil.
		self assert: (result at: #isError).
		self assert: ((self errorFrom: result) at: #errorCode) equals: 'MethodSourceHeader'.
		self assert: (MCPToolMethodMutationTestTarget new perform: #headerProbe) equals: 1.

		result := self
			          compileSource: 'MCPToolMethodMutationTestTarget >> headerProbe ^ 2'
			          into: MCPToolMethodMutationTestTarget name
			          side: nil.
		self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
		self assert: (MCPToolMethodMutationTestTarget new perform: #headerProbe) equals: 2 ] ensure: [ self removeHeaderProbes ].
	self
		assertClassSideHeaderIsRefusedIn: 'MCPToolMethodMutationTestTarget class>>headerProbe: a
	'
		side: nil.
	self assertHeaderIsRefusedIn: 'MCPToolMethodMutationTestTarget>>#headerProbe:with:' side: nil
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testAHeaderWithoutItsClassNamesTheCallsClass [
	"class>>selector and >>selector leave out the class, which the call names: the first names the class side, and the second the side the call gives. Each is dropped where a header naming the class would be. >> is a selector too, so a source that parses as written, as >> other does, is a method named >>, not a header."

	| result |
	[
		result := self
			          compileSource: 'class>>headerProbe: a
	^ a'
			          into: MCPToolMethodMutationTestTarget name
			          side: 'class'.
		self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
		self assert: (self summaryFrom: result) equals: 'Created MCPToolMethodMutationTestTarget class>>headerProbe:.'.
		self assert: (self warningsFrom: result) equals: { self droppedHeaderWarning }.
		self assert: (MCPToolMethodMutationTestTarget perform: #headerProbe: with: 3) equals: 3.

		result := self
			          compileSource: 'class >> #headerProbe
	^ 2'
			          into: MCPToolMethodMutationTestTarget name
			          side: nil.
		self assert: (self summaryFrom: result) equals: 'Created MCPToolMethodMutationTestTarget class>>headerProbe.'.
		self assert: (MCPToolMethodMutationTestTarget perform: #headerProbe) equals: 2.

		result := self
			          compileSource: '>>#headerProbe
	^ 1'
			          into: MCPToolMethodMutationTestTarget name
			          side: nil.
		self assert: (self summaryFrom: result) equals: 'Created MCPToolMethodMutationTestTarget>>headerProbe.'.
		self assert: (MCPToolMethodMutationTestTarget new perform: #headerProbe) equals: 1.

		result := self
			          compileSource: '>> #headerProbeTwo
	^ 4'
			          into: MCPToolMethodMutationTestTarget name
			          side: 'class'.
		self assert: (self summaryFrom: result) equals: 'Created MCPToolMethodMutationTestTarget class>>headerProbeTwo.'.
		self assert: (MCPToolMethodMutationTestTarget perform: #headerProbeTwo) equals: 4.

		result := self
			          compileSource: '>> other
	^ other'
			          into: MCPToolMethodMutationTestTarget name
			          side: nil.
		self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
		self assert: (self summaryFrom: result) equals: 'Created MCPToolMethodMutationTestTarget>>>>.'.
		self assert: (self warningsFrom: result) isEmpty.
		self assert: MCPToolMethodMutationTestTarget new >> 5 equals: 5 ] ensure: [ self removeHeaderProbes ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testAHeaderWithoutItsClassThatCannotBeDroppedIsRefused [
	"A header that leaves out its class is refused where one naming the class would be. A header after the comments a source begins with is refused too: dropping it would leave them above the selector line."

	self
		assertHeaderIsRefusedIn: 'class>>headerProbe:with:
	^ 1'
		side: 'class'.
	self
		assertClassSideHeaderIsRefusedIn: 'class>>headerProbe:with:
	^ 1'
		side: nil.
	self
		assertClassSideHeaderIsRefusedIn: 'class>>headerProbe: a
	^ a'
		side: 'instance'.
	self
		assertHeaderIsRefusedIn: '>>headerProbe:with:
	^ 1'
		side: nil.
	self
		assertHeader: 'class>>headerProbe: a'
		isRefusedIn: '"Instance creation"
class>>headerProbe: a
	^ a'
		side: nil
		closingWith: ' The header named the class side, so pass side class.'.
	self
		assertHeader: 'MCPToolMethodMutationTestTarget>>headerProbe'
		isRefusedIn: '"accessing"

MCPToolMethodMutationTestTarget>>headerProbe
	^ 1'
		side: nil
		closingWith: ''
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testAMethodEndingWithABlockKeepsItsBracket [
	"Only a bracket the source cannot parse with is dropped: a method whose last statement is a block parses as written and compiles with its bracket."

	[
		| result |
		result := self callToolNamed: 'method_compile' withArguments: {
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#protocol -> 'accessing').
				          (#source -> 'tonelProbe
	^ [ 4 ]') } asDictionary.
		self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
		self assert: ((MCPToolMethodMutationTestTarget >> #tonelProbe) sourceCode endsWith: '[ 4 ]').
		self assert: (MCPToolMethodMutationTestTarget new perform: #tonelProbe) value equals: 4 ] ensure: [ self removeTonelProbes ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testARefusedStatementOrBlockIsASyntaxError [
	"Pharo refuses a statement after a return, except 12 and 13, which compile it with a warning, and a block of sixteen arguments. Where the compiler's notice says what it refused and where, the answer is a syntax error there, not a failure to read the notice; from Pharo 14 on, what is refused while compiling comes without one."

	| error result |
	[
		#( 'refusedProbe ^ 1. 2' 'refusedProbe ^ [ :a1 :a2 :a3 :a4 :a5 :a6 :a7 :a8 :a9 :a10 :a11 :a12 :a13 :a14 :a15 :a16 | a1 ]' ) do: [
				:each |
				result := self compileProbe: each.
				(self resultIndicatesError: result) ifTrue: [
						error := self errorFrom: result.
						(error at: #causeClass) = 'OCCompilationError' ifFalse: [
								self assert: (error at: #errorCode) equals: 'CompileSyntaxError'.
								self assert: (error includesKey: #position) ] ] ] ] ensure: [
		self removeSelector: #refusedProbe from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testASourceEndingWithTheTonelClosingBracketCompilesWithoutIt [
	"A method copied out of a Tonel file keeps the bracket that closes it there, with or without the header and the bracket that opens it. The bracket closes nothing in the source, which compiles without it and says nothing of it. A second stray bracket is still refused."

	| result |
	[
		result := self callToolNamed: 'method_compile' withArguments: {
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#protocol -> 'accessing').
				          (#source -> 'tonelProbe
	^ 1
]') } asDictionary.
		self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
		self assert: (self summaryFrom: result) equals: 'Created MCPToolMethodMutationTestTarget>>tonelProbe.'.
		self assert: (self warningsFrom: result) isEmpty.
		self deny: ((MCPToolMethodMutationTestTarget >> #tonelProbe) sourceCode includes: $]).
		self assert: (MCPToolMethodMutationTestTarget new perform: #tonelProbe) equals: 1.

		result := self callToolNamed: 'method_compile' withArguments: {
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#source -> '{ #category : ''testing'' }
MCPToolMethodMutationTestTarget >> tonelProbe

	^ 2
]') } asDictionary.
		self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
		self
			assert: (self summaryFrom: result)
			equals: 'Replaced MCPToolMethodMutationTestTarget>>tonelProbe, moving it from accessing to testing.'.
		self assert: (MCPToolMethodMutationTestTarget new perform: #tonelProbe) equals: 2.

		result := self callToolNamed: 'method_compile' withArguments: {
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#source -> 'tonelProbe
	^ 3
]
]') } asDictionary.
		self assert: (result at: #isError ifAbsent: [ false ]).
		self assert:
			((self textFrom: result) beginsWith:
				 'Unable to compile method on MCPToolMethodMutationTestTarget: Missing opener for closer: ]').
		self assert: (MCPToolMethodMutationTestTarget new perform: #tonelProbe) equals: 2 ] ensure: [ self removeTonelProbes ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testATonelHeaderNamingAnotherClassOrSideIsRefused [
	"Dropping a Tonel header that names another class, or the other side than the call names, would compile where the call did not say. It is refused, saying what to pass, and nothing is compiled."

	| error result |
	result := self callToolNamed: 'method_compile' withArguments: {
			          (#class -> MCPToolMethodMutationTestTarget name).
			          (#source -> 'MCPToolMethodMutationTestSender >> tonelProbe [
	^ 1
]') } asDictionary.
	error := self errorFrom: result.
	self assert: (error at: #errorCode) equals: 'MethodSourceHeader'.
	self assert: (error at: #header) equals: 'MCPToolMethodMutationTestSender >> tonelProbe'.
	self
		assert: (self textFrom: result)
		equals:
		'The source is the Tonel method MCPToolMethodMutationTestSender >> tonelProbe, which goes in MCPToolMethodMutationTestSender, but the call compiles into MCPToolMethodMutationTestTarget on the instance side. Pass the class and side its header names, or correct the header.'.
	result := self callToolNamed: 'method_compile' withArguments: {
			          (#class -> MCPToolMethodMutationTestTarget name).
			          (#side -> 'instance').
			          (#source -> 'MCPToolMethodMutationTestTarget class >> tonelProbe [
	^ 1
]') } asDictionary.
	self
		assert: (self textFrom: result)
		equals:
		'The source is the Tonel method MCPToolMethodMutationTestTarget class >> tonelProbe, which goes in MCPToolMethodMutationTestTarget class, but the call compiles into MCPToolMethodMutationTestTarget on the instance side. Pass the class and side its header names, or correct the header.'.
	{
		MCPToolMethodMutationTestTarget.
		MCPToolMethodMutationTestSender } do: [ :each |
			self deny: (each includesSelector: #tonelProbe).
			self deny: (each classSide includesSelector: #tonelProbe) ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testATonelMethodCompilesWithItsCategory [
	"A method as a Tonel file writes it compiles without its header and brackets, wherever a bracket sits in its strings and comments. Its category line gives the protocol: a string in Tonel v2 and v3, a symbol in v1. A header naming the class side compiles there when the call names no side."

	| method result |
	[
		result := self callToolNamed: 'method_compile' withArguments: {
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#source -> '{ #category : ''accessing'' }
MCPToolMethodMutationTestTarget >> tonelProbe [

	"a ] in a comment"
	^ ''a ] in a string''
]') } asDictionary.
		self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
		self assert: (self summaryFrom: result) equals: 'Created MCPToolMethodMutationTestTarget>>tonelProbe.'.
		self assert: (self warningsFrom: result) isEmpty.
		method := MCPToolMethodMutationTestTarget >> #tonelProbe.
		self assert: (MCPToolMethodMutationTestTarget new perform: #tonelProbe) equals: 'a ] in a string'.
		self assert: method protocolName asString equals: 'accessing'.
		self assert: (method sourceCode beginsWith: 'tonelProbe').
		self assert: (method sourceCode includesSubstring: '"a ] in a comment"').

		result := self callToolNamed: 'method_compile' withArguments: {
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#source -> '{ #category : #''instance creation'' }
MCPToolMethodMutationTestTarget class >> tonelProbe: anObject [

	^ anObject
]') } asDictionary.
		self assert: (self summaryFrom: result) equals: 'Created MCPToolMethodMutationTestTarget class>>tonelProbe:.'.
		self assert: (MCPToolMethodMutationTestTarget perform: #tonelProbe: with: 3) equals: 3.
		self assert: (MCPToolMethodMutationTestTarget classSide >> #tonelProbe:) protocolName asString equals: 'instance creation' ]
		ensure: [ self removeTonelProbes ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testATonelMethodWithoutItsCategoryLineKeepsItsProtocol [
	"A Tonel method without its category line names no protocol, as a source that begins with its selector line and names none: the method it replaces keeps its own."

	| result |
	self ensureMethodSource: 'tonelProbe ^ 1' protocol: 'private' on: MCPToolMethodMutationTestTarget.
	[
		result := self callToolNamed: 'method_compile' withArguments: {
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#source -> 'MCPToolMethodMutationTestTarget >> tonelProbe [

	^ 2
]') } asDictionary.
		self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
		self assert: (self summaryFrom: result) equals: 'Replaced MCPToolMethodMutationTestTarget>>tonelProbe.'.
		self assert: (self warningsFrom: result) isEmpty.
		self assert: (MCPToolMethodMutationTestTarget >> #tonelProbe) protocolName asString equals: 'private'.
		self assert: (MCPToolMethodMutationTestTarget new perform: #tonelProbe) equals: 2 ] ensure: [ self removeTonelProbes ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testATonelPageCompilesEachOfItsMethods [
	"A source holding several methods as a Tonel file writes them, as a page class_get answers does, compiles each as its own, as a source array does, each in its own category and on its own side."

	| result |
	[
		result := self callToolNamed: 'method_compile' withArguments: {
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#source -> '{ #category : ''accessing'' }
MCPToolMethodMutationTestTarget >> tonelProbe [

	^ 1
]

{ #category : ''instance creation'' }
MCPToolMethodMutationTestTarget class >> tonelProbe: anObject [

	^ anObject
]
') } asDictionary.
		self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
		self assert: (self summaryFrom: result) equals: 'Compiled 2 of 2 methods.'.
		self assert: (MCPToolMethodMutationTestTarget >> #tonelProbe) protocolName asString equals: 'accessing'.
		self assert: (MCPToolMethodMutationTestTarget classSide >> #tonelProbe:) protocolName asString equals: 'instance creation'.
		self assert: (MCPToolMethodMutationTestTarget new perform: #tonelProbe) equals: 1.
		self assert: (MCPToolMethodMutationTestTarget perform: #tonelProbe: with: 2) equals: 2 ] ensure: [ self removeTonelProbes ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testAddArgumentWithoutPermutationMatchesArgumentsByName [

	| result widened |
	widened := self inferenceOutcomeSelectors second.
	result := self callToolNamed: 'method_update' withArguments: {
			          (#class -> MCPToolMethodMutationTestTarget name).
			          (#selector -> self inferenceSelector asString).
			          (#newSelector -> widened asString).
			          (#arguments -> #( 'first' 'second' 'extra' )).
			          (#argumentValueExpressions -> #( '''z''' )).
			          self fixturePackageScope } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (MCPToolMethodMutationTestTarget includesSelector: widened).
	self assert: (MCPToolMethodMutationTestTarget new perform: widened withArguments: #( 'a' 'b' 'c' )) equals: 'a-b'
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testAddArgumentsUpdatesClassSideSenders [

	| result senderSource |
	result := self callToolNamed: 'method_update' withArguments: {
			          (#class -> MCPToolMethodMutationTestTarget name).
			          (#side -> 'class').
			          (#selector -> 'buildValue:').
			          (#newSelector -> 'buildValue:prefix:').
			          (#arguments -> #( 'aString' 'prefix' )).
			          (#argumentValueExpressions -> #( 'nil' )) } asDictionary.
	self dataFrom: result.
	senderSource := (MCPToolMethodMutationTestSender >> #callClassTarget) sourceCode.
	self assert: (MCPToolMethodMutationTestTarget classSide includesSelector: #buildValue:prefix:).
	self assert: (senderSource includesSubstring: 'prefix: nil').
	self assert: MCPToolMethodMutationTestSender new callClassTarget equals: 'Class-value'
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testAddArgumentsUpdatesSendersAndReportsAction [

	| result senderSource targetSource |
	result := self callToolNamed: 'method_update' withArguments: {
			          (#class -> MCPToolMethodMutationTestTarget name).
			          (#side -> 'instance').
			          (#selector -> 'combine:with:').
			          (#newSelector -> 'combine:with:separator:').
			          (#arguments -> #( 'first' 'second' 'separator' )).
			          (#argumentValueExpressions -> (Array with: (String streamContents: [ :stream |
						             stream
							             nextPut: $';
							             nextPut: $|;
							             nextPut: $' ]))).
			          self fixturePackageScope } asDictionary.
	self dataFrom: result.
	targetSource := (MCPToolMethodMutationTestTarget >> #combine:with:separator:) sourceCode.
	senderSource := (MCPToolMethodMutationTestSender >> #callInstanceTarget) sourceCode.
	self assert: (targetSource includesSubstring: 'separator: separator').
	self assert: (senderSource includesSubstring: 'separator: ''|''').
	self assert: MCPToolMethodMutationTestSender new callInstanceTarget equals: 'first-second'
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testAddingArgumentsAsksForTheirNames [
	"A new selector with more keywords needs a name for each argument it adds, and the refusal names the argument that gives them."

	| error |
	error := self errorFrom: (self callToolNamed: 'method_update' withArguments: {
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#selector -> self instanceSelector asString).
				          (#newSelector -> 'combine:with:separator:') } asDictionary).
	self assert: (error at: #errorCode) equals: 'ArgumentNamesRequiredForAddedArguments'.
	self assert: (error at: #message) equals: 'arguments is required when newSelector adds method arguments.'
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testAnUnterminatedLeadingCommentIsASyntaxError [
	"A header is looked for past the comments a source begins with. A comment that is never closed holds the rest of the source, so there is no header to find, and the compiler's answer is the one given."

	| error result |
	[
		result := self
			          compileSource: '"Instance creation
headerProbe
	^ 1'
			          into: MCPToolMethodMutationTestTarget name
			          side: nil.
		error := self errorFrom: result.
		self assert: (result at: #isError).
		self assert: (error at: #errorCode) equals: 'CompileSyntaxError'.
		self deny: (MCPToolMethodMutationTestTarget includesSelector: #headerProbe) ] ensure: [ self removeHeaderProbes ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testArgumentListsWithoutANewSelectorAreRefused [
	"The argument lists say what the arguments of a new selector are, so without one they have nothing to describe."

	| error |
	error := self errorFrom: (self callToolNamed: 'method_update' withArguments: {
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#selector -> self instanceSelector asString).
				          (#protocol -> 'accessing').
				          (#arguments -> #( 'first' 'second' )) } asDictionary).
	self assert: (error at: #errorCode) equals: 'ArgumentMetadataRequiresMethodSelectorUpdate'.
	self assert: (error at: #message) equals: 'arguments and argumentValueExpressions are only valid with newSelector.'
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
	lines := (self textFrom: result) lines.
	self assert: (lines first: 4) asArray equals: {
			'Did not compile MCPToolMethodMutationTestTarget>>deadBlockProbe, because a critique blocks compiling it:'.
			('line 1: ' , title).
			'  [ self error: ''never run'' ]'.
			'Correct the source and compile it again.' }.
	self assert: (error at: #howToProceed) equals: 'Correct the source and compile it again.'.
	result := self callToolNamed: 'method_compile' withArguments: (self
			           compileArgumentsForClass: MCPToolMethodMutationTestTarget
			           classSide: true
			           methodSource: 'deadBlockProbe
	[ 1 ].
	[ 2 ]'
			           protocol: 'tests').
	lines := (self textFrom: result) lines.
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

	| error result |
	self removeSelector: self instanceProtocolSelector from: MCPToolMethodMutationTestTarget.
	result := self callToolNamed: 'method_update' withArguments: self instanceChangeArguments.
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
	self assert: error keys asSet equals: #( action updateAction errorClass errorCode message class side selector protocol ) asSet
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testChangesClassSideMethodProtocol [

	| data result |
	result := self callToolNamed: 'method_update' withArguments: self classChangeArguments.
	data := self dataFrom: result.
	self
		assert: (MCPToolMethodMutationTestTarget classSide >> self classProtocolSelector) protocolName asString
		equals: 'instance creation'.
	self assertSuccessDataHasMethodShape: data
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testChangesInstanceSideMethodProtocol [

	| data result |
	result := self callToolNamed: 'method_update' withArguments: self instanceChangeArguments.
	data := self dataFrom: result.
	self assert: (MCPToolMethodMutationTestTarget >> self instanceProtocolSelector) protocolName asString equals: 'accessing'.
	self assertSuccessDataHasMethodShape: data
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testChangingExtensionMethodProtocolUpdatesPackageMetadata [

	| data result |
	result := self callToolNamed: 'method_update' withArguments: self extensionChangeArguments.
	data := self dataFrom: result.
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
			           MCPDetectIfFoundRule }.
		           {
			           #smalltalkGlobalsProbe.
			           'smalltalkGlobalsProbe ^ Smalltalk globals at: #Object'.
			           MCPSmalltalkGlobalsRule } }.
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
		result := self callToolNamed: 'method_compile' withArguments: (self
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
		result := self callToolNamed: 'method_compile' withArguments: (self
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
		result := self callToolNamed: 'method_compile' withArguments: (self
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
	result := self callToolNamed: 'method_compile' withArguments: (self
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
	self assert: (data at: #changeKind) equals: 'replaced'
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileCritiqueQuotesACommentOnOneLine [
	"A comment changes nothing in the program, so a quote reads the blanks and line breaks in it as the code around it: one space each run, and the quote stays on one line. The formatter keeps a comment that opens a block where it is."

	| codes result |
	self removeSelector: #commentQuoteProbe from: MCPToolMethodMutationTestTarget.
	[
		result := self compileProbe: 'commentQuoteProbe
	^ self mcpQuoted: [ "a   comment
	on two lines" 3 ]'.
		codes := ((self dataFrom: result) at: #critiques)
			         select: [ :each | (each at: #ruleClass) = ReSentNotImplementedRule name asString ]
			         thenCollect: [ :each | each at: #code ].
		self assert: codes asArray equals: #( 'self mcpQuoted: [ "a comment on two lines" 3 ]' ).
		self assert: ((self textFrom: result) lines includes: '    self mcpQuoted: [ "a comment on two lines" 3 ]') ] ensure: [
		self removeSelector: #commentQuoteProbe from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileCritiqueQuotesItsCodeAcrossLines [
	"The formatter puts a cascade's receiver on a line of its own, so the code a critique of its first message flags starts on a line that holds only the receiver. The quote follows that code onto the next lines, each run of blanks and line breaks read as one space."

	| critique result |
	self removeSelector: #cascadeQuoteProbe from: MCPToolMethodMutationTestTarget.
	[
		result := self compileProbe: 'cascadeQuoteProbe ^ String streamContents: [ :stream | stream << self printString; cr ]'.
		critique := ((self dataFrom: result) at: #critiques) detect: [ :each |
			            (each at: #ruleClass) = MCPPrintOnStreamRule name asString ].
		self assert: (critique at: #code) equals: 'stream << self printString'.
		self assert: ((self textFrom: result) lines includes: '    stream << self printString') ] ensure: [
		self removeSelector: #cascadeQuoteProbe from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileCritiqueQuotesLiteralsAsWritten [
	"A quote reads each run of blanks and line breaks between tokens as one space, but quotes a string, symbol or character literal as written: 'a   b' is another string than 'a b', and a character literal of a space keeps its space, at the end of the quote too."

	| codes result |
	self removeSelector: #literalQuoteProbe from: MCPToolMethodMutationTestTarget.
	[
		result := self compileProbe: 'literalQuoteProbe
	self mcpQuoted: $  with: ''a   b''.
	^ self mcpQuoted: #''c   d'' with: $ ; yourself'.
		codes := ((self dataFrom: result) at: #critiques)
			         select: [ :each | (each at: #ruleClass) = ReSentNotImplementedRule name asString ]
			         thenCollect: [ :each | each at: #code ].
		self assert: codes asArray equals: #( 'self mcpQuoted: $  with: ''a   b''' 'self mcpQuoted: #''c   d'' with: $ ' ).
		self assert: ((self textFrom: result) lines includes: '    self mcpQuoted: #''c   d'' with: $ ') ] ensure: [
		self removeSelector: #literalQuoteProbe from: MCPToolMethodMutationTestTarget ]
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
		self assert: ((self textFrom: result) lines includes: '    True') ] ensure: [
		self removeSelector: #storedCodeProbe from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileCritiquesReadAsLines [
	"A critique reads as the line it starts on and what it found, under a label saying how lines are counted, never as character offsets of a source the caller does not see."

	| lines result |
	self removeSelector: #critiqueLinesProbe from: MCPToolMethodMutationTestTarget.
	[
		result := self compileProbe: 'critiqueLinesProbe ^ ''a'' , self printString , ''b'''.
		lines := (self textFrom: result) lines.
		self assert: lines first equals: 'Created MCPToolMethodMutationTestTarget>>critiqueLinesProbe.'.
		self assert: lines second equals: 'critiques (line numbers count the method as stored; method_get shows it):'.
		self assert: ((lines at: 3) beginsWith: '  line 3: ').
		self deny: (lines anySatisfy: [ :each | each matchesRegex: '.*\d+-\d+.*' ]).
		self removeSelector: #critiqueLinesProbe from: MCPToolMethodMutationTestTarget.
		result := self compileProbe: 'critiqueLinesProbe ^ 1'.
		self deny: (self resultIndicatesError: result).
		self deny: ((self textFrom: result) includesSubstring: 'critiques') ] ensure: [
		self removeSelector: #critiqueLinesProbe from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileDefaultsToInstanceSideWhenClassSideIsOmitted [

	| data result |
	result := self callToolNamed: 'method_compile' withArguments: {
			          (#class -> MCPToolMethodMutationTestTarget name).
			          (#source -> 'instanceAnswer ^ 42').
			          (#protocol -> 'tests') } asDictionary.
	data := self dataFrom: result.
	self assert: MCPToolMethodMutationTestTarget new instanceAnswer equals: 42.
	self deny: (MCPToolMethodMutationTestTarget classSide includesSelector: #instanceAnswer).
	self assertSuccessDataHasMethodShape: data
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
	self deny: (self class environment includesKey: #Zzqxw)
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
MCPToolMethodMutationTest >> testCompileMethodAnswersItsSummaryAsText [

	[
		self
			assert: (self textFrom: (self callToolNamed: 'method_compile' withArguments: {
							  (#class -> MCPToolMethodMutationTestTarget name).
							  (#protocol -> 'accessing').
							  (#source -> 'mcpPlainTextContentFixture

	^ 42') } asDictionary))
			equals: 'Created MCPToolMethodMutationTestTarget>>mcpPlainTextContentFixture.' ] ensure: [
		self removeSelector: #mcpPlainTextContentFixture from: MCPToolMethodMutationTestTarget ]
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
MCPToolMethodMutationTest >> testCompileNamesASourceHoldingSeveralMethods [
	"Methods written one after the other in one source fail where the second begins, the compiler reading its selector line as a name it does not know or as a keyword without a receiver, or further on, reading its body as the rest of the first method's last statement until a return, temporaries or a comment no longer continue it. A second method may also begin with its reference, as method_get prints it. The answer names the source for what it is, and says how several methods are passed."

	[
		{
			('probeFirst

	self yourself.

probeSecond

	self yourself' -> #( 5 'probeSecond' )).
			('probeFirst

	self yourself.

probeSecond: anObject

	self yourself' -> #( 5 'probeSecond:' )).
			('probeFirst
	^ 1.

probeSecond
	^ 2' -> #( 4 'probeSecond' )).
			('probeFirst
	^ 1.

probeSecond
	| value |
	value := 2.
	^ value' -> #( 4 'probeSecond' )).
			('probeFirst
	^ 1.

probeSecond
	"Answer two."
	^ 2' -> #( 4 'probeSecond' )).
			('probeFirst
	^ 1.

MCPToolMethodMutationTestTarget >> probeSecond
	^ 2' -> #( 4 'probeSecond' )) } do: [ :each |
				| error result |
				result := self compileSource: each key into: MCPToolMethodMutationTestTarget name side: nil.
				error := self errorFrom: result.
				self assert: (result at: #isError).
				self assert: (error at: #errorCode) equals: 'MethodSourceHoldsSeveralMethods'.
				self assert: (error at: #line) equals: each value first.
				self assert: (error at: #nextSelector) equals: each value second.
				self
					assert: (self textFrom: result)
					equals:
						('The source holds more than one method: {1} starts another at line {2}. Pass each method as its own string in a source array.'
							 format: {
									 each value second.
									 each value first printString }) ].
		self deny: (MCPToolMethodMutationTestTarget includesSelector: #probeFirst) ] ensure: [
		self removeSelector: #probeFirst from: MCPToolMethodMutationTestTarget ]
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
		lines := (self textFrom: result) lines select: [ :each | each beginsWith: '  line ' ].
		self assert: lines size equals: 2.
		self assert: (lines anySatisfy: [ :each | each endsWith: ' (method_rewrite ruleClasses: MCPStringConcatenationRule)' ]).
		self deny: (lines anySatisfy: [ :each | each includesSubstring: 'ReUsesTrueRule' ]).
		self assert: (MCPMethodRewriteNamedRuleSpec canApplyRuleClass: MCPStringConcatenationRule).
		self deny: (MCPMethodRewriteNamedRuleSpec canApplyRuleClass: ReUsesTrueRule).
		self deny: (MCPMethodRewriteNamedRuleSpec canApplyRuleClass: Object) ] ensure: [
		self removeSelector: #fixableProbe from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileOffersNoRewriteThatCanChangeWhatAMethodAnswers [
	"Pharo's rules for a conditional sent to isNil, notNil or isNotNil rewrite a one-armed one whether or not the method reads its value: ^ x isNil ifTrue: [ 1 ] becomes ^ x ifNil: [ 1 ], which answers x when x is set. The compile answer names the idiom but not method_rewrite, even on a hit whose rewrite keeps what the method answers, since method_rewrite rewrites at least a whole class."

	| sources |
	sources := OrderedCollection new.
	sources
		add: 'nilConditionalProbe: x ^ x isNil ifTrue: [ 1 ]';
		add: 'nilConditionalProbe: x x isNil ifTrue: [ ^ 1 ] ifFalse: [ ^ 2 ]'.
	(self class environment includesKey: #ReIsNotNilAndConditionalRule) ifTrue: [
		sources add: 'nilConditionalProbe: x ^ x notNil ifFalse: [ 1 ]' ].
	self removeSelector: #nilConditionalProbe: from: MCPToolMethodMutationTestTarget.
	[
		sources do: [ :source |
				| critique result |
				result := self compileProbe: source.
				critique := ((self dataFrom: result) at: #critiques) detect: [ :each |
					            (each at: #ruleClass) endsWith: 'NilAndConditionalRule' ].
				self deny: (critique includesKey: #fixable) description: source.
				self deny: ((self textFrom: result) includesSubstring: 'ruleClasses: ReIs') description: source ].
		self assert: (MCPMethodRewriteNamedRuleSpec canApplyRuleClass: ReIsNilAndConditionalRule) ] ensure: [
		self removeSelector: #nilConditionalProbe: from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileOffersTheClassSideOnlyToAMisplacedConstructor [
	"A send to a class whose instances have the method may mean the method belongs on the class side, as a constructor compiled on the instance side. The critique offers to compile it there only when it is one, as evaluate and test_run do: compiled since the image shipped, it sends new to self, which an instance cannot run. Any other method is sent to an instance, as label:, a setter sent to the class when new was forgotten, or add:, one of Pharo's own. That holds whether the receiver is the class's name or self in a class-side method, where the note first says what self is."

	| target |
	target := MCPNotUnderstoodNoteTestTarget name.
	[
		{
			({
				 'critiqueNoteProbe ^ MCPNotUnderstoodNoteTestTarget withLabel: ''a'''.
				 MCPToolMethodMutationTestTarget name.
				 nil }
			 ->
			 'MCPNotUnderstoodNoteTestTarget itself does not understand withLabel:, its instances do: it is on the instance side. It sends new to self, which instances of MCPNotUnderstoodNoteTestTarget do not understand: compile it with method_compile and side class to send it to MCPNotUnderstoodNoteTestTarget.').
			({
				 'critiqueNoteProbe ^ MCPNotUnderstoodNoteTestTarget label: ''a'''.
				 MCPToolMethodMutationTestTarget name.
				 nil }
			 ->
			 'MCPNotUnderstoodNoteTestTarget itself does not understand label:, its instances do: it is on the instance side. Send it to an instance.').
			({
				 'critiqueNoteProbe ^ OrderedCollection add: 3'.
				 MCPToolMethodMutationTestTarget name.
				 nil }
			 -> 'OrderedCollection itself does not understand add:, its instances do: it is on the instance side. Send it to an instance.').
			({
				 'critiqueNoteProbe ^ self withLabel: ''a'''.
				 target.
				 'class' }
			 ->
			 'This method is on the class side, where self is MCPNotUnderstoodNoteTestTarget. MCPNotUnderstoodNoteTestTarget itself does not understand withLabel:, its instances do: it is on the instance side. It sends new to self, which instances of MCPNotUnderstoodNoteTestTarget do not understand: compile it with method_compile and side class to send it to MCPNotUnderstoodNoteTestTarget.').
			({
				 'critiqueNoteProbe ^ self label: ''a'''.
				 target.
				 'class' }
			 ->
			 'This method is on the class side, where self is MCPNotUnderstoodNoteTestTarget. MCPNotUnderstoodNoteTestTarget itself does not understand label:, its instances do: it is on the instance side. Send it to an instance.') }
			do: [ :each |
				self assert: (self noteOnTheSendIn: each key first compiledInto: each key second side: each key third) equals: each value ] ]
		ensure: [
				self removeSelector: #critiqueNoteProbe from: MCPToolMethodMutationTestTarget.
				self removeSelector: #critiqueNoteProbe from: MCPNotUnderstoodNoteTestTarget classSide ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileQuotesALongSendInParenthesesWithoutTheClosingOne [
	"A critique of a send written in parentheses flags them too. Quoted from its first keyword, the send leaves out the closing one, as the opening one goes with its receiver."

	| critique result |
	self removeSelector: #parenthesizedSendProbe from: MCPToolMethodMutationTestTarget.
	[
		result := self compileProbe:
			          'parenthesizedSendProbe ^ (self printString mcpProbeSorted: [ :a :b | a < b ] collect: [ :e | e ]) size'.
		critique := ((self dataFrom: result) at: #critiques) detect: [ :each |
			            (each at: #ruleClass) = ReSentNotImplementedRule name asString ].
		self assert: (critique at: #code) equals: 'mcpProbeSorted: [ :a :b | a < b ] collect: [ :e | e ]' ] ensure: [
		self removeSelector: #parenthesizedSendProbe from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileQuotesALongUnimplementedSendFromItsSelector [
	"A critique of a send that nothing implements names its selector, so a send too long to quote whole is quoted from its first keyword, on that keyword's line: from its receiver, the receiver and the first argument would leave the other keywords out of the quote, and the formatter may put the receiver of a send this long on a line of its own."

	| critique result storedLines |
	self removeSelector: #unimplementedKeywordsProbe from: MCPToolMethodMutationTestTarget.
	[
		result := self compileProbe:
			          'unimplementedKeywordsProbe ^ self printString asSymbol keywords mcpProbeSorted: [ :a :b | a size < b size ] collect: [ :each | each asUppercase asSymbol printString reversed ]'.
		critique := ((self dataFrom: result) at: #critiques) detect: [ :each |
			            (each at: #ruleClass) = ReSentNotImplementedRule name asString ].
		storedLines := (MCPToolMethodMutationTestTarget >> #unimplementedKeywordsProbe) sourceCode lines.
		self assert: (critique at: #line) equals: (storedLines findFirst: [ :each | each includesSubstring: 'mcpProbeSorted:' ]).
		self assert: ((critique at: #code) beginsWith: 'mcpProbeSorted: [ :a :b | a size < b size ] collect: ') ] ensure: [
		self removeSelector: #unimplementedKeywordsProbe from: MCPToolMethodMutationTestTarget ]
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
		self assert: ((self textFrom: result) lines count: [ :each | each beginsWith: '  line ' ]) equals: 1 ] ensure: [
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
MCPToolMethodMutationTest >> testCompileReturnsAllowlistedIsNilAndConditionalCritique [

	| selector |
	selector := #isNilAndConditional:.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClass: MCPToolGetMethodTestTarget
			methodSource: 'isNilAndConditional: anObject anObject isNil ifTrue: [ ^ 1 ]. ^ 2'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'ReIsNilAndConditionalRule'
			titledLike: 'isNil' ] ensure: [ self removeSelector: selector from: MCPToolGetMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileReturnsAllowlistedIsNotNilAndConditionalCritique [
	"Pharo's rule advises ifNotNil:, and MCPIsNotNilRule stays quiet on a notNil that a conditional is sent to rather than advise isNotNil."

	| selector |
	(self class environment includesKey: #ReIsNotNilAndConditionalRule) ifFalse: [
		^ self skip: 'This Pharo version has no ReIsNotNilAndConditionalRule.' ].
	selector := #isNotNilAndConditional:.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClass: MCPToolGetMethodTestTarget
			methodSource: 'isNotNilAndConditional: anObject anObject notNil ifTrue: [ ^ 1 ]. ^ 2'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'ReIsNotNilAndConditionalRule'
			titledLike: 'notNil' ] ensure: [ self removeSelector: selector from: MCPToolGetMethodTestTarget ]
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
MCPToolMethodMutationTest >> testCompileReturnsAllowlistedUseIsEmptyNotSizeCritique [

	| selector |
	selector := #sizeIsZero:.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClass: MCPToolGetMethodTestTarget
			methodSource: 'sizeIsZero: aCollection ^ aCollection size = 0'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'ReUseIsEmptyNotSizeRule'
			titledLike: '#isEmpty' ] ensure: [ self removeSelector: selector from: MCPToolGetMethodTestTarget ]
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
					self assert: ((self callToolNamed: 'method_compile' withArguments: (self
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
	result := self callToolNamed: 'method_compile' withArguments: (self
			           compileArgumentsForClass: MCPToolMethodMutationTestTarget
			           classSide: false
			           methodSource: 'instanceProtocolTarget ^ True = true'
			           protocol: 'tests').
	data := self dataFrom: result.
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
MCPToolMethodMutationTest >> testCompileReturnsSmalltalkGlobalsCritique [

	| selector |
	selector := #smalltalkGlobalsProbe.
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		self
			assertCompileForClass: MCPToolGetMethodTestTarget
			methodSource: 'smalltalkGlobalsProbe ^ Smalltalk globals at: #Object'
			protocol: 'tests'
			returnsSingleCritiqueRuleClass: 'MCPSmalltalkGlobalsRule'
			titledLike: MCPSmalltalkGlobalsRule ruleName ] ensure: [ self removeSelector: selector from: MCPToolGetMethodTestTarget ]
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
	result := self callToolNamed: 'method_compile' withArguments: (self
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

	| error result text |
	self removeSelector: #brokenMethod from: MCPToolMethodMutationTestTarget.
	result := self callToolNamed: 'method_compile' withArguments: (self
			           compileArgumentsForClass: MCPToolMethodMutationTestTarget
			           classSide: false
			           methodSource: 'brokenMethod ^ 1 +'
			           protocol: 'tests').
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

	| error result |
	self removeSelector: #brokenMethod from: MCPToolMethodMutationTestTarget.
	result := self callToolNamed: 'method_compile' withArguments: (self
			           compileArgumentsForClass: MCPToolMethodMutationTestTarget
			           classSide: false
			           methodSource: 'brokenMethod ^ missingVar'
			           protocol: 'tests').
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
MCPToolMethodMutationTest >> testCompileSaysAChainedKeywordSendIsOneMessage [
	"sorted:collect:, which nothing implements, reads as sorted: then collect:, which are both methods. Its critique says that it is one message and how to send the two; a send whose keywords make no such pair gets no such note."

	| critiques note result |
	self removeSelector: #chainedSendProbe from: MCPToolMethodMutationTestTarget.
	[
		result := self compileProbe:
			          'chainedSendProbe ^ (self printString sorted: [ :a :b | a < b ] collect: [ :each | each ]) -> (self printString mcpProbeSorted: 1 collect: 2)'.
		critiques := ((self dataFrom: result) at: #critiques) select: [ :each |
			             (each at: #ruleClass) = ReSentNotImplementedRule name asString ].
		self assert: critiques size equals: 2.
		note := (critiques detect: [ :each | ((each at: #code) includesSubstring: 'mcpProbeSorted:') not ]) at: #note.
		self
			assert: note
			equals:
			'sorted:collect: is one message. To send collect: to what sorted: answers, put the sorted: send in parentheses: (... sorted: ...) collect: ...'.
		self assert: ((self textFrom: result) includesSubstring: 'Messages sent but not implemented. ' , note).
		self deny: ((critiques detect: [ :each | (each at: #code) includesSubstring: 'mcpProbeSorted:' ]) includesKey: #note) ] ensure: [
		self removeSelector: #chainedSendProbe from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileSaysAClassVariableSentAsAMessageIsAVariable [
	"A unary send to a class that names one of its class variables, as Units Dozen, reads the variable as a message. The critique says that it is a class variable, and how the method's class reads it: by name where it is in scope, as in the class itself or in a class that uses it as a pool, and through a method of its class elsewhere."

	| pool user |
	pool := 'MCPToolCompileUnitsProbe'.
	user := 'MCPToolCompileStockProbe'.
	self createProbeClassNamed: pool with: {
			(#superclass -> 'SharedPool').
			(#sharedVariables -> #( 'ProbeDozen' )) }.
	self createProbeClassNamed: user with: { (#sharedPools -> { pool }) }.
	[
		{
			({
				 'critiqueNoteProbe ^ MCPToolCompileUnitsProbe ProbeDozen'.
				 user.
				 nil }
			 ->
			 'ProbeDozen is a class variable of MCPToolCompileUnitsProbe, not a message. MCPToolCompileStockProbe can read it by name: write ProbeDozen alone.').
			({
				 'critiqueNoteProbe ^ self ProbeDozen'.
				 pool.
				 'class' }
			 ->
			 'ProbeDozen is a class variable of MCPToolCompileUnitsProbe, not a message. MCPToolCompileUnitsProbe can read it by name: write ProbeDozen alone.').
			({
				 'critiqueNoteProbe ^ MCPToolCompileUnitsProbe ProbeDozen'.
				 MCPToolMethodMutationTestTarget name.
				 nil }
			 ->
			 'ProbeDozen is a class variable of MCPToolCompileUnitsProbe, not a message. MCPToolMethodMutationTestTarget cannot read it by name: only MCPToolCompileUnitsProbe, its subclasses and the classes that use it as a pool can. Add a class-side method to MCPToolCompileUnitsProbe that answers it, and send that.') }
			do: [ :each |
				self assert: (self noteOnTheSendIn: each key first compiledInto: each key second side: each key third) equals: each value ] ]
		ensure: [
				self removeSelector: #critiqueNoteProbe from: MCPToolMethodMutationTestTarget.
				self removeClassNamed: user.
				self removeClassNamed: pool ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileSaysASlotSentAsAMessageHasNoAccessor [
	"A send to the object running the method that is a slot's name, or its name and a colon, is an accessor nothing defines. The critique says the slot has no accessor and that the method can read or assign it directly. A slot of the other side is not one the method sees, so it gets no such note."

	| className |
	className := 'MCPToolCompileSlotProbe'.
	self
		createClassNamed: className
		superclassName: 'Object'
		slots: #( #probeQuantity )
		classSlots: #( #probeMade ).
	[
		{
			({ 'critiqueNoteProbe MCPToolCompileSlotProbe probeMade: 0'. 'class' }
			 ->
			 'probeMade is a class-side slot of MCPToolCompileSlotProbe with no accessor probeMade:. This method can assign it directly, as probeMade := ...').
			({ 'critiqueNoteProbe ^ self probeMade'. 'class' }
			 ->
			 'probeMade is a class-side slot of MCPToolCompileSlotProbe with no accessor probeMade. This method can read it directly, as probeMade.').
			({ 'critiqueNoteProbe ^ self probeQuantity'. nil }
			 ->
			 'probeQuantity is an instance-side slot of MCPToolCompileSlotProbe with no accessor probeQuantity. This method can read it directly, as probeQuantity.').
			({ 'critiqueNoteProbe ^ self probeMade'. nil } -> nil) } do: [ :each |
			self assert: (self noteOnTheSendIn: each key first compiledInto: className side: each key second) equals: each value ] ]
		ensure: [ self removeClassNamed: className ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileSaysAnUndeclaredNameIsASlotOfTheOtherSide [
	"A slot one side of a class defines is undeclared in the methods of the other side, and nothing in the source says which side it was written for. The class side's own slots are the class's, not those every class has from Class. A class written as Foo class, or a source that begins with the method's reference, names a side of its own, so the way to the other side says to drop it."

	| className |
	className := 'MCPToolCompileSideProbe'.
	self
		createClassNamed: className
		superclassName: 'Object'
		slots: #( #probeQuantity )
		classSlots: #( #probeMade ).
	[
		{
			({
				 'probeReset
	probeMade := 0'.
				 className.
				 nil }
			 ->
			 'Unable to compile method on MCPToolCompileSideProbe: Undeclared variable: probeMade. probeMade is a class-side slot of MCPToolCompileSideProbe, which instance-side methods do not see. Compile this method with side class, or reach probeMade through a class-side method.').
			({
				 'probeReset
	probeQuantity := 0'.
				 className.
				 'class' }
			 ->
			 'Unable to compile method on MCPToolCompileSideProbe class: Undeclared variable: probeQuantity. probeQuantity is an instance-side slot of MCPToolCompileSideProbe, which class-side methods do not see. Compile this method with side instance, or reach probeQuantity through an instance-side method.').
			({
				 'probeReset
	probeQuantity := 0'.
				 (className , ' class').
				 nil }
			 ->
			 'Unable to compile method on MCPToolCompileSideProbe class: Undeclared variable: probeQuantity. probeQuantity is an instance-side slot of MCPToolCompileSideProbe, which class-side methods do not see. Compile this method with class MCPToolCompileSideProbe and side instance, or reach probeQuantity through an instance-side method.').
			({
				 (className , ' class >> probeReset
	probeQuantity := 0').
				 className.
				 nil }
			 ->
			 'Unable to compile method on MCPToolCompileSideProbe class: Undeclared variable: probeQuantity. probeQuantity is an instance-side slot of MCPToolCompileSideProbe, which class-side methods do not see. Compile this method with side instance and a source that starts with its selector line, or reach probeQuantity through an instance-side method.').
			({
				 (className , ' >> probeReset
	probeMade := 0').
				 className.
				 'instance' }
			 ->
			 'Unable to compile method on MCPToolCompileSideProbe: Undeclared variable: probeMade. probeMade is a class-side slot of MCPToolCompileSideProbe, which instance-side methods do not see. Compile this method with side class and a source that starts with its selector line, or reach probeMade through a class-side method.').
			({
				 'probeName
	^ name'.
				 className.
				 nil } -> 'Unable to compile method on MCPToolCompileSideProbe: Undeclared variable: name') } do: [ :each |
				self
					assert: (self summaryFrom: (self compileSource: each key first into: each key second side: each key third))
					equals: each value ].
		self deny: ((self classNamed: className) includesSelector: #probeReset).
		self deny: ((self classNamed: className) classSide includesSelector: #probeReset) ] ensure: [ self removeClassNamed: className ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileSaysWhichSideUnderstandsASend [
	"A send the receiver does not understand while the other side of its class does, as a constructor compiled on the instance side and sent to the class, says which side has it and what to do from where the method is. On the instance side, a method only counts when the class side defines it, as buildValue:, or when it is an instance creation method of Behavior, as new. What every class has from Class or Behavior, as name, is an accessor the instance lacks, not a message for self class. A send neither side understands gets no such note."

	| target |
	target := MCPToolMethodMutationTestTarget name.
	[
		{
			({ 'critiqueNoteProbe ^ self new'. nil }
			 ->
			 'Instances of MCPToolMethodMutationTestTarget do not understand new, MCPToolMethodMutationTestTarget itself does: this method is on the instance side, where self is an instance. Send it to self class, or compile this method with side class.').
			({ 'critiqueNoteProbe ^ self buildValue: 3'. nil }
			 ->
			 'Instances of MCPToolMethodMutationTestTarget do not understand buildValue:, MCPToolMethodMutationTestTarget itself does: this method is on the instance side, where self is an instance. Send it to self class, or compile this method with side class.').
			({ 'critiqueNoteProbe ^ self name'. nil } -> nil).
			({ 'critiqueNoteProbe ^ MCPToolMethodMutationTestTarget combine: ''a'' with: ''b'''.
			 nil }
			 ->
			 'MCPToolMethodMutationTestTarget itself does not understand combine:with:, its instances do: it is on the instance side. Send it to an instance.').
			({ 'critiqueNoteProbe ^ self combine: ''a'' with: ''b'''. 'class' }
			 ->
			 'This method is on the class side, where self is MCPToolMethodMutationTestTarget. MCPToolMethodMutationTestTarget itself does not understand combine:with:, its instances do: it is on the instance side. Send it to an instance.').
			({ 'critiqueNoteProbe ^ self mcpProbeNoSideHasIt'. nil } -> nil) } do: [ :each |
			self assert: (self noteOnTheSendIn: each key first compiledInto: target side: each key second) equals: each value ] ] ensure: [
			self removeSelector: #critiqueNoteProbe from: MCPToolMethodMutationTestTarget.
			self removeSelector: #critiqueNoteProbe from: MCPToolMethodMutationTestTarget classSide ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileStatesAnUnimplementedSendOnce [
	"Renraku flags a send that nothing implements, and flags it again when its receiver is self or a global, which cannot understand it either. The answer states each such send once, quoted with its receiver since the whole send fits in the quote."

	| critiques result |
	self removeSelector: #unimplementedOnceProbe from: MCPToolMethodMutationTestTarget.
	[
		result := self compileProbe: 'unimplementedOnceProbe ^ self mcpProbeQuantity // Object mcpProbeDozen'.
		critiques := (self dataFrom: result) at: #critiques.
		self assert: critiques size equals: 2.
		self assert: (critiques allSatisfy: [ :each | (each at: #ruleClass) = ReSentNotImplementedRule name asString ]).
		self
			assert: (critiques collect: [ :each | each at: #code ] as: Set)
			equals: #( 'self mcpProbeQuantity' 'Object mcpProbeDozen' ) asSet ] ensure: [
		self removeSelector: #unimplementedOnceProbe from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileStatesAnUnimplementedSendToSuperOnce [
	"Renraku flags a send to super that nothing implements for that, and again as neither the class nor its superclass understands it. The answer states it once."

	| critiques result |
	self removeSelector: #superOnceProbe from: MCPToolMethodMutationTestTarget.
	[
		result := self compileProbe: 'superOnceProbe ^ super mcpProbeZork: 3'.
		critiques := (self dataFrom: result) at: #critiques.
		self assert: critiques size equals: 1.
		self assert: (critiques first at: #ruleClass) equals: ReSentNotImplementedRule name asString.
		self assert: (critiques first at: #code) equals: 'super mcpProbeZork: 3' ] ensure: [
		self removeSelector: #superOnceProbe from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompileSucceedsWhenACritiqueRuleRaisesAWarning [

	| result selector |
	selector := MCPWarningTestRule probeSelector.
	self removeSelector: selector from: MCPToolMethodMutationTestTarget.
	[
		result := self callToolNamed: 'method_compile' withArguments: (self
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
	"The warning says where the method went and why, in one sentence: every compile that names no protocol for a new method carries it."

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
		self assert: warnings first equals: (String streamContents: [ :stream |
				 stream << 'No protocol was named, so it is filed under ''' << Protocol unclassified asString << '''.' ]) ] ensure: [
		self removeSelector: selector from: MCPToolMethodMutationTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompilesClassSideMethod [

	| data result |
	result := self callToolNamed: 'method_compile' withArguments: (self
			           compileArgumentsForClass: MCPToolMethodMutationTestTarget
			           classSide: true
			           methodSource: 'classAnswer ^ 7'
			           protocol: 'tests').
	data := self dataFrom: result.
	self assert: MCPToolMethodMutationTestTarget classAnswer equals: 7.
	self assert: (MCPToolMethodMutationTestTarget classSide >> #classAnswer) protocolName equals: #tests.
	self assertSuccessDataHasMethodShape: data
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompilesInstanceSideMethod [

	| data result |
	result := self callToolNamed: 'method_compile' withArguments: (self
			           compileArgumentsForClass: MCPToolMethodMutationTestTarget
			           classSide: false
			           methodSource: 'instanceAnswer ^ 42'
			           protocol: 'tests').
	data := self dataFrom: result.
	self assert: MCPToolMethodMutationTestTarget new instanceAnswer equals: 42.
	self assert: (MCPToolMethodMutationTestTarget >> #instanceAnswer) protocolName equals: #tests.
	self assertSuccessDataHasMethodShape: data
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testCompilingAClassSideInitializeSaysCompilingDoesNotRunIt [
	"Pharo runs a class-side initialize when it loads the class, so compiling one leaves the class as it was, and nothing else in the answer says so. An instance-side initialize runs for every new instance and needs no word."

	[
		self
			assert: (self summaryFrom: (self
						  compileSource: 'initialize
	^ self'
						  into: MCPToolMethodMutationTestTarget name
						  side: 'class'))
			equals:
			'Created MCPToolMethodMutationTestTarget class>>initialize. Compiling it does not run it: Pharo runs it when it loads the class. Evaluate MCPToolMethodMutationTestTarget initialize to run it now.'.
		self
			assert: (self summaryFrom: (self
						  compileSource: 'initialize
	^ self'
						  into: MCPToolMethodMutationTestTarget name
						  side: nil))
			equals: 'Created MCPToolMethodMutationTestTarget>>initialize.' ] ensure: [
			self removeSelector: #initialize from: MCPToolMethodMutationTestTarget.
			self removeSelector: #initialize from: MCPToolMethodMutationTestTarget classSide ]
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
MCPToolMethodMutationTest >> testFormatFalseKeepsEveryMethodOfACallAsWritten [
	"format applies to every method a call compiles, a method written as a Tonel file writes it included, whose body then ends with its last line rather than with the empty lines above its closing bracket."

	| result selectors |
	selectors := #( #asWrittenProbe #asWrittenTonelProbe ).
	selectors do: [ :each | self removeSelector: each from: MCPToolMethodMutationTestTarget ].
	[
		result := self callToolNamed: 'method_compile' withArguments: {
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#protocol -> 'tests').
				          (#format -> false).
				          (#source -> {
					           'asWrittenProbe ^1+1'.
					           (self lines: #( '{ #category : ''tests'' }' 'MCPToolMethodMutationTestTarget >> asWrittenTonelProbe ['
						               '    ^ 2+2' '' ']' )) }) } asDictionary.
		self assert: (self summaryFrom: result) equals: 'Compiled 2 of 2 methods.'.
		self assert: (MCPToolMethodMutationTestTarget >> #asWrittenProbe) sourceCode equals: 'asWrittenProbe ^1+1'.
		self
			assert: (MCPToolMethodMutationTestTarget >> #asWrittenTonelProbe) sourceCode
			equals: (self lines: #( 'asWrittenTonelProbe' '    ^ 2+2' )) ] ensure: [
		selectors do: [ :each | self removeSelector: each from: MCPToolMethodMutationTestTarget ] ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testFormatFalseKeepsTheSourceAsWritten [
	"With format false, the method is stored as the client wrote it but for its line endings, CR in the image, and the empty lines it ended with, so method_get answers it as sent."

	| lines |
	lines := #( 'asWrittenProbe' '    "Indented with spaces."' '    ^ (1+2)' ).
	self removeSelector: #asWrittenProbe from: MCPToolMethodMutationTestTarget.
	[
		self dataAnsweredThroughTheProtocolBy: 'method_compile' arguments: {
				('class' -> MCPToolMethodMutationTestTarget name asString).
				('protocol' -> 'tests').
				('format' -> false).
				('source' -> (String lf join: lines , #( '' '  ' '' ))) } asDictionary.
		self
			assert: ((self dataAnsweredThroughTheProtocolBy: 'method_get' arguments: {
						  ('class' -> MCPToolMethodMutationTestTarget name asString).
						  ('selector' -> 'asWrittenProbe') } asDictionary) at: 'source')
			equals: (String lf join: lines).
		self assert: (MCPToolMethodMutationTestTarget >> #asWrittenProbe) sourceCode equals: (self lines: lines) ] ensure: [
		self removeSelector: #asWrittenProbe from: MCPToolMethodMutationTestTarget ]
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
MCPToolMethodMutationTest >> testHeaderThatCannotBeDroppedIsRefused [
	"Dropping a header that names another class or side would compile somewhere the call did not say, and a selector without its argument names would leave the body's arguments undeclared. Each is refused, and nothing is compiled. A header naming the class side the call did not pass says to pass it."

	self
		assert: ((self
				  assertClassSideHeaderIsRefusedIn: 'MCPToolMethodMutationTestTarget class>>headerProbe:with:
	^ 1'
				  side: nil) at: #side)
		equals: 'class'.
	self
		assertHeaderIsRefusedIn: 'MCPToolMethodMutationTestTarget>>>=
	^ true'
		side: nil.
	self
		assertHeaderIsRefusedIn: 'MCPToolMethodMutationTestSender >> headerProbe
	^ 1'
		side: nil.
	self
		assert: ((self
				  assertClassSideHeaderIsRefusedIn: 'MCPToolMethodMutationTestTarget class >> #headerProbe
	^ 1'
				  side: 'instance') at: #side)
		equals: 'instance'
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
MCPToolMethodMutationTest >> testIsNotNilCritiqueLeavesTheConditionalsToPharosRuleWhereItExists [
	"Pharo's ReIsNotNilAndConditionalRule advises ifNotNil: or ifNil: in place of ifTrue:, ifFalse:, ifTrue:ifFalse: or ifFalse:ifTrue: sent to notNil, where isNotNil would keep the test. Where Pharo has that rule, MCPIsNotNilRule stays quiet on such a notNil; where it does not, MCPIsNotNilRule still critiques it. Either way the notNil gets exactly one of the two critiques. Any other notNil is still told to read isNotNil."

	| expected ruleNamesOf selector |
	expected := (self class environment includesKey: #ReIsNotNilAndConditionalRule)
		            ifTrue: [ #ReIsNotNilAndConditionalRule ]
		            ifFalse: [ #MCPIsNotNilRule ].
	selector := #notNilProbe:.
	ruleNamesOf := [ :body |
		               self ensureMethodSource: 'notNilProbe: anObject ' , body protocol: 'tests' on: MCPToolGetMethodTestTarget.
		               (MCPToolCompileMethod new critiquesOfMethod: MCPToolGetMethodTestTarget >> selector) collect: [ :each |
			               each rule class name ] ].
	self removeSelector: selector from: MCPToolGetMethodTestTarget.
	[
		#( 'anObject notNil ifTrue: [ ^ 1 ]. ^ 2' 'anObject notNil ifFalse: [ ^ 1 ]. ^ 2' 'anObject notNil ifTrue: [ ^ 1 ] ifFalse: [ ^ 2 ]'
		   'anObject notNil ifFalse: [ ^ 1 ] ifTrue: [ ^ 2 ]' ) do: [ :body |
				self
					assert:
					((ruleNamesOf value: body) select: [ :each | #( #MCPIsNotNilRule #ReIsNotNilAndConditionalRule ) includes: each ]) asArray
					equals: { expected } ].
		self assert: ((ruleNamesOf value: '^ anObject notNil and: [ anObject isString ]') includes: #MCPIsNotNilRule) ] ensure: [
		self removeSelector: selector from: MCPToolGetMethodTestTarget ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testMCPPackageMethodSourcesDoNotContainLineFeeds [

	| offenders |
	offenders := (self mcpPackageNames copyWith: 'BaselineOfMCP') flatCollect: [ :name |
			             (self packageOrganizer packageNamed: name) methods
				             select: [ :each | each sourceCode includes: Character lf ]
				             thenCollect: [ :each | each printString ] ].
	self assert: offenders isEmpty description: 'MCP method source must not contain Character lf: ' , offenders printString
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testMethodToolSchemasDeclareExpectedInputs [

	| classSideProperty createPropertyNames updatePropertyNames |
	createPropertyNames := MCPToolCompileMethod new inputSchema properties collect: [ :each | each name ].
	updatePropertyNames := MCPToolUpdateMethod new inputSchema properties collect: [ :each | each name ].
	classSideProperty := self inputPropertyNamed: 'side' inTool: MCPToolCompileMethod new.
	self assert: MCPToolCompileMethod new name equals: 'method_compile'.
	self assert: MCPToolUpdateMethod new name equals: 'method_update'.
	self assert: createPropertyNames asArray equals: #( 'class' 'side' 'source' 'protocol' 'force' 'format' ).
	self
		assert: updatePropertyNames asArray
		equals: #( 'class' 'side' 'force' 'format' 'selector' 'protocol' 'newSelector' 'arguments' 'argumentValueExpressions'
			   'permutation' 'scope' ).
	self assert: MCPToolCompileMethod new inputSchema required asSet equals: #( 'class' 'source' ) asSet.
	self assert: MCPToolUpdateMethod new inputSchema required asSet equals: #( 'class' 'selector' ) asSet.
	self assert: MCPToolUpdateMethod new atLeastOneInputProperties asSet equals: #( 'protocol' 'newSelector' ) asSet.
	self assert: (classSideProperty extraProperties at: #default) equals: 'instance'
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testMutationDescriptionsExplainForceWarningBehavior [

	| methodForceDescription |
	methodForceDescription := (self inputPropertyNamed: 'force' inTool: MCPToolUpdateMethod new) description.
	self assert: (methodForceDescription includesSubstring: 'refactoring warnings').
	self assert: (methodForceDescription includesSubstring: 'stopping')
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testProtocolChangeSaysFromAndTo [
	"A protocol change names the protocol the method left and the one it went to, in the words method_compile uses for a replace that moves a method; asking for the protocol it is in says so, and a method with none was in no protocol."

	| oldProtocol reference |
	reference := 'MCPToolMethodMutationTestTarget>>' , self instanceProtocolSelector.
	oldProtocol := (MCPToolMethodMutationTestTarget >> self instanceProtocolSelector) protocolName asString.
	self deny: oldProtocol equals: 'accessing'.
	self
		assert: (self summaryFrom: (self callToolNamed: 'method_update' withArguments: self instanceChangeArguments))
		equals: ('Moved {1} from {2} to accessing.' format: {
					 reference.
					 oldProtocol }).
	self
		assert: (self summaryFrom: (self callToolNamed: 'method_update' withArguments: self instanceChangeArguments))
		equals: ('{1} is already in accessing.' format: { reference }).
	self
		assert: (MCPToolUpdateMethod new protocolChangeSummaryFor: 'ZooKeeper>>feed' from: '' to: 'feeding')
		equals: 'Moved ZooKeeper>>feed from no protocol to feeding.'
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testReformatsMethod [

	| reformattedSource result source |
	source := 'uglyAnswer   ^   1+2'.
	result := self callToolNamed: 'method_compile' withArguments: (self
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
		result := self callToolNamed: 'method_compile' withArguments: (self
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
	result := self callToolNamed: 'method_update' withArguments: {
			          (#class -> MCPToolMethodMutationTestTarget name).
			          (#selector -> self inferenceSelector asString).
			          (#newSelector -> narrowed asString).
			          (#arguments -> #( 'first' )).
			          self fixturePackageScope } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (MCPToolMethodMutationTestTarget includesSelector: narrowed).
	self assert: (MCPToolMethodMutationTestTarget new perform: narrowed with: 'a') equals: 'a'
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRemoveArgumentsFailsWhenRemovedArgumentIsReferenced [

	| error newSelector oldSelector result |
	oldSelector := ('referencedRemove:' , 'unused:') asSymbol.
	newSelector := #referencedRemove:.
	[
		self
			ensureMethodSource: 'referencedRemove: first unused: ignored ^ ignored'
			protocol: 'tests'
			on: MCPToolMethodMutationTestTarget.
		result := self callToolNamed: 'method_update' withArguments: {
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#side -> 'instance').
				          (#selector -> oldSelector asString).
				          (#newSelector -> newSelector asString).
				          self fixturePackageScope } asDictionary.
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

	| newSelector oldSelector result senderSource |
	oldSelector := ('keep:' , 'unused:') asSymbol.
	newSelector := #keep:.
	[
		self ensureMethodSource: 'keep: first unused: ignored ^ first' protocol: 'tests' on: MCPToolMethodMutationTestTarget.
		self
			ensureMethodSource: 'callRemoveArgumentTarget ^ MCPToolMethodMutationTestTarget new keep: ''value'' unused: ''ignored'''
			protocol: 'tests'
			on: MCPToolMethodMutationTestSender.
		result := self callToolNamed: 'method_update' withArguments: {
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#side -> 'instance').
				          (#selector -> oldSelector asString).
				          (#newSelector -> newSelector asString).
				          self fixturePackageScope } asDictionary.
		self dataFrom: result.
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
			result := self callToolNamed: 'method_update' withArguments: {
					          (#class -> (fixtures at: #targetAClassName)).
					          (#side -> 'instance').
					          (#selector -> 'scopeSharedTarget').
					          (#newSelector -> 'scopedSharedTarget').
					          (#scope -> { (#classes -> {
						            (fixtures at: #targetAClassName).
						            (fixtures at: #senderAClassName) }) } asDictionary) } asDictionary.
			data := self dataFrom: result.
			targetAClass := self class environment at: (fixtures at: #targetAClassName) asSymbol.
			targetBClass := self class environment at: (fixtures at: #targetBClassName) asSymbol.
			senderAClass := self class environment at: (fixtures at: #senderAClassName) asSymbol.
			senderBClass := self class environment at: (fixtures at: #senderBClassName) asSymbol.
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
			result := self callToolNamed: 'method_update' withArguments: {
					          (#class -> (fixtures at: #targetAClassName)).
					          (#side -> 'instance').
					          (#selector -> 'scopeSharedTarget').
					          (#newSelector -> 'scopedSharedTarget').
					          (#scope -> { (#packages -> { (fixtures at: #packageAName) }) } asDictionary) } asDictionary.
			data := self dataFrom: result.
			targetAClass := self class environment at: (fixtures at: #targetAClassName) asSymbol.
			targetBClass := self class environment at: (fixtures at: #targetBClassName) asSymbol.
			senderAClass := self class environment at: (fixtures at: #senderAClassName) asSymbol.
			senderBClass := self class environment at: (fixtures at: #senderBClassName) asSymbol.
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
		result := self callToolNamed: 'method_update' withArguments: {
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#side -> 'instance').
				          (#selector -> oldSelector asString).
				          (#newSelector -> newSelector asString).
				          (#permutation -> #( 2 1 )).
				          self fixturePackageScope } asDictionary.
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
				result := self callToolNamed: 'method_update' withArguments: (self instanceRenameArguments copy
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

	| error result |
	self removeSelector: self instanceSelector from: MCPToolMethodMutationTestTarget.
	result := self callToolNamed: 'method_update' withArguments: self instanceRenameArguments.
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
	arguments at: #scope put: 'classes'.
	self
		assertResult: (self callDiscoveredToolNamed: 'method_update' withArguments: arguments)
		refusesArgumentsSaying: 'scope must be object, not string.'
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenameReturnsStructuredErrorWhenScopedPackageIsMissing [

	| error result |
	result := self callToolNamed: 'method_update' withArguments: (self instanceRenameArguments copy
			           at: #scope put: { (#packages -> #( 'DefinitelyMissingPackage' )) } asDictionary;
			           yourself).
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
MCPToolMethodMutationTest >> testRenameScopeOffersOnlyWhatTheRefactoringReads [
	"The refactoring reads packages, classes and hierarchies, so a scope naming subclasses is refused rather than widened to the whole image."

	| arguments |
	arguments := self instanceRenameArguments copy.
	arguments at: #scope put: { (#subclassesOf -> { MCPToolMethodMutationTestTarget name }) } asDictionary.
	self
		assertResult: (self callDiscoveredToolNamed: 'method_update' withArguments: arguments)
		refusesArgumentsSaying: 'scope.subclassesOf is not accepted here; expected one of classes, hierarchyOf, packages.'
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenameUpdatesSendersAndPermutesArguments [

	| senderSource |
	self callToolNamed: 'method_update' withArguments: self instanceRenameArguments.
	self assert: MCPToolMethodMutationTestSender new callInstanceTarget equals: 'first-second'.
	senderSource := (MCPToolMethodMutationTestSender >> #callInstanceTarget) sourceCode.
	self assert: (senderSource includesSubstring: 'with: ''second'' combine: ''first''')
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenameWithFormatFalseKeepsTheMethodAsWritten [
	"Renamed with format false, the method keeps its text but for its selector line. Its sender has only the send changed, as the refactoring writes it whatever format says."

	| selectors |
	selectors := #( #asWrittenTarget: #asWrittenAim: #asWrittenSender ).
	selectors do: [ :each | self removeSelector: each from: MCPToolMethodMutationTestTarget ].
	[
		self callToolNamed: 'method_compile' withArguments: {
				(#class -> MCPToolMethodMutationTestTarget name).
				(#protocol -> 'tests').
				(#format -> false).
				(#source -> {
					 (self lines: #( 'asWrittenTarget: a' '    ^ a+1' )).
					 (self lines: #( 'asWrittenSender' '    ^ (self asWrittenTarget: 1)+2' )) }) } asDictionary.
		self callToolNamed: 'method_update' withArguments: {
				(#class -> MCPToolMethodMutationTestTarget name).
				(#selector -> 'asWrittenTarget:').
				(#newSelector -> 'asWrittenAim:').
				(#format -> false).
				(self searchScope: { (#classes -> { MCPToolMethodMutationTestTarget name }) }) } asDictionary.
		self
			assert: (MCPToolMethodMutationTestTarget >> #asWrittenAim:) sourceCode
			equals: (self lines: #( 'asWrittenAim: a' '    ^ a+1' )).
		self
			assert: (MCPToolMethodMutationTestTarget >> #asWrittenSender) sourceCode
			equals: (self lines: #( 'asWrittenSender' '    ^ (self asWrittenAim: 1)+2' )) ] ensure: [
		selectors do: [ :each | self removeSelector: each from: MCPToolMethodMutationTestTarget ] ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenameWithoutPermutationKeepsArgumentsInPlace [

	| renamed result |
	renamed := self inferenceOutcomeSelectors first.
	result := self callToolNamed: 'method_update' withArguments: {
			          (#class -> MCPToolMethodMutationTestTarget name).
			          (#selector -> self inferenceSelector asString).
			          (#newSelector -> renamed asString).
			          self fixturePackageScope } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (MCPToolMethodMutationTestTarget includesSelector: renamed).
	self assert: (MCPToolMethodMutationTestTarget new perform: renamed with: 'a' with: 'b') equals: 'a-b'
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenamesClassSideMethodOfAClassWrittenWithItsSide [
	"Foo class with a bare selector names the class-side method, so the summary names the side once."

	| result |
	result := self callToolNamed: 'method_update' withArguments: {
			          (#class -> (MCPToolMethodMutationTestTarget name , ' class')).
			          (#selector -> self classSelector asString).
			          (#newSelector -> self renamedClassSelector asString).
			          self fixturePackageScope } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
	self deny: (MCPToolMethodMutationTestTarget classSide includesSelector: self classSelector).
	self assert: (MCPToolMethodMutationTestTarget classSide includesSelector: self renamedClassSelector).
	self assert: ((self summaryFrom: result) includesSubstring: 'MCPToolMethodMutationTestTarget class>>').
	self deny: ((self summaryFrom: result) includesSubstring: 'class class')
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenamesClassSideMethodWithDefaultPermutation [

	| data result |
	result := self callToolNamed: 'method_update' withArguments: (self classRenameArguments
			           add: self fixturePackageScope;
			           yourself).
	data := self dataFrom: result.
	self deny: (MCPToolMethodMutationTestTarget classSide includesSelector: self classSelector).
	self assert: (MCPToolMethodMutationTestTarget classSide includesSelector: self renamedClassSelector).
	self assert: MCPToolMethodMutationTestSender new callClassTarget equals: 'Class-value'.
	self assertSuccessDataHasMethodShape: data
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testRenamesInstanceMethodAndReturnsStructuredData [

	| data result |
	result := self callToolNamed: 'method_update' withArguments: (self instanceRenameArguments
			           add: self fixturePackageScope;
			           yourself).
	data := self dataFrom: result.
	self deny: (MCPToolMethodMutationTestTarget includesSelector: self instanceSelector).
	self assert: (MCPToolMethodMutationTestTarget includesSelector: self renamedInstanceSelector).
	self assertSuccessDataHasMethodShape: data
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testReplacingAnUnclassifiedMethodDoesNotWarnAgain [
	"A replace that names no protocol keeps the method where it is. The compile that filed it as unclassified said so, and the replace does not say it again."

	| result selector |
	selector := #unclassifiedProbe.
	self removeSelector: selector from: MCPToolMethodMutationTestTarget.
	[
		self callToolNamed: 'method_compile' withArguments: {
				(#class -> MCPToolMethodMutationTestTarget name).
				(#source -> 'unclassifiedProbe ^ 3') } asDictionary.
		result := self callToolNamed: 'method_compile' withArguments: {
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#source -> 'unclassifiedProbe ^ 4') } asDictionary.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (MCPToolMethodMutationTestTarget >> selector) protocolName asString equals: Protocol unclassified asString.
		self assert: (self warningsFrom: result) isEmpty.
		self assert: (self textFrom: result) equals: 'Replaced MCPToolMethodMutationTestTarget>>unclassifiedProbe.' ] ensure: [
		self removeSelector: selector from: MCPToolMethodMutationTestTarget ]
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
MCPToolMethodMutationTest >> testTemporariesAfterAStatementSayWhereTheyGo [
	"A method or block declares its temporaries before its first statement. To the compiler, a declaration after a statement is an expression that cannot begin with a bar, and its answer says nothing of where the declaration goes, so the answer says it: above the first statement of the method or block it is in, or into the declaration that one already has. A bar met anywhere else, as in a brace array, is answered as before."

	| error result |
	[
		{
			('headerProbe: aString
	aString ifNil: [ ^ '''' ].
	| stream |
	stream := WriteStream on: String new.
	^ stream contents' -> '| stream | comes after a statement: move it above the method''s first statement.').
			('headerProbe: aString
	| size |
	size := aString size.
	| first last |
	first := aString first.
	^ size' -> '| first last | comes after a statement: add first and last to the method''s declaration, above its first statement.').
			('headerProbe: aString
	^ aString collect: [ :each |
		each yourself.
		| upper |
		upper := each asUppercase ]' -> '| upper | comes after a statement: move it above the block''s first statement.').
			('headerProbe: aString
	| size |
	size := aString size.
	^ aString collect: [ :each |
		| lower |
		lower := each asLowercase.
		| upper |
		upper := each asUppercase ]'
			 -> '| upper | comes after a statement: add upper to the block''s declaration, above its first statement.') } do: [ :each |
				result := self compileSource: each key into: MCPToolMethodMutationTestTarget name side: nil.
				error := self errorFrom: result.
				self assert: (result at: #isError).
				self assert: (error at: #errorCode) equals: 'CompileSyntaxError'.
				self
					assert: ((error at: #message) endsWith: '. Temporaries are declared before the first statement, but ' , each value)
					description: [ error at: #message ].
				self deny: (MCPToolMethodMutationTestTarget includesSelector: #headerProbe:) ].

		{ 'headerProbe
	| first |
	first := | last |'. 'headerProbe
	^ { 1. | last | }' } do: [ :each |
				result := self compileSource: each into: MCPToolMethodMutationTestTarget name side: nil.
				error := self errorFrom: result.
				self assert: (error at: #errorCode) equals: 'CompileSyntaxError'.
				self deny: ((error at: #message) includesSubstring: 'Temporaries') description: [ error at: #message ] ] ] ensure: [
		self removeHeaderProbes ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testTheProtocolNamedWinsOverATonelCategory [
	"The protocol the call names is what the caller chose; a category line copied with the method gives the protocol only when the call names none."

	| result |
	[
		result := self callToolNamed: 'method_compile' withArguments: {
				          (#class -> MCPToolMethodMutationTestTarget name).
				          (#protocol -> 'private').
				          (#source -> '{ #category : ''accessing'' }
MCPToolMethodMutationTestTarget >> tonelProbe [
	^ 1
]') } asDictionary.
		self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
		self assert: (MCPToolMethodMutationTestTarget >> #tonelProbe) protocolName asString equals: 'private' ] ensure: [
		self removeTonelProbes ]
]

{ #category : 'tests' }
MCPToolMethodMutationTest >> testUpdateChangesProtocolAndSelectorInOneCall [

	| data renamed result |
	renamed := self renamedInstanceProtocolSelector.
	result := self callToolNamed: 'method_update' withArguments: {
			          (#class -> MCPToolMethodMutationTestTarget name).
			          (#side -> 'instance').
			          (#selector -> self instanceProtocolSelector asString).
			          (#protocol -> 'accessing').
			          (#newSelector -> renamed asString).
			          self fixturePackageScope } asDictionary.
	data := self dataFrom: result.
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
		self
			ensureMethodSource: 'scopeSharedTarget ^ ''A'''
			protocol: 'tests'
			on: (self class environment at: targetAClassName asSymbol).
		self
			ensureMethodSource: 'scopeSharedTarget ^ ''B'''
			protocol: 'tests'
			on: (self class environment at: targetBClassName asSymbol).
		self
			ensureMethodSource: 'callScopedTarget ^ MCPToolMethodMutationScopeTargetA new scopeSharedTarget'
			protocol: 'tests'
			on: (self class environment at: senderAClassName asSymbol).
		self
			ensureMethodSource: 'callScopedTarget ^ MCPToolMethodMutationScopeTargetB new scopeSharedTarget'
			protocol: 'tests'
			on: (self class environment at: senderBClassName asSymbol).
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
