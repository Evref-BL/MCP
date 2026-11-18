"
Concrete method metadata search tool.

Shared method-search behavior lives in MCPToolMethodSearch.
"
Class {
	#name : 'MCPToolSearchMethods',
	#superclass : 'MCPToolMethodSearch',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolSearchMethods class >> toolName [

	^ 'method_search'
]

{ #category : 'metadata' }
MCPToolSearchMethods >> buildInputSchema [

	| properties |
	properties := self methodQueryScopeInputProperties , self metadataFilterInputProperties
	              , { self offsetInputProperty }.
	^ self queryInputSchemaWithProperties: properties
]

{ #category : 'metadata' }
MCPToolSearchMethods >> defaultExposure [

	^ 'static'
]

{ #category : 'metadata' }
MCPToolSearchMethods >> description [

	^ 'List methods by class, package, selector or protocol; method_source_search finds text, method_reference_search senders.'
]

{ #category : 'private - request' }
MCPToolSearchMethods >> fieldFilterNames [

	^ #( 'selector' 'protocol' )
]

{ #category : 'private - filtering' }
MCPToolSearchMethods >> fieldTextsForMethodEntry: anEntry sourceText: sourceText fieldName: fieldName [

	fieldName = 'selector' ifTrue: [ ^ { (anEntry at: #selector) } ].
	fieldName = 'protocol' ifTrue: [ ^ { (anEntry at: #protocol) } ].
	^ #(  )
]

{ #category : 'private - schema' }
MCPToolSearchMethods >> metadataFilterInputProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'selector'
			   type: 'string'
			   description: 'Keep methods whose selector contains this text. Case matters.').
		  (self
			   schemaPropertyNamed: 'protocol'
			   type: 'string'
			   description: 'Keep methods whose protocol contains this text. Case matters.') }
]

{ #category : 'private - results' }
MCPToolSearchMethods >> removedMethodHintForRequest: request scopeQuery: scopeQuery [
	"The removed methods the search would have listed: the selector and protocol filters keep them as they keep methods, and the scope must hold their class. A search that keeps no selector names no method, and points nowhere."

	| filterMode protocolMatcher selectorMatcher |
	(request hasArgumentNamed: 'selector') ifFalse: [ ^ nil ].
	filterMode := self filterModeFromRequest: request.
	selectorMatcher := self matcherForPattern: (request stringArgumentNamed: 'selector') mode: filterMode caseSensitive: true.
	protocolMatcher := (request stringArgumentNamed: 'protocol')
		                   ifNil: [ [ :protocol | true ] ]
		                   ifNotNil: [ :pattern | self matcherForPattern: pattern mode: filterMode caseSensitive: true ].
	^ self removedMethodHintSelecting: [ :behavior :selector :protocol |
			  (selectorMatcher value: selector asString) and: [
				  (protocolMatcher value: protocol asString) and: [ scopeQuery reaches: behavior ] ] ]
]

{ #category : 'private - results' }
MCPToolSearchMethods >> successSummaryForRequest: request scopeQuery: scopeQuery page: page [
	"A search whose scope selects no class or package, and that keeps no selector or protocol, lists every method in the image, or every method of one side. A client that drops an argument the schema does not have sends exactly that, so the summary says what narrows it. A search for a selector that finds nothing says when the change history shows such a method removed."

	| summary |
	summary := super successSummaryForRequest: request scopeQuery: scopeQuery page: page.
	page totalCount = 0 ifTrue: [
			^ (self removedMethodHintForRequest: request scopeQuery: scopeQuery)
				  ifNil: [ summary ]
				  ifNotNil: [ :hint | String streamContents: [ :stream | stream << summary << ' ' << hint ] ] ].
	(self filtersRequest: request) ifTrue: [ ^ summary ].
	scopeQuery usesImplicitImageScope ifFalse: [ ^ summary ].
	^ summary
	  ,
	  ' This search names no class, package, selector or protocol: scope.classes keeps the methods of the classes it names, and selector the methods whose selector contains its text.'
]

{ #category : 'metadata' }
MCPToolSearchMethods >> title [

	^ 'Search Method Metadata'
]
