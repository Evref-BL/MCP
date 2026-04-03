Class {
	#name : 'MCPStructureCapabilities',
	#superclass : 'Object',
	#instVars : [
		'logging',
		'prompts',
		'resources',
		'tools',
		'tasks'
	],
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'accessing' }
MCPStructureCapabilities >> asJRPCJSON [
	| dic |
	dic := Dictionary new.
	self logging ifNotNil: [ dic at: #logging put: self logging asJRPCJSON ].
	self prompts ifNotNil: [ dic at: #prompts put: self prompts asJRPCJSON ].
	self resources ifNotNil: [ dic at: #resources put: self resources asJRPCJSON ].
	self tasks ifNotNil: [ dic at: #tasks put: self tasks asJRPCJSON ].
	self tools ifNotNil: [ dic at: #tools put: self tools asJRPCJSON ].
	^ dic
]

{ #category : 'accessing' }
MCPStructureCapabilities >> logging [

	^ logging
]

{ #category : 'accessing' }
MCPStructureCapabilities >> logging: anObject [

	logging := anObject
]

{ #category : 'accessing' }
MCPStructureCapabilities >> prompts [

	^ prompts
]

{ #category : 'accessing' }
MCPStructureCapabilities >> prompts: anObject [

	prompts := anObject
]

{ #category : 'accessing' }
MCPStructureCapabilities >> resources [

	^ resources
]

{ #category : 'accessing' }
MCPStructureCapabilities >> resources: anObject [

	resources := anObject
]

{ #category : 'accessing' }
MCPStructureCapabilities >> tasks [

	^ tasks
]

{ #category : 'accessing' }
MCPStructureCapabilities >> tasks: anObject [

	tasks := anObject
]

{ #category : 'accessing' }
MCPStructureCapabilities >> tools [

	^ tools
]

{ #category : 'accessing' }
MCPStructureCapabilities >> tools: anObject [

	tools := anObject
]
