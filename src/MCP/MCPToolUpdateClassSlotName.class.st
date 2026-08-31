"
Tool that renames one instance-side or class-side slot in a class.
"
Class {
	#name : 'MCPToolUpdateClassSlotName',
	#superclass : 'MCPToolClassMutation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolUpdateClassSlotName class >> toolName [

	^ 'class_slot_name_update'
]

{ #category : 'private - specs' }
MCPToolUpdateClassSlotName >> classToolSpec [

	^ {
		  (#title -> 'Update Class Slot Name').
		  (#description -> 'Rename one instance-side or class-side slot in a class.').
		  (#fixedArguments -> { (#slotAction -> 'rename') } asDictionary).
		  (#inputProperties -> {
			   self classNameSchemaProperty.
			   self slotNameSchemaProperty.
			   self newSlotNameSchemaProperty.
			   self classSideSlotSchemaProperty }).
		  (#requiredProperties -> #( 'name' 'slotName' 'newSlotName' )) } asDictionary
]
