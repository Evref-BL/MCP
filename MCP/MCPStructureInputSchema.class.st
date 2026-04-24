Class {
	#name : 'MCPStructureInputSchema',
	#superclass : 'Object',
	#instVars : [
		'type',
		'properties',
		'required',
		'additionalProperties',
		'extraProperties'
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
MCPStructureInputSchema >> allOf: aCollection [

	self schemaKeyword: #allOf put: aCollection
]

{ #category : 'accessing' }
MCPStructureInputSchema >> anyOf: aCollection [

	self schemaKeyword: #anyOf put: aCollection
]

{ #category : 'accessing' }
MCPStructureInputSchema >> asJRPCJSON [

	| dic |
	dic := Dictionary new.
	self type ifNotNil: [ dic at: #type put: self type asJRPCJSON ].
	self properties ifNotNil: [
		dic at: #properties put: self propertiesAsJRPCJSON ].
	(self required notNil and: [ self required notEmpty ]) ifTrue: [
		dic at: #required put: self required asJRPCJSON ].
	(self additionalProperties notNil and: [
		 self additionalProperties ~~ true ]) ifTrue: [
		dic
			at: #additionalProperties
			put: self additionalProperties asJRPCJSON ].
	self extraProperties keysAndValuesDo: [ :key :value |
		dic at: key put: (self jsonValueForKey: key value: value) ].
	^ dic
]

{ #category : 'accessing' }
MCPStructureInputSchema >> extraProperties [

	^ extraProperties ifNil: [ extraProperties := Dictionary new ]
]

{ #category : 'accessing' }
MCPStructureInputSchema >> extraProperties: anObject [

	extraProperties := anObject
		                   ifNil: [ Dictionary new ]
		                   ifNotNil: [ anObject ]
]

{ #category : 'initialization' }
MCPStructureInputSchema >> initialize [

	super initialize.
	additionalProperties := false.
	extraProperties := Dictionary new
]

{ #category : 'private' }
MCPStructureInputSchema >> jsonValueForKey: aKey value: aValue [

	^ (aValue respondsTo: #asJRPCJSON)
		  ifTrue: [ aValue asJRPCJSON ]
		  ifFalse: [ aValue ]
]

{ #category : 'accessing' }
MCPStructureInputSchema >> oneOf: aCollection [

	self schemaKeyword: #oneOf put: aCollection
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
MCPStructureInputSchema >> schemaKeyword: aKeyword put: aValue [

	self extraProperties at: aKeyword put: aValue
]

{ #category : 'accessing' }
MCPStructureInputSchema >> type [

	^ type
]

{ #category : 'accessing' }
MCPStructureInputSchema >> type: anObject [

	type := anObject
]
