"
Tests the MCP Spec dashboard presenter layout, actions, and refresh behavior.
"
Class {
	#name : 'MCPDashboardPresenterTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-UI-Tests-Observability',
	#package : 'MCP-UI-Tests',
	#tag : 'Observability'
}

{ #category : 'tests' }
MCPDashboardPresenterTest >> testAllObservabilitySectionsCollapsedRemovesOuterSplitter [

	| presenter layout observabilityLayout sectionsLayout |
	presenter := MCPDashboardPresenter new.

	presenter toggleMetricsSection.
	presenter toggleTracesSection.
	presenter toggleLogsSection.
	layout := presenter dashboardWidgetsLayout.
	observabilityLayout := layout children second.
	sectionsLayout := observabilityLayout children second.

	self deny: presenter hasExpandedObservabilitySection.
	self assert: layout class equals: SpBoxLayout.
	self assert: layout children size equals: 2.
	self assert: observabilityLayout children size equals: 2.
	self assert: sectionsLayout children size equals: 3
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testAutoRefreshIsDisabledByDefault [

	| presenter |
	presenter := MCPDashboardPresenter new.

	self deny: presenter isAutoRefreshEnabled.
	self deny: presenter isAutoRefreshProcessRunning
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testCheckboxRowsIncludeLeftPadding [

	| configurationLayout observabilityLayout |
	configurationLayout := MCPDashboardPresenter new configurationLayout.
	observabilityLayout := MCPDashboardPresenter new observabilityControlsLayout.

	self assert: configurationLayout children size equals: 5.
	self assert: configurationLayout children third class equals: SpNullPresenter.
	self assert: configurationLayout children fourth label equals: 'Debug mode'.
	self assert: observabilityLayout children first class equals: SpNullPresenter.
	self assert: observabilityLayout children fourth class equals: SpNullPresenter
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testCollapsedLogsSectionKeepsHeaderAndSplitsOpenSections [

	| presenter sectionsLayout splitLayout |
	presenter := MCPDashboardPresenter new.

	presenter toggleLogsSection.
	sectionsLayout := presenter observabilitySectionsLayout.
	splitLayout := sectionsLayout children first.

	self assert: sectionsLayout class equals: SpBoxLayout.
	self assert: splitLayout class equals: SpPanedLayout.
	self assert: splitLayout isVertical.
	self assert: sectionsLayout children second children size equals: 1
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testCollapsedMetricsSectionKeepsHeaderVisible [

	| presenter collapsedLayout |
	presenter := MCPDashboardPresenter new.

	presenter toggleMetricsSection.
	collapsedLayout := presenter metricsWidgetLayout.

	self deny: presenter isMetricsSectionExpanded.
	self assert: collapsedLayout children size equals: 1.
	self assert: collapsedLayout children first class equals: SpButtonPresenter
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testCollapsedObservabilitySectionUsesFixedHeaderRow [

	| presenter sectionsLayout splitLayout |
	presenter := MCPDashboardPresenter new.

	presenter toggleMetricsSection.
	sectionsLayout := presenter observabilitySectionsLayout.
	splitLayout := sectionsLayout children second.

	self assert: sectionsLayout class equals: SpBoxLayout.
	self assert: sectionsLayout children first children size equals: 1.
	self assert: splitLayout class equals: SpPanedLayout.
	self assert: splitLayout isVertical
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testCollapsedSectionCanBeExpandedAgain [

	| presenter |
	presenter := MCPDashboardPresenter new.

	presenter toggleToolsSection.
	presenter toggleToolsSection.

	self assert: presenter isToolsSectionExpanded.
	self assert: presenter toolsWidgetLayout children size equals: 2
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testCollapsedToolsSectionUsesFixedHeaderRow [

	| presenter layout observabilityLayout observabilitySectionsLayout |
	presenter := MCPDashboardPresenter new.

	presenter toggleToolsSection.
	layout := presenter dashboardWidgetsLayout.
	observabilityLayout := layout children second.
	observabilitySectionsLayout := observabilityLayout children second.

	self assert: layout class equals: SpBoxLayout.
	self assert: layout children size equals: 2.
	self assert: layout children first children size equals: 1.
	self assert: observabilityLayout class equals: SpBoxLayout.
	self assert: observabilitySectionsLayout class equals: SpPanedLayout
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testCollapsedTracesSectionKeepsHeaderAndSplitsOpenSections [

	| lowerLayout presenter sectionsLayout |
	presenter := MCPDashboardPresenter new.

	presenter toggleTracesSection.
	sectionsLayout := presenter observabilitySectionsLayout.
	lowerLayout := sectionsLayout children second.

	self assert: sectionsLayout class equals: SpPanedLayout.
	self assert: sectionsLayout isVertical.
	self assert: lowerLayout class equals: SpBoxLayout.
	self assert: lowerLayout children first children size equals: 1
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testCollapsibleSectionsAreExpandedByDefault [

	| presenter |
	presenter := MCPDashboardPresenter new.

	self assert: presenter isToolsSectionExpanded.
	self assert: presenter isMetricsSectionExpanded.
	self assert: presenter isLogsSectionExpanded.
	self assert: presenter toolsWidgetLayout children size equals: 2.
	self assert: presenter metricsWidgetLayout children size equals: 2.
	self assert: presenter logsWidgetLayout children size equals: 2
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testCollapsibleSectionsRemoveOnlyTheirBody [

	| presenter |
	presenter := MCPDashboardPresenter new.

	presenter toggleToolsSection.
	presenter toggleMetricsSection.
	presenter toggleLogsSection.

	self deny: presenter isToolsSectionExpanded.
	self deny: presenter isMetricsSectionExpanded.
	self deny: presenter isLogsSectionExpanded.
	self assert: presenter toolsWidgetLayout children size equals: 1.
	self assert: presenter metricsWidgetLayout children size equals: 1.
	self assert: presenter logsWidgetLayout children size equals: 1
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testDashboardWidgetsUseVerticalSplitters [

	| nestedSections presenter layout observabilityLayout observabilitySectionsLayout |
	presenter := MCPDashboardPresenter new.
	layout := presenter dashboardWidgetsLayout.
	observabilityLayout := layout children second.
	observabilitySectionsLayout := observabilityLayout children second.
	nestedSections := observabilitySectionsLayout children second.

	self assert: layout class equals: SpPanedLayout.
	self assert: layout isVertical.
	self assert: observabilitySectionsLayout class equals: SpPanedLayout.
	self assert: observabilitySectionsLayout isVertical.
	self assert: nestedSections class equals: SpPanedLayout.
	self assert: nestedSections isVertical
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testDebugModeCheckboxExplainsBehavior [

	| debugCheckBox presenter |
	presenter := MCPDashboardPresenter new.
	debugCheckBox := presenter instVarNamed: #debugCheckBox.

	self assert: debugCheckBox label equals: 'Debug mode'.
	self assert: (debugCheckBox help includesSubstring: 'server and JSON-RPC errors pass through').
	self assert: (debugCheckBox help includesSubstring: 'debugger can open').
	self assert: (debugCheckBox help includesSubstring: 'normal error responses')
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testDisclosureLabelsIncludeStateTitleAndCount [

	| presenter |
	presenter := MCPDashboardPresenter new.

	self assert: (presenter disclosureLabelFor: 'Logs' count: 3 expanded: true) equals: '[-] Logs (3)'.
	self assert: (presenter disclosureLabelFor: 'Logs' count: 3 expanded: false) equals: '[+] Logs (3)'
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testFreshMCPWithNoopObservabilityCollapsesObservabilitySections [

	| mcp presenter |
	mcp := MCP new.
	presenter := MCPDashboardPresenter on: mcp.
	presenter refreshView.

	self deny: mcp observabilityEnabled.
	self assert: presenter isToolsSectionExpanded.
	self deny: presenter isMetricsSectionExpanded.
	self deny: presenter isTracesSectionExpanded.
	self deny: presenter isLogsSectionExpanded.
	self assert: presenter toolsWidgetLayout children size equals: 2.
	self assert: presenter metricsWidgetLayout children size equals: 1.
	self assert: presenter tracesWidgetLayout children size equals: 1.
	self assert: presenter logsWidgetLayout children size equals: 1
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testHeaderLayoutUsesStatusAndEndpointRows [

	| headerLayout presenter statusRow |
	presenter := MCPDashboardPresenter new.
	headerLayout := presenter headerLayout.
	statusRow := headerLayout children first.

	self assert: headerLayout class equals: SpBoxLayout.
	self assert: headerLayout isVertical.
	self assert: headerLayout children size equals: 2.
	self assert: statusRow class equals: SpBoxLayout.
	self assert: statusRow isHorizontal.
	self assert: statusRow children size equals: 3.
	self assert: statusRow children first identicalTo: (presenter instVarNamed: #statusLabel).
	self assert: statusRow children second identicalTo: (presenter instVarNamed: #statusIcon).
	self assert: statusRow children third identicalTo: (presenter instVarNamed: #statusValueLabel).
	self assert: headerLayout children second identicalTo: (presenter instVarNamed: #urlLabel)
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testInitialSectionsCollapseAfterObservabilityIsDisabled [

	| mcp presenter record |
	mcp := MCP new.
	mcp observabilityEnabled: true.
	record := mcp observability recordToolCallStart: 'failing-tool'.
	mcp observability recordToolCallFinish: record result: (MCPStructureErrorToolResult content: #(  )) error: Error new.
	mcp observabilityEnabled: false.
	presenter := MCPDashboardPresenter on: mcp.
	presenter refreshView.

	self deny: mcp observabilityEnabled.
	self deny: presenter isMetricsSectionExpanded.
	self deny: presenter isTracesSectionExpanded.
	self deny: presenter isLogsSectionExpanded
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testInitialSectionsOpenForObservabilityEnabled [

	| mcp presenter |
	mcp := MCP new.
	mcp observabilityEnabled: true.
	presenter := MCPDashboardPresenter on: mcp.
	presenter refreshView.

	self assert: presenter isMetricsSectionExpanded.
	self assert: presenter isTracesSectionExpanded.
	self assert: presenter isLogsSectionExpanded.
	self assert: presenter metricsWidgetLayout children size equals: 2.
	self assert: presenter tracesWidgetLayout children size equals: 2.
	self assert: presenter logsWidgetLayout children size equals: 2
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testLifecycleActionsOnlyContainServerControls [

	| layout |
	layout := MCPDashboardPresenter new lifecycleActionsLayout.

	self assert: layout children size equals: 3.
	self assert: layout children first label equals: 'Start'.
	self assert: layout children second label equals: 'Stop'.
	self assert: layout children third label equals: 'Restart'
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testLogsForDisplayAreTailFirst [

	| presenter |
	presenter := MCPDashboardPresenter new.
	self assert: (presenter logsForDisplayFrom: #( 'oldest' 'middle' 'newest' )) equals: #( 'newest' 'middle' 'oldest' )
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testManualExpansionWorksAfterInitialStateIsChosen [

	| mcp presenter |
	mcp := MCP new.
	presenter := MCPDashboardPresenter on: mcp.
	presenter refreshView.

	self deny: presenter isMetricsSectionExpanded.
	presenter toggleMetricsSection.
	presenter refreshView.
	self assert: presenter isMetricsSectionExpanded.
	self assert: presenter metricsWidgetLayout children size equals: 2
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testMetricsTableHasExpectedColumns [

	| metricsTable presenter titles |
	presenter := MCPDashboardPresenter new.
	metricsTable := presenter instVarNamed: #metricsTable.
	titles := metricsTable columns collect: [ :each | each title ].
	self assert: titles equals: #( 'Tool' 'Calls' 'Errors' 'Avg ms' 'Min ms' 'Max ms' 'Last ms' )
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testObservabilityControlsStartWithEnableRefreshAutoRefreshAndClear [

	| layout |
	layout := MCPDashboardPresenter new observabilityControlsLayout.

	self assert: layout children size equals: 6.
	self assert: layout children second label equals: 'Enable observability'.
	self assert: layout children third label equals: 'Refresh'.
	self assert: layout children fifth label equals: 'Auto-refresh'.
	self assert: layout children sixth label equals: 'Clear'
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testObservabilityToggleUpdatesModelImmediately [

	| mcp presenter |
	mcp := MCP new.
	presenter := MCPDashboardPresenter on: mcp.

	self deny: mcp observabilityEnabled.
	presenter observabilityChangedTo: true.
	self assert: mcp observabilityEnabled.
	presenter observabilityChangedTo: false.
	self deny: mcp observabilityEnabled
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testRefreshViewUpdatesStatusIcon [

	| mcp presenter statusIcon statusLabel statusValueLabel |
	mcp := MCP new.
	presenter := MCPDashboardPresenter on: mcp.
	presenter refreshView.
	statusIcon := presenter instVarNamed: #statusIcon.
	statusLabel := presenter instVarNamed: #statusLabel.
	statusValueLabel := presenter instVarNamed: #statusValueLabel.

	self assert: statusIcon image equals: (presenter iconNamed: #testNotRun).
	self assert: statusIcon help equals: 'Status: stopped'.
	self assert: statusLabel label equals: 'Status:'.
	self assert: statusValueLabel label equals: 'stopped'
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testRefreshViewUsesShortSectionLabels [

	| logsHeader metricsHeader mcp presenter toolsHeader tracesHeader |
	mcp := MCP new.
	presenter := MCPDashboardPresenter on: mcp.
	presenter refreshView.
	toolsHeader := presenter instVarNamed: #toolsHeaderButton.
	metricsHeader := presenter instVarNamed: #metricsHeaderButton.
	tracesHeader := presenter instVarNamed: #tracesHeaderButton.
	logsHeader := presenter instVarNamed: #logsHeaderButton.

	self assert: toolsHeader label equals: ('[-] Tools ({1})' format: { mcp sortedTools size asString }).
	self assert: metricsHeader label equals: '[+] Metrics (0)'.
	self assert: tracesHeader label equals: '[+] Traces (0)'.
	self assert: logsHeader label equals: '[+] Logs (0)'
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testRefreshViewUsesSingleServerStatus [

	| mcp presenter statusValueLabel |
	mcp := MCP new.
	presenter := MCPDashboardPresenter on: mcp.
	presenter refreshView.
	statusValueLabel := presenter instVarNamed: #statusValueLabel.

	self assert: statusValueLabel label equals: 'stopped'.
	self deny: (statusValueLabel label includesSubstring: 'HTTP:').
	self deny: (statusValueLabel label includesSubstring: 'Listener:')
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testServerStatusIconUsesTestIcons [

	| presenter |
	presenter := MCPDashboardPresenter new.

	self assert: (presenter serverStatusIconNameForRunning: false listening: false) equals: #testNotRun.
	self assert: (presenter serverStatusIconNameForRunning: true listening: true) equals: #testGreen.
	self assert: (presenter serverStatusIconNameForRunning: true listening: false) equals: #testRed.
	self assert: (presenter serverStatusIconNameForRunning: false listening: true) equals: #testRed
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testServerStatusLabelShowsListenerOnlyWhenAnomalous [

	| presenter |
	presenter := MCPDashboardPresenter new.

	self assert: (presenter serverStatusLabelForRunning: false listening: false) equals: 'Status: stopped'.
	self assert: (presenter serverStatusLabelForRunning: true listening: true) equals: 'Status: running'.
	self assert: (presenter serverStatusLabelForRunning: true listening: false) equals: 'Status: running, socket not listening'.
	self assert: (presenter serverStatusLabelForRunning: false listening: true) equals: 'Status: stopped, socket still listening'
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testToolsSectionCollapsesWhenToolCatalogIsEmpty [

	| mcp presenter |
	mcp := MCP new.
	mcp toolsList: Dictionary new.
	presenter := MCPDashboardPresenter on: mcp.
	presenter refreshView.

	self deny: presenter isToolsSectionExpanded.
	self assert: presenter toolsWidgetLayout children size equals: 1
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testToolsTableHasExpectedColumns [

	| presenter titles toolsTable |
	presenter := MCPDashboardPresenter new.
	toolsTable := presenter instVarNamed: #toolsTable.
	titles := toolsTable columns collect: [ :each | each title ].
	self assert: titles equals: #( 'Tool' 'Title' 'Description' )
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testTracesContextMenuCanBeBuilt [

	| menu presenter |
	presenter := MCPDashboardPresenter new.

	menu := presenter tracesContextMenu.

	self assert: menu class equals: SpMenuPresenter
]
