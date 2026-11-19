"
Shared implementation for the tools that act on one Iceberg repository.

It defines the inputs each of them takes and runs every call the same way: a tool reads its arguments from the request, does its work in mutateWith: inside the mutation boundary, and answers a summary, its warnings and its data. An error answers with the tool's action and the arguments it read. The Iceberg and git steps come from MCPRepositoryCommand and its subclasses.
"
Class {
	#name : 'MCPToolRepositoryOperation',
	#superclass : 'MCPToolMutation',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolRepositoryOperation class >> groupName [

	^ self repositoriesGroupName
]

{ #category : 'testing' }
MCPToolRepositoryOperation class >> isAbstract [

	^ self = MCPToolRepositoryOperation
]

{ #category : 'metadata' }
MCPToolRepositoryOperation >> additionalKeywords [

	^ #( 'repository' 'repo' 'iceberg' 'git' )
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> branchNameSchemaProperty [
	"A guard, not a checkout: both tools that take it refuse to act when the repository is on another branch."

	^ self
		  schemaPropertyNamed: 'branch'
		  type: 'string'
		  description: 'Branch the repository is expected to be on. The call fails if it is on another; it never switches branch.'
]

{ #category : 'private - execution' }
MCPToolRepositoryOperation >> checkArguments: request [
	"The schema has checked every argument a repository tool takes. What remains to check needs the repository, which the operation finds."

	^ self
]

{ #category : 'private - creating' }
MCPToolRepositoryOperation >> creationFor: request [
	"The operation that creates or attaches the repository the call describes. Without a location, it goes in Iceberg's own directory of repositories, under its name."

	| name |
	name := request stringArgumentNamed: 'repository'.
	^ MCPCreateRepositoryCommand
		  name: name
		  location: (request stringArgumentNamed: 'location' default: (IceLibgitRepository repositoriesLocation / name) fullName)
		  subdirectory: (request stringArgumentNamed: 'subdirectory')
		  packageNames: (request stringCollectionArgumentNamed: 'packages')
]

{ #category : 'private - results' }
MCPToolRepositoryOperation >> dataForPackagesOf: aRepository [
	"The packages the repository registers, by name."

	| packages |
	packages := aRepository workingCopy packages asArray sort: [ :left :right | left name asString <= right name asString ].
	^ self dataKeepingNonEmpty:
		  { (#packages -> (packages collect: [ :each | (MCPRepositoryPackageInfo fromPackage: each) name ] as: Array)) }
]

{ #category : 'private - results' }
MCPToolRepositoryOperation >> dataKeepingNonEmpty: associations [
	"The answer's data: each list that holds something, under its key."

	| data |
	data := Dictionary new.
	associations do: [ :each | each value ifNotEmpty: [ :value | data at: each key put: value ] ].
	^ data
]

{ #category : 'metadata' }
MCPToolRepositoryOperation >> description [

	^ self repositoryToolSpec at: #description
]

{ #category : 'private - errors' }
MCPToolRepositoryOperation >> errorResultForCommandError: anError action: action requestedContext: requestedContext [

	| details |
	details := anError structuredDetails copy.
	requestedContext ifNotNil: [
		requestedContext keysAndValuesDo: [ :key :value | value ifNotNil: [ details at: key ifAbsentPut: [ value ] ] ] ].
	details at: #action put: action.
	^ self errorResultText: anError messageText details: details
]

{ #category : 'private - execution' }
MCPToolRepositoryOperation >> executeOperationFor: request work: workBlock successResult: successBlock [
	"Run the operation inside the mutation boundary, where an error answers with what the call asked for, under the tool's action, and with a summary saying what failed."

	^ self
		  executeMutationAction: self operationAction
		  force: false
		  requestedContext: (self requestedContextFor: request)
		  work: workBlock
		  successResult: successBlock
		  failureSummary: [ :error | self failureSummaryFor: error request: request ]
]

{ #category : 'private - repository' }
MCPToolRepositoryOperation >> expectedBranchNameIn: request [
	"The branch the caller expects the repository on, or an empty string when it expects none."

	^ (request stringArgumentNamed: 'branch') ifNil: [ '' ]
]

{ #category : 'private - errors' }
MCPToolRepositoryOperation >> failureSummaryFor: anError request: request [
	"What failed, then why."

	^ (self failureSummaryPrefixFor: request) , (anError messageText ifNil: [ anError asString ])
]

{ #category : 'private - errors' }
MCPToolRepositoryOperation >> failureSummaryPrefixFor: request [
	"What a failed call says before why it failed."

	self subclassResponsibility
]

{ #category : 'private - results' }
MCPToolRepositoryOperation >> headPhraseFor: aRepository [
	"Where HEAD is, as attach and reload say it: on a branch, detached at a commit, or before any commit."

	| info |
	(MCPIcebergCommitInfo isNoCommit: aRepository headCommit) ifTrue: [ ^ 'which has no commit yet' ].
	info := MCPRepositoryInfo fromRepository: aRepository.
	^ String streamContents: [ :stream |
			  info isDetachedHead
				  ifTrue: [ stream << 'on detached HEAD ' << (self shortCommitId: info headCommitId) ]
				  ifFalse: [ stream << 'on branch ' << info branchName ] ]
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> inputProperties [

	^ (self repositoryToolSpec at: #referenceInputProperties ifAbsent: [ self repositoryReferenceInputProperties ])
	  , (self repositoryToolSpec at: #inputProperties ifAbsent: [ #(  ) ])
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> isModifiedSchemaProperty [

	^ self
		  booleanSchemaPropertyNamed: 'isModified'
		  description: 'Assert whether the image holds changes the repository files do not.'
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> messageSchemaProperty [

	^ self schemaPropertyNamed: 'message' type: 'string' description: 'Commit message for the repository commit.'
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> modifiedPackageNamesSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'modifiedPackages'
		  description: 'Assert exactly these managed packages differ from the repository files.'
		  itemDescription: 'Package name.'
]

{ #category : 'private - errors' }
MCPToolRepositoryOperation >> mutationActionFor: request checked: aBoolean [

	^ self operationAction
]

{ #category : 'private - actions' }
MCPToolRepositoryOperation >> operationAction [

	^ self repositoryToolSpec at: #action
]

{ #category : 'private - results' }
MCPToolRepositoryOperation >> packageNamesRegisteredIn: aRepository [
	"A registration whose working copy cannot be read registers nothing this can name."

	^ [ aRepository workingCopy packageNames collect: [ :each | each asString ] ]
		  on: Error
		  do: [ #(  ) ]
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> packageNamesSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'packages'
		  description: 'Assert the repository manages exactly these packages.'
		  itemDescription: 'Package name.'
]

{ #category : 'private - results' }
MCPToolRepositoryOperation >> projectFileNoteFor: aRepository [
	"The caller did not write the .project file the next export writes, so say it is coming when the image's project differs from the one at the checkout's HEAD."

	(aRepository project isUnborn or: [ aRepository project isDirty not ]) ifTrue: [ ^ '' ].
	^ ' The next export writes its .project file, which names the source directory.'
]

{ #category : 'private - results' }
MCPToolRepositoryOperation >> registrationWarningsFor: aRepository withoutPackages: aWarning [
	"Say when the repository has no packages, and name every other repository that registers some of them: two registrations claiming one package is a hazard."

	| packageNames |
	packageNames := MCPRepositoryCommand new sortedStringsFrom: aRepository workingCopy packageNames.
	packageNames ifEmpty: [ ^ { aWarning } ].
	^ self warningsForPackages: packageNames alsoRegisteredBesides: aRepository
]

{ #category : 'private - repository' }
MCPToolRepositoryOperation >> repositoryFor: request [
	"The registered repository the call names."

	^ (self repositoryReferenceFor: request) repository
]

{ #category : 'private - repository' }
MCPToolRepositoryOperation >> repositoryReferenceFor: request [

	^ MCPRepositoryReferenceSpec fromRequest: request
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> repositoryReferenceInputProperties [

	^ {
		  (self schemaPropertyNamed: 'repository' type: 'string' description: 'Registered repository name.').
		  (self
			   schemaPropertyNamed: 'location'
			   type: 'string'
			   description: 'Checkout path, to tell apart repositories registered under the same name.') }
]

{ #category : 'private - specs' }
MCPToolRepositoryOperation >> repositoryToolSpec [

	self subclassResponsibility
]

{ #category : 'private - errors' }
MCPToolRepositoryOperation >> requestedContextFor: request [
	"The repository the call names."

	^ (self repositoryReferenceFor: request) requestedContext
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> requiredInputProperties [

	^ self repositoryToolSpec at: #requiredProperties ifAbsent: [ #( 'repository' ) ]
]

{ #category : 'private - results' }
MCPToolRepositoryOperation >> shortCommitId: aCommitId [
	"The first seven characters, as git log --oneline names a commit."

	^ aCommitId first: (7 min: aCommitId size)
]

{ #category : 'private - results' }
MCPToolRepositoryOperation >> sourcesPhraseFor: aRepository [

	| subdirectory |
	subdirectory := (aRepository subdirectory ifNil: [ '' ]) asString.
	subdirectory isEmpty ifTrue: [ ^ 'with its sources at its root' ].
	^ 'with its sources in ' , subdirectory
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> subdirectorySchemaProperty [

	^ self
		  schemaPropertyNamed: 'subdirectory'
		  type: 'string'
		  description: 'Directory inside the checkout holding the package sources, such as src.'
]

{ #category : 'metadata' }
MCPToolRepositoryOperation >> title [

	^ self repositoryToolSpec at: #title
]

{ #category : 'private - results' }
MCPToolRepositoryOperation >> warningForPackageInNeitherImageNorCheckoutNamed: aPackageName [

	| suggestions |
	suggestions := MCPScopeNameSuggester packageSuggestionsFor: aPackageName.
	^ String streamContents: [ :stream |
			  stream << aPackageName << ' is in neither the image nor the checkout.'.
			  suggestions ifNotEmpty: [ stream << ' Did you mean: ' << (', ' join: suggestions) << '.' ] ]
]

{ #category : 'private - results' }
MCPToolRepositoryOperation >> warningsForPackages: packageNames alsoRegisteredBesides: aRepository [
	"One warning per other registered repository that registers some of these packages, in the order of their names."

	| others steps |
	steps := MCPRepositoryCommand new.
	others := (IceRepository repositories reject: [ :each | each == aRepository ]) asArray sort: [ :left :right |
		          left name asString <= right name asString ].
	^ Array streamContents: [ :stream |
			  others do: [ :other |
					  | shared |
					  shared := steps sortedStringsFrom: ((self packageNamesRegisteredIn: other) select: [ :each | packageNames includes: each ]).
					  shared ifNotEmpty: [
							  stream nextPut: (String streamContents: [ :text |
										   text << (', ' join: shared) << (shared size = 1
											    ifTrue: [ ' is' ]
											    ifFalse: [ ' are' ]) << ' also registered in repository ' << other name << '.' ]) ] ] ]
]

{ #category : 'private - results' }
MCPToolRepositoryOperation >> warningsForPackagesNamed: packageNames inNeitherImageNorCheckoutOf: aRepository [
	"A registered package that neither the image nor the checkout holds is likely a name mistyped, so say so, once per package."

	| seen steps |
	seen := Set new.
	steps := MCPRepositoryCommand new.
	^ Array streamContents: [ :stream |
			  packageNames do: [ :each |
					  ((seen includes: each) or: [
						   (self packageOrganizer hasPackage: each) or: [ steps checkoutOf: aRepository holdsPackageNamed: each ] ]) ifFalse: [
						  stream nextPut: (self warningForPackageInNeitherImageNorCheckoutNamed: each) ].
					  seen add: each ] ]
]

{ #category : 'private - results' }
MCPToolRepositoryOperation >> warningsForUnloadedPackages: packageNames of: aRepository [
	"Export writes only what the image holds, so name the registered packages it left as they are."

	packageNames ifEmpty: [ ^ #(  ) ].
	^ { (String streamContents: [ :stream |
			   packageNames size = 1
				   ifTrue: [
						   stream << packageNames first << ' is registered in repository ' << aRepository name
						   <<
						   ' but not in the image, so export did not write it; its files in the checkout are left as they are. If it no longer belongs to the repository, repository_update removePackages drops it.' ]
				   ifFalse: [
						   stream << (', ' join: packageNames) << ' are registered in repository ' << aRepository name
						   <<
						   ' but not in the image, so export did not write them; their files in the checkout are left as they are. If they no longer belong to the repository, repository_update removePackages drops them.' ] ]) }
]
