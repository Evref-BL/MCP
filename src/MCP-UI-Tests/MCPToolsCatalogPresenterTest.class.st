"
Tests for the MCP tool catalog presenter.
"
Class {
	#name : 'MCPToolsCatalogPresenterTest',
	#superclass : 'TestCase',
	#category : 'MCP-UI-Tests',
	#package : 'MCP-UI-Tests'
}

{ #category : 'tests' }
MCPToolsCatalogPresenterTest >> testAnUnfilteredCountNamesTheWholeCatalog [

	| presenter |
	presenter := MCPToolsCatalogPresenter new.

	self assert: (presenter instVarNamed: #countLabel) label equals: presenter allTools size printString , ' tools'
]

{ #category : 'tests' }
MCPToolsCatalogPresenterTest >> testCatalogListsEveryToolTheImageHas [

	| presenter |
	presenter := MCPToolsCatalogPresenter new.

	self assert: (presenter instVarNamed: #toolsTable) items size equals: presenter allTools size.
	self assert: presenter allTools size equals: MCPToolRegistry default toolClasses size
]

{ #category : 'tests' }
MCPToolsCatalogPresenterTest >> testFilterMatchesDescriptionAndGroupTooNotOnlyTheName [

	| presenter tool |
	presenter := MCPToolsCatalogPresenter new.
	tool := presenter allTools detect: [ :each | each name = 'class_get' ].

	self assert: ((presenter searchTextFor: tool) includesSubstring: 'classes').
	self assert: ((presenter searchTextFor: tool) includesSubstring: 'metadata')
]

{ #category : 'tests' }
MCPToolsCatalogPresenterTest >> testFilterNarrowsTheListAndSaysSoInTheCount [

	| presenter table |
	presenter := MCPToolsCatalogPresenter new.
	table := presenter instVarNamed: #toolsTable.

	(presenter instVarNamed: #filterInput) text: 'class'.
	presenter refreshView.

	"The filter reads name, group, title and description, so a tool matches on any of them."
	self assert: (table items allSatisfy: [ :each | (presenter searchTextFor: each) includesSubstring: 'class' ]).
	self assert: (table items anySatisfy: [ :each | each name includesSubstring: 'class' ]).
	self assert: table items size < presenter allTools size.
	self assert: ((presenter instVarNamed: #countLabel) label includesSubstring: ' of ')
]

{ #category : 'tests' }
MCPToolsCatalogPresenterTest >> testRowIconsAreBuiltOncePerToolClass [

	| presenter tool |
	presenter := MCPToolsCatalogPresenter new.
	tool := presenter allTools first.

	self assert: (presenter rowIconFor: tool) == (presenter rowIconFor: tool)
]

{ #category : 'tests' }
MCPToolsCatalogPresenterTest >> testRowIconsAreScaledToFitARow [
	"The icon a client is served is 32 square, which a table row clips."

	| presenter tool |
	presenter := MCPToolsCatalogPresenter new.
	tool := presenter allTools first.

	self assert: (MCPTool toolIconFormOf: tool class) extent equals: 32 @ 32.
	self assert: (presenter rowIconFor: tool) extent equals: presenter rowIconSize @ presenter rowIconSize
]
