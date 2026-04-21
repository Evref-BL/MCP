Class {
	#name : 'MCPStructureInputSchema',
	#superclass : 'Object',
	#instVars : [
		'type',
		'properties',
		'required',
		'additionalProperties'
	],
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'accessing' }
MCPStructureInputSchema >> additionalProperties [

	^ additionalProperties
]

{ #category : 'accessing' }
MCPStructureInputSchema >> additionalProperties: anObject [

	additionalProperties := anObject
]

{ #category : 'accessing' }
MCPStructureInputSchema >> asJRPCJSON [

	| dic |
	dic := Dictionary new.
	self type ifNotNil: [ dic at: #type put: self type asJRPCJSON ].
	self properties ifNotNil: [
		dic at: #properties put: self propertiesAsJRPCJSON ].
	self required ifNotNil: [
		dic at: #required put: self required asJRPCJSON ].
	self additionalProperties ifNotNil: [
		dic
			at: #additionalProperties
			put: self additionalProperties asJRPCJSON ].
	^ dic
]

{ #category : 'initialization' }
MCPStructureInputSchema >> initialize [

	super initialize.
	additionalProperties := false
]

{ #category : 'accessing' }
MCPStructureInputSchema >> properties [

	^ properties
]

{ #category : 'accessing' }
MCPStructureInputSchema >> properties: anObject [

	properties := anObject
]

{ #category : 'private' }
MCPStructureInputSchema >> propertiesAsJRPCJSON [

	| propertiesDictionary |
	propertiesDictionary := Dictionary new.
	self properties do: [ :prop |
		propertiesDictionary at: prop name put: prop metaDescription ].
	^ propertiesDictionary
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
