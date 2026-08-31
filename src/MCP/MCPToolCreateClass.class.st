"
Tool that creates one class definition without exposing a combined class-mutation selector.
"
Class {
	#name : 'MCPToolCreateClass',
	#superclass : 'MCPToolClassMutation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolCreateClass class >> toolName [

	^ 'class_create'
]

{ #category : 'private - specs' }
MCPToolCreateClass >> classToolSpec [

	^ {
		  (#action -> 'create').
		  (#title -> 'Create Class').
		  (#description -> 'Create one class definition in the running image.').
		  (#inputProperties -> {
			   self createClassNameSchemaProperty.
			   self superclassNameSchemaProperty.
			   self createPackageNameSchemaProperty.
			   self createTagSchemaProperty.
			   self createSlotsSchemaProperty.
			   self createClassSlotsSchemaProperty.
			   self createTraitsSchemaProperty.
			   self createClassTraitsSchemaProperty.
			   self createSharedVariablesSchemaProperty.
			   self createSharedPoolsSchemaProperty.
			   self layoutSchemaProperty.
			   self createCommentSchemaProperty }).
		  (#requiredProperties -> #( 'name' 'superclassName' 'packageName' )) } asDictionary
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createClassNameSchemaProperty [

	^ self schemaPropertyNamed: 'name' type: 'string' description: 'Name of the class to create.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createClassSlotsSchemaProperty [

	^ self stringArraySchemaNamed: 'classSlots' description: 'Class-side slot names for the new class.' itemDescription: 'Slot name.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createClassTraitsSchemaProperty [

	^ self stringArraySchemaNamed: 'classTraits' description: 'Class-side traits for the new class.' itemDescription: 'Trait name.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createCommentSchemaProperty [

	^ self schemaPropertyNamed: 'comment' type: 'string' description: 'Class comment for the new class.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createPackageNameSchemaProperty [

	^ self schemaPropertyNamed: 'packageName' type: 'string' description: 'Package name for the new class.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createSharedPoolsSchemaProperty [

	^ self stringArraySchemaNamed: 'sharedPools' description: 'Shared pools for the new class.' itemDescription: 'Shared pool name.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createSharedVariablesSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'sharedVariables'
		  description: 'Class variables for the new class.'
		  itemDescription: 'Variable name.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createSlotsSchemaProperty [

	^ self stringArraySchemaNamed: 'slots' description: 'Instance slot names for the new class.' itemDescription: 'Slot name.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createTagSchemaProperty [

	^ self schemaPropertyNamed: 'tag' type: 'string' description: 'Package tag for the new class.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createTraitsSchemaProperty [

	^ self stringArraySchemaNamed: 'traits' description: 'Instance traits for the new class.' itemDescription: 'Trait name.'
]

{ #category : 'metadata' }
MCPToolCreateClass >> defaultExposure [

	^ 'static'
]
