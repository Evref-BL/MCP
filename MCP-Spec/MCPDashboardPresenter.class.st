"
Spec presenter used by the inspector for an MCP server object. It shows server state, endpoint configuration, lifecycle controls, and the currently registered tool list.
"
Class {
	#name : 'MCPDashboardPresenter',
	#superclass : 'SpPresenterWithModel',
	#instVars : [
		'summaryLabel',
		'statusLabel',
		'urlLabel',
		'detailsLabel',
		'toolsLabel',
		'portLabel',
		'portInput',
		'debugCheckBox',
		'applyButton',
		'refreshButton',
		'startButton',
		'stopButton',
		'restartButton',
		'toolsTable',
		'monitoringLabel',
		'monitoringCheckBox',
		'monitoringStatusLabel',
		'clearMonitoringButton',
		'metricsLabel',
		'metricsTable',
		'logsLabel',
		'logsTable'
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

{ #category : 'actions' }
MCPDashboardPresenter >> applyConfiguration [

	[
	| newPort |
	newPort := self readPortFromInput.
	self model configurePort: newPort debugMode: debugCheckBox state.
	self model monitoringEnabled: monitoringCheckBox state ]
		on: Error
		do: [ :error | UIManager default alert: error messageText ].

	self refreshView
]

{ #category : 'actions' }
MCPDashboardPresenter >> clearMonitoring [

	self model clearMonitoring.
	self refreshView
]

{ #category : 'initialization' }
MCPDashboardPresenter >> connectPresenters [

	applyButton action: [ self applyConfiguration ].
	refreshButton action: [ self refreshView ].
	startButton action: [ self startServer ].
	stopButton action: [ self stopServer ].
	restartButton action: [ self restartServer ].
	clearMonitoringButton action: [ self clearMonitoring ]
]

{ #category : 'layout' }
MCPDashboardPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: summaryLabel expand: false;
		  add: statusLabel expand: false;
		  add: urlLabel expand: false;
		  add: detailsLabel expand: false;
		  add: (SpBoxLayout newLeftToRight
				   add: portLabel expand: false;
				   add: portInput
				   withConstraints: [ :constraints | constraints width: 90 ];
				   add: debugCheckBox
				   withConstraints: [ :constraints | constraints width: 140 ];
				   add: applyButton
				   withConstraints: [ :constraints | constraints width: 110 ];
				   yourself)
		  withConstraints: [ :constraints | constraints height: 30 ];
		  add: (SpBoxLayout newLeftToRight
				   add: refreshButton
				   withConstraints: [ :constraints | constraints width: 110 ];
				   add: startButton
				   withConstraints: [ :constraints | constraints width: 110 ];
				   add: stopButton
				   withConstraints: [ :constraints | constraints width: 110 ];
				   add: restartButton
				   withConstraints: [ :constraints | constraints width: 120 ];
				   yourself)
		  withConstraints: [ :constraints | constraints height: 30 ];
		  add: toolsLabel expand: false;
		  add: toolsTable
		  withConstraints: [ :constraints | constraints height: 170 ];
		  add: (SpBoxLayout newLeftToRight
				   add: monitoringLabel expand: false;
				   add: monitoringCheckBox
				   withConstraints: [ :constraints | constraints width: 180 ];
				   add: clearMonitoringButton
				   withConstraints: [ :constraints | constraints width: 150 ];
				   yourself)
		  withConstraints: [ :constraints | constraints height: 30 ];
		  add: monitoringStatusLabel expand: false;
		  add: metricsLabel expand: false;
		  add: metricsTable
		  withConstraints: [ :constraints | constraints height: 150 ];
		  add: logsLabel expand: false;
		  add: logsTable
		  withConstraints: [ :constraints | constraints height: 120 ];
		  yourself
]

{ #category : 'api' }
MCPDashboardPresenter >> initialExtent [

	^ 1080 @ 760
]

{ #category : 'initialization' }
MCPDashboardPresenter >> initializePresenters [

	summaryLabel := self instantiate: SpLabelPresenter.
	statusLabel := self instantiate: SpLabelPresenter.
	urlLabel := self instantiate: SpLabelPresenter.
	detailsLabel := self instantiate: SpLabelPresenter.
	toolsLabel := self instantiate: SpLabelPresenter.
	portLabel := self instantiate: SpLabelPresenter.
	portInput := self instantiate: SpTextInputFieldPresenter.
	debugCheckBox := self instantiate: SpCheckBoxPresenter.
	applyButton := self instantiate: SpButtonPresenter.
	refreshButton := self instantiate: SpButtonPresenter.
	startButton := self instantiate: SpButtonPresenter.
	stopButton := self instantiate: SpButtonPresenter.
	restartButton := self instantiate: SpButtonPresenter.
	toolsTable := self newTable.
	monitoringLabel := self instantiate: SpLabelPresenter.
	monitoringCheckBox := self instantiate: SpCheckBoxPresenter.
	monitoringStatusLabel := self instantiate: SpLabelPresenter.
	clearMonitoringButton := self instantiate: SpButtonPresenter.
	metricsLabel := self instantiate: SpLabelPresenter.
	metricsTable := self newTable.
	logsLabel := self instantiate: SpLabelPresenter.
	logsTable := self newTable.

	portLabel label: 'Port:'.
	debugCheckBox label: 'Debug mode'.
	applyButton label: 'Apply'.
	refreshButton label: 'Refresh'.
	startButton label: 'Start'.
	stopButton label: 'Stop'.
	restartButton label: 'Restart'.
	monitoringLabel label: 'Monitoring:'.
	monitoringCheckBox label: 'Extended monitoring'.
	clearMonitoringButton label: 'Clear monitoring'.

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

{ #category : 'updating' }
MCPDashboardPresenter >> modelChanged [

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
	toolsLabel label:
		('Registered tools ({1})' format: { tools size asString }).
	toolsTable items: tools.
	monitoringCheckBox state: mcp monitoringEnabled.
	monitoringStatusLabel label: mcp monitoringStatusText.
	metricsLabel label:
		('Tool call metrics ({1} tools, {2} calls)' format: {
				 metrics size asString.
				 mcp monitoring totalCallCount asString }).
	metricsTable items: metrics.
	logsLabel label:
		('Monitoring log ({1})' format: { logs size asString }).
	logsTable items: logs
]

{ #category : 'actions' }
MCPDashboardPresenter >> restartServer [

	[ self model restart ]
		on: Error
		do: [ :error | UIManager default alert: error messageText ].

	self refreshView
]

{ #category : 'actions' }
MCPDashboardPresenter >> startServer [

	[ self model start ]
		on: Error
		do: [ :error | UIManager default alert: error messageText ].

	self refreshView
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
