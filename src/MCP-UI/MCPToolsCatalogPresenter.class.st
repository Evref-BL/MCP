"
Spec presenter that displays the MCP tool catalog.

Each row shows a compact tool identity cell with icon, title, and tool name, plus an expanded description cell.
"
Class {
	#name : 'MCPToolsCatalogPresenter',
	#superclass : 'SpPresenter',
	#traits : 'TMCPToolTable',
	#classTraits : 'TMCPToolTable classTrait',
	#instVars : [
		'filterInput',
		'countLabel',
		'toolsTable'
	],
	#category : 'MCP-UI',
	#package : 'MCP-UI'
}

{ #category : 'accessing' }
MCPToolsCatalogPresenter class >> defaultPreferredExtent [

	^ 1000 @ 700
]

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
	"Every tool the image has, not the surface one server advertises, which is what makes this the image's catalog rather than a server's."

	^ MCPToolRegistry default tools
]

{ #category : 'initialization' }
MCPToolsCatalogPresenter >> connectPresenters [

	filterInput whenTextChangedDo: [ self refreshView ]
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

{ #category : 'layout' }
MCPToolsCatalogPresenter >> filterLayout [

	^ SpBoxLayout newLeftToRight
		  spacing: 8;
		  vAlignCenter;
		  add: filterInput;
		  add: countLabel expand: false;
		  yourself
]

{ #category : 'initialization' }
MCPToolsCatalogPresenter >> initializePresenters [

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
		addColumn: self toolNameColumn;
		addColumn: ((SpStringTableColumn title: 'Group' evaluated: [ :tool | tool class groupName ])
				 beSortable;
				 yourself);
		addColumn: self toolTitleColumn;
		addColumn: self toolDescriptionColumn;
		beResizable.
	self connectToolsTable
]

{ #category : 'initialization' }
MCPToolsCatalogPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter title: 'MCP Tool Catalog'
]

{ #category : 'updating' }
MCPToolsCatalogPresenter >> refreshView [

	| shown all |
	all := self allTools.
	shown := self toolsMatchingFilter: all.
	self fitToolsColumnsTo: all.
	toolsTable items: shown.
	countLabel label: (self countLabelFor: shown size of: all size)
]

{ #category : 'updating' }
MCPToolsCatalogPresenter >> searchTextFor: aTool [

	^ String streamContents: [ :stream |
			  stream
				  << aTool name asLowercase;
				  space;
				  << aTool class groupName asLowercase;
				  space;
				  << aTool title asLowercase;
				  space;
				  << aTool description asLowercase ]
]

{ #category : 'updating' }
MCPToolsCatalogPresenter >> toolsMatchingFilter: someTools [

	| query |
	query := filterInput text asString trimBoth asLowercase.
	query ifEmpty: [ ^ someTools ].
	^ someTools select: [ :tool | (self searchTextFor: tool) includesSubstring: query ]
]

{ #category : 'tool table' }
MCPToolsCatalogPresenter >> toolsTable [

	^ toolsTable
]
