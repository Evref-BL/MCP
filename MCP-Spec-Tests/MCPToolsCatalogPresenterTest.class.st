"
Tests for the MCP tool catalog presenter.
"
Class {
	#name : 'MCPToolsCatalogPresenterTest',
	#superclass : 'TestCase',
	#category : 'MCP-Spec-Tests-Tools',
	#package : 'MCP-Spec-Tests',
	#tag : 'Tools'
}

{ #category : 'tests' }
MCPToolsCatalogPresenterTest >> testLongOperationListsAreSummarizedForCatalogRows [

	| presenter summary |
	presenter := MCPToolsCatalogPresenter new.
	summary := presenter toolCatalogOperationSummaryFor:
		           MCPToolEditRepository new.
	self assert: summary equals: 'create | update | +8'.
	self assert: summary size < 24
]

{ #category : 'tests' }
MCPToolsCatalogPresenterTest >> testShortOperationListsAreShownCompletely [

	| presenter summary |
	presenter := MCPToolsCatalogPresenter new.
	summary := presenter toolCatalogOperationSummaryFor:
		           MCPToolEditClass new.
	self assert: summary equals: 'create | update'
]

{ #category : 'tests' }
MCPToolsCatalogPresenterTest >> testShortOperationListsDoNotExposeRedundantOperationHelp [

	| presenter |
	presenter := MCPToolsCatalogPresenter new.
	self assert:
		(presenter toolCatalogOperationHelpFor: MCPToolEditClass new) isNil
]

{ #category : 'tests' }
MCPToolsCatalogPresenterTest >> testSummarizedOperationListsExposeFullOperationHelp [

	| presenter |
	presenter := MCPToolsCatalogPresenter new.
	self
		assert:
		(presenter toolCatalogOperationHelpFor: MCPToolEditRepository new)
		equals:
		'Operations: create | update | export | diff | commit | fetch | pull | push | createBranch | switchBranch'
]
