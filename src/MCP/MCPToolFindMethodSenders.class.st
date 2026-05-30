Class {
	#name : 'MCPToolFindMethodSenders',
	#superclass : 'MCPToolFindMethodsFocusedLookup',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolFindMethodSenders class >> toolName [

	^ 'find-method-senders'
]

{ #category : 'defaults' }
MCPToolFindMethodSenders >> defaultDescription [

	^ 'Find methods that send a selector. Use find-methods for general method metadata or source search.'
]

{ #category : 'defaults' }
MCPToolFindMethodSenders >> defaultTitle [

	^ 'Find Method Senders'
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
