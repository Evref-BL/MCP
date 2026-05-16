"
Parsed request for loading an existing Metacello baseline. It contains only baseline load options and is reused by repository-backed loads.
"
Class {
	#name : 'MCPLoadBaselineRequest',
	#superclass : 'Object',
	#instVars : [
		'baseline',
		'groups',
		'onWarning',
		'onConflict'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPLoadBaselineRequest class >> baseline: baselineName groups: groupNames onWarning: warningPolicy onConflict: conflictPolicy [

	^ self new
		  initializeBaseline: baselineName
		  groups: groupNames
		  onWarning: warningPolicy
		  onConflict: conflictPolicy
]

{ #category : 'instance creation' }
MCPLoadBaselineRequest class >> fromLoadRepositoryRequest: aRequest [

	^ self
		  baseline: aRequest baseline
		  groups: aRequest groups
		  onWarning: aRequest onWarning
		  onConflict: aRequest onConflict
]

{ #category : 'instance creation' }
MCPLoadBaselineRequest class >> fromRequest: request tool: aTool [

	^ self
		  baseline: (request stringArgumentNamed: 'baseline')
		  groups:
		  (request
			   uniqueStringCollectionArgumentNamed: 'groups'
			   default: #(  ))
		  onWarning: (request
				   stringArgumentNamed: 'onWarning'
				   default: aTool defaultOnWarning)
		  onConflict: (request
				   stringArgumentNamed: 'onConflict'
				   default: aTool defaultOnConflict)
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
MCPLoadBaselineRequest >> initializeBaseline: baselineName groups: groupNames onWarning: warningPolicy onConflict: conflictPolicy [

	baseline := baselineName.
	groups := groupNames ifNil: [ #(  ) ].
	onWarning := warningPolicy.
	onConflict := conflictPolicy.
	^ self
]

{ #category : 'accessing' }
MCPLoadBaselineRequest >> onConflict [

	^ onConflict
]

{ #category : 'accessing' }
MCPLoadBaselineRequest >> onWarning [

	^ onWarning
]

{ #category : 'converting' }
MCPLoadBaselineRequest >> requestedContext [

	^ {
		  (#baseline -> self baseline).
		  (#groups -> self groups).
		  (#onWarning -> self onWarning).
		  (#onConflict -> self onConflict) } asDictionary
]
