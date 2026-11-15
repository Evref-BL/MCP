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

{ #category : 'private' }
MCPSearchToolsCommand >> catalogOverviewText [
	"Answer the size and shape of the catalog: a caller that matched nothing needs the vocabulary to search with, not only a count."

	| groups |
	groups := self toolRegistry toolGroups asSortedCollection: [ :left :right |
		          left value size = right value size
			          ifTrue: [ left key <= right key ]
			          ifFalse: [ left value size > right value size ] ].
	^ String streamContents: [ :stream |
			  stream
				  print: self toolRegistry tools size;
				  nextPutAll: ' tools in ';
				  print: groups size;
				  nextPutAll: ' groups: '.
			  groups
				  do: [ :each |
						  stream
							  nextPutAll: each key;
							  space;
							  print: each value size ]
				  separatedBy: [ stream nextPutAll: ', ' ].
			  stream nextPutAll: '. Search by keyword.' ]
]

{ #category : 'executing' }
MCPSearchToolsCommand >> execute [

	| data |
	matchingTools := self toolRegistry toolsMatchingQuery: request query.
	data := Dictionary new.
	data at: #tools put: (self visibleTools collect: [ :each | self toolRegistry searchMetadataForTool: each ] as: Array).
	^ data
]

{ #category : 'private' }
MCPSearchToolsCommand >> notAdvertisedText [
	"Every registered tool is callable by name; only a client that calls nothing but the tools it lists needs tool_call to reach the others."

	^ 'Tools not in your list can be called by name, or through tool_call if your client only calls listed tools.'
]

{ #category : 'accessing' }
MCPSearchToolsCommand >> resultLimit [
	"The ranking answers the closest matches; a caller narrows the search with more words instead of paging through worse ones."

	^ 15
]

{ #category : 'private' }
MCPSearchToolsCommand >> showsToolsNotAdvertised [

	^ self visibleTools anySatisfy: [ :each | (self toolRegistry isToolAdvertised: each) not ]
]

{ #category : 'accessing' }
MCPSearchToolsCommand >> summaryText [

	| shown |
	matchingTools ifEmpty: [
			^ request query isEmptyOrNil
				  ifTrue: [ self catalogOverviewText ]
				  ifFalse: [ 'No tool matched. ' , self catalogOverviewText ] ].
	shown := self visibleTools size.
	^ String streamContents: [ :stream |
			  shown = matchingTools size
				  ifTrue: [ stream << (self tool textForCount: shown noun: 'tool') << ' matched, best first.' ]
				  ifFalse: [
						  stream << shown asString << ' of ' << matchingTools size asString
						  << ' matching tools, best first. Add words to narrow the search.' ].
			  self showsToolsNotAdvertised ifTrue: [
					  stream
						  space;
						  nextPutAll: self notAdvertisedText ] ]
]

{ #category : 'private' }
MCPSearchToolsCommand >> visibleTools [

	^ matchingTools first: (matchingTools size min: self resultLimit)
]
