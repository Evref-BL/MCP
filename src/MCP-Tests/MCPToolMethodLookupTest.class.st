"
Tests method lookup tools for senders, implementors, and references.
"
Class {
	#name : 'MCPToolMethodLookupTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolMethodLookupTest >> entryForReference: aReference in: methods [

	^ methods
		  detect: [ :each |
				  | reference |
				  reference := String streamContents: [ :stream |
						               stream nextPutAll: (each at: #className).
						               (each at: #classSide) ifTrue: [
							               stream nextPutAll: ' class' ].
						               stream
							               nextPutAll: '>>';
							               nextPutAll: (each at: #selector) ].
				  reference = aReference ]
		  ifNone: [ self fail: 'Missing method ' , aReference ]
]

{ #category : 'private' }
MCPToolMethodLookupTest >> targetClassName [

	^ 'MCPToolMethodSearchTestTarget'
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testLookupSchemasRequireDedicatedArguments [

	| commonProperties expectations |
	commonProperties := #( 'classNames' 'hierarchyClassNames'
	                       'parentClassNames' 'side' 'includeSource'
	                       'packageNames' 'subclassClassNames'
	                       'limit' 'offset' ).
	expectations := {
		                (MCPToolSearchMethodImplementors -> 'selector').
		                (MCPToolSearchMethodSenders -> 'selector').
		                (MCPToolSearchClassReferences -> 'className').
		                (MCPToolSearchVariableReferences -> 'variableName') }.
	expectations do: [ :expectation |
			| propertyNames required schema |
			schema := expectation key new inputSchema.
			required := schema required asArray.
			propertyNames := schema properties collect: [ :each | each name ].
			self assert: required equals: { expectation value }.
			self
				assert: propertyNames asSet
				equals: (commonProperties , { expectation value }) asSet ]
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testLookupToolsArePublicStaticReadTools [

	| discoverableNames staticNames |
	staticNames := #( 'method_source_search' 'method_implementor_search'
	                  'method_sender_search' ).
	discoverableNames := #( 'method_equivalent_search'
	                        'method_class_reference_search'
	                        'method_variable_reference_search' ).
	staticNames do: [ :each |
			| tool |
			self assert: (MCPToolRegistry publicToolNames includes: each).
			self assert: (MCPToolRegistry staticToolNames includes: each).
			tool := MCPToolRegistry
				        toolNamed: each
				        ifAbsent: [ self fail: 'Missing tool ' , each ].
			self
				assert: (MCPToolRegistry exposureForTool: tool)
				equals: 'static'.
			self
				assert: (MCPToolRegistry mutabilityForTool: tool)
				equals: 'read'.
			self assert: (MCPToolRegistry riskForTool: tool) equals: 'low' ].
	discoverableNames do: [ :each |
			| tool |
			self assert: (MCPToolRegistry publicToolNames includes: each).
			self deny: (MCPToolRegistry staticToolNames includes: each).
			tool := MCPToolRegistry
				        toolNamed: each
				        ifAbsent: [ self fail: 'Missing tool ' , each ].
			self
				assert: (MCPToolRegistry exposureForTool: tool)
				equals: 'discoverable'.
			self
				assert: (MCPToolRegistry mutabilityForTool: tool)
				equals: 'read'.
			self assert: (MCPToolRegistry riskForTool: tool) equals: 'low' ]
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testMethodSourceSearchSearchesSourceText [

	| data result |
	result := self
		          callToolNamed: 'method_source_search'
		          withArguments: {
				          (#classNames -> { self targetClassName }).
				          (#filter -> 'gamma value') } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	data := self dataFrom: result.
	self assert: (data at: #methods) size equals: 1.
	self
		assert: ((data at: #methods) first at: #selector)
		equals: 'gammaUtility'.
	self deny: ((data at: #methods) first includesKey: #source)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSearchClassReferencesReturnsClassBindingReferences [

	| data |
	data := self
		        toolNamed: 'method_class_reference_search'
		        dataFromArguments:
		        { (#className -> 'MCPToolMethodSearchReferenceTarget') }
			        asDictionary.
	self assert: (data at: #methods) size equals: 2.
	self
		entryForReference:
		'MCPToolMethodSearchReferenceFixture>>referenceExtensionTarget'
		in: (data at: #methods).
	self
		entryForReference:
		'MCPToolMethodSearchReferenceFixture class>>referenceExtensionTarget'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSearchEquivalentMethodsReturnsEquivalentAstMatches [

	| data methodSource subclassName |
	subclassName := 'MCPToolEquivalentSearchFixture'.
	methodSource := String streamContents: [ :stream |
			                stream
				                nextPutAll: 'sharedTarget';
				                cr;
				                cr;
				                tab;
				                nextPutAll: '^ ''instance-target''' ].
	self removeClassNamed: subclassName.
	self
		createClassNamed: subclassName
		superclassName: 'MCPToolMethodSearchReferenceFixture'
		slots: #(  )
		classSlots: #(  ).
	[
		self
			ensureMethodSource: methodSource
			protocol: 'testing'
			on: (self classNamed: subclassName).
		data := self
			        toolNamed: 'method_equivalent_search'
			        dataFromArguments: {
					        (#classNames -> { subclassName }).
					        (#className -> 'MCPToolMethodSearchReferenceFixture').
					        (#selector -> 'sharedTarget') } asDictionary.
		self assert: (data at: #methods) size equals: 1.
		self
			entryForReference: subclassName , '>>sharedTarget'
			in: (data at: #methods) ] ensure: [
		self removeClassNamed: subclassName ]
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSearchMethodImplementorsReturnsExactSelectorMatches [

	| data |
	data := self
		        toolNamed: 'method_implementor_search'
		        dataFromArguments: {
				        (#selector -> 'alphaNeedleSelector').
				        (#classNames -> { self targetClassName }) } asDictionary.
	self assert: (data at: #methods) size equals: 1.
	self
		entryForReference: self targetClassName , '>>alphaNeedleSelector'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSearchMethodSendersReturnsSelectorReferences [

	| data |
	data := self
		        toolNamed: 'method_sender_search'
		        dataFromArguments:
		        { (#selector -> 'sharedTarget') } asDictionary.
	self assert: (data at: #methods) size equals: 2.
	self
		entryForReference:
		'MCPToolMethodSearchReferenceFixture>>instanceSendShared'
		in: (data at: #methods).
	self
		entryForReference:
		'MCPToolMethodSearchReferenceFixture class>>classSendShared'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSearchVariableReferencesReturnsVariableReferences [

	| data |
	data := self
		        toolNamed: 'method_variable_reference_search'
		        dataFromArguments: {
				        (#variableName -> 'trackedSlot').
				        (#side -> 'instance').
				        (#classNames
				         -> #( 'MCPToolMethodSearchVariableReferenceTarget' )) }
				        asDictionary.
	self assert: (data at: #methods) size equals: 2.
	self
		entryForReference:
		'MCPToolMethodSearchVariableReferenceTarget>>readTrackedSlot'
		in: (data at: #methods).
	self
		entryForReference:
		'MCPToolMethodSearchVariableReferenceTarget>>writeTrackedSlot'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSourceAndEquivalentSearchSchemasUseDedicatedInputs [

	| equivalentPropertyNames equivalentRequired equivalentSchema sourcePropertyNames sourceRequired sourceSchema |
	sourceSchema := MCPToolSearchMethodSource new inputSchema.
	sourceRequired := sourceSchema required asArray.
	sourcePropertyNames := sourceSchema properties collect: [ :each |
		                       each name ].
	self assert: sourceRequired equals: #( 'filter' ).
	self
		assert: sourcePropertyNames asSet
		equals: #( 'caseSensitive' 'classNames' 'hierarchyClassNames'
			   'parentClassNames' 'side' 'includeSource' 'filter' 'packageNames'
			   'filterMode' 'subclassClassNames' 'limit' 'offset' ) asSet.

	equivalentSchema := MCPToolSearchEquivalentMethods new inputSchema.
	equivalentRequired := equivalentSchema required asArray.
	equivalentPropertyNames := equivalentSchema properties collect: [
		                           :each | each name ].
	self assert: equivalentRequired equals: #( 'className' 'selector' ).
	self
		assert: equivalentPropertyNames asSet
		equals:
			#( 'classNames' 'hierarchyClassNames' 'classSide' 'selector'
			   'parentClassNames' 'side' 'className' 'includeSource'
			   'packageNames' 'subclassClassNames' 'limit' 'offset' ) asSet
]

{ #category : 'private' }
MCPToolMethodLookupTest >> toolNamed: aToolName dataFromArguments: arguments [

	^ self dataFrom:
		  (self callToolNamed: aToolName withArguments: arguments)
]
