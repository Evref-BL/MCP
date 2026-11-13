Extension { #name : 'MCPReplaceClassDefinitionCommand' }

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPReplaceClassDefinitionCommand >> replaceDefinitionOn: aClass [
	"Before Pharo 12, the installer does not start from the class it updates."

	^ ShiftClassInstaller new
		  oldClass: aClass;
		  make: [ :builder |
			  builder fillFor: aClass.
			  self replaceSlots ifTrue: [ builder slots: self slots ].
			  self replaceClassSlots ifTrue: [ builder classSlots: self classSlots ] ]
]
