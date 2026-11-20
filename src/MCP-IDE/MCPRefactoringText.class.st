"
Cleans the text a refactoring condition writes about itself, for the rare answer that has to quote it: Pharo's conditions write line breaks as <n>, pad with spaces, and print a negated condition as NOT and the condition's own text.
"
Class {
	#name : 'MCPRefactoringText',
	#superclass : 'Object',
	#category : 'MCP-IDE-Utilities',
	#package : 'MCP-IDE',
	#tag : 'Utilities'
}

{ #category : 'cleaning' }
MCPRefactoringText class >> conditionText: aString [
	"What a condition, negated or not, found, on one line."

	^ self withoutNegation: (self singleLine: aString)
]

{ #category : 'cleaning' }
MCPRefactoringText class >> singleLine: aString [
	"aString on one line: each line break, written or as Pharo's <n>, and each run of spaces and tabs becomes one space."

	^ ' ' join: ((aString ifNil: [ '' ]) asString copyReplaceAll: '<n>' with: ' ') substrings
]

{ #category : 'cleaning' }
MCPRefactoringText class >> withoutNegation: aString [
	"A negated condition prints NOT before its own text, which states what was found."

	(aString beginsWith: 'NOT ') ifTrue: [ ^ (aString allButFirst: 4) trimBoth ].
	^ aString
]
