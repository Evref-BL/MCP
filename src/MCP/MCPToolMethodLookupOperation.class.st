"
Abstract base for method lookup tools that search from one required lookup argument, such as selector, class binding, or variable name.
"
Class {
	#name : 'MCPToolMethodLookupOperation',
	#superclass : 'MCPToolMethodSearch',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolMethodLookupOperation class >> isAbstract [

	^ self = MCPToolMethodLookupOperation
]

{ #category : 'metadata' }
MCPToolMethodLookupOperation >> buildInputSchema [

	| properties |
	properties := self methodQueryScopeInputProperties , {
		              self lookupArgumentSchemaProperty.
		              (self includeSourceSchemaPropertyWithDescription: 'Whether to include method source code in each result entry.') }
	              ,
	              (self paginationInputPropertiesWithLimitDescription:
		               'Maximum number of methods to return. Use 0 to return no entries.').
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: properties;
		  required: { self lookupArgumentName };
		  yourself
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
