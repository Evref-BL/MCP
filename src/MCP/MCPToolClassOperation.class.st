"
Abstract base for focused class editing tools. It defines per-tool class inputs while reusing MCPToolEditClass request parsing and command dispatch internally.
"
Class {
	#name : 'MCPToolClassOperation',
	#superclass : 'MCPToolEditClass',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolClassOperation class >> isAbstract [

	^ self = MCPToolClassOperation
]

{ #category : 'private - schema' }
MCPToolClassOperation >> atLeastOneInputProperties [

	^ self classOperationSpec
		  at: #atLeastOneProperties
		  ifAbsent: [ #(  ) ]
]

{ #category : 'private - schema' }
MCPToolClassOperation >> classCommentSchemaProperty [

	^ self
		  schemaPropertyNamed: 'classComment'
		  type: 'string'
		  description: 'The class comment. Use an empty string to clear it.'
]

{ #category : 'private - schema' }
MCPToolClassOperation >> classNameSchemaProperty [

	^ self
		  schemaPropertyNamed: 'className'
		  type: 'string'
		  description: 'Class name targeted by this class tool.'
]

{ #category : 'private - operations' }
MCPToolClassOperation >> classOperationSpec [

	self subclassResponsibility
]

{ #category : 'private - schema' }
MCPToolClassOperation >> classSideSlotSchemaProperty [

	^ self
		  booleanSchemaPropertyNamed: 'classSide'
		  description: 'Whether the slot edit targets class-side slots.'
		  default: false
]

{ #category : 'private - schema' }
MCPToolClassOperation >> classSlotsSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'classSlots'
		  description:
		  'Class-side slot names. Use an empty array to define no class-side slots or remove all class-side slots during replacement. May be combined with slots.'
		  itemDescription: 'A class-side slot name.'
]

{ #category : 'private - schema' }
MCPToolClassOperation >> classTraitsSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'classTraits'
		  description:
		  'Class-side trait names. Use names like TraitName classTrait or TraitName. Use an empty array to remove all class-side traits.'
		  itemDescription: 'A class-side trait name.'
]

{ #category : 'defaults' }
MCPToolClassOperation >> defaultDescription [

	^ self classOperationSpec at: #description
]

{ #category : 'defaults' }
MCPToolClassOperation >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: self inputProperties;
		  required: self requiredInputProperties;
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolClassOperation >> defaultTitle [

	^ self classOperationSpec at: #title
]

{ #category : 'private - operations' }
MCPToolClassOperation >> fixedArguments [

	^ self classOperationSpec
		  at: #fixedArguments
		  ifAbsent: [ Dictionary new ]
]

{ #category : 'private - schema' }
MCPToolClassOperation >> inputProperties [

	^ self classOperationSpec at: #inputProperties
]

{ #category : 'private - schema' }
MCPToolClassOperation >> layoutSchemaProperty [

	^ self
		  schemaPropertyNamed: 'layout'
		  type: 'string'
		  description:
		  'The layout class name. It must resolve to AbstractLayout or one of its subclasses.'
]

{ #category : 'private - schema' }
MCPToolClassOperation >> newClassNameSchemaProperty [

	^ self
		  schemaPropertyNamed: 'newClassName'
		  type: 'string'
		  description: 'The new class name.'
]

{ #category : 'private - schema' }
MCPToolClassOperation >> newSlotNameSchemaProperty [

	^ self
		  schemaPropertyNamed: 'newSlotName'
		  type: 'string'
		  description: 'The replacement slot name.'
]

{ #category : 'private - errors' }
MCPToolClassOperation >> operationForErrorFromParsedRequest: editRequest rawRequest: rawRequest [

	^ self operationName
]

{ #category : 'private - operations' }
MCPToolClassOperation >> operationName [

	^ self classOperationSpec at: #operation ifAbsent: [ 'update' ]
]

{ #category : 'private - operations' }
MCPToolClassOperation >> operationSpecifications [

	^ { { (#name -> self operationName) } asDictionary }
]

{ #category : 'private - schema' }
MCPToolClassOperation >> packageNameSchemaProperty [

	^ self
		  schemaPropertyNamed: 'packageName'
		  type: 'string'
		  description:
		  'The package name for class creation or movement. When moving a class, omit packageName and provide tag to recategorize inside the current package.'
]

{ #category : 'private - request' }
MCPToolClassOperation >> parsedRequestFromToolRequest: request [

	| arguments focusedRequest |
	arguments := request arguments copy.
	arguments at: #operation put: self operationName.
	self fixedArguments keysAndValuesDo: [ :key :value |
		arguments at: key put: value ].
	focusedRequest := MCPToolRequest new
		                  tool: self;
		                  arguments: arguments;
		                  yourself.
	^ super parsedRequestFromToolRequest: focusedRequest
]

{ #category : 'private - schema' }
MCPToolClassOperation >> requiredInputProperties [

	^ self classOperationSpec
		  at: #requiredProperties
		  ifAbsent: [ #( 'className' ) ]
]

{ #category : 'private - schema' }
MCPToolClassOperation >> sharedPoolsSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'sharedPools'
		  description:
		  'Shared pool names. Use an empty array to remove all shared pools.'
		  itemDescription: 'A shared pool name.'
]

{ #category : 'private - schema' }
MCPToolClassOperation >> sharedVariablesSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'sharedVariables'
		  description:
		  'Class variable names. Use an empty array to remove all class variables.'
		  itemDescription: 'A class variable name.'
]

{ #category : 'private - schema' }
MCPToolClassOperation >> slotNameSchemaProperty [

	^ self
		  schemaPropertyNamed: 'slotName'
		  type: 'string'
		  description: 'The slot name.'
]

{ #category : 'private - schema' }
MCPToolClassOperation >> slotsSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'slots'
		  description:
		  'Instance-side slot names. Use an empty array to define no instance-side slots or remove all instance-side slots during replacement. May be combined with classSlots.'
		  itemDescription: 'An instance-side slot name.'
]

{ #category : 'private - schema' }
MCPToolClassOperation >> superclassNameSchemaProperty [

	^ self
		  schemaPropertyNamed: 'superclassName'
		  type: 'string'
		  description: 'The superclass name.'
]

{ #category : 'private - schema' }
MCPToolClassOperation >> tagSchemaProperty [

	^ self
		  schemaPropertyNamed: 'tag'
		  type: 'string'
		  description:
		  'The package tag or class category. When updating package assignment, tag recategorizes a class; omit packageName to use the current package.'
]

{ #category : 'private - schema' }
MCPToolClassOperation >> traitsSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'traits'
		  description:
		  'Instance-side trait names. Use an empty array to remove all instance-side traits.'
		  itemDescription: 'A trait name.'
]

{ #category : 'validating' }
MCPToolClassOperation >> validateAtLeastOneInputPropertyIn: request [

	| propertyNames requiredName |
	propertyNames := self atLeastOneInputProperties.
	propertyNames ifEmpty: [ ^ self ].
	(propertyNames anySatisfy: [ :each | request hasArgumentNamed: each ])
		ifTrue: [ ^ self ].
	requiredName := String streamContents: [ :stream |
			                propertyNames
				                do: [ :each | stream nextPutAll: each ]
				                separatedBy: [ stream nextPutAll: ' or ' ] ].
	MCPInvalidToolInput
		signalMissingRequiredArgumentNamed: requiredName
		forTool: self
]

{ #category : 'validating' }
MCPToolClassOperation >> validateRequest: request [

	self requiredInputProperties do: [ :each |
			(request argumentNamed: each ifAbsent: [ nil ]) ifNil: [
					MCPInvalidToolInput
						signalMissingRequiredArgumentNamed: each
						forTool: self ] ].
	self validateAtLeastOneInputPropertyIn: request
]
