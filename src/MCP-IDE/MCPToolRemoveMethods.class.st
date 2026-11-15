"
Removes methods from one class in one batch. It is intentionally direct and does not perform sender safety checks.
"
Class {
	#name : 'MCPToolRemoveMethods',
	#superclass : 'MCPTool',
	#traits : 'TMCPMethodTool',
	#classTraits : 'TMCPMethodTool classTrait',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolRemoveMethods class >> groupName [

	^ self methodsGroupName
]

{ #category : 'metadata' }
MCPToolRemoveMethods class >> toolName [

	^ 'method_remove'
]

{ #category : 'metadata' }
MCPToolRemoveMethods >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (MCPStructureProperties new
					   name: 'class';
					   type: 'string';
					   description: 'The class to remove the methods from.';
					   yourself).
				  (self targetSideSchemaPropertyDescribedAs: 'Which side to remove from.').
				  ((MCPStructureProperties new
					    name: 'selector';
					    type: #( 'string' 'array' );
					    description: 'The selector to remove, or several removed together as one change.')
					   items: (MCPStructureProperties new
							    type: 'string';
							    yourself);
					   yourself) };
		  required: #( 'class' 'selector' );
		  yourself
]

{ #category : 'private - errors' }
MCPToolRemoveMethods >> classNameForErrorFromParsedRequest: removeRequest rawRequest: rawRequest [
	"The request did not parse, so the class is read from the raw text, without the side it may name."

	removeRequest ifNotNil: [ ^ removeRequest className ].
	^ (rawRequest stringArgumentNamed: 'class') ifNil: [ '' ] ifNotNil: [ :className | MCPImageLookup baseNameOf: className ]
]

{ #category : 'private - errors' }
MCPToolRemoveMethods >> classSideForErrorFromParsedRequest: removeRequest rawRequest: rawRequest [
	"The request did not parse: the class side is meant when the call said so, by side or by a class written as Foo class."

	removeRequest ifNotNil: [ ^ removeRequest classSide ].
	^ (rawRequest stringArgumentNamed: 'side') = 'class' or: [
		  (rawRequest stringArgumentNamed: 'class') ifNil: [ false ] ifNotNil: [ :className | MCPImageLookup namesClassSide: className ] ]
]

{ #category : 'private - execution' }
MCPToolRemoveMethods >> commandForRequest: removeRequest [

	^ MCPRemoveMethodsCommand tool: self request: removeRequest
]

{ #category : 'metadata' }
MCPToolRemoveMethods >> defaultExposure [

	^ 'static'
]

{ #category : 'metadata' }
MCPToolRemoveMethods >> description [

	^ 'Remove methods from one class. Senders do not stop it; the answer warns of sends it leaves without a method.'
]

{ #category : 'private' }
MCPToolRemoveMethods >> errorResultForError: anError className: className classSide: classSide selectors: selectors [

	^ anError
		  mcpCommandErrorDo: [ :commandError | self errorResultText: commandError messageText details: commandError structuredDetails ]
		  otherwise: [ :toolError |
				  self
					  errorResultText: (self
							   failureMessageForClassNamed: className
							   classSide: classSide
							   selectors: selectors
							   error: toolError)
					  details: {
							  (#errorClass -> toolError class name).
							  (#message -> toolError messageText).
							  (#class -> className).
							  (#side -> (classSide ifTrue: [ 'class' ] ifFalse: [ 'instance' ])).
							  (#selectors -> selectors asArray) } asDictionary ]
]

{ #category : 'executing' }
MCPToolRemoveMethods >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :removeRequest |
				  | result |
				  result := (self commandForRequest: removeRequest) execute.
				  self
					  successResultText:
					  (self successSummaryForClassName: result className classSide: result classSide selectors: result selectors)
					  data: result asDictionary
					  warnings: result warningMessages ]
		  onError: [ :error :removeRequest |
				  self
					  errorResultForError: error
					  className: (self classNameForErrorFromParsedRequest: removeRequest rawRequest: request)
					  classSide: (self classSideForErrorFromParsedRequest: removeRequest rawRequest: request)
					  selectors: (self selectorsForErrorFromParsedRequest: removeRequest rawRequest: request) ]
]

{ #category : 'private' }
MCPToolRemoveMethods >> failureMessageForClassNamed: className classSide: classSide selectors: selectors error: anError [

	| targetName |
	targetName := classSide
		              ifTrue: [ className , ' class' ]
		              ifFalse: [ className ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to remove methods from ';
				  nextPutAll: targetName;
				  nextPutAll: ': ';
				  nextPutAll: (', ' join: selectors);
				  nextPutAll: ' (';
				  nextPutAll: anError class name;
				  nextPutAll: '): ';
				  nextPutAll: anError messageText ]
]

{ #category : 'private - warnings' }
MCPToolRemoveMethods >> hierarchySendWarningFor: aSelector sends: brokenSends from: aBehavior [
	"EvalPayroll>>lines and EvalPayroll>>total still send employees to self, which EvalPayroll no longer understands."

	| receivers |
	receivers := Set new.
	brokenSends valuesDo: [ :each | receivers addAll: each ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: (self listTextForMethods: brokenSends keys);
				  nextPutAll: (brokenSends size = 1
						   ifTrue: [ ' still sends ' ]
						   ifFalse: [ ' still send ' ]);
				  nextPutAll: aSelector;
				  nextPutAll: ' to ';
				  nextPutAll: (receivers size > 1
						   ifTrue: [ 'self or super' ]
						   ifFalse: [ receivers anyOne ]);
				  nextPutAll: ', which ';
				  nextPutAll: (self targetNameForBehavior: aBehavior);
				  nextPutAll: ' no longer understands.' ]
]

{ #category : 'private - warnings' }
MCPToolRemoveMethods >> hierarchySendsBrokenByRemoving: aSelector from: aBehavior [
	"The methods the class and its subclasses define themselves, on the side removed from, that send aSelector to self where their class no longer understands it, or to super where their superclass no longer does, each with the receivers it sends it to. Only a class that inherits from aBehavior lost the method, so a send nothing understood before is left out, and a method is parsed only when one of its lookups lost it."

	| brokenSends |
	brokenSends := IdentityDictionary new.
	(self matchingSelectorReferencesForSelector: aSelector inMethods: (self localMethodsOfHierarchyOf: aBehavior)) do: [ :method |
			| selfLost superLost receivers |
			selfLost := self lookupFrom: method methodClass lost: aSelector removedFrom: aBehavior.
			superLost := self lookupFrom: method methodClass superclass lost: aSelector removedFrom: aBehavior.
			(selfLost or: [ superLost ]) ifTrue: [
					receivers := Set new.
					method ast sendNodes do: [ :node |
							node selector = aSelector ifTrue: [
									(selfLost and: [ node isSelfSend ]) ifTrue: [ receivers add: 'self' ].
									(superLost and: [ node isSuperSend ]) ifTrue: [ receivers add: 'super' ] ] ].
					receivers ifNotEmpty: [ brokenSends at: method put: receivers ] ] ].
	^ brokenSends
]

{ #category : 'private - warnings' }
MCPToolRemoveMethods >> imageImplements: aSelector [
	"Whether a class or trait of the image still has a method for aSelector; the search stops at the first it finds."

	Smalltalk globals allBehaviorsDo: [ :each | (each includesSelector: aSelector) ifTrue: [ ^ true ] ].
	^ false
]

{ #category : 'private - warnings' }
MCPToolRemoveMethods >> listTextForMethods: someMethods [
	"The methods as Pharo writes them, sorted: A, A and B, A, B and C; past ten, the first ten and how many more."

	| references |
	references := (someMethods
		               collect: [ :each | self methodReferenceForBehavior: each methodClass selector: each selector ]
		               as: Array) sort.
	references size > 10 ifFalse: [ ^ MCPScopeQuery listPhraseFor: references ].
	^ String streamContents: [ :stream |
			  (references first: 10) do: [ :each | stream nextPutAll: each ] separatedBy: [ stream nextPutAll: ', ' ].
			  stream
				  nextPutAll: ', and ';
				  print: references size - 10;
				  nextPutAll: ' more' ]
]

{ #category : 'private - warnings' }
MCPToolRemoveMethods >> localMethodsOfHierarchyOf: aBehavior [
	"The methods the class and its subclasses define themselves, on aBehavior's side; what they get from a trait is the trait's."

	^ aBehavior instanceSide withAllSubclasses flatCollect: [ :each |
			  (aBehavior isMeta
				   ifTrue: [ each classSide ]
				   ifFalse: [ each ]) localMethods ]
]

{ #category : 'private - warnings' }
MCPToolRemoveMethods >> lookupFrom: aClassOrNil lost: aSelector removedFrom: aBehavior [
	"Whether a send of aSelector looked up from aClassOrNil reached the method removed from aBehavior and now finds none."

	^ aClassOrNil isNotNil and: [ (aClassOrNil includesBehavior: aBehavior) and: [ (aClassOrNil canUnderstand: aSelector) not ] ]
]

{ #category : 'private - request' }
MCPToolRemoveMethods >> parsedRequestFromToolRequest: request [

	^ MCPRemoveMethodsRequest fromRequest: request tool: self
]

{ #category : 'private - errors' }
MCPToolRemoveMethods >> selectorsForErrorFromParsedRequest: removeRequest rawRequest: rawRequest [

	removeRequest ifNotNil: [ ^ removeRequest selectors ].
	^ rawRequest stringCollectionArgumentNamed: 'selector'
]

{ #category : 'private' }
MCPToolRemoveMethods >> selectorsFromRequest: request [

	| selectors |
	selectors := request uniqueStringCollectionArgumentNamed: 'selector'.
	selectors ifEmpty: [ Error signal: 'selector must hold at least one selector.' ].
	^ selectors
]

{ #category : 'private - warnings' }
MCPToolRemoveMethods >> sendersInImageOf: aSelector [
	"The methods of the image that send aSelector, as method_reference_search finds senders: what TraitedClass installs is left out, and a method a trait gives its users is the trait's, named once."

	^ (self matchingSelectorReferencesForSelector: aSelector inMethods: MCPCompiledMethodScopeQuery new methods) reject: [ :each |
		  each isFromTrait ]
]

{ #category : 'private' }
MCPToolRemoveMethods >> successSummaryForClassName: className classSide: classSide selectors: selectors [
	"Removed EvalPayroll>>employees. for one method, Removed 2 methods from EvalRect class: calcArea, describe. for several."

	^ String streamContents: [ :stream |
			  stream nextPutAll: 'Removed '.
			  selectors size = 1
				  ifTrue: [ stream nextPutAll: (self methodReferenceForClassName: className selector: selectors first isClassSide: classSide) ]
				  ifFalse: [
						  stream
							  print: selectors size;
							  nextPutAll: ' methods from ';
							  nextPutAll: className.
						  classSide ifTrue: [ stream nextPutAll: ' class' ].
						  stream
							  nextPutAll: ': ';
							  nextPutAll: (', ' join: selectors) ].
			  stream nextPut: $. ]
]

{ #category : 'metadata' }
MCPToolRemoveMethods >> title [

	^ 'Remove Methods'
]

{ #category : 'private - warnings' }
MCPToolRemoveMethods >> unimplementedSendWarningFor: aSelector senders: someMethods [
	"1 method still sends externallyReferencedBatchRemoval, which nothing in the image implements now: MCPToolRemoveMethodsTestSender>>sendProtectedRemovalTarget."

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: (self textForCount: someMethods size noun: 'method');
				  nextPutAll: (someMethods size = 1
						   ifTrue: [ ' still sends ' ]
						   ifFalse: [ ' still send ' ]);
				  nextPutAll: aSelector;
				  nextPutAll: ', which nothing in the image implements now: ';
				  nextPutAll: (self listTextForMethods: someMethods);
				  nextPut: $. ]
]

{ #category : 'private - warnings' }
MCPToolRemoveMethods >> warningsForSendsLeftByRemoving: selectorSymbols from: aBehavior [
	"Read once the methods are gone. For each selector, in the order asked: the methods of the class and its subclasses that still send it to self or super where it is no longer understood, then, when nothing in the image implements it any more, the other methods that still send it."

	| warnings |
	warnings := OrderedCollection new.
	selectorSymbols do: [ :selector |
			| brokenSends |
			brokenSends := self hierarchySendsBrokenByRemoving: selector from: aBehavior.
			brokenSends ifNotEmpty: [ warnings add: (self hierarchySendWarningFor: selector sends: brokenSends from: aBehavior) ].
			(self imageImplements: selector) ifFalse: [
					((self sendersInImageOf: selector) reject: [ :each | brokenSends includesKey: each ]) ifNotEmpty: [ :senders |
						warnings add: (self unimplementedSendWarningFor: selector senders: senders) ] ] ].
	^ warnings asArray
]
