Extension { #name : 'TestCase' }

{ #category : '*MCP-Tests' }
TestCase >> withoutEpiceaDuring: aBlock [

	| value |
	EpMonitor disableDuring: [ value := aBlock value ].
	^ value
]
