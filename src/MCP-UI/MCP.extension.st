Extension { #name : 'MCP' }

{ #category : '*MCP-UI' }
MCP >> inspectionDashboard: aBuilder [

	<inspectorPresentationOrder: 0 title: 'Dashboard'>
	^ MCPDashboardPresenter on: self
]

{ #category : '*MCP-UI' }
MCP >> inspectionObservability: aBuilder [

	<inspectorPresentationOrder: 1 title: 'Observability'>
	^ MCPObservabilityPresenter on: self
]

{ #category : '*MCP-UI' }
MCP class >> inspectionServers: aBuilder [

	<inspectorPresentationOrder: 0 title: 'Servers'>
	^ MCPServersPresenter new
]

{ #category : '*MCP-UI' }
MCP class >> openToolCatalog [

	<script>
	^ MCPToolsCatalogPresenter open
]
