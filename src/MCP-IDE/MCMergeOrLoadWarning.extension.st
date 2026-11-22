Extension { #name : 'MCMergeOrLoadWarning' }

{ #category : '*MCP-IDE' }
MCMergeOrLoadWarning >> mcpDefaultAction [
	"Monticello asks a person whether to load over the image's unsaved changes, merge them, or cancel, and a tool call has none: Pharo 14 opens its dialog even in a headless image, and the call waits out its time limit. Nil cancels, which is what Pharo 15 comes to with nobody to ask, since it fails like any warning nobody handles, and what an unhandled warning comes to under a tool. The image keeps its changes."

	^ nil
]

{ #category : '*MCP-IDE' }
MCMergeOrLoadWarning >> mcpResumedDescription [
	"My text announces what loading would lose, and resumed by a tool I cancel the load instead."

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: self class name;
				  nextPutAll: ': Cancelled a load that would lose the image''s unsaved changes to ';
				  nextPutAll: (', ' join: (self versions collect: [ :each | each package name ] as: Array) sort);
				  nextPutAll: '. To load over them, handle MCMergeOrLoadWarning with load.' ]
]
