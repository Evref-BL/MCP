Extension { #name : 'MCPReparentClassCommand' }

{ #category : '*MCP-IDE-Compatibility-From12' }
MCPReparentClassCommand >> builderForReparenting: aClass toSuperclass: aSuperclass [
	"fillFor: gives the builder copies of the class's slots: the new class numbers its slots after its superclass's, and the class whose instances Pharo migrates must keep its own numbers."

	^ ShiftClassBuilder new
		  fillFor: aClass;
		  superclass: aSuperclass;
		  yourself
]
