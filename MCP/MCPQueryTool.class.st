Class {
	#name : 'MCPQueryTool',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPQueryTool class >> isAbstract [

	^ self = MCPQueryTool
]

{ #category : 'private - results' }
MCPQueryTool >> errorResultForQueryError: anError requestedContext: requestedContext [

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
MCPQueryTool >> executeWithArguments: arguments [

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
MCPQueryTool >> failureMessageForRequestedContext: requestedContext error: anError [

	^ self subclassResponsibility
]

{ #category : 'private - template' }
MCPQueryTool >> queryEntriesForParameters: parameters [

	^ self subclassResponsibility
]

{ #category : 'private - pagination' }
MCPQueryTool >> queryPageForEntries: entries limit: limit offset: offset [

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
MCPQueryTool >> queryParametersFromArguments: arguments [

	^ self subclassResponsibility
]

{ #category : 'private - template' }
MCPQueryTool >> queryResultDataForParameters: parameters page: page [

	^ self subclassResponsibility
]

{ #category : 'private - pagination' }
MCPQueryTool >> queryResultDataFrom: baseData page: page entriesKey: entriesKey [

	| data |
	data := baseData
		        ifNil: [ Dictionary new ]
		        ifNotNil: [ baseData copy ].
	data
		at: #returnedCount put: (page at: #returnedCount);
		at: #totalCount put: (page at: #totalCount);
		at: #offset put: (page at: #offset);
		at: #limit put: (page at: #limit);
		at: #truncated put: (page at: #truncated);
		at: entriesKey put: (page at: #entries).
	^ data
]

{ #category : 'private - template' }
MCPQueryTool >> requestedContextFromArguments: arguments [

	^ self subclassResponsibility
]

{ #category : 'private - template' }
MCPQueryTool >> successSummaryForParameters: parameters page: page [

	^ self subclassResponsibility
]
