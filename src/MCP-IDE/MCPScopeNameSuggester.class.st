"
Builds bounded suggestions for unresolved class or package names.

It scores nearby names and limits repeated suggestions from the same package or naming group so query warnings stay concise.
"
Class {
	#name : 'MCPScopeNameSuggester',
	#superclass : 'Object',
	#category : 'MCP-IDE-Utilities',
	#package : 'MCP-IDE',
	#tag : 'Utilities'
}

{ #category : 'suggesting' }
MCPScopeNameSuggester class >> candidate: candidateDictionary matchesRequested: requestedName [

	| candidate prefixSize requested |
	requested := requestedName asString asLowercase.
	requested isEmpty ifTrue: [ ^ true ].
	candidate := (candidateDictionary at: #name) asString asLowercase.
	candidate = requested ifTrue: [ ^ true ].
	(candidate beginsWith: requested) ifTrue: [ ^ true ].
	(requested beginsWith: candidate) ifTrue: [ ^ true ].
	(candidate includesSubstring: requested) ifTrue: [ ^ true ].
	(requested includesSubstring: candidate) ifTrue: [ ^ true ].
	prefixSize := requested size min: 3.
	^ candidate beginsWith: (requested first: prefixSize)
]

{ #category : 'suggesting' }
MCPScopeNameSuggester class >> candidatesAmong: someBehaviors [
	"Each behaviour as a name to rank, in the bucket of its package, so that one package cannot fill the suggestions."

	^ someBehaviors asArray collect: [ :each |
			  {
				  (#name -> each name asString).
				  (#bucket -> (each package ifNil: [ '' ] ifNotNil: [ :package | package name asString ])) } asDictionary ]
]

{ #category : 'defaults' }
MCPScopeNameSuggester class >> defaultLimit [

	^ 5
]

{ #category : 'suggesting' }
MCPScopeNameSuggester class >> editDistanceBetween: leftString and: rightString [

	| current previous |
	leftString isEmpty ifTrue: [ ^ rightString size ].
	rightString isEmpty ifTrue: [ ^ leftString size ].
	previous := (0 to: rightString size) asArray.
	1 to: leftString size do: [ :leftIndex |
			current := Array new: rightString size + 1.
			current at: 1 put: leftIndex.
			1 to: rightString size do: [ :rightIndex |
					| cost delete insert replace |
					cost := (leftString at: leftIndex) = (rightString at: rightIndex)
						        ifTrue: [ 0 ]
						        ifFalse: [ 1 ].
					delete := (previous at: rightIndex + 1) + 1.
					insert := (current at: rightIndex) + 1.
					replace := (previous at: rightIndex) + cost.
					current at: rightIndex + 1 put: ((delete min: insert) min: replace) ].
			previous := current ].
	^ previous last
]

{ #category : 'suggesting' }
MCPScopeNameSuggester class >> packageSuggestionCandidates [

	^ self packageOrganizer packages collect: [ :eachPackage |
			  {
				  (#name -> eachPackage name asString).
				  (#bucket -> eachPackage name asString) } asDictionary ]
]

{ #category : 'suggesting' }
MCPScopeNameSuggester class >> packageSuggestionsFor: aName [

	^ self suggestionsFor: aName candidates: self packageSuggestionCandidates max: self defaultLimit
]

{ #category : 'suggesting' }
MCPScopeNameSuggester class >> scoreForRequested: requestedName candidate: candidateName [

	| candidate requested |
	requested := requestedName asString asLowercase.
	candidate := candidateName asString asLowercase.
	requested = candidate ifTrue: [ ^ 0 ].
	(candidate beginsWith: requested) ifTrue: [ ^ 10 + (candidate size - requested size) ].
	(requested beginsWith: candidate) ifTrue: [ ^ 20 + (requested size - candidate size) ].
	(candidate includesSubstring: requested) ifTrue: [ ^ 30 + (candidate size - requested size) ].
	(requested includesSubstring: candidate) ifTrue: [ ^ 40 + (requested size - candidate size) ].
	^ 100 + (self editDistanceBetween: requested and: candidate)
]

{ #category : 'suggesting' }
MCPScopeNameSuggester class >> suggestionsFor: aName among: someBehaviors [
	"The names of someBehaviors nearest aName, ranked by name and package. The caller decides which behaviours the name could have meant."

	^ self suggestionsFor: aName candidates: (self candidatesAmong: someBehaviors) max: self defaultLimit
]

{ #category : 'suggesting' }
MCPScopeNameSuggester class >> suggestionsFor: requestedName candidates: candidates max: maxCount [

	| bucketCounts chosen chosenNames filtered scored sorted |
	filtered := candidates select: [ :eachCandidate | self candidate: eachCandidate matchesRequested: requestedName ].
	filtered isEmpty ifTrue: [ ^ #(  ) ].
	scored := filtered collect: [ :eachCandidate |
			          eachCandidate copy
				          at: #score put: (self scoreForRequested: requestedName candidate: (eachCandidate at: #name));
				          yourself ].
	sorted := scored asSortedCollection: [ :left :right |
			          (left at: #score) = (right at: #score)
				          ifTrue: [ (left at: #name) <= (right at: #name) ]
				          ifFalse: [ (left at: #score) < (right at: #score) ] ].
	chosen := OrderedCollection new.
	chosenNames := Set new.
	bucketCounts := Dictionary new.
	sorted do: [ :eachCandidate |
			chosen size < maxCount ifTrue: [
					| bucket count candidateName |
					candidateName := eachCandidate at: #name.
					bucket := eachCandidate at: #bucket ifAbsent: [ '' ].
					count := bucketCounts at: bucket ifAbsent: [ 0 ].
					(count < 2 and: [ (chosenNames includes: candidateName) not ]) ifTrue: [
							chosen add: candidateName.
							chosenNames add: candidateName.
							bucketCounts at: bucket put: count + 1 ] ] ].
	chosen size < maxCount ifTrue: [
			sorted do: [ :eachCandidate |
					chosen size < maxCount ifTrue: [
							| candidateName |
							candidateName := eachCandidate at: #name.
							(chosenNames includes: candidateName) ifFalse: [
									chosen add: candidateName.
									chosenNames add: candidateName ] ] ] ].
	^ chosen asArray
]
