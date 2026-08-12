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
		  (#description -> 'Rename one class through the Pharo refactoring engine.').
		  (#inputProperties -> {
			   self classNameSchemaProperty.
			   self newClassNameSchemaProperty.
			   self forceSchemaProperty.
			   self refactoringScopePackageNamesSchemaProperty.
			   self refactoringScopeClassNamesSchemaProperty.
			   self refactoringScopeHierarchyClassNamesSchemaProperty }).
		  (#requiredProperties -> #( 'className' 'newClassName' )) } asDictionary
]
