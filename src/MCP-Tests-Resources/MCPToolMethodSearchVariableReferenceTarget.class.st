"
Fixture class that defines variables used by variable-reference search tests.
"
Class {
	#name : 'MCPToolMethodSearchVariableReferenceTarget',
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
MCPToolMethodSearchVariableReferenceTarget class >> readTrackedClassSlot [

	^ trackedClassSlot
]

{ #category : 'testing' }
MCPToolMethodSearchVariableReferenceTarget class >> writeTrackedClassSlot [

	trackedClassSlot := 'class-slot-value'
]

{ #category : 'testing' }
MCPToolMethodSearchVariableReferenceTarget >> readTrackedSlot [

	^ trackedSlot
]

{ #category : 'testing' }
MCPToolMethodSearchVariableReferenceTarget >> writeTrackedSlot [

	trackedSlot := 'slot-value'
]
