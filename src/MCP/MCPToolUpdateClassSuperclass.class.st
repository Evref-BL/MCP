"
Focused tool that changes the superclass of one class.
"
Class {
	#name : 'MCPToolUpdateClassSuperclass',
	#superclass : 'MCPToolClassOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolUpdateClassSuperclass class >> toolName [

	^ 'class_superclass_update'
]

{ #category : 'private - operations' }
MCPToolUpdateClassSuperclass >> classOperationSpec [

	^ {
		  (#title -> 'Update Class Superclass').
		  (#description -> 'Change the superclass of one class.').
		  (#inputProperties -> {
			   self classNameSchemaProperty.
			   self superclassNameSchemaProperty.
			   self forceSchemaProperty }).
		  (#requiredProperties -> #( 'className' 'superclassName' )) }
		  asDictionary
]
