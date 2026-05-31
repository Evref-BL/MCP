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
	names := #( 'method_implementor_search' 'method_sender_search'
	            'method_class_reference_search' 'method_variable_reference_search' ).
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

{ #category : 'private' }
MCPToolFocusedMethodLookupTest >> toolNamed: aToolName dataFromArguments: arguments [

	^ self dataFrom:
		  (self callToolNamed: aToolName withArguments: arguments)
]
