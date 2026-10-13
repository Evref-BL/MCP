"
SUnit fixture for notifications emitted by code under test.
"
Class {
	#name : 'MCPToolNotificationTargetTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Resources-Fixtures',
	#package : 'MCP-Tests-Resources',
	#tag : 'Fixtures'
}

{ #category : 'tests' }
MCPToolNotificationTargetTest >> testSignalsNotification [

	self assert: MCPToolDefaultActionNotification signal equals: #mcpDefaultAction
]
