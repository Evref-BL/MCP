"
One element the sessions since the image's last save changed, and the image may have lost: a method, a class definition or a class comment.

It keeps two states of the element, as Epicea recorded them. The saved state is what the element was at the save, the old side of the first change those sessions made to it; the target state is what their last change made it. A state is nil where the element did not exist. Comparing both with the image tells a lost change (the image still holds the saved state) from one the image holds already, and from a conflict, where the image changed the element since and restoring would discard that.

A subclass says how its kind of element is found in the image, compared and installed.
"
Class {
	#name : 'MCPLostChange',
	#superclass : 'Object',
	#instVars : [
		'savedState',
		'targetState',
		'position',
		'knowsSavedState',
		'isSuperseded',
		'packageName',
		'isChangedInSessionInProgress'
	],
	#category : 'MCP-IDE-Queries',
	#package : 'MCP-IDE',
	#tag : 'Queries'
}

{ #category : 'testing' }
MCPLostChange class >> isAbstract [

	^ self = MCPLostChange
]

{ #category : 'restoring' }
MCPLostChange >> addDefinitionTo: classChangesByName [
	"Only a class definition counts towards the order of the others."

	
]

{ #category : 'converting' }
MCPLostChange >> addTargetTo: aDictionary [
	"Put in aDictionary what restoring installs, as text."

	self subclassResponsibility
]

{ #category : 'accessing' }
MCPLostChange >> affectedClassName [
	"The class the element is or belongs to, by its instance-side name."

	^ self subclassResponsibility
]

{ #category : 'converting' }
MCPLostChange >> asDictionary [
	"What the element is, what the lost change did, and what restoring installs; for a conflict, why, and the version restoring would replace."

	| data |
	data := Dictionary new.
	data at: #element put: self element.
	data at: #change put: self changeDescription.
	self addTargetTo: data.
	self isChangedSinceSave ifTrue: [
			data at: #conflict put: self conflictReason.
			self imageVersionIfPresent: [ :version | data at: #inImage put: version ] ifAbsent: [ ] ].
	^ data
]

{ #category : 'updating' }
MCPLostChange >> beChangedInSessionInProgress [
	"The session in progress changed the element after this lost change: the image went on without it."

	isChangedInSessionInProgress := true
]

{ #category : 'updating' }
MCPLostChange >> becomes: aState at: anInteger [
	"A later change: the element is now aState, as the anInteger-th entry read made it."

	targetState := aState.
	position := anInteger.
	isSuperseded := false
]

{ #category : 'accessing' }
MCPLostChange >> changeDescription [
	"What the lost change did to the element since the save, such as method added."

	^ self subclassResponsibility
]

{ #category : 'converting' }
MCPLostChange >> conflictReason [
	"Why restoring would lose something, for a change the image made since its save."

	^ self
		  imageVersionIfPresent: [ :version | 'The image changed it since it was saved: restoring discards that change.' ]
		  ifAbsent: [ 'The image removed it since it was saved: restoring brings it back.' ]
]

{ #category : 'accessing' }
MCPLostChange >> element [
	"How the element is named, as restoring takes it: Foo>>bar, Foo class>>bar, or Foo."

	^ self subclassResponsibility
]

{ #category : 'private - image' }
MCPLostChange >> imageClassIfPresent: presentBlock ifAbsent: absentBlock [

	^ Smalltalk globals at: self affectedClassName asSymbol ifPresent: presentBlock ifAbsent: absentBlock
]

{ #category : 'testing' }
MCPLostChange >> imageHolds: aState [
	"Whether the element is in the image as aState records it, or missing from it when aState is nil."

	^ self subclassResponsibility
]

{ #category : 'testing' }
MCPLostChange >> imageHoldsSavedState [
	"Whether the image still holds the element as it was saved, which restoring may replace without losing anything."

	^ self imageHolds: savedState
]

{ #category : 'converting' }
MCPLostChange >> imageVersionIfPresent: presentBlock ifAbsent: absentBlock [
	"The element as the image has it now, as text: a method's source, a class's definition, a comment."

	^ self subclassResponsibility
]

{ #category : 'initialization' }
MCPLostChange >> initialize [

	super initialize.
	knowsSavedState := true.
	isSuperseded := false.
	isChangedInSessionInProgress := false
]

{ #category : 'testing' }
MCPLostChange >> isChangedSinceSave [
	"The image holds the element not as the lost change made it, and the session in progress changed it, or the image holds it not as it was saved either: something changed it since the save, and restoring would discard that. The session in progress counts even where it put the element back as it was saved, as removing what a lost session added does."

	self isInImage ifTrue: [ ^ false ].
	^ isChangedInSessionInProgress or: [ knowsSavedState and: [ self imageHoldsSavedState not ] ]
]

{ #category : 'testing' }
MCPLostChange >> isInImage [
	"Whether the image already holds what the last change made, so nothing is lost."

	^ self imageHolds: targetState
]

{ #category : 'testing' }
MCPLostChange >> isLostWithoutConflict [
	"The image lacks what the last change made, and has not changed the element since its save: nothing replaced the work, and restoring it discards nothing."

	^ self isInImage not and: [ self isChangedSinceSave not ]
]

{ #category : 'testing' }
MCPLostChange >> isNamedBy: anElementName [

	^ self element = anElementName
]

{ #category : 'testing' }
MCPLostChange >> isSuperseded [

	^ isSuperseded
]

{ #category : 'accessing' }
MCPLostChange >> packageName [
	"The package the last change to the element was made in, nil for code in no package."

	^ packageName
]

{ #category : 'updating' }
MCPLostChange >> packageName: aPackageName [

	packageName := aPackageName
]

{ #category : 'accessing' }
MCPLostChange >> position [
	"Which entry read made the last change, counting across the sessions in the order they were written."

	^ position
]

{ #category : 'restoring' }
MCPLostChange >> restoreDepthAmong: classChangesByName [
	"Where the change goes within its phase, before its position: only a class definition depends on another change of its phase."

	^ 0
]

{ #category : 'restoring' }
MCPLostChange >> restoreIfImpossible: aBlock [
	"Install what the last change made, exactly as Epicea recorded it, or evaluate aBlock with the reason it cannot be."

	self subclassResponsibility
]

{ #category : 'restoring' }
MCPLostChange >> restorePhase [
	"Changes restore in phases, so each finds what it needs: definitions, traits first, then comments, methods, method removals and class removals last."

	^ self subclassResponsibility
]

{ #category : 'initialization' }
MCPLostChange >> savedState: aState [

	savedState := aState
]

{ #category : 'initialization' }
MCPLostChange >> savedStateIsUnknown [
	"The first change read records the element after it and not before, as a move to another package does: no conflict can be told."

	knowsSavedState := false
]

{ #category : 'restoring' }
MCPLostChange >> shouldRestoreBefore: aLostChange among: classChangesByName [
	"By phase, then by what the phase needs first, then in the order the changes were made."

	| depth otherDepth |
	self restorePhase = aLostChange restorePhase ifFalse: [ ^ self restorePhase < aLostChange restorePhase ].
	depth := self restoreDepthAmong: classChangesByName.
	otherDepth := aLostChange restoreDepthAmong: classChangesByName.
	depth = otherDepth ifFalse: [ ^ depth < otherDepth ].
	^ position < aLostChange position
]

{ #category : 'updating' }
MCPLostChange >> supersede [
	"Removing the element's class removes the element with it, so restoring the class removal restores this change too, until a later change makes the element again."

	isSuperseded := true
]
