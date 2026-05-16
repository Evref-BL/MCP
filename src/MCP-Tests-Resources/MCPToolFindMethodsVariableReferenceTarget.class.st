Class {
	#name : 'MCPToolFindMethodsVariableReferenceTarget',
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
MCPToolFindMethodsVariableReferenceTarget class >> readTrackedClassSlot [

	^ trackedClassSlot
]

{ #category : 'testing' }
MCPToolFindMethodsVariableReferenceTarget class >> writeTrackedClassSlot [

	trackedClassSlot := 'class-slot-value'
]

{ #category : 'testing' }
MCPToolFindMethodsVariableReferenceTarget >> readTrackedSlot [

	^ trackedSlot
]

{ #category : 'testing' }
MCPToolFindMethodsVariableReferenceTarget >> writeTrackedSlot [

	trackedSlot := 'slot-value'
]
