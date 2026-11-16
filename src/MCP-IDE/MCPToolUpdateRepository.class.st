"
Concrete repository_update tool. It changes image-side repository subdirectory or package membership through MCPToolRepositoryOperation without writing packages to files.
"
Class {
	#name : 'MCPToolUpdateRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolUpdateRepository class >> toolName [

	^ 'repository_update'
]

{ #category : 'private - packages' }
MCPToolUpdateRepository >> add: packageNames to: aRepository with: steps recordingIn: added [

	packageNames do: [ :each | (steps addPackageNamed: each to: aRepository) ifTrue: [ added add: each ] ]
]

{ #category : 'private - errors' }
MCPToolUpdateRepository >> argumentContextFor: request [

	| context supplied |
	context := (super argumentContextFor: request) copy.
	supplied := self suppliedUpdateArgumentNamesIn: request.
	supplied do: [ :each |
			context at: each asSymbol put: (each = 'subdirectory'
					 ifTrue: [ request stringArgumentNamed: each ]
					 ifFalse: [ request stringCollectionArgumentNamed: each ]) ].
	context at: #updateActions put: (supplied collect: [ :each | self updateActionsByArgumentName at: each ] as: Array).
	^ context
]

{ #category : 'private - errors' }
MCPToolUpdateRepository >> failureSummaryPrefixFor: request [

	^ 'Failed to update repository: '
]

{ #category : 'private - execution' }
MCPToolUpdateRepository >> mutateWith: request [
	"Change the repository's subdirectory or package membership in the image, writing nothing to its files and unloading nothing."

	| added packageWarnings removed repository |
	^ self
		  executeOperationFor: request
		  work: [
				  | steps |
				  (self suppliedUpdateArgumentNamesIn: request) ifEmpty: [ self signalNoUpdateRequestedFor: request ].
				  repository := self repositoryFor: request.
				  added := OrderedCollection new.
				  removed := OrderedCollection new.
				  self
					  update: repository
					  as: request
					  added: added
					  removed: removed.
				  steps := MCPRepositoryCommand new.
				  added := steps sortedStringsFrom: added.
				  removed := steps sortedStringsFrom: removed.
				  packageWarnings := self warningsForPackagesNamed: added inNeitherImageNorCheckoutOf: repository ]
		  successResult: [ :warnings |
				  self
					  successResultText: (String streamContents: [ :stream |
							   stream << 'Updated repository ' << repository name << '.' << (self projectFileNoteFor: repository) ])
					  data: (self dataKeepingNonEmpty: {
								   (#addedPackages -> added).
								   (#removedPackages -> removed) })
					  warnings: warnings , packageWarnings ]
]

{ #category : 'private - packages' }
MCPToolUpdateRepository >> remove: packageNames from: aRepository with: steps recordingIn: removed [

	packageNames do: [ :each | (steps removePackageNamed: each from: aRepository) ifTrue: [ removed add: each ] ]
]

{ #category : 'private - specs' }
MCPToolUpdateRepository >> repositoryToolSpec [

	^ {
		  (#title -> 'Update Repository').
		  (#description -> 'Change image-side repository subdirectory or package membership without writing packages to files.').
		  (#action -> 'update').
		  (#inputProperties -> {
			   (self schemaPropertyNamed: 'subdirectory' type: 'string' description: 'Set the repository source subdirectory in the image.').
			   (self
				    stringArraySchemaNamed: 'packages'
				    description:
				    'Replace the full managed package list by adding and removing repository package membership without unloading packages or writing files.'
				    itemDescription: 'A package name.').
			   (self
				    stringArraySchemaNamed: 'addPackages'
				    description: 'Package names to add to the repository working copy without writing packages to files.'
				    itemDescription: 'A package name to add.').
			   (self
				    stringArraySchemaNamed: 'removePackages'
				    description: 'Package names to remove from repository membership without unloading packages from the image.'
				    itemDescription: 'A package name to remove.') }) } asDictionary
]

{ #category : 'private - errors' }
MCPToolUpdateRepository >> signalNoUpdateRequestedFor: request [

	MCPCommandError
		signalErrorCode: #NoRepositoryUpdateRequested
		message: 'repository_update needs at least one of subdirectory, packages, addPackages or removePackages.'
		details: (self argumentContextFor: request)
]

{ #category : 'private - request' }
MCPToolUpdateRepository >> suppliedUpdateArgumentNamesIn: request [

	^ self updateActionsByArgumentName keys select: [ :each | request hasArgumentNamed: each ]
]

{ #category : 'private - packages' }
MCPToolUpdateRepository >> update: aRepository as: request added: added removed: removed [
	"Set the subdirectory, replace the whole package list, add packages, then remove them, each when the call asks for it, recording the packages added and removed."

	| steps |
	steps := MCPRepositoryCommand new.
	(request hasArgumentNamed: 'subdirectory') ifTrue: [
		steps setSubdirectory: ((request stringArgumentNamed: 'subdirectory') ifNil: [ '' ]) on: aRepository ].
	(request hasArgumentNamed: 'packages') ifTrue: [
			| current desired |
			desired := steps sortedStringsFrom: (request stringCollectionArgumentNamed: 'packages').
			current := steps sortedStringsFrom: aRepository workingCopy packageNames.
			self
				remove: (current reject: [ :each | desired includes: each ])
				from: aRepository
				with: steps
				recordingIn: removed.
			self
				add: (desired reject: [ :each | current includes: each ])
				to: aRepository
				with: steps
				recordingIn: added ].
	self
		add: (request stringCollectionArgumentNamed: 'addPackages')
		to: aRepository
		with: steps
		recordingIn: added.
	self
		remove: (request stringCollectionArgumentNamed: 'removePackages')
		from: aRepository
		with: steps
		recordingIn: removed
]

{ #category : 'private - request' }
MCPToolUpdateRepository >> updateActionsByArgumentName [
	"What each argument asks of the repository, in the order the update applies them."

	^ OrderedDictionary new
		  at: 'subdirectory' put: 'setSubdirectory';
		  at: 'packages' put: 'replacePackages';
		  at: 'addPackages' put: 'addPackages';
		  at: 'removePackages' put: 'removePackages';
		  yourself
]
