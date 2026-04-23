Class {
	#name : 'MCPToolReferencesTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolReferencesTest >> entryForReference: aReference in: senders [

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
		  ifNone: [ self fail: 'Missing reference ' , aReference ]
]

{ #category : 'tests' }
MCPToolReferencesTest >> testClassesScopeFindsClassReferencesForExactClasses [

	| data result |
	result := self callToolWith: {
			          (#target -> 'MCPToolReferencesTestExtensionTarget').
			          (#mode -> 'class').
			          (#scope -> 'classes').
			          (#classNames -> #( 'MCPToolReferencesTestExact' )) }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 4.
	self
		entryForReference:
		'MCPToolReferencesTestExact>>referenceExtensionTarget'
		in: (data at: #references).
	self
		entryForReference:
		'MCPToolReferencesTestExact class>>referenceExtensionTarget'
		in: (data at: #references).
	self
		entryForReference:
		'MCPToolReferencesTestExact>>sendExistingClassNamedSelector'
		in: (data at: #references).
	self
		entryForReference:
		'MCPToolReferencesTestExact class>>sendExistingClassNamedSelector'
		in: (data at: #references)
]

{ #category : 'tests' }
MCPToolReferencesTest >> testClassesScopeLimitsToExactClasses [

	| data result |
	result := self callToolWith: {
			          (#target -> 'hierarchyTarget').
			          (#mode -> 'method').
			          (#scope -> 'classes').
			          (#classNames -> #( 'MCPToolHierarchyTestChild' )) }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		entryForReference: 'MCPToolHierarchyTestChild>>childHierarchySender'
		in: (data at: #references)
]

{ #category : 'tests' }
MCPToolReferencesTest >> testFilterCanNarrowResultsPaginateAndIncludeSource [

	| data result sender |
	result := self callToolWith: {
			          (#target -> 'sharedTarget').
			          (#mode -> 'method').
			          (#filter -> ' class>>').
			          (#includeSource -> true).
			          (#limit -> 1) } asDictionary.
	data := self dataFrom: result.
	sender := self
		          entryForReference:
		          'MCPToolReferencesTestExact class>>classSendShared'
		          in: (data at: #references).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self assert: (data at: #references) size equals: 1.
	self assert:
		((sender at: #source) includesSubstring: 'self sharedTarget').
	self assert:
		((sender at: #source) includesSubstring: String cr asString)
]

{ #category : 'tests' }
MCPToolReferencesTest >> testHierarchyScopeSearchesWholeHierarchy [

	| data result |
	result := self callToolWith: {
			          (#target -> 'hierarchyTarget').
			          (#mode -> 'method').
			          (#scope -> 'hierarchy').
			          (#classNames -> #( 'MCPToolHierarchyTestMid' )) }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference: 'MCPToolHierarchyTestBase>>baseHierarchySender'
		in: (data at: #references).
	self
		entryForReference: 'MCPToolHierarchyTestChild>>childHierarchySender'
		in: (data at: #references)
]

{ #category : 'tests' }
MCPToolReferencesTest >> testImageScopeFindsClassReferencesWhenSelectorMatchesExistingClassName [

	| data result |
	result := self callToolWith: {
			          (#target -> 'MCPToolReferencesTestExtensionTarget').
			          (#mode -> 'class') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 4.
	self
		entryForReference:
		'MCPToolReferencesTestExact>>referenceExtensionTarget'
		in: (data at: #references).
	self
		entryForReference:
		'MCPToolReferencesTestExact class>>referenceExtensionTarget'
		in: (data at: #references).
	self
		entryForReference:
		'MCPToolReferencesTestExact>>sendExistingClassNamedSelector'
		in: (data at: #references).
	self
		entryForReference:
		'MCPToolReferencesTestExact class>>sendExistingClassNamedSelector'
		in: (data at: #references)
]

{ #category : 'tests' }
MCPToolReferencesTest >> testImageScopeFindsInstanceAndClassSenders [

	| data result |
	result := self callToolWith: {
			          (#target -> 'sharedTarget').
			          (#mode -> 'method') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference: 'MCPToolReferencesTestExact>>instanceSendShared'
		in: (data at: #references).
	self
		entryForReference:
		'MCPToolReferencesTestExact class>>classSendShared'
		in: (data at: #references)
]

{ #category : 'tests' }
MCPToolReferencesTest >> testMethodModeDoesNotIncludeClassReferences [

	| data result |
	result := self callToolWith: {
			          (#target -> 'MCPToolReferencesTestExtensionTarget').
			          (#mode -> 'method') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference:
		'MCPToolReferencesTestExact>>sendExistingClassNamedSelector'
		in: (data at: #references).
	self
		entryForReference:
		'MCPToolReferencesTestExact class>>sendExistingClassNamedSelector'
		in: (data at: #references)
]

{ #category : 'tests' }
MCPToolReferencesTest >> testPackagesScopeIncludesExtensionMethods [

	| data result sender |
	result := self callToolWith: {
			          (#target -> 'extensionTarget').
			          (#mode -> 'method').
			          (#scope -> 'packages').
			          (#packageNames -> #( 'MCP-Tests-Resources-Extensions' )) }
			          asDictionary.
	data := self dataFrom: result.
	sender := self
		          entryForReference:
		          'MCPToolReferencesTestExtensionTarget>>extensionSender'
		          in: (data at: #references).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		assert: (sender at: #packageName)
		equals: 'MCP-Tests-Resources-Extensions'.
	self assert: (sender at: #isExtension)
]

{ #category : 'tests' }
MCPToolReferencesTest >> testPackagesScopeReturnsStructuredErrorWhenPackageNamesAreMissing [

	| error result structured |
	result := self callToolWith: {
			          (#target -> 'extensionTarget').
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
MCPToolReferencesTest >> testToolRequiresSelectorInSchema [

	self
		assert: MCPToolReferences new inputSchema required asSet
		equals: #( 'target' 'mode' ) asSet
]

{ #category : 'tests' }
MCPToolReferencesTest >> testVariableModeFindsClassSideVariableReferences [

	| data result |
	result := self callToolWith: {
			          (#target -> 'trackedClassSlot').
			          (#mode -> 'variable').
			          (#scope -> 'classes').
			          (#side -> 'class').
			          (#classNames
			           -> #( 'MCPToolReferencesVariableTestTarget' )) }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference:
		'MCPToolReferencesVariableTestTarget class>>readTrackedClassSlot'
		in: (data at: #references).
	self
		entryForReference:
		'MCPToolReferencesVariableTestTarget class>>writeTrackedClassSlot'
		in: (data at: #references)
]

{ #category : 'tests' }
MCPToolReferencesTest >> testVariableModeFindsInstanceVariableReferences [

	| data result |
	result := self callToolWith: {
			          (#target -> 'trackedSlot').
			          (#mode -> 'variable').
			          (#scope -> 'classes').
			          (#side -> 'instance').
			          (#classNames
			           -> #( 'MCPToolReferencesVariableTestTarget' )) }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference:
		'MCPToolReferencesVariableTestTarget>>readTrackedSlot'
		in: (data at: #references).
	self
		entryForReference:
		'MCPToolReferencesVariableTestTarget>>writeTrackedSlot'
		in: (data at: #references)
]

{ #category : 'tests' }
MCPToolReferencesTest >> testVariableModeReturnsStructuredErrorWhenVariableIsMissing [

	| error result structured |
	result := self callToolWith: {
			          (#target -> 'missingTrackedSlot').
			          (#mode -> 'variable').
			          (#scope -> 'classes').
			          (#classNames -> #( 'MCPToolReferencesVariableTestTarget' )) }
			          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #mode) equals: 'variable'.
	self assert: ((error at: #message) includesSubstring:
			 'No variable named missingTrackedSlot')
]

{ #category : 'private - calling' }
MCPToolReferencesTest >> toolName [

	^ 'references'
]
