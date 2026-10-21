"
Searches the tool catalog and returns compact metadata for matching tools.

This command supports the discoverable-tool workflow: agents can search by text, then read a selected tool contract before invoking it.
"
Class {
	#name : 'MCPSearchToolsCommand',
	#superclass : 'MCPToolCatalogCommand',
	#instVars : [
		'matchingTools'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPSearchToolsCommand class >> tool: aTool request: aRequest [

	^ self tool: aTool request: aRequest toolRegistry: MCPToolRegistry default
]

{ #category : 'executing' }
MCPSearchToolsCommand >> execute [

	| data |
	matchingTools := self toolRegistry toolsMatchingQuery: request query.
	data := Dictionary new.
	data at: #tools put: (self visibleTools collect: [ :each | each searchMetadata ]) asArray.
	^ data
]

{ #category : 'accessing' }
MCPSearchToolsCommand >> resultLimit [
	"The ranking answers the closest matches; a caller narrows the search with more words instead of paging through worse ones."

	^ 15
]

{ #category : 'accessing' }
MCPSearchToolsCommand >> summaryText [

	| shown |
	matchingTools ifEmpty: [ ^ '0 of ' , self toolRegistry publicTools size asString , ' tools matched.' ].
	shown := self visibleTools size.
	shown = matchingTools size ifTrue: [ ^ shown asString , ' tools matched, best first.' ].
	^ shown asString , ' of ' , matchingTools size asString , ' matching tools, best first. Add words to narrow the search.'
]

{ #category : 'private' }
MCPSearchToolsCommand >> visibleTools [

	^ matchingTools first: (matchingTools size min: self resultLimit)
]
