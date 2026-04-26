"
Parsed remove-classes tool request derived from one validated MCPToolRequest.
"
Class {
	#name : 'MCPRemoveClassesRequest',
	#superclass : 'Object',
	#instVars : [
		'classNames',
		'force'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRemoveClassesRequest class >> fromRequest: aRequest tool: aTool [

	^ self new
		  initializeClassNames: (aTool classNamesFromRequest: aRequest)
		  force: (aRequest booleanArgumentNamed: 'force' default: false)
]

{ #category : 'accessing' }
MCPRemoveClassesRequest >> classNames [

	^ classNames
]

{ #category : 'accessing' }
MCPRemoveClassesRequest >> force [

	^ force
]

{ #category : 'initialization' }
MCPRemoveClassesRequest >> initializeClassNames: aCollection force: aBoolean [

	classNames := aCollection.
	force := aBoolean.
	^ self
]
