Class {
	#name : 'MCPToolFindVariableReferences',
	#superclass : 'MCPToolFindMethodsFocusedLookup',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolFindVariableReferences class >> toolName [

	^ 'find-variable-references'
]

{ #category : 'defaults' }
MCPToolFindVariableReferences >> defaultDescription [

	^ 'Find methods that reference a variable. Use find-methods for general method metadata or source search.'
]

{ #category : 'defaults' }
MCPToolFindVariableReferences >> defaultTitle [

	^ 'Find Variable References'
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
