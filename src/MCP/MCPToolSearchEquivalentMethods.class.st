"
Concrete method_equivalent_search tool. It searches for methods with ASTs equivalent to a referenced method through MCPToolMethodSearch.
"
Class {
	#name : 'MCPToolSearchEquivalentMethods',
	#superclass : 'MCPToolMethodSearch',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolSearchEquivalentMethods class >> toolName [

	^ 'method_equivalent_search'
]

{ #category : 'metadata' }
MCPToolSearchEquivalentMethods >> description [

	^ 'Search methods whose AST is equivalent to a referenced method.'
]

{ #category : 'private - methods' }
MCPToolSearchEquivalentMethods >> equivalentEntriesForQueryRequest: queryRequest [

	| referenceMethod |
	referenceMethod := queryRequest referenceMethod.
	^ self
		  methodEntriesFromMethods:
			  (queryRequest scopeQuery methods select: [ :eachMethod |
				   eachMethod equivalentTo: referenceMethod ]) asArray
		  queryRequest: queryRequest
]

{ #category : 'metadata' }
MCPToolSearchEquivalentMethods >> inputSchema [

	| properties |
	properties := self methodQueryScopeInputProperties , {
		              (self
			               schemaPropertyNamed: 'className'
			               type: 'string'
			               description:
			               'The class that defines the reference method.').
		              (self
			               schemaPropertyNamed: 'selector'
			               type: 'string'
			               description: 'The reference method selector.').
		              (self
			               booleanSchemaPropertyNamed: 'classSide'
			               description:
			               'Whether the reference method is on class side.'
			               default: false).
		              (self includeSourceSchemaPropertyWithDescription:
			               'Whether to include method source code in each result entry.') }
	              , (self paginationInputPropertiesWithLimitDescription:
			               'Maximum number of methods to return. Use 0 to return no entries.').
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: properties;
		  required: #( 'className' 'selector' );
		  yourself
]

{ #category : 'private - request' }
MCPToolSearchEquivalentMethods >> methodReferenceSpecFromToolRequest: request [

	| className selector |
	className := request stringArgumentNamed: 'className'.
	className ifNil: [
			^ MCPInvalidToolInput
				  signalMissingRequiredArgumentNamed: 'className'
				  forTool: self ].
	selector := request stringArgumentNamed: 'selector'.
	selector ifNil: [
			^ MCPInvalidToolInput
				  signalMissingRequiredArgumentNamed: 'selector'
				  forTool: self ].
	^ MCPMethodReferenceSpec
		  className: className
		  selector: selector
		  classSide:
		  (request booleanArgumentNamed: 'classSide' default: false)
]

{ #category : 'private - template' }
MCPToolSearchEquivalentMethods >> queryEntriesForQueryRequest: queryRequest [

	^ self equivalentEntriesForQueryRequest: queryRequest
]

{ #category : 'private - template' }
MCPToolSearchEquivalentMethods >> searchRequestFromToolRequest: request [

	^ MCPSearchEquivalentMethodsRequest fromRequest: request tool: self
]

{ #category : 'metadata' }
MCPToolSearchEquivalentMethods >> title [

	^ 'Search Equivalent Methods'
]
