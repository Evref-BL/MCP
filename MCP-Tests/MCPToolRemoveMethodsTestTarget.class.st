Class {
	#name : 'MCPToolRemoveMethodsTestTarget',
	#superclass : 'Object',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'tests' }
MCPToolRemoveMethodsTestTarget class >> firstClassBatchRemoval [ ^ self secondClassBatchRemoval + 1
]

{ #category : 'tests' }
MCPToolRemoveMethodsTestTarget class >> secondClassBatchRemoval [ ^ 7
]

{ #category : 'tests' }
MCPToolRemoveMethodsTestTarget >> externallyReferencedBatchRemoval [ ^ 5
]

{ #category : 'tests' }
MCPToolRemoveMethodsTestTarget >> firstBatchRemoval [ ^ self secondBatchRemoval + 1
]

{ #category : 'tests' }
MCPToolRemoveMethodsTestTarget >> secondBatchRemoval [ ^ 2
]
