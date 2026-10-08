"
Tool that removes one instance-side or class-side slot from a class.
"
Class {
	#name : 'MCPToolRemoveClassSlot',
	#superclass : 'MCPToolClassMutation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolRemoveClassSlot class >> toolName [

	^ 'class_slot_remove'
]

{ #category : 'private - specs' }
MCPToolRemoveClassSlot >> classToolSpec [

	^ {
		  (#title -> 'Remove Class Slot').
		  (#description -> 'Remove one instance-side or class-side slot from a class.').
		  (#fixedArguments -> { (#slotAction -> 'remove') } asDictionary).
		  (#inputProperties -> {
			   self classNameSchemaProperty.
			   self slotNameSchemaProperty.
			   self classSideSlotSchemaProperty.
			   self forceSchemaProperty }).
		  (#requiredProperties -> #( 'name' 'slotName' )) } asDictionary
]
