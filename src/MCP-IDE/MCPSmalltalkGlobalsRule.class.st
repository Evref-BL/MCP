"
Renraku rule that warns when code reads or writes globals through Smalltalk: Smalltalk globals, or a message SmalltalkImage only forwards to them.

Smalltalk globals is the one system dictionary, and self class environment the one the class's own name is bound in. They are the same dictionary today, and the second stays right once classes live in more than one. On the class side self class is the metaclass, whose environment is its class's, so both sides read the same.

Smalltalk vm, Smalltalk image and the like answer the running system rather than a global, and are left alone, as is a variable that only shares the name. So is a cascade to Smalltalk unless SmalltalkImage forwards every message it sends, since they all go to the one receiver.
"
Class {
	#name : 'MCPSmalltalkGlobalsRule',
	#superclass : 'MCPMethodStyleRule',
	#category : 'MCP-IDE-Critiques',
	#package : 'MCP-IDE',
	#tag : 'Critiques'
}

{ #category : 'accessing' }
MCPSmalltalkGlobalsRule class >> forwardedSelectors [
	"What SmalltalkImage forwards to its globals on every Pharo MCP supports, each to a message of the dictionary that means the same, so the same send to the environment means the same."

	^ #( #allClasses #allClassesAndTraits #allClassesAndTraitsDo: #allClassesDo: #allTraits #at: #at:ifAbsent: #at:ifAbsentPut:
	     #at:ifPresent: #at:ifPresent:ifAbsent: #at:put: #bindingOf: #classNamed: #classNames #classOrTraitNamed: #flushClassNameCache
	     #hasClassNamed: #includesKey: #organization #removeClassNamed: #renameClass:from: #renameClassNamed:as:
	     #traitNames )
]

{ #category : 'testing' }
MCPSmalltalkGlobalsRule class >> forwardsEverySendTo: aNode [
	"A cascade sends each of its messages to the one receiver, so the receiver changes only when every message it sends is forwarded."

	| send |
	send := aNode parent.
	^ (send parent isCascade
		   ifTrue: [ send parent messages ]
		   ifFalse: [ { send } ]) allSatisfy: [ :each | self forwardedSelectors includes: each selector ]
]

{ #category : 'accessing' }
MCPSmalltalkGlobalsRule class >> rationale [

	^ 'Ask self class environment for globals instead of Smalltalk. It answers the environment the class is bound in, which stays right once classes live in more than one.'
]

{ #category : 'accessing' }
MCPSmalltalkGlobalsRule class >> ruleName [

	^ 'Use self class environment for globals'
]

{ #category : 'initialization' }
MCPSmalltalkGlobalsRule >> initialize [

	super initialize.
	self
		replace: 'Smalltalk `{ :node | node isGlobalVariable and: [ node parent parent isCascade not ] } globals'
		with: 'self class environment';
		replace:
			'Smalltalk `{ :node | node isGlobalVariable and: [ MCPSmalltalkGlobalsRule forwardsEverySendTo: node ] } `@message: `@arguments'
		with: 'self class environment `@message: `@arguments'
]
