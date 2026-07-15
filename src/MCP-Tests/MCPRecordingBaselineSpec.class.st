"
Records baseline group definitions for focused baseline contract tests.
"
Class {
	#name : 'MCPRecordingBaselineSpec',
	#superclass : 'Object',
	#instVars : [
		'groups'
	],
	#category : 'MCP-Tests-Support',
	#package : 'MCP-Tests',
	#tag : 'Support'
}

{ #category : 'recording' }
MCPRecordingBaselineSpec >> group: groupName with: members [

	groups at: groupName put: members
]

{ #category : 'accessing' }
MCPRecordingBaselineSpec >> groups [

	^ groups
]

{ #category : 'initialization' }
MCPRecordingBaselineSpec >> initialize [

	super initialize.
	groups := Dictionary new
]
