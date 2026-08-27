"
Tool that replaces the instance-side and/or class-side slot definition of one class.
"
Class {
	#name : 'MCPToolUpdateClassSlots',
	#superclass : 'MCPToolClassMutation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolUpdateClassSlots class >> toolName [

	^ 'class_slots_update'
]

{ #category : 'private - specs' }
MCPToolUpdateClassSlots >> classToolSpec [

	^ {
		  (#title -> 'Update Class Slots').
		  (#description -> 'Replace the instance-side and/or class-side slot definition of one class.').
		  (#inputProperties -> {
			   self classNameSchemaProperty.
			   self slotsSchemaProperty.
			   self classSlotsSchemaProperty }).
		  (#requiredProperties -> #( 'className' )).
		  (#atLeastOneProperties -> #( 'slots' 'classSlots' )) } asDictionary
]
