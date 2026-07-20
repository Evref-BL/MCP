"
Concrete method_implementor_search tool. It searches methods that implement a selector through MCPToolMethodLookupOperation.
"
Class {
	#name : 'MCPToolSearchMethodImplementors',
	#superclass : 'MCPToolMethodLookupOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolSearchMethodImplementors class >> toolName [

	^ 'method_implementor_search'
]

{ #category : 'metadata' }
MCPToolSearchMethodImplementors >> defaultExposure [

	^ 'static'
]

{ #category : 'metadata' }
MCPToolSearchMethodImplementors >> description [

	^ 'Search methods that implement a selector. Use method_metadata_search for general method metadata, or method_source_search for source text.'
]

{ #category : 'private - schema' }
MCPToolSearchMethodImplementors >> lookupArgumentDescription [

	^ 'The selector whose implementors should be returned.'
]

{ #category : 'private - schema' }
MCPToolSearchMethodImplementors >> lookupArgumentName [

	^ 'selector'
]

{ #category : 'private - template' }
MCPToolSearchMethodImplementors >> queryEntriesForQueryRequest: queryRequest [

	^ self
		  implementorEntriesForSelector:
		  (self requiredLookupPatternFromQueryRequest: queryRequest)
		  queryRequest: queryRequest
]

{ #category : 'metadata' }
MCPToolSearchMethodImplementors >> title [

	^ 'Search Method Implementors'
]
