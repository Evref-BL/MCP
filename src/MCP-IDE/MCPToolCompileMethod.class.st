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

{ #category : 'private - errors' }
MCPToolCompileMethod >> anotherMethodIn: aSource upToLine: aLineNumber do: aBlock [
	"aBlock gets the selector line and the number of the earliest line that starts another method, past the first line and no further than aLineNumber, the line the compile failed on: what comes before it is a whole method. The compiler fails on that line, reading its selector as a name it does not know or as a keyword without a receiver, or further on, reading the second body as the rest of the first method's last statement until a return, temporaries or a comment no longer continue it."

	| lineNumber source |
	source := aSource asString.
	lineNumber := 0.
	source lineIndicesDo: [ :start :end :endWithLineEnding |
			lineNumber := lineNumber + 1.
			lineNumber > aLineNumber ifTrue: [ ^ self ].
			lineNumber > 1 ifTrue: [
					(self selectorLineStartingAMethodIn: (source copyFrom: start to: end)) ifNotNil: [ :selectorLineNode |
						(self parsesAsOneMethod: (source first: start - 1)) ifTrue: [ ^ aBlock value: selectorLineNode value: lineNumber ] ] ] ]
]

{ #category : 'private - errors' }
MCPToolCompileMethod >> argumentsChoosingSide: classSide of: request [
	"What a call like request passes to compile on the side classSide, the class side when true: side, and, since each names a side of its own, the class without its side when it was written as Foo class, and a source without the method's reference it began with."

	| className startsWithReference |
	className := request stringArgumentNamed: 'class'.
	startsWithReference := (self headerIn: (request argumentNamed: 'source' ifAbsent: [ nil ])) isNotNil.
	^ String streamContents: [ :stream |
			  (MCPImageLookup namesClassSide: className) ifTrue: [
					  stream << 'class ' << (MCPImageLookup baseNameOf: className) << (startsWithReference
						   ifTrue: [ ', ' ]
						   ifFalse: [ ' and ' ]) ].
			  stream << 'side ' << (self sideNameFor: classSide).
			  startsWithReference ifTrue: [ stream << ' and a source that starts with its selector line' ] ]
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
	"Names the side compiled into, which a header may have chosen when the call did not, and says when a name it did not find is a slot of the other side."

	| summary |
	summary := self classNameAndSideOf: request do: [ :className :classSide :sideGiven |
			           self
				           failureMessageForCompileClassNamed: className
				           classSide: (aBehaviorOrNil ifNil: [ classSide ] ifNotNil: [ :behavior | behavior isClassSide ])
				           error: anError ].
	^ (self otherSideSlotTextFor: anError in: aBehaviorOrNil of: request)
		  ifNil: [ summary ]
		  ifNotNil: [ :slotText | String streamContents: [ :stream | stream << summary << '. ' << slotText ] ]
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
							   of: compiledMethod
							   named: methodReference
							   from: previousProtocolName)
					  data: (self dataForChange: changeKind critiques: critiques)
					  warnings: warningMessages , headerWarnings , (self protocolWarningsFor: compiledMethod from: previousProtocolName) ]
		  failureSummary: [ :error | self failureSummaryFor: error in: behavior of: request ]
]

