"
Puts a method back as the image's change history recorded it. Without a version, as it was before its last change: a removed method comes back with its protocol, a modified one gets its previous source, and one the change added is removed. With a version, as that version of method_version_list left it.

The recorded source is compiled as it is, in its protocol, without the formatting method_compile applies, and the answer shows it. The compile is itself a change the history records, so a restore is undone the same way. Nothing asks for confirmation: the version list is the preview, and a call acts.
"
Class {
	#name : 'MCPToolRestoreMethod',
	#superclass : 'MCPTool',
	#traits : 'TMCPMethodTool',
	#classTraits : 'TMCPMethodTool classTrait',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolRestoreMethod class >> groupName [

	^ self methodsGroupName
]

{ #category : 'metadata' }
MCPToolRestoreMethod class >> toolName [

	^ 'method_restore'
]

{ #category : 'metadata' }
MCPToolRestoreMethod >> additionalKeywords [
	"What a caller looking for a lost or broken method searches for."

	^ #( 'history' 'version' 'previous' 'removed' 'revert' 'undo' 'recover' )
]

{ #category : 'metadata' }
MCPToolRestoreMethod >> batchArgumentName [

	^ 'selector'
]

{ #category : 'metadata' }
MCPToolRestoreMethod >> batchSummaryNoun [

	^ 'methods'
]

{ #category : 'metadata' }
MCPToolRestoreMethod >> batchSummaryVerb [

	^ 'Restored'
]

{ #category : 'metadata' }
MCPToolRestoreMethod >> buildInputSchema [

	^ MCPStructureInputSchema
		  properties: {
				  (self schemaPropertyNamed: 'class' type: 'string' description: 'The class the method is in, or was in.').
				  (self targetSideSchemaPropertyDescribedAs: 'Which side the method is on.').
				  (self
					   stringOrArraySchemaNamed: 'selector'
					   description: 'The method''s selector, or several of that class.'
					   itemDescription: 'Selector name.').
				  ((self
					    integerSchemaPropertyNamed: 'version'
					    description:
						    'The version to install, as method_version_list numbers it. Omitted, the method goes back to how it was before its last change.')
					   minimum: 1;
					   yourself) }
		  required: #( 'class' 'selector' )
]

{ #category : 'private - errors' }
MCPToolRestoreMethod >> checkVersionNamesOneMethodIn: request [

	(request integerArgumentNamed: 'version') ifNotNil: [ :number |
			(request stringCollectionArgumentNamed: 'selector') size > 1 ifTrue: [
					MCPCommandError
						signalErrorCode: #VersionOfSeveralMethods
						message:
						'A version number names a version of one method: give one selector with version, or leave version out to put each method back as it was before its last change.'
						details: { (#version -> number) } asDictionary ] ]
]

{ #category : 'private - restoring' }
MCPToolRestoreMethod >> compile: aSource protocol: aProtocol of: aSelector in: aBehavior [
	"The recorded source exactly, without the formatting method_compile applies, since putting the method back means the text it had. A source that no longer compiles, as one reading a variable since removed, is refused with what the compiler said."

	[ aBehavior mcpCompile: aSource classified: aProtocol ]
		on: Error , Warning
		do: [ :error |
				MCPCommandError
					signalErrorCode: #RecordedSourceDoesNotCompile
					message: (String streamContents: [ :stream |
								 stream << (self methodReferenceForBehavior: aBehavior selector: aSelector)
								 << ' cannot be compiled from its recorded source: ' << (error messageText ifNil: [ error class name ])
								 << '. method_version_list shows that source.' ])
					details: (self detailsFor: aSelector in: aBehavior) ]
]

{ #category : 'private - results' }
MCPToolRestoreMethod >> dataForSource: aSource protocol: aProtocol [
	"What the method was given, as method_get answers it."

	| data |
	data := Dictionary new.
	aProtocol ifNotNil: [ data at: #protocol put: aProtocol ].
	data at: #source put: aSource.
	^ data
]

{ #category : 'metadata' }
MCPToolRestoreMethod >> description [

	^ 'Put a method back as it was before its last change, or as a version method_version_list lists. A removed method comes back. The recorded source is installed as it is.'
]

{ #category : 'private - errors' }
MCPToolRestoreMethod >> detailsFor: aSelector in: aBehavior [
	"The method an error is about, named as method_get's errors name one."

	^ Dictionary new
		  at: #class put: aBehavior instanceSide name asString;
		  at: #side put: (aBehavior isClassSide
				   ifTrue: [ 'class' ]
				   ifFalse: [ 'instance' ]);
		  at: #selector put: aSelector asString;
		  yourself
]

{ #category : 'executing' }
MCPToolRestoreMethod >> executeWithRequest: request [
	"A version is one method's, so a call naming one restores one selector. Each selector is restored on its own."

	^ self
		  executeRequest: request
		  do: [
				  self checkVersionNamesOneMethodIn: request.
				  self executeBatchedRequest: request do: [ :targetRequest |
					  self executeRequest: targetRequest do: [ self restoreWith: targetRequest ] onError: [ :error | self errorResultFor: error ] ] ]
		  onError: [ :error | self errorResultFor: error ]
]

{ #category : 'private - restoring' }
MCPToolRestoreMethod >> install: aVersion of: aSelector in: aBehavior [

	self
		compile: aVersion source
		protocol: aVersion protocol
		of: aSelector
		in: aBehavior.
	^ self
		  successResultText: (String streamContents: [ :stream |
					   stream << 'Restored ' << (self methodReferenceForBehavior: aBehavior selector: aSelector) << ' to version '
					   << aVersion number printString << '.' ])
		  data: (self dataForSource: aVersion source protocol: aVersion protocol)
]

{ #category : 'private - results' }
MCPToolRestoreMethod >> keyOrder [
	"Where the method is filed, then its source."

	^ #( protocol source )
]

{ #category : 'private - restoring' }
MCPToolRestoreMethod >> removeAddition: aSelector from: aBehavior [
	"Before the change that added it, the method did not exist. One already gone again outside the history has nothing left to remove."

	| reference |
	reference := self methodReferenceForBehavior: aBehavior selector: aSelector.
	(aBehavior includesSelector: aSelector) ifFalse: [
			^ self
				  successResultText: (String streamContents: [ :stream |
						   stream << reference << ' is not in the image, as before its last change added it: nothing was removed.' ])
				  data: Dictionary new ].
	aBehavior removeSelector: aSelector.
	^ self
		  successResultText:
		  (String streamContents: [ :stream | stream << 'Removed ' << reference << ', as it was before its last change added it.' ])
		  data: Dictionary new
]

{ #category : 'private - restoring' }
MCPToolRestoreMethod >> restoreWith: request [
	"Put the method back as it was before its last change, or as the version the call names."

	| behavior selector versions |
	behavior := self behaviorNamedIn: request.
	selector := (request stringArgumentNamed: 'selector') asSymbol.
	versions := MCPMethodVersionQuery inCurrentSession versionsOf: behavior selector: selector.
	versions ifEmpty: [ self signalNoVersionOf: selector in: behavior ].
	^ (request integerArgumentNamed: 'version')
		  ifNil: [ self undoChange: versions last of: selector in: behavior ]
		  ifNotNil: [ :number |
				  self
					  install: (self
							   version: number
							   among: versions
							   of: selector
							   in: behavior)
					  of: selector
					  in: behavior ]
]

{ #category : 'private - errors' }
MCPToolRestoreMethod >> signalNoVersionOf: aSelector in: aBehavior [

	MCPCommandError
		signalErrorCode: #MethodVersionNotFound
		message: (String streamContents: [ :stream |
					 stream << 'The change history records no change to ' << (self methodReferenceForBehavior: aBehavior selector: aSelector)
					 << ', so there is no version to restore it from.' ])
		details: (self detailsFor: aSelector in: aBehavior)
]

{ #category : 'metadata' }
MCPToolRestoreMethod >> title [

	^ 'Restore Method'
]

{ #category : 'private - restoring' }
MCPToolRestoreMethod >> undoChange: aVersion of: aSelector in: aBehavior [
	"Undo the change that made aVersion: a removal by compiling what it removed, a modification by compiling what it replaced, an addition by removing the method."

	aVersion isAddition ifTrue: [ ^ self removeAddition: aSelector from: aBehavior ].
	self
		compile: aVersion previousSource
		protocol: aVersion previousProtocol
		of: aSelector
		in: aBehavior.
	^ self
		  successResultText: (String streamContents: [ :stream |
					   stream << 'Restored ' << (self methodReferenceForBehavior: aBehavior selector: aSelector) << ' as it was before its '
					   << (aVersion isRemoval
							    ifTrue: [ 'removal.' ]
							    ifFalse: [ 'last change.' ]) ])
		  data: (self dataForSource: aVersion previousSource protocol: aVersion previousProtocol)
]

{ #category : 'private - errors' }
MCPToolRestoreMethod >> version: aNumber among: versions of: aSelector in: aBehavior [
	"Versions are numbered from 1, the oldest."

	(aNumber between: 1 and: versions size) ifTrue: [ ^ versions at: aNumber ].
	^ MCPCommandError
		  signalErrorCode: #MethodVersionNotFound
		  message: (String streamContents: [ :stream |
					   stream << (self methodReferenceForBehavior: aBehavior selector: aSelector) << ' has '
					   << (self textForCount: versions size noun: 'version') << ' in the change history'.
					   versions size > 1 ifTrue: [ stream << ', numbered 1 to ' << versions size printString ].
					   stream << ': there is no version ' << aNumber printString << '.' ])
		  details: ((self detailsFor: aSelector in: aBehavior)
				   at: #version put: aNumber;
				   at: #versionCount put: versions size;
				   yourself)
]
