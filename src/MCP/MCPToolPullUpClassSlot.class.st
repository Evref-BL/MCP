"
Focused tool that pulls one instance-side or class-side slot up to a superclass.
"
Class {
	#name : 'MCPToolPullUpClassSlot',
	#superclass : 'MCPToolClassOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolPullUpClassSlot class >> toolName [

	^ 'class_slot_pull_up'
]

{ #category : 'private - operations' }
MCPToolPullUpClassSlot >> classOperationSpec [

	^ {
		  (#title -> 'Pull Up Class Slot').
		  (#description
		   ->
		   'Pull one instance-side or class-side slot up to a superclass.').
		  (#fixedArguments -> { (#slotAction -> 'pullUp') } asDictionary).
		  (#inputProperties -> {
			   self classNameSchemaProperty.
			   self slotNameSchemaProperty.
			   self classSideSlotSchemaProperty.
			   self forceSchemaProperty }).
		  (#requiredProperties -> #( 'className' 'slotName' )) }
		  asDictionary
]
