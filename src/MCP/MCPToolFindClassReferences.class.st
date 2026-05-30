Class {
	#name : 'MCPToolFindClassReferences',
	#superclass : 'MCPToolFindMethodsFocusedLookup',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolFindClassReferences class >> toolName [

	^ 'find-class-references'
]

{ #category : 'defaults' }
MCPToolFindClassReferences >> defaultDescription [

	^ 'Find methods that reference a class binding. Use find-methods for general method metadata or source search.'
]

{ #category : 'defaults' }
MCPToolFindClassReferences >> defaultTitle [

	^ 'Find Class References'
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
