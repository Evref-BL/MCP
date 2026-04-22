Class {
	#name : 'MCPToolFindMethodsTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Tests',
	#package : 'MCP-Tests',
	#tag : 'Tests'
}

{ #category : 'private' }
MCPToolFindMethodsTest >> callToolWith: someArguments [

	^ MCP new rpcToolCall: 'find-methods' withParams: someArguments
]

{ #category : 'private' }
MCPToolFindMethodsTest >> dataFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #data
]

{ #category : 'private' }
MCPToolFindMethodsTest >> entryForReference: aReference in: methods [

	^ methods
		  detect: [ :each |
			  | reference |
			  reference := String streamContents: [ :stream |
				               stream nextPutAll: (each at: #className).
				               (each at: #side) = 'class' ifTrue: [
					               stream nextPutAll: ' class' ].
				               stream
					               nextPutAll: '>>';
					               nextPutAll: (each at: #selector) ].
			  reference = aReference ]
		  ifNone: [ self fail: 'Missing method ' , aReference ]
]

{ #category : 'private' }
MCPToolFindMethodsTest >> errorFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #error
]

{ #category : 'private' }
MCPToolFindMethodsTest >> structuredContentFrom: aResult [

	^ aResult at: #structuredContent
]

{ #category : 'private' }
MCPToolFindMethodsTest >> targetClassName [

	^ 'MCPToolFindMethodsTestTarget'
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testCanFilterAcrossExplicitProtocolTarget [

	| data result selectors |
	result := self callToolWith: {
			          (#scope -> 'classes').
			          (#classNames -> { self targetClassName }).
			          (#filter -> 'helpers').
			          (#filterTargets -> #( 'protocol' )) } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	data := self dataFrom: result.
	selectors := (data at: #methods) collect: [ :each |
		             each at: #selector ].
	self assert: (data at: #scope) equals: 'classes'.
	self assert: (data at: #filterTargets) equals: #( 'protocol' ).
	self assert: (data at: #totalCount) equals: 2.
	self
		assert: selectors asSet
		equals: #( 'betaHelper' 'classUtility' ) asSet
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testCanFilterAcrossExplicitSourceTargetWithoutIncludingSource [

	| data result |
	result := self callToolWith: {
			          (#scope -> 'classes').
			          (#classNames -> { self targetClassName }).
			          (#filter -> 'gamma value').
			          (#filterTargets -> #( 'source' )) } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	data := self dataFrom: result.
	self assert: (data at: #filterTargets) equals: #( 'source' ).
	self assert: (data at: #totalCount) equals: 1.
	self
		assert: ((data at: #methods) first at: #selector)
		equals: 'gammaUtility'.
	self deny: ((data at: #methods) first includesKey: #source)
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testCanFilterPaginateAndIncludeSource [

	| data result |
	result := self callToolWith: {
			          (#scope -> 'classes').
			          (#classNames -> { self targetClassName }).
			          (#side -> 'class').
			          (#filter -> 'meta').
			          (#filterTargets -> #( 'protocol' )).
			          (#includeSource -> true).
			          (#limit -> 1) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #sourceIncluded).
	self assert: (data at: #filterTargets) equals: #( 'protocol' ).
	self assert: (data at: #totalCount) equals: 2.
	self assert: (data at: #returnedCount) equals: 1.
	self assert: (data at: #truncated).
	self assert:
		((data at: #methods) allSatisfy: [ :each |
			 (each at: #side) = 'class' ]).
	self assert: ((data at: #methods) allSatisfy: [ :each |
			 (each at: #protocol) includesSubstring: 'meta' ]).
	self assert:
		((data at: #methods) allSatisfy: [ :each |
			 each includesKey: #source ]).
	self assert: ((data at: #methods) anySatisfy: [ :each |
			 (each at: #source) includesSubstring: String cr asString ])
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testClassesScopeReturnsMethodsForExactClassNames [

	| data result selectors |
	result := self callToolWith: {
			          (#scope -> 'classes').
			          (#classNames -> { self targetClassName }) } asDictionary.
	data := self dataFrom: result.
	selectors := (data at: #methods) collect: [ :each |
		             each at: #selector ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #scope) equals: 'classes'.
	self
		assert: (data at: #classNames)
		equals: { self targetClassName } asArray.
	self assert: (data at: #side) equals: 'both'.
	self assert: (data at: #totalCount) equals: 5.
	self assert: (data at: #returnedCount) equals: 5.
	self
		assert: selectors asSet
		equals: #( 'alphaNeedleSelector' 'betaHelper' 'classNeedleSelector'
			   'classUtility' 'gammaUtility' ) asSet.
	self
		entryForReference:
		self targetClassName , ' class>>classNeedleSelector'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testDefaultFilterAppliesToSelectorOnly [

	| data result |
	result := self callToolWith: {
			          (#scope -> 'classes').
			          (#classNames -> { self targetClassName }).
			          (#filter -> 'helpers') } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	data := self dataFrom: result.
	self assert: (data at: #scope) equals: 'classes'.
	self assert: (data at: #filterTargets) equals: #( 'selector' ).
	self assert: (data at: #totalCount) equals: 0.
	self assert: (data at: #returnedCount) equals: 0.
	self assert: (data at: #methods) isEmpty
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testHierarchyScopeReturnsWholeHierarchy [

	| data result |
	result := self callToolWith: {
			          (#scope -> 'hierarchy').
			          (#classNames -> #( 'MCPToolImplementorsTestMid' )).
			          (#side -> 'instance').
			          (#filter -> 'hierarchyProbe') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #scope) equals: 'hierarchy'.
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference: 'MCPToolImplementorsTestBase>>hierarchyProbe'
		in: (data at: #methods).
	self
		entryForReference: 'MCPToolImplementorsTestChild>>hierarchyProbe'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testPackagesScopeIncludesExtensionMethods [

	| data method result |
	result := self callToolWith: {
			          (#scope -> 'packages').
			          (#packageNames -> #( 'MCP-Tests-Resources-Extensions' )).
			          (#filter -> 'extensionProbe') } asDictionary.
	data := self dataFrom: result.
	method := self
		          entryForReference:
		          'MCPToolImplementorsTestExtensionTarget>>extensionProbe'
		          in: (data at: #methods).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #scope) equals: 'packages'.
	self assert: (data at: #totalCount) equals: 1.
	self
		assert: (method at: #packageName)
		equals: 'MCP-Tests-Resources-Extensions'.
	self assert: (method at: #isExtension)
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testReturnsStructuredErrorForInvalidFilterTarget [

	| error result structured |
	result := self callToolWith: {
			          (#scope -> 'classes').
			          (#classNames -> { self targetClassName }).
			          (#filter -> 'needle').
			          (#filterTargets -> #( 'bogus' )) } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #scope) equals: 'classes'.
	self assert: (error at: #errorClass) equals: 'Error'.
	self assert:
		((error at: #message) includesSubstring: 'filterTargets').
	self assert: ((error at: #message) includesSubstring: 'bogus')
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testReturnsStructuredErrorForInvalidRegex [

	| error result structured |
	result := self callToolWith: {
			          (#scope -> 'classes').
			          (#classNames -> { self targetClassName }).
			          (#filter -> '[').
			          (#filterMode -> 'regex') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #scope) equals: 'classes'.
	self assert: (error at: #errorClass) equals: 'RegexSyntaxError'.
	self assert:
		((error at: #message) includesSubstring: 'no terminating')
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testReturnsStructuredErrorWhenClassIsMissing [

	| error result structured |
	result := self callToolWith: {
			          (#scope -> 'classes').
			          (#classNames
			           -> #( 'MCPDefinitelyMissingFindMethodsClass' )) }
			          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'. self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPDefinitelyMissingFindMethodsClass'.
	self assert: (error at: #scope) equals: 'classes'
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testReturnsStructuredErrorWhenPackageIsMissing [

	| error result structured |
	result := self callToolWith: {
			          (#scope -> 'packages').
			          (#packageNames -> #( 'MCP-Definitely-Missing' )) }
			          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'. self assert: (error at: #errorCode) equals: 'PackageNotFound'.
	self
		assert: (error at: #packageName)
		equals: 'MCP-Definitely-Missing'.
	self assert: (error at: #scope) equals: 'packages'
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testToolDoesNotRequireArgumentsInSchema [

	self
		assert: MCPToolFindMethods new inputSchema required
		equals: #(  )
]
