Class {
	#name : 'MCPToolFindMethodImplementors',
	#superclass : 'MCPToolFindMethodsFocusedLookup',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolFindMethodImplementors class >> toolName [

	^ 'method_implementor_search'
]

{ #category : 'defaults' }
MCPToolFindMethodImplementors >> defaultDescription [

	^ 'Search methods that implement a selector. Use method_search for general method metadata or source search.'
]

{ #category : 'defaults' }
MCPToolFindMethodImplementors >> defaultTitle [

	^ 'Search Method Implementors'
]

{ #category : 'private - schema' }
MCPToolFindMethodImplementors >> lookupArgumentDescription [

	^ 'The selector whose implementors should be returned.'
]

{ #category : 'private - schema' }
MCPToolFindMethodImplementors >> lookupArgumentName [

	^ 'selector'
]

{ #category : 'private - template' }
MCPToolFindMethodImplementors >> queryEntriesForQueryRequest: queryRequest [

	^ self
		  implementorEntriesForSelector:
		  (self requiredLookupPatternFromQueryRequest: queryRequest)
		  queryRequest: queryRequest
]
