"
Names and icons for the state of an MCP server, shared by the presenters that display one.

Running and listening are two facts, not one: a server whose socket died is still running, and a socket that outlived its server is still holding the port. Both are worth saying out loud, since the second is what makes a port look mysteriously taken.
"
Trait {
	#name : 'TMCPServerStatusDisplay',
	#category : 'MCP-UI',
	#package : 'MCP-UI'
}

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
