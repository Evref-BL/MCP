Class {
	#name : 'MCPPackageScopeQuery',
	#superclass : 'MCPScopeQuery',
	#instVars : [
		'projectNames'
	],
	#category : 'MCP-Internal',
	#package : 'MCP',
	#tag : 'Internal'
}

{ #category : 'instance creation' }
MCPPackageScopeQuery class >> scope: aScope projectNames: someProjectNames [

	^ self new
		  scope: aScope;
		  projectNames: someProjectNames;
		  yourself
]

{ #category : 'private - scope' }
MCPPackageScopeQuery >> allPackages [

	^ self sortedPackagesByName: PackageOrganizer default packages
]

{ #category : 'initialization' }
MCPPackageScopeQuery >> initialize [

	super initialize.
	projectNames := #(  )
]

{ #category : 'private - querying' }
MCPPackageScopeQuery >> packageProjectNamesMap [

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

{ #category : 'querying' }
MCPPackageScopeQuery >> packages [

	self validate.
	scope = 'image' ifTrue: [ ^ self allPackages ].
	scope = 'project' ifTrue: [ ^ self packagesForProjectNames ].
	Error signal: 'Unsupported scope: ' , scope
]

{ #category : 'private - scope' }
MCPPackageScopeQuery >> packagesForProjectNames [

	| packages |
	packages := IdentitySet new.
	(self resolvedProjectsNamed: projectNames) do: [ :eachProject |
		eachProject packages do: [ :eachPackage | packages add: eachPackage ] ].
	^ self sortedPackagesByName: packages
]

{ #category : 'private - querying' }
MCPPackageScopeQuery >> projectManager [

	^ ProjectManager new
]

{ #category : 'accessing' }
MCPPackageScopeQuery >> projectNames [

	^ projectNames
]

{ #category : 'accessing' }
MCPPackageScopeQuery >> projectNames: someProjectNames [

	projectNames := someProjectNames
		                ifNil: [ #(  ) ]
		                ifNotNil: [ someProjectNames asArray ]
]

{ #category : 'private - querying' }
MCPPackageScopeQuery >> projectsByName [

	| projectsByName |
	projectsByName := Dictionary new.
	self projectManager projects do: [ :eachProject |
		projectsByName at: eachProject name asString put: eachProject ].
	^ projectsByName
]

{ #category : 'private - resolution' }
MCPPackageScopeQuery >> resolvedProjectsNamed: someProjectNames [

	| projects projectsByName |
	projectsByName := self projectsByName.
	projects := OrderedCollection new.
	someProjectNames do: [ :eachName |
		projects add: (projectsByName
				 at: eachName
				 ifAbsent: [ MCPCommandError signalMissingProjectNamed: eachName ]) ].
	^ projects asArray
]

{ #category : 'private - scope' }
MCPPackageScopeQuery >> sortedPackagesByName: somePackages [

	^ (somePackages asSortedCollection: [ :left :right |
		   left name <= right name ]) asArray
]

{ #category : 'validating' }
MCPPackageScopeQuery >> validate [

	self validateScopeIsOneOf: #( 'image' 'project' ).
	scope = 'project' ifTrue: [
		projectNames ifEmpty: [
			Error signal: 'projectNames is required when scope=project.' ] ]
]
