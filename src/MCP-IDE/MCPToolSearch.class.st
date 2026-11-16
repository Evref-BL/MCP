"
Shared base class for search-style MCP tools. A search builds the scope it looks in from its MCPToolRequest, reads the rest of its arguments from the same request as it collects its entries, and answers one page of them. It centralizes paged result shaping and search-specific error handling.
"
Class {
	#name : 'MCPToolSearch',
	#superclass : 'MCPTool',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolSearch class >> isAbstract [

	^ self = MCPToolSearch
]

{ #category : 'metadata' }
MCPToolSearch >> annotations [

	^ MCPStructureToolAnnotations readOnly
]

{ #category : 'private - schema' }
MCPToolSearch >> basicFilterModes [

	^ #( 'substring' 'prefix' 'exact' 'regex' )
]

{ #category : 'private - filtering' }
MCPToolSearch >> basicRegexMatcherForPattern: aPattern caseSensitive: aBoolean [

	| regex |
	regex := aBoolean
		         ifTrue: [ aPattern asRegex ]
		         ifFalse: [ aPattern asRegexIgnoringCase ].
	^ [ :candidate | regex search: (self regexSubjectFrom: candidate) ]
]

{ #category : 'private - schema' }
MCPToolSearch >> classQueryScopeInputProperties [

	^ { self searchScopeSchemaProperty }
]

{ #category : 'private - request' }
MCPToolSearch >> classScopeQueryFromRequest: request [

	^ MCPClassScopeQuery new
		  packageNames: (self searchScopeStringCollectionNamed: 'packages' fromRequest: request);
		  classNames: (self searchScopeStringCollectionNamed: 'classes' fromRequest: request);
		  hierarchyClassNames: (self searchScopeStringCollectionNamed: 'hierarchyOf' fromRequest: request);
		  subclassClassNames: (self searchScopeStringCollectionNamed: 'subclassesOf' fromRequest: request);
		  parentClassNames: (self searchScopeStringCollectionNamed: 'superclassesOf' fromRequest: request);
		  yourself
]

{ #category : 'private - results' }
MCPToolSearch >> countTextForPage: page offset: offset noun: aNoun filtering: aBoolean [
	"No methods, 1 method, 25 of 143563 methods: a page from the start that holds everything counts it, any other page counts what it holds of the total. An offset past the end says so, then counts the whole. A filtered count says that it matches."

	| total |
	total := page totalCount.
	^ String streamContents: [ :stream |
			  total = 0
				  ifTrue: [
						  stream
							  nextPutAll: 'No ';
							  nextPutAll: (self pluralNounFor: aNoun) ]
				  ifFalse: [
						  offset >= total
							  ifTrue: [
									  stream
										  nextPutAll: 'No ';
										  nextPutAll: (self pluralNounFor: aNoun);
										  nextPutAll: ' from offset ';
										  print: offset;
										  nextPutAll: '; ' ]
							  ifFalse: [
									  (offset = 0 and: [ page nextOffset isNil ]) ifFalse: [
											  stream
												  print: page returnedCount;
												  nextPutAll: ' of ' ] ].
						  stream nextPutAll: (self textForCount: total noun: aNoun) ].
			  stream nextPutAll: (self matchTextAfterCount: total filtering: aBoolean) ]
]

{ #category : 'private - results' }
MCPToolSearch >> countTextForRequest: request page: page [

	^ self
		  countTextForPage: page
		  offset: (request integerArgumentNamed: 'offset')
		  noun: self searchedNoun
		  filtering: (self filtersRequest: request)
]

{ #category : 'private - request' }
MCPToolSearch >> defaultFilterMode [

	^ 'substring'
]

{ #category : 'private - pagination' }
MCPToolSearch >> defaultPageLimit [

	^ 25
]

{ #category : 'private - results' }
MCPToolSearch >> errorClassNameForQueryError: anError [

	(self isRegexSyntaxError: anError) ifTrue: [ ^ #RegexSyntaxError ].
	^ anError class name
]

{ #category : 'private - results' }
MCPToolSearch >> errorResultForQueryError: anError request: request [
	"A command error says what went wrong in its own words. Any other failure is told with what was searched and where."

	^ anError
		  mcpCommandErrorDo: [ :commandError | self errorResultText: commandError messageText details: commandError structuredDetails ]
		  otherwise: [ :queryError |
				  | details |
				  details := {
					             (#errorClass -> (self errorClassNameForQueryError: queryError)).
					             (#message -> queryError messageText) } asDictionary.
				  queryError mcpAddToolErrorDetailsTo: details.
				  self errorResultText: (self failureMessageForRequest: request error: queryError) details: details ]
]

{ #category : 'executing' }
MCPToolSearch >> executeWithRequest: request [
	"A search builds the scope it looks in first, then reads the rest of its arguments as it collects what it finds, and answers one page of it. An error is told with what the caller asked for."

	^ self
		  executeRequest: request
		  do: [
				  | page scopeQuery |
				  scopeQuery := self scopeQueryFromRequest: request.
				  page := self
					          queryPageForEntries: (self queryEntriesForRequest: request scopeQuery: scopeQuery)
					          limit: self defaultPageLimit
					          offset: (request integerArgumentNamed: 'offset').
				  self
					  successResultText: (self successSummaryForRequest: request scopeQuery: scopeQuery page: page)
					  data: (self queryResultDataForPage: page)
					  warnings: (self warningsForScopeQuery: scopeQuery) ]
		  onError: [ :error | self errorResultForQueryError: error request: request ]
]

{ #category : 'private - results' }
MCPToolSearch >> failureMessageForRequest: request error: anError [
	"Unable to search methods in ZooKeeper (RegexSyntaxError): the message."

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to ';
				  nextPutAll: self searchActivityText;
				  nextPutAll: ' in ';
				  nextPutAll: (self failureScopePhraseFromRequest: request);
				  nextPutAll: ' (';
				  nextPutAll: (self errorClassNameForQueryError: anError) asString;
				  nextPutAll: '): ';
				  nextPutAll: (anError messageText ifNil: [ '' ]) asString ]
]

{ #category : 'private - results' }
MCPToolSearch >> failureScopePhraseFromRequest: request [
	"Where the request asked to look, from a scope built from it and never run, so a name that does not exist is named too."

	^ [ (self scopeQueryFromRequest: request) scopePhrase ]
		  on: Error
		  do: [ :error | 'the requested scope' ]
]

{ #category : 'private - request' }
MCPToolSearch >> fieldFilterNames [
	"The arguments that keep only the results whose field holds their text. A tool that filters on fields names them."

	^ #(  )
]

{ #category : 'private - filtering' }
MCPToolSearch >> fieldFilters: fieldFilters matchUsing: fieldTextsBlock mode: filterMode caseSensitive: caseSensitive [

	fieldFilters keysAndValuesDo: [ :fieldName :pattern |
			| matcher |
			matcher := self matcherForPattern: pattern mode: filterMode caseSensitive: caseSensitive.
			((fieldTextsBlock value: fieldName) anySatisfy: [ :each | matcher value: each ]) ifFalse: [ ^ false ] ].
	^ true
]

{ #category : 'private - request' }
MCPToolSearch >> fieldFiltersFromRequest: request [
	"Each field filter the caller wrote, by its name. A blank one is refused rather than read as matching everything."

	| filters |
	filters := Dictionary new.
	self fieldFilterNames do: [ :fieldName |
			(request hasArgumentNamed: fieldName) ifTrue: [
					filters
						at: fieldName
						put:
						((request stringArgumentNamed: fieldName) ifNil: [ MCPInvalidToolInput signalBlankArgumentNamed: fieldName forTool: self ]) ] ].
	^ filters
]

{ #category : 'private - request' }
MCPToolSearch >> filterModeFromRequest: request [

	^ request stringArgumentNamed: 'filterMode' default: self defaultFilterMode
]

{ #category : 'private - schema' }
MCPToolSearch >> filterModeSchemaPropertyWithDescription: modeDescription values: modeValues [

	^ self
		  stringEnumSchemaPropertyNamed: 'filterMode'
		  description: modeDescription
		  values: modeValues
		  default: self defaultFilterMode
]

{ #category : 'private - request' }
MCPToolSearch >> filterPatternFromRequest: request [

	(request hasArgumentNamed: 'filter') ifFalse: [ ^ nil ].
	^ (request argumentNamed: 'filter' ifAbsent: [ nil ]) ifNotNil: [ :value | value asString trimBoth ]
]

{ #category : 'private - schema' }
MCPToolSearch >> filterSchemaPropertyWithDescription: filterDescription [

	^ self schemaPropertyNamed: 'filter' type: 'string' description: filterDescription
]

{ #category : 'private - results' }
MCPToolSearch >> filtersRequest: request [
	"Whether the request keeps only the results that hold something, beyond saying where to look: a filter pattern or a field filter. Its count then says that it matches."

	^ (self filterPatternFromRequest: request) isNotNil or: [ (self fieldFiltersFromRequest: request) isNotEmpty ]
]

{ #category : 'private - results' }
MCPToolSearch >> isRegexSyntaxError: anError [

	^ anError class = RegexSyntaxError or: [ anError class = PCRE2CompileError ]
]

{ #category : 'private - results' }
MCPToolSearch >> keysStatedInSummary [
	"The summary already states the counts and the next offset in prose."

	^ #( pagination nextOffset )
]

{ #category : 'private - filtering' }
MCPToolSearch >> literalRegexSourceFor: aString [
	"A regex that matches aString as written in either engine: each character either engine reads as syntax is escaped, the colon included, which Rx reads as the start of a class such as :alpha:."

	^ String streamContents: [ :stream |
			  aString do: [ :each |
					  ('\^$.|?*+()[]{}:' includes: each) ifTrue: [ stream nextPut: $\ ].
					  stream nextPut: each ] ]
]

{ #category : 'private - results' }
MCPToolSearch >> matchTextAfterCount: aCount filtering: aBoolean [

	aBoolean ifFalse: [ ^ '' ].
	^ aCount = 1
		  ifTrue: [ ' matches' ]
		  ifFalse: [ ' match' ]
]

{ #category : 'private - filtering' }
MCPToolSearch >> matcherForPattern: aPattern mode: aMode caseSensitive: aBoolean [

	| normalizedPattern |
	aPattern ifNil: [ ^ [ :candidate | true ] ].
	aMode = 'regex' ifTrue: [ ^ self regexMatcherForPattern: aPattern caseSensitive: aBoolean ].
	normalizedPattern := self normalizeFilterString: aPattern caseSensitive: aBoolean.
	aMode = 'substring' ifTrue: [
		^ [ :candidate | (self normalizeFilterString: candidate caseSensitive: aBoolean) includesSubstring: normalizedPattern ] ].
	aMode = 'prefix' ifTrue: [
		^ [ :candidate | (self normalizeFilterString: candidate caseSensitive: aBoolean) beginsWith: normalizedPattern ] ].
	aMode = 'exact' ifTrue: [ ^ [ :candidate | (self normalizeFilterString: candidate caseSensitive: aBoolean) = normalizedPattern ] ].
	Error signal: 'Unsupported filter mode: ' , aMode
]

{ #category : 'private - filtering' }
MCPToolSearch >> matcherForPiecesAcrossBlanks: pieces caseSensitive: aBoolean [
	"Whether a text holds pieces in this order, each separated from the next by a run of blanks, line breaks included: the pieces, each escaped, joined by \s+. The longest piece is looked for first, as a plain substring, so the regex runs only on the texts that hold it and a search over the whole image stays fast."

	| longest regexMatcher |
	longest := self normalizeFilterString: (pieces detectMax: [ :each | each size ]) caseSensitive: aBoolean.
	regexMatcher := self
		                regexMatcherForPattern: ('\s+' join: (pieces collect: [ :each | self literalRegexSourceFor: each ]))
		                caseSensitive: aBoolean.
	^ [ :candidate |
	  ((self normalizeFilterString: candidate caseSensitive: aBoolean) includesSubstring: longest) and: [
		  regexMatcher value: candidate ] ]
]

{ #category : 'private - results' }
MCPToolSearch >> nextPageTextForOffset: anOffset [
	"Where the next page starts, and the other way to see what it holds."

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Next page: offset ';
				  print: anOffset;
				  nextPutAll: ', or narrow the search.' ]
]

{ #category : 'private - filtering' }
MCPToolSearch >> normalizeFilterString: aValue caseSensitive: aBoolean [

	| normalized |
	normalized := aValue ifNil: [ '' ] ifNotNil: [ :value | value asString ].
	^ aBoolean
		  ifTrue: [ normalized ]
		  ifFalse: [ normalized asLowercase ]
]

{ #category : 'private - schema' }
MCPToolSearch >> packageQueryScopeInputProperties [

	^ {
		  self packageScopeProjectNamesProperty.
		  self packageScopePackageNamesProperty }
]

{ #category : 'private - schema' }
MCPToolSearch >> packageScopePackageNamesProperty [

	^ self stringArraySchemaNamed: 'packages' description: 'These packages, named exactly.' itemDescription: 'Package name.'
]

{ #category : 'private - schema' }
MCPToolSearch >> packageScopeProjectNamesProperty [

	^ self
		  stringArraySchemaNamed: 'projects'
		  description: 'Projects whose packages are included.'
		  itemDescription: 'Project name.'
]

{ #category : 'private - filtering' }
MCPToolSearch >> pcre2RegexLibraryAvailable [
	"PCRE2 is an optional dependency: answer whether there is an engine to compile a pattern with."

	^ PCRE2Compiler nativeLibraryAvailable
]

{ #category : 'private - filtering' }
MCPToolSearch >> pcre2RegexMatcherForPattern: aPattern caseSensitive: aBoolean [

	| regex |
	regex := aBoolean
		         ifTrue: [ aPattern asPerlCompatibleRegex ]
		         ifFalse: [ aPattern asPerlCompatibleRegexIgnoringCase ].
	^ [ :candidate | regex search: (self regexSubjectFrom: candidate) ]
]

{ #category : 'private - template' }
MCPToolSearch >> queryEntriesForRequest: request scopeQuery: scopeQuery [
	"Every entry the search finds in scopeQuery, before it is paged. A tool reads the rest of its arguments from request here, checking them before it looks."

	^ self subclassResponsibility
]

{ #category : 'private - schema' }
MCPToolSearch >> queryInputSchemaWithProperties: inputProperties [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: inputProperties;
		  required: #(  );
		  yourself
]

{ #category : 'private - pagination' }
MCPToolSearch >> queryPageForEntries: entries limit: limit offset: offset [

	^ MCPPaginationResult fromEntries: entries limit: limit offset: offset
]

{ #category : 'private - template' }
MCPToolSearch >> queryResultDataForPage: page [
	"The answer's data for one page of entries."

	^ self subclassResponsibility
]

{ #category : 'private - results' }
MCPToolSearch >> readingNoteForPage: page [
	"A sentence on how to read the rows of page, or nil when they need none."

	^ nil
]

{ #category : 'private - filtering' }
MCPToolSearch >> regexMatcherForPattern: aPattern caseSensitive: aBoolean [

	^ self pcre2RegexLibraryAvailable
		  ifTrue: [ self pcre2RegexMatcherForPattern: aPattern caseSensitive: aBoolean ]
		  ifFalse: [ self basicRegexMatcherForPattern: aPattern caseSensitive: aBoolean ]
]

{ #category : 'private - filtering' }
MCPToolSearch >> regexSubjectFrom: aCandidate [

	^ aCandidate ifNil: [ '' ] ifNotNil: [ :value | value asString ]
]

{ #category : 'private - results' }
MCPToolSearch >> scopePhraseForScopeQuery: scopeQuery [
	"Where the search looked, from the names its scope resolved; nil when none of them exists."

	^ scopeQuery scopePhrase
]

{ #category : 'private - template' }
MCPToolSearch >> scopeQueryFromRequest: request [
	"The scope query the request describes."

	^ self subclassResponsibility
]

{ #category : 'private - results' }
MCPToolSearch >> searchActivityText [
	"What the tool does, for the sentence that says it could not: search methods."

	^ 'search ' , (self pluralNounFor: self searchedNoun)
]

{ #category : 'private - results' }
MCPToolSearch >> searchSummaryForCountText: countText scopePhrase: scopePhrase page: page [
	"A scope whose names all failed to resolve looked nowhere, which the summary says instead of a place; its warnings name what is missing. A note on reading the rows, when the tool has one, comes before where the next page starts."

	^ String streamContents: [ :stream |
			  stream nextPutAll: countText.
			  scopePhrase ifNil: [ stream nextPutAll: ': the scope names nothing that exists.' ] ifNotNil: [
					  stream
						  nextPutAll: ' in ';
						  nextPutAll: scopePhrase;
						  nextPut: $. ].
			  (self readingNoteForPage: page) ifNotNil: [ :note |
					  stream
						  space;
						  nextPutAll: note ].
			  page nextOffset ifNotNil: [ :offset |
					  stream
						  space;
						  nextPutAll: (self nextPageTextForOffset: offset) ] ]
]

{ #category : 'private - template' }
MCPToolSearch >> searchedNoun [
	"What one result is, in the singular: method, class."

	^ self subclassResponsibility
]

{ #category : 'private - results' }
MCPToolSearch >> successSummaryForRequest: request scopeQuery: scopeQuery page: page [
	"How many were found and where, then where the next page starts."

	^ self
		  searchSummaryForCountText: (self countTextForRequest: request page: page)
		  scopePhrase: (self scopePhraseForScopeQuery: scopeQuery)
		  page: page
]

{ #category : 'private - schema' }
MCPToolSearch >> supportedFilterModes [

	^ self basicFilterModes
]

{ #category : 'private - results' }
MCPToolSearch >> warningsForScopeQuery: scopeQuery [
	"What the scope could not resolve, such as a class that does not exist."

	^ scopeQuery warnings
]
