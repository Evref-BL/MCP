"
Tests the inspector tab that shows what a server recorded about itself.
"
Class {
	#name : 'MCPObservabilityPresenterTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-UI-Tests',
	#package : 'MCP-UI-Tests'
}

{ #category : 'private' }
MCPObservabilityPresenterTest >> presenterAfterFailedCallsTo: toolNames [
	"A presenter on a server that recorded one failed call per name, which is what puts a call in the traces as well as the metrics and the logs."

	| mcp backend |
	mcp := self mcpWithoutObservabilityExport.
	backend := mcp observability.
	toolNames do: [ :toolName |
			backend
				recordToolCallFinish: (backend
						 recordToolCallStart: toolName
						 input: nil
						 dispatchPath: 'direct'
						 context: Dictionary new)
				result: nil
				error: Error new ].
	^ MCPObservabilityPresenter on: mcp
]

{ #category : 'private' }
MCPObservabilityPresenterTest >> tableNamed: aName of: aPresenter [

	^ aPresenter instVarNamed: aName
]

{ #category : 'tests' }
MCPObservabilityPresenterTest >> testALogLineThatIsNotAToolCallFiltersNothing [
	"Selecting 'Observability cleared' or 'Trace export failed' raised, since the line names no tool for the title to say."

	| presenter logs |
	presenter := self presenterAfterFailedCallsTo: #( 'a' 'b' ).
	presenter model observability recordLog: 'Trace export failed: IOError'.
	presenter refreshView.
	logs := self tableNamed: #logsTable of: presenter.

	logs selectItem: (logs items detect: [ :line | line beginsWith: 'Trace export failed' ]).

	self assert: (self tableNamed: #metricsTable of: presenter) items size equals: 2.
	self assert: (self tableNamed: #tracesTable of: presenter) items size equals: 2.
	self assert: (presenter instVarNamed: #metricsLabel) label equals: 'Metrics (2)'.
	self assert: (presenter instVarNamed: #tracesLabel) label equals: 'Traces (2)'
]

{ #category : 'tests' }
MCPObservabilityPresenterTest >> testASelectionSurvivesARefreshAndIsForgottenOnceItsDataIsGone [

	| presenter metrics |
	presenter := self presenterAfterFailedCallsTo: #( 'a' 'b' ).
	metrics := self tableNamed: #metricsTable of: presenter.
	metrics selectItem: (metrics items detect: [ :stats | stats toolName = 'b' ]).

	presenter refreshView.
	self assert: metrics selectedItem toolName equals: 'b'.
	self assert: (self tableNamed: #tracesTable of: presenter) items size equals: 1.

	presenter clearObservability.
	self assert: (self tableNamed: #tracesTable of: presenter) items isEmpty.
	self assert: (presenter instVarNamed: #tracesLabel) label equals: 'Traces (0)'
]

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
MCPObservabilityPresenterTest >> testControlsStartWithEnableRefreshAutoRefreshClearAndShowAll [

	| layout |
	layout := MCPObservabilityPresenter new controlsLayout.

	self assert: layout children size equals: 5.
	self assert: layout children first label equals: 'Enable observability'.
	self assert: layout children second label equals: 'Refresh'.
	self assert: layout children third label equals: 'Auto-refresh'.
	self assert: layout children fourth label equals: 'Clear'.
	self assert: layout children fifth label equals: 'Show all'
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
MCPObservabilityPresenterTest >> testSelectingALogLineFiltersTheMetricsAndTracesToItsTool [

	| presenter logs |
	presenter := self presenterAfterFailedCallsTo: #( 'a' 'a' 'b' ).
	logs := self tableNamed: #logsTable of: presenter.

	logs selectItem: (logs items detect: [ :line | line includesSubstring: ' tool b #' ]).

	self assert: (self tableNamed: #metricsTable of: presenter) items size equals: 1.
	self assert: (self tableNamed: #tracesTable of: presenter) items size equals: 1.
	self assert: (self tableNamed: #logsTable of: presenter) items size equals: 3.
	self assert: (presenter instVarNamed: #tracesLabel) label equals: 'Traces (1 of 3) - log of b'
]

{ #category : 'tests' }
MCPObservabilityPresenterTest >> testSelectingAMetricFiltersTheTracesAndLogsToItsTool [

	| presenter metrics |
	presenter := self presenterAfterFailedCallsTo: #( 'a' 'a' 'b' ).
	metrics := self tableNamed: #metricsTable of: presenter.

	metrics selectItem: (metrics items detect: [ :stats | stats toolName = 'a' ]).

	self assert: (self tableNamed: #tracesTable of: presenter) items size equals: 2.
	self assert: ((self tableNamed: #tracesTable of: presenter) items allSatisfy: [ :record | record toolName = 'a' ]).
	self assert: (self tableNamed: #logsTable of: presenter) items size equals: 2.
	self assert: (self tableNamed: #metricsTable of: presenter) items size equals: 2.
	self assert: (presenter instVarNamed: #tracesLabel) label equals: 'Traces (2 of 3) - tool a'.
	self assert: (presenter instVarNamed: #logsLabel) label equals: 'Logs (2 of 3) - tool a'
]

{ #category : 'tests' }
MCPObservabilityPresenterTest >> testSelectingATraceFiltersTheMetricsToItsToolAndTheLogsToItsCall [

	| presenter traces trace |
	presenter := self presenterAfterFailedCallsTo: #( 'a' 'a' 'b' ).
	traces := self tableNamed: #tracesTable of: presenter.
	trace := traces items detect: [ :record | record toolName = 'a' ].

	traces selectItem: trace.

	self assert: (self tableNamed: #metricsTable of: presenter) items size equals: 1.
	self assert: (self tableNamed: #metricsTable of: presenter) items first toolName equals: 'a'.
	self assert: (self tableNamed: #logsTable of: presenter) items size equals: 1.
	self assert: (self tableNamed: #tracesTable of: presenter) items size equals: 3.
	self assert: (presenter instVarNamed: #metricsLabel) label equals: 'Metrics (1 of 2) - trace of a'
]

{ #category : 'tests' }
MCPObservabilityPresenterTest >> testShowAllDropsEveryFilter [

	| presenter metrics |
	presenter := self presenterAfterFailedCallsTo: #( 'a' 'a' 'b' ).
	metrics := self tableNamed: #metricsTable of: presenter.
	metrics selectItem: (metrics items detect: [ :stats | stats toolName = 'a' ]).

	presenter showAll.

	self assert: (self tableNamed: #tracesTable of: presenter) items size equals: 3.
	self assert: (self tableNamed: #logsTable of: presenter) items size equals: 3.
	self assert: metrics selectedItem isNil.
	self assert: (presenter instVarNamed: #tracesLabel) label equals: 'Traces (3)'
]

{ #category : 'tests' }
MCPObservabilityPresenterTest >> testTheMetricsTableNamesItsTool [
	"The column asked a record for #tool, which it does not answer, so the table died on its first row and took the tab with it whenever observability had recorded anything."

	| column |
	column := (MCPObservabilityPresenter new instVarNamed: #metricsTable) columns detect: [ :each | each title = 'Tool' ].

	self
		assert: (column readObject: (MCPToolCallStats new
					  toolName: 'evaluate';
					  yourself))
		equals: 'evaluate'
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
