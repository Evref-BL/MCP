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

{ #category : 'metadata' }
MCPToolUpdateClassLayout >> additionalKeywords [

	^ super additionalKeywords , #( 'layout' 'shape' 'format' 'fixed' 'variable' 'weak' 'immediate' 'word' 'byte' )
]

{ #category : 'private - specs' }
MCPToolUpdateClassLayout >> classToolSpec [

	^ {
		  (#title -> 'Update Class Layout').
		  (#description -> 'Replace the layout class used by one class.').
		  (#inputProperties -> {
			   (self schemaPropertyNamed: 'name' type: 'string' description: 'Class name.').
			   self layoutSchemaProperty }).
		  (#requiredProperties -> #( 'name' 'layout' )) } asDictionary
]
