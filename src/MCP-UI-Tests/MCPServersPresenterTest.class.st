"
Tests the presenter that lists the MCP servers an image holds.
"
Class {
	#name : 'MCPServersPresenterTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-UI-Tests',
	#package : 'MCP-UI-Tests'
}

{ #category : 'private' }
MCPServersPresenterTest >> pragmaNamesOf: aCompiledMethod [

	^ aCompiledMethod pragmas collect: [ :each | each selector ] as: Array
]

{ #category : 'private' }
MCPServersPresenterTest >> startedServer [
	"A real server on a free port, so the list has something of this test's own to find."

	^ self mcpWithoutObservabilityExport
		  port: 0;
		  start;
		  yourself
]

{ #category : 'tests' }
MCPServersPresenterTest >> testANewServerIsAlreadyRunningAndSelected [
	"Create and start is one step: a server that was only created is held by nothing and would be collected before the next refresh."

	| presenter created |
	presenter := MCPServersPresenterTestDouble new.
	presenter portInput text: '0'.

	presenter createServer.

	created := presenter serversTable selectedItem.
	[
		self assert: created isNotNil.
		self assert: created isRunning.
		self assert: created isListening.
		self assert: (presenter messageText includesSubstring: created port asString) ] ensure: [
		created ifNotNil: [ :server | server stop ] ]
]

{ #category : 'tests' }
MCPServersPresenterTest >> testARunningServerCanBeStoppedAndNotStarted [

	| server presenter |
	server := self startedServer.
	[
		presenter := MCPServersPresenter new.
		presenter serversTable selectItem: server.
		self assert: presenter hasSelectedServer.
		self assert: presenter canStopSelectedServer.
		self deny: presenter canStartSelectedServer ] ensure: [ server stop ]
]

{ #category : 'tests' }
MCPServersPresenterTest >> testAStoppedServerCanBeStartedAndNotStopped [

	| server presenter |
	server := self startedServer.
	server stop.
	presenter := MCPServersPresenter new.
	presenter serversTable selectItem: server.

	self assert: presenter hasSelectedServer.
	self assert: presenter canStartSelectedServer.
	self deny: presenter canStopSelectedServer
]

{ #category : 'tests' }
MCPServersPresenterTest >> testAnUnusablePortIsReportedInsteadOfCreatingAServer [

	| presenter listed |
	presenter := MCPServersPresenterTestDouble new.
	listed := presenter serversTable items size.
	presenter portInput text: 'not a port'.

	presenter createServer.

	self assert: (presenter messageText includesSubstring: '65535').
	self assert: presenter serversTable items size equals: listed
]

{ #category : 'tests' }
MCPServersPresenterTest >> testControlRowsDoNotConstrainButtonWidth [
	"A width constraint makes Spec draw a button without its label, and takes the labels of the rest of the row with it."

	| presenter |
	presenter := MCPServersPresenter new.
	{
		presenter actionsLayout.
		presenter creationLayout } do: [ :layout |
			layout children do: [ :child |
					(child isKindOf: SpButtonPresenter) ifTrue: [
						self assert: (layout constraintsFor: child) width isNil description: child label , ' must not be given a width' ] ] ]
]

{ #category : 'tests' }
MCPServersPresenterTest >> testEveryServerActionIsDisabledWithoutASelection [

	| presenter |
	presenter := MCPServersPresenter new.

	self deny: presenter hasSelectedServer.
	self deny: presenter canStartSelectedServer.
	self deny: presenter canStopSelectedServer
]

{ #category : 'tests' }
MCPServersPresenterTest >> testInspectingTheMCPClassOffersAServersTab [

	| tab |
	tab := MCP class >> #inspectionServers:.

	self assert: (tab pragmas anySatisfy: [ :each | each selector = #inspectorPresentationOrder:title: ]).
	self assert: (MCP inspectionServers: nil) class equals: MCPServersPresenter
]

{ #category : 'tests' }
MCPServersPresenterTest >> testTheListShowsTheServersTheImageHolds [

	| server |
	server := self startedServer.
	[ self assert: (MCPServersPresenter new serversTable items identityIncludes: server) ] ensure: [ server stop ]
]

{ #category : 'tests' }
MCPServersPresenterTest >> testThePortFieldAnswersNilForWhatIsNotAPort [

	| presenter |
	presenter := MCPServersPresenter new.

	#( 'abc' '70000' '-1' '' ) do: [ :each |
			presenter portInput text: each.
			self assert: presenter requestedPort isNil ].
	presenter portInput text: '0'.
	self assert: presenter requestedPort equals: 0.
	presenter portInput text: ' 4000 '.
	self assert: presenter requestedPort equals: 4000
]

{ #category : 'tests' }
MCPServersPresenterTest >> testTheWorldMenuOffersTheServersWindow [
	"Asking the built menu instead would ask Pragma allNamed:, whose cache answers nothing for a package loaded into an image, so this exercises the registration itself."

	| item |
	item := self worldMenuItemNamed: 'MCP Servers' registeredBy: MCPServersPresenter.

	self assert: (item instVarNamed: #parent) equals: #Tools.
	self assert: (self pragmaNamesOf: MCPServersPresenter class >> #menuCommandOn:) equals: #( worldMenu )
]

{ #category : 'tests' }
MCPServersPresenterTest >> testTheWorldMenuOffersTheToolCatalog [

	| item |
	item := self worldMenuItemNamed: 'MCP Tool Catalog' registeredBy: MCPToolsCatalogPresenter.

	self assert: (item instVarNamed: #parent) equals: #Tools.
	self assert: (self pragmaNamesOf: MCPToolsCatalogPresenter class >> #menuCommandOn:) equals: #( worldMenu )
]

{ #category : 'private' }
MCPServersPresenterTest >> worldMenuItemNamed: aName registeredBy: aPresenterClass [
	"The registration a world menu pragma makes, which is what the builder asks each contributing class for."

	| registration |
	registration := PragmaMenuAndShortcutRegistration model: nil.
	aPresenterClass menuCommandOn: registration.
	^ registration items
		  detect: [ :each | (each instVarNamed: #item) = aName ]
		  ifNone: [ self fail: 'No world menu item named ' , aName ]
]
