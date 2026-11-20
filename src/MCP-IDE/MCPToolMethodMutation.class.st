"
Shared implementation for the tools that compile and update methods.

Each target of a call is checked, then changed: a concrete tool reads its arguments from the MCPToolRequest, refuses in checkArguments: what reading them can refuse, and makes the change in mutateWith:. An error raised before the arguments are checked echoes them as the caller wrote them; one raised after, as the tool read them. It also reports the critiques of a method it compiled, and the failure of each kind of change.
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

{ #category : 'private' }
MCPToolMethodMutation >> addChainedSendNoteAt: anInterval flaggedBy: aRuleClassName in: aString to: data [
	"A send that nothing implements, whose keywords split into two selectors that are methods somewhere, as sorted:collect: into sorted: and collect:, was most likely meant as two sends: Smalltalk reads the keywords of one send as one selector, so sending the second to what the first answers takes parentheses. The rule's title alone reads as sorted: not being implemented."

	aRuleClassName = ReSentNotImplementedRule name ifFalse: [ ^ self ].
	self
		sendAt: anInterval
		in: aString
		ifFound: [ :send |
				(MCPNotUnderstoodNote
					 chainedSendTextFor: send selector
					 whereFirstPart: [ :firstPart | MCPNotUnderstoodNote isImplementedSelector: firstPart ]) ifNotNil: [ :note |
					data at: #note put: note ] ]
		ifNone: [ ]
]

{ #category : 'private - errors' }
MCPToolMethodMutation >> addCompileSourceContextFor: methodSource to: details [

	details at: #position ifPresent: [ :position | self addSourceLineContextFor: methodSource position: position to: details ]
]

{ #category : 'private' }
MCPToolMethodMutation >> addReceiverNoteAt: anInterval in: aString of: aBehavior to: data [
	"A send that will not be understood may name what its receiver has in another form: a class variable read as a message, a slot that has no accessor, or a method on the other side of a class. The rule's title alone reads as a method that is missing, which the caller then writes or looks for."

	(self unimplementedSendRuleNames includes: (data at: #ruleClass) asSymbol) ifFalse: [ ^ self ].
	self
		sendAt: anInterval
		in: aString
		ifFound: [ :send | (self receiverNoteFor: send in: aBehavior) ifNotNil: [ :note | data at: #note put: note ] ]
		ifNone: [ ]
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
		  MCPSmalltalkGlobalsRule.
		  MCPSortedCollectionConversionRule.
		  MCPStreamWriteCascadeRule.
		  MCPStringConcatenationRule.
		  ReAssignmentInBlockRule.
		  ReEquivalentSuperclassMethodsRule.
		  ReExcessiveArgumentsRule.
		  ReIsNilAndConditionalRule.
		  self isNotNilAndConditionalRuleClass.
		  ReMissingSuperSendsRule.
		  ReReturnInEnsureRule.
		  ReTempVarOverridesInstVarRule.
		  ReUnaryAccessingMethodWithoutReturnRule.
		  ReUseIsEmptyNotSizeRule } , self notOptimizedIfRuleClasses
]

{ #category : 'private' }
MCPToolMethodMutation >> behaviorChangingRewriteRuleClasses [
	"Pharo rewrites a one-armed conditional on these rules whether or not the method reads its value: ^ x isNil ifTrue: [ 1 ] becomes ^ x ifNil: [ 1 ], which answers x when x is set. method_rewrite rewrites at least a whole class, so a critique of one of them names the idiom but not method_rewrite, even on a hit whose rewrite would keep what the method answers. A rule this Pharo lacks reads as nil."

	^ {
		  ReIsNilAndConditionalRule.
		  self isNotNilAndConditionalRuleClass }
]

{ #category : 'private' }
MCPToolMethodMutation >> behaviorReceiving: aSend in: aBehavior [
	"The behavior whose methods run for the receiver of aSend, in a method of aBehavior: aBehavior for self and super, the class side of a class a global names, and the class side of aBehavior for self class on the instance side. nil for any other receiver, which the source alone does not resolve."

	| receiver |
	receiver := aSend receiver.
	(self isSelfOrSuper: receiver) ifTrue: [ ^ aBehavior ].
	(receiver isMessage and: [
		 receiver selector = #class and: [ aBehavior isClassSide not and: [ self isSelfOrSuper: receiver receiver ] ] ]) ifTrue: [
		^ aBehavior classSide ].
	receiver isVariable ifFalse: [ ^ nil ].
	^ (aBehavior instanceSide bindingOf: receiver name asSymbol) ifNotNil: [ :binding |
		  (binding value isBehavior and: [ binding value isClassSide not ]) ifTrue: [ binding value classSide ] ]
]

{ #category : 'private' }
MCPToolMethodMutation >> blockingCritiqueDataForMethodNode: aMethodNode in: aBehavior [
	"Nothing is stored yet, so lines count the source as sent."

	| critiques |
	critiques := OrderedCollection new.
	self blockingPreCompileRuleClasses do: [ :ruleClass |
			| rule |
			rule := ruleClass new.
			aMethodNode nodesDo: [ :node | rule check: node forCritiquesDo: [ :critique | critiques add: critique ] ] ].
	^ self distinctCritiqueData: (critiques collect: [ :each | self critiqueDataFor: each source: aMethodNode source in: aBehavior ])
]

{ #category : 'private' }
MCPToolMethodMutation >> blockingPreCompileRuleClasses [

	^ { ReDeadBlockRule }
]

{ #category : 'private' }
MCPToolMethodMutation >> classSideNoteFor: aSelector of: aClass [
	"When an instance of aClass, sent aSelector by a method of its own, does not understand it and the class side has a method of its own for it, as new: that the class has it, and how to reach it. The class side also understands all that Class, ClassDescription and Behavior give every class, as name, comment or category. An instance-side method that sends one of those to self lacks an accessor, and self class name would quietly answer the name of the class. So only a method defined on a class side counts, of aClass or of a superclass, and the instance creation methods of Behavior."

	| method |
	method := aClass classSide lookupSelector: aSelector.
	(method isNotNil and: [
		 method methodClass isClassSide or: [
			 method methodClass == Behavior and: [ method protocolName asString = 'instance creation' ] ] ]) ifFalse: [ ^ nil ].
	^ String streamContents: [ :stream |
			  stream << 'Instances of ' << aClass name << ' do not understand ' << aSelector << ', ' << aClass name
			  <<
			  ' itself does: this method is on the instance side, where self is an instance. Send it to self class, or compile this method with side class.' ]
]

{ #category : 'private' }
MCPToolMethodMutation >> classVariableNoteFor: aSelector receivedBy: aReceiverBehavior in: aBehavior [
	"When a unary send to a class names one of its class variables, as Units Dozen: the variable it reads as a message, and how the methods of aBehavior read it. By name where it is in their scope, as in its class, a subclass, or a class that uses it as a pool; through a method of its class elsewhere."

	(aSelector isUnary and: [ aReceiverBehavior isClassSide ]) ifFalse: [ ^ nil ].
	^ aReceiverBehavior instanceSide withAllSuperclasses
		  detect: [ :each | each classVarNames includes: aSelector ]
		  ifFound: [ :owner |
				  | reader |
				  reader := aBehavior instanceSide.
				  String streamContents: [ :stream |
						  stream << aSelector << ' is a class variable of ' << owner name << ', not a message. ' << reader name.
						  (reader bindingOf: aSelector) == (owner bindingOf: aSelector)
							  ifTrue: [ stream << ' can read it by name: write ' << aSelector << ' alone.' ]
							  ifFalse: [
									  stream << ' cannot read it by name: only ' << owner name
									  << ', its subclasses and the classes that use it as a pool can. Add a class-side method to ' << owner name
									  << ' that answers it, and send that.' ] ] ]
		  ifNone: [ nil ]
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
MCPToolMethodMutation >> critiqueData: aCritique restates: anotherCritique [
	"A hit saying that the receiver of a send, self, super or a global, does not understand it, on a send that ReSentNotImplementedRule flags: that nothing in the image implements its selector already says so."

	(anotherCritique at: #ruleClass) = ReSentNotImplementedRule name asString ifFalse: [ ^ false ].
	(aCritique at: #ruleClass) = (anotherCritique at: #ruleClass) ifTrue: [ ^ false ].
	(self unimplementedSendRuleNames includes: (aCritique at: #ruleClass) asSymbol) ifFalse: [ ^ false ].
	^ (aCritique at: #start ifAbsent: [ ^ false ]) = (anotherCritique at: #start ifAbsent: [ nil ]) and: [
		  (aCritique at: #stop) = (anotherCritique at: #stop) ]
]

{ #category : 'private' }
MCPToolMethodMutation >> critiqueDataFor: aCritique source: aString in: aBehavior [
	"A critique says where it is by the line of aString its quote starts on and the code there, which the caller can find in the method aBehavior holds; its interval stays for a tool that reads offsets. It is fixable when method_rewrite can apply its rule and the rule is not one whose rewrite can change what a method answers. A send that will not be understood says when it reads as two sends written without their parentheses, or names what its receiver has in another form."

	| data interval ruleClassName |
	ruleClassName := aCritique rule class name.
	data := {
		        (#ruleClass -> ruleClassName asString).
		        (#title -> aCritique title asString).
		        (#description -> aCritique description asString) } asDictionary.
	interval := self sourceIntervalOf: aCritique sourceAnchor.
	interval ifNotNil: [
			data
				at: #start put: interval first;
				at: #stop put: interval last.
			aString ifNotNil: [
					self
						addLineAndCodeAt: interval
						flaggedBy: ruleClassName
						in: aString
						to: data.
					self
						addChainedSendNoteAt: interval
						flaggedBy: ruleClassName
						in: aString
						to: data.
					self
						addReceiverNoteAt: interval
						in: aString
						of: aBehavior
						to: data ] ].
	((MCPMethodRewriteNamedRuleSpec canApplyRuleClass: aCritique rule class) and: [
		 (self behaviorChangingRewriteRuleClasses includes: aCritique rule class) not ]) ifTrue: [ data at: #fixable put: true ].
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
		  in: aCompiledMethod methodClass
]

{ #category : 'private' }
MCPToolMethodMutation >> critiqueDataFromProperties: properties source: aString in: aBehavior [

	^ self distinctCritiqueData: (properties
			   select: [ :each | each isCritique and: [ self shouldIncludeCritique: each ] ]
			   thenCollect: [ :each | self critiqueDataFor: each source: aString in: aBehavior ])
]

{ #category : 'private - results' }
MCPToolMethodMutation >> critiqueTextOn: stream for: critique indent: indent [
	"line 3: Build strings with a stream, naming the rule for method_rewrite only when the critique is fixable, and saying what a send nothing implements was most likely meant as, then the code it flags on a line of its own, two spaces further in. A critique without a place has no line and no code."

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
	critique at: #note ifPresent: [ :note |
			stream
				nextPutAll: '. ';
				nextPutAll: note ].
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

{ #category : 'private' }
MCPToolMethodMutation >> distinctCritiqueData: critiqueData [
	"Each problem once, in the order of the method: of equal hits the first is kept, and a hit lying strictly inside another of the same rule and title, or restating another, says nothing that one does not."

	| distinct kept |
	distinct := OrderedCollection new.
	critiqueData do: [ :each |
		(distinct anySatisfy: [ :other | self critiqueData: each isTheSameAs: other ]) ifFalse: [ distinct add: each ] ].
	kept := distinct reject: [ :each |
			        distinct anySatisfy: [ :other |
				        (self critiqueData: each liesStrictlyInside: other) or: [ self critiqueData: each restates: other ] ] ].
	^ kept asArray sort: [ :left :right | self critiqueData: left precedes: right ]
]

{ #category : 'private - schema' }
MCPToolMethodMutation >> formatSchemaPropertyDescribedAs: aString [
	"Formatting is the default, so that what is compiled reads like the rest of the image. Restoring a method's text from another branch, or a small edit across many methods, needs the text kept as written: formatted, every line the formatter writes differently changes too."

	^ self booleanSchemaPropertyNamed: 'format' description: aString default: true
]

{ #category : 'private' }
MCPToolMethodMutation >> howToProceedForBlockedCompile [

	^ 'Correct the source and compile it again.'
]

{ #category : 'private' }
MCPToolMethodMutation >> instanceSideNoteFor: aSend of: aClass [
	"When aClass itself does not understand aSend and its instances do, as a constructor compiled on the instance side and sent to the class: that its instances have it, and what to do, as MCPNotUnderstoodNote says when the send is made. Sent to self, the sending method is on the class side, which the note says first."

	| method selector |
	selector := aSend selector.
	method := aClass lookupSelector: selector.
	method ifNil: [ ^ nil ].
	^ String streamContents: [ :stream |
			  (self isSelfOrSuper: aSend receiver) ifTrue: [
				  stream << 'This method is on the class side, where self is ' << aClass name << '. ' ].
			  stream << aClass name << ' itself does not understand ' << selector << ', its instances do: it is on the instance side. '
			  << (MCPNotUnderstoodNote instanceSideAdviceFor: method of: aClass) ]
]

{ #category : 'private' }
MCPToolMethodMutation >> isSelfOrSuper: aNode [
	"Whether aNode, parsed without a class to resolve its names in, is self or super."

	^ aNode isVariable and: [ #( 'self' 'super' ) includes: aNode name asString ]
]

{ #category : 'private' }
MCPToolMethodMutation >> otherSideNoteFor: aSend receivedBy: aReceiverBehavior [
	"When the other side of the receiver's class has a method for aSend, as a constructor compiled on the instance side and sent to the class: which side has it, and what to do from the side the sending method is on."

	^ aReceiverBehavior isClassSide
		  ifTrue: [ self instanceSideNoteFor: aSend of: aReceiverBehavior instanceSide ]
		  ifFalse: [ self classSideNoteFor: aSend selector of: aReceiverBehavior ]
]

{ #category : 'private' }
MCPToolMethodMutation >> receiverNoteFor: aSend in: aBehavior [
	"What the receiver of aSend, in a method of aBehavior, has under the name of a message it does not understand: a class variable, a slot with no accessor, or a method on the other side of its class. nil when the source does not show what the receiver is, or it has nothing under that name."

	| receiver |
	receiver := self behaviorReceiving: aSend in: aBehavior.
	receiver ifNil: [ ^ nil ].
	(self classVariableNoteFor: aSend selector receivedBy: receiver in: aBehavior) ifNotNil: [ :note | ^ note ].
	(self slotNoteFor: aSend selector receivedBy: receiver in: aBehavior) ifNotNil: [ :note | ^ note ].
	^ self otherSideNoteFor: aSend receivedBy: receiver
]

{ #category : 'private' }
MCPToolMethodMutation >> reformattedMethodForBehavior: aBehavior selector: aSelector [
	"Not CompiledMethod>>reformat: it formats in the context of the AST node's class, so it reads AST-Core's manifest instead of the formatter the method's own package declares."

	| compiledMethod |
	compiledMethod := aBehavior >> aSelector.
	aBehavior compile: (compiledMethod ast formattedCodeIn: aBehavior) classified: compiledMethod protocol.
	^ aBehavior >> aSelector
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
	critiques := self blockingCritiqueDataForMethodNode: aMethodNode in: aBehavior.
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
MCPToolMethodMutation >> slotNoteFor: aSelector receivedBy: aReceiverBehavior in: aBehavior [
	"When a send to the object running a method of aBehavior is the name of one of its slots, or that name and a colon, as made: on a class side with the slot made, it is an accessor nobody defined, and the method can read or assign the slot itself. A class side's own slots are its class's, not the ones every class has from Class."

	| slotName |
	aReceiverBehavior == aBehavior ifFalse: [ ^ nil ].
	(aSelector isUnary or: [ aSelector isKeyword and: [ aSelector numArgs = 1 ] ]) ifFalse: [ ^ nil ].
	slotName := (aSelector copyWithout: $:) asSymbol.
	^ aBehavior instanceSide withAllSuperclasses
		  detect: [ :each |
				  (aBehavior isClassSide
					   ifTrue: [ each classSide ]
					   ifFalse: [ each ]) slots anySatisfy: [ :slot | slot name = slotName ] ]
		  ifFound: [ :owner |
				  String streamContents: [ :stream |
						  stream << slotName << ' is ' << (aBehavior isClassSide
							   ifTrue: [ 'a class-side' ]
							   ifFalse: [ 'an instance-side' ]) << ' slot of ' << owner name << ' with no accessor ' << aSelector
						  << '. This method can '.
						  aSelector isUnary
							  ifTrue: [ stream << 'read it directly, as ' << slotName << '.' ]
							  ifFalse: [ stream << 'assign it directly, as ' << slotName << ' := ...' ] ] ]
		  ifNone: [ nil ]
]
