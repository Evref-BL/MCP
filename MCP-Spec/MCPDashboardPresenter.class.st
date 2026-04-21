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
		'toolsTable'
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
	self model configurePort: newPort debugMode: debugCheckBox state ]
		on: Error
		do: [ :error | UIManager default alert: error messageText ].

	self refreshView
]

{ #category : 'initialization' }
MCPDashboardPresenter >> connectPresenters [

	applyButton action: [ self applyConfiguration ].
	refreshButton action: [ self refreshView ].
	startButton action: [ self startServer ].
	stopButton action: [ self stopServer ].
	restartButton action: [ self restartServer ]
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
		  add: toolsTable;
		  yourself
]

{ #category : 'api' }
MCPDashboardPresenter >> initialExtent [

	^ 780 @ 480
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

	portLabel label: 'Port'.
	debugCheckBox label: 'Mode debug'.
	applyButton label: 'Appliquer'.
	refreshButton label: 'Rafraichir'.
	startButton label: 'Demarrer'.
	stopButton label: 'Arreter'.
	restartButton label: 'Redemarrer'.

	toolsTable
		addColumn: (SpStringTableColumn title: 'Nom' evaluated: #name);
		addColumn: (SpStringTableColumn
				 title: 'Classe'
				 evaluated: [ :tool | tool class name ]);
		addColumn: (SpStringTableColumn
				 title: 'Description'
				 evaluated: [ :tool | tool description ifNil: [ '' ] ]);
		beResizable
]

{ #category : 'updating' }
MCPDashboardPresenter >> modelChanged [

	self refreshView
]

{ #category : 'private' }
MCPDashboardPresenter >> readPortFromInput [

	| trimmedPort parsedPort |
	trimmedPort := portInput text asString trimBoth.

	trimmedPort isEmpty ifTrue: [
		self error: 'Le port ne peut pas etre vide.' ].

	parsedPort := [ trimmedPort asInteger ]
		              on: Error
		              do: [ :error |
		              self error: 'Le port doit etre un entier valide.' ].

	(parsedPort between: 1 and: 65535) ifFalse: [
		self error: 'Le port doit etre compris entre 1 et 65535.' ].

	^ parsedPort
]

{ #category : 'actions' }
MCPDashboardPresenter >> refreshView [

	| mcp |
	mcp := self model ifNil: [ ^ self ].

	summaryLabel label: mcp dashboardSummary.
	statusLabel label: ('Etat HTTP: {1} | Ecoute: {2}' format: {
				 (mcp isRunning
					  ifTrue: [ 'actif' ]
					  ifFalse: [ 'arrete' ]).
				 (mcp isListening
					  ifTrue: [ 'oui' ]
					  ifFalse: [ 'non' ]) }).
	urlLabel label: 'URL locale: ' , mcp localUrlString.
	detailsLabel label:
		('Handlers: {1} | Outils: {2} | Debug: {3}' format: {
				 mcp handlersCount asString.
				 mcp sortedTools size asString.
				 (mcp debugMode
					  ifTrue: [ 'oui' ]
					  ifFalse: [ 'non' ]) }).
	portInput text: mcp port asString.
	debugCheckBox state: mcp debugMode.
	toolsLabel label: 'Outils exposes'.
	toolsTable items: mcp sortedTools
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

{ #category : 'api' }
MCPDashboardPresenter >> title [

	^ 'MCP Dashboard'
]
