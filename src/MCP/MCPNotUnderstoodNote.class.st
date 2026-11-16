"
Says what a message its receiver did not understand was most likely meant to be, when its keywords or its receiver tell: two messages run together, as sorted:collect: for sorted: then collect:, or a message the other side of the receiver's class understands, as a constructor compiled on the instance side and sent to the class. For a message sent to nil, which nil's own selectors say nothing about, it names the method that sent it instead, and the variable that held nil.

It reads the frame that sent the message, so it is made while the stack that raised the error is still there.
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
	"Keywords whose first part the receiver understands, and whose rest something implements, were most likely meant as two sends: Smalltalk reads the keywords of one send as one selector."

	| keywords |
	keywords := selector keywords.
	^ (1 to: keywords size - 1)
		  detect: [ :split |
				  (self receiverUnderstands: ('' join: (keywords first: split))) and: [
					  self class isImplementedSelector: ('' join: (keywords allButFirst: split)) ] ]
		  ifFound: [ :split | self class chainedSend: selector splitAt: split ]
		  ifNone: [ nil ]
]

{ #category : 'private' }
MCPNotUnderstoodNote >> classSideText [
	"For an instance sent a message only its class understands, as a constructor sent to a new instance."

	^ String streamContents: [ :stream |
			  stream << receiver class name << ' itself understands ' << selector << ', but its instances do not: ' << selector
			  << ' is a class-side method. Send it to ' << receiver class name
			  << ', or compile it with method_compile and side instance to send it to an instance.' ]
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

{ #category : 'accessing' }
MCPNotUnderstoodNote >> meantText [
	"What the message was most likely meant to be, or nil when neither its keywords nor its receiver tell. A message sent to nil has none: nil understands nothing anyone means to send it."

	receiver ifNil: [ ^ nil ].
	^ self chainedSendText ifNil: [ self otherSideText ]
]

{ #category : 'accessing' }
MCPNotUnderstoodNote >> nilReceiverText [
	"For a message sent to nil: the method that sent it, and the variable that held nil when the send read one, as in: Point>>+ sent + to x, which is nil. nil when the frame that sent it is not known."

	| method |
	sender ifNil: [ ^ nil ].
	method := sender compiledCode method.
	^ String streamContents: [ :stream |
			  method selector isDoIt
				  ifTrue: [ stream nextPutAll: 'The code' ]
				  ifFalse: [ stream << method methodClass name << '>>' << method selector ].
			  stream << ' sent ' << selector << ' to '.
			  self receiverVariableName
				  ifNil: [ stream nextPutAll: 'nil' ]
				  ifNotNil: [ :variableName | stream << variableName << ', which is nil' ].
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
MCPNotUnderstoodNote >> receiverUnderstands: aString [
	"A string no symbol was ever made of is no selector the receiver understands."

	^ (Symbol findInterned: aString) ifNil: [ false ] ifNotNil: [ :symbol | receiver class canUnderstand: symbol ]
]

{ #category : 'private' }
MCPNotUnderstoodNote >> receiverVariableName [
	"The variable the send read nil from, or nil when it sent to an expression, or its frame cannot say."

	| node |
	node := [ sender sourceNodeExecuted ]
		        on: Error
		        do: [ :error | ^ nil ].
	^ node ifNotNil: [
		  (node isMessage and: [ node selector == selector and: [ node receiver isVariable ] ]) ifTrue: [ node receiver name ] ]
]

{ #category : 'accessing' }
MCPNotUnderstoodNote >> text [
	"What a failure says beside its message: for a message sent to nil, the method that sent it, and otherwise what the message was most likely meant to be. nil when neither can be told."

	receiver ifNil: [ ^ self nilReceiverText ].
	^ self meantText
]
