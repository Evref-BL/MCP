Class {
	#name : 'MCPToolFindClasses',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - filtering' }
MCPToolFindClasses >> classEntriesFrom: classes filter: filterPattern filterMode: filterMode caseSensitive: caseSensitive [

	| entries matcher |
	matcher := self
		           matcherForPattern: filterPattern
		           mode: filterMode
		           caseSensitive: caseSensitive.
	entries := OrderedCollection new.
	classes do: [ :eachClass |
		| entry |
		entry := (MCPClassInfo fromClass: eachClass) asDictionary.
		(matcher value: (self filterTextForClassEntry: entry)) ifTrue: [
			entries add: entry ] ].
	^ entries asArray
]

{ #category : 'private - schema' }
MCPToolFindClasses >> classEntrySchema [

	^ MCPStructureProperties new
		  name: 'classEntry';
		  type: 'object';
		  description: 'Structured metadata for one queried class.';
		  properties: self classInfoDataProperties;
		  required:
			  #( 'className' 'superclassName' 'packageName' 'tag' 'instanceSlotNames'
			     'classSlotNames' 'subclassNames' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - schema' }
MCPToolFindClasses >> classInfoDataProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'className'
			   type: 'string'
			   description: 'The class name.').
		  (self
			   schemaPropertyNamed: 'superclassName'
			   type: 'string'
			   description:
			   'The direct superclass of the class, or an empty string for the root.').
		  (self
			   schemaPropertyNamed: 'packageName'
			   type: 'string'
			   description: 'The package that defines the class.').
		  (self
			   schemaPropertyNamed: 'tag'
			   type: 'string'
			   description: 'The package tag assigned to the class.').
		  (self
			   stringArraySchemaNamed: 'instanceSlotNames'
			   description: 'The instance-side slots defined on the class.'
			   itemDescription: 'An instance-side slot name.').
		  (self
			   stringArraySchemaNamed: 'classSlotNames'
			   description: 'The class-side slots defined on the class.'
			   itemDescription: 'A class-side slot name.').
		  (self
			   stringArraySchemaNamed: 'subclassNames'
			   description: 'The direct subclasses of the class.'
			   itemDescription: 'A subclass name.') }
]

