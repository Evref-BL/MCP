Class {
	#name : 'MCPToolFindMethods',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - methods' }
MCPToolFindMethods >> compiledMethodEntriesFromQuery: query filter: filterPattern filterTargets: filterTargets filterMode: filterMode caseSensitive: caseSensitive includeSource: includeSource [

	| entries matcher needsSourceForFiltering |
	matcher := self
		           matcherForPattern: filterPattern
		           mode: filterMode
		           caseSensitive: caseSensitive.
	needsSourceForFiltering := filterPattern notNil and: [
		                           filterTargets includes: 'source' ].
	entries := OrderedCollection new.
	query compiledMethodsDo: [ :eachMethod |
		| entry info sourceText |
		info := MCPCompiledMethodInfo fromCompiledMethod: eachMethod.
		entry := info asDictionaryIncludingSource: false.
		sourceText := needsSourceForFiltering
			              ifTrue: [ self normalizedSourceText: info source ]
			              ifFalse: [ nil ].
		(filterPattern isNil or: [
			 self
				 matchesFilterOnCompiledMethodEntry: entry
				 sourceText: sourceText
				 matcher: matcher
				 targets: filterTargets ]) ifTrue: [
			includeSource ifTrue: [
				sourceText ifNil: [
					sourceText := self normalizedSourceText: info source ].
				entry at: #source put: sourceText ].
			entries add: entry ] ].
	^ (entries asSortedCollection: [ :left :right |
		   (self compiledMethodEntryLabel: left)
		   <= (self compiledMethodEntryLabel: right) ]) asArray
]

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

	| caseSensitive data endIndex entries filterPattern filterMode filterTargets includeSource limit offset pagedEntries query requestedScope startIndex totalCount truncated |
	requestedScope := (self stringArgumentNamed: 'scope' in: arguments)
		                  ifNil: [ 'image' ]
		                  ifNotNil: [ :scope | scope asLowercase ].
	^ [
	  filterPattern := self stringArgumentNamed: 'filter' in: arguments.
	  filterTargets := self normalizedFilterTargetsFrom: arguments.
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
	  query := self compiledMethodScopeQueryFromArguments: arguments.
	  entries := self
		             compiledMethodEntriesFromQuery: query
		             filter: filterPattern
		             filterTargets: filterTargets
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
		          (#filterTargets -> filterTargets).
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

{ #category : 'private - filtering' }
MCPToolFindMethods >> filterTextsForCompiledMethodEntry: anEntry sourceText: sourceText targets: filterTargets [

	| texts |
	texts := OrderedCollection new.
	filterTargets do: [ :each |
		each = 'selector' ifTrue: [ texts add: (anEntry at: #selector) ].
		each = 'class' ifTrue: [ texts add: (anEntry at: #className) ].
		each = 'package' ifTrue: [ texts add: (anEntry at: #packageName) ].
		each = 'protocol' ifTrue: [ texts add: (anEntry at: #protocol) ].
		each = 'reference' ifTrue: [
			texts add: (self compiledMethodEntryLabel: anEntry) ].
		each = 'source' ifTrue: [ texts add: sourceText ] ].
	^ texts asArray
]

{ #category : 'initialization' }
MCPToolFindMethods >> initialize [

	| classNamesProperty filterModeProperty filterTargetsItemProperty filterTargetsProperty methodsProperty packageNamesProperty scopeProperty sideProperty |
	super initialize.
	name := 'find-methods'.
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
	filterTargetsItemProperty := MCPStructureProperties new
		                             type: 'string';
		                             description: 'A filter target.';
		                             enum: self supportedFilterTargets;
		                             yourself.
	filterTargetsProperty := (self
		                          schemaPropertyNamed: 'filterTargets'
		                          type: 'array'
		                          description:
			                          'Optional targets matched by filter. Defaults to selector.')
		                         items: filterTargetsItemProperty;
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
						                'Optional filter applied to the selected filter targets.';
					                yourself).
				               filterTargetsProperty.
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
				                filterTargetsProperty.
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
			                   'classNames' 'filterTargets' 'returnedCount'
			                   'totalCount' 'offset' 'limit' 'truncated'
			                   'methods' ).
	icons := { (self
		          pngCompositeBaseIconNamed: #page
		          badgeIconNamed: #zoomIn) }
]

{ #category : 'private - filtering' }
MCPToolFindMethods >> matchesFilterOnCompiledMethodEntry: anEntry sourceText: sourceText matcher: aMatcher targets: filterTargets [

	^ (self
		   filterTextsForCompiledMethodEntry: anEntry
		   sourceText: sourceText
		   targets: filterTargets) anySatisfy: [ :each |
		  aMatcher value: each ]
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

{ #category : 'private - arguments' }
MCPToolFindMethods >> normalizedFilterTargetsFrom: arguments [

	| invalidTargets normalizedTargets rawTargets |
	rawTargets := self
		              argumentNamed: 'filterTargets'
		              in: arguments
		              ifAbsent: [ ^ #( 'selector' ) ].
	normalizedTargets := OrderedCollection new.
	(self
		 normalizedStringCollection: rawTargets
		 argumentName: 'filterTargets') do: [ :each |
		| normalized |
		normalized := each asLowercase.
		(normalizedTargets includes: normalized) ifFalse: [
			normalizedTargets add: normalized ] ].
	normalizedTargets ifEmpty: [
		Error signal: 'filterTargets must contain at least one target.' ].
	invalidTargets := normalizedTargets reject: [ :each |
		                  self supportedFilterTargets includes: each ].
	invalidTargets ifNotEmpty: [
		Error signal: 'Unsupported filterTargets value(s): '
			, invalidTargets asArray printString
			,
			'. Supported targets are selector, class, package, protocol, reference, source.' ].
	^ normalizedTargets asArray
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

{ #category : 'private - arguments' }
MCPToolFindMethods >> supportedFilterTargets [

	^ #( 'selector' 'class' 'package' 'protocol' 'reference' 'source' )
]
