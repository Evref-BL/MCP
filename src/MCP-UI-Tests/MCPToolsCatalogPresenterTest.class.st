"
Tests for the MCP tool catalog presenter.
"
Class {
	#name : 'MCPToolsCatalogPresenterTest',
	#superclass : 'TestCase',
	#category : 'MCP-UI-Tests-Tools',
	#package : 'MCP-UI-Tests',
	#tag : 'Tools'
}

{ #category : 'tests' }
MCPToolsCatalogPresenterTest >> testCatalogCardRendersFocusedToolIdentity [

	| card presenter |
	presenter := MCPToolsCatalogPresenter new.
	card := presenter toolCatalogCardFor: MCPToolAttachRepository.
	self assert: card isNotNil
]
