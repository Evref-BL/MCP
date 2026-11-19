"
Abstract base for method search tools.

It centralizes method scope parsing, method-entry result shaping, and shared selector/class/variable lookup helpers while concrete subclasses define their public request shape.
"
Class {
	#name : 'MCPToolMethodSearch',
	#superclass : 'MCPToolSearch',
	#traits : 'TMCPMethodTool',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolMethodSearch class >> groupName [

	^ self methodsGroupName
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> addMatchContextTo: entry sourceText: sourceText matchStartFinder: aFinder [
	"What a hit carries beyond the method it names. A tool that matches text says where it matched, with the finder its matchStartFinderForPattern:mode: built."

	^ self
]

{ #category : 'metadata' }
MCPToolMethodSearch >> additionalKeywords [

	^ #( 'method' )
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> classReferenceEntriesForClassNamed: className scopeQuery: scopeQuery [
	"The class is looked up before the scope's methods are collected, so a missing one is said at once."

	| query |
	query := MCPClassReferenceQuery forClass: (MCPImageLookup classNamed: className).
	^ self methodEntriesFromMethods: (query methodsReferringIn: scopeQuery collectedMethods)
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> collapsedEntriesFor: entries [
	"One entry for the trait, keeping the classes its method reached. Entries the trait no longer answers for, as an alias installs the method under another selector, are left as they are."

	| installed entry traitName |
	traitName := entries detect: [ :each | each includesKey: #trait ] ifFound: [ :each | each at: #trait ] ifNone: [ ^ entries ].
	(self traitNamed: traitName stillImplements: entries first) ifFalse: [ ^ entries ].
	installed := (entries select: [ :each | each includesKey: #trait ] thenCollect: [ :each | each at: #class ]) asArray sort.
	entry := (entries detect: [ :each | (each includesKey: #trait) not ] ifNone: [ entries first ]) copy.
	entry removeKey: #trait ifAbsent: [ nil ].
	entry at: #class put: traitName.
	entry at: #installedIn put: installed.
	^ { entry }
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> collapsedTraitEntriesIn: entries [
	"A method defined in a trait is installed in every class that uses the trait, so a search can answer the same source dozens of times over. Those copies are answered once, as the trait that defines them."

	| groups collapsed |
	(entries anySatisfy: [ :each | each includesKey: #trait ]) ifFalse: [ ^ entries ].
	groups := OrderedDictionary new.
	entries do: [ :each | (groups at: (self traitGroupKeyFor: each) ifAbsentPut: [ OrderedCollection new ]) add: each ].
	collapsed := OrderedCollection new.
	groups valuesDo: [ :each | collapsed addAll: (self collapsedEntriesFor: each) ].
	^ collapsed
]

{ #category : 'private - filtering' }
MCPToolMethodSearch >> fieldTextsForMethodInfo: anInfo fieldName: fieldName [

	^ #(  )
]

{ #category : 'private - request' }
MCPToolMethodSearch >> filterArgumentName [
	"The argument the caller writes the filter pattern in."

	^ 'query'
]

{ #category : 'private - filtering' }
MCPToolMethodSearch >> filterTextsForMethodInfo: anInfo sourceText: sourceText [

	^ #(  )
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> implementorEntriesForSelector: selectorString scopeQuery: scopeQuery [

	^ self methodEntriesFromMethods: (self implementorMethodsForSelector: selectorString asSymbol scopeQuery: scopeQuery)
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> implementorMethodsForSelector: selectorSymbol scopeQuery: scopeQuery [

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

{ #category : 'private - filtering' }
MCPToolMethodSearch >> matchStartFinderForPattern: aPattern mode: aMode [
	"What addMatchContextTo:sourceText:matchStartFinder: is given to find where the filter matched a hit's text: a block answering where the first match starts in a text, 0 when the text holds none. A tool that says where it matched builds one."

	^ nil
]

{ #category : 'private - filtering' }
MCPToolMethodSearch >> matchesFilterOnMethodInfo: anInfo sourceText: sourceText matcher: aMatcher [

	^ (self filterTextsForMethodInfo: anInfo sourceText: sourceText) anySatisfy: [ :each | aMatcher value: each ]
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> methodEntriesFromMethods: compiledMethods [

	^ self sortedMethodEntries:
		  (compiledMethods collect: [ :eachMethod | (MCPCompiledMethodInfo fromMethod: eachMethod) asDictionary ] as: OrderedCollection)
]

{ #category : 'private - filtering' }
MCPToolMethodSearch >> needsSourceForFiltering [

	^ false
]

{ #category : 'private - searching' }
MCPToolMethodSearch >> noVariableMessageFor: aVariableName [

	^ String streamContents: [ :stream | stream << 'No variable named ' << aVariableName << ' is accessible in the requested scope.' ]
]

{ #category : 'private - template' }
MCPToolMethodSearch >> queryEntriesForRequest: request scopeQuery: scopeQuery [
	"Every method of the scope whose text matches the filter and whose fields hold the field filters. Case matters. A method is described only once it passes them."

	| entries fieldFilters filterMode filterPattern matcher matchStartFinder needsSourceForFiltering |
	filterPattern := self filterPatternFromRequest: request.
	filterMode := self filterModeFromRequest: request.
	fieldFilters := self fieldFiltersFromRequest: request.
	matcher := self matcherForPattern: filterPattern mode: filterMode caseSensitive: true.
	matchStartFinder := self matchStartFinderForPattern: filterPattern mode: filterMode.
	needsSourceForFiltering := self needsSourceForFiltering.
	entries := OrderedCollection new.
	scopeQuery methodsDo: [ :eachMethod |
			| info sourceText |
			info := MCPCompiledMethodInfo fromMethod: eachMethod.
			sourceText := needsSourceForFiltering ifTrue: [ info source ].
			((filterPattern isNil or: [ self matchesFilterOnMethodInfo: info sourceText: sourceText matcher: matcher ]) and: [
					 self
						 fieldFilters: fieldFilters
						 matchUsing: [ :fieldName | self fieldTextsForMethodInfo: info fieldName: fieldName ]
						 mode: filterMode
						 caseSensitive: true ]) ifTrue: [
					| entry |
					entry := info asDictionary.
					self addMatchContextTo: entry sourceText: sourceText matchStartFinder: matchStartFinder.
					entries add: entry ] ].
	^ self sortedMethodEntries: entries
]

{ #category : 'private - template' }
MCPToolMethodSearch >> queryResultDataForPage: page [

	^ page asDictionaryWithEntriesKey: #methods
]

{ #category : 'private - results' }
MCPToolMethodSearch >> redundantKeys [
	"An extension's protocol already names its package with a star, so isExtension says nothing a row does not."

	^ #( isExtension )
]

{ #category : 'private - request' }
MCPToolMethodSearch >> requiredFilterPatternFromRequest: request [
	"The pattern the search cannot run without. A blank one is as missing as one left out."

	| pattern |
	pattern := self filterPatternFromRequest: request.
	pattern isEmptyOrNil ifTrue: [ ^ MCPInvalidToolInput signalMissingRequiredArgumentNamed: self filterArgumentName forTool: self ].
	^ pattern
]

{ #category : 'private - template' }
MCPToolMethodSearch >> scopeQueryFromRequest: request [

	^ self methodScopeQueryFromRequest: request
]

{ #category : 'private - template' }
MCPToolMethodSearch >> searchedNoun [

	^ 'method'
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> selectorReferenceEntriesForSelector: selectorString scopeQuery: scopeQuery [

	^ self methodEntriesFromMethods:
		  (self matchingSelectorReferencesForSelector: selectorString asSymbol inMethods: scopeQuery collectedMethods)
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> sortedMethodEntries: entries [

	^ (self collapsedTraitEntriesIn: entries) asArray sort: [ :left :right |
		  (self methodEntryLabel: left) <= (self methodEntryLabel: right) ]
]

{ #category : 'private - schema' }
MCPToolMethodSearch >> supportedFilterModes [

	^ #( 'substring' 'prefix' 'exact' 'regex' )
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> traitGroupKeyFor: anEntry [
	"What makes two entries the same method: where it is defined, rather than where it was installed."

	^ {
		  (anEntry at: #trait ifAbsent: [ anEntry at: #class ]).
		  (anEntry at: #selector).
		  (anEntry at: #side ifAbsent: [ 'instance' ]) }
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> traitNamed: aTraitName stillImplements: anEntry [
	"Whether the trait still answers the selector its copies carry, which an alias changes."

	| behavior |
	behavior := self class environment at: aTraitName asSymbol ifAbsent: [ ^ false ].
	(anEntry at: #side ifAbsent: [ 'instance' ]) = 'class' ifTrue: [ behavior := behavior classSide ].
	^ behavior includesSelector: (anEntry at: #selector) asSymbol
]

{ #category : 'private - searching' }
MCPToolMethodSearch >> variableBindingsNamed: aVariableName inBehaviors: behaviors [

	| name variables |
	name := aVariableName asSymbol.
	variables := IdentitySet new.
	behaviors do: [ :eachBehavior |
			eachBehavior allSlots do: [ :eachSlot | eachSlot name = name ifTrue: [ variables add: eachSlot ] ].
			(eachBehavior bindingOf: name) ifNotNil: [ :binding | variables add: binding ] ].
	^ variables asArray
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> variableReferenceEntriesForVariableNamed: variableName scopeQuery: scopeQuery [
	"The variables are looked up before the scope's methods are collected, so a name that no variable has sweeps no method."

	| variables |
	variables := self variableBindingsNamed: variableName inBehaviors: scopeQuery behaviors.
	variables ifEmpty: [ Error signal: (self noVariableMessageFor: variableName) ].
	^ self methodEntriesFromMethods:
		  (scopeQuery collectedMethods select: [ :each | MCPClassReferenceQuery method: each referencesAnyVariable: variables ])
]
