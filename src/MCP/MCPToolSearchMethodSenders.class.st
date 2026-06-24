"
Concrete method_sender_search tool. It searches methods that send a selector through MCPToolMethodLookupOperation.
"
Class {
	#name : 'MCPToolSearchMethodSenders',
	#superclass : 'MCPToolMethodLookupOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolSearchMethodSenders class >> toolName [

	^ 'method_sender_search'
]

{ #category : 'metadata' }
MCPToolSearchMethodSenders >> description [

	^ 'Search methods that send a selector. Use method_metadata_search for general method metadata, or method_source_search for source text.'
]

{ #category : 'private - schema' }
MCPToolSearchMethodSenders >> lookupArgumentDescription [

	^ 'The selector whose senders should be returned.'
]

{ #category : 'private - schema' }
MCPToolSearchMethodSenders >> lookupArgumentName [

	^ 'selector'
]

{ #category : 'private - template' }
MCPToolSearchMethodSenders >> queryEntriesForQueryRequest: queryRequest [

	^ self
		  selectorReferenceEntriesForSelector:
		  (self requiredLookupPatternFromQueryRequest: queryRequest)
		  queryRequest: queryRequest
]

{ #category : 'metadata' }
MCPToolSearchMethodSenders >> title [

	^ 'Search Method Senders'
]
