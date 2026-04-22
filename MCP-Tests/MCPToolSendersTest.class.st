Class {
	#name : 'MCPToolSendersTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Tests',
	#package : 'MCP-Tests',
	#tag : 'Tests'
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
MCPToolSendersTest >> entryForReference: aReference in: senders [

	^ senders
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
		  ifNone: [ self fail: 'Missing sender ' , aReference ]
]

{ #category : 'private' }
MCPToolSendersTest >> errorFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #error
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
			          (#mode -> 'class').
			          (#scope -> 'classes').
			          (#classNames -> #( 'MCPToolSendersTestExact' )) }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #mode) equals: 'class'.
	self assert: (data at: #totalCount) equals: 4.
	self
		assert: (data at: #classNames) asArray
		equals: #( 'MCPToolSendersTestExact' ).
	self
		entryForReference:
		'MCPToolSendersTestExact>>referenceExtensionTarget'
		in: (data at: #senders).
	self
		entryForReference:
		'MCPToolSendersTestExact class>>referenceExtensionTarget'
		in: (data at: #senders).
	self
		entryForReference:
		'MCPToolSendersTestExact>>sendExistingClassNamedSelector'
		in: (data at: #senders).
	self
		entryForReference:
		'MCPToolSendersTestExact class>>sendExistingClassNamedSelector'
		in: (data at: #senders)
]

{ #category : 'tests' }
MCPToolSendersTest >> testClassesScopeLimitsToExactClasses [

	| data result |
	result := self callToolWith: {
			          (#selector -> 'hierarchyTarget').
			          (#mode -> 'method').
			          (#scope -> 'classes').
			          (#classNames -> #( 'MCPToolSendersTestChild' )) }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #mode) equals: 'method'.
	self assert: (data at: #totalCount) equals: 1.
	self
		assert: (data at: #classNames) asArray
		equals: #( 'MCPToolSendersTestChild' ).
	self
		entryForReference: 'MCPToolSendersTestChild>>childHierarchySender'
		in: (data at: #senders)
]

{ #category : 'tests' }
MCPToolSendersTest >> testFilterCanNarrowResultsPaginateAndIncludeSource [

	| data result sender |
	result := self callToolWith: {
			          (#selector -> 'sharedTarget').
			          (#mode -> 'method').
			          (#filter -> ' class>>').
			          (#includeSource -> true).
			          (#limit -> 1) } asDictionary.
	data := self dataFrom: result.
	sender := self
		          entryForReference:
		          'MCPToolSendersTestExact class>>classSendShared'
		          in: (data at: #senders).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #mode) equals: 'method'.
	self assert: (data at: #totalCount) equals: 1.
	self assert: (data at: #returnedCount) equals: 1.
	self deny: (data at: #truncated).
	self assert:
		((sender at: #source) includesSubstring: 'self sharedTarget').
	self deny:
		((sender at: #source) includesSubstring: String cr asString).
	self deny:
		((sender at: #source) includesSubstring: String tab asString)
]

{ #category : 'tests' }
MCPToolSendersTest >> testHierarchyScopeSearchesWholeHierarchy [

	| data result |
	result := self callToolWith: {
			          (#selector -> 'hierarchyTarget').
			          (#mode -> 'method').
			          (#scope -> 'hierarchy').
			          (#classNames -> #( 'MCPToolSendersTestMid' )) }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #mode) equals: 'method'.
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference: 'MCPToolSendersTestBase>>baseHierarchySender'
		in: (data at: #senders).
	self
		entryForReference: 'MCPToolSendersTestChild>>childHierarchySender'
		in: (data at: #senders)
]

{ #category : 'tests' }
MCPToolSendersTest >> testImageScopeFindsClassReferencesWhenSelectorMatchesExistingClassName [

	| data result |
	result := self callToolWith: {
			          (#selector -> 'MCPToolSendersTestExtensionTarget').
			          (#mode -> 'class') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #mode) equals: 'class'.
	self assert: (data at: #scope) equals: 'image'.
	self assert: (data at: #totalCount) equals: 4.
	self
		entryForReference:
		'MCPToolSendersTestExact>>referenceExtensionTarget'
		in: (data at: #senders).
	self
		entryForReference:
		'MCPToolSendersTestExact class>>referenceExtensionTarget'
		in: (data at: #senders).
	self
		entryForReference:
		'MCPToolSendersTestExact>>sendExistingClassNamedSelector'
		in: (data at: #senders).
	self
		entryForReference:
		'MCPToolSendersTestExact class>>sendExistingClassNamedSelector'
		in: (data at: #senders)
]

{ #category : 'tests' }
MCPToolSendersTest >> testImageScopeFindsInstanceAndClassSenders [

	| data result |
	result := self callToolWith: {
			          (#selector -> 'sharedTarget').
			          (#mode -> 'method') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #mode) equals: 'method'.
	self assert: (data at: #scope) equals: 'image'.
	self assert: (data at: #side) equals: 'both'.
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference: 'MCPToolSendersTestExact>>instanceSendShared'
		in: (data at: #senders).
	self
		entryForReference: 'MCPToolSendersTestExact class>>classSendShared'
		in: (data at: #senders)
]

{ #category : 'tests' }
MCPToolSendersTest >> testMethodModeDoesNotIncludeClassReferences [

	| data result |
	result := self callToolWith: {
			          (#selector -> 'MCPToolSendersTestExtensionTarget').
			          (#mode -> 'method') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #mode) equals: 'method'.
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference:
		'MCPToolSendersTestExact>>sendExistingClassNamedSelector'
		in: (data at: #senders).
	self
		entryForReference:
		'MCPToolSendersTestExact class>>sendExistingClassNamedSelector'
		in: (data at: #senders)
]

{ #category : 'tests' }
MCPToolSendersTest >> testPackagesScopeIncludesExtensionMethods [

	| data result sender |
	result := self callToolWith: {
			          (#selector -> 'extensionTarget').
			          (#mode -> 'method').
			          (#scope -> 'packages').
			          (#packageNames -> #( 'MCP-Tests-Extensions' )) }
			          asDictionary.
	data := self dataFrom: result.
	sender := self
		          entryForReference:
		          'MCPToolSendersTestExtensionTarget>>extensionSender'
		          in: (data at: #senders).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #mode) equals: 'method'.
	self assert: (data at: #totalCount) equals: 1.
	self assert: (sender at: #packageName) equals: 'MCP-Tests-Extensions'.
	self assert: (sender at: #isExtension)
]

{ #category : 'tests' }
MCPToolSendersTest >> testPackagesScopeReturnsStructuredErrorWhenPackageNamesAreMissing [

	| error result structured |
	result := self callToolWith: {
			          (#selector -> 'extensionTarget').
			          (#mode -> 'method').
			          (#scope -> 'packages') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #mode) equals: 'method'.
	self assert: (error at: #scope) equals: 'packages'.
	self assert:
		((error at: #message) includesSubstring: 'packageNames is required')
]

{ #category : 'tests' }
MCPToolSendersTest >> testToolRequiresSelectorInSchema [

	self
		assert: MCPToolSenders new inputSchema required asSet
		equals: #( 'selector' 'mode' ) asSet
]

{ #category : 'tests' }
MCPToolSendersTest >> testVariableModeFindsClassSideVariableReferences [

	| data result |
	result := self callToolWith: {
			          (#selector -> 'trackedClassSlot').
			          (#mode -> 'variable').
			          (#scope -> 'classes').
			          (#side -> 'class').
			          (#classNames -> #( 'MCPToolSendersVariableTestTarget' )) }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #mode) equals: 'variable'.
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference:
		'MCPToolSendersVariableTestTarget class>>readTrackedClassSlot'
		in: (data at: #senders).
	self
		entryForReference:
		'MCPToolSendersVariableTestTarget class>>writeTrackedClassSlot'
		in: (data at: #senders)
]

{ #category : 'tests' }
MCPToolSendersTest >> testVariableModeFindsInstanceVariableReferences [

	| data result |
	result := self callToolWith: {
			          (#selector -> 'trackedSlot').
			          (#mode -> 'variable').
			          (#scope -> 'classes').
			          (#side -> 'instance').
			          (#classNames -> #( 'MCPToolSendersVariableTestTarget' )) }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #mode) equals: 'variable'.
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference:
		'MCPToolSendersVariableTestTarget>>readTrackedSlot'
		in: (data at: #senders).
	self
		entryForReference:
		'MCPToolSendersVariableTestTarget>>writeTrackedSlot'
		in: (data at: #senders)
]

{ #category : 'tests' }
MCPToolSendersTest >> testVariableModeReturnsStructuredErrorWhenVariableIsMissing [

	| error result structured |
	result := self callToolWith: {
			          (#selector -> 'missingTrackedSlot').
			          (#mode -> 'variable').
			          (#scope -> 'classes').
			          (#classNames -> #( 'MCPToolSendersVariableTestTarget' )) }
			          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #mode) equals: 'variable'.
	self assert: ((error at: #message) includesSubstring:
			 'No variable named missingTrackedSlot')
]
