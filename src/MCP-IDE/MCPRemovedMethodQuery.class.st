"
The methods the image's change history shows removed and the image still lacks. A tool that finds no method names them, since method_restore can bring them back, where an agent told only that a method does not exist rewrites it from memory.

The history is the one method_version_list reads, through the same indexes: the session in progress and the earlier sessions it continues, back to where the image was last saved. A method's newest recorded change decides, so a method removed and then compiled again is not answered, and each removal is said to be from this session or from before the image was last saved. An image without a change history monitor answers none.
"
Class {
	#name : 'MCPRemovedMethodQuery',
	#superclass : 'Object',
	#instVars : [
		'versionQuery'
	],
	#category : 'MCP-IDE-Queries',
	#package : 'MCP-IDE',
	#tag : 'Queries'
}

{ #category : 'instance creation' }
MCPRemovedMethodQuery class >> inCurrentSession [
	"The history method_version_list reads: the session in progress, written out first so that its last entries are read, and the earlier sessions it continues. An image without a monitor keeps none."

	^ self onVersionQuery: MCPMethodVersionQuery inCurrentSession
]

{ #category : 'instance creation' }
MCPRemovedMethodQuery class >> onLog: anEpLogOrNil directory: aDirectoryOrNil [
	"A query over that history, where nil stands for an image that keeps none. The earlier sessions it continues are looked for in aDirectoryOrNil, and none when it is nil."

	^ self onVersionQuery: (MCPMethodVersionQuery onLog: anEpLogOrNil directory: aDirectoryOrNil)
]

{ #category : 'instance creation' }
MCPRemovedMethodQuery class >> onVersionQuery: aMethodVersionQuery [
	"A query over the history aMethodVersionQuery reads."

	^ self new
		  setVersionQuery: aMethodVersionQuery;
		  yourself
]

{ #category : 'private - history' }
MCPRemovedMethodQuery >> behaviorNamed: aBehaviorName stillLacking: aSelector [
	"The behavior a method was removed from, when it still exists and still lacks that method."

	^ (self class environment classNamed: aBehaviorName) ifNotNil: [ :behavior |
		  (behavior includesSelector: aSelector) ifFalse: [ behavior ] ]
]

{ #category : 'querying' }
MCPRemovedMethodQuery >> hintAfterNameSelecting: aBlock [
	"The same hint, for an answer that has just named the one method aBlock accepts: when it was removed, and that method_restore brings it back."

	self removedMethodsSelecting: aBlock do: [ :reference :inThisSession |
			^ String streamContents: [ :stream |
					  stream << 'It was removed ' << (self whenRemoved: inThisSession) << ': '.
					  self toolBringingBack: 'it' on: stream ] ].
	^ nil
]

{ #category : 'querying' }
MCPRemovedMethodQuery >> hintSelecting: aBlock [
	"Which of the removed methods aBlock accepts method_restore can bring back, and when each was removed, or nil when there is none. It names the tool rather than its arguments: tool_get gives those."

	| inThisSession earlier |
	inThisSession := OrderedCollection new.
	earlier := OrderedCollection new.
	self removedMethodsSelecting: aBlock do: [ :reference :removedInThisSession |
			(removedInThisSession
				 ifTrue: [ inThisSession ]
				 ifFalse: [ earlier ]) add: reference ].
	(inThisSession isEmpty and: [ earlier isEmpty ]) ifTrue: [ ^ nil ].
	^ String streamContents: [ :stream | self removedInThisSession: inThisSession andBefore: earlier on: stream ]
]

{ #category : 'private - printing' }
MCPRemovedMethodQuery >> names: references removedInThisSession: inThisSession on: aStream [
	"A was removed, or A and B were removed, in this session or before the image was last saved."

	aStream << (MCPCommandError joinedNames: references upTo: 3).
	aStream << (references size = 1
		 ifTrue: [ ' was' ]
		 ifFalse: [ ' were' ]) << ' removed ' << (self whenRemoved: inThisSession)
]

{ #category : 'private - history' }
MCPRemovedMethodQuery >> removalsDo: aBlock [
	"aBlock gets the behavior name, the selector and the protocol of each method whose newest recorded change is a removal, newest first, and whether the session in progress made that removal. A removal in an earlier session counts when no session after it changed the method again."

	| later |
	later := OrderedCollection new.
	versionQuery indexesDo: [ :index :lastNumber |
			index removalsUpTo: lastNumber do: [ :behaviorName :selector :protocol |
					(later anySatisfy: [ :each |
							 each key
								 hasChangeToBehaviorNamed: behaviorName
								 selector: selector
								 between: 1
								 and: each value ]) ifFalse: [
							aBlock
								value: behaviorName
								value: selector
								value: protocol
								value: later isEmpty ] ].
			later add: index -> lastNumber ]
]

{ #category : 'private - printing' }
MCPRemovedMethodQuery >> removedInThisSession: inThisSession andBefore: earlier on: aStream [
	"A was removed in this session, and B and C were removed before the image was last saved: method_restore brings them back. Either group may be empty, not both."

	({
		 (inThisSession -> true).
		 (earlier -> false) } reject: [ :group | group key isEmpty ])
		do: [ :group | self names: group key removedInThisSession: group value on: aStream ]
		separatedBy: [ aStream << ', and ' ].
	aStream << ': '.
	self
		toolBringingBack: (inThisSession size + earlier size = 1
				 ifTrue: [ 'it' ]
				 ifFalse: [ 'them' ])
		on: aStream
]

{ #category : 'querying' }
MCPRemovedMethodQuery >> removedMethodsSelecting: aBlock do: aReferenceBlock [
	"aReferenceBlock gets each method the history removed and the image still lacks that aBlock accepts, newest first, named as Foo>>bar or Foo class>>bar, and whether this session removed it. aBlock takes the behavior a method was removed from, its selector and its protocol. A method compiled again after its removal is not one."

	self removalsDo: [ :behaviorName :selector :protocol :inThisSession |
			(self behaviorNamed: behaviorName stillLacking: selector) ifNotNil: [ :behavior |
					(aBlock value: behavior value: selector value: protocol) ifTrue: [
						aReferenceBlock
							value: (String streamContents: [ :stream | stream << behavior name << '>>' << selector ])
							value: inThisSession ] ] ]
]

{ #category : 'initialization' }
MCPRemovedMethodQuery >> setVersionQuery: aMethodVersionQuery [

	versionQuery := aMethodVersionQuery
]

{ #category : 'private - printing' }
MCPRemovedMethodQuery >> toolBringingBack: aPronoun on: aStream [
	"Names the tool without saying how to reach it: whether a client lists it or reaches it through the catalog is the server's setting, which a hint cannot know."

	aStream << 'method_restore brings ' << aPronoun << ' back.'
]

{ #category : 'private - printing' }
MCPRemovedMethodQuery >> whenRemoved: inThisSession [
	"A removal is the session in progress's, or an earlier session's that this one continues, which the image held when it was last saved."

	^ inThisSession
		  ifTrue: [ 'in this session' ]
		  ifFalse: [ 'before the image was last saved' ]
]
