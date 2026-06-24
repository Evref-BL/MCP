"
Tool that replaces the class-side trait composition of one class.
"
Class {
	#name : 'MCPToolUpdateClassSideTraits',
	#superclass : 'MCPToolClassMutation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolUpdateClassSideTraits class >> toolName [

	^ 'class_side_traits_update'
]

{ #category : 'private - specs' }
MCPToolUpdateClassSideTraits >> classToolSpec [

	^ {
		  (#title -> 'Update Class-Side Traits').
		  (#description
		   -> 'Replace the class-side trait composition of one class.').
		  (#inputProperties -> {
			   self classNameSchemaProperty.
			   self classTraitsSchemaProperty.
			   self forceSchemaProperty }).
		  (#requiredProperties -> #( 'className' 'classTraits' )) }
		  asDictionary
]
