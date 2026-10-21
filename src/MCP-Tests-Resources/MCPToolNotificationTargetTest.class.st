"
SUnit fixture for notifications emitted by code under test.
"
Class {
	#name : 'MCPToolNotificationTargetTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'tests' }
MCPToolNotificationTargetTest >> testSignalsNotification [

	self assert: MCPToolNestedNotification signal equals: 'nested-mcpDefaultAction'
]
