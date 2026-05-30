"
Focused tool that replaces the class variables of one class.
"
Class {
	#name : 'MCPToolUpdateClassSharedVariables',
	#superclass : 'MCPToolClassOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolUpdateClassSharedVariables class >> toolName [

	^ 'class_shared_variables_update'
]

{ #category : 'private - operations' }
MCPToolUpdateClassSharedVariables >> classOperationSpec [

	^ {
		  (#title -> 'Update Class Shared Variables').
		  (#description -> 'Replace the class variables of one class.').
		  (#inputProperties -> {
			   self classNameSchemaProperty.
			   self sharedVariablesSchemaProperty.
			   self forceSchemaProperty }).
		  (#requiredProperties -> #( 'className' 'sharedVariables' )) }
		  asDictionary
]
