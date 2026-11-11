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
		  (#description -> 'Create a class in the running image, or several sharing one definition.').
		  (#inputProperties -> {
			   self createClassNameSchemaProperty.
			   self createSuperclassNameSchemaProperty.
			   self createPackageNameSchemaProperty.
			   self createTagSchemaProperty.
			   self createSlotsSchemaProperty.
			   self createClassSlotsSchemaProperty.
			   self createTraitsSchemaProperty.
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
				   yourself);
		  yourself
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createClassSlotsSchemaProperty [

	^ self stringArraySchemaNamed: 'classSlots' description: 'Class-side instance variable names.' itemDescription: 'Slot name.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createCommentSchemaProperty [

	^ self schemaPropertyNamed: 'comment' type: 'string' description: 'Class comment.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createPackageNameSchemaProperty [

	^ self schemaPropertyNamed: 'package' type: 'string' description: 'Package for the class, created if missing.'
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

	^ self stringArraySchemaNamed: 'sharedVariables' description: 'Class variable names.' itemDescription: 'Variable name.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createSlotsSchemaProperty [

	^ self stringArraySchemaNamed: 'slots' description: 'Instance variable names.' itemDescription: 'Slot name.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createSuperclassNameSchemaProperty [

	^ self
		  schemaPropertyNamed: 'superclass'
		  type: 'string'
		  description: 'Superclass name, Object when omitted. Trait creates a trait.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createTagSchemaProperty [

	^ self schemaPropertyNamed: 'tag' type: 'string' description: 'Tag within the package.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createTraitsSchemaProperty [

	^ self stringArraySchemaNamed: 'traits' description: 'Traits the class uses, class side included.' itemDescription: 'Trait name.'
]

{ #category : 'metadata' }
MCPToolCreateClass >> defaultExposure [

	^ 'static'
]
