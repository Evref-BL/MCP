"
Tests command-level class rename behavior.
"
Class {
	#name : 'MCPRenameClassCommandTest',
	#superclass : 'MCPCommandTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPRenameClassCommandTest >> originalClassName [

	^ 'MCPToolRenameClassTestOriginal'
]

{ #category : 'private' }
MCPRenameClassCommandTest >> renamedClassName [

	^ 'MCPToolRenameClassTestRenamed'
]

{ #category : 'running' }
MCPRenameClassCommandTest >> setUp [

	super setUp.
	self restoreClassNamed: self originalClassName renamedTo: self renamedClassName
]

{ #category : 'running' }
MCPRenameClassCommandTest >> tearDown [

	self restoreClassNamed: self originalClassName renamedTo: self renamedClassName.
	super tearDown
]

{ #category : 'tests' }
MCPRenameClassCommandTest >> testMissingClassSignalsCommandError [

	| error |
	error := self captureCommandError: [
		         (MCPRenameClassCommand className: 'MCPRenameClassCommandTestMissing' newClassName: self renamedClassName) execute ].
	self assert: error errorCode equals: #ClassNotFound.
	self assert: (error structuredDetails at: #class) equals: 'MCPRenameClassCommandTestMissing'
]
