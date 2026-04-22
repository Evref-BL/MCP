Class {
	#name : 'MCPToolFindPackages',
	#superclass : 'MCPQueryTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolFindPackages >> defaultDescription [

	^ 'List packages in the image or in a project and optionally filter them by package metadata.'
]

{ #category : 'private - arguments' }
MCPToolFindPackages >> defaultFilterTargets [

	^ #( 'package' )
]

{ #category : 'defaults' }
MCPToolFindPackages >> defaultIcons [

	^ { (self pngCompositeBaseIconNamed: #open badgeIconNamed: #search) }
]

{ #category : 'defaults' }
MCPToolFindPackages >> defaultInputSchema [

	| filterModeProperty filterTargetsItemProperty filterTargetsProperty projectNamesProperty scopeProperty |
	scopeProperty := MCPStructureProperties new
		                 name: 'scope';
		                 type: 'string';
		                 description:
			                 'Where to search for packages. Defaults to image.';
		                 enum: #( 'image' 'project' );
		                 default: 'image';
		                 yourself.
	projectNamesProperty := self
		                        stringArraySchemaNamed: 'projectNames'
		                        description:
		                        'The project names that define the project scope. Required when scope=project.'
		                        itemDescription: 'A project name.'.
	filterModeProperty := MCPStructureProperties new
		                      name: 'filterMode';
		                      type: 'string';
		                      description:
			                      'How the package filter is matched. Defaults to substring.';
		                      enum:
			                      #( 'substring' 'prefix' 'exact' 'regex' );
		                      default: 'substring';
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
			                          'Optional package-entry fields matched by filter. Defaults to package.')
		                         items: filterTargetsItemProperty;
		                         default: self defaultFilterTargets;
		                         yourself.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  scopeProperty.
				  projectNamesProperty.
				  (MCPStructureProperties new
					   name: 'filter';
					   type: 'string';
					   description:
						   'Optional filter applied to the listed package-entry fields. Use filterTargets to choose which fields are matched.';
					   yourself).
				  filterTargetsProperty.
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
						   'Maximum number of matching packages to return. Defaults to 100. Use 0 to request counts only.';
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
MCPToolFindPackages >> defaultName [

	^ 'find-packages'
]

{ #category : 'defaults' }
MCPToolFindPackages >> defaultOutputSchema [

	| filterTargetsItemProperty filterTargetsProperty packageEntryProperty projectNamesProperty |
	projectNamesProperty := self
		                        stringArraySchemaNamed: 'projectNames'
		                        description:
		                        'The project names that define the project scope. Required when scope=project.'
		                        itemDescription: 'A project name.'.
	filterTargetsItemProperty := MCPStructureProperties new
		                             type: 'string';
		                             description: 'A filter target.';
		                             enum: self supportedFilterTargets;
		                             yourself.
	filterTargetsProperty := (self
		                          schemaPropertyNamed: 'filterTargets'
		                          type: 'array'
		                          description:
			                          'The package-entry fields matched by filter. Defaults to package.')
		                         items: filterTargetsItemProperty;
		                         yourself.
	packageEntryProperty := self
		                        schemaPropertyNamed: 'packages'
		                        type: 'array'
		                        description:
		                        'The package entries returned for the requested page.'.
	packageEntryProperty items: self packageEntrySchema.
	^ self
		  standardOutputSchemaForDataProperties: {
				  ((self
					    schemaPropertyNamed: 'scope'
					    type: 'string'
					    description: 'The scope used to search for packages.')
					   enum: #( 'image' 'project' );
					   yourself).
				  projectNamesProperty.
				  filterTargetsProperty.
				  (self
					   integerSchemaPropertyNamed: 'returnedCount'
					   description:
					   'The number of package entries returned in this page.').
				  (self
					   integerSchemaPropertyNamed: 'totalCount'
					   description:
					   'The total number of matching packages before pagination.').
				  (self
					   integerSchemaPropertyNamed: 'offset'
					   description:
					   'The zero-based pagination offset that was applied.').
				  (self
					   integerSchemaPropertyNamed: 'limit'
					   description:
					   'The maximum number of package entries requested.').
				  (self
					   schemaPropertyNamed: 'truncated'
					   type: 'boolean'
					   description:
					   'Whether additional matching packages exist beyond the returned page.').
				  packageEntryProperty }
		  required:
			  #( 'scope' 'projectNames' 'filterTargets' 'returnedCount'
			     'totalCount' 'offset' 'limit' 'truncated' 'packages' )
]

{ #category : 'defaults' }
MCPToolFindPackages >> defaultTitle [

	^ 'Find Pharo Packages'
]

{ #category : 'private - template' }
MCPToolFindPackages >> failureMessageForRequestedContext: requestedContext error: anError [

	^ self
		  failureMessageForScope: (requestedContext at: #scope)
		  error: anError
]

{ #category : 'private - results' }
MCPToolFindPackages >> failureMessageForScope: scope error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to query packages [scope=';
			  nextPutAll: scope;
			  nextPutAll: '] (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'private - filtering' }
MCPToolFindPackages >> filterTextsForPackageEntry: anEntry targets: filterTargets [

	| texts |
	texts := OrderedCollection new.
	filterTargets do: [ :each |
		each = 'package' ifTrue: [ texts add: (anEntry at: #packageName) ].
		each = 'project' ifTrue: [
			(anEntry at: #projectNames) do: [ :projectName |
				texts add: projectName ] ].
		each = 'tag' ifTrue: [
			(anEntry at: #tagNames) do: [ :tagName | texts add: tagName ] ] ].
	^ texts asArray
]

{ #category : 'private - filtering' }
MCPToolFindPackages >> matchesFilterOnPackageEntry: anEntry matcher: aMatcher targets: filterTargets [

	^ (self filterTextsForPackageEntry: anEntry targets: filterTargets)
		  anySatisfy: [ :each | aMatcher value: each ]
]

{ #category : 'private - filtering' }
MCPToolFindPackages >> packageEntriesFrom: packages packageProjectNames: packageProjectNames filter: filterPattern filterTargets: filterTargets filterMode: filterMode caseSensitive: caseSensitive [

	| entries matcher |
	matcher := self
		           matcherForPattern: filterPattern
		           mode: filterMode
		           caseSensitive: caseSensitive.
	entries := OrderedCollection new.
	packages do: [ :eachPackage |
		| entry projectNames |
		projectNames := packageProjectNames
			                at: eachPackage name asString
			                ifAbsent: [ #(  ) ].
		entry := (MCPPackageInfo
			          fromPackage: eachPackage
			          projectNames: projectNames) asDictionary.
		(filterPattern isNil or: [
			 self
				 matchesFilterOnPackageEntry: entry
				 matcher: matcher
				 targets: filterTargets ]) ifTrue: [ entries add: entry ] ].
	^ entries asArray
]

{ #category : 'private - schema' }
MCPToolFindPackages >> packageEntrySchema [

	^ MCPStructureProperties new
		  name: 'packageEntry';
		  type: 'object';
		  description: 'Structured metadata for one queried package.';
		  properties: self packageInfoDataProperties;
		  required:
			  #( 'packageName' 'projectNames' 'tagNames' 'definedClassCount'
			     'extensionMethodCount' 'isUndefined' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - schema' }
MCPToolFindPackages >> packageInfoDataProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'packageName'
			   type: 'string'
			   description: 'The package name.').
		  (self
			   stringArraySchemaNamed: 'projectNames'
			   description: 'The project names that include the package.'
			   itemDescription: 'A project name.').
		  (self
			   stringArraySchemaNamed: 'tagNames'
			   description: 'The package tag names defined in the package.'
			   itemDescription: 'A package tag name.').
		  (self
			   integerSchemaPropertyNamed: 'definedClassCount'
			   description: 'The number of classes defined in the package.').
		  (self
			   integerSchemaPropertyNamed: 'extensionMethodCount'
			   description:
			   'The number of extension methods owned by the package.').
		  (self
			   schemaPropertyNamed: 'isUndefined'
			   type: 'boolean'
			   description:
			   'Whether the package belongs to the undefined project bucket.') }
]

{ #category : 'private - template' }
MCPToolFindPackages >> queryEntriesForParameters: parameters [

	| scopeQuery |
	scopeQuery := parameters at: #scopeQuery.
	^ self
		  packageEntriesFrom: scopeQuery packages
		  packageProjectNames: scopeQuery packageProjectNamesMap
		  filter: (parameters at: #filterPattern)
		  filterTargets: (parameters at: #filterTargets)
		  filterMode: (parameters at: #filterMode)
		  caseSensitive: (parameters at: #caseSensitive)
]

{ #category : 'private - template' }
MCPToolFindPackages >> queryParametersFromArguments: arguments [

	| scopeQuery |
	scopeQuery := MCPPackageScopeQuery
		              scope:
		              (self stringArgumentNamed: 'scope' in: arguments)
		              projectNames:
		              (self
			               argumentNamed: 'projectNames'
			               in: arguments
			               ifAbsent: [ nil ]).
	^ {
		  (#filterPattern
		   -> (self stringArgumentNamed: 'filter' in: arguments)).
		  (#filterTargets -> (self normalizedFilterTargetsFrom: arguments)).
		  (#filterMode -> (self normalizedFilterModeFrom: arguments)).
		  (#caseSensitive -> (self
			    booleanArgumentNamed: 'caseSensitive'
			    in: arguments
			    default: false)).
		  (#limit -> (self
			    nonNegativeIntegerArgumentNamed: 'limit'
			    in: arguments
			    default: 100)).
		  (#offset -> (self
			    nonNegativeIntegerArgumentNamed: 'offset'
			    in: arguments
			    default: 0)).
		  (#scopeQuery -> scopeQuery) } asDictionary
]

{ #category : 'private - template' }
MCPToolFindPackages >> queryResultDataForParameters: parameters page: page [

	| scopeQuery |
	scopeQuery := parameters at: #scopeQuery.
	^ self
		  queryResultDataFrom: {
				  (#scope -> scopeQuery scope).
				  (#projectNames -> scopeQuery projectNames).
				  (#filterTargets -> (parameters at: #filterTargets)) }
				  asDictionary
		  page: page
		  entriesKey: #packages
]

{ #category : 'private - template' }
MCPToolFindPackages >> requestedContextFromArguments: arguments [

	| scope |
	scope := self
		         argumentNamed: 'scope'
		         in: arguments
		         ifAbsent: [ 'image' ].
	scope := scope
		         ifNil: [ 'image' ]
		         ifNotNil: [ scope asString asLowercase ].
	^ { (#scope -> scope) } asDictionary
]

{ #category : 'private - template' }
MCPToolFindPackages >> successSummaryForParameters: parameters page: page [

	| scopeQuery |
	scopeQuery := parameters at: #scopeQuery.
	^ self
		  successSummaryForScope: scopeQuery scope
		  returnedCount: (page at: #returnedCount)
		  totalCount: (page at: #totalCount)
		  truncated: (page at: #truncated)
]

{ #category : 'private - results' }
MCPToolFindPackages >> successSummaryForScope: scope returnedCount: returnedCount totalCount: totalCount truncated: truncated [

	^ String streamContents: [ :stream |
		  stream
			  print: returnedCount;
			  nextPutAll: ' packages found [scope=';
			  nextPutAll: scope;
			  nextPutAll: '] (';
			  print: totalCount;
			  nextPutAll: ' matched'.
		  truncated ifTrue: [ stream nextPutAll: ', more available' ].
		  stream nextPutAll: ').' ]
]

{ #category : 'private - arguments' }
MCPToolFindPackages >> supportedFilterTargets [

	^ #( 'package' 'project' 'tag' )
]
