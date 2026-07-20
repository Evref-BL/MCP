"
Tool that replaces the instance-side trait composition of one class.
"
Class {
	#name : 'MCPToolUpdateClassTraits',
	#superclass : 'MCPToolClassMutation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolUpdateClassTraits class >> toolName [

	^ 'class_traits_update'
]

{ #category : 'metadata' }
MCPToolUpdateClassTraits >> additionalKeywords [

	^ super additionalKeywords , #( 'trait' 'composition' 'definition' )
]

{ #category : 'private - specs' }
MCPToolUpdateClassTraits >> classToolSpec [

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
