"
Tests for method_rewrite preview/apply behavior, scope handling, and guardrails.
"
Class {
	#name : 'MCPToolRewriteMethodsTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolRewriteMethodsTest >> applyArgumentsForRule: aRule [

	^ {
		  (#rules -> { aRule }).
		  (#scope -> { (#classes -> { self targetClassName }) } asDictionary).
		  (#apply -> true) } asDictionary
]

{ #category : 'private' }
MCPToolRewriteMethodsTest >> classSideSourceForSelector: aSelector [

	^ (self targetClass classSide compiledMethodAt: aSelector) sourceCode
]

{ #category : 'private' }
MCPToolRewriteMethodsTest >> previewArgumentsForRule: aRule [

	^ {
		  (#rules -> { aRule }).
		  (#scope -> { (#classes -> { self targetClassName }) } asDictionary) } asDictionary
]

{ #category : 'private' }
MCPToolRewriteMethodsTest >> restoreFixtureMethods [

	self ensureMethodSource: 'previewTarget ^ self oldValue' protocol: 'tests' on: self targetClass.
	self ensureMethodSource: 'untouchedTarget ^ self otherValue' protocol: 'tests' on: self targetClass.
	self ensureMethodSource: 'sideTarget ^ self oldSideValue' protocol: 'tests' on: self targetClass.
	self ensureMethodSource: 'sideTarget ^ self oldSideValue' protocol: 'tests' on: self targetClass classSide
]

{ #category : 'private' }
MCPToolRewriteMethodsTest >> rewriteRuleFrom: aMatchPattern to: aReplacementPattern [

	^ {
		  (#match -> aMatchPattern).
		  (#replacement -> aReplacementPattern) } asDictionary
]

{ #category : 'private' }
MCPToolRewriteMethodsTest >> secondaryTargetClassName [

	^ 'MCPToolRewriteMethodsATarget'
]

{ #category : 'running' }
MCPToolRewriteMethodsTest >> setUp [

	super setUp.
	self removeClassNamed: self targetClassName.
	self removeClassNamed: self secondaryTargetClassName.
	self
		createClassNamed: self targetClassName
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	self restoreFixtureMethods
]

{ #category : 'private' }
MCPToolRewriteMethodsTest >> sourceForSelector: aSelector [

	^ (self targetClass compiledMethodAt: aSelector) sourceCode
]

{ #category : 'private' }
MCPToolRewriteMethodsTest >> targetClass [

	^ self classNamed: self targetClassName
]

{ #category : 'private' }
MCPToolRewriteMethodsTest >> targetClassName [

	^ 'MCPToolRewriteMethodsTestTarget'
]

{ #category : 'running' }
MCPToolRewriteMethodsTest >> tearDown [

	self removeClassNamed: self secondaryTargetClassName.
	self removeClassNamed: self targetClassName.
	super tearDown
]

{ #category : 'tests' }
MCPToolRewriteMethodsTest >> testNamingARuleClassStandsForItsPatterns [

	| specs |
	specs := MCPMethodRewriteRuleSpec specsForRuleClassNamed: 'MCPCollectionThenDoRule' startingAt: 1.
	self assert: specs size equals: 3.
	self assert: (specs collect: [ :each | each name ]) asSet equals: (Set with: 'MCPCollectionThenDoRule').
	self assert: ((specs collect: [ :each | each match ]) anySatisfy: [ :each | each includesSubstring: 'collect:' ]).
	self assert: ((specs collect: [ :each | each replacement ]) allSatisfy: [ :each | each includesSubstring: 'thenDo:' ]).
	"One rule always expands the same way, even though Renraku does not keep the declared order."
	self
		assert: (specs collect: [ :each | each match ])
		equals: ((MCPMethodRewriteRuleSpec specsForRuleClassNamed: 'MCPCollectionThenDoRule' startingAt: 1) collect: [ :each |
				 each match ])
]

{ #category : 'tests' }
MCPToolRewriteMethodsTest >> testNamingARuleThatIsNotMCPsOwn [
	"The rules worth applying are not only the ones MCP wrote."

	| specs |
	specs := MCPMethodRewriteRuleSpec specsForRuleClassNamed: 'ReEqualNilRule' startingAt: 1.
	self deny: specs isEmpty.
	self assert: (specs collect: [ :each | each name ]) asSet equals: (Set with: 'ReEqualNilRule')
]

{ #category : 'tests' }
MCPToolRewriteMethodsTest >> testRuleThatComputesItsReplacementIsRejected [
	"A rule can build its replacement with a block, which has no pattern form to hand over."

	| error result |
	result := self callToolWith: {
			          (#ruleClasses -> #( 'ReIconHardcodedMessageRule' )).
			          (#scope -> { (#classes -> { self targetClassName }) } asDictionary) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: ((error at: #message) includesSubstring: 'computes its replacement')
]

{ #category : 'tests' }
MCPToolRewriteMethodsTest >> testRulesOrRuleClassesIsRequired [

	| error result |
	result := self callToolWith: { (#scope -> { (#classes -> { self targetClassName }) } asDictionary) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: ((error at: #message) includesSubstring: 'rules, ruleClasses, or both')
]

{ #category : 'tests' }
MCPToolRewriteMethodsTest >> testRuleClassWithoutPatternsIsRejected [

	| error result |
	result := self callToolWith: {
			          (#ruleClasses -> #( 'Object' )).
			          (#scope -> { (#classes -> { self targetClassName }) } asDictionary) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: ((error at: #message) includesSubstring: 'ReNodeRewriteRule')
]

{ #category : 'tests' }
MCPToolRewriteMethodsTest >> testApplyMutatesMethodInOneCall [

	| data result rule |
	rule := self rewriteRuleFrom: 'self oldValue' to: 'self newValue'.
	result := self callToolWith: (self applyArgumentsForRule: rule).
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #apply).
	self assert: (data at: #changeCount) equals: 1.
	self assert: (data at: #appliedCount) equals: 1.
	self assert: ((self sourceForSelector: #previewTarget) includesSubstring: 'newValue')
]

{ #category : 'tests' }
MCPToolRewriteMethodsTest >> testApplyRefusesAScopeThatNamesNothing [

	| error result rule |
	rule := self rewriteRuleFrom: 'self oldValue' to: 'self newValue'.
	result := self callToolWith: {
			          (#rules -> { rule }).
			          (#scope -> Dictionary new).
			          (#apply -> true) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'RewriteApplyRequiresExplicitScope'.
	self assert: ((self sourceForSelector: #previewTarget) includesSubstring: 'oldValue')
]

{ #category : 'tests' }
MCPToolRewriteMethodsTest >> testClassSideScopeRewritesOnlyClassSideMethod [

	| change data result rule |
	rule := self rewriteRuleFrom: 'self oldSideValue' to: 'self newSideValue'.
	result := self callToolWith: {
			          (#rules -> { rule }).
			          (#scope -> {
				           (#classes -> { self targetClassName }).
				           (#side -> 'class') } asDictionary) } asDictionary.
	data := self dataFrom: result.
	change := (data at: #changes) first.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #changeCount) equals: 1.
	self assert: (change at: #side) equals: 'class'.
	self assert: (change at: #selector) equals: 'sideTarget'.
	self assert: ((change at: #newSource) includesSubstring: 'newSideValue').
	self assert: ((self sourceForSelector: #sideTarget) includesSubstring: 'oldSideValue').
	self assert: ((self classSideSourceForSelector: #sideTarget) includesSubstring: 'oldSideValue')
]

{ #category : 'tests' }
MCPToolRewriteMethodsTest >> testInvalidLhsPatternReportsRuleDiagnostics [

	| error result validRule |
	validRule := self rewriteRuleFrom: 'self otherValue' to: 'self sameValue'.
	result := self callToolWith: {
			          (#rules -> {
				           validRule.
				           {
					           (#name -> 'broken-match').
					           (#match -> 'self +').
					           (#replacement -> 'self newValue').
					           (#isForMethod -> false) } asDictionary }).
			          (#scope -> { (#classes -> { self targetClassName }) } asDictionary) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'RewriteRuleInvalidPattern'.
	self assert: (error at: #ruleIndex) equals: 2.
	self assert: (error at: #ruleName) equals: 'broken-match'.
	self assert: (error at: #match) equals: 'self +'.
	self assert: (error at: #replacement) equals: 'self newValue'.
	self deny: (error at: #isForMethod).
	self assert: (error includesKey: #backendErrorClass).
	self assert: (error includesKey: #backendMessage)
]

{ #category : 'tests' }
MCPToolRewriteMethodsTest >> testInvalidRhsPatternReportsRuleDiagnostics [

	| error result |
	result := self callToolWith: {
			          (#rules -> { {
				           (#name -> 'broken-replacement').
				           (#match -> 'self oldValue').
				           (#replacement -> 'self +').
				           (#isForMethod -> false) } asDictionary }).
			          (#scope -> { (#classes -> { self targetClassName }) } asDictionary) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'RewriteRuleInvalidPattern'.
	self assert: (error at: #ruleIndex) equals: 1.
	self assert: (error at: #ruleName) equals: 'broken-replacement'.
	self assert: (error at: #match) equals: 'self oldValue'.
	self assert: (error at: #replacement) equals: 'self +'.
	self deny: (error at: #isForMethod).
	self assert: (error includesKey: #backendErrorClass).
	self assert: (error includesKey: #backendMessage)
]

{ #category : 'tests' }
MCPToolRewriteMethodsTest >> testMissingClassScopeRejectsRewriteBeforePartialPreview [

	| error result rule suggestions |
	rule := self rewriteRuleFrom: 'self oldValue' to: 'self newValue'.
	result := self callToolWith: {
			          (#rules -> { rule }).
			          (#scope -> { (#classes -> {
				            self targetClassName.
				            'MCPDefinitelyMissingRewriteClass' }) } asDictionary) } asDictionary.
	error := self errorFrom: result.
	suggestions := error at: #suggestions.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #class) equals: 'MCPDefinitelyMissingRewriteClass'.
	self assert: (error at: #scope) equals: 'classes'.
	self assert: suggestions size <= 5.
	self assert: ((error at: #message) includesSubstring: 'Did you mean:').
	self assert: ((self sourceForSelector: #previewTarget) includesSubstring: 'oldValue')
]

{ #category : 'tests' }
MCPToolRewriteMethodsTest >> testApplyOmitsTheSourcesAPreviewCarries [

	| applied change previewed rule |
	rule := self rewriteRuleFrom: 'self oldValue' to: 'self newValue'.
	previewed := (self dataFrom: (self callToolWith: (self previewArgumentsForRule: rule))) at: #changes.
	self assert: ((previewed first) includesKey: #oldSource).
	self assert: ((previewed first) includesKey: #newSource).
	applied := (self dataFrom: (self callToolWith: (self applyArgumentsForRule: rule))) at: #changes.
	change := applied first.
	self deny: (change includesKey: #oldSource).
	self deny: (change includesKey: #newSource)
]

{ #category : 'tests' }
MCPToolRewriteMethodsTest >> testPreviewChangesAreSortedByClassNameClassSideAndSelector [

	| changes data result rule secondaryClass triples |
	self
		createClassNamed: self secondaryTargetClassName
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	secondaryClass := self classNamed: self secondaryTargetClassName.
	self ensureMethodSource: 'betaTarget ^ self oldValue' protocol: 'tests' on: secondaryClass.
	self ensureMethodSource: 'alphaTarget ^ self oldValue' protocol: 'tests' on: secondaryClass classSide.
	self ensureMethodSource: 'zetaTarget ^ self oldValue' protocol: 'tests' on: self targetClass.
	self ensureMethodSource: 'alphaTarget ^ self oldValue' protocol: 'tests' on: self targetClass classSide.
	rule := self rewriteRuleFrom: 'self oldValue' to: 'self newValue'.
	result := self callToolWith: {
			          (#rules -> { rule }).
			          (#scope -> { (#classes -> {
				            self targetClassName.
				            self secondaryTargetClassName }) } asDictionary) } asDictionary.
	data := self dataFrom: result.
	changes := data at: #changes.
	triples := changes collect: [ :each |
			           {
				           (each at: #class).
				           ((each at: #side ifAbsent: [ 'instance' ]) = 'class').
				           (each at: #selector) } ].
	self assert: triples asArray equals: {
			{
				self secondaryTargetClassName.
				false.
				'betaTarget' }.
			{
				self secondaryTargetClassName.
				true.
				'alphaTarget' }.
			{
				self targetClassName.
				false.
				'previewTarget' }.
			{
				self targetClassName.
				false.
				'zetaTarget' }.
			{
				self targetClassName.
				true.
				'alphaTarget' } }
]

{ #category : 'tests' }
MCPToolRewriteMethodsTest >> testPreviewReturnsChangesWithoutMutatingMethod [

	| change data result rule |
	rule := self rewriteRuleFrom: 'self oldValue' to: 'self newValue'.
	result := self callToolWith: (self previewArgumentsForRule: rule).
	data := self dataFrom: result.
	change := (data at: #changes) first.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (data at: #apply).
	self assert: (data at: #changeCount) equals: 1.
	self assert: (data at: #appliedCount) equals: 0.
	self assert: (change at: #class) equals: self targetClassName.
	self assert: (change at: #side) equals: 'instance'.
	self assert: (change at: #selector) equals: 'previewTarget'.
	self assert: ((change at: #oldSource) includesSubstring: 'oldValue').
	self assert: ((change at: #newSource) includesSubstring: 'newValue').
	self assert: ((self sourceForSelector: #previewTarget) includesSubstring: 'oldValue')
]

{ #category : 'tests' }
MCPToolRewriteMethodsTest >> testRewriteRuleNormalizesLineFeedsInPatterns [

	| parsedRequest rule source tool |
	source := '''line one' , String lf , 'line two'''.
	tool := MCPToolRewriteMethods new.
	parsedRequest := self parsedRequestForTool: tool arguments: {
			                 (#rules -> { {
				                  (#match -> source).
				                  (#replacement -> source) } asDictionary }).
			                 (#scope -> { (#classes -> { self targetClassName }) } asDictionary) } asDictionary.
	rule := parsedRequest rules first.
	self deny: (rule match includes: Character lf).
	self deny: (rule replacement includes: Character lf).
	self assert: (rule match includes: Character cr).
	self assert: (rule replacement includes: Character cr)
]

{ #category : 'tests' }
MCPToolRewriteMethodsTest >> testSchemaAdvertisesRewriteContract [

	| matchProperty propertyNames replacementProperty ruleProperties rulesProperty scopeProperty scopePropertyNames tool |
	tool := MCPToolRewriteMethods new.
	propertyNames := tool inputSchema properties collect: [ :each | each name ].
	rulesProperty := tool inputSchema properties detect: [ :each | each name = 'rules' ].
	ruleProperties := ((rulesProperty extraProperties at: #items) extraProperties at: #properties) collect: [ :each | each name ].
	matchProperty := ((rulesProperty extraProperties at: #items) extraProperties at: #properties) detect: [ :each | each name = 'match' ].
	replacementProperty := ((rulesProperty extraProperties at: #items) extraProperties at: #properties) detect: [ :each | each name = 'replacement' ].
	scopeProperty := tool inputSchema properties detect: [ :each | each name = 'scope' ].
	scopePropertyNames := (scopeProperty extraProperties at: #properties) collect: [ :each | each name ].

	self assert: tool name equals: 'method_rewrite'.
	self assert: tool inputSchema required asSet equals: #( 'scope' ) asSet.
	self assert: (tool description includesSubstring: 'Smalltalk AST pattern syntax').
	self assert: (tool description includesSubstring: 'not regex').
	self assert: (rulesProperty extraProperties at: #minItems) equals: 1.
	self assert: (matchProperty extraProperties at: #minLength) equals: 1.
	self assert: (replacementProperty extraProperties at: #minLength) equals: 1.
	self
		assert: propertyNames asSet
		equals: #( 'rules' 'ruleClasses' 'apply' 'scope' ) asSet.
	self assert: scopePropertyNames asSet equals: #( 'packages' 'classes' 'subclassesOf' 'superclassesOf' 'hierarchy' 'side' ) asSet.
	self assert: (ruleProperties includes: 'match').
	self assert: (ruleProperties includes: 'replacement').
	self assert: (ruleProperties includes: 'isForMethod')
]

{ #category : 'private' }
MCPToolRewriteMethodsTest >> toolName [

	^ 'method_rewrite'
]