{ #category : 'private - errors' }
MCPToolCompileMethod >> otherSideSlotTextFor: anError in: aBehaviorOrNil of: request [
	"When the name anError found undeclared is a slot of the other side of aBehaviorOrNil's class or of a superclass, what to do about it; nil otherwise. The source alone does not show which side it was written for. A class side's own slots are its class's, not the ones every class has from Class."

	| name slotName |
	aBehaviorOrNil ifNil: [ ^ nil ].
	name := self undeclaredVariableNameFor: (self mutationFailureCauseFor: anError).
	name ifNil: [ ^ nil ].
	slotName := name asSymbol.
	^ aBehaviorOrNil instanceSide withAllSuperclasses
		  detect: [ :each |
				  (aBehaviorOrNil isClassSide
					   ifTrue: [ each ]
					   ifFalse: [ each classSide ]) slots anySatisfy: [ :slot | slot name = slotName ] ]
		  ifFound: [ :owner |
				  self
					  textForSlotNamed: name
					  of: owner
					  compiledOnClassSide: aBehaviorOrNil isClassSide
					  for: request ]
		  ifNone: [ nil ]
]

{ #category : 'private - errors' }
MCPToolCompileMethod >> parsesAsOneMethod: aString [
	"Whether aString parses as one whole method. Pharo 12 and later signal the error after the block unless it returns."

	RBParser parseMethod: aString onError: [ :message :position | ^ false ].
	^ true
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

{ #category : 'private - errors' }
MCPToolCompileMethod >> selectorLineStartingAMethodIn: aLine [
	"The selector line aLine starts a method with, parsed as a method, or nil: from its first column, aLine holds a whole selector line and nothing else, or the method's reference followed by one, as method_get prints a method."

	| node |
	(aLine isEmpty or: [ aLine first isSeparator ]) ifTrue: [ ^ nil ].
	node := self methodNodeOfSelectorLine:
		        ((MCPMethodReference fromString: aLine) ifNil: [ aLine ] ifNotNil: [ :reference | reference selector ]).
	(node isNotNil and: [ node body statements isEmpty and: [ node pragmas isEmpty ] ]) ifFalse: [ ^ nil ].
	^ node
]

{ #category : 'private - header' }
MCPToolCompileMethod >> sideNameFor: isClassSide [

	^ isClassSide
		  ifTrue: [ 'class' ]
		  ifFalse: [ 'instance' ]
]

{ #category : 'private - errors' }
MCPToolCompileMethod >> signalCompileFailure: anError methodSource: methodSource in: aBehaviorOrNil of: request [
	"A failure at or after a line that starts another method says that the source holds several, rather than what the compiler made of the second where it meets the first."

	anError mcpCommandErrorDo: [ :commandError | commandError signal ] otherwise: [ :compileError |
			| commandError |
			commandError := self
				                commandErrorForCompileFailure: compileError
				                methodSource: methodSource
				                requestedContext: (self requestedContextFor: request)
				                summary: (self failureSummaryFor: compileError in: aBehaviorOrNil of: request).
			commandError details at: #line ifPresent: [ :line |
					self
						anotherMethodIn: methodSource
						upToLine: line
						do: [ :selectorLineNode :lineNumber | self signalSeveralMethodsFrom: selectorLineNode atLine: lineNumber ] ].
			commandError signal ]
]

{ #category : 'private - errors' }
MCPToolCompileMethod >> signalSeveralMethodsFrom: aSelectorLineNode atLine: aLineNumber [
	"A source holding more than one method is refused, naming the line the second begins on. Nothing is compiled."

	| selector |
	selector := aSelectorLineNode selector asString.
	^ MCPCommandError
		  signalErrorCode: #MethodSourceHoldsSeveralMethods
		  message: (String streamContents: [ :stream |
					   stream << 'The source holds more than one method: ' << selector << ' starts another at line ' << aLineNumber printString
					   << '. Pass each method as its own string in a source array.' ])
		  details: {
				  (#line -> aLineNumber).
				  (#nextSelector -> selector) } asDictionary
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
MCPToolCompileMethod >> summaryFor: changeKind of: aCompiledMethod named: methodReference from: previousProtocolName [
	"A method that changed protocol says so. Before protocol was optional, replacing a method's body meant naming a protocol, and naming another one moved the method without a word. A class-side initialize says that compiling did not run it: Pharo runs one when it loads the class, so what it sets stays as it was until it is run."

	| protocolName |
	protocolName := self protocolNameOf: aCompiledMethod.
	^ String streamContents: [ :stream |
			  stream << (self changeSummaryVerbFor: changeKind) << ' ' << methodReference.
			  (changeKind = 'replaced' and: [ previousProtocolName ~= protocolName ]) ifTrue: [
					  stream << ', moving it from ' << (previousProtocolName ifNil: [ 'no protocol' ]) << ' to '
					  << (protocolName ifNil: [ 'no protocol' ]) ].
			  stream << '.'.
			  (aCompiledMethod methodClass isClassSide and: [ aCompiledMethod selector = #initialize ]) ifTrue: [
					  stream << ' Compiling it does not run it: Pharo runs it when it loads the class. Evaluate '
					  << aCompiledMethod methodClass instanceSide name << ' initialize to run it now.' ] ]
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

{ #category : 'private - errors' }
MCPToolCompileMethod >> textForSlotNamed: aName of: aClass compiledOnClassSide: classSide for: request [
	"What to do about aName, a slot aClass defines on the side other than the one compiled into, the class side when classSide is true: the methods of the side compiled into do not see it. The way to the other side is what request passes for it."

	| article otherSide |
	otherSide := self sideNameFor: classSide not.
	article := classSide
		           ifTrue: [ 'an' ]
		           ifFalse: [ 'a' ].
	^ String streamContents: [ :stream |
			  stream << aName << ' is ' << article << ' ' << otherSide << '-side slot of ' << aClass name << ', which '
			  << (self sideNameFor: classSide) << '-side methods do not see. Compile this method with '
			  << (self argumentsChoosingSide: classSide not of: request) << ', or reach ' << aName << ' through ' << article << ' '
			  << otherSide << '-side method.' ]
]
