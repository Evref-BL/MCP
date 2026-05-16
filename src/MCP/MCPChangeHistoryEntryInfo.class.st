"
Structured metadata for one entry in image change history.
"
Class {
	#name : 'MCPChangeHistoryEntryInfo',
	#superclass : 'Object',
	#instVars : [
		'index',
		'reference',
		'globalName',
		'localName',
		'eventClassName',
		'summary',
		'isCodeChange',
		'time',
		'triggerReference',
		'packageName',
		'behaviorName',
		'classSide',
		'selector',
		'protocol'
	],
	#category : 'MCP-DTOs',
	#package : 'MCP',
	#tag : 'DTOs'
}

{ #category : 'instance creation' }
MCPChangeHistoryEntryInfo class >> fromEntry: anEntry index: anInteger log: aLog [

	^ self new
		  initializeFromEntry: anEntry index: anInteger log: aLog;
		  yourself
]

{ #category : 'converting' }
MCPChangeHistoryEntryInfo >> asDictionary [

	^ {
		  (#index -> index).
		  (#reference -> reference).
		  (#globalName -> globalName).
		  (#localName -> localName).
		  (#eventClassName -> eventClassName).
		  (#summary -> summary).
		  (#isCodeChange -> isCodeChange).
		  (#time -> time).
		  (#triggerReference -> triggerReference).
		  (#packageName -> packageName).
		  (#behaviorName -> behaviorName).
		  (#classSide -> classSide).
		  (#selector -> selector).
		  (#protocol -> protocol) } asDictionary
]

{ #category : 'private' }
MCPChangeHistoryEntryInfo >> classSideFromBehaviorName: aString [

	aString ifNil: [ ^ nil ].
	^ aString endsWith: ' class'
]

{ #category : 'private' }
MCPChangeHistoryEntryInfo >> globalNameFromReference: aReference [

	^ self stringValueFrom: aReference selector: #globalName
]

{ #category : 'initialization' }
MCPChangeHistoryEntryInfo >> initializeFromEntry: anEntry index: anInteger log: aLog [

	| event referenceObject |
	index := anInteger.
	event := [ anEntry content ]
		         on: Error
		         do: [ :error | nil ].
	referenceObject := [ aLog referenceTo: anEntry ]
		                   on: Error
		                   do: [ :error | nil ].
	reference := self stringFromReference: referenceObject.
	globalName := self globalNameFromReference: referenceObject.
	localName := self localNameFromReference: referenceObject.
	eventClassName := event ifNotNil: [ event class name asString ].
	summary := event ifNotNil: [ event printString ].
	isCodeChange := event notNil and: [
		                (event respondsTo: #isCodeChange) and: [
			                event isCodeChange ] ].
	time := [
	        (aLog timeAt: anEntry ifAbsent: [ nil ])
		        ifNil: [ nil ]
		        ifNotNil: [ :value | value asString ] ]
		        on: Error
		        do: [ :error | nil ].
	triggerReference := [
	                    aLog
		                    triggererReferenceOf: anEntry
		                    ifPresent: [ :aReference |
		                    self stringFromReference: aReference ]
		                    ifAbsent: [ nil ] ]
		                    on: Error
		                    do: [ :error | nil ].
	packageName := self
		               stringValueFrom: event
		               selectors: #( affectedPackageName packageName ).
	behaviorName := self
		                stringValueFrom: event
		                selectors:
		                #( behaviorAffectedName behaviorName className ).
	classSide := self classSideFromBehaviorName: behaviorName.
	selector := self
		            stringValueFrom: event
		            selectors: #( methodAffectedSelector
		               selector ).
	protocol := self
		            stringValueFrom: event
		            selectors: #( methodAffectedProtocol
		               protocol ).
	^ self
]

{ #category : 'private' }
MCPChangeHistoryEntryInfo >> localNameFromReference: aReference [

	^ self stringValueFrom: aReference selector: #localName
]

{ #category : 'private' }
MCPChangeHistoryEntryInfo >> stringFromReference: aReference [

	aReference ifNil: [ ^ nil ].
	(aReference respondsTo: #shortName) ifTrue: [
		^ aReference shortName asString ].
	^ aReference asString
]

{ #category : 'private' }
MCPChangeHistoryEntryInfo >> stringValueFrom: anObject selector: aSelector [

	(anObject notNil and: [ anObject respondsTo: aSelector ]) ifFalse: [
		^ nil ].
	^ [
	  (anObject perform: aSelector)
		  ifNil: [ nil ]
		  ifNotNil: [ :value | value asString ] ]
		  on: Error
		  do: [ :error | nil ]
]

{ #category : 'private' }
MCPChangeHistoryEntryInfo >> stringValueFrom: anObject selectors: selectorCollection [

	| value |
	selectorCollection do: [ :each |
		value := self stringValueFrom: anObject selector: each.
		value ifNotNil: [ ^ value ] ].
	^ nil
]
