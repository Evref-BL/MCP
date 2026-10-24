"
Spec presenter for what an MCP server recorded about itself: per-tool timing metrics, trace records for errors and outliers, and recent logs.

It is the second inspector tab of a server, beside the dashboard that runs it. The three tables share the tab through splitters rather than collapsing, since the tab is theirs alone. Auto-refresh belongs here because this is the only part of a server whose data moves on its own.
"
Class {
	#name : 'MCPObservabilityPresenter',
	#superclass : 'SpPresenterWithModel',
	#instVars : [
		'observabilityCheckBox',
		'autoRefreshCheckBox',
		'refreshButton',
		'clearButton',
		'metricsLabel',
		'metricsTable',
		'tracesLabel',
		'tracesTable',
		'logsLabel',
		'logsTable',
		'autoRefreshProcess'
	],
	#category : 'MCP-UI',
	#package : 'MCP-UI'
}

{ #category : 'auto-refresh' }
MCPObservabilityPresenter >> autoRefreshChangedTo: enabled [

	enabled
		ifTrue: [ self startAutoRefresh ]
		ifFalse: [ self stopAutoRefreshProcess ]
]

{ #category : 'auto-refresh' }
MCPObservabilityPresenter >> autoRefreshIntervalSeconds [

	^ 2
]

{ #category : 'auto-refresh' }
MCPObservabilityPresenter >> autoRefreshLoop [

	[
		[ self shouldAutoRefresh ] whileTrue: [
				(Delay forSeconds: self autoRefreshIntervalSeconds) wait.
				self shouldAutoRefresh ifTrue: [ self defer: [ self refreshView ] ] ] ] ensure: [ autoRefreshProcess := nil ]
]

{ #category : 'actions' }
MCPObservabilityPresenter >> clearObservability [

	self model clearObservability.
	self refreshView
]

{ #category : 'initialization' }
MCPObservabilityPresenter >> connectPresenters [

	observabilityCheckBox whenChangedDo: [ :enabled | self observabilityChangedTo: enabled ].
	autoRefreshCheckBox whenChangedDo: [ :enabled | self autoRefreshChangedTo: enabled ].
	refreshButton action: [ self refreshView ].
	clearButton action: [ self clearObservability ]
]

{ #category : 'layout' }
MCPObservabilityPresenter >> controlsLayout [

	^ SpBoxLayout newLeftToRight
		  spacing: 8;
		  vAlignCenter;
		  add: observabilityCheckBox expand: false;
		  add: refreshButton expand: false;
		  add: autoRefreshCheckBox expand: false;
		  add: clearButton expand: false;
		  yourself
]

{ #category : 'layout' }
MCPObservabilityPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 6;
		  borderWidth: 8;
		  add: self controlsLayout expand: false;
		  add: self sectionsLayout;
		  yourself
]

{ #category : 'api' }
MCPObservabilityPresenter >> initialExtent [

	^ 1000 @ 700
]

{ #category : 'initialization' }
MCPObservabilityPresenter >> initializePresenters [

	observabilityCheckBox := self newCheckBox.
	autoRefreshCheckBox := self newCheckBox.
	refreshButton := self newButton.
	clearButton := self newButton.
	metricsLabel := self newLabel.
	metricsTable := self newTable.
	tracesLabel := self newLabel.
	tracesTable := self newTable.
	logsLabel := self newLabel.
	logsTable := self newTable.

	observabilityCheckBox label: 'Enable observability'.
	autoRefreshCheckBox label: 'Auto-refresh'.
	refreshButton label: 'Refresh'.
	clearButton label: 'Clear'.
	self initializeTables
]

{ #category : 'initialization' }
MCPObservabilityPresenter >> initializeTables [

	metricsTable
		addColumn: (SpStringTableColumn title: 'Tool' evaluated: #toolName);
		addColumn: (SpStringTableColumn title: 'Calls' evaluated: [ :stats | stats callCount asString ]);
		addColumn: (SpStringTableColumn title: 'Errors' evaluated: [ :stats | stats errorCount asString ]);
		addColumn: (SpStringTableColumn title: 'Avg ms' evaluated: #displayAverageMilliseconds);
		addColumn: (SpStringTableColumn title: 'Min ms' evaluated: #displayMinMilliseconds);
		addColumn: (SpStringTableColumn title: 'Max ms' evaluated: #displayMaxMilliseconds);
		addColumn: (SpStringTableColumn title: 'Last ms' evaluated: #displayLastMilliseconds);
		beResizable.
	tracesTable
		addColumn: (SpStringTableColumn title: 'Status' evaluated: #status);
		addColumn: (SpStringTableColumn title: 'Tool' evaluated: #toolName);
		addColumn: (SpStringTableColumn title: 'Duration ms' evaluated: #displayDurationMilliseconds);
		addColumn: (SpStringTableColumn title: 'Output bytes' evaluated: [ :record | record outputByteCount asString ]);
		addColumn: (SpStringTableColumn title: 'Details' evaluated: #displaySummary);
		addColumn: (SpStringTableColumn title: 'Started' evaluated: #displayStartedAt);
		contextMenu: [ self tracesContextMenu ];
		beResizable.
	logsTable
		addColumn: (SpStringTableColumn title: 'Log' evaluated: [ :line | line ]);
		beResizable
]

{ #category : 'initialization' }
MCPObservabilityPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: 'MCP Observability';
		initialExtent: self initialExtent;
		whenClosedDo: [ self stopAutoRefresh ]
]

{ #category : 'actions' }
MCPObservabilityPresenter >> inspectSelectedTraceRecord [

	tracesTable selectedItem ifNotNil: [ :record | record inspect ]
]

{ #category : 'auto-refresh' }
MCPObservabilityPresenter >> isAutoRefreshEnabled [

	^ autoRefreshCheckBox isNotNil and: [ autoRefreshCheckBox state ]
]

{ #category : 'auto-refresh' }
MCPObservabilityPresenter >> isAutoRefreshProcessRunning [

	^ autoRefreshProcess isNotNil and: [ autoRefreshProcess isTerminated not ]
]

{ #category : 'private' }
MCPObservabilityPresenter >> logsForDisplayFrom: logEntries [

	^ logEntries reversed
]

{ #category : 'updating' }
MCPObservabilityPresenter >> modelChanged [

	self refreshView
]

{ #category : 'actions' }
MCPObservabilityPresenter >> observabilityChangedTo: enabled [

	| mcp |
	mcp := self model ifNil: [ ^ self ].
	mcp observabilityEnabled = enabled ifTrue: [ ^ self ].
	mcp observabilityEnabled: enabled.
	self refreshView
]

{ #category : 'updating' }
MCPObservabilityPresenter >> refreshView [

	| mcp metrics traces logs |
	mcp := self model ifNil: [ ^ self ].
	metrics := mcp observabilityMetrics.
	traces := mcp observabilityTraces.
	logs := mcp observabilityLogs.

	observabilityCheckBox state: mcp observabilityEnabled.
	metricsLabel label: (self sectionLabelFor: 'Metrics' count: metrics size).
	metricsTable items: metrics.
	tracesLabel label: (self sectionLabelFor: 'Traces' count: traces size).
	tracesTable items: traces.
	logsLabel label: (self sectionLabelFor: 'Logs' count: logs size).
	logsTable items: (self logsForDisplayFrom: logs)
]

{ #category : 'updating' }
MCPObservabilityPresenter >> sectionLabelFor: aTitle count: aCount [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: aTitle;
				  nextPutAll: ' (';
				  print: aCount;
				  nextPut: $) ]
]

{ #category : 'layout' }
MCPObservabilityPresenter >> sectionLayoutFor: aLabel table: aTable [

	^ SpBoxLayout newTopToBottom
		  spacing: 2;
		  add: aLabel expand: false;
		  add: aTable;
		  yourself
]

{ #category : 'layout' }
MCPObservabilityPresenter >> sectionsLayout [
	"Splitters rather than collapsing: the tab is theirs alone, so what one section needs it can take from the others."

	^ SpPanedLayout newTopToBottom
		  positionOfSlider: 40 percent;
		  add: (self sectionLayoutFor: metricsLabel table: metricsTable);
		  add: (SpPanedLayout newTopToBottom
				   positionOfSlider: 50 percent;
				   add: (self sectionLayoutFor: tracesLabel table: tracesTable);
				   add: (self sectionLayoutFor: logsLabel table: logsTable);
				   yourself);
		  yourself
]

{ #category : 'auto-refresh' }
MCPObservabilityPresenter >> shouldAutoRefresh [

	^ self isAutoRefreshEnabled and: [ self isDisplayed ]
]

{ #category : 'auto-refresh' }
MCPObservabilityPresenter >> startAutoRefresh [

	self isAutoRefreshProcessRunning ifTrue: [ ^ self ].
	self refreshView.
	autoRefreshProcess := [ self autoRefreshLoop ] forkAt: Processor userBackgroundPriority
]

{ #category : 'auto-refresh' }
MCPObservabilityPresenter >> stopAutoRefresh [

	autoRefreshCheckBox ifNotNil: [ autoRefreshCheckBox state: false ].
	self stopAutoRefreshProcess
]

{ #category : 'auto-refresh' }
MCPObservabilityPresenter >> stopAutoRefreshProcess [

	| process |
	process := autoRefreshProcess.
	autoRefreshProcess := nil.
	process ifNil: [ ^ self ].
	process isTerminated ifFalse: [ process terminate ]
]

{ #category : 'api' }
MCPObservabilityPresenter >> title [

	^ 'MCP Observability'
]

{ #category : 'private' }
MCPObservabilityPresenter >> tracesContextMenu [

	^ self newMenu
		  addGroup: [ :group |
				  group addItem: [ :item |
							  item
								  name: 'Inspect';
								  description: 'Inspect the selected trace record';
								  enabled: [ tracesTable selectedItem isNotNil ];
								  action: [ self inspectSelectedTraceRecord ] ] ];
		  yourself
]
