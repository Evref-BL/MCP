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

{ #category : 'defaults' }
MCPToolSearchMethodMetadata class >> toolName [

	^ 'method_metadata_search'
]

{ #category : 'defaults' }
MCPToolSearchMethodMetadata >> defaultDescription [

	^ 'List and search methods by selector, protocol, class, package, or scope. Missing class or package names return warnings with suggestions. Use method_source_search for source text, method_equivalent_search for equivalent ASTs, method_implementor_search for selector implementors, method_sender_search for selector sends, method_class_reference_search for class binding references, and method_variable_reference_search for variable references.'
]

{ #category : 'defaults' }
MCPToolSearchMethodMetadata >> defaultInputSchema [

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
			               'Maximum number of matching methods to return. Use 0 to request counts only.').
	^ self queryInputSchemaWithProperties: properties
]

{ #category : 'defaults' }
MCPToolSearchMethodMetadata >> defaultTitle [

	^ 'Search Method Metadata'
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
MCPToolSearchMethodMetadata >> searchRequestFromToolRequest: request [

	^ MCPMethodSearchRequest fromMetadataRequest: request tool: self
]
