"
Shared user-interface vocabulary for the tools that look at the running image.

It resolves what a caller named into the morph to capture or describe: the world when nothing is named, and otherwise the one open window carrying that title.
"
Trait {
	#name : 'TMCPUserInterfaceTool',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'private - user interface' }
TMCPUserInterfaceTool >> openWindowTitles [

	^ self openWindows collect: [ :each | self titleOf: each ] as: Array
]

{ #category : 'private - user interface' }
TMCPUserInterfaceTool >> openWindows [
	"The windows a caller can name, in the order the world holds them."

	^ self currentWorld
		  ifNil: [ #(  ) ]
		  ifNotNil: [ :world | (world submorphs select: [ :each | each isKindOf: SystemWindow ]) asArray ]
]

{ #category : 'private - user interface' }
TMCPUserInterfaceTool >> targetMorphNamed: aTitle [
	"The morph the caller named: the world when they named nothing, and otherwise the one open window carrying that title."

	| matches |
	aTitle ifNil: [
			^ self currentWorld ifNil: [
				  MCPCommandError
					  signalErrorCode: #NoMorphicWorld
					  message: 'No Morphic world is available to look at.'
					  details: Dictionary new ] ].
	matches := self openWindows select: [ :each | (self titleOf: each) = aTitle ].
	matches size = 1 ifTrue: [ ^ matches first ].
	^ MCPCommandError
		  signalErrorCode: (matches isEmpty
				   ifTrue: [ #WindowNotFound ]
				   ifFalse: [ #AmbiguousWindow ])
		  message: (matches isEmpty
				   ifTrue: [ String streamContents: [ :stream | stream << 'There is no open window titled ' << aTitle << '.' ] ]
				   ifFalse: [
				   String streamContents: [ :stream | stream << matches size printString << ' open windows are titled ' << aTitle << '.' ] ])
		  details: {
				  (#window -> aTitle).
				  (#open -> self openWindowTitles) } asDictionary
]

{ #category : 'private - user interface' }
TMCPUserInterfaceTool >> titleOf: aWindow [
	"What a window is called. Its label is the one name every window answers: #title is understood from StandardWindow down, and a plain SystemWindow does not answer it."

	^ aWindow label asString
]

{ #category : 'private - user interface' }
TMCPUserInterfaceTool >> windowSchemaProperty [

	^ self schemaPropertyNamed: 'window' type: 'string' description: 'Title of an open window. Omit it for the whole world.'
]
