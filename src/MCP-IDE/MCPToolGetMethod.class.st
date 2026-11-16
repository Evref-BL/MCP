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

	| includeVariableDetailsProperty selectorProperty |
	includeVariableDetailsProperty := MCPStructureProperties new
		                                  name: 'includeVariableDetails';
		                                  type: 'boolean';
		                                  description:
			                                  'Also report, for every variable the method reads or writes, where it is defined and how often it is used.';
		                                  default: false;
		                                  yourself.
	selectorProperty := MCPStructureProperties new
		                    name: 'selector';
		                    type: #( 'string' 'array' );
		                    description: 'Class>>selector, Class class>>selector, or a bare selector with class. One or several.';
		                    items: (MCPStructureProperties new
				                     type: 'string';
				                     yourself);
		                    yourself.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (MCPStructureProperties new
					   name: 'class';
					   type: 'string';
					   description: 'Class for bare selectors.';
					   yourself).
				  selectorProperty.
				  (self targetSideSchemaPropertyDescribedAs: 'Which side a bare selector is on.').
				  includeVariableDetailsProperty };
		  required: #( 'selector' );
		  yourself
]

{ #category : 'private - errors' }
MCPToolGetMethod >> classNameFor: request checked: aBoolean [
	"The class an error names: the one the arguments name once checked, else the class argument as written, without the side it may name."

	aBoolean ifTrue: [ ^ self methodNamedIn: request do: [ :className :selector :classSide | className ] ].
	^ (request stringArgumentNamed: 'class') ifNil: [ '' ] ifNotNil: [ :className | MCPImageLookup baseNameOf: className ]
]

{ #category : 'private - errors' }
MCPToolGetMethod >> classSideFor: request checked: aBoolean [
	"Whether an error names the class side: the side the arguments name once checked, else the class side when the call said so, by side or by a class written as Foo class."

	aBoolean ifTrue: [ ^ self methodNamedIn: request do: [ :className :selector :classSide | classSide ] ].
	^ (request stringArgumentNamed: 'side') = 'class' or: [
		  (request stringArgumentNamed: 'class') ifNil: [ false ] ifNotNil: [ :className | MCPImageLookup namesClassSide: className ] ]
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

	^ 'Get the source of methods named Class>>selector or Class class>>selector, one or several.'
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
					  errorResultText: (self
							   failureMessageForClassNamed: className
							   selector: selectorString
							   classSide: classSide
							   error: toolError)
					  details: {
							  (#errorClass -> toolError class name).
							  (#message -> toolError messageText).
							  (#class -> className).
							  (#selector -> selectorString).
							  (#side -> (classSide
								    ifTrue: [ 'class' ]
								    ifFalse: [ 'instance' ])) } asDictionary ]
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
						  self methodNamedIn: targetRequest do: [ :className :selector :classSide |
								  checked := true.
								  self
									  getMethod: selector
									  in: className
									  classSide: classSide
									  includeVariableDetails: (targetRequest booleanArgumentNamed: 'includeVariableDetails') ] ]
				  onError: [ :error |
						  self
							  errorResultForError: error
							  className: (self classNameFor: targetRequest checked: checked)
							  selector: (self selectorFor: targetRequest checked: checked)
							  classSide: (self classSideFor: targetRequest checked: checked) ] ]
]

{ #category : 'private - results' }
MCPToolGetMethod >> failureMessageForClassNamed: className selector: selectorString classSide: classSide error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to get method ';
			  nextPutAll: (self methodReferenceTextForClassName: className selector: selectorString classSide: classSide);
			  nextPutAll: ' (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'private - execution' }
MCPToolGetMethod >> getMethod: selector in: className classSide: classSide includeVariableDetails: includeVariableDetails [

	| compiledMethod data |
	compiledMethod := self methodForClassNamed: className selector: selector classSide: classSide.
	data := {
		        (#protocol -> (compiledMethod protocolName ifNil: [ '' ] ifNotNil: [ :protocol | protocol asString ])).
		        (#source -> (compiledMethod sourceCode ifNil: [ '' ])) } asDictionary.
	(MCPCompiledMethodInfo fromMethod: compiledMethod) traitName ifNotNil: [ :traitName | data at: #trait put: traitName ].
	includeVariableDetails ifTrue: [
			data
				at: #variableReferences
				put: (self variableSummariesForMethod: compiledMethod methodBehavior: (self behaviorNamed: className classSide: classSide)) ].
	^ self successResultText: (self successSummaryForClassName: className selector: selector classSide: classSide) data: data
]

{ #category : 'private - analysis' }
MCPToolGetMethod >> incrementReferenceCountInSummary: aSummary [

	aSummary at: #referenceCount put: (aSummary at: #referenceCount) + 1
]

{ #category : 'private - results' }
MCPToolGetMethod >> keyOrder [
	"Where the method is defined comes before anything about it: a method a class got from a trait is read in the trait and changed there."

	^ #( trait protocol )
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
	"Give aBlock the class name without its side, the selector and whether the class side is meant, for the method the arguments name. A selector written as a reference names it alone; a bare one needs class, and a class written with its side must agree with side."

	| className text |
	text := self selectorStringFromRequest: request.
	(MCPMethodReference fromString: text) ifNotNil: [ :reference |
		^ aBlock value: reference className value: reference selector value: reference classSide ].
	className := request stringArgumentNamed: 'class'.
	((MCPMethodReference looksLikeAReference: text) or: [ className isNil ]) ifTrue: [
			MCPCommandError
				signalErrorCode: #MethodReferenceUnreadable
				message: (String streamContents: [ :stream |
						 stream << (text ifNil: [ 'A method' ]) << ' does not name a method. ' << self referenceHelpText ])
				details: { (#selector -> text) } asDictionary ].
	^ MCPImageLookup
		  className: className
		  side: (request stringArgumentNamed: 'side')
		  do: [ :baseName :isClassSide :isSideGiven | aBlock value: baseName value: text value: isClassSide ]
]

{ #category : 'private - results' }
MCPToolGetMethod >> methodReferenceTextForClassName: className selector: selector classSide: classSide [

	^ className , (classSide
		   ifTrue: [ ' class>>' ]
		   ifFalse: [ '>>' ]) , selector
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
MCPToolGetMethod >> successSummaryForClassName: className selector: selector classSide: classSide [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Got method ';
				  nextPutAll: (self methodReferenceTextForClassName: className selector: selector classSide: classSide);
				  nextPut: $. ]
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
