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

{ #category : 'testing' }
MCPToolMethodLookupOperation class >> isAbstract [

	^ self = MCPToolMethodLookupOperation
]

{ #category : 'metadata' }
MCPToolMethodLookupOperation >> buildInputSchema [

	| properties |
	properties := self methodQueryScopeInputProperties , { self lookupArgumentSchemaProperty } , self extraInputProperties
	              , { self offsetInputProperty }.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: properties;
		  required: { self lookupArgumentName };
		  yourself
]

{ #category : 'private - schema' }
MCPToolMethodLookupOperation >> extraInputProperties [
	"What a lookup takes beyond the name it looks up. A tool declares its own."

	^ #(  )
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

{ #category : 'private - request' }
MCPToolMethodLookupOperation >> requiredLookupPatternFromQueryRequest: queryRequest [

	| pattern |
	pattern := queryRequest filterPattern.
	pattern ifNil: [ ^ MCPInvalidToolInput signalMissingRequiredArgumentNamed: self lookupArgumentName forTool: self ].
	pattern isEmpty ifTrue: [ ^ MCPInvalidToolInput signalMissingRequiredArgumentNamed: self lookupArgumentName forTool: self ].
	^ pattern
]

{ #category : 'private - template' }
MCPToolMethodLookupOperation >> searchRequestFromToolRequest: request [

	^ MCPMethodSearchRequest fromRequest: request tool: self
]
