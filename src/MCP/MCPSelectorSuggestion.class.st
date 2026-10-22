"
Answers the selectors a class understands that most resemble one it does not, so a failed guess reports what was probably meant.

Prefix matches come first: a wrong guess usually keeps the prefix of the right selector, which no spelling distance recovers. Pharo's own corrector fills the remaining places, gated on how closely it actually matched, because it answers its best candidates whatever their distance.
"
Class {
	#name : 'MCPSelectorSuggestion',
	#superclass : 'Object',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
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

{ #category : 'accessing' }
MCPSelectorSuggestion class >> selectorsLike: aSelector understoodBy: aClass [

	| missed selectors suggestions |
	missed := aSelector asString.
	selectors := (aClass allSelectors collect: [ :each | each asString ]) asSet.
	suggestions := (self prefixMatchesIn: selectors for: missed) asOrderedCollection.
	suggestions size < self suggestionLimit ifTrue: [
		(self correctionsIn: selectors for: missed) do: [ :each |
			(suggestions size < self suggestionLimit and: [ (suggestions includes: each) not ]) ifTrue: [
				suggestions add: each ] ] ].
	^ suggestions asArray
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
