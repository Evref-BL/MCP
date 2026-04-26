"
Spec presenter used by the inspector for an MCP server object. It shows server state, endpoint configuration, lifecycle controls, registered tools, observability metrics, and recent observability logs. The main dashboard widgets are arranged with draggable splitters and disclosure-style section headers so the tools, metrics, and log tables can be resized or collapsed while inspecting the server. Observability data can be refreshed manually or through the auto-refresh checkbox while the presenter is displayed.
"
Class {
	#name : 'MCPDashboardPresenter',
	#superclass : 'SpPresenterWithModel',
	#instVars : [
		'summaryLabel',
		'statusLabel',
		'urlLabel',
		'detailsLabel',
		'toolsHeaderButton',
		'portLabel',
		'portInput',
		'debugCheckBox',
		'applyButton',
		'refreshButton',
		'autoRefreshCheckBox',
		'startButton',
		'stopButton',
		'restartButton',
		'toolsTable',
		'monitoringCheckBox',
		'clearMonitoringButton',
		'metricsHeaderButton',
		'metricsTable',
		'logsHeaderButton',
		'logsTable',
		'autoRefreshProcess',
		'toolsSectionExpanded',
		'metricsSectionExpanded',
		'logsSectionExpanded'
	],
	#category : 'MCP-Spec',
	#package : 'MCP-Spec'
}

