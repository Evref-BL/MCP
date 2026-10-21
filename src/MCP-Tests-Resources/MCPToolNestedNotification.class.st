"
Notification fixture whose default action signals another notification, the way Deprecation>>defaultAction does when it logs.
"
Class {
	#name : 'MCPToolNestedNotification',
	#superclass : 'Notification',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'handling' }
MCPToolNestedNotification >> defaultAction [

	^ 'nested-' , MCPToolDefaultActionNotification signal
]
