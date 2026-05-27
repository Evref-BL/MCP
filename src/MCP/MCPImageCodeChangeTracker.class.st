"
Tracks image-side code changes that may affect registered tools.

It listens to system announcements, records affected packages, and lets the server decide when tool metadata or catalog state should be refreshed.
"
Class {
	#name : 'MCPImageCodeChangeTracker',
	#superclass : 'Object',
	#instVars : [
		'announcer',
		'hasChanges',
		'affectedPackageNames'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'accessing' }
MCPImageCodeChangeTracker >> affectedPackageNames [

	^ affectedPackageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPImageCodeChangeTracker >> announcer: anAnnouncer [

	announcer := anAnnouncer
]

{ #category : 'accessing' }
MCPImageCodeChangeTracker >> hasChanges [

	^ hasChanges ifNil: [ false ]
]

{ #category : 'initialization' }
MCPImageCodeChangeTracker >> initialize [

	super initialize.
	announcer := SystemAnnouncer uniqueInstance.
	hasChanges := false.
	affectedPackageNames := Set new
]

{ #category : 'tracking' }
MCPImageCodeChangeTracker >> recordAffectedPackagesFrom: anAnnouncement [

	[
		(anAnnouncement respondsTo: #packagesAffected) ifTrue: [
				anAnnouncement packagesAffected do: [ :package |
					package ifNotNil: [ self recordPackageName: package name ] ].
				^ self ].
		(anAnnouncement respondsTo: #package) ifTrue: [
				| package |
				package := anAnnouncement package.
				package ifNotNil: [ self recordPackageName: package name ] ] ]
		on: Error
		do: [ :error | self ]
]

{ #category : 'tracking' }
MCPImageCodeChangeTracker >> recordCodeChangeAnnouncement: anAnnouncement [

	hasChanges := true.
	self recordAffectedPackagesFrom: anAnnouncement
]

{ #category : 'tracking' }
MCPImageCodeChangeTracker >> recordPackageName: aPackageName [

	aPackageName ifNil: [ ^ self ].
	self affectedPackageNames add: aPackageName asString
]

{ #category : 'tracking' }
MCPImageCodeChangeTracker >> subscribe [

	announcer
		when: ClassAnnouncement
		send: #recordCodeChangeAnnouncement:
		to: self.
	announcer
		when: MethodAnnouncement
		send: #recordCodeChangeAnnouncement:
		to: self.
	announcer
		when: PackageAnnouncement
		send: #recordCodeChangeAnnouncement:
		to: self
]

{ #category : 'tracking' }
MCPImageCodeChangeTracker >> trackDuring: aBlock [

	[
		[ self subscribe ]
			on: Error
			do: [ :error | hasChanges := true ].
		^ aBlock value ] ensure: [
			[ self unsubscribe ]
				on: Error
				do: [ :error | hasChanges := true ] ]
]

{ #category : 'tracking' }
MCPImageCodeChangeTracker >> unsubscribe [

	announcer ifNotNil: [ announcer unsubscribe: self ]
]
