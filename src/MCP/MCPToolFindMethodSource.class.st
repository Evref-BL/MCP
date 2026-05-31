Class {
	#name : 'MCPToolFindMethodSource',
	#superclass : 'MCPToolFindMethods',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolFindMethodSource class >> toolName [

	^ 'method_source_search'
]

{ #category : 'defaults' }
MCPToolFindMethodSource >> defaultDescription [

	^ 'Search methods by source text. Use method_metadata_search for method metadata queries; use method_equivalent_search for equivalent AST matches.'
]

{ #category : 'private - request' }
MCPToolFindMethodSource >> defaultFilterMode [

	^ 'substring'
]

{ #category : 'private - request' }
MCPToolFindMethodSource >> defaultFilterTargets [

	^ #( 'source' )
]

{ #category : 'defaults' }
MCPToolFindMethodSource >> defaultInputSchema [

	| properties |
	properties := self methodQueryScopeInputProperties , {
		              (self filterSchemaPropertyWithDescription:
			               'Source text to match in method bodies.').
		              (self
			               filterModeSchemaPropertyWithDescription:
			               'How source text filtering is matched.'
			               values: self supportedFilterModes).
		              (self caseSensitiveSchemaPropertyWithDescription:
			               'Whether source text matching is case-sensitive.').
		              (self includeSourceSchemaPropertyWithDescription:
			               'Whether to include method source code in each result entry.') }
	              , (self paginationInputPropertiesWithLimitDescription:
			               'Maximum number of matching methods to return. Use 0 to request counts only.').
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: properties;
		  required: #( 'filter' );
		  yourself
]

{ #category : 'defaults' }
MCPToolFindMethodSource >> defaultTitle [

	^ 'Search Method Source'
]

{ #category : 'private - template' }
MCPToolFindMethodSource >> queryEntriesForQueryRequest: queryRequest [

	queryRequest requiredFilterPatternForTool: self.
	^ super queryEntriesForQueryRequest: queryRequest
]

{ #category : 'private - request' }
MCPToolFindMethodSource >> supportedFilterTargets [

	^ #( 'source' )
]
