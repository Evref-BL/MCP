"
Lists methods in a chosen scope with optional filtering. It is the general method discovery tool.
"
Class {
	#name : 'MCPToolFindMethods',
	#superclass : 'MCPToolMethodQuery',
	#traits : '{} + TMCPMethodTool',
	#classTraits : '{} + TMCPMethodTool classTrait',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - searching' }
MCPToolFindMethods >> classBindingForClassName: aClassName [

	| binding |
	binding := Smalltalk globals
		           associationAt: aClassName asSymbol
		           ifAbsent: [ ^ nil ].
	^ binding value isBehavior
		  ifTrue: [ binding ]
		  ifFalse: [ nil ]
]

{ #category : 'private - methods' }
MCPToolFindMethods >> classReferenceEntriesForQueryRequest: queryRequest [

	| className |
	className := queryRequest requiredFilterPatternForTool: self.
	^ self
		  methodEntriesFromMethods: (self
				   matchingClassReferencesForClassNamed: className
				   inMethods: queryRequest scopeQuery methods)
		  queryRequest: queryRequest
]

{ #category : 'defaults' }
MCPToolFindMethods >> defaultDescription [

	^ 'List methods in a scope and optionally filter returned method entries. Use filterMode=exact with filterTargets=selector and caseSensitive=true to find implementors. Use filterMode=selectorReference to find senders of the selector named by filter. Use filterMode=classReference to find methods that reference the class named by filter. Use filterMode=variableReference to find methods that reference the variable named by filter. Reference lookup modes require filter and ignore filterTargets.'
]

{ #category : 'private - request' }
MCPToolFindMethods >> defaultFilterMode [

	^ 'exact'
]

{ #category : 'private - request' }
MCPToolFindMethods >> defaultFilterTargets [

	^ #( 'selector' )
]

{ #category : 'defaults' }
MCPToolFindMethods >> defaultIcons [

	^ { (self pngCompositeBaseIconNamed: #page badgeIconNamed: #search) }
]

{ #category : 'defaults' }
MCPToolFindMethods >> defaultInputSchema [

	| filterTargetsProperty schema |
	filterTargetsProperty := self
		                         stringEnumArraySchemaNamed: 'filterTargets'
		                         description:
		                         'Optional method-entry fields matched by filter for field filtering. Ignored by reference lookup modes: selectorReference, classReference, and variableReference.'
		                         itemDescription: 'A filter target.'
		                         values: self supportedFilterTargets
		                         default: self defaultFilterTargets.
	schema := MCPStructureInputSchema new
		          type: 'object';
		          properties:
			          (self
				           methodQueryScopeInputPropertiesWithScopeDescription:
					           'Where to search for methods.') , (self
					           methodQueryFilteringInputPropertiesWithFilterDescription:
						           'For field filtering, the text matched against method-entry fields. For reference lookup modes, the referenced selector, class, or variable name; required when filterMode is selectorReference, classReference, or variableReference.'
					           extraProperties: { filterTargetsProperty }
					           includeSourceDescription:
						           'Whether to include method source code in each result entry.'
					           limitDescription:
						           'Maximum number of matching methods to return. Use 0 to request counts only.');
		          required: #(  );
		          oneOf: self scopeBranchSchemasForClassAndMethodQueries;
		          yourself.
	schema allOf: self requiredFilterSchemasForReferenceModes.
	^ schema
]

{ #category : 'defaults' }
MCPToolFindMethods >> defaultName [

	^ 'find-methods'
]

{ #category : 'defaults' }
MCPToolFindMethods >> defaultOutputSchema [

	^ self
		  minimalPagedQueryOutputSchemaForEntriesPropertyNamed: 'methods'
		  entriesDescription:
		  'The method entries returned for the requested page.'
		  entrySchema: self methodEntrySchema
		  itemNounPhrase: 'methods'
]

{ #category : 'defaults' }
MCPToolFindMethods >> defaultTitle [

	^ 'Find Methods'
]

{ #category : 'private - template' }
MCPToolFindMethods >> failureMessageForRequestedContext: requestedContext error: anError [

	^ self
		  failureMessageForScope: (requestedContext at: #scope)
		  error: anError
]

{ #category : 'private - results' }
MCPToolFindMethods >> failureMessageForScope: scope error: anError [

	^ self
		  scopeQueryFailureMessageFor: 'methods'
		  scope: scope
		  error: anError
]

{ #category : 'private - filtering' }
MCPToolFindMethods >> filterTextsForMethodEntry: anEntry sourceText: sourceText targets: filterTargets [

	| texts |
	texts := OrderedCollection new.
	filterTargets do: [ :each |
		each = 'selector' ifTrue: [ texts add: (anEntry at: #selector) ].
		each = 'class' ifTrue: [ texts add: (anEntry at: #className) ].
		each = 'package' ifTrue: [ texts add: (anEntry at: #packageName) ].
		each = 'protocol' ifTrue: [ texts add: (anEntry at: #protocol) ].
		each = 'source' ifTrue: [ texts add: sourceText ] ].
	^ texts asArray
]

{ #category : 'private - methods' }
MCPToolFindMethods >> implementorEntriesForQueryRequest: queryRequest [

	| compiledMethods selectorSymbol |
	selectorSymbol := queryRequest filterPattern asSymbol.
	compiledMethods := queryRequest scopeQuery methods select: [
		                   :eachMethod |
		                   eachMethod selector = selectorSymbol ].
	^ self
		  methodEntriesFromMethods: compiledMethods asArray
		  queryRequest: queryRequest
]

{ #category : 'private - filtering' }
MCPToolFindMethods >> matchesFilterOnMethodEntry: anEntry sourceText: sourceText matcher: aMatcher targets: filterTargets [

	^ (self
		   filterTextsForMethodEntry: anEntry
		   sourceText: sourceText
		   targets: filterTargets) anySatisfy: [ :each |
		  aMatcher value: each ]
]

{ #category : 'private - searching' }
MCPToolFindMethods >> matchingClassReferencesForClassNamed: aClassName inMethods: compiledMethods [

	| classBinding |
	classBinding := self classBindingForClassName: aClassName.
	classBinding ifNil: [
		Error signal: 'There is no class named ' , aClassName , '.' ].
	^ (compiledMethods select: [ :eachMethod |
		   self method: eachMethod referencesAnyVariable: { classBinding } ])
		  asArray
]

{ #category : 'private - searching' }
MCPToolFindMethods >> matchingSelectorReferencesForSelector: aSelectorSymbol inMethods: compiledMethods [

	| specialSelectorIndex |
	specialSelectorIndex := Smalltalk specialSelectorIndexOrNil:
		                        aSelectorSymbol.
	^ (compiledMethods select: [ :eachMethod |
		   eachMethod
			   hasSelector: aSelectorSymbol
			   specialSelectorIndex: specialSelectorIndex ]) asArray
]

{ #category : 'private - searching' }
MCPToolFindMethods >> matchingVariableReferencesNamed: aVariableName scopeQuery: query inMethods: compiledMethods [

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
MCPToolFindMethods >> method: aCompiledMethod referencesAnyVariable: variables [

	^ variables anySatisfy: [ :eachVariable |
		  eachVariable isAccessedIn: aCompiledMethod ]
]

{ #category : 'private - methods' }
MCPToolFindMethods >> methodEntriesFromMethods: compiledMethods queryRequest: queryRequest [

	| entries needsSourceText |
	needsSourceText := queryRequest includeSource.
	entries := OrderedCollection new.
	compiledMethods do: [ :eachMethod |
		| entry info sourceText |
		info := MCPCompiledMethodInfo fromMethod: eachMethod.
		sourceText := needsSourceText
			              ifTrue: [ info source ]
			              ifFalse: [ nil ].
		entry := info asDictionaryIncludingSource:
			         queryRequest includeSource.
		queryRequest includeSource ifTrue: [
			entry at: #source put: sourceText ].
		entries add: entry ].
	^ self sortedMethodEntries: entries
]

{ #category : 'private - methods' }
MCPToolFindMethods >> methodEntriesFromQueryRequest: queryRequest [

	| entries matcher needsSourceForFiltering |
	matcher := self
		           matcherForPattern: queryRequest filterPattern
		           mode: queryRequest filterMode
		           caseSensitive: queryRequest caseSensitive.
	needsSourceForFiltering := queryRequest needsSourceForFiltering.
	entries := OrderedCollection new.
	queryRequest scopeQuery methodsDo: [ :eachMethod |
		| entry info sourceText |
		info := MCPCompiledMethodInfo fromMethod: eachMethod.
		entry := info asDictionaryIncludingSource: false.
		sourceText := needsSourceForFiltering
			              ifTrue: [ info source ]
			              ifFalse: [ nil ].
		(queryRequest hasFilterPattern not or: [
			 self
				 matchesFilterOnMethodEntry: entry
				 sourceText: sourceText
				 matcher: matcher
				 targets: queryRequest filterTargets ]) ifTrue: [
			queryRequest includeSource ifTrue: [
				sourceText ifNil: [ sourceText := info source ].
				entry at: #source put: sourceText ].
			entries add: entry ] ].
	^ self sortedMethodEntries: entries
]

{ #category : 'private - schema' }
MCPToolFindMethods >> methodEntrySchema [

	^ self
		  methodEntrySchemaNamed: 'method'
		  description: 'A method matching the query.'
		  subjectDescription: 'method'
		  selectorDescription: 'The selector name.'
		  sourceDescription:
		  'The formatted source code of the method when includeSource=true.'
]

{ #category : 'private - template' }
MCPToolFindMethods >> queryEntriesForQueryRequest: queryRequest [

	queryRequest usesSelectorReferenceLookup ifTrue: [
		^ self selectorReferenceEntriesForQueryRequest: queryRequest ].
	queryRequest usesClassReferenceLookup ifTrue: [
		^ self classReferenceEntriesForQueryRequest: queryRequest ].
	queryRequest usesVariableReferenceLookup ifTrue: [
		^ self variableReferenceEntriesForQueryRequest: queryRequest ].
	queryRequest usesImplementorLookup ifTrue: [
		^ self implementorEntriesForQueryRequest: queryRequest ].
	^ self methodEntriesFromQueryRequest: queryRequest
]

{ #category : 'private - template' }
MCPToolFindMethods >> queryRequestFromToolRequest: request [

	^ MCPFindMethodsRequest fromRequest: request tool: self
]

{ #category : 'private - template' }
MCPToolFindMethods >> queryResultDataForQueryRequest: queryRequest page: page [

	^ self methodQueryResultDataForPage: page entriesKey: #methods
]

{ #category : 'private - schema' }
MCPToolFindMethods >> referenceFilterModes [

	^ #( 'selectorReference' 'classReference' 'variableReference' )
]

{ #category : 'private - template' }
MCPToolFindMethods >> requestedContextFromRequest: request [

	^ { (#scope
	   -> (request stringArgumentNamed: 'scope' default: 'image')) }
		  asDictionary
]

{ #category : 'private - schema' }
MCPToolFindMethods >> requiredFilterSchemasForReferenceModes [

	| conditionSchema |
	conditionSchema := MCPStructureInputSchema new
		                   type: 'object';
		                   properties: { (self
				                    stringEnumSchemaPropertyNamed: 'filterMode'
				                    description:
					                    'A reference lookup mode. selectorReference finds senders, classReference finds class references, and variableReference finds variable references.'
				                    values: self referenceFilterModes) };
		                   required: #( 'filterMode' );
		                   additionalProperties: true;
		                   yourself.
	^ { (self
		   conditionalInputSchemaIf: conditionSchema
		   thenRequired: #( 'filter' )) }
]

{ #category : 'private - methods' }
MCPToolFindMethods >> selectorReferenceEntriesForQueryRequest: queryRequest [

	| selector |
	selector := queryRequest requiredFilterPatternForTool: self.
	^ self
		  methodEntriesFromMethods: (self
				   matchingSelectorReferencesForSelector: selector asSymbol
				   inMethods: queryRequest scopeQuery methods)
		  queryRequest: queryRequest
]

{ #category : 'private - methods' }
MCPToolFindMethods >> sortedMethodEntries: entries [

	^ (entries asSortedCollection: [ :left :right |
		   (self methodEntryLabel: left) <= (self methodEntryLabel: right) ])
		  asArray
]

{ #category : 'private - template' }
MCPToolFindMethods >> successSummaryForQueryRequest: queryRequest page: page [

	^ self
		  successSummaryForScope: queryRequest scopeQuery scope
		  returnedCount: (page at: #returnedCount)
		  totalCount: (page at: #totalCount)
		  truncated: (page at: #truncated)
]

{ #category : 'private - results' }
MCPToolFindMethods >> successSummaryForScope: scope returnedCount: returnedCount totalCount: totalCount truncated: truncated [

	^ self
		  scopeQuerySuccessSummaryFor: 'methods'
		  scope: scope
		  returnedCount: returnedCount
		  totalCount: totalCount
		  truncated: truncated
]

{ #category : 'private - schema' }
MCPToolFindMethods >> supportedFilterModes [

	^ super supportedFilterModes , self referenceFilterModes
]

{ #category : 'private - request' }
MCPToolFindMethods >> supportedFilterTargets [

	^ #( 'selector' 'class' 'package' 'protocol' 'source' )
]

{ #category : 'private - searching' }
MCPToolFindMethods >> variableBindingsNamed: aVariableName inBehaviors: behaviors [

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

{ #category : 'private - methods' }
MCPToolFindMethods >> variableReferenceEntriesForQueryRequest: queryRequest [

	| variableName |
	variableName := queryRequest requiredFilterPatternForTool: self.
	^ self
		  methodEntriesFromMethods: (self
				   matchingVariableReferencesNamed: variableName
				   scopeQuery: queryRequest scopeQuery
				   inMethods: queryRequest scopeQuery methods)
		  queryRequest: queryRequest
]
