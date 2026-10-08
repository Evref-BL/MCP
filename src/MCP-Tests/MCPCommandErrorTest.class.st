"
Tests structured command error payloads and JSON-RPC conversion.
"
Class {
	#name : 'MCPCommandErrorTest',
	#superclass : 'MCPTestCase',
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
MCPCommandErrorTest >> testClassAlreadyExistsErrorCarriesClassName [

	| details error |
	error := self capture: [ MCPCommandError signalClassAlreadyExistsNamed: 'MCPCommandErrorTestExisting' ].
	details := error structuredDetails.
	self assert: error errorCode equals: #ClassAlreadyExists.
	self assert: (details at: #className) equals: 'MCPCommandErrorTestExisting'.
	self assert: (details at: #message) equals: 'Class MCPCommandErrorTestExisting already exists.'.
	self assert: ((details at: #guidance) includesSubstring: 'Use class_get').
	self assert: ((details at: #guidance) includesSubstring: 'Do not use class_create')
]

{ #category : 'tests' }
MCPCommandErrorTest >> testMissingClassErrorCarriesStructuredDetails [

	| details error suggestions |
	error := self capture: [ MCPCommandError signalMissingClassNamed: 'MCPCommandErrorTestMissing' ].
	details := error structuredDetails.
	suggestions := details at: #suggestions.
	self assert: error errorCode equals: #ClassNotFound.
	self assert: (details at: #errorClass) equals: 'MCPCommandError'.
	self assert: (details at: #errorCode) equals: 'ClassNotFound'.
	self assert: (details at: #className) equals: 'MCPCommandErrorTestMissing'.
	self assert: (details at: #scopeName) equals: 'className'.
	self assert: suggestions size <= 5.
	self assert: ((details at: #message) includesSubstring: 'Class MCPCommandErrorTestMissing does not exist').
	self assert: ((details at: #message) includesSubstring: 'Did you mean:')
]

{ #category : 'tests' }
MCPCommandErrorTest >> testMissingMethodErrorCarriesClassSideAndSelector [

	| details error |
	error := self capture: [
			         MCPCommandError
				         signalMissingMethodInClassName: 'MCPToolGetMethodTestTarget'
				         classSide: true
				         selector: 'mcpDefinitelyMissingSelectorForErrorTest' ].
	details := error structuredDetails.
	self assert: error errorCode equals: #MethodNotFound.
	self assert: (details at: #errorClass) equals: 'MCPCommandError'.
	self assert: (details at: #errorCode) equals: 'MethodNotFound'.
	self assert: (details at: #className) equals: 'MCPToolGetMethodTestTarget'.
	self assert: (details at: #classSide).
	self assert: (details at: #selector) equals: 'mcpDefinitelyMissingSelectorForErrorTest'.
	self assert: details keys asSet equals: #( errorClass errorCode message className classSide selector ) asSet
]

{ #category : 'tests' }
MCPCommandErrorTest >> testMissingMethodErrorForMissingClassHasNoSuggestions [

	| details error |
	error := self capture: [
		         MCPCommandError signalMissingMethodInClassName: 'MCPCommandErrorTestMissingClass' classSide: false selector: 'value' ].
	details := error structuredDetails.
	self assert: error errorCode equals: #ClassNotFound.
	self assert: (details at: #className) equals: 'MCPCommandErrorTestMissingClass'.
	self assert: (details at: #selector) equals: 'value'.
	self deny: (details includesKey: #suggestions).
	self assert: ((details at: #message) includesSubstring: 'Class MCPCommandErrorTestMissingClass does not exist')
]

{ #category : 'tests' }
MCPCommandErrorTest >> testMissingMethodErrorSuggestsFirstExactSuperclassMatch [

	| details error suggestions |
	error := self capture: [
		         MCPCommandError signalMissingMethodInClassName: 'MCPToolGetMethodTestTarget' classSide: false selector: 'yourself' ].
	details := error structuredDetails.
	suggestions := details at: #suggestions.
	self assert: error errorCode equals: #MethodNotFound.
	self assert: suggestions size equals: 1.
	self assert: (suggestions first at: #className) equals: 'Object'.
	self deny: (suggestions first at: #classSide).
	self assert: (suggestions first at: #selector) equals: 'yourself'.
	self assert: ((details at: #message) includesSubstring: 'Exact matches: Object>>yourself')
]

{ #category : 'tests' }
MCPCommandErrorTest >> testMissingMethodErrorSuggestsOnlyExactOppositeSideAndSuperclassMatches [

	| details error suggestions |
	error := self capture: [
		         MCPCommandError signalMissingMethodInClassName: 'MCPToolGetMethodTestTarget' classSide: false selector: 'readClassSide' ].
	details := error structuredDetails.
	suggestions := details at: #suggestions.
	self assert: error errorCode equals: #MethodNotFound.
	self assert: suggestions size equals: 1.
	self assert: (suggestions first at: #className) equals: 'MCPToolGetMethodTestTarget'.
	self assert: (suggestions first at: #classSide).
	self assert: (suggestions first at: #selector) equals: 'readClassSide'.
	self assert: ((details at: #message) includesSubstring: 'Exact matches: MCPToolGetMethodTestTarget class>>readClassSide')
]

{ #category : 'tests' }
MCPCommandErrorTest >> testMissingPackageErrorCarriesPackageName [

	| details error suggestions |
	error := self capture: [ MCPCommandError signalMissingPackageNamed: 'MCP-Tests-Missing' ].
	details := error structuredDetails.
	suggestions := details at: #suggestions.
	self assert: error errorCode equals: #PackageNotFound.
	self assert: (details at: #errorClass) equals: 'MCPCommandError'.
	self assert: (details at: #errorCode) equals: 'PackageNotFound'.
	self assert: (details at: #packageName) equals: 'MCP-Tests-Missing'.
	self assert: (details at: #scopeName) equals: 'packageName'.
	self assert: suggestions size <= 5.
	self assert: ((details at: #message) includesSubstring: 'Package MCP-Tests-Missing does not exist')
]

{ #category : 'tests' }
MCPCommandErrorTest >> testMissingSuperclassErrorCarriesSuperclassName [

	| details error |
	error := self capture: [ MCPCommandError signalMissingSuperclassNamed: 'MCPMissingSuperclass' forClassNamed: 'MCPNewClass' ].
	details := error structuredDetails.
	self assert: error errorCode equals: #SuperclassNotFound.
	self assert: (details at: #className) equals: 'MCPNewClass'.
	self assert: (details at: #superclassName) equals: 'MCPMissingSuperclass'
]

{ #category : 'tests' }
MCPCommandErrorTest >> testMissingTagErrorCarriesTagAndClassName [

	| details error |
	error := self capture: [
		         MCPCommandError signalMissingTag: 'MissingTag' packageName: 'MCP-Tests' forClassNamed: 'MCPCommandErrorTestTarget' ].
	details := error structuredDetails.
	self assert: error errorCode equals: #TagNotFound.
	self assert: (details at: #className) equals: 'MCPCommandErrorTestTarget'.
	self assert: (details at: #packageName) equals: 'MCP-Tests'.
	self assert: (details at: #tag) equals: 'MissingTag'
]
