Class {
	#name : 'MCPCreateClassResult',
	#superclass : 'Object',
	#instVars : [
		'classInfo'
	],
	#category : 'MCP-Internal',
	#package : 'MCP',
	#tag : 'Internal'
}

{ #category : 'instance creation' }
MCPCreateClassResult class >> classInfo: aClassInfo [

	^ self new
		  classInfo: aClassInfo;
		  yourself
]

{ #category : 'converting' }
MCPCreateClassResult >> asDictionary [

	^ self classInfo asDictionary copy
]

{ #category : 'accessing' }
MCPCreateClassResult >> classInfo [

	^ classInfo
]

{ #category : 'accessing' }
MCPCreateClassResult >> classInfo: anObject [

	classInfo := anObject
]
