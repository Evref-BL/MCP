"
Test double for a repository head reference.
"
Class {
	#name : 'MCPTestRepositoryHead',
	#superclass : 'Object',
	#instVars : [
		'repository'
	],
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'instance creation' }
MCPTestRepositoryHead class >> repository: aRepository [

	^ self new
		  repository: aRepository;
		  yourself
]

{ #category : 'testing' }
MCPTestRepositoryHead >> hasUpstream [

	^ repository upstreamRemoteName notEmpty or: [
		  repository upstreamBranchName notEmpty ]
]

{ #category : 'testing' }
MCPTestRepositoryHead >> isDetached [

	^ repository isDetachedHead
]

{ #category : 'accessing' }
MCPTestRepositoryHead >> repository: aRepository [

	repository := aRepository
]

{ #category : 'accessing' }
MCPTestRepositoryHead >> upstream [

	^ MCPTestRepositoryUpstream
		  remoteName: repository upstreamRemoteName
		  branchName: repository upstreamBranchName
]
