"
Tests the MCP Spec dashboard presenter layout, actions, and refresh behavior.
"
Class {
	#name : 'MCPDashboardPresenterTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-UI-Tests',
	#package : 'MCP-UI-Tests'
}

{ #category : 'private' }
MCPDashboardPresenterTest >> isLabelledWidget: aPresenter [

	^ (aPresenter isKindOf: SpButtonPresenter) or: [ aPresenter isKindOf: SpCheckBoxPresenter ]
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testApplyIsIdleUntilThePortChanges [
	"Apply used to apply the port and the debug checkbox at once, which said neither what it would do nor whether it had anything to do."

	| presenter portInput |
	presenter := MCPDashboardPresenter on: self mcpWithoutObservabilityExport.
	portInput := presenter instVarNamed: #portInput.

	self deny: presenter isPortChangePending.
	portInput text: '5000'.
	self assert: presenter isPortChangePending.
	portInput text: 'not a port'.
	self deny: presenter isPortChangePending
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testConfigurationRowPutsApplyAgainstItsField [

	| children |
	children := MCPDashboardPresenter new configurationLayout children.

	self assert: children size equals: 4.
	self assert: children first label equals: 'Port:'.
	self assert: children second class equals: SpTextInputFieldPresenter.
	self assert: children third label equals: 'Apply'.
	self assert: children fourth label equals: 'Debug mode'
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testControlRowsDoNotConstrainWidgetWidth [
	"A width constraint makes Spec draw a button or a checkbox without its label, and takes the labels of the rest of the row with it. Every control row here used to have one, which is why the dashboard showed blank boxes."

	| presenter |
	presenter := MCPDashboardPresenter new.
	{
		presenter configurationLayout.
		presenter lifecycleActionsLayout } do: [ :layout |
			layout children do: [ :child |
					(self isLabelledWidget: child) ifTrue: [
						self assert: (layout constraintsFor: child) width isNil description: child label , ' must not be given a width' ] ] ]
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testDebugModeCheckboxExplainsBehavior [

	| debugCheckBox presenter |
	presenter := MCPDashboardPresenter new.
	debugCheckBox := presenter instVarNamed: #debugCheckBox.

	self assert: debugCheckBox label equals: 'Debug mode'.
	self assert: (debugCheckBox help includesSubstring: 'server and JSON-RPC errors pass through').
	self assert: (debugCheckBox help includesSubstring: 'debugger can open').
	self assert: (debugCheckBox help includesSubstring: 'normal error responses')
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testDebugModeTakesEffectWithoutApply [

	| mcp presenter |
	mcp := self mcpWithoutObservabilityExport.
	presenter := MCPDashboardPresenter on: mcp.
	self deny: mcp debugMode.

	presenter debugModeChangedTo: true.

	self assert: mcp debugMode
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testDisablingAToolTakesItOffTheServer [

	| mcp presenter tool |
	mcp := self mcpWithoutObservabilityExport.
	presenter := MCPDashboardPresenter on: mcp.
	tool := mcp toolRegistry toolNamed: 'image_evaluate' ifAbsent: [ nil ].

	presenter disableTool: tool.

	self deny: (presenter isToolEnabled: tool).
	self deny: (mcp toolRegistry includesToolNamed: 'image_evaluate').
	self assert: (presenter toolRows anySatisfy: [ :each | each name = 'image_evaluate' ])
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testEnablingAToolPutsItBack [

	| mcp presenter tool |
	mcp := self mcpWithoutObservabilityExport.
	presenter := MCPDashboardPresenter on: mcp.
	tool := mcp toolRegistry toolNamed: 'image_evaluate' ifAbsent: [ nil ].
	presenter disableTool: tool.

	presenter enableTool: tool.

	self assert: (presenter isToolEnabled: tool).
	self assert: (mcp toolRegistry includesToolNamed: 'image_evaluate')
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testHeaderLayoutUsesStatusAndEndpointRows [

	| headerLayout presenter statusRow |
	presenter := MCPDashboardPresenter new.
	headerLayout := presenter headerLayout.
	statusRow := headerLayout children first.

	self assert: headerLayout class equals: SpBoxLayout.
	self assert: headerLayout isVertical.
	self assert: headerLayout children size equals: 2.
	self assert: statusRow class equals: SpBoxLayout.
	self assert: statusRow isHorizontal.
	self assert: statusRow children size equals: 3.
	self assert: statusRow children first identicalTo: (presenter instVarNamed: #statusLabel).
	self assert: statusRow children second identicalTo: (presenter instVarNamed: #statusIcon).
	self assert: statusRow children third identicalTo: (presenter instVarNamed: #statusValueLabel).
	self assert: headerLayout children second identicalTo: (presenter instVarNamed: #urlLabel)
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testLifecycleActionsOnlyContainServerControls [

	| layout |
	layout := MCPDashboardPresenter new lifecycleActionsLayout.

	self assert: layout children size equals: 3.
	self assert: layout children first label equals: 'Start'.
	self assert: layout children second label equals: 'Stop'.
	self assert: layout children third label equals: 'Restart'
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testRefreshViewUpdatesStatusIcon [

	| mcp presenter statusIcon statusLabel statusValueLabel |
	mcp := MCP new.
	presenter := MCPDashboardPresenter on: mcp.
	presenter refreshView.
	statusIcon := presenter instVarNamed: #statusIcon.
	statusLabel := presenter instVarNamed: #statusLabel.
	statusValueLabel := presenter instVarNamed: #statusValueLabel.

	self assert: statusIcon image equals: (presenter iconNamed: #testNotRun).
	self assert: statusIcon help equals: 'Status: stopped'.
	self assert: statusLabel label equals: 'Status:'.
	self assert: statusValueLabel label equals: 'stopped'
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testRefreshViewUsesSingleServerStatus [

	| mcp presenter statusValueLabel |
	mcp := MCP new.
	presenter := MCPDashboardPresenter on: mcp.
	presenter refreshView.
	statusValueLabel := presenter instVarNamed: #statusValueLabel.

	self assert: statusValueLabel label equals: 'stopped'.
	self deny: (statusValueLabel label includesSubstring: 'HTTP:').
	self deny: (statusValueLabel label includesSubstring: 'Listener:')
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testServerStatusIconUsesTestIcons [

	| presenter |
	presenter := MCPDashboardPresenter new.

	self assert: (presenter serverStatusIconNameForRunning: false listening: false) equals: #testNotRun.
	self assert: (presenter serverStatusIconNameForRunning: true listening: true) equals: #testGreen.
	self assert: (presenter serverStatusIconNameForRunning: true listening: false) equals: #testRed.
	self assert: (presenter serverStatusIconNameForRunning: false listening: true) equals: #testRed
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testServerStatusLabelShowsListenerOnlyWhenAnomalous [

	| presenter |
	presenter := MCPDashboardPresenter new.

	self assert: (presenter serverStatusLabelForRunning: false listening: false) equals: 'Status: stopped'.
	self assert: (presenter serverStatusLabelForRunning: true listening: true) equals: 'Status: running'.
	self assert: (presenter serverStatusLabelForRunning: true listening: false) equals: 'Status: running, socket not listening'.
	self assert: (presenter serverStatusLabelForRunning: false listening: true) equals: 'Status: stopped, socket still listening'
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testToolRowsAreMarkedWithTheirOwnIcon [
	"The same icon the catalog shows and a client is served, scaled to the row."

	| presenter tool |
	presenter := MCPDashboardPresenter on: self mcpWithoutObservabilityExport.
	tool := presenter toolRows detect: [ :each | each name = 'image_evaluate' ].

	self assert: (presenter rowIconFor: tool) extent equals: presenter rowIconSize @ presenter rowIconSize.
	self assert: (presenter rowIconFor: tool) == (presenter rowIconFor: tool)
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testToolRowsHoldEveryToolTheServerCouldRun [
	"The table used to show the listed tools only, so the ones tools/list hides could not be found, let alone shown."

	| mcp presenter rows |
	mcp := self mcpWithoutObservabilityExport.
	presenter := MCPDashboardPresenter on: mcp.

	rows := presenter toolRows.

	self assert: rows size equals: mcp toolRegistry tools size.
	self assert: rows size > mcp advertisedToolNames size.
	self assert: (rows collect: [ :each | each name ]) asArray equals: (rows collect: [ :each | each name ]) asArray sorted
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testToolsTableHasExpectedColumns [
	"The first column carries the tool's icon and has no title of its own."

	| titles |
	titles := (MCPDashboardPresenter new instVarNamed: #toolsTable) columns collect: [ :each | each title ].

	self assert: titles equals: { nil. 'Tool'. 'Enabled'. 'Listed'. 'Title'. 'Description' }
]

{ #category : 'tests' }
MCPDashboardPresenterTest >> testUnlistingAToolLeavesItEnabledAndCallable [
	"Listed and Enabled are two states: an unlisted tool is absent from tools/list but tool_search still finds it and tool_call still runs it."

	| mcp presenter tool |
	mcp := self mcpWithoutObservabilityExport.
	presenter := MCPDashboardPresenter on: mcp.
	tool := mcp toolRegistry toolNamed: 'image_evaluate' ifAbsent: [ nil ].
	self assert: (presenter isToolListed: tool).

	presenter unlistTool: tool.

	self deny: (presenter isToolListed: tool).
	self assert: (presenter isToolEnabled: tool).
	self assert: (mcp toolRegistry includesToolNamed: 'image_evaluate')
]
