Extension { #name : 'ParametrizedTestCase' }

{ #category : '*MCP-IDE' }
ParametrizedTestCase >> mcpParameterPrintStrings [

	^ self parametersToUse collect: [ :each | each printString ]
]
