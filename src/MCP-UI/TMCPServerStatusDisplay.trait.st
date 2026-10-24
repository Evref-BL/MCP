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
