Extension { #name : 'MCPReplaceClassSharedPoolsCommand' }

{ #category : '*MCP-IDE-Compatibility-From12' }
MCPReplaceClassSharedPoolsCommand >> replaceSharedPoolsOn: aClass [

	^ ShiftClassInstaller update: aClass to: [ :builder | builder sharedPools: self resolvedSharedPools ]
]
