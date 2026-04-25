Extension { #name : 'MCP' }

{ #category : '*MCP-Spec' }
MCP >> inspectionDashboard [

	<inspectorPresentationOrder: 0 title: 'Dashboard'>
	^ MCPDashboardPresenter on: self
]

{ #category : '*MCP-Spec' }
MCP >> openDashboard [

	^ MCPDashboardPresenter openOn: self
]
