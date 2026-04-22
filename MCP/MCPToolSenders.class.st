Class {
	#name : 'MCPToolSenders',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - searching' }
MCPToolSenders >> classBindingForClassName: aClassName [

	| binding |
	binding := Smalltalk globals
		           associationAt: aClassName asSymbol
		           ifAbsent: [ ^ nil ].
	^ binding value isBehavior
		  ifTrue: [ binding ]
		  ifFalse: [ nil ]
]

{ #category : 'private - searching' }
MCPToolSenders >> compiledMethod: aCompiledMethod referencesAnyVariable: variables [

	^ variables anySatisfy: [ :eachVariable |
		  eachVariable isAccessedIn: aCompiledMethod ]
]

{ #category : 'executing' }
MCPToolSenders >> executeWithArguments: arguments [

	| caseSensitive compiledMethods data endIndex entries filterPattern filterMode includeSource limit mode offset pagedEntries query requestedMode requestedScope selectorString startIndex totalCount truncated |
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
	requestedMode := (self stringArgumentNamed: 'mode' in: arguments)
		                 ifNil: [ 'unknown' ].
	^ [
	  mode := self modeFromArguments: arguments.
	  query := self compiledMethodScopeQueryFromArguments: arguments.
	  compiledMethods := query compiledMethods.
	  entries := self
		             compiledMethodEntriesFrom: (self
				              matchingCompiledMethodsForTarget: selectorString
				              mode: mode
				              scopeQuery: query
				              inCompiledMethods: compiledMethods)
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
		          (#mode -> mode).
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
		          (#senders -> pagedEntries) } asDictionary.
	  self
		  successResultText: (self
				   successSummaryForTarget: selectorString
				   mode: mode
				   scope: query scope
				   returnedCount: pagedEntries size
				   totalCount: totalCount
				   truncated: truncated)
		  data: data ]
		  on: Error
		  do: [ :error |
			  self
				  errorResultText: (self
						   failureMessageForTarget: selectorString
						   mode: requestedMode
						   scope: requestedScope
						   error: error)
				  details: {
						  (#errorClass -> error class name).
						  (#message -> error messageText).
						  (#selector -> selectorString).
						  (#mode -> requestedMode).
						  (#scope -> requestedScope) } asDictionary ]
]

{ #category : 'private - results' }
MCPToolSenders >> failureMessageForTarget: targetString mode: mode scope: scope error: anError [

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

{ #category : 'initialization' }
MCPToolSenders >> initialize [

	| classNamesProperty modeProperty packageNamesProperty scopeProperty sendersProperty sideProperty |
	super initialize.
	name := 'pharo-senders'.
	title := 'Find Pharo Senders and References'.
	description := 'Find method senders, class references, or variable references in the running Pharo image, optionally scoped to packages, hierarchies, or specific classes.'.
	scopeProperty := MCPStructureProperties new
		                 name: 'scope';
		                 type: 'string';
		                 description:
			                 'Where to search for senders or references. Defaults to image.';
		                 enum: #( 'image' 'packages' 'hierarchy' 'classes' );
		                 yourself.
	sideProperty := MCPStructureProperties new
		                name: 'side';
		                type: 'string';
		                description:
			                'Which method side to search. Defaults to both.';
		                enum: #( 'instance' 'class' 'both' );
		                yourself.
	modeProperty := MCPStructureProperties new
		                name: 'mode';
		                type: 'string';
		                description:
			                'Which sender or reference query to run. Use method for message senders, class for class references, and variable for variable references.';
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
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: {
				               (MCPStructureProperties new
					                name: 'selector';
					                type: 'string';
					                description:
						                'The selector, class name, or variable name to search, depending on mode.';
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
						                'Optional filter applied to method selector, class, package, protocol, method reference, and source text.';
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
						                'Whether to include method source code in each result entry. Defaults to false.';
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
		               required: #( 'selector' 'mode' );
		               yourself.
	sendersProperty := self
		                   schemaPropertyNamed: 'senders'
		                   type: 'array'
		                   description:
		                   'The matching methods returned for the requested page.'.
	sendersProperty items: self senderEntrySchema.
	outputSchema := self
		                standardOutputSchemaForDataProperties: {
				                (self
					                 schemaPropertyNamed: 'selector'
					                 type: 'string'
					                 description:
					                 'The selector, class name, or variable name that was searched.').
				                ((self
					                  schemaPropertyNamed: 'mode'
					                  type: 'string'
					                  description:
						                  'The sender or reference mode that was searched.')
					                 enum: #( 'method' 'class' 'variable' );
					                 yourself).
				                ((self
					                  schemaPropertyNamed: 'scope'
					                  type: 'string'
					                  description:
						                  'The scope used to search for senders or references.')
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
					                 schemaPropertyNamed: 'returnedCount'
					                 type: 'number'
					                 description:
					                 'The number of matching methods returned in this page.').
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
					                 'The maximum number of matching methods requested.').
				                (self
					                 schemaPropertyNamed: 'truncated'
					                 type: 'boolean'
					                 description:
					                 'Whether additional matching methods exist beyond the returned page.').
				                sendersProperty }
		                required:
			                #( 'selector' 'mode' 'scope' 'side' 'sourceIncluded'
			                   'packageNames' 'classNames' 'returnedCount'
			                   'totalCount' 'offset' 'limit' 'truncated'
			                   'senders' ).
	icons := {  }
]

{ #category : 'private - searching' }
MCPToolSenders >> matchingClassReferencesForClassNamed: aClassName inCompiledMethods: compiledMethods [

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
MCPToolSenders >> matchingCompiledMethodsForTarget: targetString mode: mode scopeQuery: query inCompiledMethods: compiledMethods [

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
MCPToolSenders >> matchingMethodSendersForSelector: aSelectorSymbol inCompiledMethods: compiledMethods [

	| specialSelectorIndex |
	specialSelectorIndex := Smalltalk specialSelectorIndexOrNil:
		                        aSelectorSymbol.
	^ (compiledMethods select: [ :eachMethod |
		   eachMethod
			   hasSelector: aSelectorSymbol
			   specialSelectorIndex: specialSelectorIndex ]) asArray
]

{ #category : 'private - searching' }
MCPToolSenders >> matchingVariableReferencesNamed: aVariableName scopeQuery: query inCompiledMethods: compiledMethods [

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
MCPToolSenders >> modeFromArguments: arguments [

	| mode |
	mode := (self stringArgumentNamed: 'mode' in: arguments) ifNil: [
		        Error signal: 'mode is required.' ].
	mode := mode asLowercase.
	mode = 'methodsenders' ifTrue: [ ^ 'method' ].
	mode = 'classreferences' ifTrue: [ ^ 'class' ].
	mode = 'variablereferences' ifTrue: [ ^ 'variable' ].
	(#( 'method' 'class' 'variable' ) includes: mode) ifTrue: [ ^ mode ].
	Error signal: 'mode must be one of method, class, or variable.'
]

{ #category : 'private - results' }
MCPToolSenders >> queryDescriptionForMode: mode [

	mode = 'method' ifTrue: [ ^ 'method senders' ].
	mode = 'class' ifTrue: [ ^ 'class references' ].
	mode = 'variable' ifTrue: [ ^ 'variable references' ].
	^ 'senders or references'
]

{ #category : 'private - schema' }
MCPToolSenders >> senderEntrySchema [

	^ MCPStructureProperties new
		  name: 'sender';
		  type: 'object';
		  description:
			  'A method matching the requested sender or reference query.';
		  properties: {
				  (self
					   schemaPropertyNamed: 'selector'
					   type: 'string'
					   description: 'The selector of the matching method.').
				  (self
					   schemaPropertyNamed: 'className'
					   type: 'string'
					   description:
						   'The base class that defines the matching method.').
				  ((self
					    schemaPropertyNamed: 'side'
					    type: 'string'
					    description:
						    'The side on which the matching method is defined.')
					   enum: #( 'instance' 'class' );
					   yourself).
				  (self
					   schemaPropertyNamed: 'packageName'
					   type: 'string'
					   description: 'The package that owns the matching method.').
				  (self
					   schemaPropertyNamed: 'isExtension'
					   type: 'boolean'
					   description:
					   'Whether the matching method is an extension on its class package.').
				  (self
					   schemaPropertyNamed: 'protocol'
					   type: 'string'
					   description:
					   'The protocol/category containing the matching method.').
				  (self
					   schemaPropertyNamed: 'source'
					   type: 'string'
					   description:
					   'The formatted source code of the matching method when includeSource=true.') };
		  required:
			  #( 'selector' 'className' 'side' 'packageName' 'isExtension'
			     'protocol' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - results' }
MCPToolSenders >> successSummaryForTarget: targetString mode: mode scope: scope returnedCount: returnedCount totalCount: totalCount truncated: truncated [

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
MCPToolSenders >> targetLabelFor: targetString mode: mode [

	mode = 'method' ifTrue: [ ^ '#' , targetString ].
	^ targetString
]

{ #category : 'private - searching' }
MCPToolSenders >> variableBindingsNamed: aVariableName inBehaviors: behaviors [

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
