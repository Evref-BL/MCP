"
Tests how permissively a method reference is read.
"
Class {
	#name : 'MCPMethodReferenceTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Utilities',
	#package : 'MCP-Tests',
	#tag : 'Utilities'
}

{ #category : 'tests' }
MCPMethodReferenceTest >> testBareSelectorNamesNoClass [

	#( 'batchSummaryNoun' 'at:put:' '+' '' ) do: [ :each |
		self assert: (MCPMethodReference fromString: each) isNil.
		self deny: (MCPMethodReference looksLikeAReference: each) ]
]

{ #category : 'tests' }
MCPMethodReferenceTest >> testClassSideIsReadFromTheReference [

	#( 'MCPTool class>>toolName' 'MCPTool  class  >>  toolName' 'MCPTool class#toolName' ) do: [ :each |
		| reference |
		reference := MCPMethodReference fromString: each.
		self assert: reference className equals: 'MCPTool'.
		self assert: reference classSide.
		self assert: reference selector equals: 'toolName' ]
]

{ #category : 'tests' }
MCPMethodReferenceTest >> testEverySpellingOfTheSeparatorIsRead [

	#( 'MCPTool>>batchSummaryNoun' 'MCPTool >> batchSummaryNoun' 'MCPTool>>#batchSummaryNoun'
	   'MCPTool#batchSummaryNoun' '  MCPTool>>batchSummaryNoun  ' ) do: [ :each |
		| reference |
		reference := MCPMethodReference fromString: each.
		self assert: reference className equals: 'MCPTool'.
		self deny: reference classSide.
		self assert: reference selector equals: 'batchSummaryNoun' ]
]

{ #category : 'tests' }
MCPMethodReferenceTest >> testKeywordSelectorsSurviveTheirColons [

	| reference |
	reference := MCPMethodReference fromString: 'MCPYamlWriter class>>yamlFor:indent:'.
	self assert: reference className equals: 'MCPYamlWriter'.
	self assert: reference classSide.
	self assert: reference selector equals: 'yamlFor:indent:'.
	self assert: reference printString equals: 'MCPYamlWriter class>>yamlFor:indent:'
]

{ #category : 'tests' }
MCPMethodReferenceTest >> testTextMeantAsAReferenceIsRecognisedEvenWhenUnreadable [

	#( 'MCPTool>>' '>>foo' 'Foo Bar>>baz' 'mcpTool>>foo' ) do: [ :each |
		self assert: (MCPMethodReference fromString: each) isNil.
		self assert: (MCPMethodReference looksLikeAReference: each) ]
]
