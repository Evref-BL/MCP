Class {
	#name : 'MCPToolImplementors',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - scope' }
MCPToolImplementors >> addBehaviorsForBaseClass: aClass side: side to: behaviors [

	(side = 'instance' or: [ side = 'both' ]) ifTrue: [
		behaviors add: aClass instanceSide ].
	(side = 'class' or: [ side = 'both' ]) ifTrue: [
		behaviors add: aClass instanceSide classSide ]
]

{ #category : 'private - methods' }
MCPToolImplementors >> baseClassNameForCompiledMethod: aCompiledMethod [

	^ aCompiledMethod methodClass instanceSide name asString
]

{ #category : 'private - scope' }
MCPToolImplementors >> behaviorsForClassNames: classNames side: side [

	| behaviors |
	behaviors := IdentitySet new.
	classNames do: [ :eachName |
		self
			addBehaviorsForBaseClass:
			(self class environment at: eachName asSymbol) instanceSide
			side: side
			to: behaviors ].
	^ behaviors asArray
]

{ #category : 'private - methods' }
MCPToolImplementors >> classPackageNameForCompiledMethod: aCompiledMethod [

	^ aCompiledMethod methodClass instanceSide package name asString
]

{ #category : 'private - scope' }
MCPToolImplementors >> compiledMethodsForBehaviors: behaviors [

	| methods |
	methods := IdentitySet new.
	behaviors do: [ :eachBehavior |
		eachBehavior methods do: [ :eachMethod | methods add: eachMethod ] ].
	^ methods asArray
]

{ #category : 'private - scope' }
MCPToolImplementors >> compiledMethodsForPackageNames: packageNames side: side [

	| methods |
	methods := IdentitySet new.
	packageNames do: [ :eachName |
		| package |
		package := eachName asPackage.
		package definedClasses do: [ :class |
			(side = 'instance' or: [ side = 'both' ]) ifTrue: [
				class localMethods do: [ :eachMethod | methods add: eachMethod ] ].
			(side = 'class' or: [ side = 'both' ]) ifTrue: [
				class classSide localMethods do: [ :eachMethod |
					methods add: eachMethod ] ] ].
		package extensionMethods do: [ :eachMethod |
			(self matchesSide: side forCompiledMethod: eachMethod) ifTrue: [
				methods add: eachMethod ] ] ].
	^ methods asArray
]

{ #category : 'private - results' }
MCPToolImplementors >> entriesFromCompiledMethods: compiledMethods filter: filterPattern filterMode: filterMode caseSensitive: caseSensitive includeSource: includeSource [

	| entries matcher needsSourceText |
	matcher := self
		           matcherForPattern: filterPattern
		           mode: filterMode
		           caseSensitive: caseSensitive.
	needsSourceText := includeSource or: [ filterPattern notNil ].
	entries := OrderedCollection new.
	compiledMethods do: [ :eachMethod |
		| entry sourceText |
		sourceText := needsSourceText
			              ifTrue: [
			              self sourceTextForCompiledMethod: eachMethod ]
			              ifFalse: [ nil ].
		entry := self
			         implementorEntryForCompiledMethod: eachMethod
			         includeSource: includeSource
			         sourceText: sourceText.
		(self
			 matchesFilterOnEntry: entry
			 sourceText: sourceText
			 matcher: matcher) ifTrue: [ entries add: entry ] ].
	^ (entries asSortedCollection: [ :left :right |
		   (left at: #methodReference) <= (right at: #methodReference) ])
		  asArray
]

{ #category : 'executing' }
MCPToolImplementors >> executeWithArguments: arguments [

	| classNames compiledMethods data endIndex entries filterPattern filterMode includeSource limit offset packageNames pagedEntries scope selectorString startIndex totalCount truncated side |
	selectorString := self selectorStringFrom: arguments.
	scope := self normalizedScopeFrom: arguments.
	side := self normalizedSideFrom: arguments.
	packageNames := self
		                stringArrayArgumentNamed: 'packageNames'
		                in: arguments.
	classNames := self
		              stringArrayArgumentNamed: 'classNames'
		              in: arguments.
	filterPattern := self stringArgumentNamed: 'filter' in: arguments.
	filterMode := self normalizedFilterModeFrom: arguments.
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
	^ [
	  self
		  validateScope: scope
		  packageNames: packageNames
		  classNames: classNames.
	  compiledMethods := self
		                     scopedImplementorsOf: selectorString asSymbol
		                     scope: scope
		                     packageNames: packageNames
		                     classNames: classNames
		                     side: side.
	  entries := self
		             entriesFromCompiledMethods: compiledMethods
		             filter: filterPattern
		             filterMode: filterMode
		             caseSensitive: (self
				              booleanArgumentNamed: 'caseSensitive'
				              in: arguments
				              default: false)
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
		          (#scope -> scope).
		          (#side -> side).
		          (#sourceIncluded -> includeSource).
		          (#packageNames -> (packageNames ifNil: [ #(  ) ])).
		          (#classNames -> (classNames ifNil: [ #(  ) ])).
		          (#returnedCount -> pagedEntries size).
		          (#totalCount -> totalCount).
		          (#offset -> offset).
		          (#limit -> limit).
		          (#truncated -> truncated).
		          (#implementors -> pagedEntries) } asDictionary.
	  self
		  successResultText: (self
				   successSummaryForSelector: selectorString
				   scope: scope
				   returnedCount: pagedEntries size
				   totalCount: totalCount
				   truncated: truncated)
		  data: data ]
		  on: Error
		  do: [ :error |
			  self
				  errorResultText: (self
						   failureMessageForSelector: selectorString
						   scope: scope
						   error: error)
				  details: {
						  (#errorClass -> error class name).
						  (#message -> error messageText).
						  (#selector -> selectorString).
						  (#scope -> scope) } asDictionary ]
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

{ #category : 'private - filtering' }
MCPToolImplementors >> filterTextForEntry: anEntry sourceText: sourceText [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: (anEntry at: #selector);
			  nextPutAll: ' ';
			  nextPutAll: (anEntry at: #className);
			  nextPutAll: ' ';
			  nextPutAll: (anEntry at: #side);
			  nextPutAll: ' ';
			  nextPutAll: (anEntry at: #packageName);
			  nextPutAll: ' ';
			  nextPutAll: (anEntry at: #protocol);
			  nextPutAll: ' ';
			  nextPutAll: (anEntry at: #methodReference).
		  sourceText ifNotNil: [
			  stream
				  nextPutAll: ' ';
				  nextPutAll: sourceText ] ]
]

{ #category : 'private - scope' }
MCPToolImplementors >> hierarchyBehaviorsForClassNames: classNames side: side [

	| baseClasses behaviors hierarchyClasses |
	baseClasses := classNames collect: [ :eachName |
		               (self class environment at: eachName asSymbol)
			               instanceSide ].
	hierarchyClasses := IdentitySet new.
	baseClasses do: [ :eachClass |
		eachClass withAllSuperAndSubclasses do: [ :relatedClass |
			hierarchyClasses add: relatedClass instanceSide ] ].
	behaviors := IdentitySet new.
	hierarchyClasses do: [ :eachClass |
		self addBehaviorsForBaseClass: eachClass side: side to: behaviors ].
	^ behaviors asArray
]

{ #category : 'private - searching' }
MCPToolImplementors >> imageImplementorsOf: aSelectorSymbol side: side [

	^ ((SystemNavigation default allImplementorsOf: aSelectorSymbol)
		   select: [ :eachMethod |
		   self matchesSide: side forCompiledMethod: eachMethod ]) asArray
]

{ #category : 'private - methods' }
MCPToolImplementors >> implementorEntryForCompiledMethod: aCompiledMethod includeSource: includeSource sourceText: sourceText [

	| className entry isClassSide selectorString |
	className := self baseClassNameForCompiledMethod: aCompiledMethod.
	selectorString := aCompiledMethod selector asString.
	isClassSide := self isClassSideCompiledMethod: aCompiledMethod.
	entry := Dictionary new.
	entry at: #selector put: selectorString.
	entry at: #className put: className.
	entry at: #side put: (isClassSide
			 ifTrue: [ 'class' ]
			 ifFalse: [ 'instance' ]).
	entry
		at: #packageName
		put: (self packageNameForCompiledMethod: aCompiledMethod).
	entry
		at: #isExtension
		put: (self isExtensionCompiledMethod: aCompiledMethod).
	entry
		at: #protocol
		put: (self protocolNameForCompiledMethod: aCompiledMethod).
	entry at: #methodReference put: (self
			 methodReferenceForClassName: className
			 selector: selectorString
			 isClassSide: isClassSide).
	includeSource ifTrue: [ entry at: #source put: sourceText ].
	^ entry
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
					   schemaPropertyNamed: 'methodReference'
					   type: 'string'
					   description:
					   'A readable method reference such as Class>>selector or Class class>>selector.').
				  (self
					   schemaPropertyNamed: 'source'
					   type: 'string'
					   description:
					   'The formatted source code of the implementor when includeSource=true.') };
		  required:
			  #( 'selector' 'className' 'side' 'packageName' 'isExtension'
			     'protocol' 'methodReference' );
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
					                type: 'number';
					                description:
						                'Maximum number of matching implementors to return. Defaults to 100. Use 0 to request counts only.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'offset';
					                type: 'number';
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
					                 schemaPropertyNamed: 'returnedCount'
					                 type: 'number'
					                 description:
					                 'The number of implementors returned in this page.').
				                (self
					                 schemaPropertyNamed: 'totalCount'
					                 type: 'number'
					                 description:
					                 'The total number of matching implementors before pagination.').
				                (self
					                 schemaPropertyNamed: 'offset'
					                 type: 'number'
					                 description:
					                 'The zero-based pagination offset that was applied.').
				                (self
					                 schemaPropertyNamed: 'limit'
					                 type: 'number'
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

{ #category : 'private - methods' }
MCPToolImplementors >> isClassSideCompiledMethod: aCompiledMethod [

	^ aCompiledMethod methodClass isMeta
]

{ #category : 'private - methods' }
MCPToolImplementors >> isExtensionCompiledMethod: aCompiledMethod [

	^ (self packageNameForCompiledMethod: aCompiledMethod)
	  ~= (self classPackageNameForCompiledMethod: aCompiledMethod)
]

{ #category : 'private - filtering' }
MCPToolImplementors >> matchesFilterOnEntry: anEntry sourceText: sourceText matcher: aMatcher [

	^ aMatcher value:
		  (self filterTextForEntry: anEntry sourceText: sourceText)
]

{ #category : 'private - methods' }
MCPToolImplementors >> matchesSide: side forCompiledMethod: aCompiledMethod [

	side = 'both' ifTrue: [ ^ true ].
	side = 'class' ifTrue: [
		^ self isClassSideCompiledMethod: aCompiledMethod ].
	^ (self isClassSideCompiledMethod: aCompiledMethod) not
]

{ #category : 'private - arguments' }
MCPToolImplementors >> normalizedScopeFrom: arguments [

	| scope |
	scope := (self stringArgumentNamed: 'scope' in: arguments) ifNil: [
		         ^ 'image' ].
	scope := scope asLowercase.
	(#( 'image' 'packages' 'hierarchy' 'classes' ) includes: scope)
		ifFalse: [
			Error signal:
				'scope must be one of image, packages, hierarchy, or classes.' ].
	^ scope
]

{ #category : 'private - arguments' }
MCPToolImplementors >> normalizedSideFrom: arguments [

	| side |
	side := (self stringArgumentNamed: 'side' in: arguments) ifNil: [
		        ^ 'both' ].
	side := side asLowercase.
	(#( 'instance' 'class' 'both' ) includes: side) ifFalse: [
		Error signal: 'side must be one of instance, class, or both.' ].
	^ side
]

{ #category : 'private - methods' }
MCPToolImplementors >> packageNameForCompiledMethod: aCompiledMethod [

	| package |
	package := aCompiledMethod package ifNil: [
		           aCompiledMethod methodClass instanceSide package ].
	^ package name asString
]

{ #category : 'private - methods' }
MCPToolImplementors >> protocolNameForCompiledMethod: aCompiledMethod [

	^ aCompiledMethod protocol
		  ifNil: [ '' ]
		  ifNotNil: [ :protocol | protocol name asString ]
]

{ #category : 'private - searching' }
MCPToolImplementors >> scopedImplementorsOf: aSelectorSymbol scope: scope packageNames: packageNames classNames: classNames side: side [

	| methods |
	scope = 'image' ifTrue: [
		^ self imageImplementorsOf: aSelectorSymbol side: side ].
	scope = 'packages' ifTrue: [
		methods := self
			           compiledMethodsForPackageNames: packageNames
			           side: side.
		^ (methods select: [ :eachMethod |
			   eachMethod selector = aSelectorSymbol ]) asArray ].
	scope = 'classes' ifTrue: [
		methods := self compiledMethodsForBehaviors:
			           (self behaviorsForClassNames: classNames side: side).
		^ (methods select: [ :eachMethod |
			   eachMethod selector = aSelectorSymbol ]) asArray ].
	scope = 'hierarchy' ifTrue: [
		methods := self compiledMethodsForBehaviors:
			           (self
				            hierarchyBehaviorsForClassNames: classNames
				            side: side).
		^ (methods select: [ :eachMethod |
			   eachMethod selector = aSelectorSymbol ]) asArray ].
	Error signal: 'Unsupported scope: ' , scope
]

{ #category : 'private - methods' }
MCPToolImplementors >> sourceTextForCompiledMethod: aCompiledMethod [

	^ aCompiledMethod sourceCode ifNil: [ '' ]
]

{ #category : 'private - arguments' }
MCPToolImplementors >> stringArrayArgumentNamed: anArgumentName in: arguments [

	| normalized value values |
	value := self
		         argumentNamed: anArgumentName
		         in: arguments
		         ifAbsent: [ ^ nil ].
	value ifNil: [ ^ nil ].
	(value isString or: [ value isSymbol ]) ifTrue: [ value := { value } ].
	(value isCollection and: [ value isString not ]) ifFalse: [
		Error signal:
			anArgumentName asString , ' must be an array of strings.' ].
	values := OrderedCollection new.
	value do: [ :each |
		normalized := each asString trimBoth.
		normalized isEmpty ifFalse: [ values add: normalized ] ].
	^ values asArray
]

{ #category : 'private - schema' }
MCPToolImplementors >> stringArraySchemaNamed: aName description: aDescription itemDescription: anItemDescription [

	| itemsProperty |
	itemsProperty := MCPStructureProperties new
		                 type: 'string';
		                 description: anItemDescription;
		                 yourself.
	^ (self
		   schemaPropertyNamed: aName
		   type: 'array'
		   description: aDescription)
		  items: itemsProperty;
		  yourself
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

{ #category : 'private - arguments' }
MCPToolImplementors >> validateScope: scope packageNames: packageNames classNames: classNames [

	scope = 'packages' ifTrue: [
		(packageNames isNil or: [ packageNames isEmpty ]) ifTrue: [
			Error signal: 'packageNames is required when scope=packages.' ] ].
	(scope = 'classes' or: [ scope = 'hierarchy' ]) ifTrue: [
		(classNames isNil or: [ classNames isEmpty ]) ifTrue: [
			Error signal: 'classNames is required when scope=' , scope , '.' ] ]
]
