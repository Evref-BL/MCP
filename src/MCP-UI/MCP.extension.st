Extension { #name : 'MCP' }

{ #category : '*MCP-UI' }
MCP >> inspectionDashboard: aBuilder [

	<inspectorPresentationOrder: 0 title: 'Dashboard'>
	^ MCPDashboardPresenter on: self
]

{ #category : '*MCP-UI' }
MCP >> inspectionToolCatalog: aBuilder [

	<inspectorPresentationOrder: 1 title: 'Tool Catalog'>
	^ MCPToolsCatalogPresenter new
]

{ #category : '*MCP-UI' }
MCP class >> openToolCatalog [

	<script>
	^ MCPToolsCatalogPresenter open
]
