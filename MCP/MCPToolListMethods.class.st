Class {
	#name : 'MCPToolListMethods',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'executing' }
MCPToolListMethods >> executeWithArguments: arguments [

	| caseSensitive classBehavior className data endIndex filterMode includeSource limit methodEntries needsSourceText offset pagedMethods protocolFilter protocolMatcher selectorFilter selectorMatcher side sourceFilter sourceMatcher startIndex totalCount truncated |
	className := self
		             argumentNamed: 'className'
		             in: arguments
		             ifAbsent: [ nil ].
	side := self normalizedSideFrom: arguments.
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
	selectorFilter := self
		                  stringArgumentNamed: 'selectorFilter'
		                  in: arguments.
	protocolFilter := self
		                  stringArgumentNamed: 'protocolFilter'
		                  in: arguments.
	sourceFilter := self
		                stringArgumentNamed: 'sourceFilter'
		                in: arguments.
	^ [
	  | behaviors |
	  selectorMatcher := self
		                     matcherForPattern: selectorFilter
		                     mode: filterMode
		                     caseSensitive: caseSensitive.
	  protocolMatcher := self
		                     matcherForPattern: protocolFilter
		                     mode: filterMode
		                     caseSensitive: caseSensitive.
	  sourceMatcher := self
		                   matcherForPattern: sourceFilter
		                   mode: filterMode
		                   caseSensitive: caseSensitive.
	  needsSourceText := includeSource or: [ sourceFilter notNil ].
	  classBehavior := self class environment at: className asSymbol.
	  behaviors := OrderedCollection new.
	  (side = 'instance' or: [ side = 'both' ]) ifTrue: [
		  behaviors add: {
				  classBehavior.
				  false } ].
	  (side = 'class' or: [ side = 'both' ]) ifTrue: [
		  behaviors add: {
				  classBehavior classSide.
				  true } ].
	  methodEntries := OrderedCollection new.
	  behaviors do: [ :behaviorSpec |
		  | behavior isClassSide |
		  behavior := behaviorSpec first.
		  isClassSide := behaviorSpec second.
		  behavior selectors asSortedCollection do: [ :selector |
			  | compiledMethod protocolString selectorString sourceText |
			  compiledMethod := behavior compiledMethodAt: selector.
			  selectorString := selector asString.
			  protocolString := compiledMethod protocol
				                    ifNil: [ '' ]
				                    ifNotNil: [ :protocol |
				                    protocol name asString ].
			  sourceText := needsSourceText
				                ifTrue: [ compiledMethod sourceCode ifNil: [ '' ] ]
				                ifFalse: [ nil ].
			  (self
				   matchesSelector: selectorString
				   protocol: protocolString
				   source: sourceText
				   selectorMatcher: selectorMatcher
				   protocolMatcher: protocolMatcher
				   sourceMatcher: sourceMatcher) ifTrue: [
				  methodEntries add: (self
						   methodEntryForSelector: selector
						   compiledMethod: compiledMethod
						   className: className
						   isClassSide: isClassSide
						   includeSource: includeSource
						   sourceText: sourceText) ] ] ].
	  methodEntries := methodEntries asSortedCollection: [ :left :right |
		                   (left at: #methodReference)
		                   <= (right at: #methodReference) ].
	  totalCount := methodEntries size.
	  startIndex := offset + 1.
	  pagedMethods := (startIndex > totalCount or: [ limit = 0 ])
		                  ifTrue: [ #(  ) ]
		                  ifFalse: [
			                  endIndex := totalCount min: offset + limit.
			                  (methodEntries copyFrom: startIndex to: endIndex)
				                  asArray ].
	  truncated := offset + pagedMethods size < totalCount.
	  data := {
		          (#className -> className).
		          (#side -> side).
		          (#sourceIncluded -> includeSource).
		          (#returnedCount -> pagedMethods size).
		          (#totalCount -> totalCount).
		          (#offset -> offset).
		          (#limit -> limit).
		          (#truncated -> truncated).
		          (#methods -> pagedMethods) } asDictionary.
	  self
		  successResultText: (self
				   successSummaryForClassName: className
				   returnedCount: pagedMethods size
				   totalCount: totalCount
				   side: side
				   truncated: truncated)
		  data: data ]
		  on: Error
		  do: [ :error |
			  self
				  errorResultText:
				  (self failureMessageForClassNamed: className error: error)
				  details: {
						  (#errorClass -> error class name).
						  (#message -> error messageText).
						  (#className -> className).
						  (#side -> side) } asDictionary ]
]

{ #category : 'private' }
MCPToolListMethods >> failureMessageForClassNamed: aClassName error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to list methods for class ';
			  nextPutAll: aClassName;
			  nextPutAll: ' (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'initialization' }
MCPToolListMethods >> initialize [

	| filterModeProperty methodSchema methodsProperty sideProperty |
	super initialize.
	name := 'pharo-list-methods'.
	title := 'List Pharo Methods'.
	description := 'List methods defined on a Pharo class, with optional side, selector, protocol, and source filters.'.
	sideProperty := MCPStructureProperties new
		                name: 'side';
		                type: 'string';
		                description:
			                'Which side of the class to inspect. Defaults to both.';
		                enum: #( 'instance' 'class' 'both' );
		                yourself.
	filterModeProperty := MCPStructureProperties new
		                      name: 'filterMode';
		                      type: 'string';
		                      description:
			                      'How selector, protocol, and source filters are matched. Defaults to substring.';
		                      enum:
			                      #( 'substring' 'prefix' 'exact' 'regex' );
		                      yourself.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: {
				               (MCPStructureProperties new
					                name: 'className';
					                type: 'string';
					                description:
						                'The class whose methods should be listed.';
					                yourself).
				               sideProperty.
				               (MCPStructureProperties new
					                name: 'selectorFilter';
					                type: 'string';
					                description:
						                'Optional selector filter. Combined with other filters using logical AND.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'protocolFilter';
					                type: 'string';
					                description:
						                'Optional protocol filter. Combined with other filters using logical AND.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'sourceFilter';
					                type: 'string';
					                description:
						                'Optional source-code filter. This still applies when includeSource=false.';
					                yourself).
				               filterModeProperty.
				               (MCPStructureProperties new
					                name: 'caseSensitive';
					                type: 'boolean';
					                description:
						                'Whether textual matching is case-sensitive. Defaults to false.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'includeSource';
					                type: 'boolean';
					                description:
						                'Whether to include full method source in each returned method entry. Defaults to false.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'limit';
					                type: 'number';
					                description:
						                'Maximum number of matching methods to return. Defaults to 100. Use 0 to request counts only.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'offset';
					                type: 'number';
					                description:
						                'Zero-based pagination offset applied after filtering. Defaults to 0.';
					                yourself) };
		               required: #( 'className' );
		               yourself.
	methodsProperty := self
		                   schemaPropertyNamed: 'methods'
		                   type: 'array'
		                   description:
		                   'The method entries returned for the requested page.'.
	methodSchema := MCPStructureProperties new
		                name: 'method';
		                type: 'object';
		                description: 'A listed method entry.';
		                properties: {
				                (self
					                 schemaPropertyNamed: 'selector'
					                 type: 'string'
					                 description: 'The selector name.').
				                (self
					                 schemaPropertyNamed: 'protocol'
					                 type: 'string'
					                 description:
						                 'The protocol/category that contains the method.').
				                ((self
					                  schemaPropertyNamed: 'side'
					                  type: 'string'
					                  description:
						                  'The side on which the method is defined.')
					                 enum: #( 'instance' 'class' );
					                 yourself).
				                (self
					                 schemaPropertyNamed: 'methodReference'
					                 type: 'string'
					                 description:
					                 'A readable method reference such as Class>>selector or Class class>>selector.').
				                (self
					                 schemaPropertyNamed: 'source'
					                 type: 'string'
					                 description:
					                 'The formatted source code of the method when includeSource=true.') };
		                required:
		                #( 'selector' 'protocol' 'side' 'methodReference' );
		                additionalProperties: false;
		                yourself.
	methodsProperty items: methodSchema.
	outputSchema := self
		                standardOutputSchemaForDataProperties: {
				                (self
					                 schemaPropertyNamed: 'className'
					                 type: 'string'
					                 description:
					                 'The class whose methods were inspected.').
				                ((self
					                  schemaPropertyNamed: 'side'
					                  type: 'string'
					                  description: 'The requested side selection.')
					                 enum: #( 'instance' 'class' 'both' );
					                 yourself).
				                (self
					                 schemaPropertyNamed: 'sourceIncluded'
					                 type: 'boolean'
					                 description:
					                 'Whether method source was included in the returned method entries.').
				                (self
					                 schemaPropertyNamed: 'returnedCount'
					                 type: 'number'
					                 description:
					                 'The number of method entries returned in this page.').
				                (self
					                 schemaPropertyNamed: 'totalCount'
					                 type: 'number'
					                 description:
					                 'The total number of matching methods before pagination.').
				                (self
					                 schemaPropertyNamed: 'offset'
					                 type: 'number'
					                 description:
					                 'The zero-based pagination offset that was applied.').
				                (self
					                 schemaPropertyNamed: 'limit'
					                 type: 'number'
					                 description:
					                 'The maximum number of method entries requested.').
				                (self
					                 schemaPropertyNamed: 'truncated'
					                 type: 'boolean'
					                 description:
					                 'Whether additional matching methods exist beyond the returned page.').
				                methodsProperty }
		                required:
			                #( 'className' 'side' 'sourceIncluded'
			                   'returnedCount' 'totalCount' 'offset' 'limit'
			                   'truncated' 'methods' ).
	icons := {  }
]

{ #category : 'private - filtering' }
MCPToolListMethods >> matchesSelector: selectorString protocol: protocolString source: sourceString selectorMatcher: selectorMatcher protocolMatcher: protocolMatcher sourceMatcher: sourceMatcher [

	^ (selectorMatcher value: selectorString) and: [
		  (protocolMatcher value: protocolString) and: [
			  sourceMatcher value: sourceString ] ]
]

{ #category : 'private' }
MCPToolListMethods >> methodEntryForSelector: aSelector compiledMethod: aCompiledMethod className: aClassName isClassSide: isClassSide includeSource: includeSource sourceText: sourceText [

	| entry protocolName selectorName |
	selectorName := aSelector asString.
	protocolName := aCompiledMethod protocol
		                ifNil: [ '' ]
		                ifNotNil: [ :protocol | protocol name asString ].
	entry := Dictionary new.
	entry at: #selector put: selectorName.
	entry at: #protocol put: protocolName.
	entry at: #side put: (isClassSide
			 ifTrue: [ 'class' ]
			 ifFalse: [ 'instance' ]).
	entry at: #methodReference put: (self
			 methodReferenceForClassName: aClassName
			 selector: selectorName
			 isClassSide: isClassSide).
	includeSource ifTrue: [
		entry at: #source put: (sourceText ifNil: [ '' ]) ].
	^ entry
]

{ #category : 'private - arguments' }
MCPToolListMethods >> normalizedSideFrom: arguments [

	| side |
	side := (self stringArgumentNamed: 'side' in: arguments) ifNil: [
		        ^ 'both' ].
	side := side asLowercase.
	(#( 'instance' 'class' 'both' ) includes: side) ifFalse: [
		Error signal: 'side must be one of instance, class, or both.' ].
	^ side
]

{ #category : 'private - results' }
MCPToolListMethods >> successSummaryForClassName: className returnedCount: returnedCount totalCount: totalCount side: side truncated: truncated [

	^ String streamContents: [ :stream |
		  stream
			  print: returnedCount;
			  nextPutAll: ' methods returned for ';
			  nextPutAll: className;
			  nextPutAll: ' [side=';
			  nextPutAll: side;
			  nextPutAll: '] (';
			  print: totalCount;
			  nextPutAll: ' matched'.
		  truncated ifTrue: [ stream nextPutAll: ', more available' ].
		  stream nextPutAll: ').' ]
]
