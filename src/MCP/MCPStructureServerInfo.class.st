"
MCP protocol structure for server identity metadata.

It provides name, title, version, description, icons, website URL, and optional server instructions.
"
Class {
	#name : 'MCPStructureServerInfo',
	#superclass : 'Object',
	#instVars : [
		'name',
		'title',
		'version',
		'description',
		'icons',
		'websiteUrl',
		'instructions'
	],
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'accessing' }
MCPStructureServerInfo >> asJRPCJSON [

	| dic |
	dic := Dictionary new.
	self description ifNotNil: [
		dic at: #description put: self description asJRPCJSON ].
	self icons ifNotNil: [ dic at: #icons put: self icons asJRPCJSON ].
	self instructions ifNotNil: [
		dic at: #instructions put: self instructions asJRPCJSON ].
	self name ifNotNil: [ dic at: #name put: self name asJRPCJSON ].
	self title ifNotNil: [ dic at: #title put: self title asJRPCJSON ].
	self version ifNotNil: [
		dic at: #version put: self version asJRPCJSON ].
	self websiteUrl ifNotNil: [
		dic at: #websiteUrl put: self websiteUrl asJRPCJSON ].
	^ dic
]

{ #category : 'accessing' }
MCPStructureServerInfo >> description [

	^ description
]

{ #category : 'accessing' }
MCPStructureServerInfo >> description: anObject [

	description := anObject
]

{ #category : 'accessing' }
MCPStructureServerInfo >> icons [

	^ icons
]

{ #category : 'accessing' }
MCPStructureServerInfo >> icons: anObject [

	icons := anObject
]

{ #category : 'accessing' }
MCPStructureServerInfo >> instructions [

	^ instructions
]

{ #category : 'accessing' }
MCPStructureServerInfo >> instructions: anObject [

	instructions := anObject
]

{ #category : 'accessing' }
MCPStructureServerInfo >> name [

	^ name
]

{ #category : 'accessing' }
MCPStructureServerInfo >> name: anObject [

	name := anObject
]

{ #category : 'accessing' }
MCPStructureServerInfo >> title [

	^ title
]

{ #category : 'accessing' }
MCPStructureServerInfo >> title: anObject [

	title := anObject
]

{ #category : 'accessing' }
MCPStructureServerInfo >> version [

	^ version
]

{ #category : 'accessing' }
MCPStructureServerInfo >> version: anObject [

	version := anObject
]

{ #category : 'accessing' }
MCPStructureServerInfo >> websiteUrl [

	^ websiteUrl
]

{ #category : 'accessing' }
MCPStructureServerInfo >> websiteUrl: anObject [

	websiteUrl := anObject
]
