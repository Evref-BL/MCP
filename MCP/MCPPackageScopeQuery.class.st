"
Parsed scope query for package listings.

It resolves projectNames and packageNames into a union of packages. Empty scope properties mean all packages in the image.
"
Class {
	#name : 'MCPPackageScopeQuery',
	#superclass : 'Object',
	#instVars : [
		'projectNames',
		'packageNames'
	],
	#category : 'MCP-Queries',
	#package : 'MCP',
	#tag : 'Queries'
}

{ #category : 'private - scope' }
MCPPackageScopeQuery >> allPackages [

	^ self sortedPackagesByName: PackageOrganizer default packages
]

{ #category : 'initialization' }
MCPPackageScopeQuery >> initialize [

	super initialize.
	projectNames := #(  ).
	packageNames := #(  )
]

{ #category : 'accessing' }
MCPPackageScopeQuery >> packageNames [

	^ packageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPPackageScopeQuery >> packageNames: somePackageNames [

	packageNames := somePackageNames
		                ifNil: [ #(  ) ]
		                ifNotNil: [ somePackageNames asArray ]
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

	| packages |
	self validate.
	self usesImplicitImageScope ifTrue: [ ^ self allPackages ].
	packages := IdentitySet new.
	self packageNames ifNotEmpty: [
		packages addAll: self packagesForPackageNames ].
	self projectNames ifNotEmpty: [
		packages addAll: self packagesForProjectNames ].
	^ self sortedPackagesByName: packages
]

{ #category : 'private - scope' }
MCPPackageScopeQuery >> packagesForPackageNames [

	| packages |
	packages := IdentitySet new.
	self packageNames do: [ :eachName |
		packages add: (self resolvedPackageNamed: eachName) ].
	^ self sortedPackagesByName: packages
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
MCPPackageScopeQuery >> resolvedPackageNamed: packageName [

	^ PackageOrganizer default
		  packageNamed: packageName asSymbol
		  ifAbsent: [
		  MCPCommandError signalMissingPackageNamed: packageName ]
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

{ #category : 'private - source' }
MCPPackageScopeQuery >> usesImplicitImageScope [

	^ self projectNames isEmpty and: [ self packageNames isEmpty ]
]

{ #category : 'validating' }
MCPPackageScopeQuery >> validate [

	^ self
]
