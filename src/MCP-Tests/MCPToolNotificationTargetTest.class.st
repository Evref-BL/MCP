"
SUnit fixture for notifications emitted by code under test.
"
Class {
	#name : 'MCPToolNotificationTargetTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'tests' }
MCPToolNotificationTargetTest >> testSignalsNotification [

	self assert: MCPToolDefaultActionNotification signal equals: #mcpDefaultAction
]
