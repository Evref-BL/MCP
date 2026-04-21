Class {
	#name : 'MCPToolListMethodsTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolListMethodsTest >> callToolWith: someArguments [

	^ MCP new rpcToolCall: 'pharo-list-methods' withParams: someArguments
]

{ #category : 'private' }
MCPToolListMethodsTest >> dataFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #data
]

{ #category : 'private' }
MCPToolListMethodsTest >> errorFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #error
]

{ #category : 'private' }
MCPToolListMethodsTest >> structuredContentFrom: aResult [

	^ aResult at: #structuredContent
]

{ #category : 'tests' }
MCPToolListMethodsTest >> testListMethodsReturnsBothSidesByDefault [

	| data result selectors |
	result := self callToolWith:
		          { (#className -> 'MCPToolListMethodsTestTarget') }
			          asDictionary.
	data := self dataFrom: result.
	selectors := (data at: #methods) collect: [ :each |
		             each at: #selector ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #side) equals: 'both'.
	self assert: (data at: #totalCount) equals: 5.
	self assert: (data at: #returnedCount) equals: 5.
	self
		assert: selectors asSet
		equals: #( 'alphaNeedleSelector' 'betaHelper' 'classNeedleSelector'
			   'classUtility' 'gammaUtility' ) asSet.
	self assert:
		((data at: #methods) anySatisfy: [ :each |
			 (each at: #side) = 'class' ])
]

{ #category : 'tests' }
MCPToolListMethodsTest >> testListMethodsReturnsStructuredErrorForInvalidRegex [

	| error result structured |
	result := self callToolWith: {
			          (#className -> 'MCPToolListMethodsTestTarget').
			          (#selectorFilter -> '[').
			          (#filterMode -> 'regex') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self
		assert: (error at: #className)
		equals: 'MCPToolListMethodsTestTarget'.
	self assert: (error at: #errorClass) equals: 'RegexSyntaxError'.
	self assert:
		((error at: #message) includesSubstring: 'no terminating')
]

{ #category : 'tests' }
MCPToolListMethodsTest >> testListMethodsSupportsProtocolFilteringAndPagination [

	| data result |
	result := self callToolWith: {
			          (#className -> 'MCPToolListMethodsTestTarget').
			          (#side -> 'class').
			          (#protocolFilter -> 'meta').
			          (#limit -> 1) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self assert: (data at: #returnedCount) equals: 1.
	self assert: (data at: #truncated).
	self assert:
		((data at: #methods) allSatisfy: [ :each |
			 (each at: #side) = 'class' ]).
	self assert: ((data at: #methods) allSatisfy: [ :each |
			 (each at: #protocol) includesSubstring: 'meta' ])
]

{ #category : 'tests' }
MCPToolListMethodsTest >> testListMethodsSupportsSourceFilteringAndSourceInclusion [

	| data method result |
	result := self callToolWith: {
			          (#className -> 'MCPToolListMethodsTestTarget').
			          (#sourceFilter -> 'needle alpha').
			          (#includeSource -> true) } asDictionary.
	data := self dataFrom: result.
	method := (data at: #methods) first.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #sourceIncluded).
	self assert: (data at: #totalCount) equals: 1.
	self assert: (method at: #selector) equals: 'alphaNeedleSelector'.
	self assert:
		((method at: #source) includesSubstring: '''needle alpha''')
]

{ #category : 'tests' }
MCPToolListMethodsTest >> testToolRequiresClassNameInSchema [

	self assert:
		(MCPToolListMethods new inputSchema required includes: 'className')
]
