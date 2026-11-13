Extension { #name : 'MCPReplaceClassDefinitionCommand' }

{ #category : '*MCP-IDE-Compatibility-From12' }
MCPReplaceClassDefinitionCommand >> replaceDefinitionOn: aClass [

	^ ShiftClassInstaller update: aClass to: [ :builder |
			  self replaceSlots ifTrue: [ builder slots: self slots ].
			  self replaceClassSlots ifTrue: [ builder classSlots: self classSlots ] ]
]
