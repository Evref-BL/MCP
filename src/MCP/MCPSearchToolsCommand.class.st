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
	data at: #tools put: (self visibleTools collect: [ :each | each searchMetadata ] as: Array).
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
	matchingTools ifEmpty: [
			^ request query isEmptyOrNil
				  ifTrue: [ self catalogOverviewText ]
				  ifFalse: [ 'No tool matched. ' , self catalogOverviewText ] ].
	shown := self visibleTools size.
	shown = matchingTools size ifTrue: [ ^ shown asString , ' tools matched, best first.' ].
	^ String streamContents: [ :stream |
			  stream << shown asString << ' of ' << matchingTools size asString
			  << ' matching tools, best first. Add words to narrow the search.' ]
]

{ #category : 'private' }
MCPSearchToolsCommand >> visibleTools [

	^ matchingTools first: (matchingTools size min: self resultLimit)
]
