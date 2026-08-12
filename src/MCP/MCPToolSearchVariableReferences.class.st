"
Concrete method_variable_reference_search tool. It searches methods that reference a variable through MCPToolMethodLookupOperation.
"
Class {
	#name : 'MCPToolSearchVariableReferences',
	#superclass : 'MCPToolMethodLookupOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolSearchVariableReferences class >> toolName [

	^ 'method_variable_reference_search'
]

{ #category : 'metadata' }
MCPToolSearchVariableReferences >> description [

	^ 'Search methods that reference a variable. Use method_metadata_search for general method metadata, or method_source_search for source text.'
]

{ #category : 'private - schema' }
MCPToolSearchVariableReferences >> lookupArgumentDescription [

	^ 'The variable name whose method references should be returned.'
]

{ #category : 'private - schema' }
MCPToolSearchVariableReferences >> lookupArgumentName [

	^ 'variableName'
]

{ #category : 'private - template' }
MCPToolSearchVariableReferences >> queryEntriesForQueryRequest: queryRequest [

	^ self
		  variableReferenceEntriesForVariableNamed: (self requiredLookupPatternFromQueryRequest: queryRequest)
		  queryRequest: queryRequest
]

{ #category : 'metadata' }
MCPToolSearchVariableReferences >> title [

	^ 'Search Variable References'
]
