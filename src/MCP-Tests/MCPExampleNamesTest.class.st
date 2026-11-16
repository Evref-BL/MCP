"
Holds that MCP's examples, in its comments and tests, name no fixture of the tasks that measure agents using these tools. Those tasks run in an image MCP is loaded in, where a source search answers with MCP's methods too.
"
Class {
	#name : 'MCPExampleNamesTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'tests' }
MCPExampleNamesTest >> testNothingIsNamedLikeATaskFixture [
	"The tasks name their classes with Eval and a capital letter, and their packages with Eval and a dash. An MCP class, comment or method naming one that way is read, in a task's image, as evidence about the task's own classes."

	| hits packageNames pattern |
	pattern := 'Eval-?[A-Z]' asRegex.
	packageNames := BaselineOfMCP allPackageNames select: [ :name | self packageOrganizer hasPackage: name ].
	self denyEmpty: packageNames.
	hits := OrderedCollection new.
	packageNames do: [ :name |
			| package |
			package := self packageOrganizer packageNamed: name.
			package definedClasses do: [ :class |
				((pattern search: class name) or: [ pattern search: class comment ]) ifTrue: [ hits add: class name ] ].
			package methods do: [ :method | (pattern search: method sourceCode) ifTrue: [ hits add: method printString ] ] ].
	self assert: hits isEmpty description: 'Named like a task fixture: ' , (', ' join: hits)
]
