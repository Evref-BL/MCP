"
Structured representation of a JSON Schema object used as a tool input schema.

It serializes type, properties, required fields and additionalProperties into JSON-RPC output.
"
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

	| dictionary |
	dictionary := Dictionary new.
	self type ifNotNil: [ :schemaType | dictionary at: #type put: schemaType asJRPCJSON ].
	self properties ifNotNil: [ :someProperties |
		dictionary at: #properties put: (MCPStructureProperties propertiesAsJRPCJSON: someProperties) ].
	self required ifNotNil: [ :requiredProperties |
		requiredProperties ifNotEmpty: [ dictionary at: #required put: requiredProperties asJRPCJSON ] ].
	self additionalProperties ifNotNil: [ :additionalPropertiesValue |
		additionalPropertiesValue ~~ true ifTrue: [ dictionary at: #additionalProperties put: additionalPropertiesValue asJRPCJSON ] ].
	^ dictionary
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
