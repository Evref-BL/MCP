"
Concrete history_lost_change_restore tool. It installs the lost changes history_lost_change_list lists, all of them or those the call names by element, in an order where each finds what it needs, and says what it restored and what it could not, with why. A change the image has made since its save is refused unless forced, as restoring would discard it.
"
Class {
	#name : 'MCPToolRestoreLostChanges',
	#superclass : 'MCPToolLostChanges',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolRestoreLostChanges class >> toolName [

	^ 'history_lost_change_restore'
]

{ #category : 'private - execution' }
MCPToolRestoreLostChanges >> add: anElementName toUnknownOrHeldIn: aLostChangeQuery into: data [

	(aLostChangeQuery changes anySatisfy: [ :each | each isNamedBy: anElementName ])
		ifTrue: [ (data at: #alreadyInImage) add: anElementName ]
		ifFalse: [
				(data at: #notRestored) add: {
						(#element -> anElementName).
						(#reason -> 'No session since the image was last saved changed it.') } asDictionary ]
]

{ #category : 'metadata' }
MCPToolRestoreLostChanges >> buildInputSchema [

	^ MCPStructureInputSchema
		  properties: {
				  (self
					   stringOrArraySchemaNamed: 'elements'
					   description:
					   'What to restore, as history_lost_change_list names it: Foo>>bar or Foo class>>bar for a method, Foo for its class definition and comment. Defaults to every lost change.'
					   itemDescription: 'Element name.').
				  (self
					   booleanSchemaPropertyNamed: 'force'
					   description: 'Restore a change even where the image changed the element since its save, discarding that change.'
					   default: false) }
		  required: #(  )
]

{ #category : 'private - execution' }
MCPToolRestoreLostChanges >> changesNamed: someElementNames among: someLostChanges of: aLostChangeQuery into: data [
	"The lost changes to the elements named. A name no lost change has is not restored, unless the image already holds its change, which the answer says apart."

	| chosen |
	chosen := OrderedCollection new.
	someElementNames do: [ :name |
			(someLostChanges select: [ :each | each isNamedBy: name ])
				ifEmpty: [ self add: name toUnknownOrHeldIn: aLostChangeQuery into: data ]
				ifNotEmpty: [ :changes | chosen addAll: changes ] ].
	^ chosen
]

{ #category : 'private - execution' }
MCPToolRestoreLostChanges >> changesToRestoreFor: request from: aLostChangeQuery into: data [
	"Every lost change, or those the request names. A change the image made since its save is refused unless the request forces it, since restoring discards it."

	| chosen lostChanges |
	lostChanges := aLostChangeQuery lostChanges.
	chosen := (self elementNamesOf: request) ifEmpty: [ lostChanges ] ifNotEmpty: [ :names |
			          self
				          changesNamed: names
				          among: lostChanges
				          of: aLostChangeQuery
				          into: data ].
	(request booleanArgumentNamed: 'force') ifTrue: [ ^ chosen ].
	chosen
		select: [ :each | each isChangedSinceSave ]
		thenDo: [ :each | (data at: #notRestored) add: (self rowFor: each because: self forceableConflictReason) ].
	^ chosen reject: [ :each | each isChangedSinceSave ]
]

{ #category : 'private - execution' }
MCPToolRestoreLostChanges >> dataFor: request from: aLostChangeQuery [
	"Restore the changes the request chooses, in an order where each finds what it needs, and say what became of each. A call that restores none of them fails, saying why."

	| data |
	data := Dictionary new.
	data at: #restored put: OrderedCollection new.
	data at: #notRestored put: OrderedCollection new.
	data at: #alreadyInImage put: OrderedCollection new.
	(self inRestoreOrder: (self changesToRestoreFor: request from: aLostChangeQuery into: data)) do: [ :each |
		self restore: each into: data ].
	((data at: #restored) isEmpty and: [ (data at: #notRestored) isNotEmpty ]) ifTrue: [ self signalNothingRestored: data ].
	^ data collect: [ :each | each asArray ]
]

{ #category : 'metadata' }
MCPToolRestoreLostChanges >> description [

	^ 'Restore what history_lost_change_list lists, all of it or the elements named, installing each source as it was recorded, and say what was restored and what could not be. A change the image has made since its save is refused unless forced.'
]

{ #category : 'private - execution' }
MCPToolRestoreLostChanges >> elementNamesOf: request [
	"The elements the request names, each once, written as the list writes them."

	| names |
	names := OrderedCollection new.
	(request stringCollectionArgumentNamed: 'elements') do: [ :each | names addIfNotPresent: (self normalizedElementName: each) ].
	^ names
]

{ #category : 'private - results' }
MCPToolRestoreLostChanges >> forceableConflictReason [

	^ 'The image changed it since it was saved: force restores it anyway, discarding that change.'
]

{ #category : 'private - execution' }
MCPToolRestoreLostChanges >> inRestoreOrder: someLostChanges [
	"Definitions first, a superclass before its subclasses, then comments, methods, and removals last."

	| classChangesByName |
	classChangesByName := Dictionary new.
	someLostChanges do: [ :each | each addDefinitionTo: classChangesByName ].
	^ someLostChanges asArray sorted: [ :first :second | first shouldRestoreBefore: second among: classChangesByName ]
]

{ #category : 'private - results' }
MCPToolRestoreLostChanges >> keysStatedInSummary [
	"The summary names what the image already held."

	^ #( alreadyInImage )
]

{ #category : 'private - execution' }
MCPToolRestoreLostChanges >> normalizedElementName: aString [
	"Foo >> bar and Foo>>#bar name the method the list writes Foo>>bar."

	| separator |
	separator := aString indexOfSubCollection: '>>'.
	separator = 0 ifTrue: [ ^ aString trimBoth ].
	^ String streamContents: [ :stream |
		  stream << (aString first: separator - 1) trimBoth << '>>' << ((aString allButFirst: separator + 1) trimBoth copyWithout: $#) ]
]

{ #category : 'private - execution' }
MCPToolRestoreLostChanges >> reasonNotRestoring: aLostChange [
	"Restore aLostChange and answer nil, or answer why it is not restored: it cannot be installed, or the image still lacks it once installed."

	aLostChange restoreIfImpossible: [ :impossibility | ^ impossibility ].
	aLostChange isInImage ifTrue: [ ^ nil ].
	^ 'The image still differs from it once restored.'
]

{ #category : 'private - execution' }
MCPToolRestoreLostChanges >> restore: aLostChange into: data [
	"A change that fails is not restored and says why, and the others still are: each one restored is that much less to recover by hand."

	| reason |
	reason := [ self reasonNotRestoring: aLostChange ]
		          on: Error
		          do: [ :error | error messageText ].
	reason
		ifNil: [ (data at: #restored) add: (self rowFor: aLostChange because: nil) ]
		ifNotNil: [ (data at: #notRestored) add: (self rowFor: aLostChange because: reason) ]
]

{ #category : 'private - results' }
MCPToolRestoreLostChanges >> rowFor: aLostChange because: aReasonOrNil [
	"A change as the answer names it: its element and what it did, and why it was not restored when it was not."

	| row |
	row := Dictionary new.
	row at: #element put: aLostChange element.
	row at: #change put: aLostChange changeDescription.
	aReasonOrNil ifNotNil: [ row at: #reason put: aReasonOrNil ].
	^ row
]

{ #category : 'private - execution' }
MCPToolRestoreLostChanges >> signalNothingRestored: data [
	"Each reason on its own line, since the summary is all an error shows, then what the image already held."

	MCPCommandError
		signalErrorCode: #LostChangesNotRestored
		message: (String streamContents: [ :stream |
					 stream << 'Restored no lost change.'.
					 (data at: #notRestored) do: [ :each | stream lf << (each at: #element) << ': ' << (each at: #reason) ].
					 (data at: #alreadyInImage) ifNotEmpty: [ :names |
						 stream lf << 'The image already holds ' << (MCPScopeQuery listPhraseFor: names) << '.' ] ])
		details: { (#notRestored -> (data at: #notRestored) asArray) } asDictionary
]

{ #category : 'private - results' }
MCPToolRestoreLostChanges >> successSummaryForData: data [
	"'Restored 3 of 4 lost changes; 1 could not be.' A call with nothing to restore says why: nothing is lost, or the image already holds what it named."

	| restoredCount totalCount |
	restoredCount := (data at: #restored) size.
	totalCount := restoredCount + (data at: #notRestored) size.
	totalCount = 0 ifTrue: [
			^ (data at: #alreadyInImage)
				  ifEmpty: [ 'Nothing to restore: the image holds every change made since it was last saved.' ]
				  ifNotEmpty: [ :names |
						  String streamContents: [ :stream |
							  stream << 'Nothing to restore: the image already holds ' << (MCPScopeQuery listPhraseFor: names) << '.' ] ] ].
	^ String streamContents: [ :stream |
			  stream << 'Restored '.
			  restoredCount < totalCount ifTrue: [
					  stream
						  print: restoredCount;
						  << ' of ' ].
			  stream << (self textForCount: totalCount noun: 'lost change').
			  restoredCount < totalCount ifTrue: [ stream << '; ' << (totalCount - restoredCount) printString << ' could not be' ].
			  stream << '.'.
			  (data at: #alreadyInImage) ifNotEmpty: [ :names |
				  stream << ' The image already held ' << (MCPScopeQuery listPhraseFor: names) << '.' ] ]
]

{ #category : 'metadata' }
MCPToolRestoreLostChanges >> title [

	^ 'Restore Lost Changes'
]
