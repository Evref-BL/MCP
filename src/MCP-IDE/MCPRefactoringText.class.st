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
MCPRefactoringText class >> singleLine: aString [
	"aString on one line: each line break, written or as Pharo's <n>, becomes a space, and runs of spaces become one."

	| text |
	text := aString ifNil: [ '' ] ifNotNil: [ aString asString ].
	text := text copyReplaceAll: '<n>' with: ' '.
	text := text copyReplaceAll: String cr with: ' '.
	text := text copyReplaceAll: String lf with: ' '.
	[ text includesSubstring: '  ' ] whileTrue: [ text := text copyReplaceAll: '  ' with: ' ' ].
	^ text trimBoth
]

{ #category : 'cleaning' }
MCPRefactoringText class >> withoutNegation: aString [
	"A negated condition prints NOT before its own text, which states what was found."

	(aString beginsWith: 'NOT ') ifTrue: [ ^ (aString allButFirst: 4) trimBoth ].
	^ aString
]
