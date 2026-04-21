Class {
	#name : 'MCPToolSendersTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolSendersTest >> callToolWith: someArguments [

	^ MCP new rpcToolCall: 'pharo-senders' withParams: someArguments
]

{ #category : 'private' }
MCPToolSendersTest >> dataFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #data
]

{ #category : 'private' }
MCPToolSendersTest >> errorFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #error
]

{ #category : 'private' }
MCPToolSendersTest >> methodReference: aMethodReference in: senders [

	^ senders
		  detect: [ :each | (each at: #methodReference) = aMethodReference ]
		  ifNone: [ self fail: 'Missing sender ' , aMethodReference ]
]

{ #category : 'private' }
MCPToolSendersTest >> structuredContentFrom: aResult [

	^ aResult at: #structuredContent
]

{ #category : 'tests' }
MCPToolSendersTest >> testClassesScopeFindsClassReferencesForExactClasses [

	| data result |
	result := self callToolWith: {
			          (#selector -> 'MCPToolSendersTestExtensionTarget').
			          (#scope -> 'classes').
			          (#classNames -> #( 'MCPToolSendersTestExact' )) }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 4.
	self
		assert: (data at: #classNames) asArray
		equals: #( 'MCPToolSendersTestExact' ).
	self
		methodReference: 'MCPToolSendersTestExact>>referenceExtensionTarget'
		in: (data at: #senders).
	self
		methodReference:
		'MCPToolSendersTestExact class>>referenceExtensionTarget'
		in: (data at: #senders).
	self
		methodReference:
		'MCPToolSendersTestExact>>sendExistingClassNamedSelector'
		in: (data at: #senders).
	self
		methodReference:
		'MCPToolSendersTestExact class>>sendExistingClassNamedSelector'
		in: (data at: #senders)
]

{ #category : 'tests' }
MCPToolSendersTest >> testClassesScopeLimitsToExactClasses [

	| data result |
	result := self callToolWith: {
			          (#selector -> 'hierarchyTarget').
			          (#scope -> 'classes').
			          (#classNames -> #( 'MCPToolSendersTestChild' )) }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		assert: (data at: #classNames) asArray
		equals: #( 'MCPToolSendersTestChild' ).
	self
		methodReference: 'MCPToolSendersTestChild>>childHierarchySender'
		in: (data at: #senders)
]

{ #category : 'tests' }
MCPToolSendersTest >> testFilterCanNarrowResultsPaginateAndIncludeSource [

	| data result sender |
	result := self callToolWith: {
			          (#selector -> 'sharedTarget').
			          (#filter -> ' class>>').
			          (#includeSource -> true).
			          (#limit -> 1) } asDictionary.
	data := self dataFrom: result.
	sender := self
		          methodReference:
		          'MCPToolSendersTestExact class>>classSendShared'
		          in: (data at: #senders).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self assert: (data at: #returnedCount) equals: 1.
	self deny: (data at: #truncated).
	self assert:
		((sender at: #source) includesSubstring: 'self sharedTarget')
]

{ #category : 'tests' }
MCPToolSendersTest >> testHierarchyScopeSearchesWholeHierarchy [

	| data result |
	result := self callToolWith: {
			          (#selector -> 'hierarchyTarget').
			          (#scope -> 'hierarchy').
			          (#classNames -> #( 'MCPToolSendersTestMid' )) }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self
		methodReference: 'MCPToolSendersTestBase>>baseHierarchySender'
		in: (data at: #senders).
	self
		methodReference: 'MCPToolSendersTestChild>>childHierarchySender'
		in: (data at: #senders)
]

{ #category : 'tests' }
MCPToolSendersTest >> testImageScopeFindsClassReferencesWhenSelectorMatchesExistingClassName [

	| data result |
	result := self callToolWith:
		          { (#selector -> 'MCPToolSendersTestExtensionTarget') }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #scope) equals: 'image'.
	self assert: (data at: #totalCount) equals: 4.
	self
		methodReference: 'MCPToolSendersTestExact>>referenceExtensionTarget'
		in: (data at: #senders).
	self
		methodReference:
		'MCPToolSendersTestExact class>>referenceExtensionTarget'
		in: (data at: #senders).
	self
		methodReference:
		'MCPToolSendersTestExact>>sendExistingClassNamedSelector'
		in: (data at: #senders).
	self
		methodReference:
		'MCPToolSendersTestExact class>>sendExistingClassNamedSelector'
		in: (data at: #senders)
]

{ #category : 'tests' }
MCPToolSendersTest >> testImageScopeFindsInstanceAndClassSenders [

	| data result |
	result := self callToolWith:
		          { (#selector -> 'sharedTarget') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #scope) equals: 'image'.
	self assert: (data at: #side) equals: 'both'.
	self assert: (data at: #totalCount) equals: 2.
	self
		methodReference: 'MCPToolSendersTestExact>>instanceSendShared'
		in: (data at: #senders).
	self
		methodReference: 'MCPToolSendersTestExact class>>classSendShared'
		in: (data at: #senders)
]

{ #category : 'tests' }
MCPToolSendersTest >> testPackagesScopeIncludesExtensionMethods [

	| data result sender |
	result := self callToolWith: {
			          (#selector -> 'extensionTarget').
			          (#scope -> 'packages').
			          (#packageNames -> #( 'MCP-Tests-Extensions' )) }
			          asDictionary.
	data := self dataFrom: result.
	sender := self
		          methodReference:
		          'MCPToolSendersTestExtensionTarget>>extensionSender'
		          in: (data at: #senders).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self assert: (sender at: #packageName) equals: 'MCP-Tests-Extensions'.
	self assert: (sender at: #isExtension)
]

{ #category : 'tests' }
MCPToolSendersTest >> testPackagesScopeReturnsStructuredErrorWhenPackageNamesAreMissing [

	| error result structured |
	result := self callToolWith: {
			          (#selector -> 'extensionTarget').
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
MCPToolSendersTest >> testToolRequiresSelectorInSchema [

	self assert:
		(MCPToolSenders new inputSchema required includes: 'selector')
]
