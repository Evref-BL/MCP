"
Tests the package_search tool.
"
Class {
	#name : 'MCPToolSearchPackagesTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolSearchPackagesTest >> createFixtureClassNamed: aClassName packageName: aPackageName tag: aTag [

	^ self withoutEpiceaDuring: [
			  | builder |
			  self packageOrganizer ensurePackage: aPackageName.
			  builder := Object << aClassName asSymbol.
			  builder package: aPackageName.
			  builder tag: aTag.
			  builder install ]
]

{ #category : 'private' }
MCPToolSearchPackagesTest >> entryNamed: aPackageName in: packageEntries [

	^ packageEntries
		  detect: [ :each | (each at: #package) = aPackageName ]
		  ifNone: [ self fail: 'Missing package entry ' , aPackageName ]
]

{ #category : 'tests' }
MCPToolSearchPackagesTest >> testCanFilterPackageEntriesByTagNamesUsingControlledPackages [

	self withTemporaryTaggedPackagesDo: [ :packages :packageProjectNames |
			| data entry |
			data := MCPToolSearchPackages new
				        packageEntriesFromPackages: packages
				        projectNames: packageProjectNames
				        fieldFilters: { (#tag -> 'FixtureBetaTag') } asDictionary.
			self assert: data size equals: 1.
			entry := self entryNamed: 'MCP-Tests-SearchPackages-Temp-Beta' in: data.
			self assert: (entry at: #projects) equals: #( 'FixtureProject' ).
			self assert: (entry at: #tags) equals: #( 'FixtureBetaTag' ) ]
]

{ #category : 'tests' }
MCPToolSearchPackagesTest >> testImageScopeCanFilterPackagesByTagTarget [

	self withTemporaryTaggedPackagesDo: [ :packages :packageProjectNames |
			| data packageNames result |
			result := self callToolWith: {
					          (#tag -> 'FixtureBetaTag') } asDictionary.
			data := self dataFrom: result.
			packageNames := (data at: #packages) collect: [ :each | each at: #package ].
			self deny: (result at: #isError ifAbsent: [ false ]).
			self assert: (data at: #packages) size equals: 1.
			self assert: packageNames equals: #( 'MCP-Tests-SearchPackages-Temp-Beta' ) ]
]

{ #category : 'tests' }
MCPToolSearchPackagesTest >> testImageScopeCanPaginateFilteredPackages [

	| data expected packageNames pagination result summary |
	result := self callToolWith: {
			          (#query -> 'MCP-').
			          (#offset -> 1) } asDictionary.
	data := self dataFrom: result.
	pagination := data at: #pagination.
	summary := self summaryFrom: result.
	packageNames := (data at: #packages) collect: [ :each | each at: #package ].
	"The filter keeps a package whose name holds the text anywhere, so the expectation has to read it the same way: a package such as PharoImageFS-MCP-Tests is one of them."
	expected := (self packageOrganizer packages
		             select: [ :each | each name asString includesSubstring: 'MCP-' ]
		             thenCollect: [ :each | each name asString ]) asArray sort.
	self assert: packageNames size equals: expected size - 1.
	self deny: (data includesKey: #nextOffset).
	self assert: (pagination at: #returnedCount) equals: expected size - 1.
	self assert: (pagination at: #totalCount) equals: expected size.
	self deny: (pagination at: #truncated).
	self assert: summary equals: ('{1} of {2} packages match in the image.' format: {
				 (expected size - 1).
				 expected size }).
	self assert: packageNames equals: expected allButFirst asArray
]

{ #category : 'tests' }
MCPToolSearchPackagesTest >> testImageScopeReturnsStructuredPackages [

	| entry result |
	result := self callToolWith: { (#query -> 'MCP-Tests-Resources') } asDictionary.
	entry := self entryNamed: 'MCP-Tests-Resources' in: ((self dataFrom: result) at: #packages).
	self assert: (entry includesKey: #projects).
	self assert: (entry includesKey: #tags).
	self deny: (entry includesKey: #definedClassCount).
	self deny: (entry includesKey: #extensionMethodCount).
	self deny: (entry includesKey: #isUndefined)
]

{ #category : 'tests' }
MCPToolSearchPackagesTest >> testProjectFilterKeepsTheProjectsPackages [

	| entries |
	entries := self packageSearchFixtureEntries.
	self assert: (entries collect: [ :each | each at: #package ]) equals: self packageSearchFixturePackageNames.
	self assert: (entries allSatisfy: [ :each | (each at: #projects) = { self packageSearchFixtureProjectName } ])
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
		alphaPackage := self packageOrganizer packageNamed: alphaPackageName asSymbol.
		betaPackage := self packageOrganizer packageNamed: betaPackageName asSymbol.
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
