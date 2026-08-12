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
		^ request stringArgumentNamed: 'onConflict' default: aTool defaultOnConflict ].
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

	((request hasArgumentNamed: fieldName) and: [ projectCollections anySatisfy: [ :each | each notEmpty ] ]) ifFalse: [ ^ self ].
	MCPCommandError
		signalErrorCode: #AmbiguousLoadPolicy
		message: fieldName , ' cannot be combined with project-specific Metacello policy lists.'
		details: { (#field -> fieldName) } asDictionary
]

{ #category : 'private - parsing' }
MCPLoadPolicySpec class >> signalIfPolicyField: fieldName isPresentIn: policy withAny: projectCollections [

	(((policy includesKey: fieldName asSymbol) or: [ policy includesKey: fieldName asString ]) and: [
		 projectCollections anySatisfy: [ :each | each notEmpty ] ]) ifFalse: [ ^ self ].
	MCPCommandError
		signalErrorCode: #AmbiguousLoadPolicy
		message: fieldName , ' cannot be combined with project-specific Metacello policy lists.'
		details: { (#field -> fieldName) } asDictionary
]

{ #category : 'private - applying' }
MCPLoadPolicySpec >> applyConflictPolicyTo: metacello [

	self hasProjectSpecificConflictPolicy ifTrue: [
		^ metacello onConflictUseIncoming: self onConflictUseIncoming useLoaded: self onConflictUseLoaded ].
	self onConflict = 'useLoaded' ifTrue: [ ^ metacello onConflictUseLoaded ].
	self onConflict = 'useIncoming' ifTrue: [ ^ metacello onConflictUseIncoming ].
	self onConflict = 'pass' ifTrue: [ ^ self ].
	self signalUnsupportedPolicyNamed: 'conflict' allowedValues: #( 'useLoaded' 'useIncoming' 'pass' )
]

{ #category : 'private - applying' }
MCPLoadPolicySpec >> applyDowngradePolicyTo: metacello [

	self hasProjectSpecificDowngradePolicy ifTrue: [ ^ metacello onDowngradeUseIncoming: self onDowngradeUseIncoming ].
	self onDowngrade = 'useIncoming' ifTrue: [ ^ metacello onDowngradeUseIncoming ].
	self onDowngrade = 'pass' ifTrue: [ ^ self ].
	self signalUnsupportedPolicyNamed: 'downgrade' allowedValues: #( 'useIncoming' 'pass' )
]

{ #category : 'private - applying' }
MCPLoadPolicySpec >> applyLockPolicyTo: metacello [

	self hasProjectSpecificLockPolicy ifTrue: [ ^ metacello onLockBreak: self onLockBreak ].
	self onLock = 'break' ifTrue: [ ^ metacello onLockBreak ].
	self onLock = 'pass' ifTrue: [ ^ self ].
	self signalUnsupportedPolicyNamed: 'lock' allowedValues: #( 'break' 'pass' )
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

	self hasProjectSpecificUpgradePolicy ifTrue: [ ^ metacello onUpgradeUseLoaded: self onUpgradeUseLoaded ].
	self onUpgrade = 'useLoaded' ifTrue: [ ^ metacello onUpgradeUseLoaded ].
	self onUpgrade = 'pass' ifTrue: [ ^ self ].
	self signalUnsupportedPolicyNamed: 'upgrade' allowedValues: #( 'useLoaded' 'pass' )
]

{ #category : 'private - applying' }
MCPLoadPolicySpec >> applyWarningPolicyTo: metacello [

	self onWarning = 'log' ifTrue: [ ^ metacello onWarningLog ].
	self onWarning = 'resume' ifTrue: [ ^ metacello onWarning: [ :warning | warning resume ] ].
	self onWarning = 'pass' ifTrue: [ ^ self ].
	self signalUnsupportedPolicyNamed: 'warning' allowedValues: #( 'log' 'resume' 'pass' )
]

{ #category : 'converting' }
MCPLoadPolicySpec >> asDictionary [

	| data |
	data := Dictionary new.
	self onWarning = 'log' ifFalse: [ data at: #warning put: self onWarning ].
	self onConflict = 'useLoaded' ifFalse: [ data at: #conflict put: self onConflict ].
	self onConflictUseIncoming ifNotEmpty: [ :projects | data at: #conflictUseIncoming put: projects ].
	self onConflictUseLoaded ifNotEmpty: [ :projects | data at: #conflictUseLoaded put: projects ].
	self onUpgrade = self class defaultOnUpgrade ifFalse: [ data at: #upgrade put: self onUpgrade ].
	self onUpgradeUseLoaded ifNotEmpty: [ :projects | data at: #upgradeUseLoaded put: projects ].
	self onDowngrade = self class defaultOnDowngrade ifFalse: [ data at: #downgrade put: self onDowngrade ].
	self onDowngradeUseIncoming ifNotEmpty: [ :projects | data at: #downgradeUseIncoming put: projects ].
	self onLock = self class defaultOnLock ifFalse: [ data at: #lock put: self onLock ].
	self onLockBreak ifNotEmpty: [ :projects | data at: #lockBreak put: projects ].
	^ data
]

{ #category : 'testing' }
MCPLoadPolicySpec >> hasProjectSpecificConflictPolicy [

	^ self onConflictUseIncoming notEmpty or: [ self onConflictUseLoaded notEmpty ]
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

	| policy |
	policy := request argumentNamed: 'policy' ifAbsent: [ Dictionary new ].
	onConflictUseIncoming := request uniqueStringCollectionFrom:
		                         (request stringCollectionArgumentNamed: 'conflictUseIncoming' in: policy).
	onConflictUseLoaded := request uniqueStringCollectionFrom:
		                       (request stringCollectionArgumentNamed: 'conflictUseLoaded' in: policy).
	onUpgradeUseLoaded := request uniqueStringCollectionFrom: (request stringCollectionArgumentNamed: 'upgradeUseLoaded' in: policy).
	onDowngradeUseIncoming := request uniqueStringCollectionFrom:
		                          (request stringCollectionArgumentNamed: 'downgradeUseIncoming' in: policy).
	onLockBreak := request uniqueStringCollectionFrom: (request stringCollectionArgumentNamed: 'lockBreak' in: policy).
	self class signalIfPolicyField: 'conflict' isPresentIn: policy withAny: {
			onConflictUseIncoming.
			onConflictUseLoaded }.
	self class signalIfPolicyField: 'upgrade' isPresentIn: policy withAny: { onUpgradeUseLoaded }.
	self class signalIfPolicyField: 'downgrade' isPresentIn: policy withAny: { onDowngradeUseIncoming }.
	self class signalIfPolicyField: 'lock' isPresentIn: policy withAny: { onLockBreak }.
	onWarning := request stringArgumentNamed: 'warning' in: policy default: aTool defaultOnWarning.
	onConflict := (onConflictUseIncoming isEmpty and: [ onConflictUseLoaded isEmpty ])
		              ifTrue: [ request stringArgumentNamed: 'conflict' in: policy default: aTool defaultOnConflict ]
		              ifFalse: [ 'pass' ].
	onUpgrade := request stringArgumentNamed: 'upgrade' in: policy default: self class defaultOnUpgrade.
	onDowngrade := request stringArgumentNamed: 'downgrade' in: policy default: self class defaultOnDowngrade.
	onLock := request stringArgumentNamed: 'lock' in: policy default: self class defaultOnLock
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
