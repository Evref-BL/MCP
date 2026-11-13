Extension { #name : 'MCPReplaceClassSharedPoolsCommand' }

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPReplaceClassSharedPoolsCommand >> replaceSharedPoolsOn: aClass [
	"Before Pharo 12, the installer does not start from the class it updates, and the builder takes the names of the pools as one string."

	^ ShiftClassInstaller new
		  oldClass: aClass;
		  make: [ :builder |
			  builder fillFor: aClass.
			  builder sharedPools: (' ' join: (self resolvedSharedPools collect: [ :pool | pool name ])) ]
]
