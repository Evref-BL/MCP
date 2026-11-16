"
Says what a message its receiver did not understand was most likely meant to be, when its receiver or its keywords tell: a message the other side of the receiver's class understands, as a constructor compiled on the instance side and sent to the class, or two messages run together, as sorted:collect: for sorted: then collect:. For a message sent to nil, which nil's own selectors say nothing about, it names instead the send in the caller's own code it came from, past the kernel methods that only noticed the nil, and the variable that held nil.

It reads the frames that sent the message, so it is made while the stack that raised the error is still there.
"
Class {
	#name : 'MCPNotUnderstoodNote',
	#superclass : 'Object',
	#instVars : [
		'receiver',
		'selector',
		'sender'
	],
	#category : 'MCP-Utilities',
	#package : 'MCP',
	#tag : 'Utilities'
}

{ #category : 'private' }
MCPNotUnderstoodNote class >> callerTextOf: aContext [
	"The code, for code evaluated as a DoIt; otherwise the method aContext runs, or the one that defines the block it runs, as its frame prints it: the receiver's class, the method's class in parentheses when it differs, and the selector, as in ZooLion(ZooAnimal)>>feed:. A block that refers to no variable of its method runs with nil as its receiver, which says nothing of the method's own, so the method's class stands alone then."

	| method receiverClass |
	method := aContext compiledCode method.
	method selector isDoIt ifTrue: [ ^ 'The code' ].
	receiverClass := aContext receiver class.
	^ String streamContents: [ :stream |
			  (receiverClass == method methodClass or: [ (receiverClass inheritsFrom: method methodClass) not ])
				  ifTrue: [ stream nextPutAll: method methodClass name ]
				  ifFalse: [
						  stream
							  nextPutAll: receiverClass name;
							  nextPut: $(;
							  nextPutAll: method methodClass name;
							  nextPut: $) ].
			  stream
				  nextPutAll: '>>';
				  nextPutAll: method selector ]
]

{ #category : 'accessing' }
MCPNotUnderstoodNote class >> chainedSend: aSelector splitAt: anIndex [
	"As in: sorted:collect: is one message. To send collect: to what sorted: answers, put the sorted: send in parentheses: (... sorted: ...) collect: ..."

	| first firstSelector rest |
	first := aSelector keywords first: anIndex.
	rest := aSelector keywords allButFirst: anIndex.
	firstSelector := '' join: first.
	^ String streamContents: [ :stream |
			  stream << aSelector << ' is one message. To send ' << ('' join: rest) << ' to what ' << firstSelector << ' answers, put the '
			  << firstSelector << ' send in parentheses: (...'.
			  first do: [ :each | stream << ' ' << each << ' ...' ].
			  stream nextPut: $).
			  rest do: [ :each | stream << ' ' << each << ' ...' ] ]
]

{ #category : 'accessing' }
MCPNotUnderstoodNote class >> chainedSendTextFor: aSelector whereFirstPart: aBlock [
	"Keywords that run two messages together, as sorted:collect: for sorted: then collect:, split at the first place where aBlock accepts the keywords before it and a method somewhere in the image implements the rest: Smalltalk reads the keywords of one send as one selector. nil when no split does."

	| keywords |
	keywords := aSelector keywords.
	^ (1 to: keywords size - 1)
		  detect: [ :split |
			  (aBlock value: ('' join: (keywords first: split))) and: [
				  self isImplementedSelector: ('' join: (keywords allButFirst: split)) ] ]
		  ifFound: [ :split | self chainedSend: aSelector splitAt: split ]
		  ifNone: [ nil ]
]

{ #category : 'private' }
MCPNotUnderstoodNote class >> isContext: aContext inAnyPackageOf: somePackageNames [
	"Whether the method aContext runs, or the one that defines the block it runs, belongs to one of somePackageNames. Code evaluated as a DoIt is the caller's own, whatever class it was compiled in."

	| method package |
	method := aContext compiledCode method.
	method selector isDoIt ifTrue: [ ^ false ].
	package := method package.
	^ package isNotNil and: [ somePackageNames includes: package name asString ]
]

{ #category : 'testing' }
MCPNotUnderstoodNote class >> isImplementedSelector: aString [
	"Whether a method somewhere in the image has aString as its selector. A string no symbol was ever made of is no method's selector."

	| selector |
	selector := Symbol findInterned: aString.
	^ selector isNotNil and: [ (SystemNavigation default allImplementorsOf: selector) isNotEmpty ]
]

{ #category : 'instance creation' }
MCPNotUnderstoodNote class >> on: aMessageNotUnderstood [
	"Made while the stack that raised aMessageNotUnderstood is still there, which holds the frame that sent the message."

	^ self new
		  initializeReceiver: aMessageNotUnderstood receiver
		  selector: aMessageNotUnderstood message selector
		  sender: (self senderOf: aMessageNotUnderstood)
]

{ #category : 'private' }
MCPNotUnderstoodNote class >> pharoPackageNames [
	"The packages of Pharo's kernel, as its bootstrap baseline groups them, and SUnit's: code that runs in them notices a nil that the caller's own code handed it."

	| names |
	names := Set new.
	self environment at: #TestCase ifPresent: [ :testCase | names add: testCase package name asString ].
	self environment
		at: #BaselineOfPharoBootstrap
		ifPresent: [ :baseline | baseline kernelPackageNames do: [ :each | names add: each asString ] ].
	^ names
]

{ #category : 'private' }
MCPNotUnderstoodNote class >> senderOf: aMessageNotUnderstood [
	"The frame that sent the message: the sender of the doesNotUnderstand: the virtual machine sent in its place, which Pharo 14 signals from a frame above it and earlier versions from that frame itself. nil when the error was raised some other way."

	| context |
	context := aMessageNotUnderstood signalerContext ifNil: [ ^ nil ].
	^ (context findContextSuchThat: [ :each |
		   each selector == #doesNotUnderstand: and: [ each receiver == aMessageNotUnderstood receiver ] ]) ifNotNil: [ :notUnderstood |
		  notUnderstood sender ]
]

{ #category : 'private' }
MCPNotUnderstoodNote >> chainedSendText [
	"Keywords whose first part the receiver understands, and whose rest something implements, were most likely meant as two sends."

	^ self class chainedSendTextFor: selector whereFirstPart: [ :firstPart | self receiverUnderstands: firstPart ]
]

{ #category : 'private' }
MCPNotUnderstoodNote >> classSideText [
	"For an instance sent a message only its class understands, as a constructor sent to a new instance."

	^ String streamContents: [ :stream |
			  stream << receiver class name << ' itself understands ' << selector << ', but its instances do not: ' << selector
			  << ' is a class-side method. Send it to ' << receiver class name
			  << ', or compile it with method_compile and side instance to send it to an instance.' ]
]

{ #category : 'private' }
MCPNotUnderstoodNote >> indexOfNilIn: aContext [
	"Which of the receiver and the arguments aContext was sent is nil: 0 for the receiver, the index of the first argument that is, or nil when none is."

	aContext receiver ifNil: [ ^ 0 ].
	^ (1 to: aContext numArgs) detect: [ :index | (aContext tempAt: index) isNil ] ifNone: [ nil ]
]

{ #category : 'initialization' }
MCPNotUnderstoodNote >> initializeReceiver: anObject selector: aSelector sender: aContextOrNil [

	receiver := anObject.
	selector := aSelector.
	sender := aContextOrNil
]

{ #category : 'private' }
MCPNotUnderstoodNote >> instanceSideText [
	"For a class sent a message only its instances understand, as a constructor compiled on the instance side."

	^ String streamContents: [ :stream |
			  stream << 'Instances of ' << receiver name << ' understand ' << selector << ', but ' << receiver name << ' itself does not: '
			  << selector
			  << ' is an instance-side method. Send it to an instance, or compile it with method_compile and side class to send it to '
			  << receiver name << '.' ]
]

{ #category : 'testing' }
MCPNotUnderstoodNote >> leavesOutSuggestions [
	"Whether the selectors that resemble the message are beside the point: nil's own say nothing of what was meant to be sent to it, and a message the other side of the class understands was not mistyped. Two messages run together are only a guess, which a mistyped selector can match too, so the selectors stay beside that note."

	^ receiver isNil or: [ self otherSideText isNotNil ]
]

{ #category : 'accessing' }
MCPNotUnderstoodNote >> meantText [
	"What the message was most likely meant to be, or nil when neither its receiver nor its keywords tell. That the other side of the class understands the whole selector is a fact, and comes before reading the keywords as two messages, a guess that every selector starting with one a class understands, such as at:, would match. A message sent to nil has none: nil understands nothing anyone means to send it."

	receiver ifNil: [ ^ nil ].
	^ self otherSideText ifNil: [ self chainedSendText ]
]

{ #category : 'accessing' }
MCPNotUnderstoodNote >> nilReceiverText [
	"For a message sent to nil: the send in the caller's own code it came from, in the code evaluated as a DoIt or the first method that is neither Pharo's kernel nor SUnit, and which of that send's receiver and arguments was nil, named by the variable it was read from, as in: The code sent > with the argument width, which is nil. Comparing a number with nil, or adding nil to it, fails in the kernel, which sends nil a message of its own on the number's behalf, from a method running on nil. nil when no frame of the caller's own code is known."

	| callee caller pharoPackageNames |
	caller := sender ifNil: [ ^ nil ].
	pharoPackageNames := self class pharoPackageNames.
	[ self class isContext: caller inAnyPackageOf: pharoPackageNames ] whileTrue: [
			callee := caller.
			caller := caller sender ifNil: [ ^ nil ] ].
	callee ifNil: [ ^ self nilSendTextFrom: caller sent: selector nilAt: 0 ].
	callee isBlockContext ifTrue: [ ^ nil ].
	^ self nilSendTextFrom: caller sent: callee selector nilAt: (self indexOfNilIn: callee)
]

{ #category : 'private' }
MCPNotUnderstoodNote >> nilSendTextFrom: aContext sent: aSelector nilAt: anIndexOrNil [
	"The send of aSelector that aContext was running, and which of its operands was nil: 0 for its receiver, a positive index for that argument, nil for neither, when the nil was met further in."

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: (self class callerTextOf: aContext);
				  nextPutAll: ' sent ';
				  nextPutAll: aSelector.
			  anIndexOrNil
				  ifNil: [ stream nextPutAll: ', whose receiver and arguments are not nil: the nil was met inside it' ]
				  ifNotNil: [
						  stream nextPutAll: (anIndexOrNil = 0
								   ifTrue: [ ' to ' ]
								   ifFalse: [ ' with the argument ' ]).
						  self
							  printOperandAt: anIndexOrNil
							  in: aContext
							  sent: aSelector
							  on: stream ].
			  stream nextPut: $. ]
]

{ #category : 'private' }
MCPNotUnderstoodNote >> otherSideText [
	"A class that does not understand a message its instances understand, or an instance one its class side defines. Behavior, ClassDescription and Class give every class side their methods, which no instance was meant to understand, so only a class side of the receiver's own hierarchy counts."

	receiver class isMeta ifTrue: [ ^ (receiver canUnderstand: selector) ifTrue: [ self instanceSideText ] ].
	^ (receiver class classSide lookupSelector: selector) ifNotNil: [ :method |
		  method methodClass isMeta ifTrue: [ self classSideText ] ]
]

{ #category : 'private' }
MCPNotUnderstoodNote >> printOperandAt: anIndex in: aContext sent: aSelector on: aStream [
	"The receiver, at 0, or the argument at anIndex of the send of aSelector that aContext was running, which was nil: the variable it was read from, as in width, which is nil, or nil when it was no variable or the send cannot be read."

	| node operand |
	node := [ aContext sourceNodeExecuted ]
		        on: Error
		        do: [ :error | nil ].
	(node isNotNil and: [ node isMessage and: [ node selector == aSelector ] ]) ifFalse: [ ^ aStream nextPutAll: 'nil' ].
	operand := anIndex = 0
		           ifTrue: [ node receiver ]
		           ifFalse: [ node arguments at: anIndex ].
	operand isVariable ifFalse: [ ^ aStream nextPutAll: 'nil' ].
	aStream
		nextPutAll: operand name;
		nextPutAll: ', which is nil'
]

{ #category : 'private' }
MCPNotUnderstoodNote >> receiverUnderstands: aString [
	"A string no symbol was ever made of is no selector the receiver understands."

	| symbol |
	symbol := Symbol findInterned: aString.
	^ symbol isNotNil and: [ receiver class canUnderstand: symbol ]
]

{ #category : 'accessing' }
MCPNotUnderstoodNote >> text [
	"What a failure says beside its message: for a message sent to nil, the send in the caller's own code it came from, and otherwise what the message was most likely meant to be. nil when neither can be told."

	receiver ifNil: [ ^ self nilReceiverText ].
	^ self meantText
]
