"
Spec presenter listing the MCP servers an image holds, with their port, state, endpoint and tool count.

It answers the question an image cannot otherwise be asked: is anything running, on which port, and is the port a client is configured for held by a server that was forgotten. Selecting a server starts, stops or removes it, or opens its dashboard or its observability; the port field creates and starts a new one, defaulting to 0 so the operating system picks a free port instead of colliding.

The list comes from `MCP allServers`, so nothing registers servers and nothing retains them. While the window is open it holds the servers it listed, and lets go of them when it closes. Removing a server is therefore stopping it and letting go of it: it leaves the list once nothing else refers to it, and the window says so when something does.
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
		'refreshButton',
		'messageLabel',
		'portLabel',
		'removeButton'
	],
	#category : 'MCP-UI',
	#package : 'MCP-UI'
}

{ #category : 'defaults' }
MCPServersPresenter class >> defaultPreferredExtent [

	^ 760 @ 420
]

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
	"No width constraint on a button: one makes Spec draw it without its label. Opening a server's windows is on its row, by double-click or the context menu."

	^ SpBoxLayout newLeftToRight
		  spacing: 6;
		  add: startButton expand: false;
		  add: stopButton expand: false;
		  add: removeButton expand: false;
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
	removeButton action: [ self removeSelectedServer ].
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
	port := self requestedPort ifNil: [ ^ self showMessage: self invalidPortText ].
	server := self newServerOnPort: port.
	[ server start ]
		on: Error
		do: [ :error |
				server stop.
				^ self showMessage: error mcpMessageText ].
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

{ #category : 'initialization' }
MCPServersPresenter >> initializePresenters [

	serversTable := self newTable.
	portLabel := self newLabel.
	portInput := self newTextInput.
	newButton := self newButton.
	startButton := self newStartButton.
	stopButton := self newStopButton.
	removeButton := self newButton.
	refreshButton := self newRefreshButton.
	messageLabel := self newLabel.

	portLabel label: 'New server on port:'.
	portInput
		text: '0';
		help: self portHelpText.
	newButton
		label: 'New server';
		icon: (self iconNamed: #add);
		help: self portHelpText.
	removeButton
		label: 'Remove';
		icon: (self iconNamed: #trash);
		help: self removeHelpText.
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
		addColumn: (SpStringTableColumn title: 'Tools' evaluated: [ :server | server toolsList size asString ]);
		contextMenu: [ self serversContextMenu ];
		beResizable
]

{ #category : 'initialization' }
MCPServersPresenter >> initializeWindow: aWindowPresenter [
	"A closed window can still be referenced, by the hand's keyboard focus among others, so it lets go of its servers rather than wait to be collected."

	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: 'MCP Servers';
		whenClosedDo: [ serversTable items: #(  ) ]
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

{ #category : 'actions' }
MCPServersPresenter >> openObservability [

	serversTable selectedItem ifNotNil: [ :server | MCPObservabilityPresenter openOn: server ]
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
	"Every running server, and the stopped ones this window already shows, so that stopping a server does not take its row away; removing it does. Reselect by identity, since the rows are the servers themselves."

	| selected servers |
	selected := serversTable selectedItem.
	servers := (serversTable items reject: [ :each | each isRunning ]) asArray , MCP runningServers sort: [ :left :right |
		           left port <= right port ].
	serversTable items: servers.
	selected ifNotNil: [ :previous | (servers identityIncludes: previous) ifTrue: [ serversTable selectItem: previous ] ].
	self updateActionButtons
]

{ #category : 'private' }
MCPServersPresenter >> removeHelpText [

	^ 'Stop the selected server and take it off the list.'
]

{ #category : 'actions' }
MCPServersPresenter >> removeSelectedServer [
	"Stop it and drop its row. Only running servers are picked up, so it stays gone whatever else still refers to it."

	| server |
	server := serversTable selectedItem ifNil: [ ^ self ].
	self showMessage: ''.
	[ server stop ]
		on: Error
		do: [ :error | ^ self showMessage: error mcpMessageText ].
	serversTable items: (serversTable items copyWithout: server).
	self refreshView.
	self showMessage: (String streamContents: [ :stream | stream << 'Removed the server on port ' << server port asString << '.' ])
]

{ #category : 'private' }
MCPServersPresenter >> requestedPort [

	^ self portFrom: portInput text
]

{ #category : 'actions' }
MCPServersPresenter >> selectedServerDo: aBlock [
	"Act on the selected server, say what stopped it, and show where it left the server."

	self showMessage: ''.
	serversTable selectedItem ifNotNil: [ :server |
			[ aBlock value: server ]
				on: Error
				do: [ :error | self showMessage: error mcpMessageText ] ].
	self refreshView
]

{ #category : 'private' }
MCPServersPresenter >> serversContextMenu [

	^ self newMenu
		  addGroup: [ :group |
				  group
					  addItem: [ :item |
							  item
								  name: 'Dashboard';
								  description: 'Open the dashboard of the selected server';
								  enabled: [ self hasSelectedServer ];
								  action: [ self openDashboard ] ];
					  addItem: [ :item |
							  item
								  name: 'Observability';
								  description: 'Open what the selected server recorded about its tool calls';
								  enabled: [ self hasSelectedServer ];
								  action: [ self openObservability ] ] ];
		  addGroup: [ :group |
				  group
					  addItem: [ :item |
							  item
								  name: 'Start';
								  enabled: [ self canStartSelectedServer ];
								  action: [ self startSelectedServer ] ];
					  addItem: [ :item |
							  item
								  name: 'Stop';
								  enabled: [ self canStopSelectedServer ];
								  action: [ self stopSelectedServer ] ];
					  addItem: [ :item |
							  item
								  name: 'Restart';
								  enabled: [ self canStopSelectedServer ];
								  action: [ self selectedServerDo: [ :server | server restart ] ] ];
					  addItem: [ :item |
							  item
								  name: 'Remove';
								  description: self removeHelpText;
								  enabled: [ self hasSelectedServer ];
								  action: [ self removeSelectedServer ] ] ];
		  addGroup: [ :group |
				  group
					  addItem: [ :item |
							  item
								  name: 'Inspect';
								  description: 'Inspect the selected server';
								  enabled: [ self hasSelectedServer ];
								  action: [ self inspectSelectedServer ] ];
					  addItem: [ :item |
							  item
								  name: 'Copy endpoint';
								  description: 'Copy the endpoint of the selected server to the clipboard';
								  enabled: [ self hasSelectedServer ];
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

	self selectedServerDo: [ :server | server start ]
]

{ #category : 'actions' }
MCPServersPresenter >> stopSelectedServer [

	self selectedServerDo: [ :server | server stop ]
]

{ #category : 'updating' }
MCPServersPresenter >> updateActionButtons [

	startButton enabled: self canStartSelectedServer.
	stopButton enabled: self canStopSelectedServer.
	removeButton enabled: self hasSelectedServer
]
