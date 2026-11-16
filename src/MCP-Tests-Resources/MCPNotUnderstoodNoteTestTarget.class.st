"
Fixture class whose constructor, withLabel:, is compiled on the instance side on purpose, as one compiled on the wrong side is: its send of new cannot run there. The evaluate, test_run and method_compile tests send it to the class, and see the answer offer to compile it on the class side, as no answer does for its setter, label:.
"
Class {
	#name : 'MCPNotUnderstoodNoteTestTarget',
	#superclass : 'Object',
	#instVars : [
		'label'
	],
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'accessing' }
MCPNotUnderstoodNoteTestTarget >> label: aString [

	label := aString
]

{ #category : 'fixtures' }
MCPNotUnderstoodNoteTestTarget >> withLabel: aString [
	"This is a fixture method; it is compiled on the instance side on purpose, as a constructor compiled on the wrong side, and exercised by MCP evaluate and test_run tests."

	^ self new label: aString
]
