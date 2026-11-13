Extension { #name : 'MCPReparentClassCommand' }

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPReparentClassCommand >> builderForReparenting: aClass toSuperclass: aSuperclass [
	"Before Pharo 12, a builder fills itself from a class with fillFor:, and only an installer gives a new one the environment to build in."

	^ ShiftClassBuilder new
		  buildEnvironment: ShSmalltalkGlobalsEnvironment new;
		  fillFor: aClass;
		  superclass: aSuperclass;
		  yourself
]
