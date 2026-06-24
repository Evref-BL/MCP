"
Tool that moves or recategorizes one class package/tag assignment.
"
Class {
	#name : 'MCPToolUpdateClassPackage',
	#superclass : 'MCPToolClassMutation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolUpdateClassPackage class >> toolName [

	^ 'class_package_update'
]

{ #category : 'private - specs' }
MCPToolUpdateClassPackage >> classToolSpec [

	^ {
		  (#title -> 'Update Class Package').
		  (#description
		   ->
		   'Move one class to a package and/or recategorize it under a package tag. Omit packageName when only changing tag inside the current package.').
		  (#inputProperties -> {
			   self classNameSchemaProperty.
			   self packageNameSchemaProperty.
			   self tagSchemaProperty.
			   self forceSchemaProperty }).
		  (#requiredProperties -> #( 'className' )).
		  (#atLeastOneProperties -> #( 'packageName' 'tag' )) } asDictionary
]
