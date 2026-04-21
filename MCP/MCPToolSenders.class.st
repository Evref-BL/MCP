Class {
	#name : 'MCPToolSenders',
	#superclass : 'MCPToolImplementors',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - searching' }
MCPToolSenders >> allCompiledMethodsForSide: side [

	| methods |
	methods := IdentitySet new.
	Smalltalk globals allBehaviorsDo: [ :eachBehavior |
		eachBehavior methods do: [ :eachMethod |
			(eachMethod isCompiledMethod and: [
				 self matchesSide: side forCompiledMethod: eachMethod ]) ifTrue: [
				methods add: eachMethod ] ] ].
	^ methods asArray
]

{ #category : 'private - searching' }
MCPToolSenders >> classBindingForSelectorSymbol: aSelectorSymbol [

	| binding |
	binding := Smalltalk globals
		           associationAt: aSelectorSymbol
		           ifAbsent: [ ^ nil ].
	^ binding value isBehavior
		  ifTrue: [ binding ]
		  ifFalse: [ nil ]
]

{ #category : 'private - searching' }
MCPToolSenders >> compiledMethod: aCompiledMethod referencesClassBinding: classBinding [

	^ aCompiledMethod hasLiteralSuchThat: [ :eachLiteral |
		  eachLiteral == classBinding ]
]

{ #category : 'executing' }
MCPToolSenders >> executeWithArguments: arguments [

	| caseSensitive classNames compiledMethods data endIndex entries filterPattern filterMode includeSource limit offset packageNames pagedEntries scope selectorString startIndex totalCount truncated side |
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
	^ [
	  self
		  validateScope: scope
		  packageNames: packageNames
		  classNames: classNames.
	  compiledMethods := self
		                     scopedSendersOf: selectorString asSymbol
		                     scope: scope
		                     packageNames: packageNames
		                     classNames: classNames
		                     side: side.
	  entries := self
		             entriesFromCompiledMethods: compiledMethods
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
		          (#senders -> pagedEntries) } asDictionary.
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
MCPToolSenders >> failureMessageForSelector: selectorString scope: scope error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to find senders for #';
			  nextPutAll: selectorString;
			  nextPutAll: ' [scope=';
			  nextPutAll: scope;
			  nextPutAll: '] (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'private - searching' }
MCPToolSenders >> imageSendersOf: aSelectorSymbol side: side [

	| classBinding referenceSenders selectorSenders |
	selectorSenders := ((SystemNavigation default allCallsOn:
		                     aSelectorSymbol) select: [ :eachMethod |
		                    self
			                    matchesSide: side
			                    forCompiledMethod: eachMethod ]) asArray.
	classBinding := self classBindingForSelectorSymbol: aSelectorSymbol.
	classBinding ifNil: [ ^ selectorSenders ].
	referenceSenders := self
		                    imageSendersReferencingClassBinding:
		                    classBinding
		                    side: side.
	^ self mergeCompiledMethods: selectorSenders with: referenceSenders
]

{ #category : 'private - searching' }
MCPToolSenders >> imageSendersReferencingClassBinding: classBinding side: side [

	^ ((self allCompiledMethodsForSide: side) select: [ :eachMethod |
		   self
			   compiledMethod: eachMethod
			   referencesClassBinding: classBinding ]) asArray
]

{ #category : 'initialization' }
MCPToolSenders >> initialize [

	| classNamesProperty packageNamesProperty scopeProperty sendersProperty sideProperty |
	super initialize.
	name := 'pharo-senders'.
	title := 'Find Pharo Senders'.
	description := 'Find methods that send a selector in the running Pharo image, optionally scoped to packages, hierarchies, or specific classes.'.
	scopeProperty := MCPStructureProperties new
		                 name: 'scope';
		                 type: 'string';
		                 description:
			                 'Where to search for senders. Defaults to image.';
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
						                'The selector whose senders should be found.';
					                yourself).
				               scopeProperty.
				               sideProperty.
				               packageNamesProperty.
				               classNamesProperty.
				               (MCPStructureProperties new
					                name: 'filter';
					                type: 'string';
					                description:
						                'Optional filter applied to sender selector, class, package, protocol, method reference, and source text.';
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
						                'Whether to include sender source code in each result entry. Defaults to false.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'limit';
					                type: 'number';
					                description:
						                'Maximum number of matching senders to return. Defaults to 100. Use 0 to request counts only.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'offset';
					                type: 'number';
					                description:
						                'Zero-based pagination offset applied after filtering. Defaults to 0.';
					                yourself) };
		               required: #( 'selector' );
		               yourself.
	sendersProperty := self
		                   schemaPropertyNamed: 'senders'
		                   type: 'array'
		                   description:
		                   'The sender methods returned for the requested page.'.
	sendersProperty items: self senderEntrySchema.
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
						                  'The scope used to search for senders.')
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
					                 'Whether sender source was included in the returned entries.').
				                packageNamesProperty.
				                classNamesProperty.
				                (self
					                 schemaPropertyNamed: 'returnedCount'
					                 type: 'number'
					                 description:
					                 'The number of senders returned in this page.').
				                (self
					                 schemaPropertyNamed: 'totalCount'
					                 type: 'number'
					                 description:
					                 'The total number of matching senders before pagination.').
				                (self
					                 schemaPropertyNamed: 'offset'
					                 type: 'number'
					                 description:
					                 'The zero-based pagination offset that was applied.').
				                (self
					                 schemaPropertyNamed: 'limit'
					                 type: 'number'
					                 description:
					                 'The maximum number of senders requested.').
				                (self
					                 schemaPropertyNamed: 'truncated'
					                 type: 'boolean'
					                 description:
					                 'Whether additional matching senders exist beyond the returned page.').
				                sendersProperty }
		                required:
			                #( 'selector' 'scope' 'side' 'sourceIncluded'
			                   'packageNames' 'classNames' 'returnedCount'
			                   'totalCount' 'offset' 'limit' 'truncated'
			                   'senders' ).
	icons := {  }
]

{ #category : 'private - searching' }
MCPToolSenders >> matchingSendersForSelector: aSelectorSymbol classBinding: classBinding inCompiledMethods: compiledMethods [

	| referenceSenders selectorSenders |
	selectorSenders := (compiledMethods select: [ :eachMethod |
		                    eachMethod sendsSelector: aSelectorSymbol ])
		                   asArray.
	classBinding ifNil: [ ^ selectorSenders ].
	referenceSenders := (compiledMethods select: [ :eachMethod |
		                     self
			                     compiledMethod: eachMethod
			                     referencesClassBinding: classBinding ])
		                    asArray.
	^ self mergeCompiledMethods: selectorSenders with: referenceSenders
]

{ #category : 'private - searching' }
MCPToolSenders >> mergeCompiledMethods: leftMethods with: rightMethods [

	| merged |
	merged := IdentitySet new.
	merged addAll: leftMethods.
	merged addAll: rightMethods.
	^ merged asArray
]

{ #category : 'private - searching' }
MCPToolSenders >> scopedSendersOf: aSelectorSymbol scope: scope packageNames: packageNames classNames: classNames side: side [

	| classBinding methods |
	classBinding := self classBindingForSelectorSymbol: aSelectorSymbol.
	scope = 'image' ifTrue: [
		^ self imageSendersOf: aSelectorSymbol side: side ].
	scope = 'packages' ifTrue: [
		methods := self
			           compiledMethodsForPackageNames: packageNames
			           side: side.
		^ self
			  matchingSendersForSelector: aSelectorSymbol
			  classBinding: classBinding
			  inCompiledMethods: methods ].
	scope = 'classes' ifTrue: [
		methods := self compiledMethodsForBehaviors:
			           (self behaviorsForClassNames: classNames side: side).
		^ self
			  matchingSendersForSelector: aSelectorSymbol
			  classBinding: classBinding
			  inCompiledMethods: methods ].
	scope = 'hierarchy' ifTrue: [
		methods := self compiledMethodsForBehaviors:
			           (self
				            hierarchyBehaviorsForClassNames: classNames
				            side: side).
		^ self
			  matchingSendersForSelector: aSelectorSymbol
			  classBinding: classBinding
			  inCompiledMethods: methods ].
	Error signal: 'Unsupported scope: ' , scope
]

{ #category : 'private - schema' }
MCPToolSenders >> senderEntrySchema [

	^ MCPStructureProperties new
		  name: 'sender';
		  type: 'object';
		  description: 'A method that sends the requested selector.';
		  properties: {
				  (self
					   schemaPropertyNamed: 'selector'
					   type: 'string'
					   description: 'The selector of the sender method.').
				  (self
					   schemaPropertyNamed: 'className'
					   type: 'string'
					   description: 'The base class that defines the sender method.').
				  ((self
					    schemaPropertyNamed: 'side'
					    type: 'string'
					    description: 'The side on which the sender is defined.')
					   enum: #( 'instance' 'class' );
					   yourself).
				  (self
					   schemaPropertyNamed: 'packageName'
					   type: 'string'
					   description: 'The package that owns the sender method.').
				  (self
					   schemaPropertyNamed: 'isExtension'
					   type: 'boolean'
					   description:
					   'Whether the sender method is an extension on its class package.').
				  (self
					   schemaPropertyNamed: 'protocol'
					   type: 'string'
					   description:
					   'The protocol/category containing the sender method.').
				  (self
					   schemaPropertyNamed: 'methodReference'
					   type: 'string'
					   description:
					   'A readable method reference such as Class>>selector or Class class>>selector.').
				  (self
					   schemaPropertyNamed: 'source'
					   type: 'string'
					   description:
					   'The formatted source code of the sender when includeSource=true.') };
		  required:
			  #( 'selector' 'className' 'side' 'packageName' 'isExtension'
			     'protocol' 'methodReference' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - results' }
MCPToolSenders >> successSummaryForSelector: selectorString scope: scope returnedCount: returnedCount totalCount: totalCount truncated: truncated [

	^ String streamContents: [ :stream |
		  stream
			  print: returnedCount;
			  nextPutAll: ' senders returned for #';
			  nextPutAll: selectorString;
			  nextPutAll: ' [scope=';
			  nextPutAll: scope;
			  nextPutAll: '] (';
			  print: totalCount;
			  nextPutAll: ' matched'.
		  truncated ifTrue: [ stream nextPutAll: ', more available' ].
		  stream nextPutAll: ').' ]
]
