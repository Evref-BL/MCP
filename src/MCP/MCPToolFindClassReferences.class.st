Class {
	#name : 'MCPToolFindClassReferences',
	#superclass : 'MCPToolFindMethodsFocusedLookup',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolFindClassReferences class >> toolName [

	^ 'method_class_reference_search'
]

{ #category : 'defaults' }
MCPToolFindClassReferences >> defaultDescription [

	^ 'Search methods that reference a class binding. Use method_metadata_search for general method metadata, or method_source_search for source text.'
]

{ #category : 'defaults' }
MCPToolFindClassReferences >> defaultTitle [

	^ 'Search Class References'
]

{ #category : 'private - schema' }
MCPToolFindClassReferences >> lookupArgumentDescription [

	^ 'The class binding name whose method references should be returned.'
]

{ #category : 'private - schema' }
MCPToolFindClassReferences >> lookupArgumentName [

	^ 'className'
]

{ #category : 'private - template' }
MCPToolFindClassReferences >> queryEntriesForQueryRequest: queryRequest [

	^ self
		  classReferenceEntriesForClassNamed:
		  (self requiredLookupPatternFromQueryRequest: queryRequest)
		  queryRequest: queryRequest
]
