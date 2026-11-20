"
It works out from the name itself whether the name means implementors and senders of a selector, references to a class, or references to a variable.
"
Class {
	#name : 'MCPToolSearchMethodReferences',
	#superclass : 'MCPToolMethodSearch',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolSearchMethodReferences class >> toolName [

	^ 'method_reference_search'
]

{ #category : 'metadata' }
MCPToolSearchMethodReferences >> buildInputSchema [

	^ MCPStructureInputSchema
		  properties: self methodQueryScopeInputProperties , {
				  (self filterSchemaPropertyWithDescription: 'Selector, class name or variable name.').
				  (self
					   stringEnumSchemaPropertyNamed: 'kind'
					   description: 'Read query as this kind of thing, instead of deciding from its spelling.'
					   values: self referenceKinds).
				  self offsetInputProperty }
		  required: #( 'query' )
]

{ #category : 'private - methods' }
MCPToolSearchMethodReferences >> classReferenceEntriesForClassNamed: className scopeQuery: scopeQuery [
	"The class is looked up before the scope's methods are collected, so a missing one is said at once."

	| query |
	query := MCPClassReferenceQuery forClass: (MCPImageLookup classNamed: className).
	^ self methodEntriesFromMethods: (query methodsReferringIn: scopeQuery collectedMethods)
]

{ #category : 'private - results' }
MCPToolSearchMethodReferences >> countTextForRequest: request page: page [
	"What was looked for and how much of it was found, counted over every hit rather than the page: 1 implementor and 3 senders of dailyRation, 25 of 40 methods refer to ZooLion. Nothing found names the kinds that were looked for."

	| counts name |
	name := self filterPatternFromRequest: request.
	page totalCount = 0 ifTrue: [ ^ self noHitTextForKinds: (self kindsForName: name fromRequest: request) name: name ].
	counts := page countsByKind.
	^ String streamContents: [ :stream |
			  self
				  pagePrefixOn: stream
				  page: page
				  offset: (request integerArgumentOrDefaultNamed: 'offset')
				  nouns: (self kindNounsTextForCounts: counts).
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
MCPToolSearchMethodReferences >> entriesForKinds: kinds name: aName scopeQuery: scopeQuery [

	| entries |
	entries := OrderedCollection new.
	kinds do: [ :kind | entries addAll: (self entriesOfKind: kind forName: aName scopeQuery: scopeQuery) ].
	^ entries asArray
]

{ #category : 'private - lookup' }
MCPToolSearchMethodReferences >> entriesForKinds: kinds name: aName scopeQuery: scopeQuery ifUnknown: aBlock [
	"A reading that does not resolve is not a failure while another reading is still to be tried, so what
	it said is kept for the message that reports both."

	^ [ self entriesForKinds: kinds name: aName scopeQuery: scopeQuery ]
		  on: Error
		  do: [ :error | aBlock value: error ]
]

{ #category : 'private - lookup' }
MCPToolSearchMethodReferences >> entriesOfKind: aKind forName: aName scopeQuery: scopeQuery [

	| entries |
	entries := aKind = 'implementors'
		           ifTrue: [ self implementorEntriesForSelector: aName scopeQuery: scopeQuery ]
		           ifFalse: [
				           aKind = 'senders'
					           ifTrue: [ self selectorReferenceEntriesForSelector: aName scopeQuery: scopeQuery ]
					           ifFalse: [
							           aKind = 'class'
								           ifTrue: [ self classReferenceEntriesForClassNamed: aName scopeQuery: scopeQuery ]
								           ifFalse: [ self variableReferenceEntriesForVariableNamed: aName scopeQuery: scopeQuery ] ] ].
	^ entries collect: [ :each |
			  | entry |
			  entry := each copy.
			  entry at: #reference put: aKind.
			  entry ]
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
	"1 implementor and 3 senders of dailyRation, 3 methods refer to ZooLion, 1 method uses weight."

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

{ #category : 'private - methods' }
MCPToolSearchMethodReferences >> implementorEntriesForSelector: selectorString scopeQuery: scopeQuery [

	^ self methodEntriesFromMethods: (self implementorMethodsForSelector: selectorString asSymbol scopeQuery: scopeQuery)
]

{ #category : 'private - methods' }
MCPToolSearchMethodReferences >> implementorMethodsForSelector: selectorSymbol scopeQuery: scopeQuery [

	| methods |
	scopeQuery packageNames ifNotEmpty: [
		^ (scopeQuery collectedMethods select: [ :eachMethod | eachMethod selector = selectorSymbol ]) asArray ].
	methods := OrderedCollection new.
	scopeQuery behaviors do: [ :eachBehavior |
			(eachBehavior includesSelector: selectorSymbol) ifTrue: [
					| method |
					method := eachBehavior >> selectorSymbol.
					(scopeQuery isInstalledFromTraitedClass: method) ifFalse: [ methods add: method ] ] ].
	^ methods asArray
]

{ #category : 'private - lookup' }
MCPToolSearchMethodReferences >> isSelectorName: aName [
	"Whether aName can be a selector, as audit, at:put: and + can, and #audit, self audit and audit.total cannot."

	^ aName numArgs >= 0
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
MCPToolSearchMethodReferences >> kindsForName: aName fromRequest: request [
	"A capitalised name is a class when its base name is one, so Foo class reads as references to Foo, and a variable otherwise."

	(self requestedKindFromRequest: request) ifNotNil: [ :requested | ^ { requested } ].
	(aName includes: $:) ifTrue: [ ^ #( 'implementors' 'senders' ) ].
	aName first isLetter ifFalse: [ ^ #( 'implementors' 'senders' ) ].
	aName first isUppercase ifFalse: [ ^ #( 'implementors' 'senders' ) ].
	^ (MCPImageLookup isClassName: aName)
		  ifTrue: [ #( 'class' ) ]
		  ifFalse: [ #( 'variable' ) ]
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
	"No senders of feed, No implementors or senders of feed, No methods refer to ZooLion, No methods use weight."

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

{ #category : 'private - searching' }
MCPToolSearchMethodReferences >> noVariableMessageFor: aVariableName [

	^ String streamContents: [ :stream | stream << 'No variable named ' << aVariableName << ' is accessible in the requested scope.' ]
]

{ #category : 'private - template' }
MCPToolSearchMethodReferences >> queryEntriesForRequest: request scopeQuery: scopeQuery [
	"The name is read as its spelling says, then the other way when that finds nothing. When neither finds anything and a reading failed, the name is unknown, except for a selector: a selector always resolves, so its first reading answers that nothing implements or sends it. A name that can be neither a selector nor a variable, such as #audit, is unknown before anything is swept: its reading as a variable is what fails."

	| entries fallback kinds name failures |
	name := self filterPatternFromRequest: request.
	kinds := self kindsForName: name fromRequest: request.
	(self requestedKindFromRequest: request) ifNotNil: [ ^ self entriesForKinds: kinds name: name scopeQuery: scopeQuery ].
	((kinds includes: 'class') or: [ self isSelectorName: name ]) ifFalse: [
		^ self signalUnknownName: name failures: { (Error new messageText: (self noVariableMessageFor: name)) } ].
	failures := OrderedCollection new.
	entries := self
		           entriesForKinds: kinds
		           name: name
		           scopeQuery: scopeQuery
		           ifUnknown: [ :error |
				           failures add: error.
				           nil ].
	(entries isNotNil and: [ entries isNotEmpty ]) ifTrue: [ ^ entries ].
	fallback := self
		            entriesForKinds: (self fallbackKindsFor: kinds)
		            name: name
		            scopeQuery: scopeQuery
		            ifUnknown: [ :error |
				            failures add: error.
				            nil ].
	(fallback isNotNil and: [ fallback isNotEmpty ]) ifTrue: [ ^ fallback ].
	^ (failures isEmpty or: [ entries isNotNil and: [ self isSelectorName: name ] ])
		  ifTrue: [ entries ]
		  ifFalse: [ self signalUnknownName: name failures: failures ]
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
MCPToolSearchMethodReferences >> requestedKindFromRequest: request [
	"The kind the caller asked query to be read as, or nil to decide it from its spelling."

	^ request stringArgumentNamed: 'kind'
]

{ #category : 'private - results' }
MCPToolSearchMethodReferences >> selectorInMethodName: aName [
	"The selector a method name such as ZooKeeper>>#feed:at: carries: what follows its last >>, without a leading #."

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

{ #category : 'private - methods' }
MCPToolSearchMethodReferences >> selectorReferenceEntriesForSelector: selectorString scopeQuery: scopeQuery [

	^ self methodEntriesFromMethods:
		  (self matchingSelectorReferencesForSelector: selectorString asSymbol inMethods: scopeQuery collectedMethods)
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
				(#attempted -> (failures collect: [ :each | each mcpMessageText ] as: Array)) } asDictionary
]

{ #category : 'private - results' }
MCPToolSearchMethodReferences >> successSummaryForRequest: request scopeQuery: scopeQuery page: page [
	"When nothing implements or sends the name, a sentence follows when the name says what was meant instead, or when the change history shows a method of that selector removed."

	| hint kinds name summary |
	summary := super successSummaryForRequest: request scopeQuery: scopeQuery page: page.
	page totalCount = 0 ifFalse: [ ^ summary ].
	name := self filterPatternFromRequest: request.
	kinds := self kindsForName: name fromRequest: request.
	hint := (self noHitHintForKinds: kinds name: name) ifNil: [
			        (kinds anySatisfy: [ :kind | self selectorKinds includes: kind ]) ifFalse: [ ^ summary ].
			        (self removedMethodHintSelecting: [ :behavior :selector :protocol |
				         selector = name asSymbol and: [ scopeQuery reaches: behavior ] ]) ifNil: [ ^ summary ] ].
	^ String streamContents: [ :stream | stream << summary << ' ' << hint ]
]

{ #category : 'metadata' }
MCPToolSearchMethodReferences >> title [

	^ 'Search Method References'
]

{ #category : 'private - searching' }
MCPToolSearchMethodReferences >> variableBindingsNamed: aVariableName inBehaviors: behaviors [

	| name variables |
	name := aVariableName asSymbol.
	variables := IdentitySet new.
	behaviors do: [ :eachBehavior |
			eachBehavior allSlots do: [ :eachSlot | eachSlot name = name ifTrue: [ variables add: eachSlot ] ].
			(eachBehavior bindingOf: name) ifNotNil: [ :binding | variables add: binding ] ].
	^ variables asArray
]

{ #category : 'private - methods' }
MCPToolSearchMethodReferences >> variableReferenceEntriesForVariableNamed: variableName scopeQuery: scopeQuery [
	"The variables are looked up before the scope's methods are collected, so a name that no variable has sweeps no method."

	| variables |
	variables := self variableBindingsNamed: variableName inBehaviors: scopeQuery behaviors.
	variables ifEmpty: [ Error signal: (self noVariableMessageFor: variableName) ].
	^ self methodEntriesFromMethods:
		  (scopeQuery collectedMethods select: [ :each | MCPClassReferenceQuery method: each referencesAnyVariable: variables ])
]
