"
Focused tool that renames one instance-side or class-side slot in a class.
"
Class {
	#name : 'MCPToolUpdateClassSlotName',
	#superclass : 'MCPToolClassOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolUpdateClassSlotName class >> toolName [

	^ 'class_slot_name_update'
]

{ #category : 'private - operations' }
MCPToolUpdateClassSlotName >> classOperationSpec [

	^ {
		  (#title -> 'Update Class Slot Name').
		  (#description
		   -> 'Rename one instance-side or class-side slot in a class.').
		  (#fixedArguments -> { (#slotAction -> 'rename') } asDictionary).
		  (#inputProperties -> {
			   self classNameSchemaProperty.
			   self slotNameSchemaProperty.
			   self newSlotNameSchemaProperty.
			   self classSideSlotSchemaProperty.
			   self forceSchemaProperty }).
		  (#requiredProperties -> #( 'className' 'slotName' 'newSlotName' )) }
		  asDictionary
]
