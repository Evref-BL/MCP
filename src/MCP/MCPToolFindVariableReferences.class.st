Class {
	#name : 'MCPToolFindVariableReferences',
	#superclass : 'MCPToolFindMethodsFocusedLookup',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolFindVariableReferences class >> toolName [

	^ 'method_variable_reference_search'
]

{ #category : 'defaults' }
MCPToolFindVariableReferences >> defaultDescription [

	^ 'Search methods that reference a variable. Use method_search for general method metadata, or method_source_search for source text.'
]

{ #category : 'defaults' }
MCPToolFindVariableReferences >> defaultTitle [

	^ 'Search Variable References'
]

{ #category : 'private - schema' }
MCPToolFindVariableReferences >> lookupArgumentDescription [

	^ 'The variable name whose method references should be returned.'
]

{ #category : 'private - schema' }
MCPToolFindVariableReferences >> lookupArgumentName [

	^ 'variableName'
]

{ #category : 'private - template' }
MCPToolFindVariableReferences >> queryEntriesForQueryRequest: queryRequest [

	^ self
		  variableReferenceEntriesForVariableNamed:
		  (self requiredLookupPatternFromQueryRequest: queryRequest)
		  queryRequest: queryRequest
]
