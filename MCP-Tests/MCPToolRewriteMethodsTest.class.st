"
Tests for rewrite-methods preview/apply behavior, scope handling, and guardrails.
"
Class {
	#name : 'MCPToolRewriteMethodsTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolRewriteMethodsTest >> applyArgumentsForRule: aRule expectedChangeSetHash: expectedHash [

	^ {
		  (#rules -> { aRule }).
		  (#classNames -> { self targetClassName }).
		  (#apply -> true).
		  (#expectedChangeSetHash -> expectedHash) } asDictionary
]

{ #category : 'private' }
MCPToolRewriteMethodsTest >> classSideSourceForSelector: aSelector [

	^ (self targetClass classSide compiledMethodAt: aSelector) sourceCode
]

{ #category : 'private' }
MCPToolRewriteMethodsTest >> previewArgumentsForRule: aRule [

	^ {
		  (#rules -> { aRule }).
		  (#classNames -> { self targetClassName }) } asDictionary
]

{ #category : 'private' }
MCPToolRewriteMethodsTest >> restoreFixtureMethods [

	self
		ensureMethodSource: 'previewTarget ^ self oldValue'
		protocol: 'tests'
		on: self targetClass.
	self
		ensureMethodSource: 'untouchedTarget ^ self otherValue'
		protocol: 'tests'
		on: self targetClass.
	self
		ensureMethodSource: 'sideTarget ^ self oldSideValue'
		protocol: 'tests'
		on: self targetClass.
	self
		ensureMethodSource: 'sideTarget ^ self oldSideValue'
		protocol: 'tests'
		on: self targetClass classSide
]

{ #category : 'private' }
MCPToolRewriteMethodsTest >> rewriteRuleFrom: lhsString to: rhsString [

	^ {
		  (#lhs -> lhsString).
		  (#rhs -> rhsString) } asDictionary
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
MCPToolRewriteMethodsTest >> testApplyMutatesMethodWhenExpectedChangeSetHashMatches [

	| data hash previewResult result rule |
	rule := self rewriteRuleFrom: 'self oldValue' to: 'self newValue'.
	previewResult := self callToolWith:
		                 (self previewArgumentsForRule: rule).
	hash := (self dataFrom: previewResult) at: #changeSetHash.
	result := self callToolWith:
		          (self
			           applyArgumentsForRule: rule
			           expectedChangeSetHash: hash).
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #apply).
	self assert: (data at: #changeCount) equals: 1.
	self assert: (data at: #appliedCount) equals: 1.
	self assert: (data at: #changeSetHash) equals: hash.
	self assert:
		((self sourceForSelector: #previewTarget) includesSubstring:
			 'newValue')
]

{ #category : 'tests' }
MCPToolRewriteMethodsTest >> testApplyRejectsMismatchedExpectedChangeSetHash [

	| badHash error previewResult result rule |
	rule := self rewriteRuleFrom: 'self oldValue' to: 'self newValue'.
	previewResult := self callToolWith:
		                 (self previewArgumentsForRule: rule).
	badHash := ((self dataFrom: previewResult) at: #changeSetHash) + 1.
	result := self callToolWith:
		          (self
			           applyArgumentsForRule: rule
			           expectedChangeSetHash: badHash).
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self
		assert: (error at: #errorCode)
		equals: 'RewriteChangeSetHashMismatch'.
	self assert: (error at: #expectedChangeSetHash) equals: badHash.
	self deny: (error at: #actualChangeSetHash) equals: badHash.
	self assert:
		((self sourceForSelector: #previewTarget) includesSubstring:
			 'oldValue')
]

{ #category : 'tests' }
MCPToolRewriteMethodsTest >> testApplyRequiresExplicitScopeUnlessForced [

	| error result rule |
	rule := self rewriteRuleFrom: 'self oldValue' to: 'self newValue'.
	result := self callToolWith: {
			          (#rules -> { rule }).
			          (#apply -> true).
			          (#expectedChangeSetHash -> 1) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self
		assert: (error at: #errorCode)
		equals: 'RewriteApplyRequiresExplicitScope'.
	self assert:
		((self sourceForSelector: #previewTarget) includesSubstring:
			 'oldValue')
]

{ #category : 'tests' }
MCPToolRewriteMethodsTest >> testApplyResultRequestsImageSaveButPreviewDoesNot [

	| applyResult previewResult tool |
	tool := MCPToolRewriteMethods new.
	previewResult := tool successResultText: 'preview' data: {
			                 (#apply -> false).
			                 (#appliedCount -> 0) } asDictionary.
	applyResult := tool successResultText: 'apply' data: {
			               (#apply -> true).
			               (#appliedCount -> 1) } asDictionary.
	self deny:
		(tool shouldSaveImageAfterSuccessfulExecutionForResult:
			 previewResult).
	self assert:
		(tool shouldSaveImageAfterSuccessfulExecutionForResult: applyResult)
]

{ #category : 'tests' }
MCPToolRewriteMethodsTest >> testClassSideScopeRewritesOnlyClassSideMethod [

	| change data result rule |
	rule := self
		        rewriteRuleFrom: 'self oldSideValue'
		        to: 'self newSideValue'.
	result := self callToolWith: {
			          (#rules -> { rule }).
			          (#classNames -> { self targetClassName }).
			          (#side -> 'class') } asDictionary.
	data := self dataFrom: result.
	change := (data at: #changes) first.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #changeCount) equals: 1.
	self assert: (change at: #classSide).
	self assert: (change at: #selector) equals: 'sideTarget'.
	self assert:
		((change at: #newSource) includesSubstring: 'newSideValue').
	self assert:
		((self sourceForSelector: #sideTarget) includesSubstring:
			 'oldSideValue').
	self assert:
		((self classSideSourceForSelector: #sideTarget) includesSubstring:
			 'oldSideValue')
]

{ #category : 'tests' }
MCPToolRewriteMethodsTest >> testInvalidLhsPatternReportsRuleDiagnostics [

	| error result validRule |
	validRule := self
		             rewriteRuleFrom: 'self otherValue'
		             to: 'self sameValue'.
	result := self callToolWith: {
			          (#rules -> {
				           validRule.
				           {
					           (#name -> 'broken-lhs').
					           (#lhs -> 'self +').
					           (#rhs -> 'self newValue').
					           (#isForMethod -> false) } asDictionary }).
			          (#classNames -> { self targetClassName }) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self
		assert: (error at: #errorCode)
		equals: 'RewriteRuleInvalidPattern'.
	self assert: (error at: #ruleIndex) equals: 2.
	self assert: (error at: #ruleName) equals: 'broken-lhs'.
	self assert: (error at: #lhs) equals: 'self +'.
	self assert: (error at: #rhs) equals: 'self newValue'.
	self deny: (error at: #isForMethod).
	self assert: (error includesKey: #backendErrorClass).
	self assert: (error includesKey: #backendMessage)
]

{ #category : 'tests' }
MCPToolRewriteMethodsTest >> testInvalidRhsPatternReportsRuleDiagnostics [

	| error result |
	result := self callToolWith: {
			          (#rules -> { {
				           (#name -> 'broken-rhs').
				           (#lhs -> 'self oldValue').
				           (#rhs -> 'self +').
				           (#isForMethod -> false) } asDictionary }).
			          (#classNames -> { self targetClassName }) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self
		assert: (error at: #errorCode)
		equals: 'RewriteRuleInvalidPattern'.
	self assert: (error at: #ruleIndex) equals: 1.
	self assert: (error at: #ruleName) equals: 'broken-rhs'.
	self assert: (error at: #lhs) equals: 'self oldValue'.
	self assert: (error at: #rhs) equals: 'self +'.
	self deny: (error at: #isForMethod).
	self assert: (error includesKey: #backendErrorClass).
	self assert: (error includesKey: #backendMessage)
]

{ #category : 'tests' }
MCPToolRewriteMethodsTest >> testPreviewCanOmitSources [

	| change data result rule |
	rule := self rewriteRuleFrom: 'self oldValue' to: 'self newValue'.
	result := self callToolWith: {
			          (#rules -> { rule }).
			          (#classNames -> { self targetClassName }).
			          (#includeSources -> false) } asDictionary.
	data := self dataFrom: result.
	change := (data at: #changes) first.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #changeCount) equals: 1.
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
	self
		ensureMethodSource: 'betaTarget ^ self oldValue'
		protocol: 'tests'
		on: secondaryClass.
	self
		ensureMethodSource: 'alphaTarget ^ self oldValue'
		protocol: 'tests'
		on: secondaryClass classSide.
	self
		ensureMethodSource: 'zetaTarget ^ self oldValue'
		protocol: 'tests'
		on: self targetClass.
	self
		ensureMethodSource: 'alphaTarget ^ self oldValue'
		protocol: 'tests'
		on: self targetClass classSide.
	rule := self rewriteRuleFrom: 'self oldValue' to: 'self newValue'.
	result := self callToolWith: {
			          (#rules -> { rule }).
			          (#classNames -> {
				           self targetClassName.
				           self secondaryTargetClassName }) } asDictionary.
	data := self dataFrom: result.
	changes := data at: #changes.
	triples := changes collect: [ :each |
		           {
			           (each at: #className).
			           (each at: #classSide).
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
	self assert: (data at: #changeSetHash) isInteger.
	self assert: (change at: #className) equals: self targetClassName.
	self assert: (change at: #classSide) equals: false.
	self assert: (change at: #selector) equals: 'previewTarget'.
	self assert: ((change at: #oldSource) includesSubstring: 'oldValue').
	self assert: ((change at: #newSource) includesSubstring: 'newValue').
	self assert:
		((self sourceForSelector: #previewTarget) includesSubstring:
			 'oldValue')
]

{ #category : 'tests' }
MCPToolRewriteMethodsTest >> testSchemaAdvertisesRewriteContract [

	| lhsProperty propertyNames rhsProperty ruleProperties rulesProperty tool |
	tool := MCPToolRewriteMethods new.
	propertyNames := tool inputSchema properties collect: [ :each |
		                 each name ].
	rulesProperty := tool inputSchema properties detect: [ :each |
		                 each name = 'rules' ].
	ruleProperties := ((rulesProperty extraProperties at: #items)
		                   extraProperties at: #properties) collect: [ :each |
		                  each name ].
	lhsProperty := ((rulesProperty extraProperties at: #items)
		                extraProperties at: #properties) detect: [ :each |
		               each name = 'lhs' ].
	rhsProperty := ((rulesProperty extraProperties at: #items)
		                extraProperties at: #properties) detect: [ :each |
		               each name = 'rhs' ].
	self assert: tool name equals: 'rewrite-methods'.
	self
		assert: tool inputSchema required asSet
		equals: #( 'rules' ) asSet.
	self assert:
		(tool description includesSubstring: 'RB AST pattern syntax').
	self assert: (tool description includesSubstring: 'not regex').
	self assert: (rulesProperty extraProperties at: #minItems) equals: 1.
	self assert: (lhsProperty extraProperties at: #minLength) equals: 1.
	self assert: (rhsProperty extraProperties at: #minLength) equals: 1.
	self assert: (propertyNames includes: 'apply').
	self assert: (propertyNames includes: 'expectedChangeSetHash').
	self assert: (propertyNames includes: 'force').
	self assert: (propertyNames includes: 'includeSources').
	self assert: (propertyNames includes: 'packageNames').
	self assert: (propertyNames includes: 'classNames').
	self assert: (propertyNames includes: 'hierarchyClassNames').
	self assert: (propertyNames includes: 'subclassClassNames').
	self assert: (propertyNames includes: 'parentClassNames').
	self assert: (propertyNames includes: 'side').
	self assert: (ruleProperties includes: 'lhs').
	self assert: (ruleProperties includes: 'rhs').
	self assert: (ruleProperties includes: 'isForMethod')
]

{ #category : 'private' }
MCPToolRewriteMethodsTest >> toolName [

	^ 'rewrite-methods'
]
