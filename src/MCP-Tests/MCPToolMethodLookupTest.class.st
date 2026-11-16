"
Tests method lookup tools for senders, implementors, and references.
"
Class {
	#name : 'MCPToolMethodLookupTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolMethodLookupTest >> entryForReference: aReference in: methods [

	^ methods
		  detect: [ :each |
				  | reference |
				  reference := String streamContents: [ :stream |
						               stream nextPutAll: (each at: #class).
						               (each at: #side ifAbsent: [ 'instance' ]) = 'class' ifTrue: [ stream nextPutAll: ' class' ].
						               stream
							               nextPutAll: '>>';
							               nextPutAll: (each at: #selector) ].
				  reference = aReference ]
		  ifNone: [ self fail: 'Missing method ' , aReference ]
]

{ #category : 'private' }
MCPToolMethodLookupTest >> referenceSummaryFor: arguments [

	^ self summaryFrom: (self callToolNamed: 'method_reference_search' withArguments: arguments asDictionary)
]

{ #category : 'private' }
MCPToolMethodLookupTest >> targetClassName [

	^ MCPToolMethodSearchTestTarget name
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testAClassNameThatNamesNoClassIsSaidByTheLookup [

	| error result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#kind -> 'class').
			          (#name -> 'MCPToolMethodSearchReferenceTargt') } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: ((error at: #message) beginsWith: 'Class MCPToolMethodSearchReferenceTargt does not exist. Did you mean: ').
	self assert: ((error at: #suggestions) includes: 'MCPToolMethodSearchReferenceTarget').
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#kind -> 'class').
			          (#name -> 'Transcript') } asDictionary.
	error := self errorFrom: result.
	self assert: (error at: #errorCode) equals: 'NotAClass'.
	self assert: (error at: #message) equals: 'Transcript is a global variable, not a class.'
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testAClassSideNameAnswersReferencesToItsClass [
	"Foo class names no global of its own, so its spelling alone would read it as a variable. Its base name decides, and the references are those of Foo."

	| data references |
	data := self
		        toolNamed: 'method_reference_search'
		        dataFromArguments: { (#name -> 'MCPToolMethodSearchReferenceTarget class') } asDictionary.
	references := self
		              toolNamed: 'method_reference_search'
		              dataFromArguments: { (#name -> 'MCPToolMethodSearchReferenceTarget') } asDictionary.
	self denyEmpty: (data at: #methods).
	(data at: #methods) do: [ :each | self assert: (each at: #reference) equals: 'class' ].
	self assert: (data at: #methods) equals: (references at: #methods)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testALowercaseNameNothingUsesFindsNoImplementorsOrSenders [
	"A lowercase name reads as a selector, which any name can be, and then as a variable. When nothing implements or sends it and no variable has that name, nothing was found: the answer says so, rather than that the name is unknown."

	| result |
	result := self callToolNamed: 'method_reference_search' withArguments: { (#name -> 'mcpNoSuchSelectorAnywhere') } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
	self assert: (self summaryFrom: result) equals: 'No implementors or senders of mcpNoSuchSelectorAnywhere in the image.'
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testClassNameAnswersClassReferences [

	| data |
	data := self
		        toolNamed: 'method_reference_search'
		        dataFromArguments: { (#name -> 'MCPToolMethodSearchReferenceTarget') } asDictionary.
	(data at: #methods) do: [ :each | self assert: (each at: #reference) equals: 'class' ]
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testKindNarrowsWhatIsLookedFor [

	| data |
	data := self toolNamed: 'method_reference_search' dataFromArguments: {
		        (#kind -> 'implementors').
		        (#name -> 'sharedTarget') } asDictionary.
	(data at: #methods) do: [ :each | self assert: (each at: #reference) equals: 'implementors' ]
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testLookupSchemasRequireDedicatedArguments [

	| commonProperties expectations |
	commonProperties := #( 'scope' 'offset' ).
	expectations := {
		                (MCPToolSearchMethodReferences -> #( 'name' 'kind' )).
		                (MCPToolSearchEquivalentMethods -> #( 'class' 'selector' 'side' )) }.
	expectations do: [ :expectation |
			| propertyNames schema |
			schema := expectation key new inputSchema.
			propertyNames := schema properties collect: [ :each | each name ].
			self assert: propertyNames asSet equals: (commonProperties , expectation value) asSet ]
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testLookupToolsArePublicStaticReadTools [

	| discoverableNames staticNames |
	staticNames := #( 'method_source_search' 'method_reference_search' ).
	discoverableNames := #( 'method_equivalent_search' ).
	staticNames do: [ :each |
			| tool |
			self assert: (self toolRegistry toolNames includes: each).
			self assert: (self toolRegistry advertisedToolNames includes: each).
			tool := self toolRegistry toolNamed: each ifAbsent: [ self fail: 'Missing tool ' , each ].
			self assert: tool defaultExposure equals: 'static'.
			self assert: tool annotations readOnlyHint ].
	discoverableNames do: [ :each |
			| tool |
			self assert: (self toolRegistry toolNames includes: each).
			self deny: (self toolRegistry advertisedToolNames includes: each).
			tool := self toolRegistry toolNamed: each ifAbsent: [ self fail: 'Missing tool ' , each ].
			self assert: tool defaultExposure equals: 'discoverable'.
			self assert: tool annotations readOnlyHint ]
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testMethodSourceSearchSearchesSourceText [

	| data result |
	result := self callToolNamed: 'method_source_search' withArguments: {
			          (self searchScope: { (#classes -> { self targetClassName }) }).
			          (#filter -> 'gamma value') } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	data := self dataFrom: result.
	self assert: (data at: #methods) size equals: 1.
	self assert: ((data at: #methods) first at: #selector) equals: 'gammaUtility'.
	self deny: ((data at: #methods) first includesKey: #source)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testNoHitsForAClassPointToKindClass [
	"A class or trait name finds no implementor or sender; the answer says that kind class finds what refers to it. The name is read as every class name is, so Foo class names Foo."

	self
		assert: (self referenceSummaryFor: {
					 (#name -> 'MCPToolMethodSearchReferenceFixture').
					 (#kind -> 'senders') })
		equals:
		'No senders of MCPToolMethodSearchReferenceFixture in the image. MCPToolMethodSearchReferenceFixture is a class; kind: class finds the methods that refer to it.'.
	self
		assert: (self referenceSummaryFor: {
					 (#name -> 'TMCPToolMethodSearchFixture').
					 (#kind -> 'implementors') })
		equals:
		'No implementors of TMCPToolMethodSearchFixture in the image. TMCPToolMethodSearchFixture is a trait; kind: class finds the methods that refer to it.'.
	self
		assert: (self referenceSummaryFor: {
					 (#name -> 'MCPToolMethodSearchReferenceFixture class').
					 (#kind -> 'senders') })
		equals:
		'No senders of MCPToolMethodSearchReferenceFixture class in the image. MCPToolMethodSearchReferenceFixture is a class; kind: class finds the methods that refer to it.'
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testNoHitsForAMethodNameTheSelector [
	"A method written with its class finds no sender; the answer names the selector to ask for instead."

	self
		assert: (self referenceSummaryFor: {
					 (#name -> 'MCPToolMethodSearchReferenceFixture>>#sharedTarget').
					 (#kind -> 'senders') })
		equals:
		'No senders of MCPToolMethodSearchReferenceFixture>>#sharedTarget in the image. MCPToolMethodSearchReferenceFixture>>#sharedTarget names a method; name its selector alone: sharedTarget.'
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testNoHitsSayWhatWasLookedFor [
	"Nothing found names the kinds that were looked for and the name."

	self
		assert: (self referenceSummaryFor: {
					 (#name -> 'mcpNoSuchSelectorAnywhere').
					 (#kind -> 'senders') })
		equals: 'No senders of mcpNoSuchSelectorAnywhere in the image.'.
	self
		assert: (self referenceSummaryFor: {
					 (#name -> 'trackedSlot').
					 (#kind -> 'implementors') })
		equals: 'No implementors of trackedSlot in the image.'.
	self
		assert: (self referenceSummaryFor: {
					 (#name -> 'MCPToolMethodSearchReferenceTarget').
					 (#kind -> 'class').
					 (self searchScope: { (#classes -> #( 'MCPToolMethodSearchVariableReferenceTarget' )) }) })
		equals: 'No methods refer to MCPToolMethodSearchReferenceTarget in MCPToolMethodSearchVariableReferenceTarget.'
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSearchClassReferencesReturnsClassBindingReferences [

	| data |
	data := self
		        toolNamed: 'method_reference_search'
		        dataFromArguments: { (#name -> 'MCPToolMethodSearchReferenceTarget') } asDictionary.
	self assert: (data at: #methods) size equals: 2.
	self entryForReference: 'MCPToolMethodSearchReferenceFixture>>referenceExtensionTarget' in: (data at: #methods).
	self entryForReference: 'MCPToolMethodSearchReferenceFixture class>>referenceExtensionTarget' in: (data at: #methods)
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
		self ensureMethodSource: methodSource protocol: 'testing' on: (self classNamed: subclassName).
		data := self toolNamed: 'method_equivalent_search' dataFromArguments: {
				        (self searchScope: { (#classes -> { subclassName }) }).
				        (#class -> 'MCPToolMethodSearchReferenceFixture').
				        (#selector -> 'sharedTarget') } asDictionary.
		self assert: (data at: #methods) size equals: 1.
		self entryForReference: subclassName , '>>sharedTarget' in: (data at: #methods) ] ensure: [ self removeClassNamed: subclassName ]
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSearchMethodImplementorsReturnsExactSelectorMatches [

	| data |
	data := self toolNamed: 'method_reference_search' dataFromArguments: {
			        (#name -> 'alphaNeedleSelector').
			        (self searchScope: { (#classes -> { self targetClassName }) }) } asDictionary.
	self assert: (data at: #methods) size equals: 1.
	self entryForReference: self targetClassName , '>>alphaNeedleSelector' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSearchMethodSendersReturnsSelectorReferences [

	| data |
	data := self toolNamed: 'method_reference_search' dataFromArguments: { (#kind -> 'senders').
			          (#name -> 'sharedTarget') } asDictionary.
	self assert: (data at: #methods) size equals: 2.
	self entryForReference: 'MCPToolMethodSearchReferenceFixture>>instanceSendShared' in: (data at: #methods).
	self entryForReference: 'MCPToolMethodSearchReferenceFixture class>>classSendShared' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSearchVariableReferencesReturnsVariableReferences [

	| data |
	data := self toolNamed: 'method_reference_search' dataFromArguments: {
			        (#name -> 'trackedSlot').
			        (self searchScope: { (#classes -> #( 'MCPToolMethodSearchVariableReferenceTarget' )) } side: 'instance') } asDictionary.
	self assert: (data at: #methods) size equals: 2.
	self entryForReference: 'MCPToolMethodSearchVariableReferenceTarget>>readTrackedSlot' in: (data at: #methods).
	self entryForReference: 'MCPToolMethodSearchVariableReferenceTarget>>writeTrackedSlot' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSelectorNameAnswersImplementorsAndSendersLabelled [

	| data kinds |
	data := self toolNamed: 'method_reference_search' dataFromArguments: { (#name -> 'sharedTarget') } asDictionary.
	kinds := (data at: #methods) collect: [ :each | each at: #reference ] as: Set.
	self assert: kinds equals: #( 'implementors' 'senders' ) asSet
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSourceAndEquivalentSearchSchemasUseDedicatedInputs [

	| equivalentPropertyNames equivalentRequired equivalentSchema filterModeProperty sourcePropertyNames sourceRequired sourceSchema |
	sourceSchema := MCPToolSearchMethodSource new inputSchema.
	sourceRequired := sourceSchema required asArray.
	sourcePropertyNames := sourceSchema properties collect: [ :each | each name ].
	filterModeProperty := sourceSchema properties detect: [ :each | each name = 'filterMode' ].
	self assert: sourceRequired equals: #( 'filter' ).
	self
		assert: sourcePropertyNames asSet
		equals: #( 'scope' 'filter' 'filterMode' 'offset' ) asSet.
	self assert: (filterModeProperty extraProperties at: #enum) asArray equals: #( 'substring' 'regex' ).
	equivalentSchema := MCPToolSearchEquivalentMethods new inputSchema.
	equivalentRequired := equivalentSchema required asArray.
	equivalentPropertyNames := equivalentSchema properties collect: [ :each | each name ].
	self assert: equivalentRequired equals: #( 'class' 'selector' ).
	self
		assert: equivalentPropertyNames asSet
		equals: #( 'scope' 'selector' 'side' 'class' 'offset' ) asSet
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSummaryNamesTheKindAndTheName [
	"The summary says what was looked for and counts every hit of each kind, not only the page."

	| pagedSummary |
	self
		assert: (self referenceSummaryFor: { (#name -> 'sharedTarget') })
		equals: '2 implementors and 2 senders of sharedTarget in the image.'.
	self
		assert: (self referenceSummaryFor: {
					 (#name -> 'sharedTarget').
					 (#kind -> 'senders') })
		equals: '2 senders of sharedTarget in the image.'.
	self
		assert: (self referenceSummaryFor: { (#name -> 'MCPToolMethodSearchReferenceTarget') })
		equals: '2 methods refer to MCPToolMethodSearchReferenceTarget in the image.'.
	self
		assert: (self referenceSummaryFor: {
					 (#name -> 'trackedSlot').
					 (self searchScope: { (#classes -> #( 'MCPToolMethodSearchVariableReferenceTarget' )) } side: 'instance') })
		equals: '2 methods use trackedSlot in MCPToolMethodSearchVariableReferenceTarget, instance side.'.
	self
		assert: (self referenceSummaryFor: {
					 (#name -> 'sharedTarget').
					 (#offset -> 30) })
		equals: 'No implementors or senders from offset 30; 2 implementors and 2 senders of sharedTarget in the image.'.
	pagedSummary := self referenceSummaryFor: {
			                (#name -> 'printString').
			                (#kind -> 'senders') }.
	self assert: (pagedSummary beginsWith: '25 of ').
	self assert: (pagedSummary endsWith: ' senders of printString in the image. Next page: offset 25, or narrow the search.')
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testTextGroupsHitsByKind [
	"Hits read under the kind of reference they are, so no row repeats it; the data keeps reference on each entry."

	| contentText lines result |
	result := self callToolNamed: 'method_reference_search' withArguments: { (#name -> 'sharedTarget') } asDictionary.
	contentText := (result at: #content) first at: #text.
	lines := contentText lines.
	self assert: (lines at: 2) equals: 'implementors (each package=MCP-Tests-Resources):'.
	self
		assert: (lines copyFrom: 3 to: 4) asSet
		equals:
		#( '  MCPToolMethodSearchReferenceFixture class>>sharedTarget' '  MCPToolMethodSearchReferenceFixture>>sharedTarget' ) asSet.
	self assert: (lines at: 5) equals: 'senders (each package=MCP-Tests-Resources):'.
	self
		assert: (lines copyFrom: 6 to: 7) asSet
		equals:
			#( '  MCPToolMethodSearchReferenceFixture class>>classSendShared'
			   '  MCPToolMethodSearchReferenceFixture>>instanceSendShared' ) asSet.
	self deny: (contentText includesSubstring: 'reference=').
	self deny: (contentText includesSubstring: 'protocol=').
	self assert: (((self dataFrom: result) at: #methods) allSatisfy: [ :each | each includesKey: #reference ])
]

{ #category : 'private' }
MCPToolMethodLookupTest >> toolNamed: aToolName dataFromArguments: arguments [

	^ self dataFrom: (self callToolNamed: aToolName withArguments: arguments)
]
