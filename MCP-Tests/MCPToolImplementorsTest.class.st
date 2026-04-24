Class {
	#name : 'MCPToolImplementorsTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

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
	self assert: (data at: #implementors) size equals: 1.
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
			          (#classNames -> #( 'MCPToolHierarchyTestChild' )) }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		entryForReference: 'MCPToolHierarchyTestChild>>hierarchyProbe'
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
	self assert: (data at: #implementors) size equals: 1.
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
			          (#classNames -> #( 'MCPToolHierarchyTestMid' )) }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference: 'MCPToolHierarchyTestBase>>hierarchyProbe'
		in: (data at: #implementors).
	self
		entryForReference: 'MCPToolHierarchyTestChild>>hierarchyProbe'
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
		               'MCPToolReferencesTestExtensionTarget>>extensionProbe'
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

	self
		should: [
			self callToolWith: {
					(#selector -> 'extensionProbe').
					(#scope -> 'packages') } asDictionary ]
		raise: JRPCInvalidParameters
]

{ #category : 'tests' }
MCPToolImplementorsTest >> testToolRequiresSelectorInSchema [

	self assert:
		(MCPToolImplementors new inputSchema required includes: 'selector')
]

{ #category : 'private - calling' }
MCPToolImplementorsTest >> toolName [

	^ 'implementors'
]
