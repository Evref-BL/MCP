"
Abstract base for method lookup tools that search from one required lookup argument, such as selector, class binding, or variable name.
"
Class {
	#name : 'MCPToolMethodLookupOperation',
	#superclass : 'MCPToolMethodSearch',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolMethodLookupOperation >> buildInputSchema [

	^ MCPStructureInputSchema
		  properties: self methodQueryScopeInputProperties , { self lookupArgumentSchemaProperty } , self extraInputProperties
			  , { self offsetInputProperty }
		  required: { self lookupArgumentName }
]

{ #category : 'private - schema' }
MCPToolMethodLookupOperation >> extraInputProperties [
	"What a lookup takes beyond the name it looks up. A tool declares its own."

	^ #(  )
]

{ #category : 'private - request' }
MCPToolMethodLookupOperation >> filterArgumentName [

	^ self lookupArgumentName
]

{ #category : 'private - request' }
MCPToolMethodLookupOperation >> filterPatternFromRequest: request [

	^ (request stringArgumentNamed: self lookupArgumentName) ifNotNil: [ :value | value trimBoth ]
]

{ #category : 'private - schema' }
MCPToolMethodLookupOperation >> lookupArgumentDescription [

	^ self subclassResponsibility
]

{ #category : 'private - schema' }
MCPToolMethodLookupOperation >> lookupArgumentName [

	^ self subclassResponsibility
]

{ #category : 'private - schema' }
MCPToolMethodLookupOperation >> lookupArgumentSchemaProperty [

	^ MCPStructureProperties new
		  name: self lookupArgumentName;
		  type: 'string';
		  description: self lookupArgumentDescription;
		  yourself
]
