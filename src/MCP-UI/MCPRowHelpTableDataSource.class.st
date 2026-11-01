"
A Morphic table data source that gives every cell of a row the row's help as balloon text, so hovering anywhere on a row shows it.

Spec has help for a whole table, not for a row, so `installOn:help:` replaces the data source Spec built, once the table is built.
"
Class {
	#name : 'MCPRowHelpTableDataSource',
	#superclass : 'SpMorphicTableDataSource',
	#instVars : [
		'rowHelp'
	],
	#category : 'MCP-UI',
	#package : 'MCP-UI'
}

{ #category : 'instance creation' }
MCPRowHelpTableDataSource class >> installOn: aTablePresenter help: aBlock [
	"aBlock answers the help for an item, or nil for none."

	aTablePresenter whenBuiltDo: [ :announcement |
			announcement widget dataSource: (self new
					 model: aTablePresenter;
					 rowHelp: aBlock;
					 yourself) ]
]

{ #category : 'accessing' }
MCPRowHelpTableDataSource >> cellColumn: aColumn row: rowIndex [

	| cell |
	cell := super cellColumn: aColumn row: rowIndex.
	(rowHelp value: (self elementAt: rowIndex)) ifNotNil: [ :help | cell setBalloonText: help ].
	^ cell
]

{ #category : 'accessing' }
MCPRowHelpTableDataSource >> rowHelp: aBlock [

	rowHelp := aBlock
]
