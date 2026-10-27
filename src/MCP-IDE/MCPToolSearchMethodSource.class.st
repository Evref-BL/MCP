"
Concrete method_source_search tool. It searches methods by source text through MCPToolMethodSearch.
"
Class {
	#name : 'MCPToolSearchMethodSource',
	#superclass : 'MCPToolMethodSearch',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolSearchMethodSource class >> toolName [

	^ 'method_source_search'
]

{ #category : 'private - methods' }
MCPToolSearchMethodSource >> addMatchContextTo: entry sourceText: sourceText matcher: matcher queryRequest: queryRequest [
	"A hit on source text is read by seeing the line that matched, not by fetching the whole method."

	| lines index |
	sourceText ifNil: [ ^ self ].
	lines := sourceText lines.
	index := lines findFirst: [ :each | matcher value: each ].
	index isZero ifTrue: [ ^ self ].
	entry at: #lineNumber put: index.
	entry at: #line put: (lines at: index) trimBoth
]

{ #category : 'metadata' }
MCPToolSearchMethodSource >> buildInputSchema [

	| properties |
	properties := self methodQueryScopeInputProperties , {
		              (self filterSchemaPropertyWithDescription:
			               'Source text to match in method bodies. Case matters, as it does in code.').
		              (self
			               filterModeSchemaPropertyWithDescription:
			               'How filter is matched against the source: anywhere in it, at its start, as the whole of it, or as a regular expression.'
			               values: self supportedFilterModes).
		              self offsetInputProperty }.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: properties;
		  required: #( 'filter' );
		  yourself
]

{ #category : 'metadata' }
MCPToolSearchMethodSource >> defaultExposure [

	^ 'static'
]

{ #category : 'private - request' }
MCPToolSearchMethodSource >> defaultFilterMode [

	^ 'substring'
]

{ #category : 'metadata' }
MCPToolSearchMethodSource >> description [

	^ 'Search methods by source text. Use method_search for selector, protocol, class, or package metadata.'
]

{ #category : 'private - filtering' }
MCPToolSearchMethodSource >> filterTextsForMethodEntry: anEntry sourceText: sourceText [

	^ { sourceText }
]

{ #category : 'private - filtering' }
MCPToolSearchMethodSource >> needsSourceForFiltering [

	^ true
]

{ #category : 'private - template' }
MCPToolSearchMethodSource >> queryEntriesForQueryRequest: queryRequest [

	queryRequest requiredFilterPatternForTool: self.
	^ super queryEntriesForQueryRequest: queryRequest
]

{ #category : 'private - template' }
MCPToolSearchMethodSource >> searchRequestFromToolRequest: request [

	^ MCPMethodSearchRequest fromRequest: request tool: self
]

{ #category : 'private - schema' }
MCPToolSearchMethodSource >> supportedFilterModes [

	^ #( 'substring' 'regex' )
]

{ #category : 'metadata' }
MCPToolSearchMethodSource >> title [

	^ 'Search Method Source'
]
