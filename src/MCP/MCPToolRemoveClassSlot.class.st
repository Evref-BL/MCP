"
Focused tool that removes one instance-side or class-side slot from a class.
"
Class {
	#name : 'MCPToolRemoveClassSlot',
	#superclass : 'MCPToolClassOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolRemoveClassSlot class >> toolName [

	^ 'class_slot_remove'
]

{ #category : 'private - operations' }
MCPToolRemoveClassSlot >> classOperationSpec [

	^ {
		  (#title -> 'Remove Class Slot').
		  (#description
		   -> 'Remove one instance-side or class-side slot from a class.').
		  (#fixedArguments -> { (#slotAction -> 'remove') } asDictionary).
		  (#inputProperties -> {
			   self classNameSchemaProperty.
			   self slotNameSchemaProperty.
			   self classSideSlotSchemaProperty.
			   self forceSchemaProperty }).
		  (#requiredProperties -> #( 'className' 'slotName' )) }
		  asDictionary
]
