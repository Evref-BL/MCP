"
Answers the selectors a class understands that most resemble one it does not, so a failed guess reports what was probably meant.

Prefix matches come first: a wrong guess usually keeps the prefix of the right selector, which no spelling distance recovers. Pharo's own corrector fills the remaining places, gated on how closely it actually matched, because it answers its best candidates whatever their distance.
"
Class {
	#name : 'MCPSelectorSuggestion',
	#superclass : 'Object',
	#category : 'MCP-Utilities',
	#package : 'MCP',
	#tag : 'Utilities'
}

{ #category : 'accessing' }
MCPSelectorSuggestion class >> correctionsIn: selectors for: aSelectorString [
	"Pharo's corrector answers its best candidates whatever their distance, so a selector resembling nothing still gets three. alike: scores the resemblance, and half the missed selector's length separates a correction from noise: frobnicate scores 4 against fromSton:, where prntString scores 11 against printString."

	^ (aSelectorString correctAgainst: selectors) select: [ :each | (aSelectorString alike: each) * 2 >= aSelectorString size ]
]

{ #category : 'private' }
MCPSelectorSuggestion class >> minimumSharedPrefixSize [

	^ 4
]

{ #category : 'suggesting' }
MCPSelectorSuggestion class >> namesLike: aName among: names [
	"A name the caller got slightly wrong is usually one that starts the same way; a name they
	misspelled is usually one letter off."

	| missed candidates suggestions |
	missed := aName asString.
	candidates := (names collect: [ :each | each asString ]) asSet.
	suggestions := (self prefixMatchesIn: candidates for: missed) asOrderedCollection.
	suggestions size < self suggestionLimit ifTrue: [
		(self correctionsIn: candidates for: missed) do: [ :each |
			(suggestions size < self suggestionLimit and: [ (suggestions includes: each) not ]) ifTrue: [
				suggestions add: each ] ] ].
	^ suggestions asArray
]

{ #category : 'accessing' }
MCPSelectorSuggestion class >> prefixMatchesIn: selectors for: aSelectorString [
	"The longest shared prefix wins, then the shortest selector: diffToReferenceWorkingCopy answers diffToReferenceCommit before diffTo:."

	| scored |
	scored := OrderedCollection new.
	selectors do: [ :each |
		| shared |
		shared := self sharedPrefixSizeOf: each and: aSelectorString.
		shared >= self minimumSharedPrefixSize ifTrue: [ scored add: shared -> each ] ].
	scored sort: [ :left :right |
		left key = right key
			ifTrue: [ left value size <= right value size ]
			ifFalse: [ left key > right key ] ].
	^ (scored first: (self suggestionLimit min: scored size)) collect: [ :each | each value ]
]

{ #category : 'suggesting' }
MCPSelectorSuggestion class >> selectorsLike: aSelector understoodBy: aClass [

	^ self namesLike: aSelector among: aClass allSelectors
]

{ #category : 'private' }
MCPSelectorSuggestion class >> sharedPrefixSizeOf: aString and: anotherString [

	| shared |
	shared := 0.
	[ shared < (aString size min: anotherString size) and: [ (aString at: shared + 1) == (anotherString at: shared + 1) ] ]
		whileTrue: [ shared := shared + 1 ].
	^ shared
]

{ #category : 'private' }
MCPSelectorSuggestion class >> suggestionLimit [

	^ 3
]
