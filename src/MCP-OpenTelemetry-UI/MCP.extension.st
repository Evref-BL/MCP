Extension { #name : 'MCP' }

{ #category : '*MCP-OpenTelemetry-UI' }
MCP >> inspectionCallGraph: aBuilder [

	<inspectorPresentationOrder: 2 title: 'Call graph'>
	^ MCPCallGraphPresenter on: self
]
