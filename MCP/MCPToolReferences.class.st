"
Finds methods that reference a selector, class, or variable. It is the main caller and usage query tool.
"
Class {
	#name : 'MCPToolReferences',
	#superclass : 'MCPToolMethodQuery',
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

	| modeProperty |
	modeProperty := self
		                stringEnumSchemaPropertyNamed: 'mode'
		                description:
		                'Which reference query to run. Use method for message sends to a selector, class for references to a class/global binding, and variable for variable or slot references.'
		                values: #( 'method' 'class' 'variable' ).
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   schemaPropertyNamed: 'target'
					   type: 'string'
					   description:
						   'The selector, class name, or variable name to look for, depending on mode.').
				  modeProperty }
			  , (self methodQueryScopeInputPropertiesWithScopeDescription:
						   'Where to search for references. Defaults to image.')
			  , (self
					   methodQueryFilteringInputPropertiesWithFilterDescription:
						   'Optional filter applied to the matching reference methods after target lookup.'
					   extraProperties: #(  )
					   includeSourceDescription:
						   'Whether to include method source code in each result entry. Defaults to false.'
					   limitDescription:
						   'Maximum number of matching methods to return. Defaults to 100. Use 0 to request counts only.');
		  required: #( 'target' 'mode' );
		  oneOf: self scopeBranchSchemasForClassAndMethodQueries;
		  yourself
]

{ #category : 'defaults' }
MCPToolReferences >> defaultName [

	^ 'references'
]

{ #category : 'defaults' }
MCPToolReferences >> defaultOutputSchema [

	^ self
		  minimalPagedQueryOutputSchemaForEntriesPropertyNamed: 'references'
		  entriesDescription:
		  'The matching methods returned for the requested page. Each entry is a method that references the requested target.'
		  entrySchema: self senderEntrySchema
		  itemNounPhrase: 'matching methods'
]

{ #category : 'defaults' }
MCPToolReferences >> defaultTitle [

	^ 'Find References'
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
MCPToolReferences >> matchingClassReferencesForClassNamed: aClassName inMethods: compiledMethods [

	| classBinding classSymbol |
	classBinding := self classBindingForClassName: aClassName.
	classBinding ifNil: [
		Error signal: 'There is no class named ' , aClassName , '.' ].
	classSymbol := aClassName asSymbol.
	^ (compiledMethods select: [ :eachMethod |
		   (self method: eachMethod referencesAnyVariable: { classBinding })
			   or: [ eachMethod hasSelector: classSymbol ] ]) asArray
]

{ #category : 'private - searching' }
MCPToolReferences >> matchingMethodSendersForSelector: aSelectorSymbol inMethods: compiledMethods [

	| specialSelectorIndex |
	specialSelectorIndex := Smalltalk specialSelectorIndexOrNil:
		                        aSelectorSymbol.
	^ (compiledMethods select: [ :eachMethod |
		   eachMethod
			   hasSelector: aSelectorSymbol
			   specialSelectorIndex: specialSelectorIndex ]) asArray
]

{ #category : 'private - searching' }
MCPToolReferences >> matchingMethodsForTarget: targetString mode: mode scopeQuery: query inMethods: compiledMethods [

	mode = 'method' ifTrue: [
		^ self
			  matchingMethodSendersForSelector: targetString asSymbol
			  inMethods: compiledMethods ].
	mode = 'class' ifTrue: [
		^ self
			  matchingClassReferencesForClassNamed: targetString
			  inMethods: compiledMethods ].
	mode = 'variable' ifTrue: [
		^ self
			  matchingVariableReferencesNamed: targetString
			  scopeQuery: query
			  inMethods: compiledMethods ].
	Error signal: 'Unsupported mode: ' , mode
]

{ #category : 'private - searching' }
MCPToolReferences >> matchingVariableReferencesNamed: aVariableName scopeQuery: query inMethods: compiledMethods [

	| variables |
	variables := self
		             variableBindingsNamed: aVariableName
		             inBehaviors: query behaviors.
	variables ifEmpty: [
		Error signal: 'No variable named ' , aVariableName
			, ' is accessible in the requested scope.' ].
	^ (compiledMethods select: [ :eachMethod |
		   self method: eachMethod referencesAnyVariable: variables ])
		  asArray
]

{ #category : 'private - searching' }
MCPToolReferences >> method: aCompiledMethod referencesAnyVariable: variables [

	^ variables anySatisfy: [ :eachVariable |
		  eachVariable isAccessedIn: aCompiledMethod ]
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
	compiledMethods := query methods.
	^ self
		  methodEntriesFrom: (self
				   matchingMethodsForTarget: (parameters at: #target)
				   mode: (parameters at: #mode)
				   scopeQuery: query
				   inMethods: compiledMethods)
		  filter: (parameters at: #filterPattern)
		  filterMode: (parameters at: #filterMode)
		  caseSensitive: (parameters at: #caseSensitive)
		  includeSource: (parameters at: #includeSource)
]

{ #category : 'private - template' }
MCPToolReferences >> queryParametersFromArguments: arguments [

	| parameters |
	parameters := self methodQueryParametersFromArguments:
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
		  methodQueryResultDataForPage: page
		  entriesKey: #references
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
		  methodEntrySchemaNamed: 'reference'
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
