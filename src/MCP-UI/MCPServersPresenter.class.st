"
Spec presenter listing the MCP servers an image holds, with their port, state, endpoint and tool count.

It answers the question an image cannot otherwise be asked: is anything running, on which port, and is the port a client is configured for held by a server that was forgotten. Selecting a server starts or stops it, or opens its dashboard; the port field creates and starts a new one, defaulting to 0 so the operating system picks a free port instead of colliding.

The list comes from `MCP allServers`, so nothing registers servers and nothing retains them. While the window is open it holds the servers it listed, and lets go of them when it closes.
"
Class {
	#name : 'MCPServersPresenter',
	#superclass : 'SpPresenter',
	#traits : 'TMCPServerStatusDisplay',
	#classTraits : 'TMCPServerStatusDisplay classTrait',
	#instVars : [
		'serversTable',
		'portInput',
		'newButton',
		'startButton',
		'stopButton',
		'dashboardButton',
		'refreshButton',
		'messageLabel',
		'portLabel'
	],
	#category : 'MCP-UI',
	#package : 'MCP-UI'
}

{ #category : 'world menu' }
MCPServersPresenter class >> menuCommandOn: aBuilder [

	<worldMenu>
	(aBuilder item: 'MCP Servers')
		action: [ self open ];
		order: 40;
		parent: #Tools;
		help: 'List the MCP servers this image holds, start and stop them, and open their dashboards.';
		iconName: #glamorousTable
]

{ #category : 'instance creation' }
MCPServersPresenter class >> open [

	^ self new open
]

{ #category : 'layout' }
MCPServersPresenter >> actionsLayout [
	"No width constraint on a button: one makes Spec draw it without its label."

	^ SpBoxLayout newLeftToRight
		  spacing: 6;
		  add: startButton expand: false;
		  add: stopButton expand: false;
		  add: dashboardButton expand: false;
		  add: refreshButton expand: false;
		  yourself
]

{ #category : 'testing' }
MCPServersPresenter >> canStartSelectedServer [

	^ serversTable selectedItem ifNil: [ false ] ifNotNil: [ :server | server isRunning not ]
]

{ #category : 'testing' }
MCPServersPresenter >> canStopSelectedServer [

	^ serversTable selectedItem ifNil: [ false ] ifNotNil: [ :server | server isRunning ]
]

{ #category : 'initialization' }
MCPServersPresenter >> connectPresenters [

	serversTable whenSelectionChangedDo: [ self updateActionButtons ].
	serversTable whenActivatedDo: [ :selection | self openDashboard ].
	newButton action: [ self createServer ].
	startButton action: [ self startSelectedServer ].
	stopButton action: [ self stopSelectedServer ].
	dashboardButton action: [ self openDashboard ].
	refreshButton action: [ self refreshView ].
	self refreshView
]

{ #category : 'actions' }
MCPServersPresenter >> copySelectedEndpoint [

	serversTable selectedItem ifNotNil: [ :server |
			Clipboard clipboardText: server localUrlString.
			self showMessage: (String streamContents: [ :stream | stream << 'Copied ' << server localUrlString << '.' ]) ]
]

{ #category : 'actions' }
MCPServersPresenter >> createServer [
	"Create and start in one step. A server nothing refers to is garbage, so one that was only created would be gone by the next refresh."

	| port server |
	self showMessage: ''.
	port := self requestedPort ifNil: [ ^ self showMessage: 'Enter a port between 0 and 65535, or 0 for a free one.' ].
	server := self newServerOnPort: port.
	[ server start ]
		on: Error
		do: [ :error |
				server stop.
				^ self showMessage: error messageText ].
	self refreshView.
	serversTable selectItem: server.
	self showMessage: (String streamContents: [ :stream | stream << 'Started a server on port ' << server port asString << '.' ])
]

{ #category : 'layout' }
MCPServersPresenter >> creationLayout [

	^ SpBoxLayout newLeftToRight
		  spacing: 6;
		  vAlignCenter;
		  add: portLabel expand: false;
		  add: portInput withConstraints: [ :constraints | constraints width: 90 ];
		  add: newButton expand: false;
		  yourself
]

{ #category : 'layout' }
MCPServersPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 6;
		  borderWidth: 8;
		  add: serversTable;
		  add: self actionsLayout expand: false;
		  add: self creationLayout expand: false;
		  add: messageLabel expand: false;
		  yourself
]

{ #category : 'testing' }
MCPServersPresenter >> hasSelectedServer [

	^ serversTable selectedItem isNotNil
]

{ #category : 'api' }
MCPServersPresenter >> initialExtent [

	^ 760 @ 420
]

{ #category : 'initialization' }
MCPServersPresenter >> initializePresenters [

	serversTable := self newTable.
	portLabel := self newLabel.
	portInput := self newTextInput.
	newButton := self newButton.
	startButton := self newButton.
	stopButton := self newButton.
	dashboardButton := self newButton.
	refreshButton := self newButton.
	messageLabel := self newLabel.

	portLabel label: 'New server on port:'.
	portInput
		text: '0';
		help: self portHelpText.
	newButton
		label: 'New server';
		help: self portHelpText.
	startButton label: 'Start'.
	stopButton label: 'Stop'.
	dashboardButton label: 'Dashboard'.
	refreshButton label: 'Refresh'.
	self initializeServersTable
]

{ #category : 'initialization' }
MCPServersPresenter >> initializeServersTable [

	serversTable
		addColumn: ((SpImageTableColumn evaluated: [ :server | self iconNamed: (self serverStatusIconNameFor: server) ])
				 width: 24;
				 yourself);
		addColumn: (SpStringTableColumn title: 'Status' evaluated: [ :server | self serverStatusValueFor: server ]);
		addColumn: (SpStringTableColumn title: 'Port' evaluated: [ :server | server port asString ]);
		addColumn: (SpStringTableColumn title: 'Endpoint' evaluated: [ :server | server localUrlString ]);
		addColumn: (SpStringTableColumn title: 'Tools' evaluated: [ :server | server sortedTools size asString ]);
		contextMenu: self serversContextMenu;
		beResizable
]

{ #category : 'initialization' }
MCPServersPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: 'MCP Servers';
		initialExtent: self initialExtent
]

{ #category : 'actions' }
MCPServersPresenter >> inspectSelectedServer [

	serversTable selectedItem ifNotNil: [ :server | server inspect ]
]

{ #category : 'accessing' }
MCPServersPresenter >> messageText [

	^ messageLabel label
]

{ #category : 'actions' }
MCPServersPresenter >> newServerOnPort: aPortNumber [
	"Where a new server comes from, so a subclass can configure one of its own."

	^ MCP new
		  port: aPortNumber;
		  yourself
]

{ #category : 'actions' }
MCPServersPresenter >> openDashboard [

	serversTable selectedItem ifNotNil: [ :server | MCPDashboardPresenter openOn: server ]
]

{ #category : 'private' }
MCPServersPresenter >> portHelpText [

	^ 'Port for a new server. 0 asks the operating system for a free one, which is also the way out when the port you want is already taken.'
]

{ #category : 'accessing' }
MCPServersPresenter >> portInput [

	^ portInput
]

{ #category : 'updating' }
MCPServersPresenter >> refreshView [
	"Reselect by identity: the list is rebuilt from the heap, so the previous selection is the same object or it is gone."

	| selected servers |
	selected := serversTable selectedItem.
	servers := MCP allServers.
	serversTable items: servers.
	selected ifNotNil: [ :previous | (servers identityIncludes: previous) ifTrue: [ serversTable selectItem: previous ] ].
	self updateActionButtons
]

{ #category : 'private' }
MCPServersPresenter >> requestedPort [
	"Answer the port the field asks for, or nil when it is not a port at all. 0 is valid and means a free one."

	^ (portInput text ifNil: [ '' ]) trimBoth asInteger ifNotNil: [ :port | (port between: 0 and: 65535) ifTrue: [ port ] ]
]

{ #category : 'private' }
MCPServersPresenter >> serversContextMenu [

	^ self newMenu
		  addGroup: [ :group |
				  group
					  addItem: [ :item |
							  item
								  name: 'Inspect';
								  description: 'Inspect the selected server';
								  enabled: [ serversTable selectedItem isNotNil ];
								  action: [ self inspectSelectedServer ] ];
					  addItem: [ :item |
							  item
								  name: 'Copy endpoint';
								  description: 'Copy the endpoint of the selected server to the clipboard';
								  enabled: [ serversTable selectedItem isNotNil ];
								  action: [ self copySelectedEndpoint ] ] ];
		  yourself
]

{ #category : 'accessing' }
MCPServersPresenter >> serversTable [

	^ serversTable
]

{ #category : 'updating' }
MCPServersPresenter >> showMessage: aString [

	messageLabel label: aString
]

{ #category : 'actions' }
MCPServersPresenter >> startSelectedServer [

	self showMessage: ''.
	serversTable selectedItem ifNotNil: [ :server |
			[ server start ]
				on: Error
				do: [ :error | self showMessage: error messageText ] ].
	self refreshView
]

{ #category : 'actions' }
MCPServersPresenter >> stopSelectedServer [

	self showMessage: ''.
	serversTable selectedItem ifNotNil: [ :server |
			[ server stop ]
				on: Error
				do: [ :error | self showMessage: error messageText ] ].
	self refreshView
]

{ #category : 'updating' }
MCPServersPresenter >> updateActionButtons [

	startButton enabled: self canStartSelectedServer.
	stopButton enabled: self canStopSelectedServer.
	dashboardButton enabled: self hasSelectedServer
]
