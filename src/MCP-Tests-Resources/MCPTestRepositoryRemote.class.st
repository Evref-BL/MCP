"
Test double for an Iceberg remote used by repository tool tests.
"
Class {
	#name : 'MCPTestRepositoryRemote',
	#superclass : 'Object',
	#instVars : [
		'name',
		'repository',
		'url'
	],
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'instance creation' }
MCPTestRepositoryRemote class >> named: aName repository: aRepository [

	^ self new
		  name: aName;
		  repository: aRepository;
		  yourself
]

{ #category : 'accessing' }
MCPTestRepositoryRemote >> name [

	^ name
]

{ #category : 'accessing' }
MCPTestRepositoryRemote >> name: aString [

	name := aString
]

{ #category : 'accessing' }
MCPTestRepositoryRemote >> repository: aRepository [

	repository := aRepository
]

{ #category : 'accessing' }
MCPTestRepositoryRemote >> url [

	^ url ifNil: [ 'memory://' , self name ]
]

{ #category : 'accessing' }
MCPTestRepositoryRemote >> url: aString [

	url := aString
]
