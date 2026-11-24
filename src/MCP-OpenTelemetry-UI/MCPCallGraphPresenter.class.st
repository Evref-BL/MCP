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
		'clearButton'
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
	refreshButton action: [ self refreshView ].
	clearButton action: [ self clearSpans ]
]

{ #category : 'layout' }
MCPCallGraphPresenter >> controlsLayout [

	^ SpBoxLayout newLeftToRight
		  spacing: 8;
		  vAlignCenter;
		  add: localSpansCheckBox expand: false;
		  add: refreshButton expand: false;
		  add: clearButton expand: false;
		  yourself
]

{ #category : 'layout' }
MCPCallGraphPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 6;
		  borderWidth: 8;
		  add: self controlsLayout expand: false;
		  add: statusLabel expand: false;
		  yourself
]

{ #category : 'initialization' }
MCPCallGraphPresenter >> initializePresenters [

	localSpansCheckBox := self newCheckBox.
	refreshButton := self newButton.
	clearButton := self newButton.
	statusLabel := self newLabel.

	localSpansCheckBox label: 'Keep spans in memory (nothing is exported)'.
	refreshButton
		label: 'Refresh';
		icon: (self iconNamed: #refreshCircling).
	clearButton
		label: 'Clear';
		icon: (self iconNamed: #trash)
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

	| mcp enabled |
	mcp := self model ifNil: [ ^ self ].
	enabled := MCPOpenTelemetryObservabilityBackend isLocalSpansEnabled.
	localSpansCheckBox state: enabled.
	statusLabel label: (self statusFor: mcp enabled: enabled)
]

{ #category : 'updating' }
MCPCallGraphPresenter >> statusFor: mcp enabled: enabled [

	^ String streamContents: [ :stream |
			  enabled
				  ifFalse: [ stream nextPutAll: 'Spans are not kept: turn it on to build the call graph.' ]
				  ifTrue: [
						  stream
							  print: MCPOpenTelemetryObservabilityBackend localSpanStore size;
							  nextPutAll: ' spans kept'.
						  (mcp observability isKindOf: MCPOpenTelemetryObservabilityBackend) ifFalse: [
							  stream nextPutAll: ' - this server does not record through OpenTelemetry' ] ] ]
]
