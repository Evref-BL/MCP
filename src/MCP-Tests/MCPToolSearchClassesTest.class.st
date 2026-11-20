"
Tests the class_search tool.
"
Class {
	#name : 'MCPToolSearchClassesTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolSearchClassesTest >> baseClassName [

	^ self fixturePrefix , 'Base'
]

{ #category : 'private' }
MCPToolSearchClassesTest >> childClassName [

	^ self fixturePrefix , 'Child'
]

{ #category : 'private' }
MCPToolSearchClassesTest >> entryNamed: aClassName in: classEntries [

	^ classEntries detect: [ :each | (each at: #class) = aClassName ] ifNone: [ self fail: 'Missing class entry ' , aClassName ]
]

{ #category : 'private' }
MCPToolSearchClassesTest >> fixtureClassNames [

	^ {
		  self baseClassName.
		  self childClassName.
		  self grandchildClassName } asArray
]

{ #category : 'private' }
MCPToolSearchClassesTest >> fixturePrefix [

	^ self class name asString , 'Fixture'
]

{ #category : 'private' }
MCPToolSearchClassesTest >> grandchildClassName [

	^ self fixturePrefix , 'Grandchild'
]

{ #category : 'private' }
MCPToolSearchClassesTest >> missingClassName [

	^ self fixturePrefix , 'Missing'
]

{ #category : 'private' }
MCPToolSearchClassesTest >> restoreFixtureClasses [

	self removeFixtureClasses.
	self
		createClassNamed: self baseClassName
		superclassName: 'Object'
		slots: #( betaSlot alphaSlot )
		classSlots: #( classBeta classAlpha ).
	self
		createClassNamed: self childClassName
		superclassName: self baseClassName
		slots: #(  )
		classSlots: #(  ).
	self
		createClassNamed: self grandchildClassName
		superclassName: self childClassName
		slots: #(  )
		classSlots: #(  )
]

{ #category : 'running' }
MCPToolSearchClassesTest >> setUp [

	super setUp.
	self restoreFixtureClasses
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testAnUntaggedClassRowHasNoTag [
	"An untagged class sits in its package's root tag, which its row leaves out; a filter on that tag still finds it."

	| entry result |
	result := self callToolWith: { (self searchScope: { (#classes -> #( 'MCPToolGetMethodTestTarget' )) }) } asDictionary.
	entry := ((self dataFrom: result) at: #classes) first.
	self deny: (entry includesKey: #tag).
	self assert: (((result at: #content) first at: #text) lines includes: '  MCPToolGetMethodTestTarget package=MCP-Tests-Resources').
	result := self callToolWith: {
			          (self searchScope: { (#classes -> #( 'MCPToolGetMethodTestTarget' )) }).
			          (#tag -> MCPToolGetMethodTestTarget packageTagName asString) } asDictionary.
	self assert: ((self dataFrom: result) at: #classes) size equals: 1
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testClassNamesReturnExactClassInfos [

	| baseEntry classes |
	classes := (self dataFrom: (self callToolWith: { (self searchScope: { (#classes -> {
					               self childClassName.
					               self baseClassName }) }) } asDictionary)) at: #classes.
	baseEntry := self entryNamed: self baseClassName in: classes.
	self assert: (classes collect: [ :each | each at: #class ]) equals: {
			self baseClassName.
			self childClassName } asArray.
	self assert: (classes allSatisfy: [ :each | each includesKey: #package ]).
	self assert: (baseEntry at: #package) equals: self generatedPackageName.
	self assert: (baseEntry at: #tag) equals: self generatedTagName.
	self deny: (baseEntry includesKey: #instanceSlots).
	self deny: (baseEntry includesKey: #classSlots).
	self deny: (baseEntry includesKey: #superclass).
	self deny: (baseEntry includesKey: #subclasses)
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testDefaultFilterAppliesToClassOnly [

	| classNames data result |
	result := self callToolWith: {
			          (self searchScope: { (#packages -> { self generatedPackageName }) }).
			          (#query -> self baseClassName) } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each | each at: #class ].
	self assert: (data at: #classes) size equals: 1.
	self assert: classNames equals: { self baseClassName } asArray
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testHierarchyOfScopeSelectsTheWholeHierarchy [
	"The scope advertised hierarchyOf but no query builder read it, so naming one silently widened the sweep to the whole image."

	| classNames data result |
	result := self callToolWith: {
			          (self searchScope: { (#hierarchyOf -> { self childClassName }) }).
			          (#query -> self fixturePrefix) } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each | each at: #class ].
	self assert: classNames equals: {
			self baseClassName.
			self childClassName.
			self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testImageScopeCanFilterAndPaginate [

	| classNames data pagination result summary |
	result := self callToolWith: {
			          (#query -> self fixturePrefix).
			          (#offset -> 1) } asDictionary.
	data := self dataFrom: result.
	pagination := data at: #pagination.
	summary := self summaryFrom: result.
	classNames := (data at: #classes) collect: [ :each | each at: #class ].
	self assert: classNames size equals: 2.
	self deny: (data includesKey: #nextOffset).
	self assert: (pagination at: #returnedCount) equals: 2.
	self assert: (pagination at: #totalCount) equals: 3.
	self deny: (pagination at: #truncated).
	self assert: summary equals: '2 of 3 classes match in the image.'.
	self assert: classNames equals: {
			self childClassName.
			self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testMissingClassScopeReturnsPartialResultsAndWarnings [

	| classNames data result warnings |
	result := self callToolWith: { (self searchScope: { (#classes -> {
				            self baseClassName.
				            self missingClassName }) }) } asDictionary.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	classNames := (data at: #classes) collect: [ :each | each at: #class ].
	self assert: (data at: #classes) size equals: 1.
	self assert: classNames equals: { self baseClassName } asArray.
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring: self missingClassName)
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testMissingScopeEntriesAreNamedByTheirKey [

	| warnings |
	warnings := self warningsFrom: (self callToolWith: { (self searchScope: {
					              (#classes -> #( 'Zzqxw' 'Transcript' )).
					              (#hierarchyOf -> #( 'Zzqxw' )).
					              (#superclassesOf -> #( 'Zzqxw' )).
					              (#subclassesOf -> #( 'Zzqxw' )) }) } asDictionary).
	self
		assert: warnings asSet
		equals:
			#( 'Class Zzqxw does not exist, so scope.classes skipped it.' 'Transcript is a global variable, not a class, so scope.classes skipped it.'
			   'Class Zzqxw does not exist, so scope.hierarchyOf skipped it.'
			   'Class Zzqxw does not exist, so scope.superclassesOf skipped it.'
			   'Class Zzqxw does not exist, so scope.subclassesOf skipped it.' ) asSet
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testMultipleScopesAreUnioned [

	| classNames data result |
	result := self callToolWith: {
			          (self searchScope: {
					           (#classes -> {
						            self class name asString.
						            self childClassName }).
					           (#superclassesOf -> { self childClassName }).
					           (#subclassesOf -> { self childClassName }) }).
			          (#query -> 'MCPToolSearchClasses') } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each | each at: #class ].
	self assert: (data at: #classes) size equals: 4.
	self assert: classNames equals: {
			self class name asString.
			self baseClassName.
			self childClassName.
			self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testNameFilterIgnoresCase [

	| classNames data result |
	result := self callToolWith: {
			          (self searchScope: { (#packages -> { self generatedPackageName }) }).
			          (#query -> self fixturePrefix asLowercase) } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each | each at: #class ].
	self assert: (data at: #classes) size equals: 3.
	self assert: classNames equals: {
			self baseClassName.
			self childClassName.
			self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testPackageNamesReturnPackageClasses [

	| classNames data result |
	result := self callToolWith: {
			          (self searchScope: { (#packages -> { self generatedPackageName }) }).
			          (#query -> self fixturePrefix) } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each | each at: #class ].
	self assert: (data at: #classes) size equals: 3.
	self assert: classNames equals: {
			self baseClassName.
			self childClassName.
			self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testPageStopsAtTheToolsOwnSize [
	"A search wider than one page says where the next one starts, without being told a size."

	| data result |
	result := self callToolWith: { (#query -> 'MCP') } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #classes) size equals: MCPToolSearchClasses new defaultPageLimit.
	self assert: (data at: #nextOffset) equals: MCPToolSearchClasses new defaultPageLimit.
	self assert: ((data at: #pagination) at: #truncated)
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testParentClassNamesReturnParentsOnly [

	| classNames data result |
	result := self callToolWith: {
			          (self searchScope: { (#superclassesOf -> { self childClassName }) }).
			          (#query -> self fixturePrefix) } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each | each at: #class ].
	self assert: (data at: #classes) size equals: 1.
	self assert: classNames equals: { self baseClassName } asArray
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testReturnsWarningsAndEmptyResultsWhenClassIsMissing [

	| data result warnings |
	result := self callToolWith: { (self searchScope: { (#classes -> { self missingClassName }) }) } asDictionary.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	self assert: (data at: #classes) size equals: 0.
	self assert: (data at: #classes) isEmpty.
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring: self missingClassName).
	self assert: (warnings first includesSubstring: 'Did you mean:')
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testReturnsWarningsAndEmptyResultsWhenPackageIsMissing [

	| data result warnings |
	result := self callToolWith: { (self searchScope: { (#packages -> #( 'MCP-Definitely-Missing' )) }) } asDictionary.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	self deny: ((self structuredContentFrom: result) includesKey: #error).
	self assert: (data at: #classes) size equals: 0.
	self assert: (data at: #classes) isEmpty.
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring: 'MCP-Definitely-Missing').
	self assert: (warnings first includesSubstring: 'does not exist, so ').
	self assert: (warnings first includesSubstring: 'Did you mean:')
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testRowsLeadWithTheClassName [

	| lines result |
	result := self callToolWith: { (#query -> self fixturePrefix) } asDictionary.
	lines := ((result at: #content) first at: #text) lines.
	self deny: (self resultIndicatesError: result).
	self assert: (lines second beginsWith: 'classes (each package=').
	self assert: (lines allButFirst: 2) equals: (self fixtureClassNames collect: [ :each | '  ' , each ])
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testRowsReachedByInheritanceSayWhatTheyInheritFrom [
	"Rows come by name, so a scope that reaches classes by inheritance gives each its superclass, from which the chain of superclasses and the tree of subclasses read. A row reached otherwise says nothing of it."

	| result rows |
	result := self callToolWith: { (self searchScope: { (#subclassesOf -> { self baseClassName }) }) } asDictionary.
	rows := (self dataFrom: result) at: #classes.
	self assert: (rows collect: [ :each | (each at: #class) -> (each at: #superclass) ] as: Array) equals: {
			(self childClassName -> self baseClassName).
			(self grandchildClassName -> self childClassName) }.
	self assert: ((self textFrom: result) includesSubstring: ('{1} superclass={2}' format: {
					  self grandchildClassName.
					  self childClassName })).
	rows := (self dataFrom: (self callToolWith: {
				          (self searchScope: { (#superclassesOf -> { self grandchildClassName }) }).
				          (#query -> self fixturePrefix) } asDictionary)) at: #classes.
	self assert: (rows collect: [ :each | (each at: #class) -> (each at: #superclass) ] as: Array) equals: {
			(self baseClassName -> 'Object').
			(self childClassName -> self baseClassName) }.
	rows := (self dataFrom: (self callToolWith: { (#query -> self fixturePrefix) } asDictionary)) at: #classes.
	self assert: rows size equals: 3.
	self deny: (rows anySatisfy: [ :each | each includesKey: #superclass ])
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testScopeArgumentIsRejected [

	self
		assertResult: (self callToolWith: { (#scope -> 'packages') } asDictionary)
		refusesArgumentsSaying: 'scope must be object, not string.'
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testScopeEntriesWrittenWithTheirSideSelectTheirClass [
	"A class search answers whole classes, so Foo class selects Foo, in every scope key, without a warning, and the summary names Foo."

	| result |
	result := self callToolWith: { (self searchScope: { (#classes -> { (self baseClassName , ' class') }) }) } asDictionary.
	self assert: (self warningsFrom: result) isEmpty.
	self assert: (((self dataFrom: result) at: #classes) collect: [ :each | each at: #class ]) equals: { self baseClassName }.
	self assert: (self summaryFrom: result) equals: '1 class in ' , self baseClassName , '.'.
	result := self callToolWith: {
			          (self searchScope: { (#hierarchyOf -> { (self childClassName , ' class') }) }).
			          (#query -> self fixturePrefix) } asDictionary.
	self assert: (self warningsFrom: result) isEmpty.
	self assert: (((self dataFrom: result) at: #classes) collect: [ :each | each at: #class ]) equals: {
			self baseClassName.
			self childClassName.
			self grandchildClassName }.
	self assert: (self summaryFrom: result) equals: '3 classes match in the hierarchy of ' , self childClassName , '.'
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testSearchClassesListsClassesForExistingPackage [
	"A package scope finds a class of that package wherever it falls among the pages: the name narrows the search, as a package this large needs."

	| result |
	result := self callToolNamed: 'class_search' withArguments: {
			          (self searchScope: { (#packages -> #( 'MCP-Tests' )) }).
			          (#query -> 'MCPToolMethodMutationTest') } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: ((((result at: #structuredContent) at: #data) at: #classes) collect: [ :each | each at: #class ] as: Array)
		equals: #( 'MCPToolMethodMutationTest' )
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testSubclassClassNamesReturnSubclassesOnly [

	| classNames data result |
	result := self callToolWith: {
			          (self searchScope: { (#subclassesOf -> { self childClassName }) }).
			          (#query -> self fixturePrefix) } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each | each at: #class ].
	self assert: (data at: #classes) size equals: 1.
	self assert: classNames equals: { self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testSuperclassAndSubclassScopesReturnRelatedClasses [

	| classNames data result |
	result := self callToolWith: {
			          (self searchScope: {
					           (#classes -> { self childClassName }).
					           (#superclassesOf -> { self childClassName }).
					           (#subclassesOf -> { self childClassName }) }).
			          (#query -> self fixturePrefix) } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each | each at: #class ].
	self assert: (data at: #classes) size equals: 3.
	self assert: classNames equals: {
			self baseClassName.
			self childClassName.
			self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testToolDoesNotRequireArgumentsInSchema [

	| schema scopeProperty |
	schema := MCPToolSearchClasses new inputSchema.
	scopeProperty := self inputPropertyNamed: 'scope' inTool: MCPToolSearchClasses new.
	self assert: MCPToolSearchClasses new name equals: 'class_search'.
	self assert: schema required equals: #(  ).
	self assert: (schema properties collect: [ :each | each name ] as: Set) equals: #( 'scope' 'query' 'tag' 'offset' ) asSet.
	self
		assert: ((scopeProperty extraProperties at: #properties) collect: [ :each | each name ] as: Set)
		equals: #( 'classes' 'packages' 'superclassesOf' 'subclassesOf' 'hierarchyOf' ) asSet
]

{ #category : 'private - calling' }
MCPToolSearchClassesTest >> toolName [

	^ 'class_search'
]
