"
Concrete history_file_list tool. It lists image change-history .ombu files through MCPToolChangeHistory.
"
Class {
	#name : 'MCPToolListChangeHistoryFiles',
	#superclass : 'MCPToolChangeHistory',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolListChangeHistoryFiles class >> toolName [

	^ 'history_file_list'
]

{ #category : 'metadata' }
MCPToolListChangeHistoryFiles >> annotations [

	^ MCPStructureToolAnnotations readOnly
]

{ #category : 'metadata' }
MCPToolListChangeHistoryFiles >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   schemaPropertyNamed: 'directoryPath'
					   type: 'string'
					   description: 'Directory holding the .ombu files. Defaults to this image''s own history directory.').
				  self offsetInputProperty };
		  required: #(  );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - execution' }
MCPToolListChangeHistoryFiles >> dataFor: request [

	| currentFile data directory page |
	currentFile := self currentHistoryFileReference.
	directory := self directoryToList: (request stringArgumentNamed: 'directoryPath') current: currentFile.
	page := MCPPaginationResult
		        fromEntries: (self historyFilesIn: directory current: currentFile)
		        limit: self defaultPageLimit
		        offset: (request integerArgumentNamed: 'offset').
	data := Dictionary new.
	data at: #files put: (page entries
			 collect: [ :each |
				 (MCPChangeHistoryLogInfo fromFileReference: each isCurrent: (self sameFileReference: each as: currentFile)) asDictionary ]
			 as: Array).
	page nextOffset ifNotNil: [ :offset | data at: #nextOffset put: offset ].
	^ data
]

{ #category : 'metadata' }
MCPToolListChangeHistoryFiles >> defaultPageLimit [

	^ 25
]

{ #category : 'metadata' }
MCPToolListChangeHistoryFiles >> description [

	^ 'List Pharo image change history .ombu files. Use history_entry_list to inspect entries. Use apply/revert only for recovery previews or changes.'
]

{ #category : 'private - files' }
MCPToolListChangeHistoryFiles >> directoryToList: directoryPath current: currentFile [
	"The directory directoryPath names, else the one holding this image's history."

	| directory |
	directoryPath ifNil: [ ^ self historyDirectoryForCurrentFile: currentFile ].
	self refuseRelativeDirectoryPath: directoryPath.
	directory := directoryPath asFileReference.
	currentFile ifNotNil: [
			(self sameFileReference: directory as: currentFile) ifTrue: [
					MCPCommandError
						signalErrorCode: #ChangeHistoryPathNotDirectory
						message: (String streamContents: [ :stream | stream << 'Change history path ' << directoryPath << ' is not a directory.' ])
						details: { (#directoryPath -> directoryPath) } asDictionary ] ].
	directory exists ifFalse: [
			MCPCommandError
				signalErrorCode: #ChangeHistoryDirectoryNotFound
				message: (String streamContents: [ :stream | stream << 'Change history directory ' << directoryPath << ' does not exist.' ])
				details: { (#directoryPath -> directoryPath) } asDictionary ].
	directory isDirectory ifFalse: [
			MCPCommandError
				signalErrorCode: #ChangeHistoryPathNotDirectory
				message: (String streamContents: [ :stream | stream << 'Change history path ' << directoryPath << ' is not a directory.' ])
				details: { (#directoryPath -> directoryPath) } asDictionary ].
	^ directory
]

{ #category : 'private - results' }
MCPToolListChangeHistoryFiles >> entryNameKeys [
	"A row is a file."

	^ #( file )
]

{ #category : 'private - files' }
MCPToolListChangeHistoryFiles >> historyFilesIn: aDirectory current: currentFile [
	"The .ombu files of aDirectory, the most recently modified first, with the session in progress among them when aDirectory holds it."

	| files |
	files := aDirectory exists
		         ifTrue: [ aDirectory files select: [ :each | each extension = 'ombu' ] ]
		         ifFalse: [ #(  ) ].
	(currentFile isNotNil and: [
			 (self sameFileReference: aDirectory as: currentFile parent) and: [
				 (files anySatisfy: [ :each | self sameFileReference: each as: currentFile ]) not ] ]) ifTrue: [
		files := files copyWith: currentFile ].
	^ files asArray sort: [ :left :right | self shouldSortFile: left before: right ]
]

{ #category : 'private - files' }
MCPToolListChangeHistoryFiles >> modificationTimeOf: aFileReference [

	^ [ aFileReference modificationTime ]
		  on: Error
		  do: [ :error | nil ]
]

{ #category : 'private - files' }
MCPToolListChangeHistoryFiles >> shouldSortFile: leftFile before: rightFile [

	| leftTime rightTime |
	leftTime := self modificationTimeOf: leftFile.
	rightTime := self modificationTimeOf: rightFile.
	(leftTime isNil and: [ rightTime isNil ]) ifTrue: [ ^ leftFile basename <= rightFile basename ].
	leftTime ifNil: [ ^ false ].
	rightTime ifNil: [ ^ true ].
	^ leftTime >= rightTime
]

{ #category : 'private - results' }
MCPToolListChangeHistoryFiles >> successSummaryForData: data [

	^ self listedSummaryForCount: (data at: #files) size noun: 'change history file' data: data
]

{ #category : 'metadata' }
MCPToolListChangeHistoryFiles >> title [

	^ 'List Change History Files'
]
