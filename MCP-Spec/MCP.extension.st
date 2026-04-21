Extension { #name : 'MCP' }

{ #category : '*MCP-Spec' }
MCP >> configurePort: aPortNumber debugMode: aBoolean [

	| currentPort wasRunning |
	currentPort := self port.
	wasRunning := self isRunning.

	wasRunning ifFalse: [
		self port: aPortNumber.
		self debugMode: aBoolean.
		^ self ].

	currentPort = aPortNumber ifTrue: [
		self debugMode: aBoolean.
		^ self ].

	self stop.

	[
	self port: aPortNumber.
	self debugMode: aBoolean.
	self start ]
		on: Error
		do: [ :error |
			self port: currentPort.
			self debugMode: aBoolean.
			self start.
			error pass ]
]

{ #category : '*MCP-Spec' }
MCP >> dashboardSummary [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Serveur MCP ';
			  nextPutAll: (self isRunning
					   ifTrue: [ 'actif' ]
					   ifFalse: [ 'arrete' ]);
			  nextPutAll: ' sur le port ';
			  print: self port.
		  self isListening ifTrue: [ stream nextPutAll: ' (a l''ecoute)' ] ]
]

{ #category : '*MCP-Spec' }
MCP >> debugMode [

	^ self server messageProcessor debugMode
]

{ #category : '*MCP-Spec' }
MCP >> handlersCount [

	^ self server messageProcessor handlersCount
]

{ #category : '*MCP-Spec' }
MCP >> inspectionDashboard [

	<inspectorPresentationOrder: 0 title: 'Dashboard'>
	^ MCPDashboardPresenter on: self
]

{ #category : '*MCP-Spec' }
MCP >> isListening [

	^ self server isListening
]

{ #category : '*MCP-Spec' }
MCP >> isRunning [

	^ self server isRunning
]

{ #category : '*MCP-Spec' }
MCP >> localUrlString [

	^ self server localUrl asString
]

{ #category : '*MCP-Spec' }
MCP >> openDashboard [

	^ MCPDashboardPresenter openOn: self
]

{ #category : '*MCP-Spec' }
MCP >> port [

	^ self server port
]

{ #category : '*MCP-Spec' }
MCP >> port: aPortNumber [

	self server port: aPortNumber
]

{ #category : '*MCP-Spec' }
MCP >> restart [

	self stop.
	^ self start
]

{ #category : '*MCP-Spec' }
MCP >> sortedTools [

	^ self toolsList values asSortedCollection: [ :left :right |
		  left name <= right name ]
]
