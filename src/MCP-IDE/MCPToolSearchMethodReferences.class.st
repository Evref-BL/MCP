"
Concrete method_reference_search tool. It answers where a name is used, working out from the name itself whether that means implementors and senders of a selector, references to a class, or references to a variable.
"
Class {
	#name : 'MCPToolSearchMethodReferences',
	#superclass : 'MCPToolMethodLookupOperation',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolSearchMethodReferences class >> toolName [

	^ 'method_reference_search'
]

{ #category : 'private - results' }
MCPToolSearchMethodReferences >> countTextForQueryRequest: queryRequest page: page [
	"What was looked for and how much of it was found, counted over every hit rather than the page: 1 implementor and 3 senders of calcArea, 25 of 40 methods refer to EvalRect. Nothing found names the kinds that were looked for."

	| counts name offset |
	name := queryRequest filterPattern.
	page totalCount = 0 ifTrue: [ ^ self noHitTextForKinds: (self kindsForName: name request: queryRequest) name: name ].
	counts := page countsByKind.
	offset := self offsetFromQueryRequest: queryRequest.
	^ String streamContents: [ :stream |
			  offset >= page totalCount
				  ifTrue: [
						  stream
							  nextPutAll: 'No ';
							  nextPutAll: (self kindNounsTextForCounts: counts);
							  nextPutAll: ' from offset ';
							  print: offset;
							  nextPutAll: '; ' ]
				  ifFalse: [
						  (offset = 0 and: [ page nextOffset isNil ]) ifFalse: [
								  stream
									  print: page returnedCount;
									  nextPutAll: ' of ' ] ].
			  stream nextPutAll: (self hitCountTextForCounts: counts name: name) ]
]

{ #category : 'private - results' }
MCPToolSearchMethodReferences >> dataTextOn: stream for: data [
	"Hits are listed under the kind of reference they are, implementors before senders, in the order of the one list the offset counts, so a page can end inside a group."

	| groups rest |
	rest := data copy.
	rest removeKey: #methods ifAbsent: [ nil ].
	super dataTextOn: stream for: rest.
	groups := OrderedDictionary new.
	((self valueIn: data at: #methods) ifNil: [ #(  ) ]) do: [ :each |
		(groups at: (self groupLabelForKind: (self valueIn: each at: #reference)) ifAbsentPut: [ OrderedCollection new ]) add: each ].
	groups keysAndValuesDo: [ :label :entries |
			self
				entriesTextOn: stream
				for: entries asArray
				labelled: label
				indent: '' ]
]

{ #category : 'metadata' }
MCPToolSearchMethodReferences >> defaultExposure [

	^ 'static'
]

{ #category : 'metadata' }
MCPToolSearchMethodReferences >> description [

	^ 'Find senders and implementors of a selector, or methods referring to a class or variable.'
]

{ #category : 'private - lookup' }
MCPToolSearchMethodReferences >> entriesForKinds: kinds name: aName queryRequest: queryRequest [

	| entries |
	entries := OrderedCollection new.
	kinds do: [ :kind | entries addAll: (self entriesOfKind: kind forName: aName queryRequest: queryRequest) ].
	^ entries asArray
]

{ #category : 'private - lookup' }
MCPToolSearchMethodReferences >> entriesForKinds: kinds name: aName queryRequest: queryRequest ifUnknown: aBlock [
	"A reading that does not resolve is not a failure while another reading is still to be tried, so what
	it said is kept for the message that reports both."

	^ [ self entriesForKinds: kinds name: aName queryRequest: queryRequest ]
		  on: Error
		  do: [ :error | aBlock value: error ]
]

{ #category : 'private - lookup' }
MCPToolSearchMethodReferences >> entriesOfKind: aKind forName: aName queryRequest: queryRequest [

	| entries |
	entries := aKind = 'implementors'
		           ifTrue: [ self implementorEntriesForSelector: aName queryRequest: queryRequest ]
		           ifFalse: [
			           aKind = 'senders'
				           ifTrue: [ self selectorReferenceEntriesForSelector: aName queryRequest: queryRequest ]
				           ifFalse: [
					           aKind = 'class'
						           ifTrue: [ self classReferenceEntriesForClassNamed: aName queryRequest: queryRequest ]
						           ifFalse: [ self variableReferenceEntriesForVariableNamed: aName queryRequest: queryRequest ] ] ].
	^ entries collect: [ :each |
		  | entry |
		  entry := each copy.
		  entry at: #reference put: aKind.
		  entry ]
]

{ #category : 'private - schema' }
MCPToolSearchMethodReferences >> extraInputProperties [

	^ { ((self
		    schemaPropertyNamed: 'kind'
		    type: 'string'
		    description: 'Read name as this kind of thing, instead of deciding from its spelling.')
		   enum: self referenceKinds;
		   yourself) }
]

{ #category : 'private - lookup' }
MCPToolSearchMethodReferences >> fallbackKindsFor: kinds [
	"A lowercase name is read as a selector, but an instance variable looks exactly the same, so a
	selector that nothing implements or sends is tried as a variable instead, and the other way round."

	(kinds includes: 'implementors') ifTrue: [ ^ #( 'variable' ) ].
	(kinds includes: 'variable') ifTrue: [ ^ #( 'implementors' 'senders' ) ].
	^ #(  )
]

{ #category : 'private - results' }
MCPToolSearchMethodReferences >> groupLabelForKind: aKind [
	"Implementors and senders are listed under their own names; the methods referring to a class or using a variable are just methods."

	^ (self selectorKinds includes: aKind)
		  ifTrue: [ aKind ]
		  ifFalse: [ 'methods' ]
]

{ #category : 'private - results' }
MCPToolSearchMethodReferences >> hitCountTextForCounts: counts name: aName [
	"1 implementor and 3 senders of calcArea, 3 methods refer to EvalRect, 1 method uses total."

	^ String streamContents: [ :stream |
			  (counts includesKey: 'class')
				  ifTrue: [
						  stream
							  nextPutAll: (self textForCount: (counts at: 'class') noun: 'method');
							  nextPutAll: ((counts at: 'class') = 1
									   ifTrue: [ ' refers to ' ]
									   ifFalse: [ ' refer to ' ]) ]
				  ifFalse: [
						  (counts includesKey: 'variable')
							  ifTrue: [
									  stream
										  nextPutAll: (self textForCount: (counts at: 'variable') noun: 'method');
										  nextPutAll: ((counts at: 'variable') = 1
												   ifTrue: [ ' uses ' ]
												   ifFalse: [ ' use ' ]) ]
							  ifFalse: [
									  stream
										  nextPutAll: (' and ' join: (self selectorKinds
														    select: [ :kind | counts includesKey: kind ]
														    thenCollect: [ :kind | self textForCount: (counts at: kind) noun: kind allButLast ]));
										  nextPutAll: ' of ' ] ].
			  stream nextPutAll: aName ]
]

{ #category : 'private - results' }
MCPToolSearchMethodReferences >> kindNounsTextForCounts: counts [
	"What the hits are, without the name they are of: implementors or senders, or methods."

	| selectorKinds |
	selectorKinds := self selectorKinds select: [ :kind | counts includesKey: kind ].
	selectorKinds ifEmpty: [ ^ 'methods' ].
	^ ' or ' join: selectorKinds
]

{ #category : 'private - lookup' }
MCPToolSearchMethodReferences >> kindsForName: aName request: request [
	"A capitalised name is a class when its base name is one, so Foo class reads as references to Foo, and a variable otherwise."

	(self requestedKindIn: request) ifNotNil: [ :requested | ^ { requested } ].
	(aName includes: $:) ifTrue: [ ^ #( 'implementors' 'senders' ) ].
	aName first isLetter ifFalse: [ ^ #( 'implementors' 'senders' ) ].
	aName first isUppercase ifFalse: [ ^ #( 'implementors' 'senders' ) ].
	^ (MCPImageLookup isClassName: aName)
		  ifTrue: [ #( 'class' ) ]
		  ifFalse: [ #( 'variable' ) ]
]

{ #category : 'private - schema' }
MCPToolSearchMethodReferences >> lookupArgumentDescription [

	^ 'Selector, class name or variable name.'
]

{ #category : 'private - schema' }
MCPToolSearchMethodReferences >> lookupArgumentName [

	^ 'name'
]

{ #category : 'private - results' }
MCPToolSearchMethodReferences >> noHitHintForKinds: kinds name: aName [
	"A name that no method implements or sends may not be a selector at all: a method written with its class, or a class, read as every class name is, so Foo class names Foo. Answer the sentence that says what to ask instead, or nil."

	(self selectorKinds anySatisfy: [ :kind | kinds includes: kind ]) ifFalse: [ ^ nil ].
	(aName includesSubstring: '>>') ifTrue: [
			^ String streamContents: [ :stream |
				  stream << aName << ' names a method; name its selector alone: ' << (self selectorInMethodName: aName) << '.' ] ].
	(MCPImageLookup isClassName: aName) ifFalse: [ ^ nil ].
	^ String streamContents: [ :stream |
			  stream << (MCPImageLookup baseNameOf: aName) << ((MCPImageLookup classNamed: aName) isTrait
				   ifTrue: [ ' is a trait' ]
				   ifFalse: [ ' is a class' ]) << '; kind: class finds the methods that refer to it.' ]
]

{ #category : 'private - results' }
MCPToolSearchMethodReferences >> noHitTextForKinds: kinds name: aName [
	"No senders of audit, No implementors or senders of audit, No methods refer to EvalRect, No methods use total."

	^ String streamContents: [ :stream |
			  (kinds includes: 'class')
				  ifTrue: [ stream nextPutAll: 'No methods refer to ' ]
				  ifFalse: [
						  (kinds includes: 'variable')
							  ifTrue: [ stream nextPutAll: 'No methods use ' ]
							  ifFalse: [
									  stream
										  nextPutAll: 'No ';
										  nextPutAll: (' or ' join: (self selectorKinds select: [ :kind | kinds includes: kind ]));
										  nextPutAll: ' of ' ] ].
			  stream nextPutAll: aName ]
]

{ #category : 'private - template' }
MCPToolSearchMethodReferences >> queryEntriesForQueryRequest: queryRequest [

	| entries fallback kinds name failures |
	name := self requiredLookupPatternFromQueryRequest: queryRequest.
	kinds := self kindsForName: name request: queryRequest.
	(self requestedKindIn: queryRequest) ifNotNil: [ ^ self entriesForKinds: kinds name: name queryRequest: queryRequest ].
	failures := OrderedCollection new.
	entries := self
		           entriesForKinds: kinds
		           name: name
		           queryRequest: queryRequest
		           ifUnknown: [ :error |
		           failures add: error.
		           nil ].
	(entries isNotNil and: [ entries isNotEmpty ]) ifTrue: [ ^ entries ].
	fallback := self
		            entriesForKinds: (self fallbackKindsFor: kinds)
		            name: name
		            queryRequest: queryRequest
		            ifUnknown: [ :error |
		            failures add: error.
		            nil ].
	(fallback isNotNil and: [ fallback isNotEmpty ]) ifTrue: [ ^ fallback ].
	failures ifNotEmpty: [ ^ self signalUnknownName: name failures: failures ].
	^ entries ifNil: [ #(  ) ]
]

{ #category : 'private - pagination' }
MCPToolSearchMethodReferences >> queryPageForEntries: entries limit: limit offset: offset [
	"The summary counts every hit of each kind, not only the page's."

	| counts |
	counts := Dictionary new.
	entries do: [ :each |
			| kind |
			kind := each at: #reference.
			counts at: kind put: (counts at: kind ifAbsent: [ 0 ]) + 1 ].
	^ (super queryPageForEntries: entries limit: limit offset: offset)
		  countsByKind: counts;
		  yourself
]

{ #category : 'private - results' }
MCPToolSearchMethodReferences >> redundantKeys [
	"Hits are listed under the kind of reference they are, and the protocol says nothing about where a name is used."

	^ super redundantKeys , #( reference protocol )
]

{ #category : 'metadata' }
MCPToolSearchMethodReferences >> referenceKinds [

	^ #( 'implementors' 'senders' 'class' 'variable' )
]

{ #category : 'private - lookup' }
MCPToolSearchMethodReferences >> requestedKindIn: queryRequest [

	^ (queryRequest fieldFilters ifNil: [ Dictionary new ]) at: 'kind' ifAbsent: [ nil ]
]

{ #category : 'private - lookup' }
MCPToolSearchMethodReferences >> searchRequestFromToolRequest: request [

	| searchRequest |
	searchRequest := super searchRequestFromToolRequest: request.
	searchRequest fieldFilters: (self fieldFiltersFromRequest: request fieldNames: #( 'kind' )).
	^ searchRequest
]

{ #category : 'private - results' }
MCPToolSearchMethodReferences >> selectorInMethodName: aName [
	"The selector a method name such as EvalCanvas>>#draw:at: carries: what follows its last >>, without a leading #."

	| selector |
	selector := (aName splitOn: '>>') last trimBoth.
	^ (selector beginsWith: '#')
		  ifTrue: [ selector allButFirst ]
		  ifFalse: [ selector ]
]

{ #category : 'private - results' }
MCPToolSearchMethodReferences >> selectorKinds [
	"The kinds a selector is looked up as, in the order their hits are listed."

	^ #( 'implementors' 'senders' )
]

{ #category : 'private - lookup' }
MCPToolSearchMethodReferences >> signalUnknownName: aName failures: failures [
	"Both readings were tried; what each of them said is kept, so a real failure underneath is not lost."

	MCPCommandError
		signalErrorCode: #ReferenceSubjectNotFound
		message: (String streamContents: [ :stream |
				 stream << 'There is no class, variable or selector named ' << aName << ' in the requested scope.' ])
		details: {
				(#name -> aName).
				(#attempted -> (failures collect: [ :each | each messageText ] as: Array)) } asDictionary
]

{ #category : 'private - results' }
MCPToolSearchMethodReferences >> successSummaryForQueryRequest: queryRequest page: page [
	"When nothing implements or sends the name, a sentence follows when the name says what was meant instead."

	| hint name summary |
	summary := super successSummaryForQueryRequest: queryRequest page: page.
	page totalCount = 0 ifFalse: [ ^ summary ].
	name := queryRequest filterPattern.
	hint := (self noHitHintForKinds: (self kindsForName: name request: queryRequest) name: name) ifNil: [ ^ summary ].
	^ String streamContents: [ :stream | stream << summary << ' ' << hint ]
]

{ #category : 'metadata' }
MCPToolSearchMethodReferences >> title [

	^ 'Search Method References'
]
