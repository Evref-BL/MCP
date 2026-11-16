"
Tests the class_get tool.
"
Class {
	#name : 'MCPToolGetClassTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolGetClassTest >> baseClassName [

	^ self fixturePrefix , 'Base'
]

{ #category : 'private' }
MCPToolGetClassTest >> childAClassName [

	^ self fixturePrefix , 'AChild'
]

{ #category : 'private' }
MCPToolGetClassTest >> childZClassName [

	^ self fixturePrefix , 'ZChild'
]

{ #category : 'private' }
MCPToolGetClassTest >> ensureClassComment: aComment onClassNamed: aClassName [

	self withoutEpiceaDuring: [ (self classNamed: aClassName) comment: aComment stamp: '' ]
]

{ #category : 'private' }
MCPToolGetClassTest >> ensureClassMethodSource: aMethodSource onClassNamed: aClassName [

	self withoutEpiceaDuring: [ (self classNamed: aClassName) classSide compile: aMethodSource classified: 'testing' ]
]

{ #category : 'private' }
MCPToolGetClassTest >> ensureMethodSource: aMethodSource onClassNamed: aClassName [

	self withoutEpiceaDuring: [ (self classNamed: aClassName) compile: aMethodSource classified: 'testing' ]
]

{ #category : 'private' }
MCPToolGetClassTest >> fixtureClassNames [

	^ {
		  self baseClassName.
		  self childAClassName.
		  self childZClassName.
		  self grandchildClassName } asArray
]

{ #category : 'private' }
MCPToolGetClassTest >> fixturePrefix [

	^ self class name asString
]

{ #category : 'private' }
MCPToolGetClassTest >> grandchildClassName [

	^ self fixturePrefix , 'Grandchild'
]

{ #category : 'private' }
MCPToolGetClassTest >> missingClassName [

	^ self fixturePrefix , 'Missing'
]

{ #category : 'private' }
MCPToolGetClassTest >> removeFixtureClasses [

	self fixtureClassNames reverseDo: [ :each | self removeClassNamed: each ]
]

{ #category : 'private' }
MCPToolGetClassTest >> restoreFixtureClasses [

	self removeFixtureClasses.
	self
		createClassNamed: self baseClassName
		superclassName: 'Object'
		slots: #( betaSlot alphaSlot )
		classSlots: #( classBeta classAlpha ).
	self withoutEpiceaDuring: [
			(self classNamed: self baseClassName)
				addClassVarNamed: 'BetaShared';
				addClassVarNamed: 'AlphaShared' ].
	self
		createClassNamed: self childZClassName
		superclassName: self baseClassName
		slots: #(  )
		classSlots: #(  ).
	self
		createClassNamed: self childAClassName
		superclassName: self baseClassName
		slots: #(  )
		classSlots: #(  ).
	self
		createClassNamed: self grandchildClassName
		superclassName: self childZClassName
		slots: #(  )
		classSlots: #(  ).
	self ensureMethodSource: 'instanceMarker ^ 1' onClassNamed: self baseClassName.
	self ensureClassMethodSource: 'classMarker ^ 2' onClassNamed: self baseClassName.
	self ensureClassComment: 'Base fixture class comment.' onClassNamed: self baseClassName.
	self ensureClassComment: 'Child A fixture class comment.' onClassNamed: self childAClassName.
	self ensureClassComment: 'Child Z fixture class comment.' onClassNamed: self childZClassName.
	self ensureClassComment: 'Grandchild fixture class comment.' onClassNamed: self grandchildClassName
]

{ #category : 'running' }
MCPToolGetClassTest >> setUp [

	super setUp.
	self restoreFixtureClasses
]

{ #category : 'running' }
MCPToolGetClassTest >> tearDown [

	self removeFixtureClasses.
	super tearDown
]

{ #category : 'tests' }
MCPToolGetClassTest >> testClampsSubclassDepthAboveMaximum [

	| data result subclasses |
	result := self callToolWith: {
			          (#name -> self baseClassName).
			          (#subclassDepth -> 1000) } asDictionary.
	data := self dataFrom: result.
	subclasses := data at: #subclasses.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self resultIndicatesError: result).
	self assert: (subclasses collect: [ :each | each at: #class ]) equals: {
			self childAClassName.
			self childZClassName.
			self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolGetClassTest >> testClassFieldsReadInOrderAndAreNotRepeated [
	"The summary already names the class, so a class: field would say it twice, and a reader wants what the class is and where it lives before how big it is."

	| labels text |
	text := ((self callToolNamed: 'class_get' withArguments: { (#name -> self baseClassName) } asDictionary) at: #content) first at:
		        #text.
	labels := (text lines allButFirst select: [ :each | each includesSubstring: ': ' ] thenCollect: [ :each | each copyUpTo: $: ])
		          asArray.
	self assert: text lines first equals: (String streamContents: [ :stream | stream << 'Got class ' << self baseClassName << '.' ]).
	self deny: (labels includes: 'class').
	self assert: (labels copyFrom: 1 to: 3) equals: #( 'superclass' 'package' 'tag' ).
	self assert: (labels indexOf: 'methods') < (labels indexOf: 'classMethods')
]

{ #category : 'tests' }
MCPToolGetClassTest >> testCountsOnlyTheMethodsTheClassDefines [
	"A class using a trait gets the trait's methods, and its class side also holds what Pharo installs from TraitedClass; neither is the class's own."

	| data |
	self assert: MCPToolMethodSearchTraitUser selectors isNotEmpty.
	self assert: MCPToolMethodSearchTraitUser classSide selectors isNotEmpty.
	data := self dataFrom: (self callToolWith: { (#name -> MCPToolMethodSearchTraitUser name) } asDictionary).
	self assert: (data at: #methods) equals: 0.
	self assert: (data at: #classMethods) equals: 0.
	data := self dataFrom: (self callToolWith: { (#name -> TMCPToolMethodSearchFixture name) } asDictionary).
	self assert: (data at: #methods) equals: 1.
	self assert: (data at: #classMethods) equals: 1
]

{ #category : 'tests' }
MCPToolGetClassTest >> testDescribesATraitAndNamesTheClassesUsingIt [

	| data result text |
	result := self callToolWith: { (#name -> TMCPToolMethodSearchFixture name) } asDictionary.
	data := self dataFrom: result.
	text := (result at: #content) first at: #text.
	self
		assert: text lines first
		equals: (String streamContents: [ :stream | stream << 'Got trait ' << TMCPToolMethodSearchFixture name << '.' ]).
	self assert: (data at: #isTrait).
	self deny: (data includesKey: #superclass).
	self assert: (data at: #users) equals: {
			MCPToolMethodSearchTraitExcluder name asString.
			MCPToolMethodSearchTraitOtherUser name asString.
			MCPToolMethodSearchTraitOverrider name asString.
			MCPToolMethodSearchTraitUser name asString }
]

{ #category : 'tests' }
MCPToolGetClassTest >> testGetsAClassWrittenWithItsSideAsTheClass [
	"class_get reports both sides of a class, so Foo class, as MCP's own answers print a class side, reads as Foo and gets what Foo gets."

	| plain sided |
	plain := self callToolWith: { (#name -> self baseClassName) } asDictionary.
	sided := self callToolWith: { (#name -> ('{1} class' format: { self baseClassName })) } asDictionary.
	self deny: (self resultIndicatesError: sided) description: [ self summaryFrom: sided ].
	self assert: (self summaryFrom: sided) equals: ('Got class {1}.' format: { self baseClassName }).
	self assert: (self dataFrom: sided) equals: (self dataFrom: plain)
]

{ #category : 'tests' }
MCPToolGetClassTest >> testGetsClassMetadata [

	| data result |
	result := self callToolWith: { (#name -> self baseClassName) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self resultIndicatesError: result).
	self assert: (data at: #class) equals: self baseClassName.
	self assert: (data at: #superclass) equals: 'Object'.
	self assert: (data at: #package) equals: self generatedPackageName.
	self assert: (data at: #tag) equals: self generatedTagName.
	self deny: (data includesKey: #comment).
	self assert: (data at: #instanceSlots) equals: #( 'betaSlot' 'alphaSlot' ).
	self assert: (data at: #classSlots) equals: #( 'classBeta' 'classAlpha' ).
	self deny: (data includesKey: #traits).
	self deny: (data includesKey: #classTraits).
	self deny: (data includesKey: #traitComposition).
	self deny: (data includesKey: #classTraitComposition).
	self deny: (data includesKey: #sharedPools).
	self assert: (data at: #sharedVariables) equals: #( 'AlphaShared' 'BetaShared' ).
	self deny: (data includesKey: #layout).
	self assert: (data at: #methods) equals: 1.
	self assert: (data at: #classMethods) equals: 1.
	self deny: (data includesKey: #superclasses).
	self deny: (data includesKey: #subclasses)
]

{ #category : 'tests' }
MCPToolGetClassTest >> testIncludeSourceAnswersAMethodLongerThanAPageAlone [
	"A page holds at least one method, so a method longer than a page still comes, alone on its page, and the next page starts after it."

	| class first limit second |
	limit := MCPToolGetClass new pageCharacterLimit.
	class := self classNamed: self baseClassName.
	self
		ensureClassMethodSource: ('aLongMarker ^ ''{1}''' format: { (String new: limit withAll: $a) })
		onClassNamed: self baseClassName.
	first := self callToolWith: {
			         (#name -> self baseClassName).
			         (#includeSource -> true) } asDictionary.
	second := self callToolWith: {
			          (#name -> self baseClassName).
			          (#includeSource -> true).
			          (#offset -> 1) } asDictionary.
	self
		assert: (self summaryFrom: first)
		equals: ('Got class {1} as its Tonel file, with method 1 of 3. Next page: offset 1.' format: { self baseClassName }).
	self assert: ((self dataFrom: first) at: #source) size > limit.
	self assert: (((self dataFrom: first) at: #source) includesSubstring: 'aLongMarker').
	self
		assert: (self summaryFrom: second)
		equals: ('Got methods 2 to 3 of 3 in the Tonel file of class {1}.' format: { self baseClassName }).
	self
		assert: ((self dataFrom: first) at: #source) , ((self dataFrom: second) at: #source)
		equals: (TonelWriter sourceCodeOf: class)
]

{ #category : 'tests' }
MCPToolGetClassTest >> testIncludeSourceAnswersATraitAsItsTonelFile [
	"No file holds the classes that use a trait, so they come beside its file, as they do without it."

	| data result source |
	result := self callToolWith: {
			          (#name -> TMCPToolMethodSearchFixture name).
			          (#includeSource -> true) } asDictionary.
	data := self dataFrom: result.
	source := data at: #source.
	self assert: (self summaryFrom: result) equals: ('Got trait {1} as its Tonel file.' format: { TMCPToolMethodSearchFixture name }).
	self assert: source equals: (TonelWriter sourceCodeOf: TMCPToolMethodSearchFixture).
	self assert: (source includesSubstring: 'from the class side of the trait').
	self
		assert: (data at: #users)
		equals: ((self dataFrom: (self callToolWith: { (#name -> TMCPToolMethodSearchFixture name) } asDictionary)) at: #users).
	self assert: ((data at: #users) includes: MCPToolMethodSearchTraitOverrider name asString)
]

{ #category : 'tests' }
MCPToolGetClassTest >> testIncludeSourceAnswersTheClassAsItsTonelFile [
	"The file is what Pharo's Tonel writer writes for the class: its definition, its comment, and its methods on both sides with their protocols. It stands for the description, and holds the comment already."

	| data expected result |
	expected := TonelWriter sourceCodeOf: (self classNamed: self baseClassName).
	self assert: (expected includesSubstring: 'Base fixture class comment.').
	self assert: (expected includesSubstring: 'classMarker').
	self assert: (expected includesSubstring: 'instanceMarker').
	result := self callToolWith: {
			          (#name -> self baseClassName).
			          (#includeSource -> true).
			          (#includeComment -> true) } asDictionary.
	data := self dataFrom: result.
	self assert: (self summaryFrom: result) equals: ('Got class {1} as its Tonel file.' format: { self baseClassName }).
	self assert: (data at: #source) equals: expected.
	self assert: ((self textFrom: result) includesSubstring: expected).
	self deny: (data includesKey: #superclass).
	self deny: (data includesKey: #methods).
	self deny: (data includesKey: #comment).
	self deny: (data includesKey: #nextOffset)
]

{ #category : 'tests' }
MCPToolGetClassTest >> testIncludeSourceCountsWhatSeveralPackagesAdd [
	"Methods several packages add are counted together, and each package is named once. The class is named, not referred to, since method search tests count the methods that refer to it."

	| class data result |
	class := self classNamed: 'MCPToolMethodSearchReferenceTarget'.
	self ensureMethodSource: 'extensionMarker ^ 3' protocol: self generatedExtensionProtocol on: class.
	[
		result := self callToolWith: {
				          (#name -> class name).
				          (#includeSource -> true) } asDictionary.
		data := self dataFrom: result.
		self assert: (data at: #extensionMethods) equals: 3.
		self assert: (data at: #extensionPackages) equals: {
				self generatedExtensionPackageName.
				'MCP-Tests-Resources-Extensions' }.
		self
			assert: (self summaryFrom: result)
			equals:
				('Got class {1} as its Tonel file. The file leaves out 3 methods that 2 other packages add to class {1}, each in its own package''s file. method_search with protocol "*" and scope.classes lists them.'
					 format: { class name }) ] ensure: [ self removeSelector: #extensionMarker from: class ]
]

{ #category : 'tests' }
MCPToolGetClassTest >> testIncludeSourceEndsAPageBeforeItsCharacterLimit [
	"A page holds the methods that fit in its characters, fewer than its count when they are long, and the next page starts at the first one left out. The pages put end to end are still the whole file."

	| class limit offsets pages |
	limit := MCPToolGetClass new pageCharacterLimit.
	class := self classNamed: self baseClassName.
	1 to: 3 do: [ :index |
			self
				ensureMethodSource: ('longMarker{1} ^ ''{2}''' format: {
							 index.
							 (String new: limit * 3 // 5 withAll: $a) })
				onClassNamed: self baseClassName ].
	offsets := #( 0 3 4 ).
	pages := offsets collect: [ :each |
			         self callToolWith: {
					         (#name -> self baseClassName).
					         (#includeSource -> true).
					         (#offset -> each) } asDictionary ].
	self assert: (pages collect: [ :each | self summaryFrom: each ]) equals: {
			('Got class {1} as its Tonel file, with methods 1 to 3 of 5. Next page: offset 3.' format: { self baseClassName }).
			('Got method 4 of 5 in the Tonel file of class {1}. Next page: offset 4.' format: { self baseClassName }).
			('Got method 5 of 5 in the Tonel file of class {1}.' format: { self baseClassName }) }.
	pages do: [ :each | self assert: ((self dataFrom: each) at: #source) size <= limit ].
	self
		assert: (String streamContents: [ :stream | pages do: [ :each | stream nextPutAll: ((self dataFrom: each) at: #source) ] ])
		equals: (TonelWriter sourceCodeOf: class)
]

{ #category : 'tests' }
MCPToolGetClassTest >> testIncludeSourceIsAnOptionTheDescriptionNames [
	"Off unless asked for, so an answer without it stays the class's description; the tool's description names it, since a whole class is otherwise read a method at a time. Its own description gives a page's bounds, the method count tool_get gives as the page size and the characters."

	| schema tool |
	tool := MCPToolGetClass new.
	schema := tool inputSchema asJRPCJSON at: #properties.
	self assert: ((schema at: 'includeSource') at: #type) equals: 'boolean'.
	self assert: ((schema at: 'includeSource') at: #default) equals: false.
	self assert: ((schema at: 'offset') at: #default) equals: 0.
	self assert: (tool description includesSubstring: 'includeSource').
	self assert: tool defaultPageLimit > 0.
	self assert: (tool contract at: #pageSize) equals: tool defaultPageLimit.
	self assert: (((schema at: 'includeSource') at: #description) includesSubstring:
			 ('a page holds up to {1} methods and {2} characters' format: {
					  tool defaultPageLimit.
					  tool pageCharacterLimit asStringWithCommas }))
]

{ #category : 'tests' }
MCPToolGetClassTest >> testIncludeSourceKeepsTheHierarchyItWasAskedFor [
	"The superclasses and subclasses come as they do without the file, as short records."

	| data result |
	result := self callToolWith: {
			          (#name -> self grandchildClassName).
			          (#includeSource -> true).
			          (#upToSuperclass -> self baseClassName) } asDictionary.
	data := self dataFrom: result.
	self
		assert: (self summaryFrom: result)
		equals: ('Got class {1} as its Tonel file. Included 1 superclass and 0 subclasses.' format: { self grandchildClassName }).
	self assert: ((data at: #superclasses) collect: [ :each | each at: #class ]) equals: { self childZClassName }.
	self assert: (data at: #source) equals: (TonelWriter sourceCodeOf: (self classNamed: self grandchildClassName))
]

{ #category : 'tests' }
MCPToolGetClassTest >> testIncludeSourceLeavesOutWhatATraitGives [
	"A method a class gets from a trait is in the trait's file. The class's file holds the methods the class defines itself, as an export of its package writes it: here the one that overrides the trait's on the instance side, and not the trait's own on the class side. A class that overrides nothing holds none of the trait's, on either side."

	| class result source user writer |
	class := MCPToolMethodSearchTraitOverrider.
	writer := TonelWriter new.
	writer snapshot: (MCPackage named: class package name) snapshot.
	result := self callToolWith: {
			          (#name -> class name).
			          (#includeSource -> true) } asDictionary.
	source := (self dataFrom: result) at: #source.
	self assert: (self summaryFrom: result) equals: ('Got class {1} as its Tonel file.' format: { class name }).
	self assert: source equals: (String streamContents: [ :stream | writer writeClass: class asClassDefinition on: stream ]).
	self assert: (source includesSubstring: '''overridden''').
	self deny: (source includesSubstring: 'from the class side of the trait').
	user := MCPToolMethodSearchTraitUser.
	source := (self dataFrom: (self callToolWith: {
				            (#name -> user name).
				            (#includeSource -> true) } asDictionary)) at: #source.
	self assert: source equals: (String streamContents: [ :stream | writer writeClass: user asClassDefinition on: stream ]).
	self deny: (source includesSubstring: 'from the trait').
	self deny: (source includesSubstring: 'mcpTraitFixtureValue')
]

{ #category : 'tests' }
MCPToolGetClassTest >> testIncludeSourceLeavesOutWhatOtherPackagesAdd [
	"A method another package adds to the class is in that package's file, not in the class's. The answer says how many there are and which packages hold them, and the method_search it names lists them."

	| class data expected listed result |
	class := self classNamed: self baseClassName.
	expected := TonelWriter sourceCodeOf: class.
	self ensureMethodSource: 'extensionMarker ^ 3' protocol: self generatedExtensionProtocol on: class.
	[
		result := self callToolWith: {
				          (#name -> self baseClassName).
				          (#includeSource -> true) } asDictionary.
		data := self dataFrom: result.
		self assert: (data at: #source) equals: expected.
		self assert: (data at: #extensionMethods) equals: 1.
		self assert: (data at: #extensionPackages) equals: { self generatedExtensionPackageName }.
		self
			assert: (self summaryFrom: result)
			equals:
				('Got class {1} as its Tonel file. The file leaves out 1 method that another package adds to class {1}, in that package''s own file. method_search with protocol "*" and scope.classes lists it.'
					 format: { self baseClassName }).
		self assert:
			((self textFrom: result) includesSubstring: ('extensionPackages: [{1}]' format: { self generatedExtensionPackageName })).
		listed := (self dataFrom: (self callToolNamed: 'method_search' withArguments: {
					            (#protocol -> '*').
					            (#scope -> { (#classes -> { self baseClassName }) } asDictionary) } asDictionary)) at: #methods.
		self assert: (listed collect: [ :each | each at: #selector ] as: Array) equals: #( 'extensionMarker' ) ] ensure: [
		self removeSelector: #extensionMarker from: class ]
]

{ #category : 'tests' }
MCPToolGetClassTest >> testIncludeSourcePagesALargeClassByMethods [
	"A page of the file holds a page of methods. The first opens with the definition, a later one holds its methods alone, and the pages put end to end are the whole file."

	| class first pageSize second total |
	pageSize := MCPToolGetClass new defaultPageLimit.
	class := self classNamed: self baseClassName.
	1 to: pageSize + 1 do: [ :index |
	self ensureMethodSource: ('pagedMarker{1} ^ {1}' format: { index }) onClassNamed: self baseClassName ].
	total := class localMethods size + class classSide localMethods size.
	self assert: total equals: pageSize + 3.
	first := self callToolWith: {
			         (#name -> self baseClassName).
			         (#includeSource -> true) } asDictionary.
	second := self callToolWith: {
			          (#name -> self baseClassName).
			          (#includeSource -> true).
			          (#offset -> pageSize) } asDictionary.
	self
		assert: (self summaryFrom: first)
		equals: ('Got class {1} as its Tonel file, with methods 1 to {2} of {3}. Next page: offset {2}.' format: {
					 self baseClassName.
					 pageSize.
					 total }).
	self assert: ((self dataFrom: first) at: #nextOffset) equals: pageSize.
	self assert: (self summaryFrom: second) equals: ('Got methods {1} to {2} of {2} in the Tonel file of class {3}.' format: {
				 (pageSize + 1).
				 total.
				 self baseClassName }).
	self deny: ((self dataFrom: second) includesKey: #nextOffset).
	self deny: (((self dataFrom: second) at: #source) includesSubstring: 'Class {').
	self
		assert: ((self dataFrom: first) at: #source) , ((self dataFrom: second) at: #source)
		equals: (TonelWriter sourceCodeOf: class)
]

{ #category : 'tests' }
MCPToolGetClassTest >> testIncludeSourceSaysWhenTheOffsetIsPastTheLastMethod [

	| result |
	result := self callToolWith: {
			          (#name -> self baseClassName).
			          (#includeSource -> true).
			          (#offset -> 10) } asDictionary.
	self
		assert: (self summaryFrom: result)
		equals: ('No methods from offset 10: the Tonel file of class {1} holds 2 methods.' format: { self baseClassName }).
	self deny: ((self dataFrom: result) includesKey: #source)
]

{ #category : 'tests' }
MCPToolGetClassTest >> testIncludesClassCommentsWhenRequested [

	| data result subclasses |
	result := self callToolWith: {
			          (#name -> self childZClassName).
			          (#includeComment -> true).
			          (#upToSuperclass -> self baseClassName).
			          (#subclassDepth -> 1) } asDictionary.
	data := self dataFrom: result.
	subclasses := data at: #subclasses.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self resultIndicatesError: result).
	self assert: (data at: #comment) equals: 'Child Z fixture class comment.'.
	self deny: (data includesKey: #superclasses).
	self assert: subclasses size equals: 1.
	self assert: (subclasses first at: #class) equals: self grandchildClassName.
	self assert: (subclasses first at: #comment) equals: 'Grandchild fixture class comment.'
]

{ #category : 'tests' }
MCPToolGetClassTest >> testIncludesDirectSubclasses [

	| data result subclasses |
	result := self callToolWith: {
			          (#name -> self baseClassName).
			          (#subclassDepth -> 1) } asDictionary.
	data := self dataFrom: result.
	subclasses := data at: #subclasses.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self resultIndicatesError: result).
	self assert: (subclasses collect: [ :each | each at: #class ]) equals: {
			self childAClassName.
			self childZClassName } asArray
]

{ #category : 'tests' }
MCPToolGetClassTest >> testIncludesNamedSuperclassChain [

	| data result superclasses |
	result := self callToolWith: {
			          (#name -> self grandchildClassName).
			          (#upToSuperclass -> 'Object') } asDictionary.
	data := self dataFrom: result.
	superclasses := data at: #superclasses.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self resultIndicatesError: result).
	self assert: (superclasses collect: [ :each | each at: #class ]) equals: {
			self childZClassName.
			self baseClassName } asArray
]

{ #category : 'tests' }
MCPToolGetClassTest >> testIncludesSharedPoolNamesForSharedPoolUsingClass [

	| data result |
	result := self callToolWith: { (#name -> 'AbstractTimeZone') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: ((data at: #sharedPools) includes: 'ChronologyConstants')
]

{ #category : 'tests' }
MCPToolGetClassTest >> testIncludesSubclassesUpToRequestedDepth [

	| data result subclasses |
	result := self callToolWith: {
			          (#name -> self baseClassName).
			          (#subclassDepth -> 2) } asDictionary.
	data := self dataFrom: result.
	subclasses := data at: #subclasses.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self resultIndicatesError: result).
	self assert: (subclasses collect: [ :each | each at: #class ]) equals: {
			self childAClassName.
			self childZClassName.
			self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolGetClassTest >> testIncludesTraitNamesForTraitUsingClass [

	| data result |
	result := self callToolWith: { (#name -> 'AlignmentMorph') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: ((data at: #traits) anySatisfy: [ :each | each includesSubstring: 'TAbleToRotate' ]).
	self deny: (data includesKey: #classTraits)
]

{ #category : 'tests' }
MCPToolGetClassTest >> testKeepsATraitCompositionThatExcludesAMethod [

	| data result |
	result := self callToolWith: { (#name -> MCPToolMethodSearchTraitExcluder name) } asDictionary.
	data := self dataFrom: result.
	self assert: ((data at: #traitComposition) includesSubstring: 'mcpTraitFixtureValue').
	self assert: ((data at: #classTraitComposition) includesSubstring: 'mcpTraitFixtureValue')
]

{ #category : 'tests' }
MCPToolGetClassTest >> testLeavesOutClassTraitsThatMirrorTheTraits [
	"Using a trait gives the class side the trait's class side; classTraits is named only when the class side says something else."

	| data |
	data := self dataFrom: (self callToolWith: { (#name -> MCPToolMethodSearchTraitUser name) } asDictionary).
	self assert: (data at: #traits) equals: { TMCPToolMethodSearchFixture name asString }.
	self deny: (data includesKey: #classTraits).
	self assert:
		(MCPClassDescriptionInfo new classSideTraitsOf: MCPToolMethodSearchTraitUser mirrorTheTraits: { TMCPToolMethodSearchFixture }).
	self deny: (MCPClassDescriptionInfo new classSideTraitsOf: MCPToolMethodSearchTraitUser mirrorTheTraits: #(  ))
]

{ #category : 'tests' }
MCPToolGetClassTest >> testLeavesOutTheTagOfAnUntaggedClass [
	"An untagged class sits in its package's root tag, which says nothing; a tagged one names its tag."

	| data result |
	result := self callToolWith: { (#name -> MCPToolGetMethodTestTarget name) } asDictionary.
	data := self dataFrom: result.
	self deny: (data includesKey: #tag).
	self deny: (((result at: #content) first at: #text) includesSubstring: 'tag:').
	self assert: MCPToolGetMethodTestTarget mcpTagName isNil.
	self assert: (self classNamed: self baseClassName) mcpTagName equals: self generatedTagName
]

{ #category : 'tests' }
MCPToolGetClassTest >> testNamesALayoutOnlyWhenItIsNotFixed [

	| data |
	data := self dataFrom: (self callToolWith: { (#name -> 'Array') } asDictionary).
	self assert: (data at: #layout) equals: Array classLayout class name asString.
	data := self dataFrom: (self callToolWith: { (#name -> MCPToolGetMethodTestTarget name) } asDictionary).
	self assert: MCPToolGetMethodTestTarget classLayout class equals: FixedLayout.
	self deny: (data includesKey: #layout)
]

{ #category : 'tests' }
MCPToolGetClassTest >> testOffsetGoesOnlyWithIncludeSource [
	"Without includeSource the answer is the class's description, which has no pages, so an offset past the first is refused rather than ignored. The default offset changes nothing and is accepted."

	| result |
	result := self callToolWith: {
			          (#name -> self baseClassName).
			          (#offset -> 1) } asDictionary.
	self
		assertResult: result
		refusesArgumentsSaying:
		'offset pages the Tonel file that includeSource answers; pass includeSource: true with it, or leave offset out.'.
	result := self callToolWith: {
			          (#name -> self baseClassName).
			          (#offset -> 0) } asDictionary.
	self assert: (self summaryFrom: result) equals: ('Got class {1}.' format: { self baseClassName })
]

{ #category : 'tests' }
MCPToolGetClassTest >> testOmitsATraitCompositionThatOnlyRepeatsTheTraits [

	| data result |
	result := self callToolWith: { (#name -> MCPToolMethodSearchTraitUser name) } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #traits) equals: { TMCPToolMethodSearchFixture name asString }.
	self deny: (data includesKey: #traitComposition).
	self deny: (data includesKey: #classTraitComposition)
]

{ #category : 'tests' }
MCPToolGetClassTest >> testRejectsNegativeSubclassDepth [

	self
		assertResult: (self callToolWith: {
					 (#name -> self baseClassName).
					 (#subclassDepth -> -1) } asDictionary)
		refusesArgumentsSaying: 'subclassDepth must be at least 0, not -1.'
]

{ #category : 'tests' }
MCPToolGetClassTest >> testReturnsStructuredErrorWhenClassIsMissing [

	| error result |
	result := self callToolWith: { (#name -> self missingClassName) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #class) equals: self missingClassName.
	self assert: ((error at: #message) beginsWith: ('Class {1} does not exist.' format: { self missingClassName })).
	self deny: (error includesKey: #scope)
]

{ #category : 'tests' }
MCPToolGetClassTest >> testToolRequiresNameInSchema [

	self assert: MCPToolGetClass new inputSchema required asSet equals: #( 'name' ) asSet
]

{ #category : 'tests' }
MCPToolGetClassTest >> testUpToSuperclassWrittenWithItsSideNamesTheClass [

	| plain sided |
	plain := self callToolWith: {
			         (#name -> self grandchildClassName).
			         (#upToSuperclass -> 'Object') } asDictionary.
	sided := self callToolWith: {
			         (#name -> self grandchildClassName).
			         (#upToSuperclass -> 'Object class') } asDictionary.
	self deny: (self resultIndicatesError: sided) description: [ self summaryFrom: sided ].
	self assert: ((self dataFrom: sided) at: #superclasses) equals: ((self dataFrom: plain) at: #superclasses)
]

{ #category : 'private - calling' }
MCPToolGetClassTest >> toolName [

	^ 'class_get'
]
