"
Focused tool that adds one instance-side or class-side slot to a class.
"
Class {
	#name : 'MCPToolAddClassSlot',
	#superclass : 'MCPToolClassOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolAddClassSlot class >> toolName [

	^ 'class_slot_add'
]

{ #category : 'private - operations' }
MCPToolAddClassSlot >> classOperationSpec [

	^ {
		  (#title -> 'Add Class Slot').
		  (#description
		   -> 'Add one instance-side or class-side slot to a class.').
		  (#fixedArguments -> { (#slotAction -> 'add') } asDictionary).
		  (#inputProperties -> {
			   self classNameSchemaProperty.
			   self slotNameSchemaProperty.
			   self classSideSlotSchemaProperty.
			   self forceSchemaProperty }).
		  (#requiredProperties -> #( 'className' 'slotName' )) }
		  asDictionary
]
