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
		'autoRefreshProcess',
		'toolFilter',
		'selectedTrace',
		'selectedLog',
		'isUpdatingTables',
		'showAllButton'
	],
	#category : 'MCP-UI',
	#package : 'MCP-UI'
}

{ #category : 'accessing' }
MCPObservabilityPresenter class >> defaultPreferredExtent [

	^ 1000 @ 700
]

{ #category : 'instance creation' }
MCPObservabilityPresenter class >> openOn: anMCP [

	^ (self on: anMCP) open
]

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
	metricsTable whenSelectionChangedDo: [ :selection | self metricsSelectionChanged ].
	tracesTable whenSelectionChangedDo: [ :selection | self tracesSelectionChanged ].
	logsTable whenSelectionChangedDo: [ :selection | self logsSelectionChanged ].
	refreshButton action: [ self refreshView ].
	clearButton action: [ self clearObservability ].
	showAllButton action: [ self showAll ]
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
		  add: showAllButton expand: false;
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

{ #category : 'initialization' }
MCPObservabilityPresenter >> initializePresenters [

	observabilityCheckBox := self newCheckBox.
	autoRefreshCheckBox := self newCheckBox.
	refreshButton := self newButton.
	clearButton := self newButton.
	showAllButton := self newButton.
	metricsLabel := self newLabel.
	metricsTable := self newTable.
	tracesLabel := self newLabel.
	tracesTable := self newTable.
	logsLabel := self newLabel.
	logsTable := self newTable.

	observabilityCheckBox label: 'Enable observability'.
	autoRefreshCheckBox label: 'Auto-refresh'.
	refreshButton
		label: 'Refresh';
		icon: (self iconNamed: #refreshCircling).
	clearButton
		label: 'Clear';
		icon: (self iconNamed: #trash).
	showAllButton
		label: 'Show all';
		help: 'Drop the selections that filter the tables'.
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
		title: self title;
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
MCPObservabilityPresenter >> logCallOf: aLogLine [
	"The tool name and call id a log line states, as tool -> id, or nil for a line that states none. The backend logs a call as '<status> tool <name> #<id> in ...', and keeps its lines as plain strings."

	| start nameStart nameEnd idEnd |
	start := aLogLine indexOfSubCollection: ' tool ' startingAt: 1.
	start = 0 ifTrue: [ ^ nil ].
	nameStart := start + 6.
	nameEnd := aLogLine indexOfSubCollection: ' #' startingAt: nameStart.
	nameEnd = 0 ifTrue: [ ^ nil ].
	idEnd := aLogLine indexOf: Character space startingAt: nameEnd + 2.
	idEnd = 0 ifTrue: [ idEnd := aLogLine size + 1 ].
	^ (aLogLine copyFrom: nameStart to: nameEnd - 1) -> (aLogLine copyFrom: nameEnd + 2 to: idEnd - 1)
]

{ #category : 'private' }
MCPObservabilityPresenter >> logLine: aLogLine isForRecord: aRecord [

	^ (MCPLocalObservabilityBackend toolCallOfLogLine: aLogLine)
		  ifNil: [ false ]
		  ifNotNil: [ :call | call key = aRecord toolName and: [ call value = aRecord id printString ] ]
]

{ #category : 'private' }
MCPObservabilityPresenter >> logsAmong: logs [
	"Only the lines of the selected trace's call, or else of the tool selected in the metrics table."

	selectedTrace ifNotNil: [ :trace | ^ logs select: [ :line | self logLine: line isForRecord: trace ] ].
	toolFilter ifNotNil: [ :toolName | ^ logs select: [ :line | (self toolNameOfLog: line) = toolName ] ].
	^ logs
]

{ #category : 'private' }
MCPObservabilityPresenter >> logsForDisplayFrom: logEntries [

	^ logEntries reversed
]

{ #category : 'actions' }
MCPObservabilityPresenter >> logsSelectionChanged [

	isUpdatingTables == true ifTrue: [ ^ self ].
	selectedLog := logsTable selectedItem.
	self selectionChanged
]

{ #category : 'private' }
MCPObservabilityPresenter >> metricsAmong: metrics [
	"Only the tool of the selected trace, or else of the selected log line."

	| toolName |
	toolName := selectedTrace
		            ifNotNil: [ :trace | trace toolName ]
		            ifNil: [ selectedLog ifNotNil: [ :line | self toolNameOfLog: line ] ].
	^ toolName ifNil: [ metrics ] ifNotNil: [ metrics select: [ :stats | stats toolName = toolName ] ]
]

{ #category : 'actions' }
MCPObservabilityPresenter >> metricsSelectionChanged [

	isUpdatingTables == true ifTrue: [ ^ self ].
	toolFilter := metricsTable selectedItem ifNotNil: [ :stats | stats toolName ].
	self selectionChanged
]

{ #category : 'initialization' }
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

{ #category : 'private' }
MCPObservabilityPresenter >> reasonFromSelectedLog [
	"What a selected log line says about the other tables, or nil when none is selected or the line is not about a tool call, in which case it filters nothing."

	^ selectedLog ifNotNil: [ :line |
			  (self toolNameOfLog: line) ifNotNil: [ :toolName |
					  String streamContents: [ :stream |
							  stream
								  nextPutAll: 'log of ';
								  nextPutAll: toolName ] ] ]
]

{ #category : 'updating' }
MCPObservabilityPresenter >> refreshView [

	| mcp |
	mcp := self model ifNil: [ ^ self ].
	observabilityCheckBox state: mcp observabilityEnabled.
	self updateTablesFrom: mcp forcing: true
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

{ #category : 'updating' }
MCPObservabilityPresenter >> sectionLabelFor: aTitle count: shownCount of: totalCount because: aReason [
	"'Title (n)', or 'Title (n of m) - reason' when a selection in another table filters it."

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: aTitle;
				  nextPutAll: ' (';
				  print: shownCount.
			  aReason ifNotNil: [
					  stream
						  nextPutAll: ' of ';
						  print: totalCount ].
			  stream nextPut: $).
			  aReason ifNotNil: [
					  stream
						  nextPutAll: ' - ';
						  nextPutAll: aReason ] ]
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

{ #category : 'actions' }
MCPObservabilityPresenter >> selectionChanged [
	"Selecting a row filters the other two tables to what relates to it; clearing the selection shows them all."

	self model ifNotNil: [ :mcp | self updateTablesFrom: mcp forcing: false ]
]

{ #category : 'updating' }
MCPObservabilityPresenter >> settleSelectionsAmong: metrics traces: traces logs: logs [
	"A selection is kept across refreshes by tool name, record or line, and forgotten once its table no longer shows it, because the data is gone (after Clear, say) or because another selection filters it out. Forgetting one can show another, so this goes on until nothing more is dropped."

	| changed |
	[
		changed := false.
		(toolFilter isNotNil and: [ (self metricsAmong: metrics) noneSatisfy: [ :stats | stats toolName = toolFilter ] ]) ifTrue: [
				toolFilter := nil.
				changed := true ].
		(selectedTrace isNotNil and: [ ((self tracesAmong: traces) includes: selectedTrace) not ]) ifTrue: [
				selectedTrace := nil.
				changed := true ].
		(selectedLog isNotNil and: [ ((self logsAmong: logs) includes: selectedLog) not ]) ifTrue: [
				selectedLog := nil.
				changed := true ].
		changed ] whileTrue
]

{ #category : 'auto-refresh' }
MCPObservabilityPresenter >> shouldAutoRefresh [

	^ self isAutoRefreshEnabled and: [ self isDisplayed ]
]

{ #category : 'actions' }
MCPObservabilityPresenter >> showAll [
	"Spec gives a table no way to drop its selection, and Refresh keeps the filters, so this is how the user gets every row back."

	toolFilter := nil.
	selectedTrace := nil.
	selectedLog := nil.
	self model ifNotNil: [ :mcp | self updateTablesFrom: mcp forcing: true ]
]

{ #category : 'updating' }
MCPObservabilityPresenter >> showLogs: shown of: totalCount forcing: forced [
	"The selected line is put back after the items are replaced."

	| reason |
	reason := selectedTrace
		          ifNotNil: [ :trace |
				          String streamContents: [ :stream |
						          stream
							          nextPutAll: 'call #';
							          print: trace id;
							          nextPutAll: ' of ';
							          nextPutAll: trace toolName ] ]
		          ifNil: [ toolFilter ifNotNil: [ :toolName | 'tool ' , toolName ] ].
	logsLabel label: (self
			 sectionLabelFor: 'Logs'
			 count: shown size
			 of: totalCount
			 because: reason).
	(forced or: [ logsTable items asArray ~= shown asArray ]) ifFalse: [ ^ self ].
	logsTable items: shown.
	selectedLog ifNotNil: [ :line | logsTable selectItem: line ]
]

{ #category : 'updating' }
MCPObservabilityPresenter >> showMetrics: shown of: totalCount forcing: forced [
	"The selected tool is put back by name after the items are replaced."

	| reason |
	reason := selectedTrace
		          ifNotNil: [ :trace |
				          String streamContents: [ :stream |
						          stream
							          nextPutAll: 'trace of ';
							          nextPutAll: trace toolName ] ]
		          ifNil: [ self reasonFromSelectedLog ].
	metricsLabel label: (self
			 sectionLabelFor: 'Metrics'
			 count: shown size
			 of: totalCount
			 because: reason).
	(forced or: [ metricsTable items asArray ~= shown asArray ]) ifFalse: [ ^ self ].
	metricsTable items: shown.
	toolFilter ifNotNil: [ :toolName |
		shown detect: [ :stats | stats toolName = toolName ] ifFound: [ :stats | metricsTable selectItem: stats ] ]
]

{ #category : 'updating' }
MCPObservabilityPresenter >> showTraces: shown of: totalCount forcing: forced [
	"The selected trace is put back after the items are replaced."

	| reason |
	reason := toolFilter
		          ifNotNil: [ :toolName |
				          String streamContents: [ :stream |
						          stream
							          nextPutAll: 'tool ';
							          nextPutAll: toolName ] ]
		          ifNil: [ self reasonFromSelectedLog ].
	tracesLabel label: (self
			 sectionLabelFor: 'Traces'
			 count: shown size
			 of: totalCount
			 because: reason).
	(forced or: [ tracesTable items asArray ~= shown asArray ]) ifFalse: [ ^ self ].
	tracesTable items: shown.
	selectedTrace ifNotNil: [ :trace | tracesTable selectItem: trace ]
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
MCPObservabilityPresenter >> toolNameOfLog: aLogLine [
	"Nil for a line that is not about a tool call, such as 'Observability cleared'."

	^ (MCPLocalObservabilityBackend toolCallOfLogLine: aLogLine) ifNotNil: [ :call | call key ]
]

{ #category : 'private' }
MCPObservabilityPresenter >> tracesAmong: traces [
	"Only the tool selected in the metrics table, or else the tool of the selected log line."

	| toolName |
	toolName := toolFilter ifNil: [ selectedLog ifNotNil: [ :line | self toolNameOfLog: line ] ].
	^ toolName ifNil: [ traces ] ifNotNil: [ traces select: [ :record | record toolName = toolName ] ]
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

{ #category : 'actions' }
MCPObservabilityPresenter >> tracesSelectionChanged [

	isUpdatingTables == true ifTrue: [ ^ self ].
	selectedTrace := tracesTable selectedItem.
	self selectionChanged
]

{ #category : 'updating' }
MCPObservabilityPresenter >> updateTablesFrom: mcp forcing: forced [
	"What is selected in one table filters the other two, and never its own. A table is rebuilt only when what it shows changed, unless forced, so that a click does not reset the table it was made in; the data of a refresh moves even when the same objects are shown."

	| metrics traces logs |
	metrics := mcp observabilityMetrics.
	traces := mcp observabilityTraces.
	logs := self logsForDisplayFrom: mcp observabilityLogs.
	self settleSelectionsAmong: metrics traces: traces logs: logs.
	isUpdatingTables := true.
	[
		self showMetrics: (self metricsAmong: metrics) of: metrics size forcing: forced.
		self showTraces: (self tracesAmong: traces) of: traces size forcing: forced.
		self showLogs: (self logsAmong: logs) of: logs size forcing: forced ] ensure: [ isUpdatingTables := false ]
]
