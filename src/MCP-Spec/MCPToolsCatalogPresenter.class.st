"
Spec presenter that displays the MCP tool catalog.

Each row shows a compact tool identity cell with icon, title, and tool name, plus an expanded description cell.
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

{ #category : 'layout' }
MCPToolsCatalogPresenter >> toolCatalogLeftCellFor: tool [

	| identifierLabel image labelLayout leftCell leftLayout title |
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
	labelLayout := SpBoxLayout newTopToBottom
		               spacing: 1;
		               hAlignStart;
		               yourself.
	labelLayout
		add: title expand: false;
		add: identifierLabel expand: false.
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
