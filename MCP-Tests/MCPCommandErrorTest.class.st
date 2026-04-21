Class {
	#name : 'MCPCommandErrorTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'private' }
MCPCommandErrorTest >> capture: aBlock [

	^ [
	  aBlock value.
	  self fail: 'Expected MCPCommandError' ]
		  on: MCPCommandError
		  do: [ :error | error ]
]

{ #category : 'tests' }
MCPCommandErrorTest >> testMissingClassErrorCarriesStructuredDetails [

	| error details |
	error := self capture: [
		         MCPCommandError signalMissingClassNamed:
			         'MCPCommandErrorTestMissing' ].
	details := error structuredDetails.
	self assert: error errorCode equals: #ClassNotFound.
	self assert: (details at: #errorClass) equals: 'ClassNotFound'.
	self
		assert: (details at: #className)
		equals: 'MCPCommandErrorTestMissing'.
	self
		assert: (details at: #message)
		equals: 'Class MCPCommandErrorTestMissing does not exist.'
]

{ #category : 'tests' }
MCPCommandErrorTest >> testMissingMethodErrorCarriesMethodReference [

	| details error |
	error := self capture: [
		         MCPCommandError
			         signalMissingMethodInClassName:
			         'MCPCommandErrorTestTarget'
			         classSide: true
			         selector: 'value' ].
	details := error structuredDetails.
	self assert: error errorCode equals: #MethodNotFound.
	self
		assert: (details at: #methodReference)
		equals: 'MCPCommandErrorTestTarget class>>value'.
	self assert: (details at: #selector) equals: 'value'
]

{ #category : 'tests' }
MCPCommandErrorTest >> testMissingPackageErrorCarriesPackageName [

	| details error |
	error := self capture: [
		         MCPCommandError signalMissingPackageNamed:
			         'MCP-Tests-Missing' ].
	details := error structuredDetails.
	self assert: error errorCode equals: #PackageNotFound.
	self assert: (details at: #packageName) equals: 'MCP-Tests-Missing'.
	self assert: (details at: #errorClass) equals: 'PackageNotFound'
]

{ #category : 'tests' }
MCPCommandErrorTest >> testMissingTagErrorCarriesTagAndClassName [

	| details error |
	error := self capture: [
		         MCPCommandError
			         signalMissingTag: 'MissingTag'
			         packageName: 'MCP-Tests'
			         forClassNamed: 'MCPCommandErrorTestTarget' ].
	details := error structuredDetails.
	self assert: error errorCode equals: #TagNotFound.
	self
		assert: (details at: #className)
		equals: 'MCPCommandErrorTestTarget'.
	self assert: (details at: #packageName) equals: 'MCP-Tests'.
	self assert: (details at: #tag) equals: 'MissingTag'
]
