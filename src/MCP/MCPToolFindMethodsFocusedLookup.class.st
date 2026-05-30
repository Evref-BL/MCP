Class {
	#name : 'MCPToolFindMethodsFocusedLookup',
	#superclass : 'MCPToolFindMethods',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolFindMethodsFocusedLookup class >> isAbstract [

	^ self = MCPToolFindMethodsFocusedLookup
]

{ #category : 'defaults' }
MCPToolFindMethodsFocusedLookup >> defaultInputSchema [

	| properties |
	properties := self methodQueryScopeInputProperties , {
		              self scopeModeSchemaProperty.
		              self lookupArgumentSchemaProperty.
		              self wherePredicateSchemaProperty.
		              (self includeSourceSchemaPropertyWithDescription:
			               'Whether to include method source code in each result entry.') }
	              , (self paginationInputPropertiesWithLimitDescription:
			               'Maximum number of matching methods to return. Use 0 to request counts only.').
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: properties;
		  required: { self lookupArgumentName };
		  yourself
]

{ #category : 'private - request' }
MCPToolFindMethodsFocusedLookup >> filterPatternFromRequest: request [

	^ (request stringArgumentNamed: self lookupArgumentName)
		  ifNil: [ nil ]
		  ifNotNil: [ :value | value trimBoth ]
]

{ #category : 'private - schema' }
MCPToolFindMethodsFocusedLookup >> lookupArgumentDescription [

	^ self subclassResponsibility
]

{ #category : 'private - schema' }
MCPToolFindMethodsFocusedLookup >> lookupArgumentName [

	^ self subclassResponsibility
]

{ #category : 'private - schema' }
MCPToolFindMethodsFocusedLookup >> lookupArgumentSchemaProperty [

	^ MCPStructureProperties new
		  name: self lookupArgumentName;
		  type: 'string';
		  description: self lookupArgumentDescription;
		  yourself
]

{ #category : 'private - request' }
MCPToolFindMethodsFocusedLookup >> requiredLookupPatternFromQueryRequest: queryRequest [

	| pattern |
	pattern := queryRequest filterPattern.
	(pattern isNil or: [ pattern isEmpty ]) ifTrue: [
			^ MCPInvalidToolInput
				  signalMissingRequiredArgumentNamed: self lookupArgumentName
				  forTool: self ].
	^ pattern
]
