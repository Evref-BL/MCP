"
Notification fixture with an observable default action.
"
Class {
	#name : 'MCPToolDefaultActionNotification',
	#superclass : 'Notification',
	#category : 'MCP-Tests-Resources-Fixtures',
	#package : 'MCP-Tests-Resources',
	#tag : 'Fixtures'
}

{ #category : 'handling' }
MCPToolDefaultActionNotification >> defaultAction [

	^ #mcpDefaultAction
]
