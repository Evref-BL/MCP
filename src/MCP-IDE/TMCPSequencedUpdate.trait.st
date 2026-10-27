"
Applies the several actions one update request can ask for, in a fixed order, stopping at the first that fails.

A user answers planForAction: and executePlan: for its own kind of target, actionApplicationOrder for the order they must run in, and updateSubjectDescription for the summary.

Unlike a batch over independent targets, these actions all land on one target and the later ones build on the earlier, so a failure stops the rest rather than carrying on.
"
Trait {
	#name : 'TMCPSequencedUpdate',
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'requirements' }
TMCPSequencedUpdate >> actionApplicationOrder [
	"The actions this kind of update can ask for, in the order they must be applied."

	^ self explicitRequirement
]

{ #category : 'private - results' }
TMCPSequencedUpdate >> actionsInApplicationOrder: plans [
	"Order by what each plan does, keeping plans that do the same thing in the order they were asked for."

	| order |
	order := self actionApplicationOrder.
	^ ((plans asArray withIndexCollect: [ :plan :index |
			    {
				    (order indexOf: plan updateAction).
				    index.
				    plan } ]) sorted: [ :left :right |
			   left first = right first
				   ifTrue: [ (left at: 2) <= (right at: 2) ]
				   ifFalse: [ left first < right first ] ]) collect: [ :each | each last ]
]

{ #category : 'private - results' }
TMCPSequencedUpdate >> dataOfResult: aResult [

	^ aResult structuredContent at: #data ifAbsent: [ Dictionary new ]
]

{ #category : 'executing' }
TMCPSequencedUpdate >> executeActions: plans [
	"Apply the plans in order, stopping at the first that fails. Unlike a batch over independent targets, these all land on one target and the later ones build on the earlier, so carrying on would apply half a change nobody asked for."

	| applied |
	applied := OrderedCollection new.
	plans doWithIndex: [ :plan :index |
			| result |
			result := self executePlan: plan.
			result isError ifTrue: [
					^ self
						  resultForFailure: result
						  at: plan
						  applied: (applied collect: [ :each | each key ]) asArray
						  skipped: ((plans copyFrom: index + 1 to: plans size) collect: [ :each | each updateAction ]) ].
			applied add: plan updateAction -> result ].
	^ self resultForAppliedUpdates: applied
]

{ #category : 'requirements' }
TMCPSequencedUpdate >> executePlan: plan [
	"Carry out one planned action."

	^ self explicitRequirement
]

{ #category : 'private - results' }
TMCPSequencedUpdate >> resultForAppliedUpdates: applied [
	"One action answers exactly what it answered when it had a tool of its own; several are reported together."

	| warnings updates |
	applied size = 1 ifTrue: [ ^ applied first value ].
	warnings := OrderedCollection new.
	updates := applied collect: [ :each |
			           warnings addAll: (self warningsOfResult: each value).
			           (self dataOfResult: each value) copy
				           at: #action put: each key;
				           yourself ].
	^ self tool
		  successResultText: (String streamContents: [ :stream |
					   stream << 'Applied ' << applied size asString << ' updates to ' << self updateSubjectDescription << ': '.
					   applied do: [ :each | stream << each key ] separatedBy: [ stream << ', ' ].
					   stream << '.' ])
		  data: { (#updates -> updates asArray) } asDictionary
		  warnings: warnings asArray
]

{ #category : 'private - results' }
TMCPSequencedUpdate >> resultForFailure: errorResult at: plan applied: appliedActions skipped: skippedActions [
	"A single change fails as it always did. When it was one of several, say which had already landed and which were never attempted, because the target is left part-way."

	| action details summary |
	(appliedActions isEmpty and: [ skippedActions isEmpty ]) ifTrue: [ ^ errorResult ].
	action := plan updateAction.
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
	^ self tool errorResultText: summary details: details
]

{ #category : 'requirements' }
TMCPSequencedUpdate >> updateSubjectDescription [
	"What the summary calls the thing being updated, such as 'class Foo'."

	^ self explicitRequirement
]

{ #category : 'private - results' }
TMCPSequencedUpdate >> warningsOfResult: aResult [

	^ aResult structuredContent at: #warnings ifAbsent: [ #(  ) ]
]
