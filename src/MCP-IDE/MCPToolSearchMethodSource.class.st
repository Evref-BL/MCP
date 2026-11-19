"
Concrete method_source_search tool. It searches methods by source text through MCPToolMethodSearch.
"
Class {
	#name : 'MCPToolSearchMethodSource',
	#superclass : 'MCPToolMethodSearch',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolSearchMethodSource class >> toolName [

	^ 'method_source_search'
]

{ #category : 'private - methods' }
MCPToolSearchMethodSource >> addMatchContextTo: entry sourceText: sourceText matchStartFinder: aFinder [
	"A hit on source text is read by seeing the line that matched, not by fetching the whole method."

	| lines index |
	sourceText ifNil: [ ^ self ].
	lines := sourceText lines.
	index := self lineNumberOfMatchIn: sourceText lines: lines finder: aFinder.
	index isZero ifTrue: [ ^ self ].
	entry at: #lineNumber put: index.
	entry at: #line put: (lines at: index) trimBoth
]

{ #category : 'metadata' }
MCPToolSearchMethodSource >> buildInputSchema [

	^ MCPStructureInputSchema
		  properties: self methodQueryScopeInputProperties , {
				  (self filterSchemaPropertyWithDescription: 'Text to find in method source. Case matters.').
				  (self
					   filterModeSchemaPropertyWithDescription:
					   'Match query as a substring or as a regular expression. In substring mode, blanks match any blanks, line breaks included.'
					   values: self supportedFilterModes).
				  self offsetInputProperty }
		  required: #( 'query' )
]

{ #category : 'metadata' }
MCPToolSearchMethodSource >> defaultExposure [

	^ 'static'
]

{ #category : 'private - request' }
MCPToolSearchMethodSource >> defaultFilterMode [

	^ 'substring'
]

{ #category : 'metadata' }
MCPToolSearchMethodSource >> description [

	^ 'Find methods by text or regex in their source.'
]

{ #category : 'private - results' }
MCPToolSearchMethodSource >> entryLineTextFor: entry omitting: omittedKeys [
	"ZooAnimal>>plaque line 3: ^ self nickname , ' of the pen '. The line is written as it is, unquoted, since nothing follows it on the row."

	| lineNumber text |
	text := super entryLineTextFor: entry omitting: omittedKeys.
	lineNumber := (self valueIn: entry at: #lineNumber) ifNil: [ ^ text ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: text;
				  nextPutAll: ' line ';
				  nextPutAll: lineNumber asString;
				  nextPutAll: ': ';
				  nextPutAll: ((self valueIn: entry at: #line) ifNil: [ '' ]) asString ]
]

{ #category : 'private - filtering' }
MCPToolSearchMethodSource >> filterTextsForMethodInfo: anInfo sourceText: sourceText [

	^ { sourceText }
]

{ #category : 'private - methods' }
MCPToolSearchMethodSource >> lineNumberOfMatchIn: sourceText lines: lines finder: aFinder [
	"The line a hit is read at: the first line that holds a match by itself. A match that no line holds by itself runs over several lines and is read at the line it starts on: where it starts in the whole text, after as many line breaks as come before it, so the cost grows with the text's length and no faster. A regex match can start with a blank or a line break, on a line that shows none of it, so such a hit names no line. 0 when no line is named."

	| index start |
	index := lines findFirst: [ :each | (aFinder value: each) > 0 ].
	index isZero ifFalse: [ ^ index ].
	start := aFinder value: sourceText.
	((start between: 1 and: sourceText size) and: [ (sourceText at: start) isSeparator not ]) ifFalse: [ ^ 0 ].
	^ self lineNumberAt: start in: sourceText
]

{ #category : 'private - filtering' }
MCPToolSearchMethodSource >> matchStartFinderForPattern: aPattern mode: aMode [
	"Where the filter's first match starts in a text, 0 when the text holds none, the filter read as matcherForPattern:mode:caseSensitive: reads it: as a regex, as pieces joined by any run of blanks, or as a plain substring."

	| pieces |
	aMode = 'regex' ifTrue: [ ^ self regexMatchStartFinderForPattern: aPattern caseSensitive: true ].
	pieces := aPattern substrings.
	pieces size > 1 ifTrue: [ ^ self matchStartFinderForPiecesAcrossBlanks: pieces caseSensitive: true ].
	^ [ :candidate | candidate indexOfSubCollection: aPattern ]
]

{ #category : 'private - filtering' }
MCPToolSearchMethodSource >> matcherForPattern: aPattern mode: aMode caseSensitive: aBoolean [
	"In substring mode, a run of blanks in the filter matches any run of blanks in the source, line breaks included: isNil ifTrue: also finds isNil at the end of one line and ifTrue: at the start of the next. A filter without blanks keeps the plain substring match."

	| pieces |
	pieces := aPattern ifNil: [ #(  ) ] ifNotNil: [ :pattern | pattern substrings ].
	(aMode = 'substring' and: [ pieces size > 1 ]) ifFalse: [
		^ super matcherForPattern: aPattern mode: aMode caseSensitive: aBoolean ].
	^ self matcherForPiecesAcrossBlanks: pieces caseSensitive: aBoolean
]

{ #category : 'private - filtering' }
MCPToolSearchMethodSource >> needsSourceForFiltering [

	^ true
]

{ #category : 'private - template' }
MCPToolSearchMethodSource >> queryEntriesForRequest: request scopeQuery: scopeQuery [

	self requiredFilterPatternFromRequest: request.
	^ super queryEntriesForRequest: request scopeQuery: scopeQuery
]

{ #category : 'private - results' }
MCPToolSearchMethodSource >> redundantKeys [
	"A hit reads like grep: the line that matched closes its row, so its line and number are not fields. The protocol says nothing about where the text matched."

	^ #( isExtension protocol line lineNumber )
]

{ #category : 'private - results' }
MCPToolSearchMethodSource >> successSummaryForRequest: request scopeQuery: scopeQuery page: page [
	"Source writes an argument after each keyword of a selector, so a filter spelled as a selector of several keywords misses every method that implements or sends it. When it finds nothing, the summary says why and names the tools that look for a selector, with the scope the call gave. A scope that names nothing that exists looked nowhere, so the miss is not the selector's and the summary says only that, leaving the next step to the warning about the missing names."

	| selector summary |
	summary := super successSummaryForRequest: request scopeQuery: scopeQuery page: page.
	page totalCount = 0 ifFalse: [ ^ summary ].
	scopeQuery namesNothingThatExists ifTrue: [ ^ summary ].
	selector := self filterPatternFromRequest: request.
	selector numArgs > 1 ifFalse: [ ^ summary ].
	^ String streamContents: [ :stream |
			  stream << summary << ' ' << selector
			  <<
			  ' is a selector: source writes an argument after each of its keywords, so a method that implements or sends it does not contain that text. '.
			  (request hasArgumentNamed: 'scope') ifTrue: [ stream << 'With the same scope, ' ].
			  stream << 'method_reference_search with query ' << selector
			  << ' finds its implementors and senders, and method_search with query ' << selector << ' finds its implementors.' ]
]

{ #category : 'private - schema' }
MCPToolSearchMethodSource >> supportedFilterModes [

	^ #( 'substring' 'regex' )
]

{ #category : 'metadata' }
MCPToolSearchMethodSource >> title [

	^ 'Search Method Source'
]
