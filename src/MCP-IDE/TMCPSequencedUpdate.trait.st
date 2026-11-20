"
Applies the several updates one call can ask for of a tool, in order, stopping at the first that fails.

A user answers applyUpdate:of: for one update, updateActionOf: for the action an update names, and updateSubjectDescriptionFor: for the summary of several.

Unlike a batch over independent targets, these updates all land on one target and the later ones build on the earlier, so a failure stops the rest rather than carrying on.
"
Trait {
	#name : 'TMCPSequencedUpdate',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'private - updating' }
TMCPSequencedUpdate >> applyUpdate: update of: request [
	"Apply one update and answer its tool result, which is an error result when it failed."

	^ self explicitRequirement
]

{ #category : 'updating' }
TMCPSequencedUpdate >> applyUpdates: updates of: request [
	"Apply the updates in order, stopping at the first that fails. They all land on one target and the later ones build on the earlier, so carrying on would apply half a change nobody asked for."

	| applied |
	applied := OrderedCollection new.
	updates doWithIndex: [ :update :index |
			| result |
			result := self applyUpdate: update of: request.
			result isError ifTrue: [
					^ self
						  resultForFailure: result
						  of: (self updateActionOf: update)
						  applied: (applied collect: [ :each | each key ] as: Array)
						  skipped: ((updates allButFirst: index) collect: [ :each | self updateActionOf: each ]) ].
			applied add: (self updateActionOf: update) -> result ].
	^ self resultForUpdates: applied of: request
]

{ #category : 'updating' }
TMCPSequencedUpdate >> resultForFailure: errorResult of: action applied: appliedActions skipped: skippedActions [
	"A single change fails as it always did. When it was one of several, say which had already landed and which were never attempted, because the target is left part-way."

	| details summary |
	(appliedActions isEmpty and: [ skippedActions isEmpty ]) ifTrue: [ ^ errorResult ].
	details := (errorResult structuredContent at: #error ifAbsent: [ Dictionary new ]) copy.
	details
		at: #failedUpdate put: action;
		at: #appliedUpdates put: appliedActions asArray;
		at: #skippedUpdates put: skippedActions asArray.
	summary := String streamContents: [ :stream |
			           stream << (errorResult structuredContent at: #summary ifAbsent: [ '' ]).
			           stream << ' Update ' << action << ' failed'.
			           appliedActions ifNotEmpty: [
					           stream << ', after applying '.
					           appliedActions do: [ :each | stream << each ] separatedBy: [ stream << ', ' ] ].
			           skippedActions ifNotEmpty: [
					           stream << '; not attempted: '.
					           skippedActions do: [ :each | stream << each ] separatedBy: [ stream << ', ' ] ].
			           stream << '.' ].
	^ self errorResultText: summary details: details
]

{ #category : 'updating' }
TMCPSequencedUpdate >> resultForUpdates: applied of: request [
	"One update answers exactly what it answers alone. Several say how many were applied, then what each one answered alone, a line each in the order applied; their data stays under updates."

	| updates warnings |
	applied size = 1 ifTrue: [ ^ applied first value ].
	warnings := OrderedCollection new.
	updates := applied collect: [ :each |
			           warnings addAll: (self warningsOfResult: each value).
			           (each value structuredContent at: #data ifAbsent: [ Dictionary new ]) copy
				           at: #action put: each key;
				           yourself ].
	^ self
		  successResultText: (String streamContents: [ :stream |
					   stream
						   nextPutAll: 'Applied ';
						   print: applied size;
						   nextPutAll: ' updates to ';
						   nextPutAll: (self updateSubjectDescriptionFor: request);
						   nextPut: $:.
					   applied do: [ :each |
							   stream
								   nextPut: Character lf;
								   nextPutAll: (each value structuredContent at: #summary ifAbsent: [ '' ]) ] ])
		  data: { (#updates -> updates asArray) } asDictionary
		  warnings: warnings asArray
]

{ #category : 'private - updating' }
TMCPSequencedUpdate >> updateActionOf: update [
	"The name of the action an update performs, as the answer reports it."

	^ self explicitRequirement
]

{ #category : 'private - updating' }
TMCPSequencedUpdate >> updateSubjectDescriptionFor: request [
	"What the summary of several updates calls their target."

	^ self explicitRequirement
]
