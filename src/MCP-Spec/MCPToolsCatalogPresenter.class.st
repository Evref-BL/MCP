"
Spec presenter that displays the MCP tool catalog.

Each row shows a compact tool identity cell with icon, title, tool name, and supported operations, plus an expanded description cell. Long operation lists are summarized in the row and exposed in full through hover help.
"
Class {
	#name : 'MCPToolsCatalogPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'contentPresenter'
	],
	#category : 'MCP-Spec',
	#package : 'MCP-Spec'
}

{ #category : 'instance creation' }
MCPToolsCatalogPresenter class >> open [

	^ self new open
]

{ #category : 'layout' }
MCPToolsCatalogPresenter >> addToolCatalogGroup: group to: contentLayout [

	| heading |
	heading := self newLabel.
	heading
		label: group key;
		displayBold: [ :ignored | true ].
	contentLayout add: heading expand: false.
	group value do: [ :toolClass |
		contentLayout
			add: (self toolCatalogCardFor: toolClass)
			withConstraints: [ :constraints |
				constraints
					expand: false;
					fill: true ] ]
]

{ #category : 'layout' }
MCPToolsCatalogPresenter >> catalogLayout [

	| contentLayout |
	contentLayout := SpBoxLayout newTopToBottom
		                 spacing: 10;
		                 borderWidth: 12;
		                 yourself.
	MCPTool toolGroups do: [ :group |
		self addToolCatalogGroup: group to: contentLayout ].
	^ contentLayout
]

{ #category : 'layout' }
MCPToolsCatalogPresenter >> defaultLayout [

	^ SpScrollableLayout with: contentPresenter
]

{ #category : 'accessing' }
MCPToolsCatalogPresenter >> fallbackToolCatalogOperationNamesFor: tool [

	| toolName |
	toolName := tool name.
	toolName = 'rewrite-methods' ifTrue: [ ^ #( 'preview' 'apply' ) ].
	toolName = 'run-tests' ifTrue: [ ^ #( 'run' ) ].
	toolName = 'evaluate' ifTrue: [ ^ #( 'evaluate' ) ].
	(toolName beginsWith: 'find-') ifTrue: [ ^ #( 'query' ) ].
	(toolName beginsWith: 'inspect-') ifTrue: [ ^ #( 'inspect' ) ].
	(toolName beginsWith: 'remove-') ifTrue: [ ^ #( 'remove' ) ].
	^ #( 'call' )
]

{ #category : 'initialization' }
MCPToolsCatalogPresenter >> initializePresenters [

	contentPresenter := self instantiate: SpPresenter.
	contentPresenter layout: self catalogLayout
]

{ #category : 'initialization' }
MCPToolsCatalogPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: 'MCP Tool Catalog';
		initialExtent: 1000 @ 760
]

{ #category : 'accessing' }
MCPToolsCatalogPresenter >> joinToolCatalogItems: strings [

	strings isEmpty ifTrue: [ ^ 'call' ].
	^ String streamContents: [ :stream |
		  strings doWithIndex: [ :each :index |
			  index > 1 ifTrue: [ stream nextPutAll: ' | ' ].
			  stream nextPutAll: each asString ] ]
]

{ #category : 'accessing' }
MCPToolsCatalogPresenter >> maximumVisibleOperationNames [

	^ 2
]

{ #category : 'layout' }
MCPToolsCatalogPresenter >> toolCatalogCardFor: toolClass [

	| card cardLayout tool |
	tool := toolClass new.
	card := self newPresenter.
	cardLayout := SpBoxLayout newLeftToRight
		              spacing: 12;
		              borderWidth: 8;
		              yourself.
	cardLayout
		add: (self toolCatalogLeftCellFor: tool)
		width: self toolCatalogLeftColumnWidth;
		add: (self toolCatalogDescriptionPresenterFor: tool)
		withConstraints: [ :constraints |
			constraints
				expand: true;
				fill: true ].
	card layout: cardLayout.
	^ card
]

{ #category : 'accessing' }
MCPToolsCatalogPresenter >> toolCatalogDescriptionFor: tool [

	^ tool description ifNil: [ 'No description available.' ]
]

{ #category : 'layout' }
MCPToolsCatalogPresenter >> toolCatalogDescriptionPresenterFor: tool [

	| description descriptionCell descriptionLayout |
	descriptionCell := self newPresenter.
	description := self newText.
	description
		text: (self toolCatalogDescriptionFor: tool);
		beNotEditable;
		beWrapWord;
		withoutEditionContextMenu;
		withoutScrollBars.
	descriptionLayout := SpBoxLayout newTopToBottom yourself.
	descriptionLayout add: description withConstraints: [ :constraints |
		constraints
			expand: true;
			fill: true ].
	descriptionCell layout: descriptionLayout.
	^ descriptionCell
]

{ #category : 'accessing' }
MCPToolsCatalogPresenter >> toolCatalogFullOperationSummaryFor: tool [

	^ self joinToolCatalogItems:
		  (self toolCatalogOperationNamesFor: tool)
]

{ #category : 'layout' }
MCPToolsCatalogPresenter >> toolCatalogLeftCellFor: tool [

	| identifierLabel image labelLayout leftCell leftLayout operationHelp operations title |
	leftCell := self newPresenter.
	image := self newImage.
	image
		image: (MCPTool toolIconFormOf: tool class);
		autoScale: false.
	title := self newLabel.
	title
		label: tool title;
		displayBold: [ :ignored | true ].
	identifierLabel := self newLabel.
	identifierLabel label: tool name.
	operations := self newLabel.
	operations label: (self toolCatalogOperationSummaryFor: tool).
	operationHelp := self toolCatalogOperationHelpFor: tool.
	operationHelp ifNotNil: [ operations help: operationHelp ].
	labelLayout := SpBoxLayout newTopToBottom
		               spacing: 1;
		               hAlignStart;
		               yourself.
	labelLayout
		add: title expand: false;
		add: identifierLabel expand: false;
		add: operations expand: false.
	leftLayout := SpBoxLayout newLeftToRight
		              spacing: 8;
		              borderWidth: 0;
		              hAlignStart;
		              vAlignCenter;
		              yourself.
	leftLayout
		add: image expand: false;
		add: labelLayout expand: true.
	leftCell layout: leftLayout.
	^ leftCell
]

{ #category : 'layout' }
MCPToolsCatalogPresenter >> toolCatalogLeftColumnWidth [

	^ 180
]

{ #category : 'accessing' }
MCPToolsCatalogPresenter >> toolCatalogOperationHelpFor: tool [

	| operationNames |
	operationNames := self toolCatalogOperationNamesFor: tool.
	operationNames size <= self maximumVisibleOperationNames ifTrue: [
		^ nil ].
	^ 'Operations: ' , (self joinToolCatalogItems: operationNames)
]

{ #category : 'accessing' }
MCPToolsCatalogPresenter >> toolCatalogOperationNamesFor: tool [

	(tool respondsTo: #canonicalOperationNames) ifTrue: [
		^ tool canonicalOperationNames ].
	^ self fallbackToolCatalogOperationNamesFor: tool
]

{ #category : 'accessing' }
MCPToolsCatalogPresenter >> toolCatalogOperationSummaryFor: tool [

	| operationNames visibleOperations |
	operationNames := self toolCatalogOperationNamesFor: tool.
	operationNames size <= self maximumVisibleOperationNames ifTrue: [
		^ self joinToolCatalogItems: operationNames ].
	visibleOperations := operationNames first:
		                     self maximumVisibleOperationNames.
	^ (self joinToolCatalogItems: visibleOperations) , ' | +'
	  , (operationNames size - visibleOperations size) asString
]
