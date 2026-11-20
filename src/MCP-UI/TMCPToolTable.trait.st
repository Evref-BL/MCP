"
A table of tools, for the presenters that list them: each row starts with the tool's icon, double-clicking a row browses the tool's class, right-clicking one offers to browse, inspect or copy it, and hovering one shows its description.

Its columns start as wide as what they hold, up to a cap, and the last one, where a table of tools puts the description, takes what is left. Spec reads a column's width when it builds the table, so fitting sets where the columns start and resizing them afterwards is kept.

The icon a client is served is 32 square, which a table row clips, so it is scaled once per tool class. The scaled icons are the presenter's, so they go when it goes.
"
Trait {
	#name : 'TMCPToolTable',
	#instVars : [
		'rowIcons'
	],
	#category : 'MCP-UI',
	#package : 'MCP-UI'
}

{ #category : 'tool table' }
TMCPToolTable >> browseSelectedTool [

	self toolsTable selectedItem ifNotNil: [ :tool | tool class browse ]
]

{ #category : 'tool table' }
TMCPToolTable >> connectToolsTable [

	self toolsTable
		contextMenu: [ self toolsContextMenu ];
		whenActivatedDo: [ :selection | self browseSelectedTool ].
	MCPRowHelpTableDataSource installOn: self toolsTable help: [ :tool | tool description ]
]

{ #category : 'tool table' }
TMCPToolTable >> copySelectedToolName [

	self toolsTable selectedItem ifNotNil: [ :tool | Clipboard clipboardText: tool name ]
]

{ #category : 'tool table' }
TMCPToolTable >> fitToolsColumnsTo: someTools [
	"Every column but the last, which takes what is left. A column without a title is an icon and has a width of its own."

	self toolsTable columns allButLast do: [ :column |
		column title ifNotNil: [ column width: (self fittedWidthOf: column for: someTools) ] ]
]

{ #category : 'tool table' }
TMCPToolTable >> fittedWidthOf: aColumn for: someTools [
	"As wide as its title or the widest text it shows, whichever is wider, and never wider than the cap. A checkbox is narrower than any title."

	| font widest |
	font := StandardFonts defaultFont.
	widest := someTools inject: (font widthOfString: aColumn title) into: [ :width :each |
			          | value |
			          value := aColumn readObject: each.
			          value isString
				          ifTrue: [ width max: (font widthOfString: value) ]
				          ifFalse: [ width ] ].
	^ widest + self toolsColumnPadding min: self toolsColumnMaximumWidth
]

{ #category : 'tool table' }
TMCPToolTable >> inspectSelectedTool [

	self toolsTable selectedItem ifNotNil: [ :tool | tool inspect ]
]

{ #category : 'tool table' }
TMCPToolTable >> rowIconColumn [

	^ (SpImageTableColumn evaluated: [ :tool | self rowIconFor: tool ])
		  width: self rowIconSize + 8;
		  yourself
]

{ #category : 'tool table' }
TMCPToolTable >> rowIconFor: aTool [

	^ (rowIcons ifNil: [ rowIcons := Dictionary new ])
		  at: aTool class
		  ifAbsentPut: [ (aTool class toolIconSpec formUsing: MCPStructureIcon) scaledIntoFormOfSize: self rowIconSize ]
]

{ #category : 'tool table' }
TMCPToolTable >> rowIconSize [

	^ 16
]

{ #category : 'tool table' }
TMCPToolTable >> toolDescriptionColumn [

	^ SpStringTableColumn title: 'Description' evaluated: #description
]

{ #category : 'tool table' }
TMCPToolTable >> toolNameColumn [

	^ (SpStringTableColumn title: 'Tool' evaluated: #name)
		  beSortable;
		  yourself
]

{ #category : 'tool table' }
TMCPToolTable >> toolTitleColumn [

	^ (SpStringTableColumn title: 'Title' evaluated: #title)
		  beSortable;
		  yourself
]

{ #category : 'tool table' }
TMCPToolTable >> toolsColumnMaximumWidth [

	^ 240
]

{ #category : 'tool table' }
TMCPToolTable >> toolsColumnPadding [

	^ 20
]

{ #category : 'tool table' }
TMCPToolTable >> toolsContextMenu [

	^ self newMenu
		  addGroup: [ :group |
				  group
					  addItem: [ :item |
							  item
								  name: 'Browse class';
								  description: 'Open the class that implements the selected tool';
								  enabled: [ self toolsTable selectedItem isNotNil ];
								  action: [ self browseSelectedTool ] ];
					  addItem: [ :item |
							  item
								  name: 'Inspect';
								  description: 'Inspect the selected tool';
								  enabled: [ self toolsTable selectedItem isNotNil ];
								  action: [ self inspectSelectedTool ] ];
					  addItem: [ :item |
							  item
								  name: 'Copy name';
								  description: 'Copy the name of the selected tool to the clipboard';
								  enabled: [ self toolsTable selectedItem isNotNil ];
								  action: [ self copySelectedToolName ] ] ];
		  yourself
]

{ #category : 'tool table' }
TMCPToolTable >> toolsTable [

	^ self explicitRequirement
]
