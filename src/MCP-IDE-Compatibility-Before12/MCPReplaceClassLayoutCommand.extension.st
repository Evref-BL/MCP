Extension { #name : 'MCPReplaceClassLayoutCommand' }

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPReplaceClassLayoutCommand >> replaceLayoutOn: aClass [
	"Before Pharo 12, the installer does not start from the class it updates, and the builder takes the layout with layoutClass:."

	^ ShiftClassInstaller new
		  oldClass: aClass;
		  make: [ :builder |
			  builder fillFor: aClass.
			  builder layoutClass: (self resolvedLayoutClassNamed: self layout) ]
]
