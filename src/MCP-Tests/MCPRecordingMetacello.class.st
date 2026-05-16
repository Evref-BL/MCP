"
Test double that records the Metacello messages sent by load-repository command tests without loading an external mocking framework.
"
Class {
	#name : 'MCPRecordingMetacello',
	#superclass : 'Object',
	#instVars : [
		'messages'
	],
	#category : 'MCP-Tests-Support',
	#package : 'MCP-Tests',
	#tag : 'Support'
}

{ #category : 'accessing' }
MCPRecordingMetacello >> argumentsFor: selector [

	^ (messages
		   detect: [ :each | (each at: #selector) = selector ]
		   ifNone: [ ^ nil ]) at: #arguments
]

{ #category : 'metacello protocol' }
MCPRecordingMetacello >> baseline: baselineName [

	^ self record: #baseline: arguments: { baselineName }
]

{ #category : 'testing' }
MCPRecordingMetacello >> denyReceived: selector [

	^ (self received: selector) not
]

{ #category : 'initialization' }
MCPRecordingMetacello >> initialize [

	super initialize.
	messages := OrderedCollection new
]

{ #category : 'metacello protocol' }
MCPRecordingMetacello >> load [

	^ self record: #load arguments: #(  )
]

{ #category : 'metacello protocol' }
MCPRecordingMetacello >> load: groups [

	^ self record: #load: arguments: { groups }
]

{ #category : 'testing' }
MCPRecordingMetacello >> messageCountFor: selector [

	^ (messages select: [ :each | (each at: #selector) = selector ]) size
]

{ #category : 'accessing' }
MCPRecordingMetacello >> messages [

	^ messages copy
]

{ #category : 'metacello protocol' }
MCPRecordingMetacello >> onConflictUseIncoming [

	^ self record: #onConflictUseIncoming arguments: #(  )
]

{ #category : 'metacello protocol' }
MCPRecordingMetacello >> onConflictUseLoaded [

	^ self record: #onConflictUseLoaded arguments: #(  )
]

{ #category : 'metacello protocol' }
MCPRecordingMetacello >> onWarning: aBlock [

	^ self record: #onWarning: arguments: { aBlock }
]

{ #category : 'metacello protocol' }
MCPRecordingMetacello >> onWarningLog [

	^ self record: #onWarningLog arguments: #(  )
]

{ #category : 'testing' }
MCPRecordingMetacello >> received: selector [

	^ messages anySatisfy: [ :each | (each at: #selector) = selector ]
]

{ #category : 'testing' }
MCPRecordingMetacello >> received: selector withArguments: arguments [

	^ messages anySatisfy: [ :each |
		  (each at: #selector) = selector and: [
			  (each at: #arguments) = arguments asArray ] ]
]

{ #category : 'recording' }
MCPRecordingMetacello >> record: selector arguments: arguments [

	messages add: {
			(#selector -> selector).
			(#arguments -> arguments asArray) } asDictionary.
	^ self
]

{ #category : 'metacello protocol' }
MCPRecordingMetacello >> repository: repositoryUrl [

	^ self record: #repository: arguments: { repositoryUrl }
]
