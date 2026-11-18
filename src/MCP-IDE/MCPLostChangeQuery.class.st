"
Finds what the sessions since the image's last save changed and the image lacks, after a crash or a stop without saving.

The session store keeps, in the saved image, the reference of the last entry logged before the save, and each session writes a file of its own whose first entry follows that reference: the save point. Every session started from one save follows the same save point, so they do not chain to one another. The changes lost are those the saved session wrote after its save point, in its own file, then those of every other session file whose first entry follows the save point, oldest first. EpLostChangesDetector, which Pharo runs at startup, sees only the first part. A save that does not quit logs a snapshot in the session in progress, the save point from then on: the image saved went on without what earlier sessions lost.

Each file is read once, and only from the save point on, the session in progress's own first: it says where the save point is, and which elements the image changed since, whose lost changes it went on without. Visiting the entries keeps one MCPLostChange per method, class definition and class comment, so the result is the net change of each element, not every step towards it. What a load changed is left out, as the files it loaded hold it. MCPSessionLostChanges keeps the reading of the session in progress for the image session.
"
Class {
	#name : 'MCPLostChangeQuery',
	#superclass : 'Object',
	#traits : 'EpTCodeChangeVisitor',
	#classTraits : 'EpTCodeChangeVisitor classTrait',
	#instVars : [
		'currentFile',
		'savePoint',
		'methodChanges',
		'classChanges',
		'commentChanges',
		'position',
		'files',
		'warnings',
		'changes'
	],
	#category : 'MCP-IDE-Queries',
	#package : 'MCP-IDE',
	#tag : 'Queries'
}

