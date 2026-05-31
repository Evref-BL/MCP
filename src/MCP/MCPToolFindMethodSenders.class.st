Class {
	#name : 'MCPToolFindMethodSenders',
	#superclass : 'MCPToolFindMethodsFocusedLookup',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolFindMethodSenders class >> toolName [

	^ 'method_sender_search'
]

{ #category : 'defaults' }
MCPToolFindMethodSenders >> defaultDescription [

	^ 'Search methods that send a selector. Use method_search for general method metadata, or method_source_search for source text.'
]

{ #category : 'defaults' }
MCPToolFindMethodSenders >> defaultTitle [

	^ 'Search Method Senders'
]

{ #category : 'private - schema' }
MCPToolFindMethodSenders >> lookupArgumentDescription [

	^ 'The selector whose senders should be returned.'
]

{ #category : 'private - schema' }
MCPToolFindMethodSenders >> lookupArgumentName [

	^ 'selector'
]

{ #category : 'private - template' }
MCPToolFindMethodSenders >> queryEntriesForQueryRequest: queryRequest [

	^ self
		  selectorReferenceEntriesForSelector:
		  (self requiredLookupPatternFromQueryRequest: queryRequest)
		  queryRequest: queryRequest
]
