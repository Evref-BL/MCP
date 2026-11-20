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

	^ MCPStructureInputSchema
		  properties: self methodQueryScopeInputProperties , self metadataFilterInputProperties , { self offsetInputProperty }
		  required: #(  )
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

	^ #( 'protocol' )
]

{ #category : 'private - filtering' }
MCPToolSearchMethods >> fieldTextsForMethodInfo: anInfo fieldName: fieldName [

	fieldName = 'protocol' ifTrue: [ ^ { anInfo protocol } ].
	^ #(  )
]

{ #category : 'private - filtering' }
MCPToolSearchMethods >> filterTextsForMethodInfo: anInfo sourceText: sourceText [
	"The text query matches: the selector."

	^ { anInfo selector }
]

{ #category : 'private - schema' }
MCPToolSearchMethods >> metadataFilterInputProperties [

	^ {
		  (self schemaPropertyNamed: 'query' type: 'string' description: 'Keep methods whose selector contains this text. Case matters.').
		  (self
			   schemaPropertyNamed: 'protocol'
			   type: 'string'
			   description: 'Keep methods whose protocol contains this text. Case matters.') }
]

{ #category : 'private - results' }
MCPToolSearchMethods >> removedMethodHintForRequest: request scopeQuery: scopeQuery [
	"The removed methods the search would have listed: the selector and protocol filters keep them as they keep methods, and the scope must hold their class. A search that keeps no selector names no method, and points nowhere."

	| filterMode protocolMatcher selectorMatcher |
	(request hasArgumentNamed: 'query') ifFalse: [ ^ nil ].
	filterMode := self filterModeFromRequest: request.
	selectorMatcher := self matcherForPattern: (request stringArgumentNamed: 'query') mode: filterMode caseSensitive: true.
	protocolMatcher := (request stringArgumentNamed: 'protocol')
		                   ifNil: [ [ :protocol | true ] ]
		                   ifNotNil: [ :pattern | self matcherForPattern: pattern mode: filterMode caseSensitive: true ].
	^ self removedMethodHintSelecting: [ :behavior :selector :protocol |
			  (selectorMatcher value: selector asString) and: [
				  (protocolMatcher value: protocol asString) and: [ scopeQuery reaches: behavior ] ] ]
]

{ #category : 'private - results' }
MCPToolSearchMethods >> successSummaryForRequest: request scopeQuery: scopeQuery page: page [
	"A search whose scope selects no class or package, and that keeps no selector or protocol, lists every method in the image, or every method of one side. A client that drops an argument the schema does not have sends exactly that, so the summary says what narrows it. A search for a selector that finds nothing says when the change history shows such a method removed, and a search scoped to packages or classes says what the image lost of them since its last save."

	| summary |
	summary := super successSummaryForRequest: request scopeQuery: scopeQuery page: page.
	page totalCount = 0 ifTrue: [
			(self removedMethodHintForRequest: request scopeQuery: scopeQuery) ifNotNil: [ :hint |
				summary := String streamContents: [ :stream | stream << summary << ' ' << hint ] ] ].
	((self filtersRequest: request) or: [ scopeQuery usesImplicitImageScope not ]) ifTrue: [
			^ MCPToolListLostChanges
				  summary: summary
				  notingLostChangesToPackagesNamed: scopeQuery packageNames
				  classesNamed: (scopeQuery classNames collect: [ :each | each copyUpTo: Character space ]) ].
	^ summary
	  ,
	  ' This search names no class, package, selector or protocol: scope.classes keeps the methods of the classes it names, and query the methods whose selector contains its text.'
]

{ #category : 'metadata' }
MCPToolSearchMethods >> title [

	^ 'Search Method Metadata'
]
