"
Shared base class for query-style MCP tools. It centralizes paged result shaping and query-specific error handling.
"
Class {
	#name : 'MCPToolQuery',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolQuery class >> isAbstract [

	^ self = MCPToolQuery
]

{ #category : 'private - execution' }
MCPToolQuery >> commandForRequest: queryRequest [

	^ MCPQueryToolCommand tool: self request: queryRequest
]

{ #category : 'private - request' }
MCPToolQuery >> defaultFilterMode [

	^ 'substring'
]

{ #category : 'private - request' }
MCPToolQuery >> defaultFilterTargets [

	self subclassResponsibility
]

{ #category : 'private - results' }
MCPToolQuery >> errorResultForQueryError: anError requestedContext: requestedContext [

	| details normalizedContext |
	normalizedContext := requestedContext ifNil: [ Dictionary new ].
	(anError isKindOf: MCPCommandError) ifTrue: [
		details := anError structuredDetails copy.
		normalizedContext associationsDo: [ :each |
			each value ifNotNil: [ details at: each key put: each value ] ].
		^ self errorResultText: anError messageText details: details ].
	details := {
		           (#errorClass -> anError class name).
		           (#message -> anError messageText) } asDictionary.
	normalizedContext associationsDo: [ :each |
		each value ifNotNil: [ details at: each key put: each value ] ].
	^ self
		  errorResultText: (self
				   failureMessageForRequestedContext: normalizedContext
				   error: anError)
		  details: details
]

{ #category : 'executing' }
MCPToolQuery >> executeWithRequest: request [

	| command page queryRequest requestedContext |
	requestedContext := self requestedContextFromRequest: request.
	^ [
	  queryRequest := self toolRequestFromRequest: request.
	  command := self commandForRequest: queryRequest.
	  page := self
		          queryPageForEntries: command execute
		          limit: (self limitFromQuerySpec: queryRequest)
		          offset: (self offsetFromQuerySpec: queryRequest).
	  self
		  successResultText:
		  (self successSummaryForQuerySpec: queryRequest page: page)
		  data: (self queryResultDataForQuerySpec: queryRequest page: page) ]
		  on: Error
		  do: [ :error |
			  self
				  errorResultForQueryError: error
				  requestedContext: requestedContext ]
]

{ #category : 'private - template' }
MCPToolQuery >> failureMessageForRequestedContext: requestedContext error: anError [

	^ self subclassResponsibility
]

{ #category : 'private - request' }
MCPToolQuery >> filterModeFromRequest: request [

	^ request
		  stringArgumentNamed: 'filterMode'
		  default: self defaultFilterMode
]

{ #category : 'private - request' }
MCPToolQuery >> filterTargetsFromRequest: request [

	| filterTargets |
	filterTargets := request
		                 uniqueStringCollectionArgumentNamed:
		                 'filterTargets'
		                 default: self defaultFilterTargets.
	filterTargets ifEmpty: [
		Error signal: 'filterTargets must contain at least one target.' ].
	^ filterTargets
]

{ #category : 'private - template' }
MCPToolQuery >> limitFromQuerySpec: queryRequest [

	^ queryRequest limit
]

{ #category : 'private - filtering' }
MCPToolQuery >> matcherForPattern: aPattern mode: aMode caseSensitive: aBoolean [

	| normalizedPattern regex |
	aPattern ifNil: [ ^ [ :candidate | true ] ].
	aMode = 'regex' ifTrue: [
		regex := aBoolean
			         ifTrue: [ aPattern asRegex ]
			         ifFalse: [ aPattern asRegexIgnoringCase ].
		^ [ :candidate |
		  regex search:
			  (candidate ifNil: [ '' ] ifNotNil: [ candidate asString ]) ] ].
	normalizedPattern := self
		                     normalizeFilterString: aPattern
		                     caseSensitive: aBoolean.
	aMode = 'substring' ifTrue: [
		^ [ :candidate |
		  (self normalizeFilterString: candidate caseSensitive: aBoolean)
			  includesSubstring: normalizedPattern ] ].
	aMode = 'prefix' ifTrue: [
		^ [ :candidate |
		  (self normalizeFilterString: candidate caseSensitive: aBoolean)
			  beginsWith: normalizedPattern ] ].
	aMode = 'exact' ifTrue: [
		^ [ :candidate |
		  (self normalizeFilterString: candidate caseSensitive: aBoolean)
		  = normalizedPattern ] ].
	Error signal: 'Unsupported filter mode: ' , aMode
]

{ #category : 'private - schema' }
MCPToolQuery >> minimalPagedQueryOutputSchemaForEntriesPropertyNamed: entriesPropertyName entriesDescription: entriesDescription entrySchema: entrySchema itemNounPhrase: itemNounPhrase [

	| entriesProperty |
	entriesProperty := self
		                   schemaPropertyNamed: entriesPropertyName
		                   type: 'array'
		                   description: entriesDescription.
	entriesProperty items: entrySchema.
	^ self
		  standardOutputSchemaForDataProperties: {
				  (self
					   integerSchemaPropertyNamed: 'totalCount'
					   description: 'The total number of matching ' , itemNounPhrase
						   , ' before pagination.').
				  entriesProperty }
		  required: {
				  'totalCount'.
				  entriesPropertyName }
]

{ #category : 'private - filtering' }
MCPToolQuery >> normalizeFilterString: aValue caseSensitive: aBoolean [

	| normalized |
	normalized := aValue
		              ifNil: [ '' ]
		              ifNotNil: [ :value | value asString ].
	^ aBoolean
		  ifTrue: [ normalized ]
		  ifFalse: [ normalized asLowercase ]
]

{ #category : 'private - template' }
MCPToolQuery >> offsetFromQuerySpec: queryRequest [

	^ queryRequest offset
]

{ #category : 'private - template' }
MCPToolQuery >> queryEntriesForQuerySpec: queryRequest [

	self subclassResponsibility
]

{ #category : 'private - pagination' }
MCPToolQuery >> queryPageForEntries: entries limit: limit offset: offset [

	| endIndex pagedEntries startIndex totalCount truncated |
	totalCount := entries size.
	startIndex := offset + 1.
	pagedEntries := (startIndex > totalCount or: [ limit = 0 ])
		                ifTrue: [ #(  ) ]
		                ifFalse: [
			                endIndex := totalCount min: offset + limit.
			                (entries copyFrom: startIndex to: endIndex) asArray ].
	truncated := offset + pagedEntries size < totalCount.
	^ {
		  (#entries -> pagedEntries).
		  (#returnedCount -> pagedEntries size).
		  (#totalCount -> totalCount).
		  (#offset -> offset).
		  (#limit -> limit).
		  (#truncated -> truncated) } asDictionary
]

{ #category : 'private - template' }
MCPToolQuery >> queryResultDataForQuerySpec: queryRequest page: page [

	self subclassResponsibility
]

{ #category : 'private - pagination' }
MCPToolQuery >> queryResultDataFrom: baseData page: page entriesKey: entriesKey [

	^ {
		  (#totalCount -> (page at: #totalCount)).
		  (entriesKey -> (page at: #entries)) } asDictionary
]

{ #category : 'private - template' }
MCPToolQuery >> querySpecFromRequest: request [

	self subclassResponsibility
]

{ #category : 'private - template' }
MCPToolQuery >> requestedContextFromRequest: request [

	^ self subclassResponsibility
]

{ #category : 'private - schema' }
MCPToolQuery >> scopeBranchSchemasForClassAndMethodQueries [

	^ {
		  (self
			   inputSchemaBranchForStringDiscriminatorNamed: 'scope'
			   value: 'image'
			   required: #(  )
			   requireDiscriminator: false).
		  (self
			   inputSchemaBranchForStringDiscriminatorNamed: 'scope'
			   value: 'packages'
			   required: #( 'packageNames' )
			   requireDiscriminator: true).
		  (self
			   inputSchemaBranchForStringDiscriminatorNamed: 'scope'
			   value: 'classes'
			   required: #( 'classNames' )
			   requireDiscriminator: true).
		  (self
			   inputSchemaBranchForStringDiscriminatorNamed: 'scope'
			   value: 'hierarchy'
			   required: #( 'classNames' )
			   requireDiscriminator: true) } asArray
]

{ #category : 'private - schema' }
MCPToolQuery >> scopeBranchSchemasForPackageQueries [

	^ {
		  (self
			   inputSchemaBranchForStringDiscriminatorNamed: 'scope'
			   value: 'image'
			   required: #(  )
			   requireDiscriminator: false).
		  (self
			   inputSchemaBranchForStringDiscriminatorNamed: 'scope'
			   value: 'project'
			   required: #( 'projectNames' )
			   requireDiscriminator: true) } asArray
]

{ #category : 'private - results' }
MCPToolQuery >> scopeQueryFailureMessageFor: resultKind scope: scope error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to query ';
			  nextPutAll: resultKind;
			  nextPutAll: ' [scope=';
			  nextPutAll: scope;
			  nextPutAll: '] (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'private - results' }
MCPToolQuery >> scopeQuerySuccessSummaryFor: resultKind scope: scope returnedCount: returnedCount totalCount: totalCount truncated: truncated [

	^ String streamContents: [ :stream |
		  stream
			  print: returnedCount;
			  space;
			  nextPutAll: resultKind;
			  nextPutAll: ' found [scope=';
			  nextPutAll: scope;
			  nextPutAll: '] (';
			  print: totalCount;
			  nextPutAll: ' matched'.
		  truncated ifTrue: [ stream nextPutAll: ', more available' ].
		  stream nextPutAll: ').' ]
]

{ #category : 'private - template' }
MCPToolQuery >> successSummaryForQuerySpec: queryRequest page: page [

	self subclassResponsibility
]

{ #category : 'private - request' }
MCPToolQuery >> supportedFilterTargets [

	self subclassResponsibility
]

{ #category : 'private - request' }
MCPToolQuery >> toolRequestFromRequest: request [

	^ self querySpecFromRequest: request
]
