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

{ #category : 'metadata' }
MCPToolSearchMethods >> title [

	^ 'Search Method Metadata'
]
