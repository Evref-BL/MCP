"
Result DTO for repository_load. It wraps the reusable baseline load result and reports the resolved repository URL plus source fields relevant to the selected source mode.
"
Class {
	#name : 'MCPLoadRepositoryResult',
	#superclass : 'MCPResult',
	#instVars : [
		'mode',
		'repositoryUrl',
		'hostUrl',
		'owner',
		'project',
		'commitish',
		'sourceDirectory',
		'checkoutPath',
		'repositoryName',
		'location',
		'loadResult'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPLoadRepositoryResult class >> request: aRequest repositoryUrl: aRepositoryUrl loadResult: aLoadResult [

	^ self new
		  initializeRequest: aRequest
		  repositoryUrl: aRepositoryUrl
		  loadResult: aLoadResult
]

{ #category : 'converting' }
MCPLoadRepositoryResult >> asDictionary [

	^ {
		  (#mode -> self mode).
		  (#repository -> self repositoryDictionary).
		  (#load -> self loadResult asDictionary) } asDictionary
]

{ #category : 'accessing' }
MCPLoadRepositoryResult >> baseline [

	^ self loadResult baseline
]

{ #category : 'accessing' }
MCPLoadRepositoryResult >> checkoutPath [

	^ checkoutPath
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
MCPLoadRepositoryResult >> initializeRequest: aRequest repositoryUrl: aRepositoryUrl loadResult: aLoadResult [

	mode := aRequest mode.
	repositoryUrl := aRepositoryUrl.
	hostUrl := aRequest hostUrl.
	owner := aRequest owner.
	project := aRequest project.
	commitish := aRequest commitish.
	sourceDirectory := aRequest sourceDirectory.
	checkoutPath := aRequest checkoutPath.
	repositoryName := aRequest repositoryName.
	location := aRequest location.
	loadResult := aLoadResult.
	^ self
]

{ #category : 'accessing' }
MCPLoadRepositoryResult >> loadResult [

	^ loadResult
]

{ #category : 'accessing' }
MCPLoadRepositoryResult >> location [

	^ location
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

	^ { (#repositoryUrl -> self repositoryUrl) } asDictionary
]

{ #category : 'accessing' }
MCPLoadRepositoryResult >> repositoryInfos [

	^ self loadResult repositoryInfos
]

{ #category : 'accessing' }
MCPLoadRepositoryResult >> repositoryName [

	^ repositoryName
]

{ #category : 'accessing' }
MCPLoadRepositoryResult >> repositoryUrl [

	^ repositoryUrl
]

{ #category : 'accessing' }
MCPLoadRepositoryResult >> sourceDirectory [

	^ sourceDirectory
]
