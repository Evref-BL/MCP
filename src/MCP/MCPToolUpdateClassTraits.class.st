"
Focused tool that replaces the instance-side trait composition of one class.
"
Class {
	#name : 'MCPToolUpdateClassTraits',
	#superclass : 'MCPToolClassOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolUpdateClassTraits class >> toolName [

	^ 'class_traits_update'
]

{ #category : 'private - operations' }
MCPToolUpdateClassTraits >> classOperationSpec [

	^ {
		  (#title -> 'Update Class Traits').
		  (#description
		   -> 'Replace the instance-side trait composition of one class.').
		  (#inputProperties -> {
			   self classNameSchemaProperty.
			   self traitsSchemaProperty.
			   self forceSchemaProperty }).
		  (#requiredProperties -> #( 'className' 'traits' )) } asDictionary
]
