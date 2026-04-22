Class {
	#name : 'MCPCompiledMethodQueryTool',
	#superclass : 'MCPQueryTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPCompiledMethodQueryTool class >> isAbstract [

	^ self = MCPCompiledMethodQueryTool
]

{ #category : 'private - schema' }
MCPCompiledMethodQueryTool >> compiledMethodEntrySchemaNamed: entryName description: entryDescription subjectDescription: subjectDescription selectorDescription: selectorDescription sourceDescription: sourceDescription [

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
				  ((self
					    schemaPropertyNamed: 'side'
					    type: 'string'
					    description:
						    'The side on which the ' , subjectDescription
						    , ' is defined.')
					   enum: #( 'instance' 'class' );
					   yourself).
				  (self
					   schemaPropertyNamed: 'packageName'
					   type: 'string'
					   description:
					   'The package that owns the ' , subjectDescription , '.').
				  (self
					   schemaPropertyNamed: 'isExtension'
					   type: 'boolean'
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

{ #category : 'private - arguments' }
MCPCompiledMethodQueryTool >> compiledMethodQueryParametersFromArguments: arguments [

	^ {
		  (#filterPattern
		   -> (self stringArgumentNamed: 'filter' in: arguments)).
		  (#filterMode -> (self normalizedFilterModeFrom: arguments)).
		  (#caseSensitive -> (self
			    booleanArgumentNamed: 'caseSensitive'
			    in: arguments
			    default: false)).
		  (#includeSource -> (self
			    booleanArgumentNamed: 'includeSource'
			    in: arguments
			    default: false)).
		  (#limit -> (self
			    nonNegativeIntegerArgumentNamed: 'limit'
			    in: arguments
			    default: 100)).
		  (#offset -> (self
			    nonNegativeIntegerArgumentNamed: 'offset'
			    in: arguments
			    default: 0)).
		  (#query -> (self compiledMethodScopeQueryFromArguments: arguments)) }
		  asDictionary
]

{ #category : 'private - results' }
MCPCompiledMethodQueryTool >> compiledMethodQueryResultDataForParameters: parameters page: page entriesKey: entriesKey extraData: extraData [

	| baseData query |
	query := parameters at: #query.
	baseData := {
		            (#scope -> query scope).
		            (#side -> query side).
		            (#sourceIncluded -> (parameters at: #includeSource)).
		            (#packageNames -> query packageNames).
		            (#classNames -> query classNames) } asDictionary.
	extraData ifNotNil: [
		extraData associationsDo: [ :each |
			baseData at: each key put: each value ] ].
	^ self
		  queryResultDataFrom: baseData
		  page: page
		  entriesKey: entriesKey
]
