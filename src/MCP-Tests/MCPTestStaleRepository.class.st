"
Test double for repository metadata failures caused by stale filesystem state.

It raises a file exception from head access so repository search tests can verify one stale registered repository does not abort the whole query.
"
Class {
	#name : 'MCPTestStaleRepository',
	#superclass : 'Object',
	#instVars : [
		'name',
		'location'
	],
	#category : 'MCP-Tests-Repository doubles',
	#package : 'MCP-Tests',
	#tag : 'Repository doubles'
}

{ #category : 'instance creation' }
MCPTestStaleRepository class >> named: aName location: aFileReference [

	^ self new initializeName: aName location: aFileReference
]

{ #category : 'accessing' }
MCPTestStaleRepository >> branchName [

	^ FileDoesNotExistException signal: location pathString
]

{ #category : 'accessing' }
MCPTestStaleRepository >> head [

	^ FileDoesNotExistException signal: location pathString
]

{ #category : 'accessing' }
MCPTestStaleRepository >> headCommit [

	^ nil
]

{ #category : 'accessing' }
MCPTestStaleRepository >> headDescription [

	^ ''
]

{ #category : 'initialization' }
MCPTestStaleRepository >> initializeName: aName location: aFileReference [

	name := aName.
	location := aFileReference
]

{ #category : 'testing' }
MCPTestStaleRepository >> isMissing [

	^ true
]

{ #category : 'testing' }
MCPTestStaleRepository >> isModified [

	^ false
]

{ #category : 'accessing' }
MCPTestStaleRepository >> location [

	^ location
]

{ #category : 'accessing' }
MCPTestStaleRepository >> name [

	^ name
]

{ #category : 'accessing' }
MCPTestStaleRepository >> subdirectory [

	^ 'src'
]
