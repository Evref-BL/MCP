Extension { #name : 'ParametrizedTestCase' }

{ #category : '*MCP' }
ParametrizedTestCase >> mcpParameterPrintStrings [

	^ self parametersToUse collect: [ :each | each printString ]
]
