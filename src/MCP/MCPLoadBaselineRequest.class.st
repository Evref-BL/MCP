"
Parsed request for loading an existing Metacello baseline. It stores baseline groups and the shared Metacello load policy used by direct baseline and repository-backed loads.
"
Class {
	#name : 'MCPLoadBaselineRequest',
	#superclass : 'Object',
	#instVars : [
		'baseline',
		'groups',
		'loadPolicy'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPLoadBaselineRequest class >> baseline: baselineName groups: groupNames loadPolicy: aLoadPolicy [

	^ self new initializeBaseline: baselineName groups: groupNames loadPolicy: aLoadPolicy
]

{ #category : 'instance creation' }
MCPLoadBaselineRequest class >> fromLoadRepositoryRequest: aRequest [

	^ self baseline: aRequest baseline groups: aRequest groups loadPolicy: aRequest loadPolicy
]

{ #category : 'instance creation' }
MCPLoadBaselineRequest class >> fromRequest: request tool: aTool [

	^ self
		  baseline: (request stringArgumentNamed: 'baseline')
		  groups: (request uniqueStringCollectionArgumentNamed: 'groups' default: #(  ))
		  loadPolicy: (MCPLoadPolicySpec fromRequest: request tool: aTool)
]

{ #category : 'accessing' }
MCPLoadBaselineRequest >> baseline [

	^ baseline
]

{ #category : 'accessing' }
MCPLoadBaselineRequest >> groups [

	^ groups ifNil: [ #(  ) ]
]

{ #category : 'initialization' }
MCPLoadBaselineRequest >> initializeBaseline: baselineName groups: groupNames loadPolicy: aLoadPolicy [

	baseline := baselineName.
	groups := groupNames ifNil: [ #(  ) ].
	loadPolicy := aLoadPolicy.
	^ self
]

{ #category : 'accessing' }
MCPLoadBaselineRequest >> loadPolicy [

	^ loadPolicy
]

{ #category : 'accessing' }
MCPLoadBaselineRequest >> onConflict [

	^ self loadPolicy onConflict
]

{ #category : 'accessing' }
MCPLoadBaselineRequest >> onWarning [

	^ self loadPolicy onWarning
]

{ #category : 'converting' }
MCPLoadBaselineRequest >> requestedContext [

	| context policy |
	context := { (#baseline -> self baseline) } asDictionary.
	self groups ifNotEmpty: [ :loadGroups | context at: #groups put: loadGroups ].
	policy := self loadPolicy asDictionary.
	policy ifNotEmpty: [ context at: #policy put: policy ].
	^ context
]
