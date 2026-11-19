"
What the presenters that display an MCP server share: the names and icons of its state, the buttons that start, stop and refresh it, and the reading of a port typed into a field.

Running and listening are two facts, not one: a server whose socket died is still running, and a socket that outlived its server is still holding the port. Both are worth saying out loud, since the second is what makes a port look mysteriously taken.
"
Trait {
	#name : 'TMCPServerStatusDisplay',
	#category : 'MCP-UI',
	#package : 'MCP-UI'
}

{ #category : 'server port' }
TMCPServerStatusDisplay >> invalidPortText [

	^ 'Enter a port between 0 and 65535, or 0 for a free one.'
]

{ #category : 'server actions' }
TMCPServerStatusDisplay >> newRefreshButton [

	^ self newButton
		  label: 'Refresh';
		  icon: (self iconNamed: #refreshCircling);
		  yourself
]

{ #category : 'server actions' }
TMCPServerStatusDisplay >> newStartButton [

	^ self newButton
		  label: 'Start';
		  icon: (self iconNamed: #go);
		  yourself
]

{ #category : 'server actions' }
TMCPServerStatusDisplay >> newStopButton [

	^ self newButton
		  label: 'Stop';
		  icon: self serverStopIcon;
		  yourself
]

{ #category : 'server port' }
TMCPServerStatusDisplay >> portFrom: aString [
	"The port a field asks for, or nil when its text is not one. Only digits are read, since asInteger takes the first run of digits wherever it is. 0 asks for a free port."

	| text |
	text := aString asString trimBoth.
	(text isNotEmpty and: [ (text allSatisfy: [ :each | each isDigit ]) and: [ text asInteger <= 65535 ] ]) ifFalse: [ ^ nil ].
	^ text asInteger
]

{ #category : 'server status' }
TMCPServerStatusDisplay >> serverStatusIconNameFor: anMCP [

	^ self serverStatusIconNameForRunning: anMCP isRunning listening: anMCP isListening
]

{ #category : 'server status' }
TMCPServerStatusDisplay >> serverStatusIconNameForRunning: isRunning listening: isListening [

	isRunning ifFalse: [
			^ isListening
				  ifTrue: [ #testRed ]
				  ifFalse: [ #testNotRun ] ].
	^ isListening
		  ifTrue: [ #testGreen ]
		  ifFalse: [ #testRed ]
]

{ #category : 'server status' }
TMCPServerStatusDisplay >> serverStatusLabelForRunning: isRunning listening: isListening [

	^ 'Status: ' , (self serverStatusValueForRunning: isRunning listening: isListening)
]

{ #category : 'server status' }
TMCPServerStatusDisplay >> serverStatusValueFor: anMCP [

	^ self serverStatusValueForRunning: anMCP isRunning listening: anMCP isListening
]

{ #category : 'server status' }
TMCPServerStatusDisplay >> serverStatusValueForRunning: isRunning listening: isListening [

	isRunning ifFalse: [
			^ isListening
				  ifTrue: [ 'stopped, socket still listening' ]
				  ifFalse: [ 'stopped' ] ].
	^ isListening
		  ifTrue: [ 'running' ]
		  ifFalse: [ 'running, socket not listening' ]
]

{ #category : 'server status' }
TMCPServerStatusDisplay >> serverStopIcon [
	"The icon set has no stop square, only a cross that reads as delete, so it is drawn."

	| form |
	form := Form extent: 16 @ 16 depth: 32.
	form fillColor: Color transparent.
	form getCanvas fillRectangle: (3 @ 3 extent: 10 @ 10) color: (Color r: 0.85 g: 0.25 b: 0.2).
	^ form
]
