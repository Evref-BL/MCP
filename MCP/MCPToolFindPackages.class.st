"
Lists packages in the image or a project with optional filtering. It is the general package discovery tool.
"
Class {
	#name : 'MCPToolFindPackages',
	#superclass : 'MCPToolQuery',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolFindPackages >> defaultDescription [

	^ 'List packages in the image or in a project and optionally filter them by package metadata.'
]

{ #category : 'private - request' }
MCPToolFindPackages >> defaultFilterTargets [

	^ #( 'package' )
]

{ #category : 'defaults' }
MCPToolFindPackages >> defaultIcons [

	^ { (self pngCompositeBaseIconNamed: #open badgeIconNamed: #search) }
]

{ #category : 'defaults' }
MCPToolFindPackages >> defaultInputSchema [

	| filterModeProperty filterTargetsProperty projectNamesProperty scopeProperty |
	scopeProperty := self
		                 stringEnumSchemaPropertyNamed: 'scope'
		                 description:
		                 'Where to search for packages. Defaults to image.'
		                 values: #( 'image' 'project' )
		                 default: 'image'.
	projectNamesProperty := self
		                        stringArraySchemaNamed: 'projectNames'
		                        description:
		                        'The project names that define the project scope. Required when scope=project.'
		                        itemDescription: 'A project name.'.
	filterModeProperty := self
		                      stringEnumSchemaPropertyNamed: 'filterMode'
		                      description:
		                      'How the package filter is matched. Defaults to substring.'
		                      values:
		                      #( 'substring' 'prefix' 'exact' 'regex' )
		                      default: 'substring'.
	filterTargetsProperty := self
		                         stringEnumArraySchemaNamed: 'filterTargets'
		                         description:
		                         'Optional package-entry fields matched by filter. Defaults to package.'
		                         itemDescription: 'A filter target.'
		                         values: self supportedFilterTargets
		                         default: self defaultFilterTargets.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  scopeProperty.
				  projectNamesProperty.
				  (self
					   schemaPropertyNamed: 'filter'
					   type: 'string'
					   description:
						   'Optional filter applied to the listed package-entry fields. Use filterTargets to choose which fields are matched.').
				  filterTargetsProperty.
				  filterModeProperty.
				  (self
					   booleanSchemaPropertyNamed: 'caseSensitive'
					   description:
						   'Whether filter matching is case-sensitive. Defaults to false.'
					   default: false).
				  (self
					   integerSchemaPropertyNamed: 'limit'
					   description:
						   'Maximum number of matching packages to return. Defaults to 100. Use 0 to request counts only.'
					   default: 100).
				  (self
					   integerSchemaPropertyNamed: 'offset'
					   description:
						   'Zero-based pagination offset applied after filtering. Defaults to 0.'
					   default: 0) };
		  required: #(  );
		  oneOf: self scopeBranchSchemasForPackageQueries;
		  yourself
]

{ #category : 'defaults' }
MCPToolFindPackages >> defaultName [

	^ 'find-packages'
]

{ #category : 'defaults' }
MCPToolFindPackages >> defaultOutputSchema [

	^ self
		  minimalPagedQueryOutputSchemaForEntriesPropertyNamed: 'packages'
		  entriesDescription:
		  'The package entries returned for the requested page.'
		  entrySchema: self packageEntrySchema
		  itemNounPhrase: 'package entries'
]

{ #category : 'defaults' }
MCPToolFindPackages >> defaultTitle [

	^ 'Find Packages'
]

{ #category : 'private - template' }
MCPToolFindPackages >> failureMessageForRequestedContext: requestedContext error: anError [

	^ self
		  failureMessageForScope: (requestedContext at: #scope)
		  error: anError
]

{ #category : 'private - results' }
MCPToolFindPackages >> failureMessageForScope: scope error: anError [

	^ self
		  scopeQueryFailureMessageFor: 'packages'
		  scope: scope
		  error: anError
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
			          projectNames: projectNames) asQueryDictionary.
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
		  required: #( 'packageName' 'projectNames' 'tagNames' );
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
			   itemDescription: 'A package tag name.') }
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
MCPToolFindPackages >> queryResultDataForParameters: parameters page: page [

	^ self queryResultDataFrom: nil page: page entriesKey: #packages
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

	^ self
		  scopeQuerySuccessSummaryFor: 'packages'
		  scope: scope
		  returnedCount: returnedCount
		  totalCount: totalCount
		  truncated: truncated
]

{ #category : 'private - request' }
MCPToolFindPackages >> supportedFilterTargets [

	^ #( 'package' 'project' 'tag' )
]
