"
Lists methods in a chosen scope with optional filtering. It is the general method discovery tool.
"
Class {
	#name : 'MCPToolFindMethods',
	#superclass : 'MCPToolQuery',
	#traits : '{} + TMCPMethodTool',
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

	^ 'List methods and optionally filter returned method entries. Omit packageNames, classNames, hierarchyClassNames, subclassClassNames, and parentClassNames to search all methods. Use packageNames for package-defined and extension methods, classNames for exact classes, hierarchyClassNames for hierarchy roots including the root, subclassClassNames for GUI Subclasses-style scope, and parentClassNames for GUI Parents-style scope. Multiple scope properties are unioned. Use filterMode=exact with filterTargets=selector and caseSensitive=true to find implementors. Use filterMode=selectorReference to find senders of the selector named by filter. Use filterMode=classReference to find methods that reference the class named by filter. Use filterMode=variableReference to find methods that reference the variable named by filter. Reference lookup modes require filter and ignore filterTargets. Use where for recursive boolean predicates and relation predicates; method predicates can use equivalentTo with a className/selector/classSide method reference to match AST-equivalent methods.'
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
					           'Method scope.') , (self
					           methodQueryFilteringInputPropertiesWithFilterDescription:
						           'For field filtering, the text matched against method-entry fields. For reference lookup modes, the referenced selector, class, or variable name; required when filterMode is selectorReference, classReference, or variableReference.'
					           extraProperties: {
							           filterTargetsProperty.
							           self wherePredicateSchemaProperty }
					           includeSourceDescription:
						           'Whether to include method source code in each result entry.'
					           limitDescription:
						           'Maximum number of matching methods to return. Use 0 to request counts only.');
		          required: #(  );
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

