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

{ #category : 'metadata' }
MCPToolCreateClass >> batchArgumentName [

	^ 'name'
]

{ #category : 'metadata' }
MCPToolCreateClass >> batchSummaryNoun [

	^ 'classes'
]

{ #category : 'metadata' }
MCPToolCreateClass >> batchSummaryVerb [

	^ 'Created'
]

{ #category : 'private - specs' }
MCPToolCreateClass >> classToolSpec [

	^ {
		  (#action -> 'create').
		  (#title -> 'Create Class').
		  (#description -> 'Create one class definition in the running image. Naming Trait as the superclass creates a trait.').
		  (#inputProperties -> {
			   self createClassNameSchemaProperty.
			   self createSuperclassNameSchemaProperty.
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
		  (#requiredProperties -> #( 'name' 'package' )) } asDictionary
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createClassNameSchemaProperty [

	^ (self
		   schemaPropertyNamed: 'name'
		   type: #( 'string' 'array' )
		   description: 'Name of the class to create, or several names sharing the other arguments.')
		  items: (MCPStructureProperties new
			   type: 'string';
			   description: 'Name of one class to create.';
			   yourself);
		  yourself
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

	^ self schemaPropertyNamed: 'package' type: 'string' description: 'Package name for the new class.'
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
MCPToolCreateClass >> createSuperclassNameSchemaProperty [

	^ self
		  schemaPropertyNamed: 'superclass'
		  type: 'string'
		  description: 'Superclass name, Object when omitted. Name Trait here to create a trait, which has no superclass of its own.'
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
