Extension { #name : 'MCPReplaceClassSharedVariablesCommand' }

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPReplaceClassSharedVariablesCommand >> replaceSharedVariablesOn: aClass [
	"Before Pharo 12, the installer does not start from the class it updates."

	^ ShiftClassInstaller new
		  oldClass: aClass;
		  make: [ :builder |
			  builder fillFor: aClass.
			  builder sharedVariables: self sharedVariableNames ]
]
