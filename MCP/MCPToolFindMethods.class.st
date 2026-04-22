Class {
	#name : 'MCPToolFindMethods',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - results' }
MCPToolFindMethods >> errorResultForError: anError scope: scope [

	(anError isKindOf: MCPCommandError) ifTrue: [
		| details |
		details := anError structuredDetails copy.
		details at: #scope put: scope.
		^ self errorResultText: anError messageText details: details ].
	^ self
		  errorResultText:
		  (self failureMessageForScope: scope error: anError)
		  details: {
				  (#errorClass -> anError class name).
				  (#message -> anError messageText).
				  (#scope -> scope) } asDictionary
]

{ #category : 'executing' }
MCPToolFindMethods >> executeWithArguments: arguments [

	| caseSensitive data endIndex entries filterPattern filterMode includeSource limit offset pagedEntries query requestedScope startIndex totalCount truncated |
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
		                  ifNil: [ 'image' ]
		                  ifNotNil: [ :scope | scope asLowercase ].
	^ [
	  query := self compiledMethodScopeQueryFromArguments: arguments.
	  entries := self
		             compiledMethodEntriesFrom: query compiledMethods
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
		          (#methods -> pagedEntries) } asDictionary.
	  self
		  successResultText: (self
				   successSummaryForScope: query scope
				   returnedCount: pagedEntries size
				   totalCount: totalCount
				   truncated: truncated)
		  data: data ]
		  on: Error
		  do: [ :error |
		  self errorResultForError: error scope: requestedScope ]
]

{ #category : 'private - results' }
MCPToolFindMethods >> failureMessageForScope: scope error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to query methods [scope=';
			  nextPutAll: scope;
			  nextPutAll: '] (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'initialization' }
MCPToolFindMethods >> initialize [

	| classNamesProperty filterModeProperty methodsProperty packageNamesProperty scopeProperty sideProperty |
	super initialize.
	name := 'pharo-find-methods'.
	title := 'Find Pharo Methods'.
	description := 'Find methods in the running Pharo image, optionally scoped to packages, hierarchies, or specific classes.'.
	scopeProperty := MCPStructureProperties new
		                 name: 'scope';
		                 type: 'string';
		                 description:
			                 'Where to search for methods. Defaults to image.';
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
	filterModeProperty := MCPStructureProperties new
		                      name: 'filterMode';
		                      type: 'string';
		                      description:
			                      'How the filter is matched. Defaults to substring.';
		                      enum:
			                      #( 'substring' 'prefix' 'exact' 'regex' );
		                      yourself.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: {
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
				               filterModeProperty.
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
						                'Whether to include method source code in each result entry. Defaults to false.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'limit';
					                type: 'integer';
					                description:
						                'Maximum number of matching methods to return. Defaults to 100. Use 0 to request counts only.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'offset';
					                type: 'integer';
					                description:
						                'Zero-based pagination offset applied after filtering. Defaults to 0.';
					                yourself) };
		               required: #(  );
		               yourself.
	methodsProperty := self
		                   schemaPropertyNamed: 'methods'
		                   type: 'array'
		                   description:
		                   'The method entries returned for the requested page.'.
	methodsProperty items: self methodEntrySchema.
	outputSchema := self
		                standardOutputSchemaForDataProperties: {
				                ((self
					                  schemaPropertyNamed: 'scope'
					                  type: 'string'
					                  description:
						                  'The scope used to search for methods.')
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
					                 'Whether method source was included in the returned entries.').
				                packageNamesProperty.
				                classNamesProperty.
				                (self
					                 integerSchemaPropertyNamed: 'returnedCount'
					                 description:
					                 'The number of methods returned in this page.').
				                (self
					                 integerSchemaPropertyNamed: 'totalCount'
					                 description:
					                 'The total number of matching methods before pagination.').
				                (self
					                 integerSchemaPropertyNamed: 'offset'
					                 description:
					                 'The zero-based pagination offset that was applied.').
				                (self
					                 integerSchemaPropertyNamed: 'limit'
					                 description:
					                 'The maximum number of methods requested.').
				                (self
					                 schemaPropertyNamed: 'truncated'
					                 type: 'boolean'
					                 description:
					                 'Whether additional matching methods exist beyond the returned page.').
				                methodsProperty }
		                required:
			                #( 'scope' 'side' 'sourceIncluded' 'packageNames'
			                   'classNames' 'returnedCount' 'totalCount'
			                   'offset' 'limit' 'truncated' 'methods' ).
	icons := {  }
]

{ #category : 'private - schema' }
MCPToolFindMethods >> methodEntrySchema [

	^ MCPStructureProperties new
		  name: 'method';
		  type: 'object';
		  description: 'A method matching the query.';
		  properties: {
				  (self
					   schemaPropertyNamed: 'selector'
					   type: 'string'
					   description: 'The selector name.').
				  (self
					   schemaPropertyNamed: 'className'
					   type: 'string'
					   description: 'The base class that defines the method.').
				  ((self
					    schemaPropertyNamed: 'side'
					    type: 'string'
					    description: 'The side on which the method is defined.')
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
					   description: 'The protocol/category containing the method.').
				  (self
					   schemaPropertyNamed: 'source'
					   type: 'string'
					   description:
					   'The formatted source code of the method when includeSource=true.') };
		  required:
			  #( 'selector' 'className' 'side' 'packageName' 'isExtension'
			     'protocol' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - results' }
MCPToolFindMethods >> successSummaryForScope: scope returnedCount: returnedCount totalCount: totalCount truncated: truncated [

	^ String streamContents: [ :stream |
		  stream
			  print: returnedCount;
			  nextPutAll: ' methods found [scope=';
			  nextPutAll: scope;
			  nextPutAll: '] (';
			  print: totalCount;
			  nextPutAll: ' matched'.
		  truncated ifTrue: [ stream nextPutAll: ', more available' ].
		  stream nextPutAll: ').' ]
]
