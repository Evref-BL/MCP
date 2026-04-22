Class {
	#name : 'MCPToolReferencesVariableTestTarget',
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
MCPToolReferencesVariableTestTarget class >> readTrackedClassSlot [

	^ trackedClassSlot
]

{ #category : 'testing' }
MCPToolReferencesVariableTestTarget class >> writeTrackedClassSlot [

	trackedClassSlot := 'class-slot-value'
]

{ #category : 'testing' }
MCPToolReferencesVariableTestTarget >> readTrackedSlot [

	^ trackedSlot
]

{ #category : 'testing' }
MCPToolReferencesVariableTestTarget >> writeTrackedSlot [

	trackedSlot := 'slot-value'
]
