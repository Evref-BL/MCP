Class {
	#name : 'MCPStructureInputSchema',
	#superclass : 'Object',
	#instVars : [
		'type',
		'properties',
		'required'
	],
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'accessing' }
MCPStructureInputSchema >> asJRPCJSON [

	| dic |
	dic := Dictionary new.
	self properties
		ifNotNil: [ 
			| propertiesDicObject|
			propertiesDicObject := Dictionary new.
			self properties do: [ :prop |
				propertiesDicObject at: prop name put: prop metaDescription.
				 ].
			dic at: #properties put: propertiesDicObject  ]
		ifNil: [ dic at: #additionalProperties put: false ].
	self required ifNotNil: [
		dic at: #required put: self required asJRPCJSON ].
	self type ifNotNil: [ dic at: #type put: self type asJRPCJSON ].
	^ dic
]

{ #category : 'accessing' }
MCPStructureInputSchema >> properties [

	^ properties
]

{ #category : 'accessing' }
MCPStructureInputSchema >> properties: anObject [

	properties := anObject
]

{ #category : 'accessing' }
MCPStructureInputSchema >> required [

	^ required
]

{ #category : 'accessing' }
MCPStructureInputSchema >> required: anObject [

	required := anObject
]

{ #category : 'accessing' }
MCPStructureInputSchema >> type [

	^ type
]

{ #category : 'accessing' }
MCPStructureInputSchema >> type: anObject [

	type := anObject
]
