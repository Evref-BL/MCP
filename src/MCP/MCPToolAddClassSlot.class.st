"
Tool that adds one instance-side or class-side slot to a class.
"
Class {
	#name : 'MCPToolAddClassSlot',
	#superclass : 'MCPToolClassMutation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolAddClassSlot class >> toolName [

	^ 'class_slot_add'
]

{ #category : 'private - specs' }
MCPToolAddClassSlot >> classToolSpec [

	^ {
		  (#title -> 'Add Class Slot').
		  (#description -> 'Add one instance-side or class-side slot to a class.').
		  (#fixedArguments -> { (#slotAction -> 'add') } asDictionary).
		  (#inputProperties -> {
			   self classNameSchemaProperty.
			   self slotNameSchemaProperty.
			   self classSideSlotSchemaProperty }).
		  (#requiredProperties -> #( 'name' 'slotName' )) } asDictionary
]
