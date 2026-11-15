"
Command that compiles one method source from a parsed method_compile request.

It reports whether compilation created a new method or replaced an existing method, and includes any method critiques produced after compilation.
"
Class {
	#name : 'MCPCompileMethodCommand',
	#superclass : 'MCPToolRequestCommand',
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'private' }
MCPCompileMethodCommand >> changeSummaryVerbFor: changeKindString [

	changeKindString = 'created' ifTrue: [ ^ 'Created' ].
	changeKindString = 'replaced' ifTrue: [ ^ 'Replaced' ].
	^ 'Changed'
]

{ #category : 'private - header' }
MCPCompileMethodCommand >> droppedHeaderWarning [
	"Generic, so that a batch says it once while each summary names its method."

	^ 'The source began with the method''s reference, which was dropped: a method''s source starts with its selector line.'
]

{ #category : 'executing' }
MCPCompileMethodCommand >> execute [

	| behavior changeKind compiledMethod headerWarnings methodReference methodSource previousProtocolName result selector |
	headerWarnings := #(  ).
	^ self tool
		  executeMutationAction: 'compile'
		  force: self request force
		  requestedContext: self request requestedContext
		  work: [
				  behavior := MCPImageLookup compileTargetNamed: self request className classSide: self request classSide.
				  methodSource := self request methodSource.
				  (self headerIn: methodSource) ifNotNil: [ :header |
						  behavior := self target: behavior forHeader: header source: methodSource.
						  methodSource := self source: methodSource withSelectorLine: header selector.
						  headerWarnings := { self droppedHeaderWarning } ].
				  selector := [ self selectorForMethodSource: methodSource in: behavior ]
					              on: Exception
					              do: [ :error | self signalCompileFailure: error methodSource: methodSource in: behavior ].
				  changeKind := (behavior includesSelector: selector)
					                ifTrue: [ 'replaced' ]
					                ifFalse: [ 'created' ].
				  previousProtocolName := changeKind = 'replaced' ifTrue: [ self protocolNameOf: behavior >> selector ].
				  self tool signalTraitOriginBeforeCompiling: selector in: behavior unlessForced: self request force.
				  "Naming no protocol keeps the one the method is in. Pharo's own compile:classified: with nil does not promise that, so it is passed explicitly."
				  selector := [ behavior mcpCompile: methodSource classified: (self request protocol ifNil: [ previousProtocolName ]) ]
					              on: Exception
					              do: [ :error | self signalCompileFailure: error methodSource: methodSource in: behavior ].
				  compiledMethod := self tool reformattedMethodForBehavior: behavior selector: selector.
				  methodReference := self tool methodReferenceForBehavior: behavior selector: selector.
				  result := MCPMethodCompileResult
					            method: compiledMethod
					            critiques: (self tool critiqueDataForMethod: compiledMethod)
					            changeKind: changeKind ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText: (self
							   summaryFor: result changeKind
							   of: methodReference
							   from: previousProtocolName
							   to: (self protocolNameOf: compiledMethod))
					  data: result asDictionary
					  warnings: warningMessages , headerWarnings , (self protocolWarningsFor: compiledMethod) ]
		  failureSummary: [ :error | self failureSummaryFor: error in: behavior ]
]

{ #category : 'private - errors' }
MCPCompileMethodCommand >> failureSummaryFor: anError in: aBehaviorOrNil [
	"Names the side compiled into, which a header may have chosen when the call did not."

	^ self tool
		  failureMessageForCompileClassNamed: self request className
		  classSide: (aBehaviorOrNil ifNil: [ self request classSide ] ifNotNil: [ :behavior | behavior isClassSide ])
		  error: anError
]

{ #category : 'private - header' }
MCPCompileMethodCommand >> firstLineEndIn: aSource [
	"Where the source's first line ends, at its first CR or LF; zero when it is one line."

	^ aSource asString findFirst: [ :each | each = Character cr or: [ each = Character lf ] ]
]

{ #category : 'private - header' }
MCPCompileMethodCommand >> firstLineOf: aSource [
	"The source's first line as written, without the spaces around it."

	| end |
	end := self firstLineEndIn: aSource.
	^ (end isZero
		   ifTrue: [ aSource asString ]
		   ifFalse: [ aSource asString first: end - 1 ]) trimBoth
]

{ #category : 'private - header' }
MCPCompileMethodCommand >> headerIn: aSource [
	"The method's reference a source begins with, as in EvalRectangle >> #calcArea, read the way method_get reads one; nil when the first line is the method's own. A real method cannot begin with one: a body cannot start with a binary operator, Name >> parses only as a method named Name sending >>, and a reference needs one capitalised word before its separator."

	^ MCPMethodReference fromString: (self firstLineOf: aSource)
]

{ #category : 'private' }
MCPCompileMethodCommand >> isUnclassified: aCompiledMethod [

	^ (self protocolNameOf: aCompiledMethod)
		  ifNil: [ true ]
		  ifNotNil: [ :protocolName | protocolName = Protocol unclassified asString ]
]

{ #category : 'private - header' }
MCPCompileMethodCommand >> methodNodeOfSelectorLine: aSelectorLine [
	"The method aSelectorLine, the text after a header's separator, parses as on its own, or nil when it is not a method's whole first line, as width:height:color: and >= are not, leaving out their argument names. The parser is the one selectorForMethodSource:in: uses; Pharo 12 and later signal the error after the block unless it returns."

	^ RBParser parseMethod: aSelectorLine onError: [ :message :position | ^ nil ]
]

{ #category : 'private' }
MCPCompileMethodCommand >> protocolNameOf: aCompiledMethod [

	^ aCompiledMethod protocolName ifNotNil: [ :protocolName | protocolName asString ]
]

{ #category : 'private' }
MCPCompileMethodCommand >> protocolWarningsFor: aCompiledMethod [
	"Nobody chose to file a method as unclassified: it is what is left when no protocol was named for it. The summary above the warning names the method, and a batch says a warning its methods share once, so the warning does not name it again."

	(self isUnclassified: aCompiledMethod) ifFalse: [ ^ #(  ) ].
	^ { (String streamContents: [ :stream |
			   stream << 'No protocol was named, so it is filed under ''' << Protocol unclassified asString
			   << '''. Name one with protocol, or move it with method_update.' ]) }
]

{ #category : 'private' }
MCPCompileMethodCommand >> selectorForMethodSource: methodSourceString in: aBehavior [

	| methodNode |
	methodNode := RBParser parseMethod: methodSourceString.
	self tool signalBlockingCritiquesForMethodNode: methodNode in: aBehavior.
	^ methodNode selector
]

{ #category : 'private - header' }
MCPCompileMethodCommand >> sideNameFor: isClassSide [

	^ isClassSide
		  ifTrue: [ 'class' ]
		  ifFalse: [ 'instance' ]
]

{ #category : 'private - errors' }
MCPCompileMethodCommand >> signalCompileFailure: anError methodSource: methodSource in: aBehaviorOrNil [

	anError mcpCommandErrorDo: [ :commandError | commandError signal ] otherwise: [ :compileError |
			(self tool
				 commandErrorForCompileFailure: compileError
				 methodSource: methodSource
				 requestedContext: self request requestedContext
				 summary: (self failureSummaryFor: compileError in: aBehaviorOrNil)) signal ]
]

{ #category : 'private - header' }
MCPCompileMethodCommand >> source: aSource holdsNoBodyAfterSelectorLine: aSelectorLineNodeOrNil [
	"Whether a source that begins with a header holds nothing else: only blanks follow its first line, and its selector line, parsed as aSelectorLineNodeOrNil when it is a whole first line, holds no statement or pragma of its own, as #fail or foo: a do not. Such a source names a method rather than writing it."

	| end |
	end := self firstLineEndIn: aSource.
	(end isZero or: [ (aSource asString allButFirst: end) allSatisfy: [ :each | each isSeparator ] ]) ifFalse: [ ^ false ].
	^ aSelectorLineNodeOrNil isNil or: [
		  aSelectorLineNodeOrNil body statements isEmpty and: [ aSelectorLineNodeOrNil pragmas isEmpty ] ]
]

{ #category : 'private - header' }
MCPCompileMethodCommand >> source: aSource withSelectorLine: aSelectorLine [
	"The source with its header replaced by its selector line. The rest is kept from the first line ending on, so the lines keep their numbers and an error in the body reports its own line."

	| end |
	end := self firstLineEndIn: aSource.
	end isZero ifTrue: [ ^ aSelectorLine ].
	^ aSelectorLine , (aSource asString allButFirst: end - 1)
]

{ #category : 'private' }
MCPCompileMethodCommand >> summaryFor: changeKind of: methodReference from: previousProtocolName to: protocolName [
	"A method that changed protocol says so. Before protocol was optional, replacing a method's body meant naming a protocol, and naming another one moved the method without a word."

	^ String streamContents: [ :stream |
			  stream << (self changeSummaryVerbFor: changeKind) << ' ' << methodReference.
			  (changeKind = 'replaced' and: [ previousProtocolName ~= protocolName ]) ifTrue: [
					  stream << ', moving it from ' << (previousProtocolName ifNil: [ 'no protocol' ]) << ' to '
					  << (protocolName ifNil: [ 'no protocol' ]) ].
			  stream << '.' ]
]

{ #category : 'private - header' }
MCPCompileMethodCommand >> target: aBehavior forHeader: aReference source: aSource [
	"The behaviour a source that begins with the method's reference aReference compiles into. The header is dropped only when it names the call's class and side and a whole method follows its separator: dropping any other would compile where the call did not say, leave the body's arguments undeclared, or empty a method. Otherwise nothing is compiled. When the call gave no side, the header's is used."

	| line selectorLineNode targetSide |
	line := self firstLineOf: aSource.
	targetSide := self request sideGiven
		              ifTrue: [ self request classSide ]
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
				className: self request className
				side: (self sideNameFor: targetSide) ].
	^ targetSide
		  ifTrue: [ aBehavior instanceSide classSide ]
		  ifFalse: [ aBehavior instanceSide ]
]
