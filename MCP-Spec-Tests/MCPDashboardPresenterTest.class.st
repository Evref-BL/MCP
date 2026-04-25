Class {
	#name : 'MCPDashboardPresenterTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Spec-Tests-Monitoring',
	#package : 'MCP-Spec-Tests',
	#tag : 'Monitoring'
}

{ #category : 'tests' }
MCPDashboardPresenterTest >> testAllMonitoringSectionsCollapsedRemovesOuterSplitter [

	| presenter layout monitoringLayout sectionsLayout |
	presenter := MCPDashboardPresenter new.

	presenter toggleMetricsSection.
	presenter toggleLogsSection.
	layout := presenter dashboardWidgetsLayout.
	monitoringLayout := layout children second.
	sectionsLayout := monitoringLayout children second.

	self deny: presenter hasExpandedMonitoringSection.
	self assert: layout class equals: SpBoxLayout.
	self assert: layout children size equals: 2.
	self assert: monitoringLayout children size equals: 2.
	self assert: sectionsLayout children size equals: 2
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
	observabilityLayout := MCPDashboardPresenter new
		                       monitoringControlsLayout.

	self assert: configurationLayout children size equals: 5.
	self
		assert: configurationLayout children third class
		equals: SpNullPresenter.
	self
		assert: configurationLayout children fourth label
		equals: 'Debug mode'.
	self
		assert: observabilityLayout children first class
		equals: SpNullPresenter.
	self
		assert: observabilityLayout children fourth class
		equals: SpNullPresenter
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testCollapsedMetricsSectionKeepsHeaderVisible [

	| presenter collapsedLayout |
	presenter := MCPDashboardPresenter new.

	presenter toggleMetricsSection.
	collapsedLayout := presenter metricsWidgetLayout.

	self deny: presenter isMetricsSectionExpanded.
	self assert: collapsedLayout children size equals: 1.
	self
		assert: collapsedLayout children first class
		equals: SpButtonPresenter
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testCollapsedMonitoringSectionUsesFixedHeaderRow [

	| presenter layout sectionsLayout |
	presenter := MCPDashboardPresenter new.

	presenter toggleMetricsSection.
	layout := presenter monitoringWidgetsLayout.
	sectionsLayout := layout children second.

	self assert: layout class equals: SpBoxLayout.
	self assert: layout children size equals: 2.
	self assert: sectionsLayout class equals: SpBoxLayout.
	self assert: sectionsLayout children size equals: 2.
	self assert: sectionsLayout children first children size equals: 1.
	self assert: sectionsLayout children second children size equals: 2
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

	| presenter layout monitoringLayout monitoringSectionsLayout |
	presenter := MCPDashboardPresenter new.

	presenter toggleToolsSection.
	layout := presenter dashboardWidgetsLayout.
	monitoringLayout := layout children second.
	monitoringSectionsLayout := monitoringLayout children second.

	self assert: layout class equals: SpBoxLayout.
	self assert: layout children size equals: 2.
	self assert: layout children first children size equals: 1.
	self assert: monitoringLayout class equals: SpBoxLayout.
	self assert: monitoringSectionsLayout class equals: SpPanedLayout
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

	| presenter layout monitoringLayout monitoringSectionsLayout |
	presenter := MCPDashboardPresenter new.
	layout := presenter dashboardWidgetsLayout.
	monitoringLayout := layout children second.
	monitoringSectionsLayout := monitoringLayout children second.

	self assert: layout class equals: SpPanedLayout.
	self assert: layout isVertical.
	self assert: layout children size equals: 2.
	self assert: monitoringLayout class equals: SpBoxLayout.
	self assert: monitoringLayout children size equals: 2.
	self assert: monitoringSectionsLayout class equals: SpPanedLayout.
	self assert: monitoringSectionsLayout isVertical.
	self assert: monitoringSectionsLayout children size equals: 2
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testDebugModeCheckboxExplainsBehavior [

	| debugCheckBox presenter |
	presenter := MCPDashboardPresenter new.
	debugCheckBox := presenter instVarNamed: #debugCheckBox.

	self assert: debugCheckBox label equals: 'Debug mode'.
	self assert: (debugCheckBox help includesSubstring:
			 'server and JSON-RPC errors pass through').
	self assert:
		(debugCheckBox help includesSubstring: 'debugger can open').
	self assert:
		(debugCheckBox help includesSubstring: 'normal error responses')
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testDisclosureLabelsIncludeStateTitleAndCount [

	| presenter |
	presenter := MCPDashboardPresenter new.

	self
		assert:
		(presenter disclosureLabelFor: 'Logs' count: 3 expanded: true)
		equals: '[-] Logs (3)'.
	self
		assert:
		(presenter disclosureLabelFor: 'Logs' count: 3 expanded: false)
		equals: '[+] Logs (3)'
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
	self
		assert:
		(presenter logsForDisplayFrom: #( 'oldest' 'middle' 'newest' ))
		equals: #( 'newest' 'middle' 'oldest' )
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testObservabilityControlsStartWithEnableRefreshAutoRefreshAndClear [

	| layout |
	layout := MCPDashboardPresenter new monitoringControlsLayout.

	self assert: layout children size equals: 6.
	self
		assert: layout children second label
		equals: 'Enable observability'.
	self assert: layout children third label equals: 'Refresh'.
	self assert: layout children fifth label equals: 'Auto-refresh'.
	self assert: layout children sixth label equals: 'Clear'
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testObservabilityToggleUpdatesModelImmediately [

	| mcp presenter |
	mcp := MCP new.
	presenter := MCPDashboardPresenter on: mcp.

	self deny: mcp monitoringEnabled.
	presenter observabilityChangedTo: true.
	self assert: mcp monitoringEnabled.
	presenter observabilityChangedTo: false.
	self deny: mcp monitoringEnabled
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testRefreshViewUsesShortObservabilitySectionLabels [

	| logsHeader metricsHeader mcp presenter |
	mcp := MCP new.
	presenter := MCPDashboardPresenter on: mcp.
	presenter refreshView.
	metricsHeader := presenter instVarNamed: #metricsHeaderButton.
	logsHeader := presenter instVarNamed: #logsHeaderButton.

	self assert: metricsHeader label equals: '[-] Tool metrics (0)'.
	self assert: logsHeader label equals: '[-] Logs (0)'
]
