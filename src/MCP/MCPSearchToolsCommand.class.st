"
Searches the tool catalog and returns compact metadata for matching tools.

This command supports the discoverable-tool workflow: agents can search by text or group, then read a selected tool contract before invoking it.
"
Class {
	#name : 'MCPSearchToolsCommand',
	#superclass : 'MCPToolCatalogCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPSearchToolsCommand class >> tool: aTool request: aRequest [

	^ self
		  tool: aTool
		  request: aRequest
		  toolExposurePolicy: MCPToolExposurePolicy default
]

{ #category : 'executing' }
MCPSearchToolsCommand >> execute [

	| data matchingTools pageSize visibleTools |
	pageSize := self pageSize.
	matchingTools := MCPToolRegistry
		toolsMatchingQuery: request query
		group: request group
		usingPolicy: self toolExposurePolicy.
	visibleTools := self visibleToolsFrom: matchingTools.
	data := Dictionary new.
	data
		at: #tools
		put: ((visibleTools collect: [ :each |
				  MCPToolRegistry
					  searchMetadataForTool: each
					  usingPolicy: self toolExposurePolicy ]) asArray).
	(self hasMoreToolsAfter: matchingTools) ifTrue: [
		data at: #nextCursor put: (request cursor + pageSize) asString ].
	^ data
]

{ #category : 'private' }
MCPSearchToolsCommand >> hasMoreToolsAfter: matchingTools [

	^ matchingTools size > (request cursor + self pageSize)
]

{ #category : 'accessing' }
MCPSearchToolsCommand >> pageSize [

	^ 25
]

{ #category : 'private' }
MCPSearchToolsCommand >> visibleToolsFrom: matchingTools [

	request cursor >= matchingTools size ifTrue: [ ^ #(  ) ].
	^ matchingTools
		copyFrom: request cursor + 1
		to: (matchingTools size min: (request cursor + self pageSize))
]
