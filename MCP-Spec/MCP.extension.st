Extension { #name : 'MCP' }

{ #category : '*MCP-Spec' }
MCP >> dashboardSummary [

	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'Serveur MCP ';
			nextPutAll: (self isRunning ifTrue: [ 'actif' ] ifFalse: [ 'arrete' ]);
			nextPutAll: ' sur le port ';
			print: self port.
		self isListening ifTrue: [ stream nextPutAll: ' (a l''ecoute)' ] ]
]

{ #category : '*MCP-Spec' }
MCP >> inspectionDashboard: aBuilder [

	<inspectorPresentationOrder: 0 title: 'Dashboard'>
	^ MCPDashboardPresenter on: self
]

{ #category : '*MCP-Spec' }
MCP >> inspectionToolCatalog [

	<inspectorPresentationOrder: 1 title: 'Tool Catalog'>
	^ MCPToolsCatalogPresenter new
]
