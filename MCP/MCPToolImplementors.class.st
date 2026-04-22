Class {
	#name : 'MCPToolImplementors',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'executing' }
MCPToolImplementors >> executeWithArguments: arguments [

	| caseSensitive data endIndex entries filterPattern filterMode includeSource limit offset pagedEntries query requestedScope selectorString startIndex totalCount truncated |
	selectorString := self selectorStringFrom: arguments.
	filterPattern := self stringArgumentNamed: 'filter' in: arguments.
	filterMode := self normalizedFilterModeFrom: arguments.
	caseSensitive := self
		                 booleanArgumentNamed: 'caseSensitive'
		                 in: arguments
		                 default: false.
	includeSource := self
		                 booleanArgumentNamed: 'includeSource'
		                 in: arguments
		                 default: false.
	limit := self
		         nonNegativeIntegerArgumentNamed: 'limit'
		         in: arguments
		         default: 100.
	offset := self
		          nonNegativeIntegerArgumentNamed: 'offset'
		          in: arguments
		          default: 0.
	requestedScope := (self stringArgumentNamed: 'scope' in: arguments)
		                  ifNil: [ 'image' ].
	^ [
	  query := self compiledMethodScopeQueryFromArguments: arguments.
	  entries := self
		             compiledMethodEntriesFrom:
			             (query compiledMethods select: [ :eachMethod |
				              eachMethod selector = selectorString asSymbol ])
				             asArray
		             filter: filterPattern
		             filterMode: filterMode
		             caseSensitive: caseSensitive
		             includeSource: includeSource.
	  totalCount := entries size.
	  startIndex := offset + 1.
	  pagedEntries := (startIndex > totalCount or: [ limit = 0 ])
		                  ifTrue: [ #(  ) ]
		                  ifFalse: [
			                  endIndex := totalCount min: offset + limit.
			                  (entries copyFrom: startIndex to: endIndex)
				                  asArray ].
	  truncated := offset + pagedEntries size < totalCount.
	  data := {
		          (#selector -> selectorString).
		          (#scope -> query scope).
		          (#side -> query side).
		          (#sourceIncluded -> includeSource).
		          (#packageNames -> query packageNames).
		          (#classNames -> query classNames).
		          (#returnedCount -> pagedEntries size).
		          (#totalCount -> totalCount).
		          (#offset -> offset).
		          (#limit -> limit).
		          (#truncated -> truncated).
		          (#implementors -> pagedEntries) } asDictionary.
	  self
		  successResultText: (self
				   successSummaryForSelector: selectorString
				   scope: query scope
				   returnedCount: pagedEntries size
				   totalCount: totalCount
				   truncated: truncated)
		  data: data ]
		  on: Error
		  do: [ :error |
			  self
				  errorResultText: (self
						   failureMessageForSelector: selectorString
						   scope: requestedScope
						   error: error)
				  details: {
						  (#errorClass -> error class name).
						  (#message -> error messageText).
						  (#selector -> selectorString).
						  (#scope -> requestedScope) } asDictionary ]
]

{ #category : 'private - results' }
MCPToolImplementors >> failureMessageForSelector: selectorString scope: scope error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to find implementors for #';
			  nextPutAll: selectorString;
			  nextPutAll: ' [scope=';
			  nextPutAll: scope;
			  nextPutAll: '] (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'private - schema' }
MCPToolImplementors >> implementorEntrySchema [

	^ MCPStructureProperties new
		  name: 'implementor';
		  type: 'object';
		  description: 'A method implementing the requested selector.';
		  properties: {
				  (self
					   schemaPropertyNamed: 'selector'
					   type: 'string'
					   description: 'The implemented selector.').
				  (self
					   schemaPropertyNamed: 'className'
					   type: 'string'
					   description: 'The base class that defines the implementor.').
				  ((self
					    schemaPropertyNamed: 'side'
					    type: 'string'
					    description: 'The side on which the implementor is defined.')
					   enum: #( 'instance' 'class' );
					   yourself).
				  (self
					   schemaPropertyNamed: 'packageName'
					   type: 'string'
					   description: 'The package that owns the method.').
				  (self
					   schemaPropertyNamed: 'isExtension'
					   type: 'boolean'
					   description:
					   'Whether the method is an extension on its class package.').
				  (self
					   schemaPropertyNamed: 'protocol'
					   type: 'string'
					   description:
					   'The protocol/category containing the implementor.').
				  (self
					   schemaPropertyNamed: 'source'
					   type: 'string'
					   description:
					   'The formatted source code of the implementor when includeSource=true.') };
		  required:
			  #( 'selector' 'className' 'side' 'packageName' 'isExtension'
			     'protocol' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'initialization' }
MCPToolImplementors >> initialize [

	| classNamesProperty implementorsProperty packageNamesProperty scopeProperty sideProperty |
	super initialize.
	name := 'pharo-implementors'.
	title := 'Find Pharo Implementors'.
	description := 'Find implementors of a selector in the running Pharo image, optionally scoped to packages, hierarchies, or specific classes.'.
	scopeProperty := MCPStructureProperties new
		                 name: 'scope';
		                 type: 'string';
		                 description:
			                 'Where to search for implementors. Defaults to image.';
		                 enum: #( 'image' 'packages' 'hierarchy' 'classes' );
		                 yourself.
	sideProperty := MCPStructureProperties new
		                name: 'side';
		                type: 'string';
		                description:
			                'Which method side to search. Defaults to both.';
		                enum: #( 'instance' 'class' 'both' );
		                yourself.
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
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: {
				               (MCPStructureProperties new
					                name: 'selector';
					                type: 'string';
					                description:
						                'The selector whose implementors should be found.';
					                yourself).
				               scopeProperty.
				               sideProperty.
				               packageNamesProperty.
				               classNamesProperty.
				               (MCPStructureProperties new
					                name: 'filter';
					                type: 'string';
					                description:
						                'Optional filter applied to selector, class, package, protocol, method reference, and source text.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'filterMode';
					                type: 'string';
					                description:
						                'How the filter is matched. Defaults to substring.';
					                enum: #( 'substring' 'prefix' 'exact' 'regex' );
					                yourself).
				               (MCPStructureProperties new
					                name: 'caseSensitive';
					                type: 'boolean';
					                description:
						                'Whether filter matching is case-sensitive. Defaults to false.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'includeSource';
					                type: 'boolean';
					                description:
						                'Whether to include implementor source code in each result entry. Defaults to false.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'limit';
					                type: 'integer';
					                description:
						                'Maximum number of matching implementors to return. Defaults to 100. Use 0 to request counts only.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'offset';
					                type: 'integer';
					                description:
						                'Zero-based pagination offset applied after filtering. Defaults to 0.';
					                yourself) };
		               required: #( 'selector' );
		               yourself.
	implementorsProperty := self
		                        schemaPropertyNamed: 'implementors'
		                        type: 'array'
		                        description:
		                        'The implementors returned for the requested page.'.
	implementorsProperty items: self implementorEntrySchema.
	outputSchema := self
		                standardOutputSchemaForDataProperties: {
				                (self
					                 schemaPropertyNamed: 'selector'
					                 type: 'string'
					                 description: 'The selector that was searched.').
				                ((self
					                  schemaPropertyNamed: 'scope'
					                  type: 'string'
					                  description:
						                  'The scope used to search for implementors.')
					                 enum:
						                 #( 'image' 'packages' 'hierarchy' 'classes' );
					                 yourself).
				                ((self
					                  schemaPropertyNamed: 'side'
					                  type: 'string'
					                  description: 'The searched method side.')
					                 enum: #( 'instance' 'class' 'both' );
					                 yourself).
				                (self
					                 schemaPropertyNamed: 'sourceIncluded'
					                 type: 'boolean'
					                 description:
					                 'Whether implementor source was included in the returned entries.').
				                packageNamesProperty.
				                classNamesProperty.
				                (self
					                 integerSchemaPropertyNamed: 'returnedCount'
					                 description:
					                 'The number of implementors returned in this page.').
				                (self
					                 integerSchemaPropertyNamed: 'totalCount'
					                 description:
					                 'The total number of matching implementors before pagination.').
				                (self
					                 integerSchemaPropertyNamed: 'offset'
					                 description:
					                 'The zero-based pagination offset that was applied.').
				                (self
					                 integerSchemaPropertyNamed: 'limit'
					                 description:
					                 'The maximum number of implementors requested.').
				                (self
					                 schemaPropertyNamed: 'truncated'
					                 type: 'boolean'
					                 description:
					                 'Whether additional matching implementors exist beyond the returned page.').
				                implementorsProperty }
		                required:
			                #( 'selector' 'scope' 'side' 'sourceIncluded'
			                   'packageNames' 'classNames' 'returnedCount'
			                   'totalCount' 'offset' 'limit' 'truncated'
			                   'implementors' ).
	icons := {  }
]

{ #category : 'private - results' }
MCPToolImplementors >> successSummaryForSelector: selectorString scope: scope returnedCount: returnedCount totalCount: totalCount truncated: truncated [

	^ String streamContents: [ :stream |
		  stream
			  print: returnedCount;
			  nextPutAll: ' implementors returned for #';
			  nextPutAll: selectorString;
			  nextPutAll: ' [scope=';
			  nextPutAll: scope;
			  nextPutAll: '] (';
			  print: totalCount;
			  nextPutAll: ' matched'.
		  truncated ifTrue: [ stream nextPutAll: ', more available' ].
		  stream nextPutAll: ').' ]
]
