Extension { #name : 'MCPTool' }

{ #category : '*MCP-IDE' }
MCPTool >> addLineAndCodeAt: anInterval flaggedBy: aRuleClassName in: aString to: data [
	"The line of aString a critique is on and the code there, shown the same way by every answer that shows a critique."

	| quoted |
	quoted := self quoteIntervalAt: anInterval flaggedBy: aRuleClassName in: aString.
	data at: #line put: (self lineNumberAt: quoted first in: aString).
	(self codeQuoteFor: quoted in: aString) ifNotEmpty: [ :code | data at: #code put: code ]
]

{ #category : '*MCP-IDE' }
MCPTool >> codeQuoteFor: anInterval in: aString [
	"The code an interval flags, as flaggedCodeFor:in: reads it, cut to its first 60 characters and ... when longer."

	| code |
	code := self flaggedCodeFor: anInterval in: aString.
	code size > 60 ifFalse: [ ^ code ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: (code first: 60);
				  nextPutAll: '...' ]
]

{ #category : '*MCP-IDE' }
MCPTool >> compactedCode: aString [
	"aString on one line: each run of blanks and line breaks between its tokens reads as one space, and there is none at either end. A string, symbol or character literal is kept as written, blanks included: 'hello   world' is another string than 'hello world', and the blank after a $ is the character it names. A comment is compacted as the code around it is."

	| code |
	code := aString readStream.
	^ String streamContents: [ :stream |
			  code skipSeparators.
			  [ code atEnd ] whileFalse: [
					  | character |
					  character := code next.
					  stream nextPut: character.
					  (character = $$ and: [ code atEnd not ]) ifTrue: [ stream nextPut: code next ].
					  character = $' ifTrue: [ self copyLiteralFrom: code to: stream ].
					  character = $" ifTrue: [ self copyCommentFrom: code to: stream ].
					  (code atEnd not and: [ code peek isSeparator ]) ifTrue: [
							  code skipSeparators.
							  code atEnd ifFalse: [ stream space ] ] ] ]
]

{ #category : '*MCP-IDE' }
MCPTool >> copyCommentFrom: code to: aStream [
	"Copy the rest of a comment from code, up to and with the quote that closes it, each run of blanks and line breaks in it as one space. A comment's blanks change nothing in the program, and a line break in it would break the line a quote is."

	[ code atEnd ] whileFalse: [
			| character |
			character := code next.
			character isSeparator
				ifTrue: [
						code skipSeparators.
						aStream space ]
				ifFalse: [
						aStream nextPut: character.
						character = $" ifTrue: [ ^ self ] ] ]
]

{ #category : '*MCP-IDE' }
MCPTool >> copyLiteralFrom: code to: aStream [
	"Copy the rest of a string or symbol literal from code, as written, up to and with the quote that closes it."

	[ code atEnd ] whileFalse: [
			| character |
			character := code next.
			aStream nextPut: character.
			character = $' ifTrue: [ ^ self ] ]
]

{ #category : '*MCP-IDE' }
MCPTool >> errorResultFor: anError unableTo: aPhrase details: someAssociations [
	"Unable to get class Foo (Error): the message, with what the call named in the details. A command error says it in its own words."

	^ self errorResultFor: anError otherwise: [ :toolError |
			  self
				  errorResultText: (String streamContents: [ :stream |
						   stream << 'Unable to ' << aPhrase << ' (' << toolError class name << '): ' << toolError mcpMessageText ])
				  details: ({
						   (#errorClass -> toolError class name).
						   (#message -> toolError mcpMessageText) } , someAssociations) asDictionary ]
]

{ #category : '*MCP-IDE' }
MCPTool >> flaggedCodeFor: anInterval in: aString [
	"The code an interval flags, from its first character to its last, as compactedCode: reads it. The formatter spreads a long expression over several lines, so the line the code starts on can hold only the receiver of what is flagged."

	(anInterval first between: 1 and: aString size) ifFalse: [ ^ '' ].
	^ self compactedCode: (aString copyFrom: anInterval first to: (anInterval last min: aString size))
]

{ #category : '*MCP-IDE' }
MCPTool >> lineNumberAt: aPosition in: aString [
	"The line of aString that holds aPosition, counting from 1. CR, LF and CRLF each end a line, so a source reads the same lines whichever it uses."

	| line |
	line := 1.
	1 to: (aPosition - 1 min: aString size) do: [ :index |
			| character |
			character := aString at: index.
			(character = Character cr or: [ character = Character lf and: [ index = 1 or: [ (aString at: index - 1) ~= Character cr ] ] ])
				ifTrue: [ line := line + 1 ] ].
	^ line
]

{ #category : '*MCP-IDE' }
MCPTool >> methodSearchScopeSchemaProperties [
	"What a scope selects when the entities are methods: the classes to look in, and which of their sides. side lives here rather than beside scope, so one object answers what this operates on."

	^ self searchScopeSchemaProperties , { (self
		   stringEnumSchemaPropertyNamed: 'side'
		   description: 'Which sides of the selected classes to sweep.'
		   values: #( 'instance' 'class' 'both' )
		   default: 'both') }
]

{ #category : '*MCP-IDE' }
MCPTool >> methodSearchScopeSchemaProperty [

	^ self searchScopeSchemaPropertyWith: self methodSearchScopeSchemaProperties
]

{ #category : '*MCP-IDE' }
MCPTool >> quoteIntervalAt: anInterval flaggedBy: aRuleClassName in: aString [
	"The part of aString a critique's line and code show: the code it flags, except for a send that will not be understood and is too long to quote whole. That one is shown from its first keyword, which the critique is about: from its receiver, the receiver and the first argument would push the other keywords out of the quote, and the formatter may put the receiver on a line of its own. A send written in parentheses leaves out the closing one, as its opening one goes with the receiver."

	(self unimplementedSendRuleNames includes: aRuleClassName) ifFalse: [ ^ anInterval ].
	(self codeQuoteFor: anInterval in: aString) = (self flaggedCodeFor: anInterval in: aString) ifTrue: [ ^ anInterval ].
	^ self
		  sendAt: anInterval
		  in: aString
		  ifFound: [ :send | send keywordsPositions first to: send stopWithoutParentheses ]
		  ifNone: [ anInterval ]
]

{ #category : '*MCP-IDE' }
MCPTool >> scopeQuery: aScopeQuery fromRequest: request [
	"aScopeQuery, given the entries the request's scope names."

	^ aScopeQuery
		  packageNames: (self searchScopeStringCollectionNamed: 'packages' fromRequest: request);
		  classNames: (self searchScopeStringCollectionNamed: 'classes' fromRequest: request);
		  hierarchyClassNames: (self searchScopeStringCollectionNamed: 'hierarchyOf' fromRequest: request);
		  subclassClassNames: (self searchScopeStringCollectionNamed: 'subclassesOf' fromRequest: request);
		  parentClassNames: (self searchScopeStringCollectionNamed: 'superclassesOf' fromRequest: request);
		  yourself
]

{ #category : '*MCP-IDE' }
MCPTool >> searchScopeFromRequest: request [

	^ request argumentNamed: 'scope' ifAbsent: [ Dictionary new ]
]

{ #category : '*MCP-IDE' }
MCPTool >> searchScopeSchemaProperties [
	"One definition of what a scope selects. A class has no side, so side belongs to the method variant rather than here. Several of these together select everything any of them names."

	^ {
		  (self stringArraySchemaNamed: 'classes' description: 'These classes.' itemDescription: 'Class name.').
		  (self stringArraySchemaNamed: 'packages' description: 'Every class in these packages.' itemDescription: 'Package name.').
		  (self
			   stringArraySchemaNamed: 'superclassesOf'
			   description: 'Ancestors of these classes, excluding them.'
			   itemDescription: 'Class name.').
		  (self
			   stringArraySchemaNamed: 'subclassesOf'
			   description: 'Descendants of these classes, excluding them.'
			   itemDescription: 'Class name.').
		  (self
			   stringArraySchemaNamed: 'hierarchyOf'
			   description: 'These classes with their ancestors and descendants.'
			   itemDescription: 'Class name.') }
]

{ #category : '*MCP-IDE' }
MCPTool >> searchScopeSchemaProperty [

	^ self searchScopeSchemaPropertyWith: self searchScopeSchemaProperties
]

{ #category : '*MCP-IDE' }
MCPTool >> searchScopeSchemaPropertyWith: someProperties [

	^ MCPStructureProperties new
		  name: 'scope';
		  type: 'object';
		  description: 'Where to search; entries add up. Omitted, the whole image.';
		  properties: someProperties;
		  additionalProperties: false;
		  yourself
]

{ #category : '*MCP-IDE' }
MCPTool >> searchScopeSideFromRequest: request [
	"Which sides to sweep lives in the scope, beside the entities it narrows."

	^ request argumentOrDefaultNamed: 'side' in: (self searchScopeFromRequest: request)
]

{ #category : '*MCP-IDE' }
MCPTool >> searchScopeStringCollectionNamed: aName fromRequest: request [

	^ request stringCollectionArgumentNamed: aName in: (self searchScopeFromRequest: request)
]

{ #category : '*MCP-IDE' }
MCPTool >> sendAt: anInterval in: aString ifFound: foundBlock ifNone: noneBlock [
	"foundBlock with the send in the method aString that spans anInterval, as a critique of a send gives it, or noneBlock when there is none or aString does not parse."

	^ (RBParser parseMethod: aString onError: [ :message :position | ^ noneBlock value ]) allChildren
		  detect: [ :each | each isMessage and: [ each sourceInterval = anInterval ] ]
		  ifFound: foundBlock
		  ifNone: noneBlock
]

{ #category : '*MCP-IDE' }
MCPTool >> sideNameFor: isClassSide [

	^ isClassSide
		  ifTrue: [ 'class' ]
		  ifFalse: [ 'instance' ]
]

{ #category : '*MCP-IDE' }
MCPTool >> sourceIntervalOf: aSourceAnchor [
	"Where in its source a critique's anchor points, or nil when it gives no interval."

	^ (aSourceAnchor isNotNil and: [ aSourceAnchor providesInterval ]) ifTrue: [ aSourceAnchor interval ]
]

{ #category : '*MCP-IDE' }
MCPTool >> targetSideSchemaPropertyDescribedAs: aDescription [
	"Which side the thing this tool was given is on. A single target is on one side, so there is no 'both' here; scope.side is where a sweep says which sides to cover."

	^ self
		  stringEnumSchemaPropertyNamed: 'side'
		  description: aDescription
		  values: #( 'instance' 'class' )
		  default: 'instance'
]

{ #category : '*MCP-IDE' }
MCPTool >> textWithoutFinalPeriod: aString [
	"One period, so that 'Got 1 instead of 2.' reads on as a clause of a longer sentence, and an ellipsis keeps two."

	^ (aString endsWith: '.')
		  ifTrue: [ aString allButLast ]
		  ifFalse: [ aString ]
]

{ #category : '*MCP-IDE' }
MCPTool >> unimplementedSendRuleNames [
	"The rules that flag a send that will not be understood: ReSentNotImplementedRule when nothing in the image implements its selector, the others when its receiver, self, super or a global, does not, which the first then says too. They are named rather than referenced, since older Pharo versions have no ReSentButNotUnderstoodBySuperRule."

	^ #( #ReSentNotImplementedRule #ReSelfSentNotImplementedRule #ReSendsUnknownMessageToGlobalRule
	     #ReSentButNotUnderstoodBySuperRule )
]
