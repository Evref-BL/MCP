"
Test double for a modified Iceberg package used by repository tool tests.
"
Class {
	#name : 'MCPTestRepositoryModifiedPackage',
	#superclass : 'Object',
	#instVars : [
		'name'
	],
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'instance creation' }
MCPTestRepositoryModifiedPackage class >> named: aName [

	^ self new
		  name: aName;
		  yourself
]

{ #category : 'accessing' }
MCPTestRepositoryModifiedPackage >> name [

	^ name
]

{ #category : 'accessing' }
MCPTestRepositoryModifiedPackage >> name: aString [

	name := aString
]
