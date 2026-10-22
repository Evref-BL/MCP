"
Abstract base for method search tools.

It centralizes method scope parsing, method-entry result shaping, and shared selector/class/variable lookup helpers while concrete subclasses define their public request shape.
"
Class {
	#name : 'MCPToolMethodSearch',
	#superclass : 'MCPToolSearch',
	#traits : 'TMCPMethodTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolMethodSearch class >> groupName [

	^ self methodsGroupName
]

{ #category : 'testing' }
MCPToolMethodSearch class >> isAbstract [

	^ self = MCPToolMethodSearch
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> addMatchContextTo: entry sourceText: sourceText matcher: matcher queryRequest: queryRequest [
	"What a hit carries beyond the method it names. A tool that matches text says where it matched."

	^ self
]

{ #category : 'metadata' }
MCPToolMethodSearch >> additionalKeywords [

	^ #( 'method' )
]

{ #category : 'private - searching' }
MCPToolMethodSearch >> classBindingForClassName: aClassName [

	| binding |
	binding := Smalltalk globals associationAt: aClassName asSymbol ifAbsent: [ ^ nil ].
	^ binding value isBehavior ifTrue: [ binding ]
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> classReferenceEntriesForClassNamed: className queryRequest: queryRequest [

	^ self
		  methodEntriesFromMethods: (self matchingClassReferencesForClassNamed: className inMethods: queryRequest scopeQuery methods)
		  queryRequest: queryRequest
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> classReferenceEntriesForQueryRequest: queryRequest [

	^ self classReferenceEntriesForClassNamed: (queryRequest requiredFilterPatternForTool: self) queryRequest: queryRequest
]

{ #category : 'private - results' }
MCPToolMethodSearch >> failureMessageForScope: scopeSummary error: anError [

	^ self scopeQueryFailureMessageFor: 'methods' scope: scopeSummary error: anError
]

{ #category : 'private - filtering' }
MCPToolMethodSearch >> fieldTextsForMethodEntry: anEntry sourceText: sourceText fieldName: fieldName [

	^ #(  )
]

{ #category : 'private - filtering' }
MCPToolMethodSearch >> filterTextsForMethodEntry: anEntry sourceText: sourceText [

	^ #(  )
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> implementorEntriesForQueryRequest: queryRequest [

	^ self implementorEntriesForSelector: queryRequest filterPattern queryRequest: queryRequest
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> implementorEntriesForSelector: selectorString queryRequest: queryRequest [

	| compiledMethods selectorSymbol |
	selectorSymbol := selectorString asSymbol.
	compiledMethods := self implementorMethodsForSelector: selectorSymbol queryRequest: queryRequest.
	^ self methodEntriesFromMethods: compiledMethods queryRequest: queryRequest
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> implementorMethodsForSelector: selectorSymbol queryRequest: queryRequest [

	| methods scopeQuery |
	scopeQuery := queryRequest scopeQuery.
	scopeQuery packageNames ifNotEmpty: [
		^ (scopeQuery methods select: [ :eachMethod | eachMethod selector = selectorSymbol ]) asArray ].
	methods := OrderedCollection new.
	scopeQuery behaviors do: [ :eachBehavior |
		(eachBehavior includesSelector: selectorSymbol) ifTrue: [ methods add: eachBehavior >> selectorSymbol ] ].
	^ methods asArray
]

{ #category : 'private - filtering' }
MCPToolMethodSearch >> matchesFieldFiltersOnMethodEntry: anEntry sourceText: sourceText queryRequest: queryRequest [

	^ self
		  fieldFilters: queryRequest fieldFilters
		  matchUsing: [ :fieldName | self fieldTextsForMethodEntry: anEntry sourceText: sourceText fieldName: fieldName ]
		  mode: queryRequest filterMode
		  caseSensitive: queryRequest caseSensitive
]

{ #category : 'private - filtering' }
MCPToolMethodSearch >> matchesFilterOnMethodEntry: anEntry sourceText: sourceText matcher: aMatcher [

	^ (self filterTextsForMethodEntry: anEntry sourceText: sourceText) anySatisfy: [ :each | aMatcher value: each ]
]

{ #category : 'private - searching' }
MCPToolMethodSearch >> matchingClassReferencesForClassNamed: aClassName inMethods: compiledMethods [

	| classBinding |
	classBinding := self classBindingForClassName: aClassName.
	classBinding ifNil: [ Error signal: 'There is no class named ' , aClassName , '.' ].
	^ (compiledMethods select: [ :eachMethod | self method: eachMethod referencesAnyVariable: { classBinding } ]) asArray
]

{ #category : 'private - searching' }
MCPToolMethodSearch >> matchingSelectorReferencesForSelector: aSelectorSymbol inMethods: compiledMethods [

	| specialSelectorIndex |
	specialSelectorIndex := Smalltalk specialSelectorIndexOrNil: aSelectorSymbol.
	^ (compiledMethods select: [ :eachMethod | eachMethod hasSelector: aSelectorSymbol specialSelectorIndex: specialSelectorIndex ])
		  asArray
]

{ #category : 'private - searching' }
MCPToolMethodSearch >> matchingVariableReferencesNamed: aVariableName scopeQuery: query inMethods: compiledMethods [

	| variables |
	variables := self variableBindingsNamed: aVariableName inBehaviors: query behaviors.
	variables ifEmpty: [ Error signal: 'No variable named ' , aVariableName , ' is accessible in the requested scope.' ].
	^ (compiledMethods select: [ :eachMethod | self method: eachMethod referencesAnyVariable: variables ]) asArray
]

{ #category : 'private - searching' }
MCPToolMethodSearch >> method: aCompiledMethod referencesAnyVariable: variables [

	^ variables anySatisfy: [ :eachVariable | eachVariable isAccessedIn: aCompiledMethod ]
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> methodEntriesFromMethods: compiledMethods queryRequest: queryRequest [

	| entries |
	entries := OrderedCollection new.
	compiledMethods do: [ :eachMethod |
			| info |
			info := MCPCompiledMethodInfo fromMethod: eachMethod.
			entries add: (info asDictionaryIncludingSource: queryRequest includeSource) ].
	^ self sortedMethodEntries: entries
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> methodEntriesFromQueryRequest: queryRequest [

	| entries matcher needsSourceForFiltering |
	matcher := self
		           matcherForPattern: queryRequest filterPattern
		           mode: queryRequest filterMode
		           caseSensitive: queryRequest caseSensitive.
	needsSourceForFiltering := self needsSourceForFiltering.
	entries := OrderedCollection new.
	queryRequest scopeQuery methodsDo: [ :eachMethod |
			| entry info matchesFilter sourceText |
			info := MCPCompiledMethodInfo fromMethod: eachMethod.
			entry := info asDictionaryIncludingSource: false.
			sourceText := needsSourceForFiltering ifTrue: [ info source ].
			matchesFilter := (queryRequest hasFilterPattern not or: [
				                  self matchesFilterOnMethodEntry: entry sourceText: sourceText matcher: matcher ]) and: [
				                 self matchesFieldFiltersOnMethodEntry: entry sourceText: sourceText queryRequest: queryRequest ].
			matchesFilter ifTrue: [
					self
						addMatchContextTo: entry
						sourceText: sourceText
						matcher: matcher
						queryRequest: queryRequest.
					entries add: entry ] ].
	^ self sortedMethodEntries: entries
]

{ #category : 'private - results' }
MCPToolMethodSearch >> methodQueryResultDataForPage: page entriesKey: entriesKey [

	^ self queryResultDataFrom: nil page: page entriesKey: entriesKey
]

{ #category : 'private - schema' }
MCPToolMethodSearch >> methodQueryScopeInputProperties [

	^ {
		  self methodSideSchemaProperty.
		  self searchScopeSchemaProperty }
]

{ #category : 'private - filtering' }
MCPToolMethodSearch >> needsSourceForFiltering [

	^ false
]

{ #category : 'private - template' }
MCPToolMethodSearch >> queryEntriesForQueryRequest: queryRequest [

	^ self methodEntriesFromQueryRequest: queryRequest
]

{ #category : 'private - template' }
MCPToolMethodSearch >> queryResultDataForQueryRequest: queryRequest page: page [

	^ self methodQueryResultDataForPage: page entriesKey: #methods
]

{ #category : 'private - template' }
MCPToolMethodSearch >> requestedContextFromRequest: request [

	^ { (#scope -> (self classAndMethodScopeSummaryFromRequest: request)) } asDictionary
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> selectorReferenceEntriesForQueryRequest: queryRequest [

	^ self selectorReferenceEntriesForSelector: (queryRequest requiredFilterPatternForTool: self) queryRequest: queryRequest
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> selectorReferenceEntriesForSelector: selectorString queryRequest: queryRequest [

	^ self
		  methodEntriesFromMethods:
		  (self matchingSelectorReferencesForSelector: selectorString asSymbol inMethods: queryRequest scopeQuery methods)
		  queryRequest: queryRequest
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> sortedMethodEntries: entries [

	^ entries asArray sort: [ :left :right | (self methodEntryLabel: left) <= (self methodEntryLabel: right) ]
]

{ #category : 'private - results' }
MCPToolMethodSearch >> successSummaryForScope: scopeSummary page: page [

	^ self scopeQuerySuccessSummaryFor: 'methods' scope: scopeSummary page: page
]

{ #category : 'private - schema' }
MCPToolMethodSearch >> supportedFilterModes [

	^ #( 'substring' 'prefix' 'exact' 'regex' )
]

{ #category : 'private - searching' }
MCPToolMethodSearch >> variableBindingsNamed: aVariableName inBehaviors: behaviors [

	| variables |
	variables := IdentitySet new.
	behaviors do: [ :eachBehavior |
			eachBehavior allSlots do: [ :eachSlot | eachSlot name asString = aVariableName ifTrue: [ variables add: eachSlot ] ].
			(eachBehavior bindingOf: aVariableName) ifNotNil: [ :binding | variables add: binding ] ].
	^ variables asArray
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> variableReferenceEntriesForQueryRequest: queryRequest [

	^ self variableReferenceEntriesForVariableNamed: (queryRequest requiredFilterPatternForTool: self) queryRequest: queryRequest
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> variableReferenceEntriesForVariableNamed: variableName queryRequest: queryRequest [

	^ self
		  methodEntriesFromMethods:
		  (self
			   matchingVariableReferencesNamed: variableName
			   scopeQuery: queryRequest scopeQuery
			   inMethods: queryRequest scopeQuery methods)
		  queryRequest: queryRequest
]
