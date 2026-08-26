"
Tool that sets or clears one class comment.
"
Class {
	#name : 'MCPToolUpdateClassComment',
	#superclass : 'MCPToolClassMutation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolUpdateClassComment class >> toolName [

	^ 'class_comment_update'
]

{ #category : 'private - specs' }
MCPToolUpdateClassComment >> classToolSpec [

	^ {
		  (#title -> 'Update Class Comment').
		  (#description -> 'Set or clear one class comment.').
		  (#inputProperties -> {
			   self classNameSchemaProperty.
			   self commentSchemaProperty }).
		  (#requiredProperties -> #( 'className' 'comment' )) } asDictionary
]
