"
Notification fixture with an observable default action.
"
Class {
	#name : 'MCPToolDefaultActionNotification',
	#superclass : 'Notification',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'handling' }
MCPToolDefaultActionNotification >> defaultAction [

	^ #mcpDefaultAction
]
