"
Test double for a repository head commit.
"
Class {
	#name : 'MCPTestRepositoryCommit',
	#superclass : 'Object',
	#instVars : [
		'id'
	],
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'instance creation' }
MCPTestRepositoryCommit class >> id: aString [

	^ self new
		  id: aString;
		  yourself
]

{ #category : 'accessing' }
MCPTestRepositoryCommit >> id [

	^ id ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPTestRepositoryCommit >> id: aString [

	id := aString
]
