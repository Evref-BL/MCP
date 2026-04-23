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

{ #category : 'private - arguments' }
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
MCPToolQuery >> executeWithArguments: arguments [

	| page parameters requestedContext |
	requestedContext := self requestedContextFromArguments: arguments.
	^ [
	  parameters := self queryParametersFromArguments: arguments.
	  page := self
		          queryPageForEntries:
		          (self queryEntriesForParameters: parameters)
		          limit: (parameters at: #limit)
		          offset: (parameters at: #offset).
	  self
		  successResultText:
		  (self successSummaryForParameters: parameters page: page)
		  data: (self queryResultDataForParameters: parameters page: page) ]
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

{ #category : 'private - arguments' }
MCPToolQuery >> normalizedFilterTargetsFrom: arguments [

	| invalidTargets normalizedTargets rawTargets supportedTargets |
	rawTargets := self
		              argumentNamed: 'filterTargets'
		              in: arguments
		              ifAbsent: [ ^ self defaultFilterTargets ].
	supportedTargets := self supportedFilterTargets.
	normalizedTargets := OrderedCollection new.
	invalidTargets := OrderedCollection new.
	(self
		 normalizedStringCollection: rawTargets
		 argumentName: 'filterTargets') do: [ :each |
		| canonical |
		canonical := supportedTargets
			             detect: [ :supported |
			             supported asLowercase = each asLowercase ]
			             ifNone: [ nil ].
		canonical ifNil: [ invalidTargets add: each ] ifNotNil: [
			(normalizedTargets includes: canonical) ifFalse: [
				normalizedTargets add: canonical ] ] ].
	invalidTargets ifNotEmpty: [
		Error signal: 'Unsupported filterTargets value(s): '
			, invalidTargets asArray printString , '. Supported targets are '
			, supportedTargets printString , '.' ].
	normalizedTargets ifEmpty: [
		Error signal: 'filterTargets must contain at least one target.' ].
	^ normalizedTargets asArray
]

{ #category : 'private - template' }
MCPToolQuery >> queryEntriesForParameters: parameters [

	^ self subclassResponsibility
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
MCPToolQuery >> queryParametersFromArguments: arguments [

	^ self subclassResponsibility
]

{ #category : 'private - template' }
MCPToolQuery >> queryResultDataForParameters: parameters page: page [

	^ self subclassResponsibility
]

{ #category : 'private - pagination' }
MCPToolQuery >> queryResultDataFrom: baseData page: page entriesKey: entriesKey [

	^ {
		  (#totalCount -> (page at: #totalCount)).
		  (entriesKey -> (page at: #entries)) } asDictionary
]

{ #category : 'private - template' }
MCPToolQuery >> requestedContextFromArguments: arguments [

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
MCPToolQuery >> successSummaryForParameters: parameters page: page [

	^ self subclassResponsibility
]

{ #category : 'private - arguments' }
MCPToolQuery >> supportedFilterTargets [

	self subclassResponsibility
]
