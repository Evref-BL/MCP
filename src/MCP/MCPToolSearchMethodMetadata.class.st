"
Concrete method metadata search tool.

Shared method-search behavior lives in MCPToolMethodSearch.
"
Class {
	#name : 'MCPToolSearchMethodMetadata',
	#superclass : 'MCPToolMethodSearch',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolSearchMethodMetadata class >> toolName [

	^ 'method_metadata_search'
]

{ #category : 'metadata' }
MCPToolSearchMethodMetadata >> buildInputSchema [

	| properties |
	properties := self methodQueryScopeInputProperties
	              , self metadataFilterInputProperties , {
		              (self
			               filterModeSchemaPropertyWithDescription:
			               'How selector and protocol filters are matched.'
			               values: self supportedFilterModes).
		              (self caseSensitiveSchemaPropertyWithDescription:
			               'Whether selector and protocol matching is case-sensitive.').
		              (self includeSourceSchemaPropertyWithDescription:
			               'Whether to include method source code in each result entry.') }
	              , (self paginationInputPropertiesWithLimitDescription:
			               'Maximum number of matching methods to return. Use 0 to return no entries.').
	^ self queryInputSchemaWithProperties: properties
]

{ #category : 'metadata' }
MCPToolSearchMethodMetadata >> defaultExposure [

	^ 'static'
]

{ #category : 'metadata' }
MCPToolSearchMethodMetadata >> description [

	^ 'Search method metadata by selector, protocol, class, package, or scope. Use specialized method search tools for source, senders, implementors, and references.'
]

{ #category : 'private - filtering' }
MCPToolSearchMethodMetadata >> fieldTextsForMethodEntry: anEntry sourceText: sourceText fieldName: fieldName [

	fieldName = 'selector' ifTrue: [ ^ { (anEntry at: #selector) } ].
	fieldName = 'protocol' ifTrue: [ ^ { (anEntry at: #protocol) } ].
	^ #(  )
]

{ #category : 'private - request' }
MCPToolSearchMethodMetadata >> metadataFilterFieldNames [

	^ #( 'selector' 'protocol' )
]

{ #category : 'private - schema' }
MCPToolSearchMethodMetadata >> metadataFilterInputProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'selector'
			   type: 'string'
			   description:
			   'Optional selector text matched against method selectors.').
		  (self
			   schemaPropertyNamed: 'protocol'
			   type: 'string'
			   description:
			   'Optional protocol/category text matched against method protocols.') }
]

{ #category : 'private - template' }
MCPToolSearchMethodMetadata >> queryEntriesForQueryRequest: queryRequest [

	(self usesExactSelectorLookupForQueryRequest: queryRequest) ifTrue: [
		^ self implementorEntriesForSelector: (queryRequest fieldFilters at: 'selector') queryRequest: queryRequest ].
	^ super queryEntriesForQueryRequest: queryRequest
]

{ #category : 'private - template' }
MCPToolSearchMethodMetadata >> searchRequestFromToolRequest: request [

	^ MCPMethodSearchRequest fromMetadataRequest: request tool: self
]

{ #category : 'metadata' }
MCPToolSearchMethodMetadata >> title [

	^ 'Search Method Metadata'
]

{ #category : 'testing' }
MCPToolSearchMethodMetadata >> usesExactSelectorLookupForQueryRequest: queryRequest [

	^ queryRequest filterPattern isNil and: [
			  queryRequest filterMode = 'exact' and: [
				  queryRequest caseSensitive and: [
					  queryRequest fieldFilters size = 1 and: [ queryRequest fieldFilters includesKey: 'selector' ] ] ] ]
]
