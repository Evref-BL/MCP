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
		'graphPresenter'
	],
	#category : 'MCP-OpenTelemetry-UI',
	#package : 'MCP-OpenTelemetry-UI'
}

{ #category : 'actions' }
MCPCallGraphPresenter >> clearSpans [

	MCPOpenTelemetryObservabilityBackend localSpanStore clear.
	self refreshView
]

{ #category : 'initialization' }
MCPCallGraphPresenter >> connectPresenters [

	localSpansCheckBox whenChangedDo: [ :enabled | self localSpansChangedTo: enabled ].
	objectTypeDropList whenSelectedItemChangedDo: [ :type | self refreshView ].
	refreshButton action: [ self refreshView ].
	clearButton action: [ self clearSpans ]
]

{ #category : 'layout' }
MCPCallGraphPresenter >> controlsLayout [

	^ SpBoxLayout newLeftToRight
		  spacing: 8;
		  vAlignCenter;
		  add: localSpansCheckBox expand: false;
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
	"Draws the graph of the last refresh. Setting the script redraws, so a new block each time; the canvas gets its controller, for zoom and drag, once."

	| graph |
	graph := flowGraph.
	graphPresenter script: [ :canvas |
			MCPCallGraphDrawing drawFlowGraph: graph on: canvas.
			canvas controllerInteraction ifNil: [ canvas @ RSCanvasController ] ]
]

{ #category : 'initialization' }
MCPCallGraphPresenter >> initializePresenters [

	localSpansCheckBox := self newCheckBox.
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

{ #category : 'actions' }
MCPCallGraphPresenter >> localSpansChangedTo: enabled [
	"The spans are made by the image's OpenTelemetry providers, which are global, so this turns them on for every server of the image; this one is switched to the OpenTelemetry backend, which makes them, when it records through another."

	| mcp |
	mcp := self model ifNil: [ ^ self ].
	MCPOpenTelemetryObservabilityBackend isLocalSpansEnabled = enabled ifTrue: [ ^ self ].
	(enabled and: [ (mcp observability isKindOf: MCPOpenTelemetryObservabilityBackend) not ]) ifTrue: [
		mcp useOpenTelemetryObservability ].
	MCPOpenTelemetryObservabilityBackend useLocalSpans: enabled.
	self refreshView
]

{ #category : 'initialization' }
MCPCallGraphPresenter >> modelChanged [

	self refreshView
]

{ #category : 'updating' }
MCPCallGraphPresenter >> refreshView [

	| mcp enabled log type |
	mcp := self model ifNil: [ ^ self ].
	enabled := MCPOpenTelemetryObservabilityBackend isLocalSpansEnabled.
	localSpansCheckBox state: enabled.
	log := MCPOcelLog fromSpanSnapshots: MCPOpenTelemetryObservabilityBackend localSpanStore snapshots.
	type := objectTypeDropList selectedItem ifNil: [ 'tool' ].
	flowGraph := log flowGraphOfType: type.
	statusLabel label: (self statusFor: mcp enabled: enabled events: log events size).
	activitiesLabel label: (self sectionLabelFor: 'Tools' count: flowGraph activities size type: type).
	activitiesTable items: flowGraph activities.
	edgesLabel label: (self sectionLabelFor: 'Directly follows' count: flowGraph edges size type: type).
	edgesTable items: flowGraph edges asArray.
	self drawGraph
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
