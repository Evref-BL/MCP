"
Spec presenter for the call graph of an MCP server: the successive calls its OpenTelemetry spans record, as an object-centric process model whose central object is the tool. It is the third inspector tab of a server, beside its dashboard and its observability, and is only there once MCP-OpenTelemetry is loaded.
"
Class {
	#name : 'MCPCallGraphPresenter',
	#superclass : 'SpPresenterWithModel',
	#instVars : [
		'statusLabel',
		'localSpansCheckBox',
		'refreshButton',
		'clearButton',
		'objectTypeDropList',
		'activitiesLabel',
		'activitiesTable',
		'edgesLabel',
		'edgesTable',
		'flowGraph',
		'graphPresenter',
		'drawing',
		'isSyncingSelection',
		'autoRefreshCheckBox',
		'autoRefreshProcess',
		'lastSignature'
	],
	#category : 'MCP-OpenTelemetry-UI',
	#package : 'MCP-OpenTelemetry-UI'
}

{ #category : 'actions' }
MCPCallGraphPresenter >> activityClickedInGraph: anActivity [
	"A click on a box selects the tool in its table, and none of the arrows'; clicking the selected one again selects nothing."

	self syncingSelectionDo: [
			edgesTable unselectAll.
			anActivity ifNil: [ activitiesTable unselectAll ] ifNotNil: [ activitiesTable selectItem: anActivity ] ]
]

{ #category : 'actions' }
MCPCallGraphPresenter >> activitySelectedInTable [
	"Selecting a tool in its table lights its box in the graph, and drops the selection of an arrow."

	isSyncingSelection == true ifTrue: [ ^ self ].
	self syncingSelectionDo: [
			activitiesTable selectedItem ifNotNil: [ edgesTable unselectAll ].
			drawing ifNotNil: [ :each | each selectActivity: activitiesTable selectedItem ] ]
]

{ #category : 'auto-refresh' }
MCPCallGraphPresenter >> autoRefreshChangedTo: enabled [

	enabled
		ifTrue: [
				self refreshViewForcing: false.
				self startAutoRefresh ]
		ifFalse: [ self stopAutoRefreshProcess ]
]

{ #category : 'auto-refresh' }
MCPCallGraphPresenter >> autoRefreshIntervalSeconds [

	^ 2
]

{ #category : 'auto-refresh' }
MCPCallGraphPresenter >> autoRefreshLoop [

	[
		[ self shouldAutoRefresh ] whileTrue: [
				(Delay forSeconds: self autoRefreshIntervalSeconds) wait.
				self shouldAutoRefresh ifTrue: [ self defer: [ self refreshViewForcing: false ] ] ] ] ensure: [ autoRefreshProcess := nil ]
]

{ #category : 'actions' }
MCPCallGraphPresenter >> clearSpans [

	MCPOpenTelemetryObservabilityBackend localSpanStore clear.
	self refreshView
]

{ #category : 'initialization' }
MCPCallGraphPresenter >> connectPresenters [

	localSpansCheckBox whenChangedDo: [ :enabled | self localSpansChangedTo: enabled ].
	autoRefreshCheckBox whenChangedDo: [ :enabled | self autoRefreshChangedTo: enabled ].
	objectTypeDropList whenSelectedItemChangedDo: [ :type | self refreshView ].
	refreshButton action: [ self refreshView ].
	clearButton action: [ self clearSpans ].
	activitiesTable whenSelectionChangedDo: [ :selection | self activitySelectedInTable ].
	edgesTable whenSelectionChangedDo: [ :selection | self edgeSelectedInTable ]
]

{ #category : 'layout' }
MCPCallGraphPresenter >> controlsLayout [

	^ SpBoxLayout newLeftToRight
		  spacing: 8;
		  vAlignCenter;
		  add: localSpansCheckBox expand: false;
		  add: autoRefreshCheckBox expand: false;
		  add: objectTypeDropList expand: false;
		  add: refreshButton expand: false;
		  add: clearButton expand: false;
		  yourself
]

{ #category : 'updating' }
MCPCallGraphPresenter >> currentFlowGraph [
	"The graph the tables show: of the object type chosen, over the spans kept when it was last refreshed."

	^ flowGraph ifNil: [ flowGraph := MCPOcelFlowGraph ofType: 'tool' in: MCPOcelLog new ]
]

{ #category : 'layout' }
MCPCallGraphPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 6;
		  borderWidth: 8;
		  add: self controlsLayout expand: false;
		  add: statusLabel expand: false;
		  add: self sectionsLayout;
		  yourself
]

{ #category : 'updating' }
MCPCallGraphPresenter >> drawGraph [
	"Draws the graph of the last refresh. Setting the script redraws, so a new block each time; the canvas gets its controller, for zoom and drag, once. The boxes the user dragged keep their places."

	| graph positions |
	graph := flowGraph.
	positions := drawing ifNotNil: [ :previous | previous nodePositions ].
	graphPresenter script: [ :canvas |
			drawing := MCPCallGraphDrawing new
				           flowGraph: graph;
				           initialPositions: positions;
				           onActivityClicked: [ :activity | self activityClickedInGraph: activity ];
				           onEdgeClicked: [ :edge | self edgeClickedInGraph: edge ];
				           drawOn: canvas;
				           yourself.
			canvas controllerInteraction ifNil: [ canvas @ RSCanvasController ] ]
]

{ #category : 'actions' }
MCPCallGraphPresenter >> edgeClickedInGraph: anEdge [

	self syncingSelectionDo: [
			activitiesTable unselectAll.
			anEdge ifNil: [ edgesTable unselectAll ] ifNotNil: [ edgesTable selectItem: anEdge ] ]
]

{ #category : 'actions' }
MCPCallGraphPresenter >> edgeSelectedInTable [
	"Selecting an edge in its table lights its arrow in the graph, and drops the selection of a tool."

	isSyncingSelection == true ifTrue: [ ^ self ].
	self syncingSelectionDo: [
			edgesTable selectedItem ifNotNil: [ activitiesTable unselectAll ].
			drawing ifNotNil: [ :each | each selectEdge: edgesTable selectedItem ] ]
]

{ #category : 'initialization' }
MCPCallGraphPresenter >> initializePresenters [

	localSpansCheckBox := self newCheckBox.
	autoRefreshCheckBox := self newCheckBox.
	objectTypeDropList := self newDropList.
	refreshButton := self newButton.
	clearButton := self newButton.
	statusLabel := self newLabel.
	graphPresenter := self newRoassal.
	activitiesLabel := self newLabel.
	activitiesTable := self newTable.
	edgesLabel := self newLabel.
	edgesTable := self newTable.

	localSpansCheckBox label: 'Keep spans (no export)'.
	autoRefreshCheckBox label: 'Auto-refresh'.
	objectTypeDropList
		items: MCPOcelLog new objectTypes;
		display: [ :type | 'Object: ' , type ].
	refreshButton
		label: 'Refresh';
		icon: (self iconNamed: #refreshCircling).
	clearButton
		label: 'Clear';
		icon: (self iconNamed: #trash).
	self initializeTables
]

{ #category : 'initialization' }
MCPCallGraphPresenter >> initializeTables [

	activitiesTable
		addColumn: (SpStringTableColumn title: 'Tool' evaluated: [ :activity | activity ]);
		addColumn:
			(SpStringTableColumn title: 'Calls' evaluated: [ :activity | (self currentFlowGraph callCountOf: activity) asString ]);
		addColumn:
			(SpStringTableColumn title: 'Errors' evaluated: [ :activity | (self currentFlowGraph errorCountOf: activity) asString ]);
		addColumn: (SpStringTableColumn
				 title: 'Mean ms'
				 evaluated: [ :activity | (self currentFlowGraph meanDurationMillisecondsOf: activity) asFloat printShowingDecimalPlaces: 1 ]);
		beResizable.
	edgesTable
		addColumn: (SpStringTableColumn title: 'From' evaluated: #source);
		addColumn: (SpStringTableColumn title: 'To' evaluated: #target);
		addColumn: (SpStringTableColumn title: 'Cases' evaluated: [ :edge | edge count asString ]);
		addColumn: (SpStringTableColumn title: 'Objects' evaluated: [ :edge | edge objectCount asString ]);
		addColumn:
			(SpStringTableColumn title: 'Mean gap ms' evaluated: [ :edge | edge meanGapMilliseconds asFloat printShowingDecimalPlaces: 1 ]);
		beResizable
]

{ #category : 'initialization' }
MCPCallGraphPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter whenClosedDo: [ self stopAutoRefresh ]
]

{ #category : 'auto-refresh' }
MCPCallGraphPresenter >> isAutoRefreshEnabled [

	^ autoRefreshCheckBox state
]

{ #category : 'auto-refresh' }
MCPCallGraphPresenter >> isAutoRefreshProcessRunning [

	^ autoRefreshProcess notNil and: [ autoRefreshProcess isTerminated not ]
]

{ #category : 'actions' }
MCPCallGraphPresenter >> localSpansChangedTo: enabled [
	"The spans are made by the image's OpenTelemetry providers, which are global, so this turns them on for every server of the image; this one is switched to the OpenTelemetry backend, which makes them, when it records through another."

	| mcp |
	mcp := self model ifNil: [ ^ self ].
	(enabled and: [ (mcp observability isKindOf: MCPOpenTelemetryObservabilityBackend) not ]) ifTrue: [
		mcp useOpenTelemetryObservability ].
	MCPOpenTelemetryObservabilityBackend isLocalSpansEnabled = enabled ifFalse: [
		MCPOpenTelemetryObservabilityBackend useLocalSpans: enabled ].
	self refreshView
]

{ #category : 'initialization' }
MCPCallGraphPresenter >> modelChanged [

	self refreshView
]

{ #category : 'updating' }
MCPCallGraphPresenter >> refreshView [
	"Brings the whole view up to date, whatever changed."

	self refreshViewForcing: true
]

{ #category : 'updating' }
MCPCallGraphPresenter >> refreshViewForcing: aBoolean [
	"Rebuilds the view from the span store. Unforced, as the auto-refresh does, it does nothing when the spans, the object type and the switch are those of the last build, so the selection and the hover are not lost every few seconds for nothing."

	| mcp enabled snapshots type signature log selectedActivity selectedEdge |
	mcp := self model ifNil: [ ^ self ].
	enabled := MCPOpenTelemetryObservabilityBackend isLocalSpansEnabled.
	snapshots := MCPOpenTelemetryObservabilityBackend localSpanStore snapshots.
	type := objectTypeDropList selectedItem ifNil: [ 'tool' ].
	signature := {
		             snapshots size.
		             (snapshots ifNotEmpty: [ snapshots last spanId ]).
		             type.
		             enabled }.
	(aBoolean not and: [ signature = lastSignature ]) ifTrue: [ ^ self ].
	lastSignature := signature.
	selectedActivity := activitiesTable selectedItem.
	selectedEdge := edgesTable selectedItem.
	localSpansCheckBox state: enabled.
	log := MCPOcelLog fromSpanSnapshots: snapshots.
	flowGraph := log flowGraphOfType: type.
	statusLabel label: (self statusFor: mcp enabled: enabled events: log events size).
	activitiesLabel label: (self sectionLabelFor: 'Tools' count: flowGraph activities size type: type).
	edgesLabel label: (self sectionLabelFor: 'Directly follows' count: flowGraph edges size type: type).
	self syncingSelectionDo: [
			activitiesTable items: flowGraph activities.
			edgesTable items: flowGraph edges asArray ].
	self drawGraph.
	self restoreSelectionOfActivity: selectedActivity edge: selectedEdge
]

{ #category : 'updating' }
MCPCallGraphPresenter >> restoreSelectionOfActivity: anActivity edge: anEdge [
	"A rebuild makes new objects: what was selected is found again by name, and shown in the tables and in the new drawing."

	| edge |
	self syncingSelectionDo: [
			(anActivity notNil and: [ flowGraph activities includes: anActivity ])
				ifTrue: [
						activitiesTable selectItem: anActivity.
						drawing ifNotNil: [ :each | each selectActivity: anActivity ] ]
				ifFalse: [
						edge := anEdge ifNotNil: [ flowGraph edgeFrom: anEdge source to: anEdge target ].
						edge ifNotNil: [
								edgesTable selectItem: edge.
								drawing ifNotNil: [ :each | each selectEdge: edge ] ] ] ]
]

{ #category : 'updating' }
MCPCallGraphPresenter >> sectionLabelFor: aTitle count: aCount type: anObjectType [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: aTitle;
				  nextPutAll: ' (';
				  print: aCount;
				  nextPutAll: ') - flow of ';
				  nextPutAll: anObjectType;
				  nextPutAll: ' objects' ]
]

{ #category : 'layout' }
MCPCallGraphPresenter >> sectionLayoutFor: aLabel table: aTable [

	^ SpBoxLayout newTopToBottom
		  spacing: 2;
		  add: aLabel expand: false;
		  add: aTable;
		  yourself
]

{ #category : 'layout' }
MCPCallGraphPresenter >> sectionsLayout [
	"The graph, then the numbers it is drawn from."

	^ SpPanedLayout newTopToBottom
		  positionOfSlider: 55 percent;
		  add: graphPresenter;
		  add: (SpPanedLayout newTopToBottom
				   positionOfSlider: 40 percent;
				   add: (self sectionLayoutFor: activitiesLabel table: activitiesTable);
				   add: (self sectionLayoutFor: edgesLabel table: edgesTable);
				   yourself);
		  yourself
]

{ #category : 'auto-refresh' }
MCPCallGraphPresenter >> shouldAutoRefresh [

	^ self isAutoRefreshEnabled and: [ self isDisplayed ]
]

{ #category : 'auto-refresh' }
MCPCallGraphPresenter >> startAutoRefresh [

	self isAutoRefreshProcessRunning ifTrue: [ ^ self ].
	autoRefreshProcess := [ self autoRefreshLoop ] forkAt: Processor userBackgroundPriority named: 'MCP OCEL auto-refresh'
]

{ #category : 'updating' }
MCPCallGraphPresenter >> statusFor: mcp enabled: enabled events: eventCount [

	^ String streamContents: [ :stream |
			  enabled
				  ifFalse: [ stream nextPutAll: 'Spans are not kept: turn it on to build the call graph.' ]
				  ifTrue: [
						  stream
							  print: MCPOpenTelemetryObservabilityBackend localSpanStore size;
							  nextPutAll: ' spans kept, '.
						  stream
							  print: eventCount;
							  nextPutAll: ' calls'.
						  (mcp observability isKindOf: MCPOpenTelemetryObservabilityBackend) ifFalse: [
							  stream nextPutAll: ' - this server does not record through OpenTelemetry' ] ] ]
]

{ #category : 'auto-refresh' }
MCPCallGraphPresenter >> stopAutoRefresh [
	"The window is closing: nothing is left to refresh."

	self stopAutoRefreshProcess
]

{ #category : 'auto-refresh' }
MCPCallGraphPresenter >> stopAutoRefreshProcess [

	autoRefreshProcess ifNotNil: [ :process | process terminate ].
	autoRefreshProcess := nil
]

{ #category : 'actions' }
MCPCallGraphPresenter >> syncingSelectionDo: aBlock [
	"Selecting in one place selects in the other, which must not select back."

	| wasSyncing |
	wasSyncing := isSyncingSelection == true.
	isSyncingSelection := true.
	aBlock ensure: [ isSyncingSelection := wasSyncing ]
]
