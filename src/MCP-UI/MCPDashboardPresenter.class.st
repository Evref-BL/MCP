"
Spec presenter used by the inspector for an MCP server object. It shows server state, endpoint configuration, lifecycle controls, registered tools, and observability data. The observability area separates aggregate tool metrics, trace records for errors and outliers, and recent logs. The main dashboard widgets are arranged with draggable splitters and disclosure-style section headers so the tools, metrics, traces, and log tables can be resized or collapsed while inspecting the server. Observability data can be refreshed manually or through the auto-refresh checkbox while the presenter is displayed.
"
Class {
	#name : 'MCPDashboardPresenter',
	#superclass : 'SpPresenterWithModel',
	#traits : 'TMCPServerStatusDisplay',
	#classTraits : 'TMCPServerStatusDisplay classTrait',
	#instVars : [
		'statusIcon',
		'statusLabel',
		'statusValueLabel',
		'urlLabel',
		'portLabel',
		'portInput',
		'debugCheckBox',
		'applyButton',
		'refreshButton',
		'startButton',
		'stopButton',
		'restartButton',
		'toolsLabel',
		'toolsTable'
	],
	#category : 'MCP-UI',
	#package : 'MCP-UI'
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
MCPDashboardPresenter >> applyPort [
	"Apply does one thing now: it moves the server to the port in the field. Debug mode takes effect when it is ticked."

	[ self model changePortTo: self readPortFromInput ]
		on: Error
		do: [ :error | UIManager default alert: error messageText ].
	self refreshView
]

