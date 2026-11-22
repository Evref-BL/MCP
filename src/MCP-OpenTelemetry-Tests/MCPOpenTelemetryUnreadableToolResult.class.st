"
An error result whose structured content cannot be read, as a tool written elsewhere might answer, so a test can see that recording such an answer still ends the call's span.
"
Class {
	#name : 'MCPOpenTelemetryUnreadableToolResult',
	#superclass : 'MCPStructureErrorToolResult',
	#category : 'MCP-OpenTelemetry-Tests',
	#package : 'MCP-OpenTelemetry-Tests'
}

{ #category : 'accessing' }
MCPOpenTelemetryUnreadableToolResult >> structuredContent [

	^ self error: 'This answer cannot be read.'
]
