"
Tool that pushes one instance-side or class-side slot down to subclasses.
"
Class {
	#name : 'MCPToolPushDownClassSlot',
	#superclass : 'MCPToolClassMutation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolPushDownClassSlot class >> toolName [

	^ 'class_slot_push_down'
]

{ #category : 'private - specs' }
MCPToolPushDownClassSlot >> classToolSpec [

	^ {
		  (#title -> 'Push Down Class Slot').
		  (#description
		   ->
		   'Push one instance-side or class-side slot down to subclasses.').
		  (#fixedArguments -> { (#slotAction -> 'pushDown') } asDictionary).
		  (#inputProperties -> {
			   self classNameSchemaProperty.
			   self slotNameSchemaProperty.
			   self classSideSlotSchemaProperty.
			   self forceSchemaProperty }).
		  (#requiredProperties -> #( 'className' 'slotName' )) }
		  asDictionary
]
