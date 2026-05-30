"
Focused tool that replaces the shared pools referenced by one class.
"
Class {
	#name : 'MCPToolUpdateClassSharedPools',
	#superclass : 'MCPToolClassOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolUpdateClassSharedPools class >> toolName [

	^ 'class_shared_pools_update'
]

{ #category : 'private - operations' }
MCPToolUpdateClassSharedPools >> classOperationSpec [

	^ {
		  (#title -> 'Update Class Shared Pools').
		  (#description
		   -> 'Replace the shared pools referenced by one class.').
		  (#inputProperties -> {
			   self classNameSchemaProperty.
			   self sharedPoolsSchemaProperty.
			   self forceSchemaProperty }).
		  (#requiredProperties -> #( 'className' 'sharedPools' )) }
		  asDictionary
]
