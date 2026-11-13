Extension { #name : 'MCPReplaceClassSharedVariablesCommand' }

{ #category : '*MCP-IDE-Compatibility-From12' }
MCPReplaceClassSharedVariablesCommand >> replaceSharedVariablesOn: aClass [

	^ ShiftClassInstaller update: aClass to: [ :builder | builder sharedVariables: self sharedVariableNames ]
]
