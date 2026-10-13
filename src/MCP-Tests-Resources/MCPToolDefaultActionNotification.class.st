"
Notification fixture with an observable default action.
"
Class {
	#name : 'MCPToolDefaultActionNotification',
	#superclass : 'Notification',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'handling' }
MCPToolDefaultActionNotification >> defaultAction [

	^ #mcpDefaultAction
]