{ #category : 'private - arguments' }
MCPToolFindClasses >> classNamesFromArguments: arguments [

	^ self stringCollectionArgumentNamed: 'classNames' in: arguments
]

{ #category : 'private - querying' }
MCPToolFindClasses >> classesForPackageNames: packageNames [

	| classes |
	classes := IdentitySet new.
	packageNames do: [ :eachName |
		(self resolvedPackageNamed: eachName) classes do: [ :eachClass |
			classes add: eachClass instanceSide ] ].
	^ self sortedClassesByName: classes
]

{ #category : 'private - querying' }
MCPToolFindClasses >> classesForScope: scope packageNames: packageNames classNames: classNames [

	scope = 'image' ifTrue: [
		| classes |
		classes := IdentitySet new.
		Smalltalk globals allClasses do: [ :eachClass |
			classes add: eachClass instanceSide ].
		^ self sortedClassesByName: classes ].
	scope = 'packages' ifTrue: [
		packageNames ifEmpty: [
			Error signal: 'packageNames is required when scope=packages.' ].
		^ self classesForPackageNames: packageNames ].
	scope = 'classes' ifTrue: [
		classNames ifEmpty: [
			Error signal: 'classNames is required when scope=classes.' ].
		^ self resolvedClassesNamed: classNames ].
	scope = 'hierarchy' ifTrue: [
		classNames ifEmpty: [
			Error signal: 'classNames is required when scope=hierarchy.' ].
		^ self hierarchyClassesNamed: classNames ].
	Error signal: 'Unsupported scope: ' , scope
]

{ #category : 'defaults' }
MCPToolFindClasses >> defaultDescription [

	^ 'List classes in the selected scope and optionally filter them by class metadata. Use inspect-class when you already know the class to inspect.'
]

{ #category : 'defaults' }
MCPToolFindClasses >> defaultIcons [

	| packageNamesProperty classNamesProperty classesProperty |
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
	classesProperty := self
		                   schemaPropertyNamed: 'classes'
		                   type: 'array'
		                   description:
		                   'The class entries returned for the requested page.'.
	classesProperty items: self classEntrySchema.
	^ { (self
		          pngCompositeBaseIconNamed: #class
		          badgeIconNamed: #zoomIn) }
]

{ #category : 'defaults' }
MCPToolFindClasses >> defaultInputSchema [

	| scopeProperty packageNamesProperty classNamesProperty filterModeProperty |
	scopeProperty := MCPStructureProperties new
		                 name: 'scope';
		                 type: 'string';
		                 description:
			                 'Where to search for classes. Defaults to image.';
		                 enum: #( 'image' 'packages' 'hierarchy' 'classes' );
		                 default: 'image';
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
			                      'How the class filter is matched. Defaults to substring.';
		                      enum:
			                      #( 'substring' 'prefix' 'exact' 'regex' );
		                      default: 'substring';
		                      yourself.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  scopeProperty.
				  packageNamesProperty.
				  classNamesProperty.
				  (MCPStructureProperties new
					   name: 'filter';
					   type: 'string';
					   description:
						   'Optional filter applied to class metadata such as names, package, tag, slots, and subclasses.';
					   yourself).
				  filterModeProperty.
				  (MCPStructureProperties new
					   name: 'caseSensitive';
					   type: 'boolean';
					   description:
						   'Whether filter matching is case-sensitive. Defaults to false.';
					   default: false;
					   yourself).
				  (MCPStructureProperties new
					   name: 'limit';
					   type: 'integer';
					   description:
						   'Maximum number of matching classes to return. Defaults to 100. Use 0 to request counts only.';
					   default: 100;
					   yourself).
				  (MCPStructureProperties new
					   name: 'offset';
					   type: 'integer';
					   description:
						   'Zero-based pagination offset applied after filtering. Defaults to 0.';
					   default: 0;
					   yourself) };
		  required: #(  );
		  yourself
]

{ #category : 'defaults' }
MCPToolFindClasses >> defaultName [

	^ 'find-classes'
]

{ #category : 'defaults' }
MCPToolFindClasses >> defaultOutputSchema [

	| packageNamesProperty classNamesProperty classesProperty |
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
	classesProperty := self
		                   schemaPropertyNamed: 'classes'
		                   type: 'array'
		                   description:
		                   'The class entries returned for the requested page.'.
	classesProperty items: self classEntrySchema.
	^ self
		                standardOutputSchemaForDataProperties: {
				                ((self
					                  schemaPropertyNamed: 'scope'
					                  type: 'string'
					                  description:
						                  'The scope used to search for classes.')
					                 enum:
						                 #( 'image' 'packages' 'hierarchy' 'classes' );
					                 yourself).
				                packageNamesProperty.
				                classNamesProperty.
				                (self
					                 integerSchemaPropertyNamed: 'returnedCount'
					                 description:
					                 'The number of class entries returned in this page.').
				                (self
					                 integerSchemaPropertyNamed: 'totalCount'
					                 description:
					                 'The total number of matching classes before pagination.').
				                (self
					                 integerSchemaPropertyNamed: 'offset'
					                 description:
					                 'The zero-based pagination offset that was applied.').
				                (self
					                 integerSchemaPropertyNamed: 'limit'
					                 description:
					                 'The maximum number of class entries requested.').
				                (self
					                 schemaPropertyNamed: 'truncated'
					                 type: 'boolean'
					                 description:
					                 'Whether additional matching classes exist beyond the returned page.').
				                classesProperty }
		                required:
			                #( 'scope' 'packageNames' 'classNames' 'returnedCount'
			                   'totalCount' 'offset' 'limit' 'truncated'
			                   'classes' )
]

{ #category : 'defaults' }
MCPToolFindClasses >> defaultTitle [

	^ 'Find Pharo Classes'
]

{ #category : 'private - results' }
MCPToolFindClasses >> errorResultForError: anError scope: scope [

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
MCPToolFindClasses >> executeWithArguments: arguments [

	| caseSensitive classEntries classNames data endIndex filterPattern filterMode limit offset packageNames pagedEntries requestedScope scope startIndex totalCount truncated |
	filterPattern := self stringArgumentNamed: 'filter' in: arguments.
	filterMode := self normalizedFilterModeFrom: arguments.
	caseSensitive := self
		                 booleanArgumentNamed: 'caseSensitive'
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
		                  ifNotNil: [ :value | value asLowercase ].
	^ [
	  scope := self scopeFromArguments: arguments.
	  packageNames := self packageNamesFromArguments: arguments.
	  classNames := self classNamesFromArguments: arguments.
	  classEntries := self
		                  classEntriesFrom: (self
				                   classesForScope: scope
				                   packageNames: packageNames
				                   classNames: classNames)
		                  filter: filterPattern
		                  filterMode: filterMode
		                  caseSensitive: caseSensitive.
	  totalCount := classEntries size.
	  startIndex := offset + 1.
	  pagedEntries := (startIndex > totalCount or: [ limit = 0 ])
		                  ifTrue: [ #(  ) ]
		                  ifFalse: [
			                  endIndex := totalCount min: offset + limit.
			                  (classEntries copyFrom: startIndex to: endIndex)
				                  asArray ].
	  truncated := offset + pagedEntries size < totalCount.
	  data := {
		          (#scope -> scope).
		          (#packageNames -> packageNames).
		          (#classNames -> classNames).
		          (#returnedCount -> pagedEntries size).
		          (#totalCount -> totalCount).
		          (#offset -> offset).
		          (#limit -> limit).
		          (#truncated -> truncated).
		          (#classes -> pagedEntries) } asDictionary.
	  self
		  successResultText: (self
				   successSummaryForScope: scope
				   returnedCount: pagedEntries size
				   totalCount: totalCount
				   truncated: truncated)
		  data: data ]
		  on: Exception
		  do: [ :error |
		  self errorResultForError: error scope: requestedScope ]
]

{ #category : 'private - results' }
MCPToolFindClasses >> failureMessageForScope: scope error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to query classes [scope=';
			  nextPutAll: scope;
			  nextPutAll: '] (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'private - filtering' }
MCPToolFindClasses >> filterTextForClassEntry: anEntry [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: (anEntry at: #className);
			  nextPutAll: ' ';
			  nextPutAll: (anEntry at: #superclassName);
			  nextPutAll: ' ';
			  nextPutAll: (anEntry at: #packageName);
			  nextPutAll: ' ';
			  nextPutAll: (anEntry at: #tag).
		  (anEntry at: #instanceSlotNames) do: [ :each |
			  stream
				  space;
				  nextPutAll: each ].
		  (anEntry at: #classSlotNames) do: [ :each |
			  stream
				  space;
				  nextPutAll: each ].
		  (anEntry at: #subclassNames) do: [ :each |
			  stream
				  space;
				  nextPutAll: each ] ]
]

{ #category : 'private - querying' }
MCPToolFindClasses >> hierarchyClassesNamed: classNames [

	| classes |
	classes := IdentitySet new.
	(self resolvedClassesNamed: classNames) do: [ :eachClass |
		eachClass withAllSuperAndSubclasses do: [ :relatedClass |
			classes add: relatedClass instanceSide ] ].
	^ self sortedClassesByName: classes
]

{ #category : 'private - arguments' }
MCPToolFindClasses >> packageNamesFromArguments: arguments [

	^ self stringCollectionArgumentNamed: 'packageNames' in: arguments
]

{ #category : 'private - querying' }
MCPToolFindClasses >> resolvedClassNamed: className [

	^ Smalltalk globals
		  at: className asSymbol
		  ifAbsent: [ MCPCommandError signalMissingClassNamed: className ]
]

{ #category : 'private - querying' }
MCPToolFindClasses >> resolvedClassesNamed: classNames [

	| classes |
	classes := IdentitySet new.
	classNames do: [ :eachName |
		classes add: (self resolvedClassNamed: eachName) instanceSide ].
	^ self sortedClassesByName: classes
]

{ #category : 'private - querying' }
MCPToolFindClasses >> resolvedPackageNamed: packageName [

	^ PackageOrganizer default
		  packageNamed: packageName asSymbol
		  ifAbsent: [
		  MCPCommandError signalMissingPackageNamed: packageName ]
]

{ #category : 'private - arguments' }
MCPToolFindClasses >> scopeFromArguments: arguments [

	| scope |
	scope := (self stringArgumentNamed: 'scope' in: arguments)
		         ifNil: [ 'image' ]
		         ifNotNil: [ :value | value asLowercase ].
	(#( 'image' 'packages' 'hierarchy' 'classes' ) includes: scope)
		ifFalse: [
			Error signal:
				'scope must be one of image, packages, hierarchy, or classes.' ].
	^ scope
]

{ #category : 'private - querying' }
MCPToolFindClasses >> sortedClassesByName: someClasses [

	^ (someClasses asSortedCollection: [ :left :right |
		   left name <= right name ]) asArray
]

{ #category : 'private - results' }
MCPToolFindClasses >> successSummaryForScope: scope returnedCount: returnedCount totalCount: totalCount truncated: truncated [

	^ String streamContents: [ :stream |
		  stream
			  print: returnedCount;
			  nextPutAll: ' classes found [scope=';
			  nextPutAll: scope;
			  nextPutAll: '] (';
			  print: totalCount;
			  nextPutAll: ' matched'.
		  truncated ifTrue: [ stream nextPutAll: ', more available' ].
		  stream nextPutAll: ').' ]
]
