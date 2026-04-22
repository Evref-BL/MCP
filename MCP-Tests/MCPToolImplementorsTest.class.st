Class {
	#name : 'MCPToolImplementorsTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Tests',
	#package : 'MCP-Tests',
	#tag : 'Tests'
}

{ #category : 'private' }
MCPToolImplementorsTest >> callToolWith: someArguments [

	^ MCP new rpcToolCall: 'implementors' withParams: someArguments
]

{ #category : 'private' }
MCPToolImplementorsTest >> dataFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #data
]

{ #category : 'private' }
MCPToolImplementorsTest >> entryForReference: aReference in: implementors [

	^ implementors
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
		  ifNone: [ self fail: 'Missing implementor ' , aReference ]
]

{ #category : 'private' }
MCPToolImplementorsTest >> errorFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #error
]

{ #category : 'private' }
MCPToolImplementorsTest >> structuredContentFrom: aResult [

	^ aResult at: #structuredContent
]

{ #category : 'tests' }
MCPToolImplementorsTest >> testCanIncludeFormattedSource [

	| data implementor result |
	result := self callToolWith: {
			          (#selector -> 'dualProbe').
			          (#filter -> ' class>>').
			          (#includeSource -> true).
			          (#limit -> 1) } asDictionary.
	data := self dataFrom: result.
	implementor := self
		               entryForReference:
		               'MCPToolImplementorsTestExact class>>dualProbe'
		               in: (data at: #implementors).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self assert: (data at: #returnedCount) equals: 1.
	self deny: (data at: #truncated).
	self assert: (implementor includesKey: #source).
	self assert:
		((implementor at: #source) includesSubstring: String cr asString)
]

{ #category : 'tests' }
MCPToolImplementorsTest >> testClassesScopeLimitsToExactClasses [

	| data result |
	result := self callToolWith: {
			          (#selector -> 'hierarchyProbe').
			          (#scope -> 'classes').
			          (#classNames -> #( 'MCPToolImplementorsTestChild' )) }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		assert: (data at: #classNames) asArray
		equals: #( 'MCPToolImplementorsTestChild' ).
	self
		entryForReference: 'MCPToolImplementorsTestChild>>hierarchyProbe'
		in: (data at: #implementors)
]

{ #category : 'tests' }
MCPToolImplementorsTest >> testFilterCanNarrowResultsAndPaginate [

	| data result |
	result := self callToolWith: {
			          (#selector -> 'dualProbe').
			          (#filter -> ' class>>').
			          (#limit -> 1) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self assert: (data at: #returnedCount) equals: 1.
	self deny: (data at: #truncated).
	self
		entryForReference: 'MCPToolImplementorsTestExact class>>dualProbe'
		in: (data at: #implementors)
]

{ #category : 'tests' }
MCPToolImplementorsTest >> testHierarchyScopeSearchesWholeHierarchy [

	| data result |
	result := self callToolWith: {
			          (#selector -> 'hierarchyProbe').
			          (#scope -> 'hierarchy').
			          (#classNames -> #( 'MCPToolImplementorsTestMid' )) }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference: 'MCPToolImplementorsTestBase>>hierarchyProbe'
		in: (data at: #implementors).
	self
		entryForReference: 'MCPToolImplementorsTestChild>>hierarchyProbe'
		in: (data at: #implementors)
]

{ #category : 'tests' }
MCPToolImplementorsTest >> testImageScopeFindsInstanceAndClassImplementors [

	| data result |
	result := self callToolWith:
		          { (#selector -> 'dualProbe') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #scope) equals: 'image'.
	self assert: (data at: #side) equals: 'both'.
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference: 'MCPToolImplementorsTestExact>>dualProbe'
		in: (data at: #implementors).
	self
		entryForReference: 'MCPToolImplementorsTestExact class>>dualProbe'
		in: (data at: #implementors)
]

{ #category : 'tests' }
MCPToolImplementorsTest >> testPackagesScopeIncludesExtensionMethods [

	| data implementor result |
	result := self callToolWith: {
			          (#selector -> 'extensionProbe').
			          (#scope -> 'packages').
			          (#packageNames -> #( 'MCP-Tests-Resources-Extensions' )) }
			          asDictionary.
	data := self dataFrom: result.
	implementor := self
		               entryForReference:
		               'MCPToolImplementorsTestExtensionTarget>>extensionProbe'
		               in: (data at: #implementors).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		assert: (implementor at: #packageName)
		equals: 'MCP-Tests-Resources-Extensions'.
	self assert: (implementor at: #isExtension)
]

{ #category : 'tests' }
MCPToolImplementorsTest >> testPackagesScopeReturnsStructuredErrorWhenPackageNamesAreMissing [

	| error result structured |
	result := self callToolWith: {
			          (#selector -> 'extensionProbe').
			          (#scope -> 'packages') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #scope) equals: 'packages'.
	self assert:
		((error at: #message) includesSubstring: 'packageNames is required')
]

{ #category : 'tests' }
MCPToolImplementorsTest >> testToolRequiresSelectorInSchema [

	self assert:
		(MCPToolImplementors new inputSchema required includes: 'selector')
]
