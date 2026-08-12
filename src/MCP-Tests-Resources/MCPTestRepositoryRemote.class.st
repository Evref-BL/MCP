"
Test double for an Iceberg remote used by repository tool tests.
"
Class {
	#name : 'MCPTestRepositoryRemote',
	#superclass : 'Object',
	#instVars : [
		'name',
		'repository',
		'shouldFail',
		'url'
	],
	#category : 'MCP-Tests-Resources-Internal',
	#package : 'MCP-Tests-Resources',
	#tag : 'Internal'
}

{ #category : 'instance creation' }
MCPTestRepositoryRemote class >> named: aName repository: aRepository shouldFail: aBoolean [

	^ self new
		  name: aName;
		  repository: aRepository;
		  shouldFail: aBoolean;
		  yourself
]

{ #category : 'actions' }
MCPTestRepositoryRemote >> fetch [

	self shouldFail ifTrue: [ Error signal: 'Fetch failed for remote ' , self name ].
	repository recordAction: 'fetch:' , self name
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

{ #category : 'testing' }
MCPTestRepositoryRemote >> shouldFail [

	^ shouldFail ifNil: [ false ]
]

{ #category : 'accessing' }
MCPTestRepositoryRemote >> shouldFail: aBoolean [

	shouldFail := aBoolean
]

{ #category : 'accessing' }
MCPTestRepositoryRemote >> url [

	^ url ifNil: [ 'memory://' , self name ]
]

{ #category : 'accessing' }
MCPTestRepositoryRemote >> url: aString [

	url := aString
]
