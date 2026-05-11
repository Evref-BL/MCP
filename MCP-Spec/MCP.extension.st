Extension { #name : 'MCP' }

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

{ #category : '*MCP-Spec' }
MCP class >> openToolCatalog [

	<script>
	^ MCPToolsCatalogPresenter open
]
