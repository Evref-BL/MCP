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
MCPJSONSchemaValidator class >> isValid: aValue against: aSchema [

	^ (self violationsFor: aValue schema: aSchema) isEmpty
]

{ #category : 'validating' }
MCPJSONSchemaValidator class >> violationsFor: aValue schema: aSchema [

	^ self new validate: aValue against: aSchema
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

{ #category : 'private - schema' }
MCPJSONSchemaValidator >> hasKeywordNamed: aKey in: aDictionary [

	^ (aDictionary includesKey: aKey) or: [
		  aDictionary includesKey: aKey asString ]
]

{ #category : 'private - schema' }
MCPJSONSchemaValidator >> hasObjectKeywordsIn: schema [

	^ #( required properties additionalProperties ) anySatisfy: [ :each |
		  self hasKeywordNamed: each in: schema ]
]

{ #category : 'private - object validation' }
MCPJSONSchemaValidator >> includesPropertyNamed: propertyName in: aDictionary [

	^ (aDictionary includesKey: propertyName) or: [
		  (aDictionary includesKey: propertyName asString) or: [
			  aDictionary includesKey: propertyName asSymbol ] ]
]

{ #category : 'initialization' }
MCPJSONSchemaValidator >> initialize [

	super initialize.
	violations := OrderedCollection new
]

{ #category : 'private - testing' }
MCPJSONSchemaValidator >> isJSONArray: aValue [

	^ aValue isCollection and: [
		  aValue isString not and: [ aValue isDictionary not ] ]
]

{ #category : 'private - schema' }
MCPJSONSchemaValidator >> keywordNamed: aKey in: aDictionary ifAbsent: absentBlock [

	^ aDictionary
		  at: aKey
		  ifAbsent: [ aDictionary at: aKey asString ifAbsent: absentBlock ]
]

{ #category : 'private - object validation' }
MCPJSONSchemaValidator >> propertyNamesIn: schema [

	| properties |
	properties := self
		              keywordNamed: #properties
		              in: schema
		              ifAbsent: [ ^ Set new ].
	^ (properties keys collect: [ :each | each asString ]) asSet
]

{ #category : 'private - object validation' }
MCPJSONSchemaValidator >> propertyValueNamed: propertyName in: aDictionary ifPresent: presentBlock ifAbsent: absentBlock [

	(aDictionary includesKey: propertyName) ifTrue: [
		^ presentBlock value: (aDictionary at: propertyName) ].
	(aDictionary includesKey: propertyName asString) ifTrue: [
		^ presentBlock value: (aDictionary at: propertyName asString) ].
	(aDictionary includesKey: propertyName asSymbol) ifTrue: [
		^ presentBlock value: (aDictionary at: propertyName asSymbol) ].
	^ absentBlock value
]

{ #category : 'private - combinators' }
MCPJSONSchemaValidator >> schema: schema matchesValue: aValue [

	^ (self class violationsFor: aValue schema: schema) isEmpty
]

{ #category : 'private - schema' }
MCPJSONSchemaValidator >> schemaCollectionNamed: aKey in: schema [

	| collection |
	collection := self
		              keywordNamed: aKey
		              in: schema
		              ifAbsent: [ ^ #(  ) ].
	collection ifNil: [ ^ #(  ) ].
	^ collection asArray
]

{ #category : 'private - schema' }
MCPJSONSchemaValidator >> schemaDictionaryFrom: aSchemaObject [

	aSchemaObject ifNil: [ ^ nil ].
	aSchemaObject isDictionary ifTrue: [ ^ aSchemaObject ].
	(aSchemaObject respondsTo: #asJRPCJSON) ifTrue: [
		^ aSchemaObject asJRPCJSON ].
	^ nil
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

	| additionalProperties propertyNames |
	additionalProperties := self
		                        keywordNamed: #additionalProperties
		                        in: schema
		                        ifAbsent: [ true ].
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
						expected: propertyNames asArray
						actual: key asString ]
				ifFalse: [
					self
						validateValue: value
						againstSchema: additionalProperties
						atPath: (path copyWith: key asString) ] ] ]
]

{ #category : 'private - combinators' }
MCPJSONSchemaValidator >> validateAllOfIn: schema for: aValue atPath: path [

	(self schemaCollectionNamed: #allOf in: schema) do: [ :eachSchema |
		self validateValue: aValue againstSchema: eachSchema atPath: path ]
]

{ #category : 'private - combinators' }
MCPJSONSchemaValidator >> validateAnyOfIn: schema for: aValue atPath: path [

	| matches schemas |
	schemas := self schemaCollectionNamed: #anyOf in: schema.
	schemas ifEmpty: [ ^ self ].
	matches := schemas count: [ :eachSchema |
		           self schema: eachSchema matchesValue: aValue ].
	matches = 0 ifTrue: [
		self
			addViolationAt: path
			keyword: #anyOf
			message: 'Value must match at least one schema branch.'
			expected: 'at least one matching branch'
			actual: matches ]
]

{ #category : 'private - array validation' }
MCPJSONSchemaValidator >> validateArray: aCollection againstSchema: schema atPath: path [

	| itemSchema minimumSize |
	minimumSize := self
		               keywordNamed: #minItems
		               in: schema
		               ifAbsent: [ nil ].
	(minimumSize notNil and: [ aCollection size < minimumSize ]) ifTrue: [
		self
			addViolationAt: path
			keyword: #minItems
			message: 'Array has too few items.'
			expected: minimumSize
			actual: aCollection size ].
	itemSchema := self
		              keywordNamed: #items
		              in: schema
		              ifAbsent: [ ^ self ].
	aCollection withIndexDo: [ :each :index |
		self
			validateValue: each
			againstSchema: itemSchema
			atPath: (path copyWith: index) ]
]

{ #category : 'private - validating' }
MCPJSONSchemaValidator >> validateConstIn: schema for: aValue atPath: path [

	| expectedValue |
	expectedValue := self
		                 keywordNamed: #const
		                 in: schema
		                 ifAbsent: [ ^ self ].
	aValue = expectedValue ifFalse: [
		self
			addViolationAt: path
			keyword: #const
			message: 'Value must equal the schema constant.'
			expected: expectedValue
			actual: aValue ]
]

{ #category : 'private - object validation' }
MCPJSONSchemaValidator >> validateDefinedPropertiesIn: aDictionary againstSchema: schema atPath: path [

	| properties |
	properties := self
		              keywordNamed: #properties
		              in: schema
		              ifAbsent: [ ^ self ].
	properties keysAndValuesDo: [ :propertyName :propertySchema |
		self
			propertyValueNamed: propertyName
			in: aDictionary
			ifPresent: [ :value |
				self
					validateValue: value
					againstSchema: propertySchema
					atPath: (path copyWith: propertyName asString) ]
			ifAbsent: [  ] ]
]

{ #category : 'private - validating' }
MCPJSONSchemaValidator >> validateEnumIn: schema for: aValue atPath: path [

	| expectedValues |
	expectedValues := self
		                  keywordNamed: #enum
		                  in: schema
		                  ifAbsent: [ ^ self ].
	(expectedValues includes: aValue) ifFalse: [
		self
			addViolationAt: path
			keyword: #enum
			message: 'Value must be one of the schema enum values.'
			expected: expectedValues
			actual: aValue ]
]

{ #category : 'private - combinators' }
MCPJSONSchemaValidator >> validateIfThenIn: schema for: aValue atPath: path [

	| conditionSchema thenSchema |
	conditionSchema := self
		                   keywordNamed: #if
		                   in: schema
		                   ifAbsent: [ ^ self ].
	thenSchema := self
		              keywordNamed: #then
		              in: schema
		              ifAbsent: [ ^ self ].
	(self schema: conditionSchema matchesValue: aValue) ifTrue: [
		self validateValue: aValue againstSchema: thenSchema atPath: path ]
]

{ #category : 'private - combinators' }
MCPJSONSchemaValidator >> validateNotIn: schema for: aValue atPath: path [

	| prohibitedSchema |
	prohibitedSchema := self
		                    keywordNamed: #not
		                    in: schema
		                    ifAbsent: [ ^ self ].
	(self schema: prohibitedSchema matchesValue: aValue) ifTrue: [
		self
			addViolationAt: path
			keyword: #not
			message: 'Value must not match the prohibited schema.'
			expected: 'a value that does not match the prohibited schema'
			actual: 'matched prohibited schema' ]
]

{ #category : 'private - object validation' }
MCPJSONSchemaValidator >> validateObject: aDictionary againstSchema: schema atPath: path [

	self
		validateRequiredPropertiesIn: aDictionary
		againstSchema: schema
		atPath: path.
	self
		validateDefinedPropertiesIn: aDictionary
		againstSchema: schema
		atPath: path.
	self
		validateAdditionalPropertiesIn: aDictionary
		againstSchema: schema
		atPath: path
]

{ #category : 'private - combinators' }
MCPJSONSchemaValidator >> validateOneOfIn: schema for: aValue atPath: path [

	| matches schemas |
	schemas := self schemaCollectionNamed: #oneOf in: schema.
	schemas ifEmpty: [ ^ self ].
	matches := schemas count: [ :eachSchema |
		           self schema: eachSchema matchesValue: aValue ].
	matches = 1 ifFalse: [
		self
			addViolationAt: path
			keyword: #oneOf
			message: 'Value must match exactly one schema branch.'
			expected: 'exactly one matching branch'
			actual: matches ]
]

{ #category : 'private - object validation' }
MCPJSONSchemaValidator >> validateRequiredPropertiesIn: aDictionary againstSchema: schema atPath: path [

	| requiredProperties |
	requiredProperties := self
		                      keywordNamed: #required
		                      in: schema
		                      ifAbsent: [ #(  ) ].
	requiredProperties do: [ :propertyName |
		(self includesPropertyNamed: propertyName in: aDictionary) ifFalse: [
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
	minimumLength := self
		                 keywordNamed: #minLength
		                 in: schema
		                 ifAbsent: [ nil ].
	(minimumLength notNil and: [ aString size < minimumLength ]) ifTrue: [
		self
			addViolationAt: path
			keyword: #minLength
			message: 'String is too short.'
			expected: minimumLength
			actual: aString size ]
]

{ #category : 'private - validating' }
MCPJSONSchemaValidator >> validateValue: aValue againstSchema: aSchemaObject atPath: path [

	| schema type |
	schema := self schemaDictionaryFrom: aSchemaObject.
	schema ifNil: [ ^ self ].
	self validateAllOfIn: schema for: aValue atPath: path.
	self validateAnyOfIn: schema for: aValue atPath: path.
	self validateOneOfIn: schema for: aValue atPath: path.
	self validateNotIn: schema for: aValue atPath: path.
	self validateIfThenIn: schema for: aValue atPath: path.
	self validateConstIn: schema for: aValue atPath: path.
	self validateEnumIn: schema for: aValue atPath: path.
	type := self keywordNamed: #type in: schema ifAbsent: [ nil ].
	type ifNotNil: [
		(self value: aValue matchesType: type) ifFalse: [
			self
				addViolationAt: path
				keyword: #type
				message: 'Value has the wrong JSON type.'
				expected: type
				actual: (self typeNameFor: aValue).
			^ self ] ].
	(aValue isDictionary or: [ self hasObjectKeywordsIn: schema ])
		ifTrue: [
			aValue isDictionary ifTrue: [
				self validateObject: aValue againstSchema: schema atPath: path ] ].
	(self isJSONArray: aValue) ifTrue: [
		self validateArray: aValue againstSchema: schema atPath: path ].
	aValue isString ifTrue: [
		self validateString: aValue againstSchema: schema atPath: path ]
]

{ #category : 'private - testing' }
MCPJSONSchemaValidator >> value: aValue matchesSingleType: typeName [

	| normalizedType |
	normalizedType := typeName asString.
	normalizedType = 'object' ifTrue: [ ^ aValue isDictionary ].
	normalizedType = 'array' ifTrue: [ ^ self isJSONArray: aValue ].
	normalizedType = 'string' ifTrue: [ ^ aValue isString ].
	normalizedType = 'boolean' ifTrue: [
		^ aValue == true or: [ aValue == false ] ].
	normalizedType = 'integer' ifTrue: [ ^ aValue isInteger ].
	normalizedType = 'number' ifTrue: [ ^ aValue isNumber ].
	normalizedType = 'null' ifTrue: [ ^ aValue isNil ].
	^ true
]

{ #category : 'private - testing' }
MCPJSONSchemaValidator >> value: aValue matchesType: typeName [

	(typeName isCollection and: [ typeName isString not ]) ifTrue: [
		^ typeName anySatisfy: [ :each |
			  self value: aValue matchesType: each ] ].
	^ self value: aValue matchesSingleType: typeName
]

{ #category : 'accessing' }
MCPJSONSchemaValidator >> violations [

	^ violations
]
