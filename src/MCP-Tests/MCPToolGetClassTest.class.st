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

{ #category : 'private' }
MCPToolGetClassTest >> sourceOfPages: someOffsets [
	"The text the pages at someOffsets of the base fixture class hold, end to end."

	^ self sourceOfPages: someOffsets of: self baseClassName
]

{ #category : 'private' }
MCPToolGetClassTest >> sourceOfPages: someOffsets of: aClassName [
	"The text the pages at someOffsets of the class named aClassName hold, end to end."

	^ String streamContents: [ :stream |
			  someOffsets do: [ :each |
					  stream nextPutAll: ((self dataFrom: (self callToolWith: {
									     (#name -> aClassName).
									     (#offset -> each) } asDictionary)) at: #source ifAbsent: [ '' ]) ] ]
]

{ #category : 'running' }
MCPToolGetClassTest >> tearDown [

	self removeFixtureClasses.
	super tearDown
]

{ #category : 'tests' }
MCPToolGetClassTest >> testAMethodLongerThanAPageComesAlone [
	"A page holds at least one method, so a method longer than a page still comes, alone on its page, and the next page starts after it."

	| class first limit second |
	limit := MCPToolGetClass new pageCharacterLimit.
	class := self classNamed: self baseClassName.
	self
		ensureClassMethodSource: ('aLongMarker ^ ''{1}''' format: { (String new: limit withAll: $a) })
		onClassNamed: self baseClassName.
	first := self callToolWith: {
			         (#name -> self baseClassName).
			         (#offset -> 1) } asDictionary.
	second := self callToolWith: {
			          (#name -> self baseClassName).
			          (#offset -> 2) } asDictionary.
	self
		assert: (self summaryFrom: first)
		equals: ('Got method 1 of 3 in the Tonel file of class {1}. Next page: offset 2.' format: { self baseClassName }).
	self assert: ((self dataFrom: first) at: #source) size > limit.
	self assert: (((self dataFrom: first) at: #source) includesSubstring: 'aLongMarker').
	self
		assert: (self summaryFrom: second)
		equals: ('Got methods 2 to 3 of 3 in the Tonel file of class {1}.' format: { self baseClassName }).
	self assert: (self sourceOfPages: #( 0 1 2 )) equals: (TonelWriter sourceCodeOf: class)
]

{ #category : 'tests' }
MCPToolGetClassTest >> testAPageEndsBeforeItsCharacterLimit [
	"A page holds the methods that fit in its characters, fewer than its count when they are long, and the next page starts at the first one left out."

	| class limit pages |
	limit := MCPToolGetClass new pageCharacterLimit.
	class := self classNamed: self baseClassName.
	1 to: 3 do: [ :index |
			self
				ensureMethodSource: ('longMarker{1} ^ ''{2}''' format: {
							 index.
							 (String new: limit * 3 // 5 withAll: $a) })
				onClassNamed: self baseClassName ].
	pages := #( 1 4 5 ) collect: [ :each |
			         self callToolWith: {
					         (#name -> self baseClassName).
					         (#offset -> each) } asDictionary ].
	self assert: (pages collect: [ :each | self summaryFrom: each ]) equals: {
			('Got methods 1 to 3 of 5 in the Tonel file of class {1}. Next page: offset 4.' format: { self baseClassName }).
			('Got method 4 of 5 in the Tonel file of class {1}. Next page: offset 5.' format: { self baseClassName }).
			('Got method 5 of 5 in the Tonel file of class {1}.' format: { self baseClassName }) }.
	pages do: [ :each | self assert: ((self dataFrom: each) at: #source) size <= limit ].
	self assert: (self sourceOfPages: #( 0 1 4 5 )) equals: (TonelWriter sourceCodeOf: class)
]

{ #category : 'tests' }
MCPToolGetClassTest >> testATraitNamesTheClassesUsingIt [
	"No file holds the classes that use a trait, so they come beside its definition."

	| data result |
	result := self callToolWith: { (#name -> TMCPToolMethodSearchFixture name) } asDictionary.
	data := self dataFrom: result.
	self
		assert: (self summaryFrom: result)
		equals:
			('Got the definition of trait {1}, as its Tonel file opens. Its file holds 2 methods, 1 on the instance side and 1 on the class side. Next page: offset 1.'
				 format: { TMCPToolMethodSearchFixture name }).
	self assert: (data at: #isTrait).
	self assert: ((TonelWriter sourceCodeOf: TMCPToolMethodSearchFixture) beginsWith: (data at: #source)).
	self assert: ((data at: #source) includesSubstring: 'Trait {').
	self assert: (data at: #users) equals: {
			MCPToolMethodSearchTraitExcluder name asString.
			MCPToolMethodSearchTraitOtherUser name asString.
			MCPToolMethodSearchTraitOverrider name asString.
			MCPToolMethodSearchTraitUser name asString }
]

{ #category : 'tests' }
MCPToolGetClassTest >> testCountsOnlyTheMethodsTheClassDefines [
	"A class using a trait gets the trait's methods, and its class side also holds what Pharo installs from TraitedClass; neither is in its file. A class whose file holds no method has no page after its definition."

	| data result |
	self assert: MCPToolMethodSearchTraitUser selectors isNotEmpty.
	self assert: MCPToolMethodSearchTraitUser classSide selectors isNotEmpty.
	result := self callToolWith: { (#name -> MCPToolMethodSearchTraitUser name) } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #methods) equals: 0.
	self assert: (data at: #classMethods) equals: 0.
	self deny: (data includesKey: #nextOffset).
	self
		assert: (self summaryFrom: result)
		equals: ('Got the definition of class {1}, as its Tonel file opens. Its file holds no methods.' format:
				 { MCPToolMethodSearchTraitUser name }).
	data := self dataFrom: (self callToolWith: { (#name -> TMCPToolMethodSearchFixture name) } asDictionary).
	self assert: (data at: #methods) equals: 1.
	self assert: (data at: #classMethods) equals: 1
]

{ #category : 'tests' }
MCPToolGetClassTest >> testCountsWhatSeveralPackagesAdd [
	"Methods several packages add are counted together, and each package is named once. The class is named, not referred to, since method search tests count the methods that refer to it."

	| class data result |
	class := self classNamed: 'MCPToolMethodSearchReferenceTarget'.
	self ensureMethodSource: 'extensionMarker ^ 3' protocol: self generatedExtensionProtocol on: class.
	[
		result := self callToolWith: { (#name -> class name) } asDictionary.
		data := self dataFrom: result.
		self assert: (data at: #extensionMethods) equals: 3.
		self assert: (data at: #extensionPackages) equals: {
				self generatedExtensionPackageName.
				'MCP-Tests-Resources-Extensions' }.
		self assert: ((self summaryFrom: result) includesSubstring:
				 ('The file leaves out 3 methods that 2 other packages add to class {1}, each in its own package''s file. method_search with protocol "*" and scope.classes lists them.'
					  format: { class name })) ] ensure: [ self removeSelector: #extensionMarker from: class ]
]

{ #category : 'tests' }
MCPToolGetClassTest >> testGetsAClassWrittenWithItsSideAsTheClass [
	"class_get reads the file of a class, which holds both sides, so Foo class, as MCP's own answers print a class side, reads as Foo and gets what Foo gets."

	| plain sided |
	plain := self callToolWith: { (#name -> self baseClassName) } asDictionary.
	sided := self callToolWith: { (#name -> ('{1} class' format: { self baseClassName })) } asDictionary.
	self deny: (self resultIndicatesError: sided) description: [ self summaryFrom: sided ].
	self assert: (self summaryFrom: sided) equals: (self summaryFrom: plain).
	self assert: (self dataFrom: sided) equals: (self dataFrom: plain)
]

{ #category : 'tests' }
MCPToolGetClassTest >> testLeavesOutWhatATraitGives [
	"A method a class gets from a trait is in the trait's file. The class's file holds the methods the class defines itself, as an export of its package writes it: here the one that overrides the trait's on the instance side, and not the trait's own on the class side. A class that overrides nothing holds none of the trait's, on either side."

	| class source user writer |
	class := MCPToolMethodSearchTraitOverrider.
	writer := TonelWriter new.
	writer snapshot: (MCPackage named: class package name) snapshot.
	source := self sourceOfPages: #( 0 1 ) of: class name.
	self assert: source equals: (String streamContents: [ :stream | writer writeClass: class asClassDefinition on: stream ]).
	self assert: (source includesSubstring: '''overridden''').
	self deny: (source includesSubstring: 'from the class side of the trait').
	user := MCPToolMethodSearchTraitUser.
	source := self sourceOfPages: #( 0 ) of: user name.
	self assert: source equals: (String streamContents: [ :stream | writer writeClass: user asClassDefinition on: stream ]).
	self deny: (source includesSubstring: 'from the trait').
	self deny: (source includesSubstring: 'mcpTraitFixtureValue')
]

{ #category : 'tests' }
MCPToolGetClassTest >> testLeavesOutWhatOtherPackagesAdd [
	"A method another package adds to the class is in that package's file, not in the class's. The definition says how many there are and which packages hold them, and the method_search it names lists them."

	| class data expected listed result |
	class := self classNamed: self baseClassName.
	expected := TonelWriter sourceCodeOf: class.
	self ensureMethodSource: 'extensionMarker ^ 3' protocol: self generatedExtensionProtocol on: class.
	[
		result := self callToolWith: { (#name -> self baseClassName) } asDictionary.
		data := self dataFrom: result.
		self assert: (data at: #extensionMethods) equals: 1.
		self assert: (data at: #extensionPackages) equals: { self generatedExtensionPackageName }.
		self
			assert: (self summaryFrom: result)
			equals:
				('Got the definition of class {1}, as its Tonel file opens. Its file holds 2 methods, 1 on the instance side and 1 on the class side. The file leaves out 1 method that another package adds to class {1}, in that package''s own file. method_search with protocol "*" and scope.classes lists it. Next page: offset 1.'
					 format: { self baseClassName }).
		self assert:
			((self textFrom: result) includesSubstring: ('extensionPackages: [{1}]' format: { self generatedExtensionPackageName })).
		self assert: (self sourceOfPages: #( 0 1 )) equals: expected.
		listed := (self dataFrom: (self callToolNamed: 'method_search' withArguments: {
					            (#protocol -> '*').
					            (#scope -> { (#classes -> { self baseClassName }) } asDictionary) } asDictionary)) at: #methods.
		self assert: (listed collect: [ :each | each at: #selector ] as: Array) equals: #( 'extensionMarker' ) ] ensure: [
		self removeSelector: #extensionMarker from: class ]
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
MCPToolGetClassTest >> testSaysWhenTheOffsetIsPastTheLastMethod [

	| result |
	result := self callToolWith: {
			          (#name -> self baseClassName).
			          (#offset -> 3) } asDictionary.
	self
		assert: (self summaryFrom: result)
		equals: ('No methods from offset 3: the Tonel file of class {1} holds 2 methods.' format: { self baseClassName }).
	self deny: ((self dataFrom: result) includesKey: #source)
]

{ #category : 'tests' }
MCPToolGetClassTest >> testSeveralNamesEachAnswerTheirDefinition [

	| result results |
	result := self callToolWith: { (#name -> {
			           self baseClassName.
			           self childAClassName }) } asDictionary.
	self assert: (self summaryFrom: result) equals: 'Got 2 of 2 classes.'.
	results := (self dataFrom: result) at: #results.
	self assert: (results collect: [ :each | each at: #class ] as: Array) equals: {
			self baseClassName.
			self childAClassName }.
	self assert: ((results second at: #source) includesSubstring: 'Child A fixture class comment.')
]

{ #category : 'tests' }
MCPToolGetClassTest >> testTheArgumentsAreTheNamesAndWhereToStart [
	"class_get reads a class's file and nothing else: the description says what each page holds and that class_search lists a class's superclasses and subclasses. Its page size is the methods a page holds at most."

	| tool |
	tool := MCPToolGetClass new.
	self assert: (tool inputSchema properties collect: [ :each | each name ] as: Set) equals: #( 'name' 'offset' ) asSet.
	self assert: ((tool inputSchema asJRPCJSON at: #properties) at: 'offset') equals: tool offsetInputProperty asJRPCJSON.
	self assert: (tool description includesSubstring: 'Tonel').
	self assert: (tool description includesSubstring: 'class_search lists superclasses and subclasses').
	self assert: (tool contract at: #pageSize) equals: tool defaultPageLimit
]

{ #category : 'tests' }
MCPToolGetClassTest >> testTheDefinitionKeepsWhatTheClassDeclares [
	"What a definition declares beyond slots comes with it: the pools it reads, its traits, a trait composition that excludes a method on either side, and a layout other than fixed."

	| sourceOf |
	sourceOf := [ :aClassName | (self dataFrom: (self callToolWith: { (#name -> aClassName) } asDictionary)) at: #source ].
	self assert: ((sourceOf value: 'AbstractTimeZone') includesSubstring: 'ChronologyConstants').
	self assert: ((sourceOf value: 'AlignmentMorph') includesSubstring: 'TAbleToRotate').
	self
		assert: ((sourceOf value: MCPToolMethodSearchTraitExcluder name) allRangesOfSubstring: 'mcpTraitFixtureValue') size
		equals: 2.
	self assert: ((sourceOf value: 'Array') includesSubstring: '#type')
]

{ #category : 'tests' }
MCPToolGetClassTest >> testTheFirstPageIsTheCommentAndTheDefinition [
	"Offset 0 answers the class's Tonel file up to its first method: the comment and the definition, with its superclass, slots on both sides, class variables and package, written as the image's Tonel version writes them. It says how many methods the pages after it hold on each side, and where they start."

	| data expected result source |
	expected := TonelWriter sourceCodeOf: (self classNamed: self baseClassName).
	result := self callToolWith: { (#name -> self baseClassName) } asDictionary.
	data := self dataFrom: result.
	source := data at: #source.
	self
		assert: (self summaryFrom: result)
		equals:
			('Got the definition of class {1}, as its Tonel file opens. Its file holds 2 methods, 1 on the instance side and 1 on the class side. Next page: offset 1.'
				 format: { self baseClassName }).
	self assert: (expected beginsWith: source).
	self assert: ((expected allButFirst: source size) trimLeft beginsWith: '{').
	#( 'Base fixture class comment.' 'betaSlot' 'alphaSlot' 'classBeta' 'classAlpha' 'AlphaShared' 'BetaShared' ) do: [ :each |
		self assert: (source includesSubstring: each) description: each ].
	self assert: ((source lines detect: [ :each | each includesSubstring: '#superclass' ]) includesSubstring: 'Object').
	self assert: (source includesSubstring: self generatedPackageName).
	self assert: (source includesSubstring: self generatedTagName).
	self deny: (source includesSubstring: 'instanceMarker').
	self deny: (source includesSubstring: 'classMarker').
	self assert: (data at: #methods) equals: 1.
	self assert: (data at: #classMethods) equals: 1.
	self assert: (data at: #nextOffset) equals: 1.
	self assert: ((self textFrom: result) includesSubstring: source)
]

{ #category : 'tests' }
MCPToolGetClassTest >> testThePagesAfterTheFirstAreItsMethods [
	"Offset n starts at the class's nth method, both sides, in the order the file writes them, a page of methods at a time. The pages put end to end are the whole file."

	| class first pageSize second total |
	pageSize := MCPToolGetClass new defaultPageLimit.
	class := self classNamed: self baseClassName.
	1 to: pageSize + 1 do: [ :index |
	self ensureMethodSource: ('pagedMarker{1} ^ {1}' format: { index }) onClassNamed: self baseClassName ].
	total := class localMethods size + class classSide localMethods size.
	self assert: total equals: pageSize + 3.
	first := self callToolWith: {
			         (#name -> self baseClassName).
			         (#offset -> 1) } asDictionary.
	second := self callToolWith: {
			          (#name -> self baseClassName).
			          (#offset -> (pageSize + 1)) } asDictionary.
	self
		assert: (self summaryFrom: first)
		equals: ('Got methods 1 to {1} of {2} in the Tonel file of class {3}. Next page: offset {4}.' format: {
					 pageSize.
					 total.
					 self baseClassName.
					 (pageSize + 1) }).
	self assert: ((self dataFrom: first) at: #nextOffset) equals: pageSize + 1.
	self assert: (self summaryFrom: second) equals: ('Got methods {1} to {2} of {2} in the Tonel file of class {3}.' format: {
				 (pageSize + 1).
				 total.
				 self baseClassName }).
	self deny: ((self dataFrom: second) includesKey: #nextOffset).
	self deny: (((self dataFrom: first) at: #source) includesSubstring: 'Class {').
	self
		assert: (self sourceOfPages: #( 0 ) , {
					 1.
					 (pageSize + 1) })
		equals: (TonelWriter sourceCodeOf: class)
]

{ #category : 'tests' }
MCPToolGetClassTest >> testToolRequiresNameInSchema [

	| tool |
	tool := MCPToolGetClass new.
	self assert: tool name equals: 'class_get'.
	self assert: tool inputSchema required asSet equals: #( 'name' ) asSet.
	self assert: ((tool inputSchema properties collect: [ :each | each name ]) includes: 'offset')
]

{ #category : 'private - calling' }
MCPToolGetClassTest >> toolName [

	^ 'class_get'
]
