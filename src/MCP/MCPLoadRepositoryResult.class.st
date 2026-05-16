"
Result DTO for load-repository. It wraps the reusable baseline load result and includes repository coordinates only for remote loads.
"
Class {
	#name : 'MCPLoadRepositoryResult',
	#superclass : 'Object',
	#instVars : [
		'mode',
		'repositoryUrl',
		'hostUrl',
		'owner',
		'project',
		'commitish',
		'sourceDirectory',
		'loadResult'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPLoadRepositoryResult class >> baselineRequest: aRequest loadResult: aLoadResult [

	^ self new
		  initializeBaselineRequest: aRequest
		  loadResult: aLoadResult
]

{ #category : 'instance creation' }
MCPLoadRepositoryResult class >> remoteRequest: aRequest repositoryUrl: aRepositoryUrl loadResult: aLoadResult [

	^ self new
		  initializeRemoteRequest: aRequest
		  repositoryUrl: aRepositoryUrl
		  loadResult: aLoadResult
]

{ #category : 'converting' }
MCPLoadRepositoryResult >> asDictionary [

	| dictionary |
	dictionary := {
		              (#mode -> self mode).
		              (#load -> self loadResult asDictionary) } asDictionary.
	self isRemoteLoad ifTrue: [
		dictionary at: #repository put: self repositoryDictionary ].
	^ dictionary
]

{ #category : 'accessing' }
MCPLoadRepositoryResult >> baseline [

	^ self loadResult baseline
]

{ #category : 'accessing' }
MCPLoadRepositoryResult >> commitish [

	^ commitish
]

{ #category : 'accessing' }
MCPLoadRepositoryResult >> groups [

	^ self loadResult groups
]

{ #category : 'accessing' }
MCPLoadRepositoryResult >> hostUrl [

	^ hostUrl
]

{ #category : 'initialization' }
MCPLoadRepositoryResult >> initializeBaselineRequest: aRequest loadResult: aLoadResult [

	mode := 'baseline'.
	loadResult := aLoadResult.
	^ self
]

{ #category : 'initialization' }
MCPLoadRepositoryResult >> initializeRemoteRequest: aRequest repositoryUrl: aRepositoryUrl loadResult: aLoadResult [

	mode := 'remote'.
	repositoryUrl := aRepositoryUrl.
	hostUrl := aRequest hostUrl.
	owner := aRequest owner.
	project := aRequest project.
	commitish := aRequest commitish.
	sourceDirectory := aRequest sourceDirectory.
	loadResult := aLoadResult.
	^ self
]

{ #category : 'accessing' }
MCPLoadRepositoryResult >> isRemoteLoad [

	^ self mode = 'remote'
]

{ #category : 'accessing' }
MCPLoadRepositoryResult >> loadResult [

	^ loadResult
]

{ #category : 'accessing' }
MCPLoadRepositoryResult >> mode [

	^ mode
]

{ #category : 'accessing' }
MCPLoadRepositoryResult >> newPackageNames [

	^ self loadResult newPackageNames
]

{ #category : 'accessing' }
MCPLoadRepositoryResult >> onConflict [

	^ self loadResult onConflict
]

{ #category : 'accessing' }
MCPLoadRepositoryResult >> onWarning [

	^ self loadResult onWarning
]

{ #category : 'accessing' }
MCPLoadRepositoryResult >> owner [

	^ owner
]

{ #category : 'accessing' }
MCPLoadRepositoryResult >> project [

	^ project
]

{ #category : 'converting' }
MCPLoadRepositoryResult >> repositoryDictionary [

	^ {
		  (#hostUrl -> self hostUrl).
		  (#owner -> self owner).
		  (#project -> self project).
		  (#commitish -> self commitish).
		  (#sourceDirectory -> self sourceDirectory).
		  (#repositoryUrl -> self repositoryUrl) } asDictionary
]

{ #category : 'accessing' }
MCPLoadRepositoryResult >> repositoryInfos [

	^ self loadResult repositoryInfos
]

{ #category : 'accessing' }
MCPLoadRepositoryResult >> repositoryUrl [

	^ repositoryUrl
]

{ #category : 'accessing' }
MCPLoadRepositoryResult >> sourceDirectory [

	^ sourceDirectory
]
