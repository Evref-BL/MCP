"
The methods the session in progress removed and has not added back, read from its change history. A tool that finds no method names them, since the history tools can bring them back, where an agent told only that a method does not exist rewrites it from memory.

The newest change to a method decides, so a method removed and then compiled again is not answered, and the history is read from its newest entry. An image without a change history monitor answers none.
"
Class {
	#name : 'MCPRemovedMethodQuery',
	#superclass : 'Object',
	#instVars : [
		'log'
	],
	#category : 'MCP-IDE-Queries',
	#package : 'MCP-IDE',
	#tag : 'Queries'
}

{ #category : 'instance creation' }
MCPRemovedMethodQuery class >> inCurrentSession [
	"The history the image's change history monitor keeps for the session in progress, written out first so that its last entries are read. An image without a monitor keeps none."

	EpMonitor hasCurrent ifFalse: [ ^ self onLog: nil ].
	EpMonitor current sessionStore flush.
	^ self onLog: EpMonitor current log
]

{ #category : 'instance creation' }
MCPRemovedMethodQuery class >> onLog: anEpLogOrNil [
	"A query over that history, where nil stands for an image that keeps none."

	^ self new
		  setLog: anEpLogOrNil;
		  yourself
]

{ #category : 'private - history' }
MCPRemovedMethodQuery >> behaviorStillLacking: aRemoval [
	"The behavior aRemoval took a method from, when it still exists and still lacks that method."

	^ (Smalltalk globals classNamed: aRemoval behaviorAffectedName) ifNotNil: [ :behavior |
		  (behavior includesSelector: aRemoval methodAffectedSelector) ifFalse: [ behavior ] ]
]

{ #category : 'querying' }
MCPRemovedMethodQuery >> hintAfterNameSelecting: aBlock [
	"The same hint, for an answer that has just named the one method aBlock accepts."

	(self removedMethodsSelecting: aBlock) ifEmpty: [ ^ nil ].
	^ String streamContents: [ :stream |
			  stream << 'It was removed in this session: '.
			  self toolsBringingBack: 'it' on: stream ]
]

{ #category : 'querying' }
MCPRemovedMethodQuery >> hintSelecting: aBlock [
	"Which of the removed methods aBlock accepts the history tools can bring back, or nil when there is none. It names the tools rather than their arguments: tool_get gives those."

	| removed one |
	removed := self removedMethodsSelecting: aBlock.
	removed ifEmpty: [ ^ nil ].
	one := removed size = 1.
	^ String streamContents: [ :stream |
			  self names: removed on: stream.
			  stream << (one
				   ifTrue: [ ' was' ]
				   ifFalse: [ ' were' ]) << ' removed in this session: '.
			  self
				  toolsBringingBack: (one
						   ifTrue: [ 'it' ]
						   ifFalse: [ 'them' ])
				  on: stream ]
]

{ #category : 'private - printing' }
MCPRemovedMethodQuery >> names: references on: aStream [
	"A, A and B, A, B and C, or A, B, C and 4 more."

	| shown |
	shown := references size > 3
		         ifTrue: [ (references first: 3) , { ((references size - 3) printString , ' more') } ]
		         ifFalse: [ references ].
	shown size = 1 ifTrue: [ ^ aStream << shown first ].
	aStream << (', ' join: shown allButLast) << ' and ' << shown last
]

{ #category : 'private - history' }
MCPRemovedMethodQuery >> newestMethodChangesDo: aBlock [
	"Each method the history changed, by its newest change, newest first."

	| seen |
	seen := Set new.
	log priorEntriesFromHeadDo: [ :entry |
			| change key |
			change := entry content.
			change isEpMethodChange ifTrue: [
					key := change behaviorAffectedName -> change methodAffectedSelector.
					(seen includes: key) ifFalse: [
							seen add: key.
							aBlock value: change ] ] ]
]

{ #category : 'querying' }
MCPRemovedMethodQuery >> removedMethodsSelecting: aBlock [
	"The methods the history removed and the image still lacks that aBlock accepts, newest first, named as Foo>>bar and Foo class>>bar. aBlock takes the behavior a method was removed from, its selector and its protocol. A method compiled again after its removal is not one."

	| removed |
	log ifNil: [ ^ #(  ) ].
	removed := OrderedCollection new.
	self newestMethodChangesDo: [ :change |
			change mcpIsMethodRemoval ifTrue: [
					(self behaviorStillLacking: change) ifNotNil: [ :behavior |
							(aBlock value: behavior value: change methodAffectedSelector value: change methodAffectedProtocol) ifTrue: [
								removed add: (String streamContents: [ :stream | stream << behavior name << '>>' << change methodAffectedSelector ]) ] ] ] ].
	^ removed asArray
]

{ #category : 'initialization' }
MCPRemovedMethodQuery >> setLog: anEpLogOrNil [

	log := anEpLogOrNil
]

{ #category : 'private - printing' }
MCPRemovedMethodQuery >> toolsBringingBack: aPronoun on: aStream [

	aStream << 'history_entry_list and history_entry_revert, through tool_call, can bring ' << aPronoun << ' back.'
]