{ #category : 'private - results' }
MCPToolFindMethods >> failureMessageForScope: scopeSummary error: anError [

	^ self
		  scopeQueryFailureMessageFor: 'methods'
		  scope: scopeSummary
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

	| entries needsSourceText whereContext |
	needsSourceText := queryRequest includeSource.
	whereContext := self newWhereContext.
	entries := OrderedCollection new.
	compiledMethods do: [ :eachMethod |
		| entry evaluation info sourceText |
		info := MCPCompiledMethodInfo fromMethod: eachMethod.
		sourceText := needsSourceText
			              ifTrue: [ info source ]
			              ifFalse: [ nil ].
		entry := info asDictionaryIncludingSource:
			         queryRequest includeSource.
		queryRequest includeSource ifTrue: [
			entry at: #source put: sourceText ].
		evaluation := self
			              whereEvaluationForEntityKind: #method
			              entry: entry
			              object: eachMethod
			              context: whereContext.
		(queryRequest whereSpec matchesEvaluation: evaluation) ifTrue: [
			entries add: entry ] ].
	^ self sortedMethodEntries: entries
]

{ #category : 'private - methods' }
MCPToolFindMethods >> methodEntriesFromQueryRequest: queryRequest [

	| entries matcher needsSourceForFiltering whereContext |
	matcher := self
		           matcherForPattern: queryRequest filterPattern
		           mode: queryRequest filterMode
		           caseSensitive: queryRequest caseSensitive.
	needsSourceForFiltering := queryRequest needsSourceForFiltering.
	whereContext := self newWhereContext.
	entries := OrderedCollection new.
	queryRequest scopeQuery methodsDo: [ :eachMethod |
		| entry evaluation info matchesFilter sourceText |
		info := MCPCompiledMethodInfo fromMethod: eachMethod.
		entry := info asDictionaryIncludingSource: false.
		sourceText := needsSourceForFiltering
			              ifTrue: [ info source ]
			              ifFalse: [ nil ].
		matchesFilter := queryRequest hasFilterPattern not or: [
			                 self
				                 matchesFilterOnMethodEntry: entry
				                 sourceText: sourceText
				                 matcher: matcher
				                 targets: queryRequest filterTargets ].
		evaluation := self
			              whereEvaluationForEntityKind: #method
			              entry: entry
			              object: eachMethod
			              context: whereContext.
		(matchesFilter and: [
			 queryRequest whereSpec matchesEvaluation: evaluation ]) ifTrue: [
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

{ #category : 'private - schema' }
MCPToolFindMethods >> methodEntrySchemaNamed: entryName description: entryDescription subjectDescription: subjectDescription selectorDescription: selectorDescription sourceDescription: sourceDescription [

	^ MCPStructureProperties new
		  name: entryName;
		  type: 'object';
		  description: entryDescription;
		  properties: {
				  (self
					   schemaPropertyNamed: 'selector'
					   type: 'string'
					   description: selectorDescription).
				  (self
					   schemaPropertyNamed: 'className'
					   type: 'string'
					   description:
						   'The base class that defines the ' , subjectDescription , '.').
				  (self
					   stringEnumSchemaPropertyNamed: 'side'
					   description:
						   'The side on which the ' , subjectDescription
						   , ' is defined.'
					   values: #( 'instance' 'class' )).
				  (self
					   schemaPropertyNamed: 'packageName'
					   type: 'string'
					   description:
						   'The package that owns the ' , subjectDescription , '.').
				  (self
					   booleanSchemaPropertyNamed: 'isExtension'
					   description: 'Whether the ' , subjectDescription
						   , ' is an extension on its class package.').
				  (self
					   schemaPropertyNamed: 'protocol'
					   type: 'string'
					   description:
						   'The protocol/category containing the ' , subjectDescription
						   , '.').
				  (self
					   schemaPropertyNamed: 'source'
					   type: 'string'
					   description: sourceDescription) };
		  required:
			  #( 'selector' 'className' 'side' 'packageName' 'isExtension'
			     'protocol' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - schema' }
MCPToolFindMethods >> methodQueryFilteringInputPropertiesWithFilterDescription: filterDescription extraProperties: extraProperties includeSourceDescription: includeSourceDescription limitDescription: limitDescription [

	| properties |
	properties := OrderedCollection new.
	properties add: (self
			 schemaPropertyNamed: 'filter'
			 type: 'string'
			 description: filterDescription).
	extraProperties ifNotNil: [ properties addAll: extraProperties ].
	properties add: (self
			 stringEnumSchemaPropertyNamed: 'filterMode'
			 description:
			 'How the filter is matched or interpreted. Reference modes on find-methods are selectorReference for senders, classReference for class references, and variableReference for variable references.'
			 values: self supportedFilterModes
			 default: self defaultFilterMode).
	properties add: (self
			 booleanSchemaPropertyNamed: 'caseSensitive'
			 description:
			 'Whether filter matching is case-sensitive. Reference lookup modes ignore this option.'
			 default: true).
	properties add: (self
			 booleanSchemaPropertyNamed: 'includeSource'
			 description: includeSourceDescription
			 default: false).
	properties add: (self
			 integerSchemaPropertyNamed: 'limit'
			 description: limitDescription
			 default: 100).
	properties add: (self
			 integerSchemaPropertyNamed: 'offset'
			 description:
			 'Zero-based pagination offset applied after filtering.'
			 default: 0).
	^ properties asArray
]

{ #category : 'private - results' }
MCPToolFindMethods >> methodQueryResultDataForPage: page entriesKey: entriesKey [

	^ self queryResultDataFrom: nil page: page entriesKey: entriesKey
]

{ #category : 'private - schema' }
MCPToolFindMethods >> methodQueryScopeInputPropertiesWithScopeDescription: scopeDescription [

	| classNamesProperty hierarchyClassNamesProperty packageNamesProperty parentClassNamesProperty sideProperty subclassClassNamesProperty |
	sideProperty := self
		                stringEnumSchemaPropertyNamed: 'side'
		                description:
		                'Which method side to search. instance searches instance-side methods, class searches class-side methods, and both searches both sides.'
		                values: #( 'instance' 'class' 'both' )
		                default: 'both'.
	packageNamesProperty := self
		                        stringArraySchemaNamed: 'packageNames'
		                        description: scopeDescription
			                        ,
			                        ' Package names whose defined methods and extension methods are included. Omit all method scope properties to search all methods. Combine with other method scope properties to union scopes.'
		                        itemDescription: 'A package name.'.
	classNamesProperty := self
		                      stringArraySchemaNamed: 'classNames'
		                      description: scopeDescription
			                      ,
			                      ' Exact class names whose methods are included. Omit all method scope properties to search all methods. Combine with other method scope properties to union scopes.'
		                      itemDescription: 'A class name.'.
	hierarchyClassNamesProperty := self
		                               stringArraySchemaNamed:
		                               'hierarchyClassNames'
		                               description: scopeDescription
			                               ,
			                               ' Class names whose superclasses, subclasses, and own methods are included. Omit all method scope properties to search all methods. Combine with other method scope properties to union scopes.'
		                               itemDescription:
		                               'A hierarchy root class name.'.
	subclassClassNamesProperty := self
		                              stringArraySchemaNamed:
		                              'subclassClassNames'
		                              description: scopeDescription
			                              ,
			                              ' Class names whose subclass methods are included. The named classes are excluded unless classNames also includes them. Combine with other method scope properties to union scopes.'
		                              itemDescription:
		                              'A class name whose subclasses are included.'.
	parentClassNamesProperty := self
		                            stringArraySchemaNamed:
		                            'parentClassNames'
		                            description: scopeDescription
			                            ,
			                            ' Class names whose superclass methods are included. The named classes are excluded unless classNames also includes them. Combine with other method scope properties to union scopes.'
		                            itemDescription:
		                            'A class name whose superclasses are included.'.
	^ {
		  sideProperty.
		  packageNamesProperty.
		  classNamesProperty.
		  hierarchyClassNamesProperty.
		  subclassClassNamesProperty.
		  parentClassNamesProperty }
]

{ #category : 'private - methods' }
MCPToolFindMethods >> methodScopeQueryFromRequest: request [

	^ MCPCompiledMethodScopeQuery new
		  packageNames:
			  (request stringCollectionArgumentNamed: 'packageNames');
		  classNames: (request stringCollectionArgumentNamed: 'classNames');
		  hierarchyClassNames:
			  (request stringCollectionArgumentNamed: 'hierarchyClassNames');
		  subclassClassNames:
			  (request stringCollectionArgumentNamed: 'subclassClassNames');
		  parentClassNames:
			  (request stringCollectionArgumentNamed: 'parentClassNames');
		  side: (request stringArgumentNamed: 'side' default: 'both');
		  yourself
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

	^ { (#scope -> (self classAndMethodScopeSummaryFromRequest: request)) }
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
		  successSummaryForScope:
		  (self classAndMethodScopeSummaryForScopeQuery:
			   queryRequest scopeQuery)
		  page: page
]

{ #category : 'private - results' }
MCPToolFindMethods >> successSummaryForScope: scopeSummary page: page [

	^ self
		  scopeQuerySuccessSummaryFor: 'methods'
		  scope: scopeSummary
		  page: page
]

{ #category : 'private - schema' }
MCPToolFindMethods >> supportedFilterModes [

	^ #( 'substring' 'prefix' 'exact' 'regex' )
	  , self referenceFilterModes
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
