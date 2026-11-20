"
Validates tool input payloads against the JSON Schema subset emitted by MCP tool input schemas. It reports structured violations instead of executing normalization logic itself.
"
Class {
	#name : 'MCPJSONSchemaValidator',
	#superclass : 'Object',
	#instVars : [
		'violations'
	],
	#category : 'MCP-Schema',
	#package : 'MCP',
	#tag : 'Schema'
}

{ #category : 'validating' }
MCPJSONSchemaValidator class >> violationsFor: aValue schema: aSchema [

	^ self new validate: aValue against: aSchema
]

{ #category : 'private - violations' }
MCPJSONSchemaValidator >> addTypeViolationAt: path for: aValue against: schema [
	"A value of the wrong type. Where the schema's type, one name or a list of them, allows an object, the violation names the object's keys, with an example made of the value."

	| type violation |
	type := schema mcpAt: #type ifAbsent: [ nil ].
	violation := MCPJSONSchemaViolation
		             path: path
		             keyword: #type
		             message: 'Value has the wrong JSON type.'
		             expected: type
		             actual: (self typeNameFor: aValue).
	((type isString
		  ifTrue: [ { type } ]
		  ifFalse: [ type ]) anySatisfy: [ :each | each asString = 'object' ]) ifTrue: [
			violation
				keys: (self propertyNamesIn: schema) asArray sort;
				example: (self exampleObjectOf: aValue against: schema) ].
	violations add: violation
]

{ #category : 'private - violations' }
MCPJSONSchemaValidator >> addViolationAt: path keyword: aKeyword message: aMessage expected: expectedValue actual: actualValue [

	violations add: (MCPJSONSchemaViolation
			 path: path
			 keyword: aKeyword
			 message: aMessage
			 expected: expectedValue
			 actual: actualValue)
]

{ #category : 'private - object validation' }
MCPJSONSchemaValidator >> exampleObjectOf: aValue against: schema [
	"An object of schema's shape made of aValue, which is not one, or nil when none can be made of it. JSON written as a string is read first, since the caller meant what it holds, and text that does not read gives none rather than one that wraps it. An object read so is the example only when it matches schema with keys schema names: one that does not would show the caller its own mistake back, and under a property that takes any object it would read as right. Otherwise the value goes under the first property by name that takes it as it is, or failing that under the first that takes it in a list, provided the object then matches schema; a property that takes the value as sent is the better guess, and which one a list goes under remains a guess. A value that names a property gives none, since the caller then sent a key where an object goes."

	| names value |
	(self hasKeywordNamed: #properties in: schema) ifFalse: [ ^ nil ].
	value := self valueHeldBy: aValue ifUnreadable: [ ^ nil ].
	names := (self propertyNamesIn: schema) asArray sort.
	value isDictionary ifTrue: [
			^ (value isNotEmpty and: [
				   (value keys allSatisfy: [ :each | names includes: each asString ]) and: [ self schema: schema matchesValue: value ] ])
				  ifTrue: [ value ]
				  ifFalse: [ nil ] ].
	(names includes: value) ifTrue: [ ^ nil ].
	{
		value.
		{ value } } do: [ :candidate |
			names do: [ :name |
					| example |
					example := Dictionary new
						           at: name put: candidate;
						           yourself.
					(self schema: schema matchesValue: example) ifTrue: [ ^ example ] ] ].
	^ nil
]

{ #category : 'private - schema' }
MCPJSONSchemaValidator >> hasKeywordNamed: aKey in: aDictionary [

	aDictionary mcpAt: aKey ifAbsent: [ ^ false ].
	^ true
]

{ #category : 'private - schema' }
MCPJSONSchemaValidator >> hasObjectKeywordsIn: schema [

	^ #( required properties additionalProperties ) anySatisfy: [ :each | self hasKeywordNamed: each in: schema ]
]

{ #category : 'initialization' }
MCPJSONSchemaValidator >> initialize [

	super initialize.
	violations := OrderedCollection new
]

{ #category : 'private - testing' }
MCPJSONSchemaValidator >> isJSONArray: aValue [

	^ aValue isCollection and: [ aValue isString not and: [ aValue isDictionary not ] ]
]

{ #category : 'private - schema' }
MCPJSONSchemaValidator >> keywordNamed: aKey in: aDictionary ifPresent: presentBlock [

	^ presentBlock value: (aDictionary mcpAt: aKey ifAbsent: [ ^ nil ])
]

{ #category : 'private - object validation' }
MCPJSONSchemaValidator >> propertyNamesIn: schema [

	| properties |
	properties := schema mcpAt: #properties ifAbsent: [ ^ Set new ].
	^ properties keys collect: [ :each | each asString ] as: Set
]

{ #category : 'private - object validation' }
MCPJSONSchemaValidator >> schema: schema matchesValue: aValue [

	^ (self class violationsFor: aValue schema: schema) isEmpty
]

{ #category : 'private - schema' }
MCPJSONSchemaValidator >> schemaDictionaryFrom: aSchemaObject [

	aSchemaObject ifNil: [ ^ nil ].
	aSchemaObject isDictionary ifTrue: [ ^ aSchemaObject ].
	^ aSchemaObject asJRPCJSON
]

{ #category : 'private - testing' }
MCPJSONSchemaValidator >> typeNameFor: aValue [

	aValue ifNil: [ ^ 'null' ].
	aValue isDictionary ifTrue: [ ^ 'object' ].
	(self isJSONArray: aValue) ifTrue: [ ^ 'array' ].
	aValue isString ifTrue: [ ^ 'string' ].
	(aValue == true or: [ aValue == false ]) ifTrue: [ ^ 'boolean' ].
	aValue isInteger ifTrue: [ ^ 'integer' ].
	aValue isNumber ifTrue: [ ^ 'number' ].
	^ aValue class name asString
]

{ #category : 'validating' }
MCPJSONSchemaValidator >> validate: aValue against: aSchema [

	violations := OrderedCollection new.
	self validateValue: aValue againstSchema: aSchema atPath: #(  ).
	^ violations asArray
]

{ #category : 'private - object validation' }
MCPJSONSchemaValidator >> validateAdditionalPropertiesIn: aDictionary againstSchema: schema atPath: path [
	"An unexpected property expects the ones the schema names, so the caller learns what it could have sent."

	| additionalProperties propertyNames |
	additionalProperties := schema mcpAt: #additionalProperties ifAbsent: [ true ].
	additionalProperties == true ifTrue: [ ^ self ].
	propertyNames := self propertyNamesIn: schema.
	aDictionary keysAndValuesDo: [ :key :value |
			(propertyNames includes: key asString) ifFalse: [
					additionalProperties == false
						ifTrue: [
								self
									addViolationAt: (path copyWith: key asString)
									keyword: #additionalProperties
									message: 'Object contains an unexpected property.'
									expected: (propertyNames ifEmpty: [ nil ] ifNotEmpty: [ propertyNames asArray sort ])
									actual: key asString ]
						ifFalse: [ self validateValue: value againstSchema: additionalProperties atPath: (path copyWith: key asString) ] ] ]
]

{ #category : 'private - array validation' }
MCPJSONSchemaValidator >> validateArray: aCollection againstSchema: schema atPath: path [
	"Positions in a path count from zero, as in the JSON the caller sent."

	| itemSchema minimumSize |
	minimumSize := schema mcpAt: #minItems ifAbsent: [ nil ].
	minimumSize ifNotNil: [ :requiredSize |
			aCollection size < requiredSize ifTrue: [
					self
						addViolationAt: path
						keyword: #minItems
						message: 'Array has too few items.'
						expected: requiredSize
						actual: aCollection size ] ].
	itemSchema := schema mcpAt: #items ifAbsent: [ ^ self ].
	aCollection withIndexDo: [ :each :index | self validateValue: each againstSchema: itemSchema atPath: (path copyWith: index - 1) ]
]

{ #category : 'private - object validation' }
MCPJSONSchemaValidator >> validateDefinedPropertiesIn: aDictionary againstSchema: schema atPath: path [

	| properties |
	properties := schema mcpAt: #properties ifAbsent: [ ^ self ].
	properties keysAndValuesDo: [ :propertyName :propertySchema |
			self
				keywordNamed: propertyName
				in: aDictionary
				ifPresent: [ :value | self validateValue: value againstSchema: propertySchema atPath: (path copyWith: propertyName asString) ] ]
]

{ #category : 'private - validating' }
MCPJSONSchemaValidator >> validateEnumIn: schema for: aValue atPath: path [

	| expectedValues |
	expectedValues := schema mcpAt: #enum ifAbsent: [ ^ self ].
	(expectedValues includes: aValue) ifFalse: [
			self
				addViolationAt: path
				keyword: #enum
				message: 'Value must be one of the schema enum values.'
				expected: expectedValues
				actual: aValue ]
]

{ #category : 'private - number validation' }
MCPJSONSchemaValidator >> validateNumber: aNumber againstSchema: schema atPath: path [

	(schema mcpAt: #minimum ifAbsent: [ nil ]) ifNotNil: [ :minimum |
			aNumber < minimum ifTrue: [
					self
						addViolationAt: path
						keyword: #minimum
						message: 'Number below schema minimum.'
						expected: minimum
						actual: aNumber ] ].
	(schema mcpAt: #maximum ifAbsent: [ nil ]) ifNotNil: [ :maximum |
			aNumber > maximum ifTrue: [
					self
						addViolationAt: path
						keyword: #maximum
						message: 'Number above schema maximum.'
						expected: maximum
						actual: aNumber ] ]
]

{ #category : 'private - object validation' }
MCPJSONSchemaValidator >> validateObject: aDictionary againstSchema: schema atPath: path [

	self validateRequiredPropertiesIn: aDictionary againstSchema: schema atPath: path.
	self validateDefinedPropertiesIn: aDictionary againstSchema: schema atPath: path.
	self validateAdditionalPropertiesIn: aDictionary againstSchema: schema atPath: path
]

{ #category : 'private - object validation' }
MCPJSONSchemaValidator >> validateRequiredPropertiesIn: aDictionary againstSchema: schema atPath: path [

	| requiredProperties |
	requiredProperties := schema mcpAt: #required ifAbsent: [ #(  ) ].
	requiredProperties do: [ :propertyName |
			(self hasKeywordNamed: propertyName in: aDictionary) ifFalse: [
					self
						addViolationAt: path
						keyword: #required
						message: 'Object is missing a required property.'
						expected: propertyName
						actual: nil ] ]
]

{ #category : 'private - string validation' }
MCPJSONSchemaValidator >> validateString: aString againstSchema: schema atPath: path [

	| minimumLength |
	minimumLength := schema mcpAt: #minLength ifAbsent: [ nil ].
	minimumLength ifNotNil: [ :requiredLength |
			aString size < requiredLength ifTrue: [
					self
						addViolationAt: path
						keyword: #minLength
						message: 'String is too short.'
						expected: requiredLength
						actual: aString size ] ]
]

{ #category : 'private - validating' }
MCPJSONSchemaValidator >> validateValue: aValue againstSchema: aSchemaObject atPath: path [

	| schema type |
	schema := self schemaDictionaryFrom: aSchemaObject.
	schema ifNil: [ ^ self ].
	self validateEnumIn: schema for: aValue atPath: path.
	type := schema mcpAt: #type ifAbsent: [ nil ].
	type ifNotNil: [
			(self value: aValue matchesType: type) ifFalse: [
					self addTypeViolationAt: path for: aValue against: schema.
					^ self ] ].
	(aValue isDictionary or: [ self hasObjectKeywordsIn: schema ]) ifTrue: [
		aValue isDictionary ifTrue: [ self validateObject: aValue againstSchema: schema atPath: path ] ].
	(self isJSONArray: aValue) ifTrue: [ self validateArray: aValue againstSchema: schema atPath: path ].
	aValue isString ifTrue: [ self validateString: aValue againstSchema: schema atPath: path ].
	aValue isNumber ifTrue: [ self validateNumber: aValue againstSchema: schema atPath: path ]
]

{ #category : 'private - testing' }
MCPJSONSchemaValidator >> value: aValue matchesSingleType: typeName [

	| normalizedType |
	normalizedType := typeName asString.
	normalizedType = 'object' ifTrue: [ ^ aValue isDictionary ].
	normalizedType = 'array' ifTrue: [ ^ self isJSONArray: aValue ].
	normalizedType = 'string' ifTrue: [ ^ aValue isString ].
	normalizedType = 'boolean' ifTrue: [ ^ aValue == true or: [ aValue == false ] ].
	normalizedType = 'integer' ifTrue: [ ^ aValue isInteger ].
	normalizedType = 'number' ifTrue: [ ^ aValue isNumber ].
	normalizedType = 'null' ifTrue: [ ^ aValue isNil ].
	^ true
]

{ #category : 'private - testing' }
MCPJSONSchemaValidator >> value: aValue matchesType: typeName [

	(typeName isCollection and: [ typeName isString not ]) ifTrue: [
		^ typeName anySatisfy: [ :each | self value: aValue matchesType: each ] ].
	^ self value: aValue matchesSingleType: typeName
]

{ #category : 'private - object validation' }
MCPJSONSchemaValidator >> valueHeldBy: aValue ifUnreadable: aBlock [
	"aValue, or the array or object it holds when it is JSON written as a string, between brackets or braces: a caller that sends a list or an object as a string means what it holds. aBlock answers for such a string that does not read as JSON, which holds no value to show."

	| text |
	aValue isString ifFalse: [ ^ aValue ].
	text := aValue trimBoth.
	(text size >= 2 and: [ (text first = $[ and: [ text last = $] ]) or: [ text first = ${ and: [ text last = $} ] ] ]) ifFalse: [
		^ aValue ].
	^ [ STONJSON fromString: text ]
		  on: Error
		  do: [ :error | aBlock value ]
]

{ #category : 'accessing' }
MCPJSONSchemaValidator >> violations [

	^ violations
]
