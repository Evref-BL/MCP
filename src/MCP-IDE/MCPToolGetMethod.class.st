"
Returns structured information for one method, including source and optional variable reference details. It is meant for single-method lookup.
"
Class {
	#name : 'MCPToolGetMethod',
	#superclass : 'MCPTool',
	#traits : 'TMCPMethodTool',
	#classTraits : 'TMCPMethodTool classTrait',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolGetMethod class >> groupName [

	^ self methodsGroupName
]

{ #category : 'metadata' }
MCPToolGetMethod class >> toolName [

	^ 'method_get'
]

{ #category : 'metadata' }
MCPToolGetMethod >> annotations [

	^ MCPStructureToolAnnotations readOnly
]

{ #category : 'metadata' }
MCPToolGetMethod >> batchArgumentName [

	^ 'selector'
]

{ #category : 'metadata' }
MCPToolGetMethod >> batchSummaryNoun [

	^ 'methods'
]

{ #category : 'metadata' }
MCPToolGetMethod >> batchSummaryVerb [

	^ 'Got'
]

{ #category : 'private - analysis' }
MCPToolGetMethod >> bindingClassNameFor: aBinding [

	^ aBinding ifNil: [ 'UnknownBinding' ] ifNotNil: [ :binding | binding class name asString ]
]

{ #category : 'metadata' }
MCPToolGetMethod >> buildInputSchema [

	^ MCPStructureInputSchema
		  properties: {
				  (self schemaPropertyNamed: 'class' type: 'string' description: 'The class to look the method up in.').
				  (self
					   stringOrArraySchemaNamed: 'selector'
					   description: 'The method''s selector, or several of that class.'
					   itemDescription: 'Method name.').
				  (self targetSideSchemaPropertyDescribedAs: 'Which side the method is on.').
				  (self
					   booleanSchemaPropertyNamed: 'includeVariableDetails'
					   description: 'Also report, for every variable the method reads or writes, where it is defined and how often it is used.'
					   default: false) }
		  required: #( 'selector' )
]

{ #category : 'private - errors' }
MCPToolGetMethod >> classNameFor: request checked: aBoolean [
	"The class an error names: the one the arguments name once checked, else the class argument as written, without the side it may name."

	aBoolean ifTrue: [ ^ self methodNamedIn: request do: [ :className :selector :classSide | className ] ].
	^ (self requestedClassNameIn: request) ifNil: [ '' ]
]

{ #category : 'private - errors' }
MCPToolGetMethod >> classSideFor: request checked: aBoolean [
	"Whether an error names the class side: the side the arguments name once checked, else the class side when the call said so."

	aBoolean ifTrue: [ ^ self methodNamedIn: request do: [ :className :selector :classSide | classSide ] ].
	^ self requestedClassSideIn: request
]

{ #category : 'private - results' }
MCPToolGetMethod >> classSideNoteForClassName: className selector: selector [
	"What a call that gave no side is told when the class side was read, since the side it left out reads as the instance side. A method the instance side inherits is named, in case it was the one meant."

	^ ((self behaviorNamed: className classSide: false) lookupSelector: selector asSymbol)
		  ifNil: [ 'It is on the class side, the only side that has it.' ]
		  ifNotNil: [ :inheritedMethod |
				  String streamContents: [ :stream |
						  stream
							  nextPutAll: 'It is on the class side, the only side that has one of its own. The instance side inherits ';
							  nextPutAll:
								  (self methodReferenceForClassName: inheritedMethod methodClass name asString selector: selector isClassSide: false);
							  nextPut: $. ] ]
]

{ #category : 'metadata' }
MCPToolGetMethod >> defaultExposure [

	^ 'static'
]

{ #category : 'private - analysis' }
MCPToolGetMethod >> definingClassNameFromBinding: aBinding [

	^ aBinding ifNotNil: [ :binding | binding definingClass ifNotNil: [ :definingClass | definingClass name ] ]
]

{ #category : 'metadata' }
MCPToolGetMethod >> description [

	^ 'Get the source of a method by its class and selector, or of several methods of that class.'
]

{ #category : 'private - results' }
MCPToolGetMethod >> entryNameKeys [
	"A variable record is the variable of its name."

	^ #( name )
]

{ #category : 'private' }
MCPToolGetMethod >> errorResultForError: anError className: className selector: selectorString classSide: classSide [

	^ anError
		  mcpCommandErrorDo: [ :commandError |
				  | details |
				  details := commandError structuredDetails copy.
				  details at: #class ifAbsentPut: [ className ].
				  details at: #selector ifAbsentPut: [ selectorString ].
				  "A side the error states, such as the one a ClassSideConflict was sent, is kept."
				  classSide ifTrue: [ details at: #side ifAbsentPut: [ 'class' ] ].
				  self errorResultText: commandError messageText details: details ]
		  otherwise: [ :toolError |
				  self
					  errorResultFor: toolError
					  unableTo: 'get method ' , (self methodReferenceForClassName: className selector: selectorString isClassSide: classSide)
					  details: {
							  (#class -> className).
							  (#selector -> selectorString).
							  (#side -> (self sideNameFor: classSide)) } ]
]

{ #category : 'executing' }
MCPToolGetMethod >> executeWithRequest: request [
	"Each selector is read as a method, then got. An error raised before it is read names the class, selector and side as the caller wrote them."

	^ self executeBatchedRequest: request do: [ :targetRequest |
			  | checked |
			  checked := false.
			  self
				  executeRequest: targetRequest
				  do: [
						  self methodNamedIn: targetRequest do: [ :className :selector :classSide :isSideGiven |
								  checked := true.
								  self
									  getMethod: selector
									  in: className
									  classSide: classSide
									  sideGiven: isSideGiven
									  includeVariableDetails: (targetRequest booleanArgumentNamed: 'includeVariableDetails') ] ]
				  onError: [ :error |
						  self
							  errorResultForError: error
							  className: (self classNameFor: targetRequest checked: checked)
							  selector: (self selectorFor: targetRequest checked: checked)
							  classSide: (self classSideFor: targetRequest checked: checked) ] ]
]

{ #category : 'private - execution' }
MCPToolGetMethod >> getMethod: selector in: className classSide: classSide sideGiven: isSideGiven includeVariableDetails: includeVariableDetails [
	"The method a send of selector would run on the side read: the class's own, or the one it inherits, which is answered where it is defined. A bare selector given no side is read on the instance side, unless the class side alone has a method of its own, or alone understands it."

	| behavior compiledMethod data isClassSide |
	isClassSide := classSide or: [ isSideGiven not and: [ self isOnClassSideOnly: selector in: className ] ].
	behavior := self behaviorNamed: className classSide: isClassSide.
	compiledMethod := (behavior lookupSelector: selector asSymbol) ifNil: [
		                  self methodForClassNamed: className selector: selector classSide: isClassSide ].
	data := {
		        (#protocol -> (compiledMethod protocolName ifNil: [ '' ] ifNotNil: [ :protocol | protocol asString ])).
		        (#source -> (compiledMethod sourceCode ifNil: [ '' ])) } asDictionary.
	compiledMethod methodClass == behavior ifFalse: [ data at: #inheritedFrom put: compiledMethod methodClass name asString ].
	(MCPCompiledMethodInfo fromMethod: compiledMethod) traitName ifNotNil: [ :traitName | data at: #trait put: traitName ].
	includeVariableDetails ifTrue: [
		data at: #variableReferences put: (self variableSummariesForMethod: compiledMethod methodBehavior: compiledMethod methodClass) ].
	^ self successResultText: (self successSummaryForMethod: compiledMethod readIn: behavior sideGiven: isSideGiven) data: data
]

{ #category : 'private - analysis' }
MCPToolGetMethod >> incrementReferenceCountInSummary: aSummary [

	aSummary at: #referenceCount put: (aSummary at: #referenceCount) + 1
]

{ #category : 'private - execution' }
MCPToolGetMethod >> isOnClassSideOnly: selector in: className [
	"Whether a bare selector given no side names a class-side method: the class side has a method of its own while the instance side has none, or the class side alone understands it. A method of its own comes first, so the class side's own is read rather than one the instance side inherits."

	| classSide instanceSide symbol |
	symbol := selector asSymbol.
	instanceSide := self behaviorNamed: className classSide: false.
	(instanceSide includesSelector: symbol) ifTrue: [ ^ false ].
	classSide := self behaviorNamed: className classSide: true.
	(classSide includesSelector: symbol) ifTrue: [ ^ true ].
	^ (instanceSide canUnderstand: symbol) not and: [ classSide canUnderstand: symbol ]
]

{ #category : 'private - results' }
MCPToolGetMethod >> keyOrder [
	"Where the method is defined comes before anything about it: a method a class inherits is read in the class that defines it, and one it got from a trait in the trait, and changed there."

	^ #( inheritedFrom trait protocol )
]

{ #category : 'private - analysis' }
MCPToolGetMethod >> matchingSummaryForNodeName: aName kind: aKind ownerName: anOwnerName in: summaries [

	^ summaries
		  detect: [ :each |
			  (each at: #name) = aName and: [ (each at: #kind) = aKind and: [ (each at: #ownerName ifAbsent: [ nil ]) = anOwnerName ] ] ]
		  ifNone: [ nil ]
]

{ #category : 'private - request' }
MCPToolGetMethod >> methodNamedIn: request do: aBlock [
	"Give aBlock the class name without its side, the selector, whether the class side is meant and, to a block that takes it, whether the call said which side. A selector written as a reference names it alone, and its side with it; a bare one needs class, and a class written with its side must agree with side."

	| className text |
	text := request stringArgumentNamed: 'selector'.
	(MCPMethodReference fromString: text) ifNotNil: [ :reference |
			^ aBlock
				  cull: reference className
				  cull: reference selector
				  cull: reference classSide
				  cull: true ].
	className := request stringArgumentNamed: 'class'.
	((MCPMethodReference looksLikeAReference: text) or: [ className isNil ]) ifTrue: [
			MCPCommandError
				signalErrorCode: #MethodReferenceUnreadable
				message: (String streamContents: [ :stream |
						 stream << (text ifNil: [ 'A method' ]) << ' does not name a method. ' << self referenceHelpText ])
				details: { (#selector -> text) } asDictionary ].
	^ MCPImageLookup className: className side: (request stringArgumentNamed: 'side') do: [ :baseName :isClassSide :isSideGiven |
			  aBlock
				  cull: baseName
				  cull: text
				  cull: isClassSide
				  cull: isSideGiven ]
]

{ #category : 'private - analysis' }
MCPToolGetMethod >> newVariableSummaryForNode: aVariableNode kind: aKind methodBehavior: aBehavior [

	| binding ownerName summary |
	binding := aVariableNode binding.
	ownerName := self ownerNameForNode: aVariableNode kind: aKind methodBehavior: aBehavior.
	summary := Dictionary new.
	summary at: #name put: aVariableNode name asString.
	summary at: #kind put: aKind.
	summary at: #bindingClass put: (self bindingClassNameFor: binding).
	summary at: #referenceCount put: 0.
	ownerName ifNotNil: [ summary at: #ownerName put: ownerName ].
	^ summary
]

{ #category : 'private - analysis' }
MCPToolGetMethod >> ownerNameForNode: aVariableNode kind: aKind methodBehavior: aBehavior [
	"Where the variable is defined, for a variable defined outside the method. An argument or a temporary is the method's own, which its kind already says, so it has none."

	| binding definingClassName |
	(#( 'argument' 'temporary' ) includes: aKind) ifTrue: [ ^ nil ].
	(#( 'self' 'super' ) includes: aKind) ifTrue: [ ^ aBehavior name asString ].
	aKind = 'thisContext' ifTrue: [ ^ 'execution context' ].
	binding := aVariableNode binding.
	(#( 'instanceVariable' 'classInstanceVariable' 'classVariable' ) includes: aKind) ifTrue: [
			definingClassName := self definingClassNameFromBinding: binding.
			^ definingClassName ifNil: [ aBehavior name asString ] ].
	aKind = 'poolVariable' ifTrue: [
			definingClassName := self definingClassNameFromBinding: binding.
			^ definingClassName ifNil: [ 'shared pool' ] ].
	(#( 'class' 'global' ) includes: aKind) ifTrue: [ ^ 'Smalltalk globals' ].
	aKind = 'undeclared' ifTrue: [ ^ 'Undeclared' ].
	^ nil
]

{ #category : 'private - results' }
MCPToolGetMethod >> redundantKeys [
	"A variable's binding class restates its kind in Pharo's terms."

	^ #( bindingClass )
]

{ #category : 'private - request' }
MCPToolGetMethod >> referenceHelpText [
	"method_get, unlike the other tools that read a method's reference, has a class argument for a bare selector."

	^ MCPMethodReference helpText , ' A bare selector works too when class is given.'
]

{ #category : 'private - errors' }
MCPToolGetMethod >> selectorFor: request checked: aBoolean [
	"The selector an error names: the one the arguments name once checked, else the selector argument as written."

	aBoolean ifTrue: [ ^ self methodNamedIn: request do: [ :className :selector :classSide | selector ] ].
	^ (request stringArgumentNamed: 'selector') ifNil: [ '' ]
]

{ #category : 'private - results' }
MCPToolGetMethod >> successSummaryForMethod: aCompiledMethod readIn: aBehavior sideGiven: isSideGiven [
	"The method is named where it is defined, which is where it would be changed, and a method aBehavior inherits is followed by aBehavior, the class it was asked of. The class side of a call that gave no side was read because only it has a method of its own, or only it understands the selector, which the answer says."

	| definingClass selector |
	definingClass := aCompiledMethod methodClass.
	selector := aCompiledMethod selector asString.
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Got method ';
				  nextPutAll: (self
						   methodReferenceForClassName: definingClass instanceSide name asString
						   selector: selector
						   isClassSide: definingClass isClassSide).
			  definingClass == aBehavior ifFalse: [
					  stream
						  nextPutAll: ', which ';
						  nextPutAll: aBehavior name asString;
						  nextPutAll: ' inherits' ].
			  stream nextPut: $..
			  (aBehavior isClassSide and: [ isSideGiven not ]) ifTrue: [
					  stream
						  space;
						  nextPutAll: (self classSideNoteForClassName: aBehavior instanceSide name asString selector: selector) ] ]
]

{ #category : 'metadata' }
MCPToolGetMethod >> title [

	^ 'Get Method'
]

{ #category : 'private - analysis' }
MCPToolGetMethod >> variableKindForNode: aVariableNode methodBehavior: aBehavior [

	| binding |
	aVariableNode isSelfVariable ifTrue: [ ^ 'self' ].
	aVariableNode isSuperVariable ifTrue: [ ^ 'super' ].
	aVariableNode isThisContextVariable ifTrue: [ ^ 'thisContext' ].
	aVariableNode isArgumentVariable ifTrue: [ ^ 'argument' ].
	aVariableNode isTempVariable ifTrue: [ ^ 'temporary' ].
	aVariableNode isInstanceVariable ifTrue: [
			^ aBehavior isMeta
				  ifTrue: [ 'classInstanceVariable' ]
				  ifFalse: [ 'instanceVariable' ] ].
	aVariableNode isClassVariable ifTrue: [ ^ 'classVariable' ].
	aVariableNode isGlobalVariable ifFalse: [ ^ 'unknown' ].
	binding := aVariableNode binding.
	binding isUndeclaredVariable ifTrue: [ ^ 'undeclared' ].
	binding isPoolVariable ifTrue: [ ^ 'poolVariable' ].
	binding value isBehavior ifTrue: [ ^ 'class' ].
	^ 'global'
]

{ #category : 'private - analysis' }
MCPToolGetMethod >> variableSummariesForMethod: aCompiledMethod methodBehavior: aBehavior [

	| summaries |
	summaries := OrderedCollection new.
	aCompiledMethod ast allChildren do: [ :node |
			node isVariable ifTrue: [
					| kind ownerName summary |
					kind := self variableKindForNode: node methodBehavior: aBehavior.
					ownerName := self ownerNameForNode: node kind: kind methodBehavior: aBehavior.
					summary := self
						           matchingSummaryForNodeName: node name asString
						           kind: kind
						           ownerName: ownerName
						           in: summaries.
					summary ifNil: [
							summary := self newVariableSummaryForNode: node kind: kind methodBehavior: aBehavior.
							summaries add: summary ].
					self incrementReferenceCountInSummary: summary ] ].
	^ summaries asArray
]
