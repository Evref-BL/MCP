"
Tests the package_search tool.
"
Class {
	#name : 'MCPToolSearchPackagesTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolSearchPackagesTest >> createFixtureClassNamed: aClassName packageName: aPackageName tag: aTag [

	^ self withoutEpiceaDuring: [
			  | builder |
			  builder := Object << aClassName asSymbol.
			  builder package: aPackageName.
			  builder tag: aTag.
			  builder install ]
]

{ #category : 'private' }
MCPToolSearchPackagesTest >> entryNamed: aPackageName in: packageEntries [

	^ packageEntries
		  detect: [ :each | (each at: #packageName) = aPackageName ]
		  ifNone: [ self fail: 'Missing package entry ' , aPackageName ]
]

{ #category : 'tests' }
MCPToolSearchPackagesTest >> testCanFilterPackageEntriesByTagNamesUsingControlledPackages [

	self withTemporaryTaggedPackagesDo: [ :packages :packageProjectNames |
			| data entry queryRequest |
			queryRequest := MCPSearchPackagesRequest new
				                fieldFilters: { (#tag -> 'FixtureBetaTag') } asDictionary;
				                filterMode: 'substring';
				                caseSensitive: false;
				                yourself.
			data := MCPToolSearchPackages new
				        packageEntriesFromPackages: packages
				        projectNames: packageProjectNames
				        usingRequest: queryRequest.
			self assert: data size equals: 1.
			entry := self entryNamed: 'MCP-Tests-SearchPackages-Temp-Beta' in: data.
			self assert: (entry at: #projectNames) equals: #( 'FixtureProject' ).
			self assert: (entry at: #tagNames) equals: #( 'FixtureBetaTag' ) ]
]

{ #category : 'tests' }
MCPToolSearchPackagesTest >> testImageScopeCanFilterPackagesByTagTarget [

	self withTemporaryTaggedPackagesDo: [ :packages :packageProjectNames |
			| data packageNames result |
			result := self callToolWith: {
					          (#tag -> 'FixtureBetaTag').
					          (#filterMode -> 'exact') } asDictionary.
			data := self dataFrom: result.
			packageNames := (data at: #packages) collect: [ :each | each at: #packageName ].
			self deny: (result at: #isError ifAbsent: [ false ]).
			self assert: (data at: #packages) size equals: 1.
			self assert: packageNames equals: #( 'MCP-Tests-SearchPackages-Temp-Beta' ) ]
]

{ #category : 'tests' }
MCPToolSearchPackagesTest >> testImageScopeCanPaginateFilteredPackages [

	| data expected packageNames result |
	result := self callToolWith: {
			          (#packageName -> 'MCP-').
			          (#filterMode -> 'prefix').
			          (#limit -> 2).
			          (#offset -> 1) } asDictionary.
	data := self dataFrom: result.
	packageNames := (data at: #packages) collect: [ :each | each at: #packageName ].
	expected := (PackageOrganizer default packages
		             select: [ :each | each name asString beginsWith: 'MCP-' ]
		             thenCollect: [ :each | each name asString ]) asArray sort.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: packageNames size equals: 2.
	self assert: (data at: #nextOffset) equals: 3.
	self assert: packageNames equals: (expected copyFrom: 2 to: 3) asArray
]

{ #category : 'tests' }
MCPToolSearchPackagesTest >> testImageScopeReturnsExactPackageNameMatch [

	| data packageNames result |
	result := self callToolWith: {
			          (#packageName -> 'MCP-Tests').
			          (#filterMode -> 'exact') } asDictionary.
	data := self dataFrom: result.
	packageNames := (data at: #packages) collect: [ :each | each at: #packageName ].

	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #packages) size equals: 1.
	self assert: packageNames equals: #( 'MCP-Tests' )
]

{ #category : 'tests' }
MCPToolSearchPackagesTest >> testImageScopeReturnsStructuredPackages [

	| data entry packages result |
	result := self callToolWith: {
			          (#packageName -> 'MCP-Tests-Resources').
			          (#filterMode -> 'exact') } asDictionary.
	data := self dataFrom: result.
	packages := data at: #packages.
	entry := self entryNamed: 'MCP-Tests-Resources' in: packages.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: packages size equals: 1.
	self assert: (entry includesKey: #projectNames).
	self assert: (entry includesKey: #tagNames).
	self deny: (entry includesKey: #definedClassCount).
	self deny: (entry includesKey: #extensionMethodCount).
	self deny: (entry includesKey: #isUndefined)
]

{ #category : 'tests' }
MCPToolSearchPackagesTest >> testPackageNamesSelectExactPackages [

	| data packageNames result |
	result := self callToolWith: { (#packageNames -> #( 'MCP' 'MCP-Tests' )) } asDictionary.
	data := self dataFrom: result.
	packageNames := (data at: #packages) collect: [ :each | each at: #packageName ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #packages) size equals: 2.
	self assert: packageNames equals: #( 'MCP' 'MCP-Tests' )
]

{ #category : 'tests' }
MCPToolSearchPackagesTest >> testProjectNamesReturnStructuredErrorWhenProjectIsMissing [

	| error result structured |
	result := self callToolWith: { (#projectNames -> #( 'DefinitelyMissingProject' )) } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ProjectNotFound'.
	self assert: (error at: #projectName) equals: 'DefinitelyMissingProject'.
	self assert: (error at: #scope) equals: 'projects'
]

{ #category : 'tests' }
MCPToolSearchPackagesTest >> testProjectNamesSearchPackagesForNamedProject [

	| entries packageNames |
	entries := self packageSearchFixtureEntriesLoadedInImage: true.
	packageNames := entries collect: [ :each | each at: #packageName ].
	self assert: entries size equals: self packageSearchFixturePackageNames size.
	self assert: packageNames equals: self packageSearchFixturePackageNames.
	self assert: (entries allSatisfy: [ :each | (each at: #projectNames) = { self packageSearchFixtureProjectName } ])
]

{ #category : 'tests' }
MCPToolSearchPackagesTest >> testProjectNamesSelectProjectScope [

	| entries packageNames |
	entries := self packageSearchFixtureEntriesLoadedInImage: false.
	packageNames := entries collect: [ :each | each at: #packageName ].
	self assert: entries size equals: self packageSearchFixturePackageNames size.
	self assert: packageNames equals: self packageSearchFixturePackageNames.
	self assert: (entries allSatisfy: [ :each | (each at: #projectNames) = { self packageSearchFixtureProjectName } ])
]

{ #category : 'tests' }
MCPToolSearchPackagesTest >> testProjectRegistrationWithPresentPackagesIsUsableWhenNotLoaded [

	| query registration |
	query := MCPPackageScopeQuery new.
	registration := self packageSearchFixtureRegistrationLoadedInImage: false.
	self assert: (query shouldUseProjectRegistration: registration)
]

{ #category : 'private - calling' }
MCPToolSearchPackagesTest >> toolName [

	^ 'package_search'
]

{ #category : 'private' }
MCPToolSearchPackagesTest >> withTemporaryTaggedPackagesDo: aBlock [

	| alphaClassName alphaPackage alphaPackageName betaClassName betaPackage betaPackageName packageProjectNames |
	alphaClassName := 'MCPToolSearchPackagesTempAlpha'.
	betaClassName := 'MCPToolSearchPackagesTempBeta'.
	alphaPackageName := 'MCP-Tests-SearchPackages-Temp-Alpha'.
	betaPackageName := 'MCP-Tests-SearchPackages-Temp-Beta'.
	self removeClassNamed: alphaClassName.
	self removeClassNamed: betaClassName.
	self removePackageNamed: alphaPackageName.
	self removePackageNamed: betaPackageName.
	[
		self createFixtureClassNamed: alphaClassName packageName: alphaPackageName tag: 'FixtureAlphaTag'.
		self createFixtureClassNamed: betaClassName packageName: betaPackageName tag: 'FixtureBetaTag'.
		alphaPackage := PackageOrganizer default packageNamed: alphaPackageName asSymbol.
		betaPackage := PackageOrganizer default packageNamed: betaPackageName asSymbol.
		packageProjectNames := Dictionary new
			                       at: alphaPackageName put: #( 'FixtureProject' );
			                       at: betaPackageName put: #( 'FixtureProject' );
			                       yourself.
		aBlock
			value: {
					alphaPackage.
					betaPackage } asArray
			value: packageProjectNames ] ensure: [
			self removeClassNamed: alphaClassName.
			self removeClassNamed: betaClassName.
			self removePackageNamed: alphaPackageName.
			self removePackageNamed: betaPackageName ]
]
