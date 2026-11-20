"
Removes methods from one class as one change. A method still sent is removed anyway, and the answer warns of the sends it leaves without a method.
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

	^ MCPStructureInputSchema
		  properties: {
				  (self schemaPropertyNamed: 'class' type: 'string' description: 'The class to remove the methods from.').
				  (self targetSideSchemaPropertyDescribedAs: 'Which side to remove from.').
				  (self
					   stringOrArraySchemaNamed: 'selector'
					   description: 'The selector to remove, or several removed together as one change.'
					   itemDescription: 'Selector name.') }
		  required: #( 'class' 'selector' )
]

{ #category : 'executing' }
MCPToolRemoveMethods >> checkArguments: request [
	"A side that says the other one than the class name is refused, as is a selector list that names none."

	self classNameAndSideOf: request do: [ :className :classSide :sideGiven | self selectorsFromRequest: request ]
]

{ #category : 'metadata' }
MCPToolRemoveMethods >> defaultExposure [

	^ 'static'
]

{ #category : 'metadata' }
MCPToolRemoveMethods >> description [

	^ 'Remove methods from one class. Senders do not stop it; the answer warns of sends it leaves without a method.'
]

{ #category : 'executing' }
MCPToolRemoveMethods >> executeWithRequest: request [

	| checked |
	checked := false.
	^ self
		  executeRequest: request
		  do: [
				  self checkArguments: request.
				  checked := true.
				  self removeWith: request ]
		  onError: [ :error |
				  | className classSide selectors |
				  className := (self requestedClassNameIn: request) ifNil: [ checked ifFalse: [ '' ] ].
				  classSide := self requestedClassSideIn: request.
				  selectors := self selectorsFor: request checked: checked.
				  self
					  errorResultFor: error
					  unableTo: (String streamContents: [ :stream |
							   stream << 'remove methods from ' << (self classReferenceNameFor: className classSide: classSide) << ': '
							   << (', ' join: selectors) ])
					  details: {
							  (#class -> className).
							  (#side -> (self sideNameFor: classSide)).
							  (#selectors -> selectors asArray) } ]
]

{ #category : 'private - warnings' }
MCPToolRemoveMethods >> hierarchySendWarningFor: aSelector sends: brokenSends from: aBehavior [
	"ZooKeeper>>roster and ZooKeeper>>feedAll still send animals to self, which ZooKeeper no longer understands."

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
	references size > 10 ifFalse: [ ^ MCPCommandError joinedNames: references ].
	^ String streamContents: [ :stream |
			  (references first: 10) do: [ :each | stream nextPutAll: each ] separatedBy: [ stream nextPutAll: ', ' ].
			  stream
				  nextPutAll: ', and ';
				  print: references size - 10;
				  nextPutAll: ' more' ]
]

{ #category : 'private - warnings' }
MCPToolRemoveMethods >> localMethodsOfHierarchyOf: aBehavior [
	"The methods the class and its subclasses define themselves, on aBehavior's side; what they get from a trait is the trait's. A subclass the image no longer holds under its name, as a class Pharo abandoned installing stays, has no method in the image."

	^ (aBehavior instanceSide withAllSubclasses select: [ :each | MCPImageLookup holds: each ]) flatCollect: [ :each |
			  (aBehavior isMeta
				   ifTrue: [ each classSide ]
				   ifFalse: [ each ]) localMethods ]
]

{ #category : 'private - warnings' }
MCPToolRemoveMethods >> lookupFrom: aClassOrNil lost: aSelector removedFrom: aBehavior [
	"Whether a send of aSelector looked up from aClassOrNil reached the method removed from aBehavior and now finds none."

	^ aClassOrNil isNotNil and: [ (aClassOrNil includesBehavior: aBehavior) and: [ (aClassOrNil canUnderstand: aSelector) not ] ]
]

{ #category : 'executing' }
MCPToolRemoveMethods >> removeWith: request [
	"Senders do not stop a removal. Once the methods are gone, the answer warns of the sends they left without a method."

	| behavior className classSide selectorSymbols selectors |
	className := self requestedClassNameIn: request.
	classSide := self requestedClassSideIn: request.
	selectors := self selectorsFromRequest: request.
	selectorSymbols := selectors collect: #asSymbol.
	behavior := self behaviorNamed: className classSide: classSide.
	selectorSymbols do: [ :selector |
			behavior compiledMethodAt: selector ifAbsent: [ MCPCommandError signalMissingMethod: selector asString in: behavior ].
			self signalTraitOriginBeforeRemoving: selector in: behavior ].
	self forceRemoveSelectors: selectorSymbols from: behavior.
	^ self
		  successResultText: (self successSummaryForClassName: className classSide: classSide selectors: selectors asArray)
		  data: Dictionary new
		  warnings: (self warningsForSendsLeftByRemoving: selectorSymbols from: behavior)
]

{ #category : 'private - errors' }
MCPToolRemoveMethods >> selectorsFor: request checked: aBoolean [
	"Each selector once after the arguments are checked; before, as the call wrote them."

	aBoolean ifTrue: [ ^ self selectorsFromRequest: request ].
	^ request stringCollectionArgumentNamed: 'selector'
]

{ #category : 'private' }
MCPToolRemoveMethods >> selectorsFromRequest: request [

	| selectors |
	selectors := request uniqueStringCollectionArgumentNamed: 'selector'.
	selectors ifEmpty: [ Error signal: 'selector must hold at least one selector.' ].
	^ selectors
]

{ #category : 'private - warnings' }
MCPToolRemoveMethods >> sendersInImageOf: someSelectors [
	"Each of someSelectors with the methods of the image that send it, as method_reference_search finds senders: what TraitedClass installs is left out, and a method a trait gives its users is the trait's, named once. The image's methods are collected once for every selector."

	| methods |
	someSelectors ifEmpty: [ ^ Dictionary new ].
	methods := MCPCompiledMethodScopeQuery new methods reject: [ :each | each isFromTrait ].
	^ (someSelectors collect: [ :each | each -> (self matchingSelectorReferencesForSelector: each inMethods: methods) ]) asDictionary
]

{ #category : 'private' }
MCPToolRemoveMethods >> successSummaryForClassName: className classSide: classSide selectors: selectors [
	"Removed ZooKeeper>>animals. for one method, Removed 2 methods from ZooLion class: dailyRation, roar. for several."

	^ String streamContents: [ :stream |
			  stream nextPutAll: 'Removed '.
			  selectors size = 1
				  ifTrue: [ stream nextPutAll: (self methodReferenceForClassName: className selector: selectors first isClassSide: classSide) ]
				  ifFalse: [
						  stream
							  print: selectors size;
							  nextPutAll: ' methods from ';
							  nextPutAll: (self classReferenceNameFor: className classSide: classSide);
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

	| warnings senders |
	senders := self sendersInImageOf: (selectorSymbols reject: [ :each | self imageImplements: each ]).
	warnings := OrderedCollection new.
	selectorSymbols do: [ :selector |
			| brokenSends |
			brokenSends := self hierarchySendsBrokenByRemoving: selector from: aBehavior.
			brokenSends ifNotEmpty: [ warnings add: (self hierarchySendWarningFor: selector sends: brokenSends from: aBehavior) ].
			((senders at: selector ifAbsent: [ #(  ) ]) reject: [ :each | brokenSends includesKey: each ]) ifNotEmpty: [ :someSenders |
				warnings add: (self unimplementedSendWarningFor: selector senders: someSenders) ] ].
	^ warnings asArray
]
