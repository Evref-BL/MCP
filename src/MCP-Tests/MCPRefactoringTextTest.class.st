"
Tests how MCPRefactoringText cleans the text a refactoring condition writes.
"
Class {
	#name : 'MCPRefactoringTextTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'tests' }
MCPRefactoringTextTest >> testSingleLineJoinsLinesAndRunsOfSpaces [

	self
		assert: (MCPRefactoringText singleLine: 'Cannot remove top level class<n>when it has subclasses')
		equals: 'Cannot remove top level class when it has subclasses'.
	self
		assert: (MCPRefactoringText singleLine: 'NOT ZooAnimal is not empty.  and ZooAnimal has subclasses. ')
		equals: 'NOT ZooAnimal is not empty. and ZooAnimal has subclasses.'.
	self
		assert: (MCPRefactoringText singleLine: ('one{1}two{2} three' format: {
						  String cr.
						  String lf }))
		equals: 'one two three'.
	self assert: (MCPRefactoringText singleLine: nil) equals: ''
]

{ #category : 'tests' }
MCPRefactoringTextTest >> testWithoutNegationDropsTheLeadingNot [

	self assert: (MCPRefactoringText withoutNegation: 'NOT ZooAnimal is not empty.') equals: 'ZooAnimal is not empty.'.
	self assert: (MCPRefactoringText withoutNegation: 'ZooLion has 3 references.') equals: 'ZooLion has 3 references.'.
	self assert: (MCPRefactoringText withoutNegation: 'NOTHING refers to it') equals: 'NOTHING refers to it'
]
