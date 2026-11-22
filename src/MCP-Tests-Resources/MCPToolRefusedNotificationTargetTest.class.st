"
SUnit fixture for a notification that code under test signals and the boundary around a tool call refuses to resume: one test leaves it to its default action, the other expects it.
"
Class {
	#name : 'MCPToolRefusedNotificationTargetTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'tests' }
MCPToolRefusedNotificationTargetTest >> testGetsItsDefaultAction [

	self assert: MCPToolRefusedNotification signal equals: #mcpDefaultAction
]

{ #category : 'tests' }
MCPToolRefusedNotificationTargetTest >> testSeesItWhenItExpectsIt [

	self should: [ MCPToolRefusedNotification signal ] raise: MCPToolRefusedNotification
]
