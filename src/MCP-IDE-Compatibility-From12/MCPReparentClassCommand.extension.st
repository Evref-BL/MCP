Extension { #name : 'MCPReparentClassCommand' }

{ #category : '*MCP-IDE-Compatibility-From12' }
MCPReparentClassCommand >> builderForReparenting: aClass toSuperclass: aSuperclass [

	| builder |
	builder := ShiftClassBuilder new.
	builder fillInstanceSideFromClass: aClass.
	builder fillClassSideFromEnvironment: aClass environment.
	builder name: aClass name.
	builder superclass: aSuperclass.
	^ builder
]
