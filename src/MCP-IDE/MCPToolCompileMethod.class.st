"
Tool that compiles one method source into a class.

The compile operation creates the method when its selector is absent and replaces the existing method when the selector is already defined.
"
Class {
	#name : 'MCPToolCompileMethod',
	#superclass : 'MCPToolMethodMutation',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolCompileMethod class >> toolName [

	^ 'method_compile'
]

{ #category : 'metadata' }
MCPToolCompileMethod >> batchArgumentName [

	^ 'source'
]

{ #category : 'metadata' }
MCPToolCompileMethod >> batchSummaryNoun [

	^ 'methods'
]

{ #category : 'metadata' }
MCPToolCompileMethod >> batchSummaryVerb [

	^ 'Compiled'
]

{ #category : 'private' }
MCPToolCompileMethod >> changeSummaryVerbFor: changeKindString [

	changeKindString = 'created' ifTrue: [ ^ 'Created' ].
	changeKindString = 'replaced' ifTrue: [ ^ 'Replaced' ].
	^ 'Changed'
]

{ #category : 'executing' }
MCPToolCompileMethod >> checkArguments: request [
	"A side that says the other one than the class name is refused, as is a call without a source."

	self classNameAndSideOf: request do: [ :className :classSide :sideGiven |  ].
	request argumentNamed: 'source' ifAbsent: [ MCPInvalidToolInput signalMissingRequiredArgumentNamed: 'source' forTool: self ]
]

{ #category : 'private - results' }
MCPToolCompileMethod >> contentTextForStructuredContent: structuredContent [
	"The summary already names the change and its kind. A critique reads as the line it starts on, what it found and the code there, since its interval counts characters of a source the caller never sees; its description is its rule's generic explanation, the same text on every hit."

	| critiques data |
	data := structuredContent at: #data ifAbsent: [ ^ super contentTextForStructuredContent: structuredContent ].
	^ String streamContents: [ :stream |
			  self summaryAndWarningsOn: stream for: structuredContent.
			  critiques := data at: #critiques ifAbsent: [ #(  ) ].
			  critiques ifNotEmpty: [
					  stream
						  nextPut: Character lf;
						  nextPutAll: 'critiques (line numbers count the method as stored; method_get shows it):'.
					  critiques do: [ :critique | self critiqueTextOn: stream for: critique indent: '  ' ] ] ]
]

{ #category : 'private - results' }
MCPToolCompileMethod >> dataForChange: changeKind critiques: critiques [

	| data |
	data := Dictionary new.
	data at: #changeKind put: changeKind.
	critiques ifNotEmpty: [ data at: #critiques put: critiques ].
	^ data
]

{ #category : 'metadata' }
MCPToolCompileMethod >> defaultExposure [

	^ 'static'
]

{ #category : 'private - header' }
MCPToolCompileMethod >> droppedHeaderWarning [
	"Generic, so that a batch says it once while each summary names its method."

	^ 'The source began with the method''s reference, which was dropped: a method''s source starts with its selector line.'
]

{ #category : 'private - errors' }
MCPToolCompileMethod >> failureSummaryFor: anError in: aBehaviorOrNil of: request [
	"Names the side compiled into, which a header may have chosen when the call did not."

	^ self classNameAndSideOf: request do: [ :className :classSide :sideGiven |
			  self
				  failureMessageForCompileClassNamed: className
				  classSide: (aBehaviorOrNil ifNil: [ classSide ] ifNotNil: [ :behavior | behavior isClassSide ])
				  error: anError ]
]

{ #category : 'private - header' }
MCPToolCompileMethod >> firstLineEndIn: aSource [
	"Where the source's first line ends, at its first CR or LF; zero when it is one line."

	^ aSource asString findFirst: [ :each | each = Character cr or: [ each = Character lf ] ]
]

{ #category : 'private - header' }
MCPToolCompileMethod >> firstLineOf: aSource [
	"The source's first line as written, without the spaces around it."

	| end |
	end := self firstLineEndIn: aSource.
	^ (end isZero
		   ifTrue: [ aSource asString ]
		   ifFalse: [ aSource asString first: end - 1 ]) trimBoth
]

{ #category : 'private - schema' }
MCPToolCompileMethod >> forceSchemaProperty [
	"Compiling has one more thing to force than the other mutations: a method the class got from a trait. Overriding one is Pharo's own move, and the override lands in the source of the class, so the caller is allowed it once they say so."

	^ self
		  booleanSchemaPropertyNamed: 'force'
		  description: 'Continue through refactoring warnings instead of stopping, and override a method the class gets from a trait.'
		  default: false
]

{ #category : 'private - header' }
MCPToolCompileMethod >> headerIn: aSource [
	"The method's reference a source begins with, as in EvalRectangle >> #calcArea, read the way method_get reads one; nil when the first line is the method's own. A real method cannot begin with one: a body cannot start with a binary operator, Name >> parses only as a method named Name sending >>, and a reference needs one capitalised word before its separator."

	^ MCPMethodReference fromString: (self firstLineOf: aSource)
]

{ #category : 'private' }
MCPToolCompileMethod >> isUnclassified: aCompiledMethod [

	^ (self protocolNameOf: aCompiledMethod)
		  ifNil: [ true ]
		  ifNotNil: [ :protocolName | protocolName = Protocol unclassified asString ]
]

{ #category : 'private - header' }
MCPToolCompileMethod >> methodNodeOfSelectorLine: aSelectorLine [
	"The method aSelectorLine, the text after a header's separator, parses as on its own, or nil when it is not a method's whole first line, as width:height:color: and >= are not, leaving out their argument names. The parser is the one selectorForMethodSource:in: uses; Pharo 12 and later signal the error after the block unless it returns."

	^ RBParser parseMethod: aSelectorLine onError: [ :message :position | ^ nil ]
]

{ #category : 'private - specs' }
MCPToolCompileMethod >> methodToolSpec [

	^ {
		  (#title -> 'Compile Method').
		  (#description -> 'Add or replace methods in a class from their full source, selector line included.').
		  (#action -> 'compile').
		  (#inputProperties -> {
			   (MCPStructureProperties new
				    name: 'class';
				    type: 'string';
				    description: 'The class to compile into.';
				    yourself).
			   (self targetSideSchemaPropertyDescribedAs: 'Which side to compile into.').
			   (MCPStructureProperties new
				    name: 'source';
				    type: #( 'string' 'array' );
				    description: 'Full method source, selector line included, or several for the same class.';
				    items: (MCPStructureProperties new
						     type: 'string';
						     yourself);
				    yourself).
			   (MCPStructureProperties new
				    name: 'protocol';
				    type: 'string';
				    description:
					    'Protocol for the method; a replaced method keeps its own when omitted. Extension methods take *Package-Name.';
				    yourself).
			   self forceSchemaProperty }).
		  (#requiredProperties -> #( 'class' 'source' )) } asDictionary
]

{ #category : 'executing' }
MCPToolCompileMethod >> mutateWith: request [
	"Compile the source into the class the call names, on the side it names or, when it names none, the side a header names. The answer says whether the method was created or replaced, and what its critiques find in it as stored."

	| behavior changeKind compiledMethod critiques force headerWarnings methodReference methodSource previousProtocolName selector |
	force := request booleanArgumentNamed: 'force'.
	headerWarnings := #(  ).
	^ self
		  executeMutationAction: 'compile'
		  force: force
		  requestedContext: (self requestedContextFor: request)
		  work: [
				  behavior := self
					              classNameAndSideOf: request
					              do: [ :className :classSide :sideGiven | MCPImageLookup compileTargetNamed: className classSide: classSide ].
				  methodSource := request argumentNamed: 'source' ifAbsent: [ nil ].
				  (self headerIn: methodSource) ifNotNil: [ :header |
						  behavior := self
							              target: behavior
							              forHeader: header
							              source: methodSource
							              of: request.
						  methodSource := self source: methodSource withSelectorLine: header selector.
						  headerWarnings := { self droppedHeaderWarning } ].
				  selector := [ self selectorForMethodSource: methodSource in: behavior ]
					              on: Exception
					              do: [ :error |
							              self
								              signalCompileFailure: error
								              methodSource: methodSource
								              in: behavior
								              of: request ].
				  changeKind := (behavior includesSelector: selector)
					                ifTrue: [ 'replaced' ]
					                ifFalse: [ 'created' ].
				  previousProtocolName := changeKind = 'replaced' ifTrue: [ self protocolNameOf: behavior >> selector ].
				  self signalTraitOriginBeforeCompiling: selector in: behavior unlessForced: force.
				  "Naming no protocol keeps the one the method is in. Pharo's own compile:classified: with nil does not promise that, so it is passed explicitly."
				  selector := [
				              behavior
					              mcpCompile: methodSource
					              classified: ((request stringArgumentNamed: 'protocol') ifNil: [ previousProtocolName ]) ]
					              on: Exception
					              do: [ :error |
							              self
								              signalCompileFailure: error
								              methodSource: methodSource
								              in: behavior
								              of: request ].
				  compiledMethod := self reformattedMethodForBehavior: behavior selector: selector.
				  methodReference := self methodReferenceForBehavior: behavior selector: selector.
				  critiques := self critiqueDataForMethod: compiledMethod ]
		  successResult: [ :warningMessages |
				  self
					  successResultText: (self
							   summaryFor: changeKind
							   of: methodReference
							   from: previousProtocolName
							   to: (self protocolNameOf: compiledMethod))
					  data: (self dataForChange: changeKind critiques: critiques)
					  warnings: warningMessages , headerWarnings , (self protocolWarningsFor: compiledMethod from: previousProtocolName) ]
		  failureSummary: [ :error | self failureSummaryFor: error in: behavior of: request ]
]

{ #category : 'private' }
MCPToolCompileMethod >> protocolNameOf: aCompiledMethod [

	^ aCompiledMethod protocolName ifNotNil: [ :protocolName | protocolName asString ]
]

{ #category : 'private' }
MCPToolCompileMethod >> protocolWarningsFor: aCompiledMethod from: previousProtocolName [
	"Nobody chose to file a method as unclassified: it is what is left when no protocol was named for it. The compile that files it there says so, and a replace that leaves it there does not say it again. The summary above the warning names the method, and a batch says a warning its methods share once, so the warning does not name it again."

	((self isUnclassified: aCompiledMethod) and: [ previousProtocolName ~= Protocol unclassified asString ]) ifFalse: [ ^ #(  ) ].
	^ { (String streamContents: [ :stream |
		   stream << 'No protocol was named, so it is filed under ''' << Protocol unclassified asString << '''.' ]) }
]

{ #category : 'private - errors' }
MCPToolCompileMethod >> requestedContextFor: request [
	"The class without its side, and the side."

	^ self classNameAndSideOf: request do: [ :className :classSide :sideGiven |
			  {
				  (#class -> className).
				  (#side -> (self sideNameFor: classSide)) } asDictionary ]
]

{ #category : 'private' }
MCPToolCompileMethod >> selectorForMethodSource: methodSourceString in: aBehavior [

	| methodNode |
	methodNode := RBParser parseMethod: methodSourceString.
	self signalBlockingCritiquesForMethodNode: methodNode in: aBehavior.
	^ methodNode selector
]

{ #category : 'private - header' }
MCPToolCompileMethod >> sideNameFor: isClassSide [

	^ isClassSide
		  ifTrue: [ 'class' ]
		  ifFalse: [ 'instance' ]
]

{ #category : 'private - errors' }
MCPToolCompileMethod >> signalCompileFailure: anError methodSource: methodSource in: aBehaviorOrNil of: request [

	anError mcpCommandErrorDo: [ :commandError | commandError signal ] otherwise: [ :compileError |
			(self
				 commandErrorForCompileFailure: compileError
				 methodSource: methodSource
				 requestedContext: (self requestedContextFor: request)
				 summary: (self failureSummaryFor: compileError in: aBehaviorOrNil of: request)) signal ]
]

{ #category : 'private - header' }
MCPToolCompileMethod >> source: aSource holdsNoBodyAfterSelectorLine: aSelectorLineNodeOrNil [
	"Whether a source that begins with a header holds nothing else: only blanks follow its first line, and its selector line, parsed as aSelectorLineNodeOrNil when it is a whole first line, holds no statement or pragma of its own, as #fail or foo: a do not. Such a source names a method rather than writing it."

	| end |
	end := self firstLineEndIn: aSource.
	(end isZero or: [ (aSource asString allButFirst: end) allSatisfy: [ :each | each isSeparator ] ]) ifFalse: [ ^ false ].
	^ aSelectorLineNodeOrNil isNil or: [
		  aSelectorLineNodeOrNil body statements isEmpty and: [ aSelectorLineNodeOrNil pragmas isEmpty ] ]
]

{ #category : 'private - header' }
MCPToolCompileMethod >> source: aSource withSelectorLine: aSelectorLine [
	"The source with its header replaced by its selector line. The rest is kept from the first line ending on, so the lines keep their numbers and an error in the body reports its own line."

	| end |
	end := self firstLineEndIn: aSource.
	end isZero ifTrue: [ ^ aSelectorLine ].
	^ aSelectorLine , (aSource asString allButFirst: end - 1)
]

{ #category : 'private' }
MCPToolCompileMethod >> summaryFor: changeKind of: methodReference from: previousProtocolName to: protocolName [
	"A method that changed protocol says so. Before protocol was optional, replacing a method's body meant naming a protocol, and naming another one moved the method without a word."

	^ String streamContents: [ :stream |
			  stream << (self changeSummaryVerbFor: changeKind) << ' ' << methodReference.
			  (changeKind = 'replaced' and: [ previousProtocolName ~= protocolName ]) ifTrue: [
					  stream << ', moving it from ' << (previousProtocolName ifNil: [ 'no protocol' ]) << ' to '
					  << (protocolName ifNil: [ 'no protocol' ]) ].
			  stream << '.' ]
]

{ #category : 'private - header' }
MCPToolCompileMethod >> target: aBehavior forHeader: aReference source: aSource of: request [
	"The behaviour a source that begins with the method's reference aReference compiles into. The header is dropped only when it names the call's class and side and a whole method follows its separator: dropping any other would compile where the call did not say, leave the body's arguments undeclared, or empty a method. Otherwise nothing is compiled. When the call gave no side, the header's is used."

	| line selectorLineNode targetSide |
	line := self firstLineOf: aSource.
	^ self classNameAndSideOf: request do: [ :className :classSide :sideGiven |
			  targetSide := sideGiven
				                ifTrue: [ classSide ]
				                ifFalse: [ aReference classSide ].
			  selectorLineNode := self methodNodeOfSelectorLine: aReference selector.
			  (aReference className = aBehavior instanceSide name asString and: [
					   aReference classSide = targetSide and: [
						   selectorLineNode notNil and: [ (self source: aSource holdsNoBodyAfterSelectorLine: selectorLineNode) not ] ] ]) ifFalse: [
					  MCPCommandError
						  signalMethodSourceHeader: line
						  message: 'The source begins with ' , line
							  ,
							  ', a method''s reference. Start it with the method''s selector line, argument names included, then its body; class and side say where it goes.'
						  className: className
						  side: (self sideNameFor: targetSide) ].
			  targetSide
				  ifTrue: [ aBehavior instanceSide classSide ]
				  ifFalse: [ aBehavior instanceSide ] ]
]
