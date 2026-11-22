"
Notification fixture that the boundary around a tool call refuses to resume, as it refuses RBRefactoringWarning, with the observable default action of its superclass.
"
Class {
	#name : 'MCPToolRefusedNotification',
	#superclass : 'MCPToolDefaultActionNotification',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'handling' }
MCPToolRefusedNotification >> mcpResumesAtToolBoundary [

	^ false
]
