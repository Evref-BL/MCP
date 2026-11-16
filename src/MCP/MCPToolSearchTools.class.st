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

{ #category : 'private - results' }
MCPToolSearchTools >> argumentsTextOn: aStream for: aSearchEntry [
	"Name the arguments of a tool the caller has no schema for, the required ones marked, so that its first call through tool_call can be right."

	| names required |
	names := aSearchEntry at: #arguments.
	names ifEmpty: [ ^ aStream nextPutAll: ' It takes no arguments.' ].
	required := aSearchEntry at: #requiredArguments ifAbsent: [ #(  ) ].
	aStream nextPutAll: ' Arguments: '.
	names
		do: [ :each |
				aStream nextPutAll: each.
				(required includes: each) ifTrue: [ aStream nextPutAll: ' (required)' ] ]
		separatedBy: [ aStream nextPutAll: ', ' ].
	aStream nextPut: $.
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
	"Separate entries with a line feed: a carriage return reaches the caller as an escaped character rather than a line break. A tool that is not advertised says so after its name, since a client that calls only what it lists cannot call it by that name alone, and names its arguments after its description, since that client has no schema for it either."

	^ String streamContents: [ :stream |
			  stream nextPutAll: aSummary.
			  toolMetadataEntries do: [ :each |
					  stream
						  nextPut: Character lf;
						  nextPutAll: (each at: #name).
					  (each at: #exposure ifAbsent: [ nil ]) = 'discoverable' ifTrue: [ stream nextPutAll: ' (not in the advertised list)' ].
					  stream
						  nextPutAll: ' - ';
						  nextPutAll: (each at: #description).
					  (each includesKey: #arguments) ifTrue: [ self argumentsTextOn: stream for: each ] ] ]
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
	"A host may let a model call only the tools in its own list, and the model cannot tell whether its host is one. So when the answer shows a tool outside that list, the summary gives the route every client has, tool_call, with that tool's name in it. It names those tools by the marker their lines carry, so that the route reads as theirs."

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
			  shownTools detect: [ :each | (self toolRegistry isToolAdvertised: each) not ] ifFound: [ :unlisted |
					  stream
					  <<
					  ' Call a tool marked (not in the advertised list) through tool_call, with the arguments its line names: tool_call {"name": "'
					  << unlisted name << '", "arguments": {...}}.' ] ]
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
