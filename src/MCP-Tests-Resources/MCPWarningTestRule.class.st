"
A critique rule that signals a warning while it checks a method named #critiqueWarningProbe, and does nothing for any other method.

It stands for a rule from any package that raises a warning of its own, such as a deprecation in its code, while the tools critique a method they just compiled.
"
Class {
	#name : 'MCPWarningTestRule',
	#superclass : 'ReAbstractRule',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'accessing' }
MCPWarningTestRule class >> checksMethod [

	^ true
]

{ #category : 'accessing' }
MCPWarningTestRule class >> probeSelector [

	^ #critiqueWarningProbe
]

{ #category : 'accessing' }
MCPWarningTestRule class >> ruleName [

	^ 'Signals a warning while checking its probe method'
]

{ #category : 'accessing' }
MCPWarningTestRule class >> uniqueIdentifierName [

	^ 'MCPWarningTestRule'
]

{ #category : 'running' }
MCPWarningTestRule >> check: aMethod forCritiquesDo: aCriticBlock [

	aMethod selector = self class probeSelector ifTrue: [ Warning signal: 'A rule raised a warning of its own' ]
]
