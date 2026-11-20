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

{ #category : 'metadata' }
MCPToolSearch >> annotations [

	^ MCPStructureToolAnnotations readOnly
]

{ #category : 'private - schema' }
MCPToolSearch >> classQueryScopeInputProperties [

	^ { self searchScopeSchemaProperty }
]

{ #category : 'private - request' }
MCPToolSearch >> classScopeQueryFromRequest: request [

	^ self scopeQuery: MCPClassScopeQuery new fromRequest: request
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
						  self
							  pagePrefixOn: stream
							  page: page
							  offset: offset
							  nouns: (self pluralNounFor: aNoun).
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

{ #category : 'metadata' }
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

	^ self errorResultFor: anError otherwise: [ :queryError |
			  | details |
			  details := {
				             (#errorClass -> (self errorClassNameForQueryError: queryError)).
				             (#message -> queryError mcpMessageText) } asDictionary.
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
				  nextPutAll: anError mcpMessageText ]
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
	"A search that takes queryMode reads it, with its schema default; one that does not always matches the same way."

	^ (request stringArgumentOrDefaultNamed: 'queryMode') ifNil: [ self defaultFilterMode ]
]

{ #category : 'private - schema' }
MCPToolSearch >> filterModeSchemaPropertyWithDescription: modeDescription values: modeValues [

	^ self
		  stringEnumSchemaPropertyNamed: 'queryMode'
		  description: modeDescription
		  values: modeValues
		  default: self defaultFilterMode
]

{ #category : 'private - request' }
MCPToolSearch >> filterPatternFromRequest: request [

	(request hasArgumentNamed: 'query') ifFalse: [ ^ nil ].
	^ (request argumentNamed: 'query' ifAbsent: [ nil ]) ifNotNil: [ :value | value asString trimBoth ]
]

{ #category : 'private - schema' }
MCPToolSearch >> filterSchemaPropertyWithDescription: filterDescription [

	^ self schemaPropertyNamed: 'query' type: 'string' description: filterDescription
]

{ #category : 'private - results' }
MCPToolSearch >> filtersRequest: request [
	"Whether the request keeps only the results that hold something, beyond saying where to look: a filter pattern or a field filter. Its count then says that it matches."

	^ (self filterPatternFromRequest: request) isNotNil or: [ (self fieldFiltersFromRequest: request) isNotEmpty ]
]

{ #category : 'private - results' }
MCPToolSearch >> isRegexSyntaxError: anError [

	^ anError class = PCRE2CompileError
]

{ #category : 'private - results' }
MCPToolSearch >> keysStatedInSummary [
	"The summary already states the counts and the next offset in prose."

	^ #( pagination nextOffset )
]

{ #category : 'private - filtering' }
MCPToolSearch >> literalRegexSourceFor: aString [
	"A regex that matches aString as written: each character a regex reads as syntax is escaped."

	^ String streamContents: [ :stream |
			  aString do: [ :each |
					  ('\^$.|?*+()[]{}' includes: each) ifTrue: [ stream nextPut: $\ ].
					  stream nextPut: each ] ]
]

{ #category : 'private - filtering' }
MCPToolSearch >> matchStartFinderForPiecesAcrossBlanks: pieces caseSensitive: aBoolean [
	"A block answering where pieces first stand in a text in this order, each separated from the next by a run of blanks, line breaks included, as the index of the first piece's first character, or 0 when they do not: the pieces, each escaped, joined by \s+. The longest piece is looked for first, as a plain substring, so the regex runs only on the texts that hold it and a search over the whole image stays fast."

	| longest regexFinder |
	longest := self normalizeFilterString: (pieces detectMax: [ :each | each size ]) caseSensitive: aBoolean.
	regexFinder := self
		               regexMatchStartFinderForPattern: ('\s+' join: (pieces collect: [ :each | self literalRegexSourceFor: each ]))
		               caseSensitive: aBoolean.
	^ [ :candidate |
		  ((self normalizeFilterString: candidate caseSensitive: aBoolean) includesSubstring: longest)
			  ifTrue: [ regexFinder value: candidate ]
			  ifFalse: [ 0 ] ]
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
	aMode = 'substring' ifFalse: [ Error signal: 'Unsupported filter mode: ' , aMode ].
	normalizedPattern := self normalizeFilterString: aPattern caseSensitive: aBoolean.
	^ [ :candidate | (self normalizeFilterString: candidate caseSensitive: aBoolean) includesSubstring: normalizedPattern ]
]

{ #category : 'private - filtering' }
MCPToolSearch >> matcherForPiecesAcrossBlanks: pieces caseSensitive: aBoolean [
	"Whether a text holds pieces in this order, each separated from the next by a run of blanks, line breaks included."

	| finder |
	finder := self matchStartFinderForPiecesAcrossBlanks: pieces caseSensitive: aBoolean.
	^ [ :candidate | (finder value: candidate) > 0 ]
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

{ #category : 'private - results' }
MCPToolSearch >> pagePrefixOn: aStream page: page offset: offset nouns: aPluralText [
	"What a count opens with: No methods from offset 40; past the end, 25 of on a page that holds part of what was found, nothing on one that holds it all."

	offset >= page totalCount ifTrue: [ ^ aStream << 'No ' << aPluralText << ' from offset ' << offset printString << '; ' ].
	(offset = 0 and: [ page nextOffset isNil ]) ifFalse: [
			aStream
				print: page returnedCount;
				nextPutAll: ' of ' ]
]

{ #category : 'private - template' }
MCPToolSearch >> queryEntriesForRequest: request scopeQuery: scopeQuery [
	"Every entry the search finds in scopeQuery, before it is paged. A tool reads the rest of its arguments from request here, checking them before it looks."

	^ self subclassResponsibility
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
MCPToolSearch >> regexMatchStartFinderForPattern: aPattern caseSensitive: aBoolean [
	"A block answering where the first match of aPattern starts in a text, as the index of its first character, or 0 when the text holds none. After a search, PCRE2 answers the 0-based position the match starts at."

	| regex |
	regex := aBoolean
		         ifTrue: [ aPattern asPerlCompatibleRegex ]
		         ifFalse: [ aPattern asPerlCompatibleRegexIgnoringCase ].
	^ [ :candidate |
		  (regex search: (self regexSubjectFrom: candidate))
			  ifTrue: [ (regex subBeginning: 1) first + 1 ]
			  ifFalse: [ 0 ] ]
]

{ #category : 'private - filtering' }
MCPToolSearch >> regexMatcherForPattern: aPattern caseSensitive: aBoolean [

	| finder |
	finder := self regexMatchStartFinderForPattern: aPattern caseSensitive: aBoolean.
	^ [ :candidate | (finder value: candidate) > 0 ]
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

{ #category : 'private - results' }
MCPToolSearch >> warningsForScopeQuery: scopeQuery [
	"What the scope could not resolve, such as a class that does not exist."

	^ scopeQuery warnings
]
