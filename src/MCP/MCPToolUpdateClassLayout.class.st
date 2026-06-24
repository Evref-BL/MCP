"
Tool that replaces the layout class used by one class.
"
Class {
	#name : 'MCPToolUpdateClassLayout',
	#superclass : 'MCPToolClassMutation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolUpdateClassLayout class >> toolName [

	^ 'class_layout_update'
]

{ #category : 'private - specs' }
MCPToolUpdateClassLayout >> classToolSpec [

	^ {
		  (#title -> 'Update Class Layout').
		  (#description -> 'Replace the layout class used by one class.').
		  (#inputProperties -> {
			   self classNameSchemaProperty.
			   self layoutSchemaProperty.
			   self forceSchemaProperty }).
		  (#requiredProperties -> #( 'className' 'layout' )) } asDictionary
]
