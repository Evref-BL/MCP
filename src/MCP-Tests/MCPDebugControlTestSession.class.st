Class {
	#name : 'MCPDebugControlTestSession',
	#superclass : 'Object',
	#instVars : [
		'contexts',
		'operations'
	],
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'instance creation' }
MCPDebugControlTestSession class >> withContext: aContext [

	^ self new
		  contexts: { aContext };
		  yourself
]

{ #category : 'accessing' }
MCPDebugControlTestSession >> contexts: aCollection [

	contexts := aCollection asArray
]

{ #category : 'accessing' }
MCPDebugControlTestSession >> exception [

	^ nil
]

{ #category : 'initialization' }
MCPDebugControlTestSession >> initialize [

	super initialize.
	contexts := #(  ).
	operations := OrderedCollection new
]

{ #category : 'accessing' }
MCPDebugControlTestSession >> operationNames [

	^ operations collect: [ :each | each first ]
]

{ #category : 'accessing' }
MCPDebugControlTestSession >> operations [

	^ operations asArray
]

{ #category : 'private' }
MCPDebugControlTestSession >> recordOperation: operationName context: aContext [

	operations add: {
			operationName.
			aContext }
]

{ #category : 'debugging' }
MCPDebugControlTestSession >> restart: aContext [

	self recordOperation: 'restart' context: aContext
]

{ #category : 'debugging' }
MCPDebugControlTestSession >> resume [

	self recordOperation: 'resume' context: nil
]

{ #category : 'debugging' }
MCPDebugControlTestSession >> stack [

	^ contexts
]

{ #category : 'debugging' }
MCPDebugControlTestSession >> stackOfSize: anInteger [

	| last |
	contexts isEmpty ifTrue: [ ^ #(  ) ].
	last := contexts size min: anInteger.
	^ contexts copyFrom: 1 to: last
]

{ #category : 'debugging' }
MCPDebugControlTestSession >> stepInto: aContext [

	self recordOperation: 'stepInto' context: aContext
]

{ #category : 'debugging' }
MCPDebugControlTestSession >> stepOver: aContext [

	self recordOperation: 'stepOver' context: aContext
]

{ #category : 'debugging' }
MCPDebugControlTestSession >> stepThrough: aContext [

	self recordOperation: 'stepThrough' context: aContext
]

{ #category : 'debugging' }
MCPDebugControlTestSession >> terminate [

	self recordOperation: 'terminate' context: nil
]
