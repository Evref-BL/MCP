"
Tool that replaces the shared pools referenced by one class.
"
Class {
	#name : 'MCPToolUpdateClassSharedPools',
	#superclass : 'MCPToolClassMutation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolUpdateClassSharedPools class >> toolName [

	^ 'class_shared_pools_update'
]

{ #category : 'private - specs' }
MCPToolUpdateClassSharedPools >> classToolSpec [

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
