"
Concrete method_class_reference_search tool. It searches methods that reference a class binding through MCPToolMethodLookupOperation.
"
Class {
	#name : 'MCPToolSearchClassReferences',
	#superclass : 'MCPToolMethodLookupOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolSearchClassReferences class >> toolName [

	^ 'method_class_reference_search'
]

{ #category : 'metadata' }
MCPToolSearchClassReferences >> description [

	^ 'Search methods that reference a class binding. Use method_metadata_search for general method metadata, or method_source_search for source text.'
]

{ #category : 'private - schema' }
MCPToolSearchClassReferences >> lookupArgumentDescription [

	^ 'The class binding name whose method references should be returned.'
]

{ #category : 'private - schema' }
MCPToolSearchClassReferences >> lookupArgumentName [

	^ 'className'
]

{ #category : 'private - template' }
MCPToolSearchClassReferences >> queryEntriesForQueryRequest: queryRequest [

	^ self classReferenceEntriesForClassNamed: (self requiredLookupPatternFromQueryRequest: queryRequest) queryRequest: queryRequest
]

{ #category : 'metadata' }
MCPToolSearchClassReferences >> title [

	^ 'Search Class References'
]
