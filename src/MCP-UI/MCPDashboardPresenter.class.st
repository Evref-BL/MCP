"
Spec presenter used by the inspector for an MCP server object. It shows the server's state, endpoint and port, and its debug mode; starts, stops and restarts it; and lists every tool the server could run, with whether it has each one and whether tools/list shows it. What the server recorded about its calls is MCPObservabilityPresenter's tab.
"
Class {
	#name : 'MCPDashboardPresenter',
	#superclass : 'SpPresenterWithModel',
	#traits : 'TMCPServerStatusDisplay + TMCPToolTable',
	#classTraits : 'TMCPServerStatusDisplay classTrait + TMCPToolTable classTrait',
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

{ #category : 'accessing' }
MCPDashboardPresenter class >> defaultPreferredExtent [

	^ 1080 @ 760
]

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
	"Apply moves the server to the port in the field. Debug mode takes effect when it is ticked."

	self serverDo: [ :mcp | mcp changePortTo: ((self portFrom: portInput text) ifNil: [ Error signal: self invalidPortText ]) ]
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
	stopButton action: [ self serverDo: [ :mcp | mcp stop ] ].
	restartButton action: [ self serverDo: [ :mcp | mcp restart ] ]
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
	refreshButton := self newRefreshButton.
	startButton := self newStartButton.
	stopButton := self newStopButton.
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
		icon: (self iconNamed: #accept);
		enabled: false.
	restartButton
		label: 'Restart';
		icon: (self iconNamed: #restart).
	self initializeToolsTable
]

{ #category : 'initialization' }
MCPDashboardPresenter >> initializeToolsTable [
	"Enabled is whether the server has the tool at all; Listed is whether tools/list shows it. An unlisted tool is still found by tool_search and still runs."

	toolsTable
		addColumn: self rowIconColumn;
		addColumn: self toolNameColumn;
		addColumn: ((SpCheckBoxTableColumn title: 'Enabled' evaluated: [ :tool | self isToolEnabled: tool ])
				 onActivation: [ :tool | self enableTool: tool ];
				 onDeactivation: [ :tool | self disableTool: tool ];
				 yourself);
		addColumn: ((SpCheckBoxTableColumn title: 'Listed' evaluated: [ :tool | self isToolListed: tool ])
				 onActivation: [ :tool | self listTool: tool ];
				 onDeactivation: [ :tool | self unlistTool: tool ];
				 yourself);
		addColumn: self toolTitleColumn;
		addColumn: self toolDescriptionColumn;
		beResizable.
	self connectToolsTable
]

{ #category : 'initialization' }
MCPDashboardPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter title: self title
]

{ #category : 'updating' }
MCPDashboardPresenter >> isPortChangePending [
	"Apply has something to do only when the field holds a port that is not the one the server is on."

	| mcp |
	mcp := self model ifNil: [ ^ false ].
	^ (self portFrom: portInput text) ifNil: [ false ] ifNotNil: [ :port | port ~= mcp port ]
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
		  add: refreshButton expand: false;
		  yourself
]

{ #category : 'tools' }
MCPDashboardPresenter >> listTool: aTool [
	"Advertising a tool the server does not have adds it, so a listed tool is an enabled one."

	self model advertiseTool: aTool.
	self refreshView
]

{ #category : 'initialization' }
MCPDashboardPresenter >> modelChanged [

	self refreshView
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
	self updateLifecycleButtonsForRunning: isRunning.
	toolsLabel label: (self toolsLabelFor: tools).
	self fitToolsColumnsTo: tools.
	toolsTable items: tools
]

{ #category : 'actions' }
MCPDashboardPresenter >> serverDo: aBlock [
	"Act on the server, alert what stopped it, and show where it left the server."

	[ aBlock value: self model ]
		on: Error
		do: [ :error | UIManager default alert: error mcpMessageText ].
	self refreshView
]

{ #category : 'actions' }
MCPDashboardPresenter >> startServer [

	self serverDo: [ :mcp | mcp start ]
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
	^ String streamContents: [ :stream |
		  stream << 'Tools (' << someTools size printString << ', ' << listed printString << ' listed)' ]
]

{ #category : 'layout' }
MCPDashboardPresenter >> toolsLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 2;
		  add: toolsLabel expand: false;
		  add: toolsTable;
		  yourself
]

{ #category : 'tool table' }
MCPDashboardPresenter >> toolsTable [

	^ toolsTable
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

{ #category : 'updating' }
MCPDashboardPresenter >> updateLifecycleButtonsForRunning: isRunning [

	startButton enabled: isRunning not.
	stopButton enabled: isRunning.
	restartButton enabled: isRunning
]
