Extension { #name : 'MCPReplaceClassLayoutCommand' }

{ #category : '*MCP-IDE-Compatibility-From12' }
MCPReplaceClassLayoutCommand >> replaceLayoutOn: aClass [

	^ ShiftClassInstaller update: aClass to: [ :builder | builder layout: (self resolvedLayoutClassNamed: self layout) ]
]
