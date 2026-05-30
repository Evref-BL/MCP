Class {
	#name : 'MCPToolFindMethodImplementors',
	#superclass : 'MCPToolFindMethodsFocusedLookup',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolFindMethodImplementors class >> toolName [

	^ 'find-method-implementors'
]

{ #category : 'defaults' }
MCPToolFindMethodImplementors >> defaultDescription [

	^ 'Find methods that implement a selector. Use find-methods for general method metadata or source search.'
]

{ #category : 'defaults' }
MCPToolFindMethodImplementors >> defaultTitle [

	^ 'Find Method Implementors'
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
