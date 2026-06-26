"
Result DTO for class creation.

It wraps the MCPClassInfo for the newly created class.
"
Class {
	#name : 'MCPCreateClassResult',
	#superclass : 'MCPClassResult',
	#instVars : [
		'classInfo'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPCreateClassResult class >> classInfo: aClassInfo [

	^ self new
		  classInfo: aClassInfo;
		  yourself
]

{ #category : 'accessing' }
MCPCreateClassResult >> classInfo [

	^ classInfo
]

{ #category : 'accessing' }
MCPCreateClassResult >> classInfo: anObject [

	classInfo := anObject
]
