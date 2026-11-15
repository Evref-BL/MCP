"
Tests how permissively a method reference is read.
"
Class {
	#name : 'MCPMethodReferenceTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'tests' }
MCPMethodReferenceTest >> testBareSelectorNamesNoClass [

	#( 'batchSummaryNoun' 'at:put:' '+' '' ) do: [ :each |
		self assert: (MCPMethodReference fromString: each) isNil.
		self deny: (MCPMethodReference looksLikeAReference: each) ]
]

{ #category : 'tests' }
MCPMethodReferenceTest >> testClassSideIsReadFromTheReference [
	"The side is read as every class name is: any run of spaces, any case, and a trait's classTrait."

	#( 'MCPTool class>>toolName' 'MCPTool  class  >>  toolName' 'MCPTool class#toolName' 'MCPTool CLASS>>toolName' ) do: [ :each |
			| reference |
			reference := MCPMethodReference fromString: each.
			self assert: reference className equals: 'MCPTool'.
			self assert: reference classSide.
			self assert: reference selector equals: 'toolName' ].
	self assert: (MCPMethodReference fromString: 'TMCPMethodTool classTrait>>foo') className equals: 'TMCPMethodTool'.
	self assert: (MCPMethodReference fromString: 'TMCPMethodTool classTrait>>foo') classSide
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
MCPMethodReferenceTest >> testHelpNamesNoArgumentOfItsOwn [
	"Several tools read a reference, and only method_get has a class argument, so the shared help does not mention one."

	self
		assert: MCPMethodReference helpText
		equals: 'Write a method as Class>>selector, or Class class>>selector for the class side.'
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
