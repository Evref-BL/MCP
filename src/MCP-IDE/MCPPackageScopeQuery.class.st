"
Where package_search looks: every package in the image, each with the projects that own it.
"
Class {
	#name : 'MCPPackageScopeQuery',
	#superclass : 'Object',
	#category : 'MCP-IDE-Queries',
	#package : 'MCP-IDE',
	#tag : 'Queries'
}

{ #category : 'querying' }
MCPPackageScopeQuery >> packageProjectNamesMap [

	| packageProjects |
	packageProjects := Dictionary new.
	self projectRegistrations do: [ :eachProject |
			| projectName |
			projectName := eachProject projectName asString.
			(self packagesForProjectRegistration: eachProject) do: [ :eachPackage |
				(packageProjects at: eachPackage name asString ifAbsentPut: [ OrderedCollection new ]) add: projectName ] ].
	packageProjects valuesDo: [ :eachProjectNames | eachProjectNames sort ].
	^ packageProjects
]

{ #category : 'querying' }
MCPPackageScopeQuery >> packages [

	^ self packageOrganizer packages asArray sort: [ :left :right | left name <= right name ]
]

{ #category : 'private - querying' }
MCPPackageScopeQuery >> packagesForProjectRegistration: aProjectRegistration [

	| packages |
	packages := OrderedCollection new.
	aProjectRegistration projectVersion packages do: [ :eachSpec |
		self packageOrganizer packageNamed: eachSpec name asSymbol ifPresent: [ :package | packages add: package ] ].
	^ packages asArray
]

{ #category : 'private - testing' }
MCPPackageScopeQuery >> projectRegistrationLoadedInImage: aProjectRegistration [

	^ [ aProjectRegistration loadedInImage ]
		  on: Error
		  do: [ false ]
]

{ #category : 'private - testing' }
MCPPackageScopeQuery >> projectRegistrationPackagesArePresent: aProjectRegistration [

	| hasPackages |
	hasPackages := false.
	[
		aProjectRegistration projectVersion packages do: [ :eachSpec |
				hasPackages := true.
				(self packageOrganizer hasPackage: eachSpec name asSymbol) ifFalse: [ ^ false ] ] ]
		on: Error
		do: [ ^ false ].
	^ hasPackages
]

{ #category : 'private - querying' }
MCPPackageScopeQuery >> projectRegistrations [

	^ MetacelloProjectRegistration registry registrations select: [ :each | self shouldUseProjectRegistration: each ]
]

{ #category : 'phrasing' }
MCPPackageScopeQuery >> scopePhrase [
	"Where the query looks, in words."

	^ 'the image'
]

{ #category : 'private - testing' }
MCPPackageScopeQuery >> shouldUseProjectRegistration: aProjectRegistration [

	^ (self projectRegistrationLoadedInImage: aProjectRegistration) or: [
		  self projectRegistrationPackagesArePresent: aProjectRegistration ]
]

{ #category : 'accessing' }
MCPPackageScopeQuery >> warnings [

	^ #(  )
]
