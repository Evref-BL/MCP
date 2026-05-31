Class {
	#name : 'MCPToolFocusedMethodLookupTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolFocusedMethodLookupTest >> entryForReference: aReference in: methods [

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
MCPToolFocusedMethodLookupTest >> targetClassName [

	^ 'MCPToolFindMethodsTestTarget'
]

{ #category : 'tests' }
MCPToolFocusedMethodLookupTest >> testFindClassReferencesReturnsClassBindingReferences [

	| data |
	data := self
		        toolNamed: 'method_class_reference_search'
		        dataFromArguments:
		        { (#className -> 'MCPToolFindMethodsReferenceTarget') }
			        asDictionary.
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference:
		'MCPToolFindMethodsReferenceFixture>>referenceExtensionTarget'
		in: (data at: #methods).
	self
		entryForReference:
		'MCPToolFindMethodsReferenceFixture class>>referenceExtensionTarget'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolFocusedMethodLookupTest >> testFindEquivalentMethodsReturnsEquivalentAstMatches [

	| data methodSource subclassName |
	subclassName := 'MCPToolFocusedEquivalentFixture'.
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
		superclassName: 'MCPToolFindMethodsReferenceFixture'
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
					        (#className -> 'MCPToolFindMethodsReferenceFixture').
					        (#selector -> 'sharedTarget') } asDictionary.
		self assert: (data at: #totalCount) equals: 1.
		self
			entryForReference: subclassName , '>>sharedTarget'
			in: (data at: #methods) ] ensure: [
		self removeClassNamed: subclassName ]
]

{ #category : 'tests' }
MCPToolFocusedMethodLookupTest >> testFindMethodImplementorsReturnsExactSelectorMatches [

	| data |
	data := self
		        toolNamed: 'method_implementor_search'
		        dataFromArguments: {
				        (#selector -> 'alphaNeedleSelector').
				        (#classNames -> { self targetClassName }) } asDictionary.
	self assert: (data at: #totalCount) equals: 1.
	self
		entryForReference: self targetClassName , '>>alphaNeedleSelector'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolFocusedMethodLookupTest >> testFindMethodSendersReturnsSelectorReferences [

	| data |
	data := self
		        toolNamed: 'method_sender_search'
		        dataFromArguments:
		        { (#selector -> 'sharedTarget') } asDictionary.
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference:
		'MCPToolFindMethodsReferenceFixture>>instanceSendShared'
		in: (data at: #methods).
	self
		entryForReference:
		'MCPToolFindMethodsReferenceFixture class>>classSendShared'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolFocusedMethodLookupTest >> testFindMethodSourceSearchesSourceText [

	| data result |
	result := self
		          callToolNamed: 'method_source_search'
		          withArguments: {
				          (#classNames -> { self targetClassName }).
				          (#filter -> 'gamma value') } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	data := self dataFrom: result.
	self assert: (data at: #totalCount) equals: 1.
	self
		assert: ((data at: #methods) first at: #selector)
		equals: 'gammaUtility'.
	self deny: ((data at: #methods) first includesKey: #source)
]

{ #category : 'tests' }
MCPToolFocusedMethodLookupTest >> testFindVariableReferencesReturnsVariableReferences [

	| data |
	data := self
		        toolNamed: 'method_variable_reference_search'
		        dataFromArguments: {
				        (#variableName -> 'trackedSlot').
				        (#side -> 'instance').
				        (#classNames
				         -> #( 'MCPToolFindMethodsVariableReferenceTarget' )) }
				        asDictionary.
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference:
		'MCPToolFindMethodsVariableReferenceTarget>>readTrackedSlot'
		in: (data at: #methods).
	self
		entryForReference:
		'MCPToolFindMethodsVariableReferenceTarget>>writeTrackedSlot'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolFocusedMethodLookupTest >> testFocusedLookupSchemasRequireFocusedArguments [

	| expectations |
	expectations := {
		                (MCPToolFindMethodImplementors -> 'selector').
		                (MCPToolFindMethodSenders -> 'selector').
		                (MCPToolFindClassReferences -> 'className').
		                (MCPToolFindVariableReferences -> 'variableName') }.
	expectations do: [ :expectation |
			| propertyNames required schema |
			schema := expectation key new inputSchema.
			required := schema required asArray.
			propertyNames := schema properties collect: [ :each | each name ].
			self assert: required equals: { expectation value }.
			self assert: (propertyNames includes: expectation value).
			self assert: (propertyNames includes: 'includeSource').
			self assert: (propertyNames includes: 'where').
			self deny: (propertyNames includes: 'filter').
			self deny: (propertyNames includes: 'filterMode').
			self deny: (propertyNames includes: 'filterTargets') ]
]

{ #category : 'tests' }
MCPToolFocusedMethodLookupTest >> testFocusedLookupToolsArePublicStaticReadTools [

	| names |
	names := #( 'method_source_search' 'method_equivalent_search'
	            'method_implementor_search' 'method_sender_search'
	            'method_class_reference_search'
	            'method_variable_reference_search' ).
	names do: [ :each |
			| tool |
			self assert: (MCPToolRegistry publicToolNames includes: each).
			self assert: (MCPToolRegistry staticToolNames includes: each).
			tool := MCPToolRegistry
				        toolNamed: each
				        ifAbsent: [ self fail: 'Missing tool ' , each ].
			self
				assert: (MCPToolRegistry mutabilityForTool: tool)
				equals: 'read'.
			self assert: (MCPToolRegistry riskForTool: tool) equals: 'low' ]
]

{ #category : 'tests' }
MCPToolFocusedMethodLookupTest >> testSourceAndEquivalentSearchSchemasAreFocused [

	| equivalentPropertyNames equivalentRequired equivalentSchema sourcePropertyNames sourceRequired sourceSchema |
	sourceSchema := MCPToolFindMethodSource new inputSchema.
	sourceRequired := sourceSchema required asArray.
	sourcePropertyNames := sourceSchema properties collect: [ :each |
		                       each name ].
	self assert: sourceRequired equals: #( 'filter' ).
	self assert: (sourcePropertyNames includes: 'filter').
	self assert: (sourcePropertyNames includes: 'filterMode').
	self assert: (sourcePropertyNames includes: 'includeSource').
	self deny: (sourcePropertyNames includes: 'where').
	self deny: (sourcePropertyNames includes: 'filterTargets').

	equivalentSchema := MCPToolFindEquivalentMethods new inputSchema.
	equivalentRequired := equivalentSchema required asArray.
	equivalentPropertyNames := equivalentSchema properties collect: [
		                           :each | each name ].
	self assert: equivalentRequired equals: #( 'className' 'selector' ).
	self assert: (equivalentPropertyNames includes: 'className').
	self assert: (equivalentPropertyNames includes: 'selector').
	self assert: (equivalentPropertyNames includes: 'classSide').
	self assert: (equivalentPropertyNames includes: 'includeSource').
	self deny: (equivalentPropertyNames includes: 'where').
	self deny: (equivalentPropertyNames includes: 'filter').
	self deny: (equivalentPropertyNames includes: 'filterMode').
	self deny: (equivalentPropertyNames includes: 'filterTargets')
]

{ #category : 'private' }
MCPToolFocusedMethodLookupTest >> toolNamed: aToolName dataFromArguments: arguments [

	^ self dataFrom:
		  (self callToolNamed: aToolName withArguments: arguments)
]
