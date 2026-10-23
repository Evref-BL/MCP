"
Test double for a repository head reference.
"
Class {
	#name : 'MCPTestRepositoryHead',
	#superclass : 'Object',
	#instVars : [
		'repository'
	],
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'instance creation' }
MCPTestRepositoryHead class >> repository: aRepository [

	^ self new
		  repository: aRepository;
		  yourself
]

{ #category : 'testing' }
MCPTestRepositoryHead >> isDetached [

	^ repository isDetachedHead
]

{ #category : 'accessing' }
MCPTestRepositoryHead >> repository: aRepository [

	repository := aRepository
]