{ #category : 'instance creation' }
MCPLostChangeQuery class >> log: anEpLog file: aFileReference [
	"The changes lost by the sessions that started from the save anEpLog, the session in progress, started from. aFileReference is the file it writes, among those of the other sessions."

	^ self new
		  setLog: anEpLog file: aFileReference;
		  yourself
]

{ #category : 'instance creation' }
MCPLostChangeQuery class >> ofSessionInProgress [
	"The changes the image running now lost: those of the sessions since its last save, as MCPSessionLostChanges keeps them for the image session."

	^ MCPSessionLostChanges current query
]

{ #category : 'accessing' }
MCPLostChangeQuery >> changes [
	"The last change to each element, in the order they were made, but for the members of a class a later change removed."

	^ changes ifNil: [ changes := self readChanges ]
]

{ #category : 'accessing' }
MCPLostChangeQuery >> directory [

	^ currentFile parent
]

{ #category : 'private - reading' }
MCPLostChangeQuery >> elementNameOf: anEvent ifPresent: aBlock [
	"Evaluate aBlock with the element anEvent changed, named as a lost change names it: Foo>>bar or Foo class>>bar for a method, Foo for a class's definition or comment. A protocol is not an element, nor is anything other than code."

	anEvent isCodeChange ifFalse: [ ^ self ].
	anEvent isEpMethodChange ifTrue: [
			^ aBlock value:
				  (String streamContents: [ :stream | stream << anEvent behaviorAffectedName << '>>' << anEvent methodAffectedSelector ]) ].
	(anEvent isEpBehaviorChange and: [ anEvent isEpProtocolChange not ]) ifTrue: [
		aBlock value: anEvent behaviorAffectedName asString ]
]

{ #category : 'private - reading' }
MCPLostChangeQuery >> entriesOf: aStore after: aCount do: aBlock [
	"A whole file reads in one pass. Past a save point, the positions Ombu indexes skip what was saved without parsing it, which matters in the saved session's file: the longest, as it often loaded the code the image was built with."

	aCount = 0 ifTrue: [ ^ aStore entriesDo: aBlock ].
	aStore refresh.
	aCount + 1 to: aStore entriesCount do: [ :index |
	aStore entryFor: (aStore referenceToLocalName: index asString) ifPresent: aBlock ifAbsent: [ ] ]
]

{ #category : 'initialization' }
MCPLostChangeQuery >> initialize [

	super initialize.
	methodChanges := Dictionary new.
	classChanges := Dictionary new.
	commentChanges := Dictionary new.
	position := 0.
	files := OrderedCollection new.
	warnings := OrderedCollection new
]

{ #category : 'accessing' }
MCPLostChangeQuery >> lostChanges [
	"The changes the image does not hold, compared with it at each call."

	^ self changes reject: [ :each | each isInImage ]
]

{ #category : 'updating' }
MCPLostChangeQuery >> noteChangeInSessionInProgress: anEvent [
	"The session in progress logged anEvent after the reading."

	self elementNameOf: anEvent ifPresent: [ :name | self noteChangeInSessionInProgressTo: name ]
]

{ #category : 'private - recording' }
MCPLostChangeQuery >> noteChangeInSessionInProgressTo: anElementName [
	"The session in progress changed the element: a lost change to it is no longer the image's latest word on it."

	{
		methodChanges.
		classChanges.
		commentChanges } do: [ :each | each at: anElementName ifPresent: [ :change | change beChangedInSessionInProgress ] ]
]

{ #category : 'private - recording' }
MCPLostChangeQuery >> packageNameOf: aChange [
	"Epicea names the package of a method change, and gives that of a class change by its name or, from Pharo 12 on, as a package definition."

	^ aChange affectedPackageName ifNotNil: [ :package |
			  package isString
				  ifTrue: [ package asString ]
				  ifFalse: [ package name asString ] ]
]

{ #category : 'private - reading' }
MCPLostChangeQuery >> read: anEntry from: aFile amongLoads: someLoadReferences [
	"Only a code change can change an element: the rest is sessions, loads and the history's own operations. What a load changed is left out: the files it loaded hold it, and a Pharo that does not log loads would never list it. A load logs itself first, then each change it makes with the load as its trigger, so the loads read so far in the file, someLoadReferences, tell its changes apart."

	files addIfNotPresent: aFile.
	position := position + 1.
	anEntry content isMonticelloVersionsLoad ifTrue: [
			someLoadReferences add: (anEntry tags at: OmStore selfReferenceKey).
			^ self ].
	anEntry content isCodeChange ifFalse: [ ^ self ].
	(someLoadReferences includes: (anEntry tags at: EpLog triggererReferenceKey ifAbsent: [ nil ])) ifFalse: [
		anEntry content accept: self ]
]

{ #category : 'private - reading' }
MCPLostChangeQuery >> readChanges [

	self readSavedSession.
	self sessionsSinceSave do: [ :each | self readEntriesOf: each after: 0 ].
	^ (methodChanges values , classChanges values , commentChanges values reject: [ :each | each isSuperseded ]) sort: [ :first :second |
		  first position < second position ]
]

{ #category : 'private - reading' }
MCPLostChangeQuery >> readEntriesOf: aFile after: aCount [
	"Visit the entries of aFile past its first aCount, oldest first. A file a crash cut short, or one naming a class this image lacks, is read up to the entry that cannot be, and a warning says so."

	| count loads store |
	store := (EpLog fromFile: aFile) store.
	count := aCount.
	loads := Set new.
	[
		self entriesOf: store after: aCount do: [ :entry |
				count := count + 1.
				self read: entry from: aFile amongLoads: loads ] ]
		on: Error
		do: [ :error | warnings add: (self warningForFile: aFile readUpTo: count error: error) ]
]

{ #category : 'private - reading' }
MCPLostChangeQuery >> readSavedSession [
	"The session that was saved went on writing its own file after the save, and what it wrote then is lost too."

	| file |
	self savePoint isNull ifTrue: [ ^ self ].
	file := OmFileStore fileReferenceForStoreNamed: self savePoint globalName inDirectory: self directory.
	(file exists and: [ file ~= currentFile ]) ifTrue: [ self readEntriesOf: file after: self savePoint localName asInteger ]
]

{ #category : 'private - recording' }
MCPLostChangeQuery >> recordDefinitionChange: aChange from: aClassDefinition to: anotherClassDefinition [
	"aClassDefinition is the class before aChange, nil where it did not exist, anotherClassDefinition after it. Only the first change to the class says what it was at the save."

	(classChanges
		 at: aChange behaviorAffectedName asString
		 ifAbsentPut: [ MCPLostClassChange className: aChange behaviorAffectedName saved: aClassDefinition ])
		becomes: anotherClassDefinition at: position;
		packageName: (self packageNameOf: aChange)
]

{ #category : 'private - recording' }
MCPLostChangeQuery >> recordMethodChange: aChange from: aMethodDefinition to: anotherMethodDefinition [
	"aMethodDefinition is the method before aChange, anotherMethodDefinition after it, nil where it does not exist. Only the first change to the method says what it was at the save."

	| element |
	element := String streamContents: [ :stream | stream << aChange behaviorAffectedName << '>>' << aChange methodAffectedSelector ].
	(methodChanges at: element ifAbsentPut: [
			 MCPLostMethodChange
				 behaviorName: aChange behaviorAffectedName
				 selector: aChange methodAffectedSelector
				 saved: aMethodDefinition ])
		becomes: anotherMethodDefinition at: position;
		packageName: (self packageNameOf: aChange)
]

{ #category : 'private - recording' }
MCPLostChangeQuery >> recordRemoval: aChange of: aClassDefinition [
	"A class removed takes its methods and comment with it, so the changes made to them before are moot. Epicea records a removed class once Pharo has renamed it obsolete, and patches its definition back, which before Pharo 12 does not read as the class did: when the removal is the first change read, the definition at the save is not known."

	(classChanges at: aChange behaviorAffectedName asString ifAbsentPut: [
				 (MCPLostClassChange className: aChange behaviorAffectedName saved: aClassDefinition)
					 savedStateIsUnknown;
					 yourself ])
		becomes: nil at: position;
		packageName: (self packageNameOf: aChange).
	self supersedeMembersOf: aChange behaviorAffectedName asString
]

{ #category : 'private - recording' }
MCPLostChangeQuery >> recordRepackaging: aChange [
	"A move records the whole definition after it, so restoring it restores what earlier changes to the definition made too. It does not record the definition before it."

	(classChanges at: aChange behaviorAffectedName asString ifAbsentPut: [
				 (MCPLostClassChange className: aChange behaviorAffectedName saved: nil)
					 savedStateIsUnknown;
					 yourself ])
		becomes: aChange behaviorAffected at: position;
		packageName: (self packageNameOf: aChange)
]

{ #category : 'accessing' }
MCPLostChangeQuery >> savePoint [

	^ savePoint
]

{ #category : 'private - reading' }
MCPLostChangeQuery >> savePointOf: anEpLog notingChangesIn: someElementNames [
	"The entry the session in progress follows: the last save it logged, when it saved the image without quitting, or else the prior of its first entry, or, while it has logged none, the head the session store kept from the save. Its file is read once, from the start, adding to someElementNames each element its changes name. An entry that cannot be read, as one still being written, ends the reading, and a warning says so."

	| count first save |
	count := 0.
	first := nil.
	save := nil.
	[
		(EpLog fromFile: currentFile) store entriesDo: [ :entry |
				count := count + 1.
				count = 1 ifTrue: [ first := entry ].
				entry content mcpIsImageSave ifTrue: [ save := entry tags at: OmStore selfReferenceKey ].
				self elementNameOf: entry content ifPresent: [ :name | someElementNames add: name ] ] ]
		on: Error
		do: [ :error | warnings add: (self warningForFile: currentFile readUpTo: count error: error) ].
	save ifNotNil: [ ^ save ].
	first ifNil: [ ^ anEpLog headReference ].
	^ anEpLog priorReferenceAt: first
]

{ #category : 'accessing' }
MCPLostChangeQuery >> sessionNames [
	"The files of the sessions the changes come from, oldest first."

	self changes.
	^ files collect: [ :each | each basename ] as: Array
]

{ #category : 'private - reading' }
MCPLostChangeQuery >> sessionsSinceSave [
	"The other sessions started from the same save, each in a file of its own whose first entry follows the save point, in the order they were written."

	self directory exists ifFalse: [ ^ #(  ) ].
	^ (self directory files select: [ :each |
		   each extension = 'ombu' and: [ each ~= currentFile and: [ self startsAtSavePoint: each ] ] ]) sort: [ :first :second |
		  self wasWritten: first before: second ]
]

{ #category : 'initialization' }
MCPLostChangeQuery >> setLog: anEpLog file: aFileReference [
	"The session in progress is read first, for the save point and for the elements it changed, then the sessions since the save, whose changes to those elements the image went on without."

	| changedInSession |
	currentFile := aFileReference.
	changedInSession := Set new.
	savePoint := self savePointOf: anEpLog notingChangesIn: changedInSession.
	self changes.
	changedInSession do: [ :each | self noteChangeInSessionInProgressTo: each ]
]

{ #category : 'private - reading' }
MCPLostChangeQuery >> startsAtSavePoint: aFile [
	"Only the first entry is read: a file of another branch of the history is left without reading the rest."

	| first |
	first := (EpLog fromFile: aFile) firstEntryIfAbsent: [ ^ false ].
	^ (first tags at: EpLog priorReferenceKey ifAbsent: [ ^ false ]) = self savePoint
]

{ #category : 'private - recording' }
MCPLostChangeQuery >> supersedeMembersOf: aClassName [

	methodChanges select: [ :each | each isOfClassNamed: aClassName ] thenDo: [ :each | each supersede ].
	commentChanges at: aClassName ifPresent: [ :each | each supersede ]
]

{ #category : 'visiting' }
MCPLostChangeQuery >> visitBehaviorCategoryChange: aChange [
	"Before Pharo 12, a class moved to another category."

	self recordRepackaging: aChange
]

{ #category : 'visiting' }
MCPLostChangeQuery >> visitBehaviorCommentChange: aChange [

	(commentChanges
		 at: aChange behaviorAffectedName asString
		 ifAbsentPut: [ MCPLostCommentChange className: aChange behaviorAffectedName saved: aChange oldComment ])
		becomes: aChange newComment stamped: aChange newStamp at: position;
		packageName: (self packageNameOf: aChange)
]

{ #category : 'visiting' }
MCPLostChangeQuery >> visitBehaviorRepackagedChange: aChange [
	"From Pharo 12 on, a class moved to another package or tag."

	self recordRepackaging: aChange
]

{ #category : 'visiting' }
MCPLostChangeQuery >> visitClassAddition: aChange [

	self recordDefinitionChange: aChange from: nil to: aChange classAdded
]

{ #category : 'visiting' }
MCPLostChangeQuery >> visitClassModification: aChange [

	self recordDefinitionChange: aChange from: aChange oldClass to: aChange newClass
]

{ #category : 'visiting' }
MCPLostChangeQuery >> visitClassRemoval: aChange [

	self recordRemoval: aChange of: aChange classRemoved
]

{ #category : 'visiting' }
MCPLostChangeQuery >> visitCodeChange: aChange [
	"Any other code change touches no element the tools restore: a protocol comes with each method, a package with each definition."

	
]

{ #category : 'visiting' }
MCPLostChangeQuery >> visitMethodAddition: aChange [

	self recordMethodChange: aChange from: nil to: aChange methodAdded
]

{ #category : 'visiting' }
MCPLostChangeQuery >> visitMethodModification: aChange [

	self recordMethodChange: aChange from: aChange oldMethod to: aChange newMethod
]

{ #category : 'visiting' }
MCPLostChangeQuery >> visitMethodRemoval: aChange [

	self recordMethodChange: aChange from: aChange methodRemoved to: nil
]

{ #category : 'visiting' }
MCPLostChangeQuery >> visitTraitAddition: aChange [

	self recordDefinitionChange: aChange from: nil to: aChange traitAdded
]

{ #category : 'visiting' }
MCPLostChangeQuery >> visitTraitModification: aChange [

	self recordDefinitionChange: aChange from: aChange oldTrait to: aChange newTrait
]

{ #category : 'visiting' }
MCPLostChangeQuery >> visitTraitRemoval: aChange [

	self recordRemoval: aChange of: aChange traitRemoved
]

{ #category : 'private - reading' }
MCPLostChangeQuery >> warningForFile: aFile readUpTo: aCount error: anError [

	^ String streamContents: [ :stream |
			  stream << aFile basename << ' could not be read past its entry ' << aCount printString
			  << ', so the changes it records after it are not listed: ' << anError messageText ]
]

{ #category : 'accessing' }
MCPLostChangeQuery >> warnings [
	"What could not be read."

	self changes.
	^ warnings asArray
]

{ #category : 'private - reading' }
MCPLostChangeQuery >> wasWritten: aFile before: anotherFile [
	"Sessions started from one save run one after the other, so their last writes order them; the name breaks a tie a coarse clock leaves."

	| otherTime time |
	time := aFile modificationTime.
	otherTime := anotherFile modificationTime.
	time = otherTime ifTrue: [ ^ aFile basename <= anotherFile basename ].
	^ time < otherTime
]
