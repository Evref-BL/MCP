"
Builds bounded suggestions for unresolved class or package names.

It scores nearby names and limits repeated suggestions from the same package or naming group so query warnings stay concise.
"
Class {
	#name : 'MCPScopeNameSuggester',
	#superclass : 'Object',
	#category : 'MCP-Queries',
	#package : 'MCP',
	#tag : 'Queries'
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
MCPScopeNameSuggester class >> classSuggestionCandidates [

	| candidates |
	candidates := OrderedCollection new.
	Smalltalk globals allClasses do: [ :eachClass |
		candidates add: {
				(#name -> eachClass name asString).
				(#bucket -> eachClass package name asString) } asDictionary ].
	^ candidates asArray
]

{ #category : 'suggesting' }
MCPScopeNameSuggester class >> classSuggestionsFor: aName [

	^ self
		  suggestionsFor: aName
		  candidates: self classSuggestionCandidates
		  max: self defaultLimit
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

{ #category : 'warnings' }
MCPScopeNameSuggester class >> missingClassWarningFor: className scope: scopeName [

	^ self
		  missingNameWarningForKind: 'Class'
		  name: className
		  scope: scopeName
		  suggestions: (self classSuggestionsFor: className)
]

{ #category : 'warnings' }
MCPScopeNameSuggester class >> missingNameWarningForKind: kind name: missingName scope: scopeName suggestions: suggestions [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: kind;
			  space;
			  nextPutAll: missingName asString;
			  nextPutAll: ' does not exist in ';
			  nextPutAll: scopeName asString;
			  nextPutAll: ' scope.'.
		  suggestions ifNotEmpty: [
			  stream nextPutAll: ' Did you mean: '.
			  suggestions
				  do: [ :each | stream nextPutAll: each ]
				  separatedBy: [ stream nextPutAll: ', ' ].
			  stream nextPut: $. ] ]
]

{ #category : 'warnings' }
MCPScopeNameSuggester class >> missingPackageWarningFor: packageName scope: scopeName [

	^ self
		  missingNameWarningForKind: 'Package'
		  name: packageName
		  scope: scopeName
		  suggestions: (self packageSuggestionsFor: packageName)
]

{ #category : 'suggesting' }
MCPScopeNameSuggester class >> packageSuggestionCandidates [

	^ PackageOrganizer default packages collect: [ :eachPackage |
		  {
			  (#name -> eachPackage name asString).
			  (#bucket -> eachPackage name asString) } asDictionary ]
]

{ #category : 'suggesting' }
MCPScopeNameSuggester class >> packageSuggestionsFor: aName [

	^ self
		  suggestionsFor: aName
		  candidates: self packageSuggestionCandidates
		  max: self defaultLimit
]

{ #category : 'suggesting' }
MCPScopeNameSuggester class >> scoreForRequested: requestedName candidate: candidateName [

	| candidate requested |
	requested := requestedName asString asLowercase.
	candidate := candidateName asString asLowercase.
	requested = candidate ifTrue: [ ^ 0 ].
	(candidate beginsWith: requested) ifTrue: [
		^ 10 + (candidate size - requested size) ].
	(requested beginsWith: candidate) ifTrue: [
		^ 20 + (requested size - candidate size) ].
	(candidate includesSubstring: requested) ifTrue: [
		^ 30 + (candidate size - requested size) ].
	(requested includesSubstring: candidate) ifTrue: [
		^ 40 + (requested size - candidate size) ].
	^ 100 + (self editDistanceBetween: requested and: candidate)
]

{ #category : 'suggesting' }
MCPScopeNameSuggester class >> suggestionsFor: requestedName candidates: candidates max: maxCount [

	| bucketCounts chosen chosenNames filtered scored sorted |
	filtered := candidates select: [ :eachCandidate |
		            self
			            candidate: eachCandidate
			            matchesRequested: requestedName ].
	filtered isEmpty ifTrue: [ ^ #(  ) ].
	scored := filtered collect: [ :eachCandidate |
		          eachCandidate copy
			          at: #score put: (self
					           scoreForRequested: requestedName
					           candidate: (eachCandidate at: #name));
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
			(count < 2 and: [ (chosenNames includes: candidateName) not ])
				ifTrue: [
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
