"
Focused tool that replaces the layout class used by one class.
"
Class {
	#name : 'MCPToolUpdateClassLayout',
	#superclass : 'MCPToolClassOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolUpdateClassLayout class >> toolName [

	^ 'class_layout_update'
]

{ #category : 'private - operations' }
MCPToolUpdateClassLayout >> classOperationSpec [

	^ {
		  (#title -> 'Update Class Layout').
		  (#description -> 'Replace the layout class used by one class.').
		  (#inputProperties -> {
			   self classNameSchemaProperty.
			   self layoutSchemaProperty.
			   self forceSchemaProperty }).
		  (#requiredProperties -> #( 'className' 'layout' )) } asDictionary
]
