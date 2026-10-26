"
Concrete method metadata search tool.

Shared method-search behavior lives in MCPToolMethodSearch.
"
Class {
	#name : 'MCPToolSearchMethods',
	#superclass : 'MCPToolMethodSearch',
	#category : 'MCP-Tools',
	#package : 'MCP',
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

	^ 'Search methods by selector, protocol, class, package, or scope. Use method_source_search for source text and method_reference_search for where a name is used.'
]

{ #category : 'private - filtering' }
MCPToolSearchMethods >> fieldTextsForMethodEntry: anEntry sourceText: sourceText fieldName: fieldName [

	fieldName = 'selector' ifTrue: [ ^ { (anEntry at: #selector) } ].
	fieldName = 'protocol' ifTrue: [ ^ { (anEntry at: #protocol) } ].
	^ #(  )
]

{ #category : 'private - request' }
MCPToolSearchMethods >> metadataFilterFieldNames [

	^ #( 'selector' 'protocol' )
]

{ #category : 'private - schema' }
MCPToolSearchMethods >> metadataFilterInputProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'selector'
			   type: 'string'
			   description: 'Keep methods whose selector contains this text, ignoring case.').
		  (self
			   schemaPropertyNamed: 'protocol'
			   type: 'string'
			   description: 'Keep methods whose protocol contains this text, ignoring case.') }
]

{ #category : 'private - template' }
MCPToolSearchMethods >> queryEntriesForQueryRequest: queryRequest [

	(self usesExactSelectorLookupForQueryRequest: queryRequest) ifTrue: [
		^ self implementorEntriesForSelector: (queryRequest fieldFilters at: 'selector') queryRequest: queryRequest ].
	^ super queryEntriesForQueryRequest: queryRequest
]

{ #category : 'private - template' }
MCPToolSearchMethods >> searchRequestFromToolRequest: request [

	^ MCPMethodSearchRequest fromMetadataRequest: request tool: self
]

{ #category : 'metadata' }
MCPToolSearchMethods >> title [

	^ 'Search Method Metadata'
]

{ #category : 'testing' }
MCPToolSearchMethods >> usesExactSelectorLookupForQueryRequest: queryRequest [

	^ queryRequest filterPattern isNil and: [
			  queryRequest filterMode = 'exact' and: [
				  queryRequest caseSensitive and: [
					  queryRequest fieldFilters size = 1 and: [ queryRequest fieldFilters includesKey: 'selector' ] ] ] ]
]
