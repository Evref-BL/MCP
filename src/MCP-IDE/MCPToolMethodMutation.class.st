"
Shared implementation for method mutation tools.

It defines per-tool input schemas, translates each concrete method tool request into method creation or update requests, and returns method state plus post-compile critiques when relevant.
"
Class {
	#name : 'MCPToolMethodMutation',
	#superclass : 'MCPToolMutation',
	#traits : 'TMCPMethodTool',
	#classTraits : 'TMCPMethodTool classTrait',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolMethodMutation class >> groupName [

	^ self methodsGroupName
]

{ #category : 'testing' }
MCPToolMethodMutation class >> isAbstract [

	^ self = MCPToolMethodMutation
]

{ #category : 'private - errors' }
MCPToolMethodMutation >> addCompileSourceContextFor: methodSource to: details [

	details at: #position ifPresent: [ :position | self addSourceLineContextFor: methodSource position: position to: details ]
]

{ #category : 'private - refactoring' }
MCPToolMethodMutation >> addParameterRefactoringForSelector: oldSelectorSymbol inBehavior: aBehavior to: newSelectorSymbol permutation: permutation newArgs: newArguments model: refactoringModel [

	^ RBAddParameterRefactoring
		  model: refactoringModel
		  addParameterToMethod: oldSelectorSymbol
		  in: aBehavior
		  newSelector: newSelectorSymbol
		  permutation: permutation
		  newArgs: newArguments
]

{ #category : 'private - errors' }
MCPToolMethodMutation >> addSourceLineContextFor: methodSource position: position to: details [

	| boundedPosition column lineEnd lineNumber lineStart sourceLine sourceText |
	sourceText := methodSource ifNil: [ '' ] ifNotNil: [ methodSource asString ].
	sourceText isEmpty ifTrue: [ ^ self ].
	boundedPosition := (position max: 1) min: sourceText size + 1.
	lineStart := sourceText lastIndexOf: Character cr startingAt: boundedPosition - 1 ifAbsent: [ 0 ].
	lineEnd := sourceText indexOf: Character cr startingAt: boundedPosition ifAbsent: [ sourceText size + 1 ].
	lineNumber := (sourceText copyFrom: 1 to: lineStart) occurrencesOf: Character cr.
	column := boundedPosition - lineStart.
	sourceLine := sourceText copyFrom: lineStart + 1 to: lineEnd - 1.
	details
		at: #line put: lineNumber + 1;
		at: #column put: column;
		at: #sourceLine put: sourceLine
]

{ #category : 'metadata' }
MCPToolMethodMutation >> additionalKeywords [

	^ #( 'method' 'refactor' 'refactoring' )
]

{ #category : 'private' }
MCPToolMethodMutation >> allowedNonErrorCritiqueRuleClasses [

	^ {
		  MCPCollectConversionRule.
		  MCPCollectionThenDoRule.
		  MCPDenyRule.
		  MCPDetectIfFoundRule.
		  MCPDictionaryAtIfPresentRule.
		  MCPFilteredEmptinessRule.
		  MCPFilterThenCollectRule.
		  MCPIncludesKeyRule.
		  MCPIsNotEmptyRule.
		  MCPIsNotNilRule.
		  MCPLiftCommonSendRule.
		  MCPMessageNotUnderstoodHandlerRule.
		  MCPNilOnlyConditionalRule.
		  MCPPrintOnStreamRule.
		  MCPRedundantExplicitSelfReturnRule.
		  MCPRespondsToUsageRule.
		  MCPSelectSizeCountRule.
		  MCPSortedCollectionConversionRule.
		  MCPStreamWriteCascadeRule.
		  MCPStringConcatenationRule.
		  ReAssignmentInBlockRule.
		  ReEquivalentSuperclassMethodsRule.
		  ReExcessiveArgumentsRule.
		  ReMissingSuperSendsRule.
		  ReNotOptimizedIfRule.
		  ReNotOptimizedIfNilRule.
		  ReReturnInEnsureRule.
		  ReTempVarOverridesInstVarRule.
		  ReUnaryAccessingMethodWithoutReturnRule }
]

{ #category : 'private - specs' }
MCPToolMethodMutation >> atLeastOneInputProperties [

	^ self methodToolSpec at: #atLeastOneProperties ifAbsent: [ #(  ) ]
]

{ #category : 'private' }
MCPToolMethodMutation >> blockingCritiqueDataForMethodNode: aMethodNode [
	"Nothing is stored yet, so lines count the source as sent."

	| critiques |
	critiques := OrderedCollection new.
	self blockingPreCompileRuleClasses do: [ :ruleClass |
			| rule |
			rule := ruleClass new.
			aMethodNode nodesDo: [ :node | rule check: node forCritiquesDo: [ :critique | critiques add: critique ] ] ].
	^ self distinctCritiqueData: (critiques collect: [ :each | self critiqueDataFor: each source: aMethodNode source ])
]

{ #category : 'private' }
MCPToolMethodMutation >> blockingPreCompileRuleClasses [

	^ { ReDeadBlockRule }
]

{ #category : 'private - arguments' }
MCPToolMethodMutation >> classNameAndSideOf: request do: aBlock [
	"aBlock gets the class the call names without its side, whether the class side is meant, and whether the call said which side, by side or by a class written as Foo class. A side that says the other one is refused."

	^ MCPImageLookup className: (request stringArgumentNamed: 'class') side: (request stringArgumentNamed: 'side') do: aBlock
]

{ #category : 'private' }
MCPToolMethodMutation >> classReferenceNameFor: className classSide: classSide [

	^ classSide
		  ifTrue: [ className , ' class' ]
		  ifFalse: [ className ]
]

{ #category : 'private - errors' }
MCPToolMethodMutation >> commandErrorForCompileFailure: anError methodSource: methodSource requestedContext: requestedContext summary: summary [

	| commandError |
	commandError := self
		                normalizedCommandErrorForActionFailure: anError
		                action: 'compile'
		                requestedContext: requestedContext
		                summary: summary.
	self addCompileSourceContextFor: methodSource to: commandError details.
	^ commandError
]

{ #category : 'private' }
MCPToolMethodMutation >> critiqueData: aCritique isTheSameAs: anotherCritique [
	"Two hits of one rule, with one title, on one interval."

	^ #( ruleClass title start stop ) allSatisfy: [ :key |
		  (aCritique at: key ifAbsent: [ nil ]) = (anotherCritique at: key ifAbsent: [ nil ]) ]
]

{ #category : 'private' }
MCPToolMethodMutation >> critiqueData: aCritique liesStrictlyInside: anotherCritique [
	"A hit of the same rule and title on a part of what another hit already flags, as a rule checking every node of a concatenation flags each of its parts."

	| start stop |
	((aCritique at: #ruleClass) = (anotherCritique at: #ruleClass) and: [ (aCritique at: #title) = (anotherCritique at: #title) ])
		ifFalse: [ ^ false ].
	start := aCritique at: #start ifAbsent: [ ^ false ].
	stop := aCritique at: #stop.
	(anotherCritique includesKey: #start) ifFalse: [ ^ false ].
	(start = (anotherCritique at: #start) and: [ stop = (anotherCritique at: #stop) ]) ifTrue: [ ^ false ].
	^ (anotherCritique at: #start) <= start and: [ stop <= (anotherCritique at: #stop) ]
]

{ #category : 'private' }
MCPToolMethodMutation >> critiqueData: aCritique precedes: anotherCritique [
	"Critiques without a line first, then by line, then by title; the rule and the place break what is left of a tie, so the order never depends on the order Renraku reported them in."

	#( line title ruleClass start ) do: [ :key |
			| left right |
			left := aCritique at: key ifAbsent: [ 0 ].
			right := anotherCritique at: key ifAbsent: [ 0 ].
			left = right ifFalse: [ ^ left < right ] ].
	^ true
]

{ #category : 'private' }
MCPToolMethodMutation >> critiqueDataFor: aCritique source: aString [
	"A critique says where it is by the line of aString its interval starts on and the code there, which the caller can find in the method; its interval stays for a tool that reads offsets. It is fixable when method_rewrite can apply its rule."

	| data interval |
	data := {
		        (#ruleClass -> aCritique rule class name asString).
		        (#title -> aCritique title asString).
		        (#description -> aCritique description asString) } asDictionary.
	interval := self sourceIntervalForCritique: aCritique.
	interval ifNotNil: [
			data
				at: #start put: interval first;
				at: #stop put: interval last.
			aString ifNotNil: [
					data at: #line put: (self lineNumberAt: interval first in: aString).
					(self codeQuoteFor: interval in: aString) ifNotEmpty: [ :code | data at: #code put: code ] ] ].
	(MCPMethodRewriteNamedRuleSpec canApplyRuleClass: aCritique rule class) ifTrue: [ data at: #fixable put: true ].
	^ data
]

{ #category : 'private' }
MCPToolMethodMutation >> critiqueDataForMethod: aCompiledMethod [
	"Critiquing runs every rule in the image, from any package. Pharo guards each rule against errors but not warnings, and a warning a rule raises about its own code, such as a deprecation, says nothing about the method just compiled: it is resumed rather than allowed to turn the compile into a failure. Lines count the source as stored, which is what method_get shows."

	^ self
		  critiqueDataFromProperties: ([ self critiquesOfMethod: aCompiledMethod ]
				   on: Warning
				   do: [ :warning | warning resume ])
		  source: aCompiledMethod sourceCode
]

{ #category : 'private' }
MCPToolMethodMutation >> critiqueDataFromProperties: properties source: aString [

	^ self distinctCritiqueData: (properties
			   select: [ :each | each isCritique and: [ self shouldIncludeCritique: each ] ]
			   thenCollect: [ :each | self critiqueDataFor: each source: aString ])
]

{ #category : 'private - results' }
MCPToolMethodMutation >> critiqueTextOn: stream for: critique indent: indent [
	"line 3: Build strings with a stream, naming the rule only when method_rewrite can apply it, then the code it flags on a line of its own, two spaces further in. A critique without a place has no line and no code."

	stream
		nextPut: Character lf;
		nextPutAll: indent.
	critique at: #line ifPresent: [ :line |
			stream
				nextPutAll: 'line ';
				print: line;
				nextPutAll: ': ' ].
	stream nextPutAll: (critique at: #title).
	(critique at: #fixable ifAbsent: [ false ]) ifTrue: [
			stream
				nextPutAll: ' (method_rewrite ruleClasses: ';
				nextPutAll: (critique at: #ruleClass);
				nextPut: $) ].
	critique at: #code ifPresent: [ :code |
			stream
				nextPut: Character lf;
				nextPutAll: indent;
				nextPutAll: '  ';
				nextPutAll: code ]
]

{ #category : 'private' }
MCPToolMethodMutation >> critiquesOfMethod: aCompiledMethod [
	"What Renraku says of the method when an agent asks, which MCP's own rules answer too. Renraku drops the false positives and adds the forced rules; the rules and classes the package rejects, which only the critique browser reads, are dropped here."

	| manifestRules |
	manifestRules := MCPManifestRules for: aCompiledMethod.
	^ (MCPAgentCritiquing value: true during: [ aCompiledMethod critiques ]) reject: [ :each |
		  each isCritique and: [ manifestRules excludes: each rule on: aCompiledMethod ] ]
]

{ #category : 'metadata' }
MCPToolMethodMutation >> description [

	^ self methodToolSpec at: #description
]

{ #category : 'private' }
MCPToolMethodMutation >> distinctCritiqueData: critiqueData [
	"Each problem once, in the order of the method: of equal hits the first is kept, and a hit lying strictly inside another of the same rule and title says nothing that one does not."

	| distinct |
	distinct := OrderedCollection new.
	critiqueData do: [ :each |
		(distinct anySatisfy: [ :kept | self critiqueData: each isTheSameAs: kept ]) ifFalse: [ distinct add: each ] ].
	^ (distinct reject: [ :each | distinct anySatisfy: [ :other | self critiqueData: each liesStrictlyInside: other ] ]) asArray
		  sort: [ :left :right | self critiqueData: left precedes: right ]
]

{ #category : 'private' }
MCPToolMethodMutation >> failureMessageForArgumentUpdateAction: updateAction classNamed: className classSide: classSide selector: oldSelector newSelector: newSelector error: anError [

	| targetName verb |
	targetName := self classReferenceNameFor: className classSide: classSide.
	verb := updateAction = 'addArguments'
		        ifTrue: [ 'add arguments to' ]
		        ifFalse: [ 'remove arguments from' ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to ';
				  nextPutAll: verb;
				  nextPutAll: ' method ';
				  nextPutAll: targetName;
				  nextPutAll: '>>';
				  nextPutAll: oldSelector;
				  nextPutAll: ' as ';
				  nextPutAll: newSelector;
				  nextPutAll: ': ';
				  nextPutAll: (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolMethodMutation >> failureMessageForChangeProtocolClassNamed: className classSide: classSide selector: selector protocol: protocol error: anError [

	| targetName |
	targetName := self classReferenceNameFor: className classSide: classSide.
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to change protocol for ';
				  nextPutAll: targetName;
				  nextPutAll: '>>';
				  nextPutAll: selector;
				  nextPutAll: ' to ';
				  nextPutAll: protocol;
				  nextPutAll: ': ';
				  nextPutAll: (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolMethodMutation >> failureMessageForCompileClassNamed: className classSide: classSide error: anError [

	| targetName |
	targetName := self classReferenceNameFor: className classSide: classSide.
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to compile method on ';
				  nextPutAll: targetName;
				  nextPutAll: ': ';
				  nextPutAll: (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolMethodMutation >> failureMessageForRenameClassNamed: className classSide: classSide selector: oldSelector newSelector: newSelector error: anError [

	| targetName |
	targetName := self classReferenceNameFor: className classSide: classSide.
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to rename method ';
				  nextPutAll: targetName;
				  nextPutAll: '>>';
				  nextPutAll: oldSelector;
				  nextPutAll: ' to ';
				  nextPutAll: newSelector;
				  nextPutAll: ': ';
				  nextPutAll: (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolMethodMutation >> howToProceedForBlockedCompile [

	^ 'Correct the source and compile it again.'
]

{ #category : 'private - schema' }
MCPToolMethodMutation >> inputProperties [

	^ self methodToolSpec at: #inputProperties
]

{ #category : 'private - specs' }
MCPToolMethodMutation >> methodToolSpec [

	self subclassResponsibility
]

{ #category : 'private - actions' }
MCPToolMethodMutation >> mutationAction [

	^ self methodToolSpec at: #action
]

{ #category : 'private - errors' }
MCPToolMethodMutation >> mutationActionFor: request checked: aBoolean [

	^ self mutationAction
]

{ #category : 'private - errors' }
MCPToolMethodMutation >> mutationActionForErrorFromParsedRequest: mutationRequest rawRequest: rawRequest [

	^ self mutationAction
]

{ #category : 'private - execution' }
MCPToolMethodMutation >> parsedRequestFromToolRequest: request [

	| requestClass |
	requestClass := self mutationAction = 'compile'
		                ifTrue: [ MCPMethodCompileRequest ]
		                ifFalse: [ MCPMethodUpdateRequest ].
	^ requestClass fromRequest: request tool: self
]

{ #category : 'private' }
MCPToolMethodMutation >> reformattedMethodForBehavior: aBehavior selector: aSelector [
	"Not CompiledMethod>>reformat: it formats in the context of the AST node's class, so it reads AST-Core's manifest instead of the formatter the method's own package declares."

	| compiledMethod |
	compiledMethod := aBehavior >> aSelector.
	aBehavior compile: (compiledMethod ast formattedCodeIn: aBehavior) classified: compiledMethod protocol.
	^ aBehavior >> aSelector
]

{ #category : 'private - refactoring' }
MCPToolMethodMutation >> removeParameterRefactoringForArgumentNamed: argumentName inBehavior: aBehavior selector: selectorSymbol model: refactoringModel [

	^ RBRemoveParameterRefactoring
		  model: refactoringModel
		  removeParameter: argumentName
		  in: aBehavior
		  selector: selectorSymbol
]

{ #category : 'private - refactoring' }
MCPToolMethodMutation >> renameRefactoringForSelector: oldSelectorSymbol inBehavior: aBehavior to: newSelectorSymbol permutation: permutation model: refactoringModel [

	^ ReRenameMethodRefactoring
		  model: refactoringModel
		  renameMethod: oldSelectorSymbol
		  in: aBehavior
		  to: newSelectorSymbol
		  permutation: permutation
]

{ #category : 'private - errors' }
MCPToolMethodMutation >> requestedContextFor: request checked: aBoolean [
	"An error raised before the arguments are checked echoes them as the caller wrote them; one raised after, as the tool read them."

	aBoolean ifFalse: [ ^ request asDictionary copy ].
	^ self requestedContextFor: request
]

{ #category : 'private - schema' }
MCPToolMethodMutation >> requiredInputProperties [

	^ self methodToolSpec at: #requiredProperties ifAbsent: [ #( 'class' ) ]
]

{ #category : 'private' }
MCPToolMethodMutation >> shouldIncludeCritique: aCritique [

	^ self shouldIncludeCritiqueRule: aCritique rule
]

{ #category : 'private' }
MCPToolMethodMutation >> shouldIncludeCritiqueRule: aRule [

	^ aRule severity = #error or: [ self allowedNonErrorCritiqueRuleClasses includes: aRule class ]
]

{ #category : 'private' }
MCPToolMethodMutation >> signalBlockingCritiquesForMethodNode: aMethodNode in: aBehavior [
	"A critique that blocks a compile is told in the refusal itself, where a caller reading text sees it, with the lines of the source as sent."

	| critiques |
	critiques := self blockingCritiqueDataForMethodNode: aMethodNode.
	critiques ifEmpty: [ ^ self ].
	MCPCommandError
		signalErrorCode: #CompileBlockedByCritiques
		message: (String streamContents: [ :stream |
					 stream
						 nextPutAll: 'Did not compile ';
						 nextPutAll: (self methodReferenceForBehavior: aBehavior selector: aMethodNode selector);
						 nextPutAll: ', because '.
					 critiques size = 1
						 ifTrue: [ stream nextPutAll: 'a critique blocks' ]
						 ifFalse: [
								 stream
									 print: critiques size;
									 nextPutAll: ' critiques block' ].
					 stream nextPutAll: ' compiling it:'.
					 critiques do: [ :each | self critiqueTextOn: stream for: each indent: '' ].
					 stream
						 nextPut: Character lf;
						 nextPutAll: self howToProceedForBlockedCompile ])
		details: {
				(#critiques -> critiques asArray).
				(#howToProceed -> self howToProceedForBlockedCompile) } asDictionary
]

{ #category : 'private' }
MCPToolMethodMutation >> sourceIntervalForCritique: aCritique [

	| sourceAnchor |
	sourceAnchor := aCritique sourceAnchor.
	sourceAnchor ifNil: [ ^ nil ].
	sourceAnchor providesInterval ifFalse: [ ^ nil ].
	^ sourceAnchor interval
]

{ #category : 'metadata' }
MCPToolMethodMutation >> title [

	^ self methodToolSpec at: #title
]
