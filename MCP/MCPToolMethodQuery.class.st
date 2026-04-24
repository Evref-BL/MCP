"
Shared base class for query tools that return methods. It factors common scope, filtering, and schema behavior for method results.
"
Class {
	#name : 'MCPToolMethodQuery',
	#superclass : 'MCPToolQuery',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolMethodQuery class >> isAbstract [

	^ self = MCPToolMethodQuery
]

{ #category : 'private - schema' }
MCPToolMethodQuery >> methodEntrySchemaNamed: entryName description: entryDescription subjectDescription: subjectDescription selectorDescription: selectorDescription sourceDescription: sourceDescription [

	^ MCPStructureProperties new
		  name: entryName;
		  type: 'object';
		  description: entryDescription;
		  properties: {
				  (self
					   schemaPropertyNamed: 'selector'
					   type: 'string'
					   description: selectorDescription).
				  (self
					   schemaPropertyNamed: 'className'
					   type: 'string'
					   description:
						   'The base class that defines the ' , subjectDescription , '.').
				  (self
					   stringEnumSchemaPropertyNamed: 'side'
					   description:
						   'The side on which the ' , subjectDescription
						   , ' is defined.'
					   values: #( 'instance' 'class' )).
				  (self
					   schemaPropertyNamed: 'packageName'
					   type: 'string'
					   description:
						   'The package that owns the ' , subjectDescription , '.').
				  (self
					   booleanSchemaPropertyNamed: 'isExtension'
					   description: 'Whether the ' , subjectDescription
						   , ' is an extension on its class package.').
				  (self
					   schemaPropertyNamed: 'protocol'
					   type: 'string'
					   description:
						   'The protocol/category containing the ' , subjectDescription
						   , '.').
				  (self
					   schemaPropertyNamed: 'source'
					   type: 'string'
					   description: sourceDescription) };
		  required:
			  #( 'selector' 'className' 'side' 'packageName' 'isExtension'
			     'protocol' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - schema' }
MCPToolMethodQuery >> methodQueryFilteringInputPropertiesWithFilterDescription: filterDescription extraProperties: extraProperties includeSourceDescription: includeSourceDescription limitDescription: limitDescription [

	| properties |
	properties := OrderedCollection new.
	properties add: (self
			 schemaPropertyNamed: 'filter'
			 type: 'string'
			 description: filterDescription).
	extraProperties ifNotNil: [ properties addAll: extraProperties ].
	properties add: (self
			 stringEnumSchemaPropertyNamed: 'filterMode'
			 description:
				 'How the filter is matched or interpreted. Defaults to '
				 , self defaultFilterMode , '.'
			 values: self supportedFilterModes
			 default: self defaultFilterMode).
	properties add: (self
			 booleanSchemaPropertyNamed: 'caseSensitive'
			 description:
			 'Whether filter matching is case-sensitive. Defaults to true.'
			 default: true).
	properties add: (self
			 booleanSchemaPropertyNamed: 'includeSource'
			 description: includeSourceDescription
			 default: false).
	properties add: (self
			 integerSchemaPropertyNamed: 'limit'
			 description: limitDescription
			 default: 100).
	properties add: (self
			 integerSchemaPropertyNamed: 'offset'
			 description:
			 'Zero-based pagination offset applied after filtering. Defaults to 0.'
			 default: 0).
	^ properties asArray
]

{ #category : 'private - request' }
MCPToolMethodQuery >> methodQueryParametersFromRequest: request [

	^ {
		  (#filterPattern -> (request stringArgumentNamed: 'filter')).
		  (#filterMode -> (self filterModeFromRequest: request)).
		  (#caseSensitive
		   -> (request booleanArgumentNamed: 'caseSensitive' default: true)).
		  (#includeSource
		   -> (request booleanArgumentNamed: 'includeSource' default: false)).
		  (#limit
		   ->
		   (request nonNegativeIntegerArgumentNamed: 'limit' default: 100)).
		  (#offset
		   -> (request nonNegativeIntegerArgumentNamed: 'offset' default: 0)).
		  (#query -> (self methodScopeQueryFromRequest: request)) }
		  asDictionary
]

{ #category : 'private - results' }
MCPToolMethodQuery >> methodQueryResultDataForPage: page entriesKey: entriesKey [

	^ self queryResultDataFrom: nil page: page entriesKey: entriesKey
]

{ #category : 'private - schema' }
MCPToolMethodQuery >> methodQueryScopeInputPropertiesWithScopeDescription: scopeDescription [

	| scopeProperty sideProperty packageNamesProperty classNamesProperty |
	scopeProperty := self
		                 stringEnumSchemaPropertyNamed: 'scope'
		                 description: scopeDescription
		                 values:
		                 #( 'image' 'packages' 'hierarchy' 'classes' )
		                 default: 'image'.
	sideProperty := self
		                stringEnumSchemaPropertyNamed: 'side'
		                description:
		                'Which method side to search. Defaults to both.'
		                values: #( 'instance' 'class' 'both' )
		                default: 'both'.
	packageNamesProperty := self
		                        stringArraySchemaNamed: 'packageNames'
		                        description:
		                        'The package names that define the packages scope. Required when scope=packages.'
		                        itemDescription: 'A package name.'.
	classNamesProperty := self
		                      stringArraySchemaNamed: 'classNames'
		                      description:
		                      'The class names that define the classes or hierarchy scope. Required when scope=classes or scope=hierarchy.'
		                      itemDescription: 'A class name.'.
	^ {
		  scopeProperty.
		  sideProperty.
		  packageNamesProperty.
		  classNamesProperty }
]

{ #category : 'private - schema' }
MCPToolMethodQuery >> supportedFilterModes [

	^ #( 'substring' 'prefix' 'exact' 'regex' )
]
