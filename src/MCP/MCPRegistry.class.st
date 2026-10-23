"
Abstract instance-scoped catalog of MCP entries: tools, resources or prompts.

A registry owns one reusable instance of each entry, keyed and kept in the order the entries were discovered or added. Subclasses say what they hold, through registeredClass, and what each entry is filed under, through keyFor:.

A registry built with #default discovers its classes and keeps doing so: it outlives the classes it found, so it rediscovers them whenever the set of auto-registering classes changes. Entries added by hand survive that rediscovery as long as their class does. A registry built with #empty is curated rather than discovered, holds exactly what was added to it, and never rediscovers.
"
Class {
	#name : 'MCPRegistry',
	#superclass : 'Object',
	#instVars : [
		'entries',
		'discoversClasses',
		'discoveredClasses',
		'changeListener'
	],
	#category : 'MCP-Registries',
	#package : 'MCP',
	#tag : 'Registries'
}

{ #category : 'instance creation' }
MCPRegistry class >> default [

	^ self new
		  reset;
		  yourself
]

{ #category : 'instance creation' }
MCPRegistry class >> empty [

	^ self new
]

{ #category : 'testing' }
MCPRegistry class >> isAbstract [

	^ self = MCPRegistry
]

{ #category : 'entries' }
MCPRegistry >> add: aClassOrEntry [

	| entry key |
	entry := self newEntryFrom: aClassOrEntry.
	key := self keyFor: entry.
	(self includesKey: key) ifTrue: [ Error signal: self registeredClass name , ' already registered: ' , key ].
	self entriesByKey at: key put: entry.
	self noteChanged.
	^ entry
]

{ #category : 'entries' }
MCPRegistry >> addAll: classesOrEntries [

	^ (classesOrEntries collect: [ :each | self add: each ]) asArray
]

{ #category : 'entries' }
MCPRegistry >> at: aKey ifAbsent: absentBlock [

	^ self entriesByKey at: aKey asString ifAbsent: absentBlock
]

{ #category : 'discovery' }
MCPRegistry >> autoRegisteringClasses [

	^ (self registeredClass concreteSubclasses select: [ :each | each shouldAutoRegister ]) asSet
]

{ #category : 'discovery' }
MCPRegistry >> defaultEntries [
	"Answer the entries a fresh registry starts with, in the order they should be listed."

	^ (self autoRegisteringClasses collect: [ :each | self newEntryFrom: each ]) asSortedCollection: [ :left :right |
		  (self keyFor: left) <= (self keyFor: right) ]
]

{ #category : 'change notification' }
MCPRegistry >> changeListener: aBlock [
	"Called with no arguments whenever what this registry holds changes. The server uses it to tell listening clients their cached list is stale."

	changeListener := aBlock
]

{ #category : 'entries' }
MCPRegistry >> entries [

	^ self entriesByKey values asArray
]

{ #category : 'private' }
MCPRegistry >> entriesByKey [

	self rediscoverClassesIfChanged.
	^ entries
]

{ #category : 'entries' }
MCPRegistry >> entryClasses [

	^ (self entries collect: [ :each | each class ]) asArray
]

{ #category : 'testing' }
MCPRegistry >> includesKey: aKey [

	^ self entriesByKey includesKey: aKey asString
]

{ #category : 'initialization' }
MCPRegistry >> initialize [

	super initialize.
	self removeAll
]

{ #category : 'entries' }
MCPRegistry >> keyFor: anEntry [
	"Answer what anEntry is filed under: a tool's name, a resource's URI, a prompt's name."

	^ self subclassResponsibility
]

{ #category : 'entries' }
MCPRegistry >> keys [

	^ self entriesByKey keys asArray
]

{ #category : 'change notification' }
MCPRegistry >> noteChanged [
	"A listener that raises must not take the change with it, so it is the listener's business to be safe."

	changeListener ifNil: [ ^ self ].
	changeListener value
]

{ #category : 'private' }
MCPRegistry >> newEntryFrom: aClassOrEntry [

	^ aClassOrEntry isBehavior
		  ifTrue: [ aClassOrEntry newForRegistry: self ]
		  ifFalse: [ aClassOrEntry ]
]

{ #category : 'discovery' }
MCPRegistry >> rediscoverClassesIfChanged [
	"A discovering registry outlives the classes it found. Loading or removing them in a running image left it answering its old catalog until someone reset it by hand, so it notices here instead.

	It takes in what appeared and drops what vanished, rather than rebuilding. Rebuilding would undo every hand edit the catalog has had: an entry added by hand, and an entry deliberately removed, which would come back the next time any class was loaded."

	| discovered appeared vanished |
	discoversClasses ifFalse: [ ^ self ].
	discovered := self autoRegisteringClasses.
	discovered = discoveredClasses ifTrue: [ ^ self ].
	vanished := discoveredClasses difference: discovered.
	appeared := discovered difference: discoveredClasses.
	discoveredClasses := discovered.
	(entries keys select: [ :each | vanished includes: (entries at: each) class ]) do: [ :each | entries removeKey: each ].
	((appeared collect: [ :each | self newEntryFrom: each ]) asSortedCollection: [ :left :right |
		 (self keyFor: left) <= (self keyFor: right) ]) do: [ :entry |
			| key |
			key := self keyFor: entry.
			(entries includesKey: key) ifFalse: [ entries at: key put: entry ] ].
	self noteChanged
]

{ #category : 'entries' }
MCPRegistry >> registeredClass [
	"Answer the abstract class whose concrete subclasses this registry discovers."

	^ self subclassResponsibility
]

{ #category : 'entries' }
MCPRegistry >> removeAll [

	discoversClasses := false.
	discoveredClasses := nil.
	entries := OrderedDictionary new.
	self noteChanged
]

{ #category : 'entries' }
MCPRegistry >> removeKey: aKey [

	self entriesByKey
		removeKey: aKey asString
		ifAbsent: [ ^ self ].
	self noteChanged
]

{ #category : 'entries' }
MCPRegistry >> reset [

	discoversClasses := true.
	discoveredClasses := self autoRegisteringClasses.
	entries := OrderedDictionary new.
	self defaultEntries do: [ :each | entries at: (self keyFor: each) put: each ].
	self noteChanged
]
