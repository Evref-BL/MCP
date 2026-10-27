"
Tests the inspector tab that shows what a server recorded about itself.
"
Class {
	#name : 'MCPObservabilityPresenterTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-UI-Tests',
	#package : 'MCP-UI-Tests'
}

{ #category : 'tests' }
MCPObservabilityPresenterTest >> testAutoRefreshIsDisabledByDefault [

	| presenter |
	presenter := MCPObservabilityPresenter new.

	self deny: presenter isAutoRefreshEnabled.
	self deny: presenter isAutoRefreshProcessRunning
]

{ #category : 'tests' }
MCPObservabilityPresenterTest >> testControlRowDoesNotConstrainWidgetWidth [
	"A width constraint makes Spec draw a button or a checkbox without its label, and takes the rest of the row with it."

	| layout |
	layout := MCPObservabilityPresenter new controlsLayout.

	layout children do: [ :child |
		self assert: (layout constraintsFor: child) width isNil description: child label , ' must not be given a width' ]
]

{ #category : 'tests' }
MCPObservabilityPresenterTest >> testControlsStartWithEnableRefreshAutoRefreshAndClear [

	| layout |
	layout := MCPObservabilityPresenter new controlsLayout.

	self assert: layout children size equals: 4.
	self assert: layout children first label equals: 'Enable observability'.
	self assert: layout children second label equals: 'Refresh'.
	self assert: layout children third label equals: 'Auto-refresh'.
	self assert: layout children fourth label equals: 'Clear'
]

{ #category : 'tests' }
MCPObservabilityPresenterTest >> testEverySectionIsLabelledWithItsCount [

	| presenter mcp |
	mcp := self mcpWithoutObservabilityExport.
	presenter := MCPObservabilityPresenter on: mcp.

	self assert: (presenter instVarNamed: #metricsLabel) label equals: 'Metrics (0)'.
	self assert: (presenter instVarNamed: #tracesLabel) label equals: 'Traces (0)'.
	self assert: (presenter instVarNamed: #logsLabel) label equals: 'Logs (0)'
]

{ #category : 'tests' }
MCPObservabilityPresenterTest >> testLogsForDisplayAreTailFirst [

	self
		assert: (MCPObservabilityPresenter new logsForDisplayFrom: #( 'oldest' 'middle' 'newest' ))
		equals: #( 'newest' 'middle' 'oldest' )
]

{ #category : 'tests' }
MCPObservabilityPresenterTest >> testMetricsTableHasExpectedColumns [

	| titles |
	titles := (MCPObservabilityPresenter new instVarNamed: #metricsTable) columns collect: [ :each | each title ].

	self assert: titles equals: #( 'Tool' 'Calls' 'Errors' 'Avg ms' 'Min ms' 'Max ms' 'Last ms' )
]

{ #category : 'tests' }
MCPObservabilityPresenterTest >> testObservabilityToggleUpdatesModelImmediately [

	| mcp presenter |
	mcp := self mcpWithoutObservabilityExport.
	presenter := MCPObservabilityPresenter on: mcp.

	self assert: mcp observabilityEnabled.
	presenter observabilityChangedTo: false.
	self deny: mcp observabilityEnabled.
	presenter observabilityChangedTo: true.
	self assert: mcp observabilityEnabled
]

{ #category : 'tests' }
MCPObservabilityPresenterTest >> testTheMetricsTableNamesItsTool [
	"The column asked a record for #tool, which it does not answer, so the table died on its first row and took the tab with it whenever observability had recorded anything."

	| column |
	column := (MCPObservabilityPresenter new instVarNamed: #metricsTable) columns detect: [ :each | each title = 'Tool' ].

	self
		assert: (column readObject: (MCPToolCallStats new
					  toolName: 'image_evaluate';
					  yourself))
		equals: 'image_evaluate'
]

{ #category : 'tests' }
MCPObservabilityPresenterTest >> testTheTracesTableNamesItsTool [

	| column |
	column := (MCPObservabilityPresenter new instVarNamed: #tracesTable) columns detect: [ :each | each title = 'Tool' ].

	self
		assert: (column readObject: (MCPToolCallRecord new
					  toolName: 'class_get';
					  yourself))
		equals: 'class_get'
]

{ #category : 'tests' }
MCPObservabilityPresenterTest >> testTracesContextMenuCanBeBuilt [

	self assert: MCPObservabilityPresenter new tracesContextMenu class equals: SpMenuPresenter
]