{ #category : 'layout' }
MCPDashboardPresenter >> configurationLayout [
	"Apply sits against the field it applies, and the checkbox that needs no applying comes after both."

	^ SpBoxLayout newLeftToRight
		  spacing: 8;
		  vAlignCenter;
		  add: portLabel expand: false;
		  add: portInput withConstraints: [ :constraints | constraints width: 90 ];
		  add: applyButton expand: false;
		  add: debugCheckBox expand: false;
		  yourself
]

{ #category : 'initialization' }
MCPDashboardPresenter >> connectPresenters [

	portInput
		whenTextChangedDo: [ self updateApplyButton ];
		whenSubmitDo: [ self applyPort ].
	applyButton action: [ self applyPort ].
	debugCheckBox whenChangedDo: [ :enabled | self debugModeChangedTo: enabled ].
	refreshButton action: [ self refreshView ].
	startButton action: [ self startServer ].
	stopButton action: [ self stopServer ].
	restartButton action: [ self restartServer ]
]

{ #category : 'actions' }
MCPDashboardPresenter >> debugModeChangedTo: enabled [

	| mcp |
	mcp := self model ifNil: [ ^ self ].
	mcp debugMode = enabled ifTrue: [ ^ self ].
	mcp debugMode: enabled
]

{ #category : 'defaults' }
MCPDashboardPresenter >> debugModeHelpText [

	^ 'When enabled, server and JSON-RPC errors pass through to Pharo so a debugger can open instead of returning normal error responses. Use this while debugging tool or server failures.'
]

{ #category : 'layout' }
MCPDashboardPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 6;
		  borderWidth: 8;
		  add: self headerLayout expand: false;
		  add: self configurationLayout expand: false;
		  add: self lifecycleActionsLayout expand: false;
		  add: self toolsLayout;
		  yourself
]

{ #category : 'tools' }
MCPDashboardPresenter >> disableTool: aTool [

	self model removeTool: aTool name.
	self refreshView
]

{ #category : 'tools' }
MCPDashboardPresenter >> enableTool: aTool [

	self model addTool: aTool.
	self refreshView
]

{ #category : 'layout' }
MCPDashboardPresenter >> headerLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 0;
		  add: self statusRowLayout expand: false;
		  add: urlLabel expand: false;
		  yourself
]

{ #category : 'api' }
MCPDashboardPresenter >> initialExtent [

	^ 1080 @ 760
]

{ #category : 'initialization' }
MCPDashboardPresenter >> initializePresenters [

	statusIcon := self newImage.
	statusLabel := self newLabel.
	statusValueLabel := self newLabel.
	urlLabel := self newLabel.
	portLabel := self newLabel.
	portInput := self newTextInput.
	debugCheckBox := self newCheckBox.
	applyButton := self newButton.
	refreshButton := self newButton.
	startButton := self newButton.
	stopButton := self newButton.
	restartButton := self newButton.
	toolsLabel := self newLabel.
	toolsTable := self newTable.

	statusLabel label: 'Status:'.
	portLabel label: 'Port:'.
	portInput help: 'The port the server listens on. Apply moves it there, restarting it if it is running.'.
	debugCheckBox
		label: 'Debug mode';
		help: self debugModeHelpText.
	applyButton
		label: 'Apply';
		enabled: false.
	refreshButton label: 'Refresh'.
	startButton label: 'Start'.
	stopButton label: 'Stop'.
	restartButton label: 'Restart'.
	self initializeToolsTable
]

{ #category : 'initialization' }
MCPDashboardPresenter >> initializeToolsTable [
	"Enabled is whether the server has the tool at all; Listed is whether tools/list shows it. An unlisted tool is still found by tool_search and still runs."

	toolsTable
		addColumn: (SpStringTableColumn title: 'Tool' evaluated: #name);
		addColumn: ((SpCheckBoxTableColumn title: 'Enabled' evaluated: [ :tool | self isToolEnabled: tool ])
				 onActivation: [ :tool | self enableTool: tool ];
				 onDeactivation: [ :tool | self disableTool: tool ];
				 width: 70;
				 yourself);
		addColumn: ((SpCheckBoxTableColumn title: 'Listed' evaluated: [ :tool | self isToolListed: tool ])
				 onActivation: [ :tool | self listTool: tool ];
				 onDeactivation: [ :tool | self unlistTool: tool ];
				 width: 70;
				 yourself);
		addColumn: (SpStringTableColumn title: 'Title' evaluated: [ :tool | tool title ifNil: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Description' evaluated: [ :tool | tool description ifNil: [ '' ] ]);
		beResizable
]

{ #category : 'initialization' }
MCPDashboardPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: self title;
		initialExtent: self initialExtent
]

{ #category : 'updating' }
MCPDashboardPresenter >> isPortChangePending [
	"Apply has something to do only when the field holds a port that is not the one the server is on."

	| mcp typed |
	mcp := self model ifNil: [ ^ false ].
	typed := [ self readPortFromInput ]
		         on: Error
		         do: [ :error | ^ false ].
	^ typed ~= mcp port
]

{ #category : 'tools' }
MCPDashboardPresenter >> isToolEnabled: aTool [

	^ self model toolRegistry includesToolNamed: aTool name
]

{ #category : 'tools' }
MCPDashboardPresenter >> isToolListed: aTool [

	^ self model toolRegistry isToolAdvertisedNamed: aTool name
]

{ #category : 'layout' }
MCPDashboardPresenter >> lifecycleActionsLayout [

	^ SpBoxLayout newLeftToRight
		  spacing: 6;
		  add: startButton expand: false;
		  add: stopButton expand: false;
		  add: restartButton expand: false;
		  yourself
]

{ #category : 'tools' }
MCPDashboardPresenter >> listTool: aTool [
	"Advertising a tool the server does not have adds it, so a listed tool is an enabled one."

	self model advertiseTool: aTool.
	self refreshView
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
		              do: [ :error | self error: 'Port must be a valid integer.' ].

	(parsedPort between: 1 and: 65535) ifFalse: [ self error: 'Port must be between 1 and 65535.' ].

	^ parsedPort
]

{ #category : 'updating' }
MCPDashboardPresenter >> refreshView [

	| mcp isRunning isListening tools |
	mcp := self model ifNil: [ ^ self ].
	isRunning := mcp isRunning.
	isListening := mcp isListening.
	tools := self toolRows.

	statusIcon
		image: (self iconNamed: (self serverStatusIconNameForRunning: isRunning listening: isListening));
		help: (self serverStatusLabelForRunning: isRunning listening: isListening).
	statusValueLabel label: (self serverStatusValueForRunning: isRunning listening: isListening).
	urlLabel label: 'Endpoint: ' , mcp localUrlString.
	portInput text: mcp port asString.
	debugCheckBox state: mcp debugMode.
	self updateApplyButton.
	toolsLabel label: (self toolsLabelFor: tools).
	toolsTable items: tools
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

{ #category : 'layout' }
MCPDashboardPresenter >> statusRowLayout [

	^ SpBoxLayout newLeftToRight
		  spacing: 6;
		  vAlignCenter;
		  add: statusLabel expand: false;
		  add: statusIcon withConstraints: [ :constraints |
				  constraints
					  width: 18;
					  height: 18 ];
		  add: statusValueLabel expand: false;
		  yourself
]

{ #category : 'actions' }
MCPDashboardPresenter >> stopServer [

	[ self model stop ]
		on: Error
		do: [ :error | UIManager default alert: error messageText ].

	self refreshView
]

{ #category : 'api' }
MCPDashboardPresenter >> title [

	^ 'MCP Server Dashboard'
]

{ #category : 'tools' }
MCPDashboardPresenter >> toolRows [
	"Every tool the server could run, not only the ones it lists. A tool removed on purpose stays in the table so it can be put back; rediscovery never brings it back on its own."

	| registry absent |
	registry := self model toolRegistry.
	absent := registry autoRegisteringClasses
		          reject: [ :each | registry includesToolNamed: each toolName ]
		          thenCollect: [ :each | each new ].
	^ registry tools asArray , absent asArray sort: [ :left :right | left name <= right name ]
]

{ #category : 'updating' }
MCPDashboardPresenter >> toolsLabelFor: someTools [

	| listed |
	listed := someTools count: [ :each | self isToolListed: each ].
	^ 'Tools (' , someTools size printString , ', ' , listed printString , ' listed)'
]

{ #category : 'layout' }
MCPDashboardPresenter >> toolsLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 2;
		  add: toolsLabel expand: false;
		  add: toolsTable;
		  yourself
]

{ #category : 'tools' }
MCPDashboardPresenter >> unlistTool: aTool [

	self model unadvertiseTool: aTool name.
	self refreshView
]

{ #category : 'updating' }
MCPDashboardPresenter >> updateApplyButton [

	applyButton enabled: self isPortChangePending
]
