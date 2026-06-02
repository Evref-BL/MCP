"
Structured representation of a JSON Schema object used as a tool input schema.

It serializes type, properties, required fields, additionalProperties, and extra schema keywords into JSON-RPC output.
"
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

	| dictionary |
	dictionary := Dictionary new.
	self type ifNotNil: [ :schemaType |
		dictionary at: #type put: schemaType asJRPCJSON ].
	self properties ifNotNil: [
		dictionary at: #properties put: self propertiesAsJRPCJSON ].
	self required ifNotNil: [ :requiredProperties |
			requiredProperties ifNotEmpty: [
				dictionary at: #required put: requiredProperties asJRPCJSON ] ].
	self additionalProperties ifNotNil: [ :additionalPropertiesValue |
			additionalPropertiesValue ~~ true ifTrue: [
					dictionary
						at: #additionalProperties
						put: additionalPropertiesValue asJRPCJSON ] ].
	self extraProperties keysAndValuesDo: [ :key :value |
		dictionary at: key put: (self jsonValueForKey: key value: value) ].
	^ dictionary
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

	^ aValue asJRPCJSON
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
