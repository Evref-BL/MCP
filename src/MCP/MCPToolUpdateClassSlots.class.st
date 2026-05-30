"
Focused tool that replaces the instance-side and/or class-side slot definition of one class.
"
Class {
	#name : 'MCPToolUpdateClassSlots',
	#superclass : 'MCPToolClassOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolUpdateClassSlots class >> toolName [

	^ 'class_slots_update'
]

{ #category : 'private - operations' }
MCPToolUpdateClassSlots >> classOperationSpec [

	^ {
		  (#title -> 'Update Class Slots').
		  (#description
		   ->
		   'Replace the instance-side and/or class-side slot definition of one class.').
		  (#inputProperties -> {
			   self classNameSchemaProperty.
			   self slotsSchemaProperty.
			   self classSlotsSchemaProperty.
			   self forceSchemaProperty }).
		  (#requiredProperties -> #( 'className' )).
		  (#atLeastOneProperties -> #( 'slots' 'classSlots' )) }
		  asDictionary
]
