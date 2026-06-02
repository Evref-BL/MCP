"
Parsed Metacello load policy specification shared by baseline_load and repository_load. It applies warning, conflict, upgrade, downgrade, and lock options to Metacello without duplicating policy parsing in load commands.
"
Class {
	#name : 'MCPLoadPolicySpec',
	#superclass : 'Object',
	#instVars : [
		'onWarning',
		'onConflict',
		'onConflictUseIncoming',
		'onConflictUseLoaded',
		'onUpgrade',
		'onUpgradeUseLoaded',
		'onDowngrade',
		'onDowngradeUseIncoming',
		'onLock',
		'onLockBreak'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'private - parsing' }
MCPLoadPolicySpec class >> conflictPolicyFromRequest: request tool: aTool useIncoming: incomingProjects useLoaded: loadedProjects [

	(incomingProjects isEmpty and: [ loadedProjects isEmpty ]) ifTrue: [
			^ request
				  stringArgumentNamed: 'onConflict'
				  default: aTool defaultOnConflict ].
	^ 'pass'
]

{ #category : 'defaults' }
MCPLoadPolicySpec class >> defaultOnDowngrade [

	^ 'pass'
]

{ #category : 'defaults' }
MCPLoadPolicySpec class >> defaultOnLock [

	^ 'pass'
]

{ #category : 'defaults' }
MCPLoadPolicySpec class >> defaultOnUpgrade [

	^ 'pass'
]

{ #category : 'instance creation' }
MCPLoadPolicySpec class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request tool: aTool
]

{ #category : 'private - parsing' }
MCPLoadPolicySpec class >> signalIfGlobalField: fieldName isCombinedIn: request withAny: projectCollections [

	((request hasArgumentNamed: fieldName) and: [
		 projectCollections anySatisfy: [ :each | each notEmpty ] ])
		ifFalse: [ ^ self ].
	MCPCommandError
		signalErrorCode: #AmbiguousLoadPolicy
		message: fieldName
			,
			' cannot be combined with project-specific Metacello policy lists.'
		details: { (#field -> fieldName) } asDictionary
]

{ #category : 'private - applying' }
MCPLoadPolicySpec >> applyConflictPolicyTo: metacello [

	self hasProjectSpecificConflictPolicy ifTrue: [
			^ metacello
				  onConflictUseIncoming: self onConflictUseIncoming
				  useLoaded: self onConflictUseLoaded ].
	self onConflict = 'useLoaded' ifTrue: [
		^ metacello onConflictUseLoaded ].
	self onConflict = 'useIncoming' ifTrue: [
		^ metacello onConflictUseIncoming ].
	self onConflict = 'pass' ifTrue: [ ^ self ].
	self
		signalUnsupportedPolicyNamed: 'onConflict'
		allowedValues: #( 'useLoaded' 'useIncoming' 'pass' )
]

{ #category : 'private - applying' }
MCPLoadPolicySpec >> applyDowngradePolicyTo: metacello [

	self hasProjectSpecificDowngradePolicy ifTrue: [
		^ metacello onDowngradeUseIncoming: self onDowngradeUseIncoming ].
	self onDowngrade = 'useIncoming' ifTrue: [
		^ metacello onDowngradeUseIncoming ].
	self onDowngrade = 'pass' ifTrue: [ ^ self ].
	self
		signalUnsupportedPolicyNamed: 'onDowngrade'
		allowedValues: #( 'useIncoming' 'pass' )
]

{ #category : 'private - applying' }
MCPLoadPolicySpec >> applyLockPolicyTo: metacello [

	self hasProjectSpecificLockPolicy ifTrue: [
		^ metacello onLockBreak: self onLockBreak ].
	self onLock = 'break' ifTrue: [ ^ metacello onLockBreak ].
	self onLock = 'pass' ifTrue: [ ^ self ].
	self
		signalUnsupportedPolicyNamed: 'onLock'
		allowedValues: #( 'break' 'pass' )
]

{ #category : 'applying' }
MCPLoadPolicySpec >> applyTo: metacello [

	self applyWarningPolicyTo: metacello.
	self applyConflictPolicyTo: metacello.
	self applyUpgradePolicyTo: metacello.
	self applyDowngradePolicyTo: metacello.
	self applyLockPolicyTo: metacello.
	^ metacello
]

{ #category : 'private - applying' }
MCPLoadPolicySpec >> applyUpgradePolicyTo: metacello [

	self hasProjectSpecificUpgradePolicy ifTrue: [
		^ metacello onUpgradeUseLoaded: self onUpgradeUseLoaded ].
	self onUpgrade = 'useLoaded' ifTrue: [
		^ metacello onUpgradeUseLoaded ].
	self onUpgrade = 'pass' ifTrue: [ ^ self ].
	self
		signalUnsupportedPolicyNamed: 'onUpgrade'
		allowedValues: #( 'useLoaded' 'pass' )
]

{ #category : 'private - applying' }
MCPLoadPolicySpec >> applyWarningPolicyTo: metacello [

	self onWarning = 'log' ifTrue: [ ^ metacello onWarningLog ].
	self onWarning = 'resume' ifTrue: [
		^ metacello onWarning: [ :warning | warning resume ] ].
	self onWarning = 'pass' ifTrue: [ ^ self ].
	self
		signalUnsupportedPolicyNamed: 'onWarning'
		allowedValues: #( 'log' 'resume' 'pass' )
]

{ #category : 'converting' }
MCPLoadPolicySpec >> asDictionary [

	^ {
		  (#onWarning -> self onWarning).
		  (#onConflict -> self onConflict).
		  (#onConflictUseIncoming -> self onConflictUseIncoming).
		  (#onConflictUseLoaded -> self onConflictUseLoaded).
		  (#onUpgrade -> self onUpgrade).
		  (#onUpgradeUseLoaded -> self onUpgradeUseLoaded).
		  (#onDowngrade -> self onDowngrade).
		  (#onDowngradeUseIncoming -> self onDowngradeUseIncoming).
		  (#onLock -> self onLock).
		  (#onLockBreak -> self onLockBreak) } asDictionary
]

{ #category : 'testing' }
MCPLoadPolicySpec >> hasProjectSpecificConflictPolicy [

	^ self onConflictUseIncoming notEmpty or: [
		  self onConflictUseLoaded notEmpty ]
]

{ #category : 'testing' }
MCPLoadPolicySpec >> hasProjectSpecificDowngradePolicy [

	^ self onDowngradeUseIncoming notEmpty
]

{ #category : 'testing' }
MCPLoadPolicySpec >> hasProjectSpecificLockPolicy [

	^ self onLockBreak notEmpty
]

{ #category : 'testing' }
MCPLoadPolicySpec >> hasProjectSpecificUpgradePolicy [

	^ self onUpgradeUseLoaded notEmpty
]

{ #category : 'initialization' }
MCPLoadPolicySpec >> initializeFromRequest: request tool: aTool [

	onConflictUseIncoming := request
		                         uniqueStringCollectionArgumentNamed:
		                         'onConflictUseIncoming'
		                         default: #(  ).
	onConflictUseLoaded := request
		                       uniqueStringCollectionArgumentNamed:
		                       'onConflictUseLoaded'
		                       default: #(  ).
	onUpgradeUseLoaded := request
		                      uniqueStringCollectionArgumentNamed:
		                      'onUpgradeUseLoaded'
		                      default: #(  ).
	onDowngradeUseIncoming := request
		                          uniqueStringCollectionArgumentNamed:
		                          'onDowngradeUseIncoming'
		                          default: #(  ).
	onLockBreak := request
		               uniqueStringCollectionArgumentNamed: 'onLockBreak'
		               default: #(  ).
	self class
		signalIfGlobalField: 'onConflict'
		isCombinedIn: request
		withAny: {
				onConflictUseIncoming.
				onConflictUseLoaded }.
	self class
		signalIfGlobalField: 'onUpgrade'
		isCombinedIn: request
		withAny: { onUpgradeUseLoaded }.
	self class
		signalIfGlobalField: 'onDowngrade'
		isCombinedIn: request
		withAny: { onDowngradeUseIncoming }.
	self class
		signalIfGlobalField: 'onLock'
		isCombinedIn: request
		withAny: { onLockBreak }.
	onWarning := request
		             stringArgumentNamed: 'onWarning'
		             default: aTool defaultOnWarning.
	onConflict := self class
		              conflictPolicyFromRequest: request
		              tool: aTool
		              useIncoming: onConflictUseIncoming
		              useLoaded: onConflictUseLoaded.
	onUpgrade := request
		             stringArgumentNamed: 'onUpgrade'
		             default: self class defaultOnUpgrade.
	onDowngrade := request
		               stringArgumentNamed: 'onDowngrade'
		               default: self class defaultOnDowngrade.
	onLock := request
		          stringArgumentNamed: 'onLock'
		          default: self class defaultOnLock.
	^ self
]

{ #category : 'accessing' }
MCPLoadPolicySpec >> onConflict [

	^ onConflict
]

{ #category : 'accessing' }
MCPLoadPolicySpec >> onConflictUseIncoming [

	^ onConflictUseIncoming ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPLoadPolicySpec >> onConflictUseLoaded [

	^ onConflictUseLoaded ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPLoadPolicySpec >> onDowngrade [

	^ onDowngrade
]

{ #category : 'accessing' }
MCPLoadPolicySpec >> onDowngradeUseIncoming [

	^ onDowngradeUseIncoming ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPLoadPolicySpec >> onLock [

	^ onLock
]

{ #category : 'accessing' }
MCPLoadPolicySpec >> onLockBreak [

	^ onLockBreak ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPLoadPolicySpec >> onUpgrade [

	^ onUpgrade
]

{ #category : 'accessing' }
MCPLoadPolicySpec >> onUpgradeUseLoaded [

	^ onUpgradeUseLoaded ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPLoadPolicySpec >> onWarning [

	^ onWarning
]

{ #category : 'private - applying' }
MCPLoadPolicySpec >> signalUnsupportedPolicyNamed: policyName allowedValues: allowedValues [

	MCPCommandError
		signalErrorCode: #UnsupportedLoadMetacelloPolicy
		message: (String streamContents: [ :stream |
					 stream
						 nextPutAll: policyName;
						 nextPutAll: ' must be one of ';
						 nextPutAll: allowedValues asArray printString;
						 nextPut: $. ])
		details: self asDictionary
]
