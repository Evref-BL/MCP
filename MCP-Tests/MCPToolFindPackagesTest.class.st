Class {
	#name : 'MCPToolFindPackagesTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolFindPackagesTest >> createFixtureClassNamed: aClassName packageName: aPackageName tag: aTag [

	^ self withoutEpiceaDuring: [
		  | builder |
		  builder := Object << aClassName asSymbol.
		  builder package: aPackageName.
		  builder tag: aTag.
		  builder install ]
]

{ #category : 'private' }
MCPToolFindPackagesTest >> entryNamed: aPackageName in: packageEntries [

	^ packageEntries
		  detect: [ :each | (each at: #packageName) = aPackageName ]
		  ifNone: [ self fail: 'Missing package entry ' , aPackageName ]
]

{ #category : 'private' }
MCPToolFindPackagesTest >> mcpProject [

	^ ProjectManager new projects
		  detect: [ :each | each name asString = 'MCP' ]
		  ifNone: [ self fail: 'Missing MCP project fixture in image.' ]
]

{ #category : 'private' }
MCPToolFindPackagesTest >> mcpProjectPackageNames [

	^ (self mcpProject packages collect: [ :each | each name asString ])
		  asArray asSortedCollection asArray
]

{ #category : 'tests' }
MCPToolFindPackagesTest >> testCanFilterPackageEntriesByTagNamesUsingControlledPackages [

	self withTemporaryTaggedPackagesDo: [ :packages :packageProjectNames |
		| data entry |
		data := MCPToolFindPackages new
			        packageEntriesFrom: packages
			        packageProjectNames: packageProjectNames
			        filter: 'FixtureBetaTag'
			        filterTargets: #( 'tag' )
			        filterMode: 'substring'
			        caseSensitive: false.
		self assert: data size equals: 1.
		entry := self
			         entryNamed: 'MCP-Tests-FindPackages-Temp-Beta'
			         in: data.
		self assert: (entry at: #projectNames) equals: #( 'FixtureProject' ).
		self assert: (entry at: #tagNames) equals: #( 'FixtureBetaTag' ) ]
]

{ #category : 'tests' }
MCPToolFindPackagesTest >> testImageScopeCanFilterPackagesByTagTarget [

	self withTemporaryTaggedPackagesDo: [ :packages :packageProjectNames |
		| data packageNames result |
		result := self callToolWith: {
				          (#filter -> 'FixtureBetaTag').
				          (#filterTargets -> #( 'tag' )).
				          (#filterMode -> 'exact') } asDictionary.
		data := self dataFrom: result.
		packageNames := (data at: #packages) collect: [ :each |
			                each at: #packageName ].
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (data at: #filterTargets) equals: #( 'tag' ).
		self assert: (data at: #totalCount) equals: 1.
		self
			assert: packageNames
			equals: #( 'MCP-Tests-FindPackages-Temp-Beta' ) ]
]

{ #category : 'tests' }
MCPToolFindPackagesTest >> testImageScopeCanPaginateFilteredPackages [

	| data packageNames result expected |
	result := self callToolWith: {
			          (#filter -> 'MCP-').
			          (#filterMode -> 'prefix').
			          (#limit -> 2).
			          (#offset -> 1) } asDictionary.
	data := self dataFrom: result.
	packageNames := (data at: #packages) collect: [ :each |
		                each at: #packageName ].
	expected := ((PackageOrganizer default packages select: [ :each |
		              each name asString beginsWith: 'MCP-' ])
		             collect: [ :each | each name asString ]
		             as: Array) asSortedCollection asArray.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #scope) equals: 'image'.
	self assert: (data at: #totalCount) equals: expected size.
	self
		assert: packageNames
		equals: (expected copyFrom: 2 to: 3) asArray
]

{ #category : 'tests' }
MCPToolFindPackagesTest >> testImageScopeFindsExactPackageNameMatch [

	| data packageNames result |
	result := self callToolWith: {
			          (#filter -> 'MCP-Tests').
			          (#filterMode -> 'exact') } asDictionary.
	data := self dataFrom: result.
	packageNames := (data at: #packages) collect: [ :each |
		                each at: #packageName ].

	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #scope) equals: 'image'.
	self assert: (data at: #filterTargets) equals: #( 'package' ).
	self assert: (data at: #totalCount) equals: 1.
	self assert: packageNames equals: #( 'MCP-Tests' )
]

{ #category : 'tests' }
MCPToolFindPackagesTest >> testImageScopeFindsStructuredPackages [

	| data entry result |
	result := self callToolWith: {
			          (#filter -> 'MCP').
			          (#filterTargets -> #( 'project' )).
			          (#filterMode -> 'exact') } asDictionary.
	data := self dataFrom: result.
	entry := self entryNamed: 'MCP' in: (data at: #packages).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #scope) equals: 'image'.
	self assert: (data at: #filterTargets) equals: #( 'project' ).
	self assert: (data at: #totalCount) > 0.
	self assert: (entry at: #projectNames) equals: #( 'MCP' ).
	self assert: (entry at: #definedClassCount) > 0.
	self assert: ((entry at: #tagNames) includes: 'Tools')
]

{ #category : 'tests' }
MCPToolFindPackagesTest >> testProjectScopeFindsPackagesForNamedProject [

	| data packageNames result |
	result := self callToolWith: {
			          (#scope -> 'project').
			          (#projectNames -> #( 'MCP' )) } asDictionary.
	data := self dataFrom: result.
	packageNames := (data at: #packages) collect: [ :each |
		                each at: #packageName ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #scope) equals: 'project'.
	self assert: (data at: #projectNames) equals: #( 'MCP' ).
	self assert: packageNames equals: self mcpProjectPackageNames
]

{ #category : 'tests' }
MCPToolFindPackagesTest >> testProjectScopeReturnsStructuredErrorWhenProjectIsMissing [

	| error result structured |
	result := self callToolWith: {
			          (#scope -> 'project').
			          (#projectNames -> #( 'DefinitelyMissingProject' )) }
			          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'. self assert: (error at: #errorCode) equals: 'ProjectNotFound'.
	self
		assert: (error at: #projectName)
		equals: 'DefinitelyMissingProject'.
	self assert: (error at: #scope) equals: 'project'
]

{ #category : 'tests' }
MCPToolFindPackagesTest >> testReturnsStructuredErrorForInvalidFilterTarget [

	| error result structured |
	result := self callToolWith: {
			          (#scope -> 'image').
			          (#filter -> 'needle').
			          (#filterTargets -> #( 'definedClassCount' )) }
			          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #scope) equals: 'image'.
	self assert: (error at: #errorClass) equals: 'Error'.
	self assert:
		((error at: #message) includesSubstring: 'filterTargets').
	self assert:
		((error at: #message) includesSubstring: 'definedClassCount')
]

{ #category : 'private - calling' }
MCPToolFindPackagesTest >> toolName [

	^ 'find-packages'
]

{ #category : 'private' }
MCPToolFindPackagesTest >> withTemporaryTaggedPackagesDo: aBlock [

	| alphaClassName alphaPackage alphaPackageName betaClassName betaPackage betaPackageName packageProjectNames |
	alphaClassName := 'MCPToolFindPackagesTempAlpha'.
	betaClassName := 'MCPToolFindPackagesTempBeta'.
	alphaPackageName := 'MCP-Tests-FindPackages-Temp-Alpha'.
	betaPackageName := 'MCP-Tests-FindPackages-Temp-Beta'.
	self removeClassNamed: alphaClassName.
	self removeClassNamed: betaClassName.
	self removePackageNamed: alphaPackageName.
	self removePackageNamed: betaPackageName.
	[
	self
		createFixtureClassNamed: alphaClassName
		packageName: alphaPackageName
		tag: 'FixtureAlphaTag'.
	self
		createFixtureClassNamed: betaClassName
		packageName: betaPackageName
		tag: 'FixtureBetaTag'.
	alphaPackage := PackageOrganizer default packageNamed:
		                alphaPackageName asSymbol.
	betaPackage := PackageOrganizer default packageNamed:
		               betaPackageName asSymbol.
	packageProjectNames := Dictionary new
		                       at: alphaPackageName
		                       put: #( 'FixtureProject' );
		                       at: betaPackageName
		                       put: #( 'FixtureProject' );
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
