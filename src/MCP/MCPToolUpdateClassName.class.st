"
Tool that renames one class through the Pharo refactoring engine.
"
Class {
	#name : 'MCPToolUpdateClassName',
	#superclass : 'MCPToolClassMutation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolUpdateClassName class >> toolName [

	^ 'class_name_update'
]

{ #category : 'private - specs' }
MCPToolUpdateClassName >> classToolSpec [

	^ {
		  (#title -> 'Update Class Name').
		  (#description -> 'Rename one class through the Pharo refactoring engine across the whole image.').
		  (#inputProperties -> {
			   self renameClassNameSchemaProperty.
			   self renameNewClassNameSchemaProperty }).
		  (#requiredProperties -> #( 'name' 'newName' )) } asDictionary
]

{ #category : 'private - schema' }
MCPToolUpdateClassName >> renameClassNameSchemaProperty [

	^ self schemaPropertyNamed: 'name' type: 'string' description: 'Class to rename.'
]

{ #category : 'private - schema' }
MCPToolUpdateClassName >> renameNewClassNameSchemaProperty [

	^ self schemaPropertyNamed: 'newName' type: 'string' description: 'New class name.'
]
