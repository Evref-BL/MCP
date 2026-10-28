"
Spec presenter that displays the MCP tool catalog.

Each row shows a compact tool identity cell with icon, title, and tool name, plus an expanded description cell.
"
Class {
	#name : 'MCPToolsCatalogPresenter',
	#superclass : 'SpPresenter',
	#traits : 'TMCPToolRowIcon',
	#classTraits : 'TMCPToolRowIcon classTrait',
	#instVars : [
		'filterInput',
		'countLabel',
		'toolsTable',
		'rowIcons'
	],
	#category : 'MCP-UI',
	#package : 'MCP-UI'
}

{ #category : 'world menu' }
MCPToolsCatalogPresenter class >> menuCommandOn: aBuilder [

	<worldMenu>
	(aBuilder item: 'MCP Tool Catalog')
		action: [ self open ];
		order: 41;
		parent: #Tools;
		help: 'Browse the MCP tools this image knows, with their descriptions.';
		iconName: #book
]

{ #category : 'instance creation' }
MCPToolsCatalogPresenter class >> open [

	^ self new open
]

{ #category : 'updating' }
MCPToolsCatalogPresenter >> allTools [
	"Every tool class the image has, not the surface one server advertises, which is what makes this the image's catalog rather than a server's."

	^ (MCPTool toolGroups flatCollect: [ :group | group value ] as: Array) collect: [ :toolClass | toolClass new ]
]

{ #category : 'private' }
MCPToolsCatalogPresenter >> browseSelectedTool [

	toolsTable selectedItem ifNotNil: [ :tool | tool class browse ]
]

{ #category : 'initialization' }
MCPToolsCatalogPresenter >> connectPresenters [

	filterInput whenTextChangedDo: [ self refreshView ]
]

{ #category : 'private' }
MCPToolsCatalogPresenter >> copySelectedToolName [

	toolsTable selectedItem ifNotNil: [ :tool | Clipboard clipboardText: tool name ]
]

{ #category : 'updating' }
MCPToolsCatalogPresenter >> countLabelFor: shownCount of: totalCount [

	^ shownCount = totalCount
		  ifTrue: [ totalCount printString , ' tools' ]
		  ifFalse: [
		  String streamContents: [ :stream | stream << shownCount printString << ' of ' << totalCount printString << ' tools' ] ]
]

{ #category : 'layout' }
MCPToolsCatalogPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 6;
		  borderWidth: 8;
		  add: self filterLayout expand: false;
		  add: toolsTable;
		  yourself
]

{ #category : 'updating' }
MCPToolsCatalogPresenter >> descriptionFor: aTool [

	^ aTool description ifNil: [ 'No description available.' ]
]

{ #category : 'layout' }
MCPToolsCatalogPresenter >> filterLayout [

	^ SpBoxLayout newLeftToRight
		  spacing: 8;
		  vAlignCenter;
		  add: filterInput;
		  add: countLabel expand: false;
		  yourself
]

{ #category : 'api' }
MCPToolsCatalogPresenter >> initialExtent [

	^ 1000 @ 700
]

{ #category : 'initialization' }
MCPToolsCatalogPresenter >> initializePresenters [

	rowIcons := Dictionary new.
	filterInput := self newTextInput.
	countLabel := self newLabel.
	toolsTable := self newTable.

	filterInput
		placeholder: 'Filter by name, title, group or description';
		autoAccept: true.
	self initializeToolsTable.
	self refreshView
]

{ #category : 'initialization' }
MCPToolsCatalogPresenter >> initializeToolsTable [

	toolsTable
		addColumn: self rowIconColumn;
		addColumn: ((SpStringTableColumn title: 'Tool' evaluated: #name)
				 beSortable;
				 yourself);
		addColumn: ((SpStringTableColumn title: 'Group' evaluated: [ :tool | tool class groupName ])
				 beSortable;
				 yourself);
		addColumn: ((SpStringTableColumn title: 'Title' evaluated: [ :tool | tool title ifNil: [ '' ] ])
				 beSortable;
				 yourself);
		addColumn: (SpStringTableColumn title: 'Description' evaluated: [ :tool | self descriptionFor: tool ]);
		contextMenu: [ self toolsContextMenu ];
		beResizable
]

{ #category : 'initialization' }
MCPToolsCatalogPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: 'MCP Tool Catalog';
		initialExtent: self initialExtent
]

{ #category : 'updating' }
MCPToolsCatalogPresenter >> refreshView [

	| shown all |
	all := self allTools.
	shown := self toolsMatchingFilter: all.
	toolsTable items: shown.
	countLabel label: (self countLabelFor: shown size of: all size)
]

{ #category : 'private' }
MCPToolsCatalogPresenter >> rowIconCache [

	^ rowIcons
]

{ #category : 'updating' }
MCPToolsCatalogPresenter >> searchTextFor: aTool [

	^ String streamContents: [ :stream |
			  stream
				  << aTool name asLowercase;
				  space;
				  << aTool class groupName asLowercase;
				  space;
				  << (aTool title ifNil: [ '' ]) asLowercase;
				  space;
				  << (self descriptionFor: aTool) asLowercase ]
]

{ #category : 'private' }
MCPToolsCatalogPresenter >> toolsContextMenu [

	^ self newMenu
		  addGroup: [ :group |
				  group
					  addItem: [ :item |
							  item
								  name: 'Browse class';
								  description: 'Open the class that implements the selected tool';
								  enabled: [ toolsTable selectedItem isNotNil ];
								  action: [ self browseSelectedTool ] ];
					  addItem: [ :item |
							  item
								  name: 'Copy name';
								  description: 'Copy the name of the selected tool to the clipboard';
								  enabled: [ toolsTable selectedItem isNotNil ];
								  action: [ self copySelectedToolName ] ] ];
		  yourself
]

{ #category : 'updating' }
MCPToolsCatalogPresenter >> toolsMatchingFilter: someTools [

	| query |
	query := filterInput text asString trimBoth asLowercase.
	query ifEmpty: [ ^ someTools ].
	^ someTools select: [ :tool | (self searchTextFor: tool) includesSubstring: query ]
]
