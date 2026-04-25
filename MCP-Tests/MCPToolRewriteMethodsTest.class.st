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
MCPToolRewriteMethodsTest >> applyArgumentsForRule: aRule expectedChangeCount: expectedCount [

	^ {
		  (#rules -> { aRule }).
		  (#classNames -> { self targetClassName }).
		  (#apply -> true).
		  (#expectedChangeCount -> expectedCount) } asDictionary
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

{ #category : 'running' }
MCPToolRewriteMethodsTest >> setUp [

	super setUp.
	self removeClassNamed: self targetClassName.
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

	self removeClassNamed: self targetClassName.
	super tearDown
]

{ #category : 'tests' }
MCPToolRewriteMethodsTest >> testApplyMutatesMethodWhenExpectedCountMatches [

	| data result rule |
	rule := self rewriteRuleFrom: 'self oldValue' to: 'self newValue'.
	result := self callToolWith:
		          (self applyArgumentsForRule: rule expectedChangeCount: 1).
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #apply).
	self assert: (data at: #changeCount) equals: 1.
	self assert: (data at: #appliedCount) equals: 1.
	self assert:
		((self sourceForSelector: #previewTarget) includesSubstring:
			 'newValue')
]

{ #category : 'tests' }
MCPToolRewriteMethodsTest >> testApplyRejectsMismatchedExpectedChangeCount [

	| error result rule |
	rule := self rewriteRuleFrom: 'self oldValue' to: 'self newValue'.
	result := self callToolWith:
		          (self applyArgumentsForRule: rule expectedChangeCount: 2).
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self
		assert: (error at: #errorCode)
		equals: 'RewriteChangeCountMismatch'.
	self assert: (error at: #expectedChangeCount) equals: 2.
	self assert: (error at: #actualChangeCount) equals: 1.
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
			          (#expectedChangeCount -> 1) } asDictionary.
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

	| propertyNames ruleProperties rulesProperty tool |
	tool := MCPToolRewriteMethods new.
	propertyNames := tool inputSchema properties collect: [ :each |
		                 each name ].
	rulesProperty := tool inputSchema properties detect: [ :each |
		                 each name = 'rules' ].
	ruleProperties := ((rulesProperty extraProperties at: #items)
		                   extraProperties at: #properties) collect: [ :each |
		                  each name ].
	self assert: tool name equals: 'rewrite-methods'.
	self
		assert: tool inputSchema required asSet
		equals: #( 'rules' ) asSet.
	self assert: (propertyNames includes: 'apply').
	self assert: (propertyNames includes: 'expectedChangeCount').
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