{ #category : 'instance creation' }
MCPDashboardPresenter class >> on: anMCP [

	^ self new
		  model: anMCP;
		  updatePresenter;
		  yourself
]

{ #category : 'instance creation' }
MCPDashboardPresenter class >> openOn: anMCP [

	^ (self on: anMCP) open
]

{ #category : 'layout' }
MCPDashboardPresenter >> addMonitoringWidgetsLayoutTo: aBoxLayout [

	self hasExpandedMonitoringSection
		ifTrue: [ aBoxLayout add: self monitoringWidgetsLayout ]
		ifFalse: [
		aBoxLayout add: self monitoringWidgetsLayout expand: false ]
]

{ #category : 'layout' }
MCPDashboardPresenter >> addPaddedCheckbox: aCheckBoxPresenter width: width to: aBoxLayout [

	aBoxLayout
		add: self newNullPresenter
		withConstraints: [ :constraints | constraints width: 8 ].
	aBoxLayout
		add: aCheckBoxPresenter
		withConstraints: [ :constraints | constraints width: width ].
	^ aBoxLayout
]

{ #category : 'layout' }
MCPDashboardPresenter >> addSectionLayout: aSectionLayout expanded: expanded to: aBoxLayout [

	expanded
		ifTrue: [ aBoxLayout add: aSectionLayout ]
		ifFalse: [ aBoxLayout add: aSectionLayout expand: false ]
]

{ #category : 'actions' }
MCPDashboardPresenter >> applyConfiguration [

	[
	| newPort |
	newPort := self readPortFromInput.
	self model configurePort: newPort debugMode: debugCheckBox state ]
		on: Error
		do: [ :error | UIManager default alert: error messageText ].

	self refreshView
]

{ #category : 'collapsing' }
MCPDashboardPresenter >> areAllMonitoringSectionsExpanded [

	^ self isMetricsSectionExpanded and: [ self isLogsSectionExpanded ]
]

{ #category : 'auto-refresh' }
MCPDashboardPresenter >> autoRefreshChangedTo: enabled [

	enabled
		ifTrue: [ self startAutoRefresh ]
		ifFalse: [ self stopAutoRefreshProcess ]
]

{ #category : 'auto-refresh' }
MCPDashboardPresenter >> autoRefreshIntervalSeconds [

	^ 2
]

{ #category : 'auto-refresh' }
MCPDashboardPresenter >> autoRefreshLoop [

	[
	[ self shouldAutoRefresh ] whileTrue: [
		(Delay forSeconds: self autoRefreshIntervalSeconds) wait.
		self shouldAutoRefresh ifTrue: [ self defer: [ self refreshView ] ] ] ]
		ensure: [ autoRefreshProcess := nil ]
]

{ #category : 'actions' }
MCPDashboardPresenter >> clearMonitoring [

	self model clearMonitoring.
	self refreshView
]

{ #category : 'layout' }
MCPDashboardPresenter >> configurationLayout [

	| boxLayout |
	boxLayout := SpBoxLayout newLeftToRight.
	boxLayout
		add: portLabel expand: false;
		add: portInput
		withConstraints: [ :constraints | constraints width: 90 ].
	self addPaddedCheckbox: debugCheckBox width: 140 to: boxLayout.
	boxLayout
		add: applyButton
		withConstraints: [ :constraints | constraints width: 110 ].
	^ boxLayout
]

{ #category : 'initialization' }
MCPDashboardPresenter >> connectPresenters [

	applyButton action: [ self applyConfiguration ].
	refreshButton action: [ self refreshView ].
	autoRefreshCheckBox whenChangedDo: [ :enabled |
		self autoRefreshChangedTo: enabled ].
	monitoringCheckBox whenChangedDo: [ :enabled |
		self observabilityChangedTo: enabled ].
	toolsHeaderButton action: [ self toggleToolsSection ].
	metricsHeaderButton action: [ self toggleMetricsSection ].
	logsHeaderButton action: [ self toggleLogsSection ].
	startButton action: [ self startServer ].
	stopButton action: [ self stopServer ].
	restartButton action: [ self restartServer ].
	clearMonitoringButton action: [ self clearMonitoring ]
]

{ #category : 'layout' }
MCPDashboardPresenter >> dashboardWidgetsBoxLayout [

	| widgetLayout |
	widgetLayout := SpBoxLayout newTopToBottom.
	self
		addSectionLayout: self toolsWidgetLayout
		expanded: self isToolsSectionExpanded
		to: widgetLayout.
	self addMonitoringWidgetsLayoutTo: widgetLayout.
	^ widgetLayout
]

{ #category : 'layout' }
MCPDashboardPresenter >> dashboardWidgetsLayout [

	(self isToolsSectionExpanded and: [
		 self hasExpandedMonitoringSection ]) ifTrue: [
		^ SpPanedLayout newTopToBottom
			  positionOfSlider: 42 percent;
			  first: self toolsWidgetLayout;
			  second: self monitoringWidgetsLayout;
			  yourself ].
	^ self dashboardWidgetsBoxLayout
]

{ #category : 'defaults' }
MCPDashboardPresenter >> debugModeHelpText [

	^ 'When enabled, server and JSON-RPC errors pass through to Pharo so a debugger can open instead of returning normal error responses. Use this while debugging tool or server failures.'
]

{ #category : 'layout' }
MCPDashboardPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: self headerLayout expand: false;
		  add: self configurationLayout
		  withConstraints: [ :constraints | constraints height: 30 ];
		  add: self lifecycleActionsLayout
		  withConstraints: [ :constraints | constraints height: 30 ];
		  add: self dashboardWidgetsLayout;
		  yourself
]

{ #category : 'collapsing' }
MCPDashboardPresenter >> disclosureLabelFor: title count: count expanded: expanded [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: (expanded
					   ifTrue: [ '[-] ' ]
					   ifFalse: [ '[+] ' ]);
			  nextPutAll: title;
			  nextPutAll: ' (';
			  print: count;
			  nextPut: $) ]
]

{ #category : 'collapsing' }
MCPDashboardPresenter >> hasExpandedMonitoringSection [

	^ self isMetricsSectionExpanded or: [ self isLogsSectionExpanded ]
]

{ #category : 'layout' }
MCPDashboardPresenter >> headerLayout [

	^ SpBoxLayout newTopToBottom
		  add: summaryLabel expand: false;
		  add: statusLabel expand: false;
		  add: urlLabel expand: false;
		  add: detailsLabel expand: false;
		  yourself
]

{ #category : 'api' }
MCPDashboardPresenter >> initialExtent [

	^ 1080 @ 760
]

{ #category : 'initialization' }
MCPDashboardPresenter >> initializePresenters [

	toolsSectionExpanded := true.
	metricsSectionExpanded := true.
	logsSectionExpanded := true.

	summaryLabel := self instantiate: SpLabelPresenter.
	statusLabel := self instantiate: SpLabelPresenter.
	urlLabel := self instantiate: SpLabelPresenter.
	detailsLabel := self instantiate: SpLabelPresenter.
	toolsHeaderButton := self instantiate: SpButtonPresenter.
	portLabel := self instantiate: SpLabelPresenter.
	portInput := self instantiate: SpTextInputFieldPresenter.
	debugCheckBox := self instantiate: SpCheckBoxPresenter.
	applyButton := self instantiate: SpButtonPresenter.
	refreshButton := self instantiate: SpButtonPresenter.
	autoRefreshCheckBox := self instantiate: SpCheckBoxPresenter.
	startButton := self instantiate: SpButtonPresenter.
	stopButton := self instantiate: SpButtonPresenter.
	restartButton := self instantiate: SpButtonPresenter.
	toolsTable := self newTable.
	monitoringCheckBox := self instantiate: SpCheckBoxPresenter.
	clearMonitoringButton := self instantiate: SpButtonPresenter.
	metricsHeaderButton := self instantiate: SpButtonPresenter.
	metricsTable := self newTable.
	logsHeaderButton := self instantiate: SpButtonPresenter.
	logsTable := self newTable.

	portLabel label: 'Port:'.
	debugCheckBox
		label: 'Debug mode';
		help: self debugModeHelpText.
	applyButton label: 'Apply'.
	refreshButton label: 'Refresh'.
	autoRefreshCheckBox label: 'Auto-refresh'.
	startButton label: 'Start'.
	stopButton label: 'Stop'.
	restartButton label: 'Restart'.
	monitoringCheckBox label: 'Enable observability'.
	clearMonitoringButton label: 'Clear'.

	toolsTable
		addColumn: (SpStringTableColumn title: 'Tool' evaluated: #name);
		addColumn: (SpStringTableColumn
				 title: 'Title'
				 evaluated: [ :tool | tool title ifNil: [ '' ] ]);
		addColumn: (SpStringTableColumn
				 title: 'Class'
				 evaluated: [ :tool | tool class name ]);
		addColumn: (SpStringTableColumn
				 title: 'Description'
				 evaluated: [ :tool | tool description ifNil: [ '' ] ]);
		beResizable.
	metricsTable
		addColumn: (SpStringTableColumn title: 'Tool' evaluated: #toolName);
		addColumn: (SpStringTableColumn
				 title: 'Calls'
				 evaluated: [ :stats | stats callCount asString ]);
		addColumn: (SpStringTableColumn
				 title: 'Errors'
				 evaluated: [ :stats | stats errorCount asString ]);
		addColumn: (SpStringTableColumn
				 title: 'Avg ms'
				 evaluated: #displayAverageMilliseconds);
		addColumn: (SpStringTableColumn
				 title: 'Min ms'
				 evaluated: #displayMinMilliseconds);
		addColumn: (SpStringTableColumn
				 title: 'Max ms'
				 evaluated: #displayMaxMilliseconds);
		addColumn: (SpStringTableColumn
				 title: 'Last ms'
				 evaluated: #displayLastMilliseconds);
		addColumn: (SpStringTableColumn
				 title: 'Outlier'
				 evaluated: #displayOutlierExplanation);
		beResizable.
	logsTable
		addColumn:
			(SpStringTableColumn title: 'Log' evaluated: [ :line | line ]);
		beResizable
]

{ #category : 'initialization' }
MCPDashboardPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter whenClosedDo: [ self stopAutoRefresh ]
]

{ #category : 'auto-refresh' }
MCPDashboardPresenter >> isAutoRefreshEnabled [

	^ autoRefreshCheckBox notNil and: [ autoRefreshCheckBox state ]
]

{ #category : 'auto-refresh' }
MCPDashboardPresenter >> isAutoRefreshProcessRunning [

	^ autoRefreshProcess notNil and: [
		  autoRefreshProcess isTerminated not ]
]

{ #category : 'collapsing' }
MCPDashboardPresenter >> isLogsSectionExpanded [

	^ logsSectionExpanded ifNil: [ true ]
]

{ #category : 'collapsing' }
MCPDashboardPresenter >> isMetricsSectionExpanded [

	^ metricsSectionExpanded ifNil: [ true ]
]

{ #category : 'collapsing' }
MCPDashboardPresenter >> isToolsSectionExpanded [

	^ toolsSectionExpanded ifNil: [ true ]
]

{ #category : 'layout' }
MCPDashboardPresenter >> lifecycleActionsLayout [

	^ SpBoxLayout newLeftToRight
		  add: startButton
		  withConstraints: [ :constraints | constraints width: 110 ];
		  add: stopButton
		  withConstraints: [ :constraints | constraints width: 110 ];
		  add: restartButton
		  withConstraints: [ :constraints | constraints width: 120 ];
		  yourself
]

{ #category : 'private - monitoring' }
MCPDashboardPresenter >> logsForDisplayFrom: logEntries [

	^ logEntries reversed
]

{ #category : 'layout' }
MCPDashboardPresenter >> logsWidgetLayout [

	| widgetLayout |
	widgetLayout := SpBoxLayout newTopToBottom.
	widgetLayout add: logsHeaderButton expand: false.
	self isLogsSectionExpanded ifTrue: [ widgetLayout add: logsTable ].
	^ widgetLayout
]

{ #category : 'layout' }
MCPDashboardPresenter >> metricsWidgetLayout [

	| widgetLayout |
	widgetLayout := SpBoxLayout newTopToBottom.
	widgetLayout add: metricsHeaderButton expand: false.
	self isMetricsSectionExpanded ifTrue: [
		widgetLayout add: metricsTable ].
	^ widgetLayout
]

{ #category : 'updating' }
MCPDashboardPresenter >> modelChanged [

	self refreshView
]

{ #category : 'layout' }
MCPDashboardPresenter >> monitoringControlsLayout [

	| controlsLayout |
	controlsLayout := SpBoxLayout newLeftToRight.
	self
		addPaddedCheckbox: monitoringCheckBox
		width: 190
		to: controlsLayout.
	controlsLayout
		add: refreshButton
		withConstraints: [ :constraints | constraints width: 110 ].
	self
		addPaddedCheckbox: autoRefreshCheckBox
		width: 150
		to: controlsLayout.
	controlsLayout
		add: clearMonitoringButton
		withConstraints: [ :constraints | constraints width: 90 ].
	^ controlsLayout
]

{ #category : 'layout' }
MCPDashboardPresenter >> monitoringHeaderLayout [

	^ SpBoxLayout newTopToBottom
		  add: self monitoringControlsLayout
		  withConstraints: [ :constraints | constraints height: 30 ];
		  yourself
]

{ #category : 'layout' }
MCPDashboardPresenter >> monitoringSectionsLayout [

	self areAllMonitoringSectionsExpanded ifTrue: [
		^ SpPanedLayout newTopToBottom
			  positionOfSlider: 58 percent;
			  first: self metricsWidgetLayout;
			  second: self logsWidgetLayout;
			  yourself ].
	^ self monitoringWidgetsBoxLayout
]

{ #category : 'layout' }
MCPDashboardPresenter >> monitoringWidgetsBoxLayout [

	| widgetLayout |
	widgetLayout := SpBoxLayout newTopToBottom.
	self
		addSectionLayout: self metricsWidgetLayout
		expanded: self isMetricsSectionExpanded
		to: widgetLayout.
	self
		addSectionLayout: self logsWidgetLayout
		expanded: self isLogsSectionExpanded
		to: widgetLayout.
	^ widgetLayout
]

{ #category : 'layout' }
MCPDashboardPresenter >> monitoringWidgetsLayout [

	^ SpBoxLayout newTopToBottom
		  add: self monitoringHeaderLayout expand: false;
		  add: self monitoringSectionsLayout;
		  yourself
]

{ #category : 'actions' }
MCPDashboardPresenter >> observabilityChangedTo: enabled [

	| mcp |
	mcp := self model ifNil: [ ^ self ].
	mcp monitoringEnabled = enabled ifTrue: [ ^ self ].
	mcp monitoringEnabled: enabled.
	self refreshView
]

{ #category : 'private' }
MCPDashboardPresenter >> readPortFromInput [

	| parsedPort trimmedPort |
	trimmedPort := portInput text asString trimBoth.

	trimmedPort isEmpty ifTrue: [ self error: 'Port cannot be empty.' ].

	parsedPort := [ trimmedPort asInteger ]
		              on: Error
		              do: [ :error |
		              self error: 'Port must be a valid integer.' ].

	(parsedPort between: 1 and: 65535) ifFalse: [
		self error: 'Port must be between 1 and 65535.' ].

	^ parsedPort
]

{ #category : 'collapsing' }
MCPDashboardPresenter >> refreshLayoutAfterSectionToggle [

	self layout: self defaultLayout.
	self refreshView
]

{ #category : 'actions' }
MCPDashboardPresenter >> refreshView [

	| mcp tools metrics logs |
	mcp := self model ifNil: [ ^ self ].
	tools := mcp sortedTools.
	metrics := mcp monitoringMetrics.
	logs := mcp monitoringLogs.

	summaryLabel label: self summaryText.
	statusLabel label: ('HTTP: {1} | Listener: {2}' format: {
				 (mcp isRunning
					  ifTrue: [ 'running' ]
					  ifFalse: [ 'stopped' ]).
				 (mcp isListening
					  ifTrue: [ 'listening' ]
					  ifFalse: [ 'not listening' ]) }).
	urlLabel label: 'Endpoint: ' , mcp localUrlString.
	detailsLabel label:
		('Handlers: {1} | Tools: {2} | Debug: {3}' format: {
				 mcp handlersCount asString.
				 tools size asString.
				 (mcp debugMode
					  ifTrue: [ 'enabled' ]
					  ifFalse: [ 'disabled' ]) }).
	portInput text: mcp port asString.
	debugCheckBox state: mcp debugMode.
	toolsHeaderButton label: (self
			 disclosureLabelFor: 'Registered tools'
			 count: tools size
			 expanded: self isToolsSectionExpanded).
	toolsTable items: tools.
	monitoringCheckBox state: mcp monitoringEnabled.
	metricsHeaderButton label: (self
			 disclosureLabelFor: 'Tool metrics'
			 count: metrics size
			 expanded: self isMetricsSectionExpanded).
	metricsTable items: metrics.
	logsHeaderButton label: (self
			 disclosureLabelFor: 'Logs'
			 count: logs size
			 expanded: self isLogsSectionExpanded).
	logsTable items: (self logsForDisplayFrom: logs)
]

{ #category : 'actions' }
MCPDashboardPresenter >> restartServer [

	[ self model restart ]
		on: Error
		do: [ :error | UIManager default alert: error messageText ].

	self refreshView
]

{ #category : 'auto-refresh' }
MCPDashboardPresenter >> shouldAutoRefresh [

	^ self isAutoRefreshEnabled and: [ self isDisplayed ]
]

{ #category : 'auto-refresh' }
MCPDashboardPresenter >> startAutoRefresh [

	self isAutoRefreshProcessRunning ifTrue: [ ^ self ].
	self refreshView.
	autoRefreshProcess := [ self autoRefreshLoop ] forkAt:
		                      Processor userBackgroundPriority
]

{ #category : 'actions' }
MCPDashboardPresenter >> startServer [

	[ self model start ]
		on: Error
		do: [ :error | UIManager default alert: error messageText ].

	self refreshView
]

{ #category : 'auto-refresh' }
MCPDashboardPresenter >> stopAutoRefresh [

	autoRefreshCheckBox ifNotNil: [ autoRefreshCheckBox state: false ].
	self stopAutoRefreshProcess
]

{ #category : 'auto-refresh' }
MCPDashboardPresenter >> stopAutoRefreshProcess [

	| process |
	process := autoRefreshProcess.
	autoRefreshProcess := nil.
	process ifNil: [ ^ self ].
	process isTerminated ifFalse: [ process terminate ]
]

{ #category : 'actions' }
MCPDashboardPresenter >> stopServer [

	[ self model stop ]
		on: Error
		do: [ :error | UIManager default alert: error messageText ].

	self refreshView
]

{ #category : 'private - text' }
MCPDashboardPresenter >> summaryText [

	| mcp |
	mcp := self model.
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'MCP server ';
			  nextPutAll: (mcp isRunning
					   ifTrue: [ 'running' ]
					   ifFalse: [ 'stopped' ]);
			  nextPutAll: ' on port ';
			  print: mcp port ]
]

{ #category : 'api' }
MCPDashboardPresenter >> title [

	^ 'MCP Server Dashboard'
]

{ #category : 'collapsing' }
MCPDashboardPresenter >> toggleLogsSection [

	logsSectionExpanded := self isLogsSectionExpanded not.
	self refreshLayoutAfterSectionToggle
]

{ #category : 'collapsing' }
MCPDashboardPresenter >> toggleMetricsSection [

	metricsSectionExpanded := self isMetricsSectionExpanded not.
	self refreshLayoutAfterSectionToggle
]

{ #category : 'collapsing' }
MCPDashboardPresenter >> toggleToolsSection [

	toolsSectionExpanded := self isToolsSectionExpanded not.
	self refreshLayoutAfterSectionToggle
]

{ #category : 'layout' }
MCPDashboardPresenter >> toolsWidgetLayout [

	| widgetLayout |
	widgetLayout := SpBoxLayout newTopToBottom.
	widgetLayout add: toolsHeaderButton expand: false.
	self isToolsSectionExpanded ifTrue: [ widgetLayout add: toolsTable ].
	^ widgetLayout
]
