"
Tool that replaces the class variables of one class.
"
Class {
	#name : 'MCPToolUpdateClassSharedVariables',
	#superclass : 'MCPToolClassMutation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolUpdateClassSharedVariables class >> toolName [

	^ 'class_shared_variables_update'
]

{ #category : 'metadata' }
MCPToolUpdateClassSharedVariables >> additionalKeywords [

	^ super additionalKeywords , #( 'variable' 'shared' 'classvar' 'binding' )
]

{ #category : 'private - specs' }
MCPToolUpdateClassSharedVariables >> classToolSpec [

	^ {
		  (#title -> 'Update Class Shared Variables').
		  (#description -> 'Replace the class variables of one class.').
		  (#inputProperties -> {
			   (self schemaPropertyNamed: 'name' type: 'string' description: 'Class name.').
			   self sharedVariablesSchemaProperty }).
		  (#requiredProperties -> #( 'name' 'sharedVariables' )) } asDictionary
]
