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

	^ 'List packages and optionally filter them by package metadata. Omit projectNames and packageNames to search all packages. Use projectNames to include packages from projects and packageNames to include exact packages. Multiple scope properties are unioned. Use where for recursive boolean predicates and relation predicates.'
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

	| properties |
	properties := self packageQueryScopeInputProperties , (self
		               fieldFilteringInputPropertiesWithFilterDescription:
		               'Optional filter applied to the listed package-entry fields. Use filterTargets to choose which fields are matched.'
		               filterTargetsDescription:
		               'Optional package-entry fields matched by filter.'
		               filterModeDescription:
		               'How the package filter is matched.'
		               limitDescription:
		               'Maximum number of matching packages to return. Use 0 to request counts only.').
	^ self queryInputSchemaWithProperties: properties
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

{ #category : 'private - results' }
MCPToolFindPackages >> failureMessageForScope: scopeSummary error: anError [

	^ self
		  scopeQueryFailureMessageFor: 'packages'
		  scope: scopeSummary
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
MCPToolFindPackages >> packageEntriesForRequest: queryRequest [

	^ self
		  packageEntriesFromPackages: queryRequest scopeQuery packages
		  projectNames: queryRequest scopeQuery packageProjectNamesMap
		  usingRequest: queryRequest
]

{ #category : 'private - filtering' }
MCPToolFindPackages >> packageEntriesFromPackages: packages projectNames: packageProjectNames usingRequest: queryRequest [

	| entries matcher whereContext |
	matcher := self
		           matcherForPattern: queryRequest filterPattern
		           mode: queryRequest filterMode
		           caseSensitive: queryRequest caseSensitive.
	whereContext := self newWhereContext
		                at: #packageProjectNames put: packageProjectNames;
		                yourself.
	entries := OrderedCollection new.
	packages do: [ :eachPackage |
		| entry evaluation matchesFilter projectNames |
		projectNames := packageProjectNames
			                at: eachPackage name asString
			                ifAbsent: [ #(  ) ].
		entry := (MCPPackageInfo
			          fromPackage: eachPackage
			          projectNames: projectNames) asQueryDictionary.
		matchesFilter := queryRequest hasFilterPattern not or: [
			                 self
				                 matchesFilterOnPackageEntry: entry
				                 matcher: matcher
				                 targets: queryRequest filterTargets ].
		evaluation := self
			              whereEvaluationForEntityKind: #package
			              entry: entry
			              object: eachPackage
			              context: whereContext.
		(matchesFilter and: [
			 queryRequest whereSpec matchesEvaluation: evaluation ]) ifTrue: [
			entries add: entry ] ].
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
MCPToolFindPackages >> queryEntriesForQueryRequest: queryRequest [

	^ self packageEntriesForRequest: queryRequest
]

{ #category : 'private - template' }
MCPToolFindPackages >> queryRequestFromToolRequest: request [

	^ MCPFindPackagesRequest fromRequest: request tool: self
]

{ #category : 'private - template' }
MCPToolFindPackages >> queryResultDataForQueryRequest: queryRequest page: page [

	^ self queryResultDataFrom: nil page: page entriesKey: #packages
]

{ #category : 'private - template' }
MCPToolFindPackages >> requestedContextFromRequest: request [

	^ { (#scope -> (self
		    packageScopeSummaryForProjectNames:
		    (request stringCollectionArgumentNamed: 'projectNames')
		    packageNames:
		    (request stringCollectionArgumentNamed: 'packageNames'))) }
		  asDictionary
]

{ #category : 'private - template' }
MCPToolFindPackages >> successSummaryForQueryRequest: queryRequest page: page [

	^ self
		  successSummaryForScope: (self
				   packageScopeSummaryForProjectNames:
				   queryRequest scopeQuery projectNames
				   packageNames: queryRequest scopeQuery packageNames)
		  page: page
]

{ #category : 'private - results' }
MCPToolFindPackages >> successSummaryForScope: scopeSummary page: page [

	^ self
		  scopeQuerySuccessSummaryFor: 'packages'
		  scope: scopeSummary
		  page: page
]

{ #category : 'private - request' }
MCPToolFindPackages >> supportedFilterTargets [

	^ #( 'package' 'project' 'tag' )
]
