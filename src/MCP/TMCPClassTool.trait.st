"
Shared class-domain helper behavior for MCP tools.

Kept as a trait so class tools can combine it with query or mutation behavior.
"
Trait {
	#name : 'TMCPClassTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - classes' }
TMCPClassTool >> resolvedClassNamed: className [

	^ MCPImageLookup classNamed: className
]

{ #category : 'private - classes' }
TMCPClassTool >> sortedClassesByName: someClasses [

	^ (someClasses asSortedCollection: [ :left :right |
		   left name <= right name ]) asArray
]
