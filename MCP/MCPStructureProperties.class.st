Class {
	#name : 'MCPStructureProperties',
	#superclass : 'Object',
	#instVars : [
		'name',
		'type',
		'description'
	],
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'accessing' }
MCPStructureProperties >> description [

	^ description
]

{ #category : 'accessing' }
MCPStructureProperties >> description: anObject [

	description := anObject
]

{ #category : 'accessing' }
MCPStructureProperties >> metaDescription [

	^ {
		  (#description -> self description).
		  (#type -> self type) } asDictionary
]

{ #category : 'accessing' }
MCPStructureProperties >> name [

	^ name
]

{ #category : 'accessing' }
MCPStructureProperties >> name: anObject [

	name := anObject
]

{ #category : 'accessing' }
MCPStructureProperties >> type [

	^ type
]

{ #category : 'accessing' }
MCPStructureProperties >> type: anObject [

	type := anObject
]
