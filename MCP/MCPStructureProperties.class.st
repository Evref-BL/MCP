"
Structured representation of one JSON Schema property.

It stores property name, type, description, and extra schema keywords such as enum, items, default, properties, required, and additionalProperties.
"
Class {
	#name : 'MCPStructureProperties',
	#superclass : 'Object',
	#instVars : [
		'name',
		'type',
		'description',
		'extraProperties'
	],
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'accessing' }
MCPStructureProperties >> additionalProperties: aBoolean [

	self extraProperties at: #additionalProperties put: aBoolean
]

{ #category : 'accessing' }
MCPStructureProperties >> asJRPCJSON [

	^ self metaDescription
]

{ #category : 'accessing' }
MCPStructureProperties >> const: anObject [

	self extraProperties at: #const put: anObject
]

{ #category : 'accessing' }
MCPStructureProperties >> default: anObject [

	self extraProperties at: #default put: anObject
]

{ #category : 'accessing' }
MCPStructureProperties >> description [

	^ description
]

{ #category : 'accessing' }
MCPStructureProperties >> description: anObject [

	description := anObject
]

{ #category : 'accessing' }
MCPStructureProperties >> enum: aCollection [

	self extraProperties at: #enum put: aCollection
]

{ #category : 'accessing' }
MCPStructureProperties >> extraProperties [

	^ extraProperties
]

{ #category : 'accessing' }
MCPStructureProperties >> extraProperties: anObject [

	extraProperties := anObject
]

{ #category : 'initialization' }
MCPStructureProperties >> initialize [

	super initialize.
	extraProperties := Dictionary new
]

{ #category : 'accessing' }
MCPStructureProperties >> items: aSchema [

	self extraProperties at: #items put: aSchema
]

{ #category : 'private' }
MCPStructureProperties >> jsonValueForKey: aKey value: aValue [

	aKey = #properties ifTrue: [ ^ self propertiesAsJRPCJSON: aValue ].
	^ (aValue respondsTo: #asJRPCJSON)
		  ifTrue: [ aValue asJRPCJSON ]
		  ifFalse: [ aValue ]
]

{ #category : 'accessing' }
MCPStructureProperties >> metaDescription [

	| schema |
	schema := Dictionary new.
	self description ifNotNil: [
		schema at: #description put: self description ].
	self type ifNotNil: [ schema at: #type put: self type ].
	self extraProperties keysAndValuesDo: [ :key :value |
		schema at: key put: (self jsonValueForKey: key value: value) ].
	^ schema
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
MCPStructureProperties >> properties: aCollection [

	self extraProperties at: #properties put: aCollection
]

{ #category : 'private' }
MCPStructureProperties >> propertiesAsJRPCJSON: aCollection [

	| propertiesDictionary |
	propertiesDictionary := Dictionary new.
	aCollection do: [ :prop |
		propertiesDictionary at: prop name put: prop metaDescription ].
	^ propertiesDictionary
]

{ #category : 'accessing' }
MCPStructureProperties >> required: aCollection [

	self extraProperties at: #required put: aCollection
]

{ #category : 'accessing' }
MCPStructureProperties >> type [

	^ type
]

{ #category : 'accessing' }
MCPStructureProperties >> type: anObject [

	type := anObject
]
