"
Focused tool that creates one class definition without exposing the broader class edit operation selector.
"
Class {
	#name : 'MCPToolCreateClass',
	#superclass : 'MCPToolClassOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolCreateClass class >> toolName [

	^ 'class_create'
]

{ #category : 'private - operations' }
MCPToolCreateClass >> classOperationSpec [

	^ {
		  (#title -> 'Create Class').
		  (#description
		   -> 'Create one class definition in the running image.').
		  (#operation -> 'create').
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
			   self classCommentSchemaProperty }).
		  (#requiredProperties
		   -> #( 'className' 'superclassName' 'packageName' )) }
		  asDictionary
]
