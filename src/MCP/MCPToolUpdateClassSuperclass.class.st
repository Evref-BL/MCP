"
Tool that changes the superclass of one class.
"
Class {
	#name : 'MCPToolUpdateClassSuperclass',
	#superclass : 'MCPToolClassMutation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolUpdateClassSuperclass class >> toolName [

	^ 'class_superclass_update'
]

{ #category : 'private - specs' }
MCPToolUpdateClassSuperclass >> classToolSpec [

	^ {
		  (#title -> 'Update Class Superclass').
		  (#description -> 'Change the superclass of one class.').
		  (#inputProperties -> {
			   (self schemaPropertyNamed: 'name' type: 'string' description: 'Class name.').
			   self superclassNameSchemaProperty }).
		  (#requiredProperties -> #( 'name' 'superclassName' )) } asDictionary
]
