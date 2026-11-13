"
I answer the compiler for an evaluation much as a Playground page does: a name the code assigns without declaring it, and that does not start with a capital, becomes a variable of the evaluation. Unlike a Playground, a name the code only reads stays undeclared: that is a typo or a missing selector far more often than a variable meant to be nil, and the compile error says which name. A capitalized name stays undeclared too, so a missing class still fails to compile.

Each evaluation gets a new requestor, so its variables end with it.

The compiler finds no real requestor API and asks by introspection: needRequestorScope makes it consult me for names, and interactive answering false keeps Pharo 12 from treating me as a user interface.
"
Class {
	#name : 'MCPPlaygroundRequestor',
	#superclass : 'Object',
	#instVars : [
		'bindings',
		'assignedNames'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPPlaygroundRequestor class >> forCode: aString [
	"A faulty parse never raises: code that does not parse fails at compile time with its own message."

	| names |
	names := Set new.
	(RBParser parseFaultyExpression: aString) allChildren do: [ :node |
		node isAssignment ifTrue: [ names add: node variable name asString ] ].
	^ self new assignedNames: names
]

{ #category : 'initialization' }
MCPPlaygroundRequestor >> assignedNames: aSet [

	assignedNames := aSet
]

{ #category : 'binding' }
MCPPlaygroundRequestor >> bindingOf: aString [

	^ bindings at: aString asSymbol ifAbsentPut: [ WorkspaceVariable key: aString asSymbol ]
]

{ #category : 'binding' }
MCPPlaygroundRequestor >> canAddBindingOf: aString [

	^ aString first isUppercase not and: [ assignedNames includes: aString asString ]
]

{ #category : 'binding' }
MCPPlaygroundRequestor >> hasBindingOf: aString [

	^ bindings includesKey: aString asSymbol
]

{ #category : 'initialization' }
MCPPlaygroundRequestor >> initialize [

	super initialize.
	bindings := Dictionary new
]

{ #category : 'testing' }
MCPPlaygroundRequestor >> interactive [

	^ false
]

{ #category : 'testing' }
MCPPlaygroundRequestor >> needRequestorScope [

	^ true
]
