"
Tool that creates one class definition without exposing a combined class-mutation selector.
"
Class {
	#name : 'MCPToolCreateClass',
	#superclass : 'MCPToolClassMutation',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
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

	^ self stringArraySchemaNamed: 'classSlots' description: 'Variables the class object itself holds.' itemDescription: 'Slot name.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createClassTraitsSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'classTraits'
		  description: 'Traits the class uses on the class side.'
		  itemDescription: 'Trait name.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createCommentSchemaProperty [

	^ self schemaPropertyNamed: 'comment' type: 'string' description: 'Class comment, saying what the class is for.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createPackageNameSchemaProperty [

	^ self
		  schemaPropertyNamed: 'package'
		  type: 'string'
		  description: 'Package to create the class in. It is created if it does not exist.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createSharedPoolsSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'sharedPools'
		  description: 'Shared pools the class reads variables from.'
		  itemDescription: 'Pool name.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createSharedVariablesSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'sharedVariables'
		  description: 'Class variables, shared by the class and every instance of it.'
		  itemDescription: 'Variable name.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createSlotsSchemaProperty [

	^ self stringArraySchemaNamed: 'slots' description: 'Instance variables the class defines.' itemDescription: 'Slot name.'
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

	^ self schemaPropertyNamed: 'tag' type: 'string' description: 'Tag to file the class under inside its package.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createTraitsSchemaProperty [

	^ self stringArraySchemaNamed: 'traits' description: 'Traits the class uses on the instance side.' itemDescription: 'Trait name.'
]

{ #category : 'metadata' }
MCPToolCreateClass >> defaultExposure [

	^ 'static'
]
