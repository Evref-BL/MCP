Class {
	#name : 'MCPToolFindEquivalentMethods',
	#superclass : 'MCPToolFindMethods',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolFindEquivalentMethods class >> toolName [

	^ 'method_equivalent_search'
]

{ #category : 'defaults' }
MCPToolFindEquivalentMethods >> defaultDescription [

	^ 'Search methods whose AST is equivalent to a referenced method. Use method_search only when you need recursive where composition.'
]

{ #category : 'defaults' }
MCPToolFindEquivalentMethods >> defaultInputSchema [

	| properties |
	properties := self methodQueryScopeInputProperties , {
		              self scopeModeSchemaProperty.
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
			               'Whether the reference method is on the class side.'
			               default: false).
		              (self includeSourceSchemaPropertyWithDescription:
			               'Whether to include method source code in each result entry.') }
	              , (self paginationInputPropertiesWithLimitDescription:
			               'Maximum number of matching methods to return. Use 0 to request counts only.').
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: properties;
		  required: #( 'className' 'selector' );
		  yourself
]

{ #category : 'defaults' }
MCPToolFindEquivalentMethods >> defaultTitle [

	^ 'Search Equivalent Methods'
]

{ #category : 'private - request' }
MCPToolFindEquivalentMethods >> methodReferenceSpecFromToolRequest: request [

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
MCPToolFindEquivalentMethods >> queryRequestFromToolRequest: request [

	| queryRequest |
	queryRequest := super queryRequestFromToolRequest: request.
	queryRequest whereSpec: (MCPWhereSpec equivalentTo:
			 (self methodReferenceSpecFromToolRequest: request)).
	^ queryRequest
]
