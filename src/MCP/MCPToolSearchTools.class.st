"
Static bridge tool for searching its owning registry's discoverable tool catalog.

It is intentionally kept on the fast path so agents can find optional or specialized tools without requiring those tools to be statically advertised.
"
Class {
	#name : 'MCPToolSearchTools',
	#superclass : 'MCPTool',
	#instVars : [
		'toolRegistry'
	],
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolSearchTools class >> groupName [

	^ self toolCatalogGroupName
]

{ #category : 'instance creation' }
MCPToolSearchTools class >> newForRegistry: aToolRegistry [

	^ self new
		  toolRegistry: aToolRegistry;
		  yourself
]

{ #category : 'metadata' }
MCPToolSearchTools class >> toolName [

	^ 'tool_search'
]

{ #category : 'metadata' }
MCPToolSearchTools >> annotations [

	^ MCPStructureToolAnnotations readOnly
]

{ #category : 'metadata' }
MCPToolSearchTools >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties:
			  { (self schemaPropertyNamed: 'query' type: 'string' description: 'Search words; tools matching more of them rank first.') };
		  required: #(  );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - results' }
MCPToolSearchTools >> catalogOverviewText [
	"Answer the size and shape of the catalog: a caller that matched nothing needs the vocabulary to search with, not only a count."

	| groups |
	groups := self toolRegistry toolGroups sorted: [ :left :right |
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

{ #category : 'private - results' }
MCPToolSearchTools >> catalogTextForSummary: aSummary tools: toolMetadataEntries [
	"Separate entries with a line feed: a carriage return reaches the caller as an escaped character rather than a line break. A tool that is not advertised says so after its name, since a client that calls only what it lists cannot call it by that name alone."

	^ String streamContents: [ :stream |
			  stream nextPutAll: aSummary.
			  toolMetadataEntries do: [ :each |
					  stream
						  nextPut: Character lf;
						  nextPutAll: (each at: #name).
					  (each at: #exposure ifAbsent: [ nil ]) = 'discoverable' ifTrue: [ stream nextPutAll: ' (not in the advertised list)' ].
					  stream
						  nextPutAll: ' - ';
						  nextPutAll: (each at: #description) ] ]
]

{ #category : 'private - results' }
MCPToolSearchTools >> contentTextForStructuredContent: structuredContent [
	"A catalog listing reads as prose and costs a third fewer characters than its JSON. Error results keep the default shape."

	^ structuredContent
		  at: #data
		  ifPresent: [ :data |
				  self
					  catalogTextForSummary: (structuredContent at: #summary ifAbsent: [ '' ])
					  tools: (data at: #tools) ]
		  ifAbsent: [ super contentTextForStructuredContent: structuredContent ]
]

{ #category : 'metadata' }
MCPToolSearchTools >> defaultExposure [

	^ 'static'
]

{ #category : 'metadata' }
MCPToolSearchTools >> description [

	^ 'Search the whole tool catalog, best match first, including tools not in your list.'
]

{ #category : 'executing' }
MCPToolSearchTools >> executeWithRequest: request [

	^ self
		  executeRequest: request
		  do: [
				  | query matchingTools shownTools data |
				  query := request stringArgumentNamed: 'query'.
				  matchingTools := self toolRegistry toolsMatchingQuery: query.
				  shownTools := matchingTools first: (matchingTools size min: self resultLimit).
				  data := { (#tools -> (shownTools collect: [ :each | self toolRegistry searchMetadataForTool: each ] as: Array)) }
					          asDictionary.
				  self successResultText: (self summaryForQuery: query matching: matchingTools shown: shownTools) data: data ]
		  onError: [ :error | self errorResultFor: error ]
]

{ #category : 'private - results' }
MCPToolSearchTools >> resultLimit [
	"The ranking answers the closest matches; a caller narrows the search with more words instead of paging through worse ones."

	^ 15
]

{ #category : 'private - results' }
MCPToolSearchTools >> summaryForQuery: aQuery matching: matchingTools shown: shownTools [
	"Every registered tool is callable by name; only a client that calls nothing but the tools it lists needs tool_call to reach the others, so the summary says so when it shows one of them."

	matchingTools ifEmpty: [
			^ aQuery isEmptyOrNil
				  ifTrue: [ self catalogOverviewText ]
				  ifFalse: [ 'No tool matched. ' , self catalogOverviewText ] ].
	^ String streamContents: [ :stream |
			  shownTools size = matchingTools size
				  ifTrue: [ stream << (self textForCount: shownTools size noun: 'tool') << ' matched, best first.' ]
				  ifFalse: [
						  stream << shownTools size asString << ' of ' << matchingTools size asString
						  << ' matching tools, best first. Add words to narrow the search.' ].
			  (shownTools anySatisfy: [ :each | (self toolRegistry isToolAdvertised: each) not ]) ifTrue: [
				  stream nextPutAll:
					  ' Tools not in your list can be called by name, or through tool_call if your client only calls listed tools.' ] ]
]

{ #category : 'metadata' }
MCPToolSearchTools >> title [

	^ 'Search Tool Catalog'
]

{ #category : 'accessing' }
MCPToolSearchTools >> toolRegistry [

	^ toolRegistry ifNil: [ toolRegistry := MCPToolRegistry default ]
]

{ #category : 'accessing' }
MCPToolSearchTools >> toolRegistry: aToolRegistry [

	toolRegistry := aToolRegistry
]
