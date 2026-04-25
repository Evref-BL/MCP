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
MCPDashboardPresenterTest >> testDisclosureLabelsIncludeStateTitleAndCount [

	| presenter |
	presenter := MCPDashboardPresenter new.

	self
		assert: (presenter
				 disclosureLabelFor: 'Monitoring log'
				 count: 3
				 expanded: true)
		equals: '[-] Monitoring log (3)'.
	self
		assert: (presenter
				 disclosureLabelFor: 'Monitoring log'
				 count: 3
				 expanded: false)
		equals: '[+] Monitoring log (3)'
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testLifecycleActionsIncludeAutoRefreshControl [

	| layout |
	layout := MCPDashboardPresenter new lifecycleActionsLayout.

	self assert: layout children size equals: 5.
	self assert: layout children first label equals: 'Refresh'.
	self assert: layout children second label equals: 'Auto-refresh'
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
