Class {
	#name : 'MCPToolReferences',
	#superclass : 'MCPCompiledMethodQueryTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - searching' }
MCPToolReferences >> classBindingForClassName: aClassName [

	| binding |
	binding := Smalltalk globals
		           associationAt: aClassName asSymbol
		           ifAbsent: [ ^ nil ].
	^ binding value isBehavior
		  ifTrue: [ binding ]
		  ifFalse: [ nil ]
]

{ #category : 'private - searching' }
MCPToolReferences >> compiledMethod: aCompiledMethod referencesAnyVariable: variables [

	^ variables anySatisfy: [ :eachVariable |
		  eachVariable isAccessedIn: aCompiledMethod ]
]

{ #category : 'defaults' }
MCPToolReferences >> defaultDescription [

	^ 'Find methods that reference a selector, class, or variable in a chosen scope. Use mode=method for message sends, mode=class for class/global references, and mode=variable for variable or slot references. Use find-methods to list methods without reference matching.'
]

{ #category : 'defaults' }
MCPToolReferences >> defaultIcons [

	^ { (self pngIconNamed: #references) }
]

{ #category : 'defaults' }
MCPToolReferences >> defaultInputSchema [

	| scopeProperty sideProperty modeProperty packageNamesProperty classNamesProperty |
	scopeProperty := MCPStructureProperties new
		                 name: 'scope';
		                 type: 'string';
		                 description:
			                 'Where to search for references. Defaults to image.';
		                 enum: #( 'image' 'packages' 'hierarchy' 'classes' );
		                 default: 'image';
		                 yourself.
	sideProperty := MCPStructureProperties new
		                name: 'side';
		                type: 'string';
		                description:
			                'Which method side to search. Defaults to both.';
		                enum: #( 'instance' 'class' 'both' );
		                default: 'both';
		                yourself.
	modeProperty := MCPStructureProperties new
		                name: 'mode';
		                type: 'string';
		                description:
			                'Which reference query to run. Use method for message sends to a selector, class for references to a class/global binding, and variable for variable or slot references.';
		                enum: #( 'method' 'class' 'variable' );
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
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (MCPStructureProperties new
					   name: 'target';
					   type: 'string';
					   description:
						   'The selector, class name, or variable name to look for, depending on mode.';
					   yourself).
				  modeProperty.
				  scopeProperty.
				  sideProperty.
				  packageNamesProperty.
				  classNamesProperty.
				  (MCPStructureProperties new
					   name: 'filter';
					   type: 'string';
					   description:
						   'Optional filter applied to the matching reference methods after target lookup.';
					   yourself).
				  (MCPStructureProperties new
					   name: 'filterMode';
					   type: 'string';
					   description:
						   'How the filter is matched. Defaults to substring.';
					   enum: #( 'substring' 'prefix' 'exact' 'regex' );
					   default: 'substring';
					   yourself).
				  (MCPStructureProperties new
					   name: 'caseSensitive';
					   type: 'boolean';
					   description:
						   'Whether filter matching is case-sensitive. Defaults to false.';
					   default: false;
					   yourself).
				  (MCPStructureProperties new
					   name: 'includeSource';
					   type: 'boolean';
					   description:
						   'Whether to include method source code in each result entry. Defaults to false.';
					   default: false;
					   yourself).
				  (MCPStructureProperties new
					   name: 'limit';
					   type: 'integer';
					   description:
						   'Maximum number of matching methods to return. Defaults to 100. Use 0 to request counts only.';
					   default: 100;
					   yourself).
				  (MCPStructureProperties new
					   name: 'offset';
					   type: 'integer';
					   description:
						   'Zero-based pagination offset applied after filtering. Defaults to 0.';
					   default: 0;
					   yourself) };
		  required: #( 'target' 'mode' );
		  yourself
]

{ #category : 'defaults' }
MCPToolReferences >> defaultName [

	^ 'references'
]

{ #category : 'defaults' }
MCPToolReferences >> defaultOutputSchema [

	| packageNamesProperty classNamesProperty referencesProperty |
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
	referencesProperty := self
		                      schemaPropertyNamed: 'references'
		                      type: 'array'
		                      description:
		                      'The matching methods returned for the requested page. Each entry is a method that references the requested target.'.
	referencesProperty items: self senderEntrySchema.
	^ self
		                standardOutputSchemaForDataProperties: {
				                (self
					                 schemaPropertyNamed: 'target'
					                 type: 'string'
					                 description:
					                 'The selector, class name, or variable name that was searched for.').
				                ((self
					                  schemaPropertyNamed: 'mode'
					                  type: 'string'
					                  description:
						                  'The reference mode that was searched.')
					                 enum: #( 'method' 'class' 'variable' );
					                 yourself).
				                ((self
					                  schemaPropertyNamed: 'scope'
					                  type: 'string'
					                  description:
						                  'The scope used to search for references.')
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
					                 'The number of matching methods returned in this page.').
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
					                 'The maximum number of matching methods requested.').
				                (self
					                 schemaPropertyNamed: 'truncated'
					                 type: 'boolean'
					                 description:
					                 'Whether additional matching methods exist beyond the returned page.').
				                referencesProperty }
		                required:
			                #( 'target' 'mode' 'scope' 'side' 'sourceIncluded'
			                   'packageNames' 'classNames' 'returnedCount'
			                   'totalCount' 'offset' 'limit' 'truncated'
			                   'references' )
]

{ #category : 'defaults' }
MCPToolReferences >> defaultTitle [

	^ 'Find Pharo References'
]

{ #category : 'private - template' }
MCPToolReferences >> failureMessageForRequestedContext: requestedContext error: anError [

	^ self
		  failureMessageForTarget:
		  (requestedContext at: #target ifAbsent: [ '' ])
		  mode: (requestedContext at: #mode ifAbsent: [ 'unknown' ])
		  scope: (requestedContext at: #scope)
		  error: anError
]

{ #category : 'private - results' }
MCPToolReferences >> failureMessageForTarget: targetString mode: mode scope: scope error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to find ';
			  nextPutAll: (self queryDescriptionForMode: mode);
			  nextPutAll: ' for ';
			  nextPutAll: (self targetLabelFor: targetString mode: mode);
			  nextPutAll: ' [scope=';
			  nextPutAll: scope;
			  nextPutAll: '] (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'private - searching' }
MCPToolReferences >> matchingClassReferencesForClassNamed: aClassName inCompiledMethods: compiledMethods [

	| classBinding classSymbol |
	classBinding := self classBindingForClassName: aClassName.
	classBinding ifNil: [
		Error signal: 'There is no class named ' , aClassName , '.' ].
	classSymbol := aClassName asSymbol.
	^ (compiledMethods select: [ :eachMethod |
		   (self
			    compiledMethod: eachMethod
			    referencesAnyVariable: { classBinding }) or: [
			   eachMethod hasSelector: classSymbol ] ]) asArray
]

{ #category : 'private - searching' }
MCPToolReferences >> matchingCompiledMethodsForTarget: targetString mode: mode scopeQuery: query inCompiledMethods: compiledMethods [

	mode = 'method' ifTrue: [
		^ self
			  matchingMethodSendersForSelector: targetString asSymbol
			  inCompiledMethods: compiledMethods ].
	mode = 'class' ifTrue: [
		^ self
			  matchingClassReferencesForClassNamed: targetString
			  inCompiledMethods: compiledMethods ].
	mode = 'variable' ifTrue: [
		^ self
			  matchingVariableReferencesNamed: targetString
			  scopeQuery: query
			  inCompiledMethods: compiledMethods ].
	Error signal: 'Unsupported mode: ' , mode
]

{ #category : 'private - searching' }
MCPToolReferences >> matchingMethodSendersForSelector: aSelectorSymbol inCompiledMethods: compiledMethods [

	| specialSelectorIndex |
	specialSelectorIndex := Smalltalk specialSelectorIndexOrNil:
		                        aSelectorSymbol.
	^ (compiledMethods select: [ :eachMethod |
		   eachMethod
			   hasSelector: aSelectorSymbol
			   specialSelectorIndex: specialSelectorIndex ]) asArray
]

{ #category : 'private - searching' }
MCPToolReferences >> matchingVariableReferencesNamed: aVariableName scopeQuery: query inCompiledMethods: compiledMethods [

	| variables |
	variables := self
		             variableBindingsNamed: aVariableName
		             inBehaviors: query behaviors.
	variables ifEmpty: [
		Error signal: 'No variable named ' , aVariableName
			, ' is accessible in the requested scope.' ].
	^ (compiledMethods select: [ :eachMethod |
		   self compiledMethod: eachMethod referencesAnyVariable: variables ])
		  asArray
]

{ #category : 'private - arguments' }
MCPToolReferences >> modeFromArguments: arguments [

	| mode |
	mode := (self stringArgumentNamed: 'mode' in: arguments) ifNil: [
		        Error signal: 'mode is required.' ].
	mode := mode asLowercase.
	(#( 'method' 'class' 'variable' ) includes: mode) ifTrue: [ ^ mode ].
	Error signal: 'mode must be one of method, class, or variable.'
]

{ #category : 'private - results' }
MCPToolReferences >> queryDescriptionForMode: mode [

	mode = 'method' ifTrue: [ ^ 'method references' ].
	mode = 'class' ifTrue: [ ^ 'class references' ].
	mode = 'variable' ifTrue: [ ^ 'variable references' ].
	^ 'references'
]

{ #category : 'private - template' }
MCPToolReferences >> queryEntriesForParameters: parameters [

	| compiledMethods query |
	query := parameters at: #query.
	compiledMethods := query compiledMethods.
	^ self
		  compiledMethodEntriesFrom: (self
				   matchingCompiledMethodsForTarget: (parameters at: #target)
				   mode: (parameters at: #mode)
				   scopeQuery: query
				   inCompiledMethods: compiledMethods)
		  filter: (parameters at: #filterPattern)
		  filterMode: (parameters at: #filterMode)
		  caseSensitive: (parameters at: #caseSensitive)
		  includeSource: (parameters at: #includeSource)
]

{ #category : 'private - template' }
MCPToolReferences >> queryParametersFromArguments: arguments [

	| parameters |
	parameters := self compiledMethodQueryParametersFromArguments:
		              arguments.
	parameters
		at: #target
		put: (self stringArgumentNamed: 'target' in: arguments).
	parameters at: #mode put: (self modeFromArguments: arguments).
	^ parameters
]

{ #category : 'private - template' }
MCPToolReferences >> queryResultDataForParameters: parameters page: page [

	^ self
		  compiledMethodQueryResultDataForParameters: parameters
		  page: page
		  entriesKey: #references
		  extraData: {
				  (#target -> (parameters at: #target)).
				  (#mode -> (parameters at: #mode)) } asDictionary
]

{ #category : 'private - template' }
MCPToolReferences >> requestedContextFromArguments: arguments [

	| mode scope targetString |
	scope := self
		         argumentNamed: 'scope'
		         in: arguments
		         ifAbsent: [ 'image' ].
	scope := scope
		         ifNil: [ 'image' ]
		         ifNotNil: [ scope asString asLowercase ].
	mode := self
		        argumentNamed: 'mode'
		        in: arguments
		        ifAbsent: [ 'unknown' ].
	mode := mode
		        ifNil: [ 'unknown' ]
		        ifNotNil: [ mode asString asLowercase ].
	targetString := self
		                argumentNamed: 'target'
		                in: arguments
		                ifAbsent: [ nil ].
	targetString := targetString
		                ifNil: [ nil ]
		                ifNotNil: [ targetString asString ].
	^ {
		  (#scope -> scope).
		  (#mode -> mode).
		  (#target -> targetString) } asDictionary
]

{ #category : 'private - schema' }
MCPToolReferences >> senderEntrySchema [

	^ self
		  compiledMethodEntrySchemaNamed: 'reference'
		  description: 'A method matching the requested reference query.'
		  subjectDescription: 'matching method'
		  selectorDescription: 'The selector of the matching method.'
		  sourceDescription:
		  'The formatted source code of the matching method when includeSource=true.'
]

{ #category : 'private - template' }
MCPToolReferences >> successSummaryForParameters: parameters page: page [

	^ self
		  successSummaryForTarget: (parameters at: #target)
		  mode: (parameters at: #mode)
		  scope: (parameters at: #query) scope
		  returnedCount: (page at: #returnedCount)
		  totalCount: (page at: #totalCount)
		  truncated: (page at: #truncated)
]

{ #category : 'private - results' }
MCPToolReferences >> successSummaryForTarget: targetString mode: mode scope: scope returnedCount: returnedCount totalCount: totalCount truncated: truncated [

	^ String streamContents: [ :stream |
		  stream
			  print: returnedCount;
			  nextPutAll: ' ';
			  nextPutAll: (self queryDescriptionForMode: mode);
			  nextPutAll: ' returned for ';
			  nextPutAll: (self targetLabelFor: targetString mode: mode);
			  nextPutAll: ' [scope=';
			  nextPutAll: scope;
			  nextPutAll: '] (';
			  print: totalCount;
			  nextPutAll: ' matched'.
		  truncated ifTrue: [ stream nextPutAll: ', more available' ].
		  stream nextPutAll: ').' ]
]

{ #category : 'private - results' }
MCPToolReferences >> targetLabelFor: targetString mode: mode [

	mode = 'method' ifTrue: [ ^ '#' , targetString ].
	^ targetString
]

{ #category : 'private - searching' }
MCPToolReferences >> variableBindingsNamed: aVariableName inBehaviors: behaviors [

	| variables |
	variables := IdentitySet new.
	behaviors do: [ :eachBehavior |
		eachBehavior allSlots do: [ :eachSlot |
			eachSlot name asString = aVariableName ifTrue: [
				variables add: eachSlot ] ].
		(eachBehavior bindingOf: aVariableName) ifNotNil: [ :binding |
			variables add: binding ] ].
	^ variables asArray
]
