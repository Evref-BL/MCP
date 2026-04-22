Class {
	#name : 'MCPToolFindPackages',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - arguments' }
MCPToolFindPackages >> defaultScopeFromArguments: arguments [

	(self stringArgumentNamed: 'scope' in: arguments) ifNotNil: [ :scope |
		^ scope asLowercase ].
	^ 'image'
]

{ #category : 'private - results' }
MCPToolFindPackages >> errorResultForError: anError scope: scope [

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
MCPToolFindPackages >> executeWithArguments: arguments [

	| caseSensitive data endIndex entries filterPattern filterMode limit offset pagedEntries projectNames requestedScope scope startIndex totalCount truncated |
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
	requestedScope := self defaultScopeFromArguments: arguments.
	^ [
	  | packageProjectNames requestedProjectNames |
	  scope := self scopeFromArguments: arguments.
	  requestedProjectNames := self projectNamesFromArguments: arguments.
	  projectNames := scope = 'project'
		                  ifTrue: [ requestedProjectNames ]
		                  ifFalse: [ #(  ) ].
	  packageProjectNames := self packageProjectNamesMap.
	  entries := self
		             packageEntriesFrom:
		             (self
			              packagesForScope: scope
			              projectNames: projectNames)
		             packageProjectNames: packageProjectNames
		             filter: filterPattern
		             filterMode: filterMode
		             caseSensitive: caseSensitive.
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
		          (#scope -> scope).
		          (#projectNames -> projectNames).
		          (#returnedCount -> pagedEntries size).
		          (#totalCount -> totalCount).
		          (#offset -> offset).
		          (#limit -> limit).
		          (#truncated -> truncated).
		          (#packages -> pagedEntries) } asDictionary.
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
MCPToolFindPackages >> filterTextForPackageEntry: anEntry [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: (anEntry at: #packageName);
			  space;
			  nextPutAll: (anEntry at: #definedClassCount) asString;
			  space;
			  nextPutAll: (anEntry at: #extensionMethodCount) asString;
			  space;
			  nextPutAll: (anEntry at: #isUndefined) asString.
		  (anEntry at: #projectNames) do: [ :each |
			  stream
				  space;
				  nextPutAll: each ].
		  (anEntry at: #tagNames) do: [ :each |
			  stream
				  space;
				  nextPutAll: each ] ]
]

{ #category : 'initialization' }
MCPToolFindPackages >> initialize [

	| filterModeProperty packageEntryProperty projectNamesProperty scopeProperty |
	super initialize.
	name := 'find-packages'.
	title := 'Find Pharo Packages'.
	description := 'List packages in the image or in a project and optionally filter them by package metadata.'.
	scopeProperty := MCPStructureProperties new
		                 name: 'scope';
		                 type: 'string';
		                 description:
			                 'Where to search for packages. Defaults to image.';
		                 enum: #( 'image' 'project' );
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
		                      yourself.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: {
				               scopeProperty.
				               projectNamesProperty.
				               (MCPStructureProperties new
					                name: 'filter';
					                type: 'string';
					                description:
						                'Optional filter applied to package metadata such as names, projects, tags, and package metrics.';
					                yourself).
				               filterModeProperty.
				               (MCPStructureProperties new
					                name: 'caseSensitive';
					                type: 'boolean';
					                description:
						                'Whether filter matching is case-sensitive. Defaults to false.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'limit';
					                type: 'integer';
					                description:
						                'Maximum number of matching packages to return. Defaults to 100. Use 0 to request counts only.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'offset';
					                type: 'integer';
					                description:
						                'Zero-based pagination offset applied after filtering. Defaults to 0.';
					                yourself) };
		               required: #(  );
		               yourself.
	packageEntryProperty := self
		                        schemaPropertyNamed: 'packages'
		                        type: 'array'
		                        description:
		                        'The package entries returned for the requested page.'.
	packageEntryProperty items: self packageEntrySchema.
	outputSchema := self
		                standardOutputSchemaForDataProperties: {
				                ((self
					                  schemaPropertyNamed: 'scope'
					                  type: 'string'
					                  description:
						                  'The scope used to search for packages.')
					                 enum: #( 'image' 'project' );
					                 yourself).
				                projectNamesProperty.
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
			                #( 'scope' 'projectNames' 'returnedCount'
			                   'totalCount' 'offset' 'limit' 'truncated'
			                   'packages' ).
	icons := { (self
		          pngCompositeBaseIconNamed: #package
		          badgeIconNamed: #zoomIn) }
]

{ #category : 'private - filtering' }
MCPToolFindPackages >> matchesFilterOnPackageEntry: anEntry filterMode: filterMode matcher: aMatcher [

	filterMode = 'exact' ifFalse: [
		^ aMatcher value: (self filterTextForPackageEntry: anEntry) ].

	^ (self packageFilterValuesForExactMatch: anEntry) anySatisfy: [
		  :each | aMatcher value: each ]
]

{ #category : 'private - filtering' }
MCPToolFindPackages >> packageEntriesFrom: packages packageProjectNames: packageProjectNames filter: filterPattern filterMode: filterMode caseSensitive: caseSensitive [

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
		(self
			 matchesFilterOnPackageEntry: entry
			 filterMode: filterMode
			 matcher: matcher) ifTrue: [ entries add: entry ] ].
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

{ #category : 'private - filtering' }
MCPToolFindPackages >> packageFilterValuesForExactMatch: anEntry [

	| values |
	values := OrderedCollection new.
	values
		add: (anEntry at: #packageName);
		add: (anEntry at: #definedClassCount) asString;
		add: (anEntry at: #extensionMethodCount) asString;
		add: (anEntry at: #isUndefined) asString.
	(anEntry at: #projectNames) do: [ :each | values add: each ].
	(anEntry at: #tagNames) do: [ :each | values add: each ].
	^ values asArray
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

{ #category : 'private - querying' }
MCPToolFindPackages >> packageProjectNamesMap [

	| packageProjects |
	packageProjects := Dictionary new.
	self projectManager projects do: [ :eachProject |
		| projectName |
		projectName := eachProject name asString.
		eachProject packages do: [ :eachPackage |
			(packageProjects
				 at: eachPackage name asString
				 ifAbsentPut: [ OrderedCollection new ]) add: projectName ] ].
	packageProjects valuesDo: [ :eachProjectNames |
		eachProjectNames sort ].
	^ packageProjects
]

{ #category : 'private - querying' }
MCPToolFindPackages >> packagesForProjectNames: projectNames [

	| packages |
	packages := IdentitySet new.
	(self resolvedProjectsNamed: projectNames) do: [ :eachProject |
		eachProject packages do: [ :eachPackage | packages add: eachPackage ] ].
	^ self sortedPackagesByName: packages
]

{ #category : 'private - querying' }
MCPToolFindPackages >> packagesForScope: scope projectNames: projectNames [

	scope = 'image' ifTrue: [
		^ self sortedPackagesByName: PackageOrganizer default packages ].
	scope = 'project' ifTrue: [
		projectNames ifEmpty: [
			Error signal: 'projectNames is required when scope=project.' ].
		^ self packagesForProjectNames: projectNames ].
	Error signal: 'Unsupported scope: ' , scope
]

{ #category : 'private - querying' }
MCPToolFindPackages >> projectManager [

	^ ProjectManager new
]

{ #category : 'private - arguments' }
MCPToolFindPackages >> projectNamesFromArguments: arguments [

	^ self stringCollectionArgumentNamed: 'projectNames' in: arguments
]

{ #category : 'private - querying' }
MCPToolFindPackages >> projectsByName [

	| projectsByName |
	projectsByName := Dictionary new.
	self projectManager projects do: [ :eachProject |
		projectsByName at: eachProject name asString put: eachProject ].
	^ projectsByName
]

{ #category : 'private - querying' }
MCPToolFindPackages >> resolvedProjectsNamed: projectNames [

	| projectsByName projects |
	projectsByName := self projectsByName.
	projects := OrderedCollection new.
	projectNames do: [ :eachName |
		projects add: (projectsByName
				 at: eachName
				 ifAbsent: [ MCPCommandError signalMissingProjectNamed: eachName ]) ].
	^ projects asArray
]

{ #category : 'private - arguments' }
MCPToolFindPackages >> scopeFromArguments: arguments [

	| scope |
	scope := self defaultScopeFromArguments: arguments.
	(#( 'image' 'project' ) includes: scope) ifFalse: [
		Error signal: 'scope must be one of image or project.' ].
	^ scope
]

{ #category : 'private - querying' }
MCPToolFindPackages >> sortedPackagesByName: somePackages [

	^ (somePackages asSortedCollection: [ :left :right |
		   left name <= right name ]) asArray
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
