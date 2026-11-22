Extension { #name : 'MCMergeOrLoadWarning' }

{ #category : '*MCP-IDE' }
MCMergeOrLoadWarning >> mcpDefaultAction [
	"Monticello asks a person whether to load over the image's unsaved changes, merge them, or cancel, and a tool call has none: Pharo 14 opens its dialog even in a headless image, and the call waits out its time limit. Nil cancels the step loading those packages, which is what Pharo 15 comes to with nobody to ask, since it fails like any warning nobody handles, and what an unhandled warning comes to under a tool. The image keeps its changes."

	^ nil
]

{ #category : '*MCP-IDE' }
MCMergeOrLoadWarning >> mcpResumedDescription [
	"My text announces what loading would lose, and resumed by a tool I cancel only the step loading the packages I name: the rest of the load goes on, a Metacello load with its other packages."

	| names pronoun |
	names := (self versions collect: [ :each | each package name ] as: Array) sort.
	pronoun := names size = 1
		           ifTrue: [ 'it' ]
		           ifFalse: [ 'them' ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: self class name;
				  nextPutAll: ': Did not load ';
				  nextPutAll: (', ' join: names);
				  nextPutAll: ': loading ';
				  nextPutAll: pronoun;
				  nextPutAll: ' would lose the image''s unsaved changes to ';
				  nextPutAll: pronoun;
				  nextPutAll: '. The rest of the load went on, without the packages loaded together with ';
				  nextPutAll: pronoun;
				  nextPutAll: '. To load over the changes, handle MCMergeOrLoadWarning with load.' ]
]
