"
Test double for an upstream branch reference.
"
Class {
	#name : 'MCPTestRepositoryUpstream',
	#superclass : 'Object',
	#instVars : [
		'remoteName',
		'branchName'
	],
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'instance creation' }
MCPTestRepositoryUpstream class >> remoteName: aRemoteName branchName: aBranchName [

	^ self new
		  remoteName: aRemoteName;
		  branchName: aBranchName;
		  yourself
]

{ #category : 'accessing' }
MCPTestRepositoryUpstream >> branchName [

	^ branchName ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPTestRepositoryUpstream >> branchName: aString [

	branchName := aString
]

{ #category : 'accessing' }
MCPTestRepositoryUpstream >> name [

	self remoteName isEmpty ifTrue: [ ^ self branchName ].
	self branchName isEmpty ifTrue: [ ^ self remoteName ].
	^ self remoteName , '/' , self branchName
]

{ #category : 'accessing' }
MCPTestRepositoryUpstream >> remoteName [

	^ remoteName ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPTestRepositoryUpstream >> remoteName: aString [

	remoteName := aString
]

{ #category : 'accessing' }
MCPTestRepositoryUpstream >> shortname [

	^ self branchName
]
