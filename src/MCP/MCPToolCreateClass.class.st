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
			   self classNameSchemaProperty.
			   self superclassNameSchemaProperty.
			   self packageNameSchemaProperty.
			   self tagSchemaProperty.
			   self slotsSchemaProperty.
			   self classSlotsSchemaProperty.
			   self traitsSchemaProperty.
			   self classTraitsSchemaProperty.
			   self sharedVariablesSchemaProperty.
			   self sharedPoolsSchemaProperty.
			   self layoutSchemaProperty.
			   self commentSchemaProperty }).
		  (#requiredProperties -> #( 'className' 'superclassName' 'packageName' )) } asDictionary
]

{ #category : 'metadata' }
MCPToolCreateClass >> defaultExposure [

	^ 'static'
]
