Extension { #name : 'MCPReparentClassCommand' }

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPReparentClassCommand >> builderForReparenting: aClass toSuperclass: aSuperclass [

	^ ShiftClassBuilder new
		  fillFor: aClass;
		  superclass: aSuperclass;
		  yourself
]
