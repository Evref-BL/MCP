Class {
	#name : 'MCPToolSendersVariableTestTarget',
	#superclass : 'Object',
	#instVars : [
		'trackedSlot'
	],
	#classInstVars : [
		'trackedClassSlot'
	],
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'testing' }
MCPToolSendersVariableTestTarget class >> readTrackedClassSlot [

	^ trackedClassSlot
]

{ #category : 'testing' }
MCPToolSendersVariableTestTarget class >> writeTrackedClassSlot [

	trackedClassSlot := 'class-slot-value'
]

{ #category : 'testing' }
MCPToolSendersVariableTestTarget >> readTrackedSlot [

	^ trackedSlot
]

{ #category : 'testing' }
MCPToolSendersVariableTestTarget >> writeTrackedSlot [

	trackedSlot := 'slot-value'
]
