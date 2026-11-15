"
Concrete repository_export tool. It writes the packages of a registered repository to its checkout, in the format the checkout declares, through MCPToolRepositoryOperation, and names the packages and files it wrote, without staging or committing anything.
"
Class {
	#name : 'MCPToolExportRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolExportRepository class >> toolName [

	^ 'repository_export'
]

{ #category : 'private - results' }
MCPToolExportRepository >> dataForPackageNames: packageNames writtenPaths: writtenPaths deletedPaths: deletedPaths alsoUncommittedPaths: alsoUncommittedPaths [
	"What export wrote and nothing else: the packages, the files it created or changed, a package directory that did not exist before as one path ending in a slash, the files it deleted, and what git sees besides in the checkout, every path from the checkout root."

	^ self dataKeepingNonEmpty: {
			  (#packages -> packageNames asArray).
			  (#written -> writtenPaths asArray).
			  (#deleted -> deletedPaths asArray).
			  (#alsoUncommitted -> alsoUncommittedPaths asArray) }
]

{ #category : 'private - errors' }
MCPToolExportRepository >> failureSummaryPrefix [

	^ 'Failed to export repository: '
]

{ #category : 'private - results' }
MCPToolExportRepository >> keyOrder [

	^ #( written deleted alsoUncommitted )
]

{ #category : 'private - results' }
MCPToolExportRepository >> keysStatedInSummary [

	^ #( packages )
]

{ #category : 'private - execution' }
MCPToolExportRepository >> mutateWith: request [
	"Write the repository's packages to its checkout and name what was written, staging and committing nothing."

	| export repository |
	^ self
		  executeOperationFor: request
		  work: [
				  repository := self repositoryFor: request.
				  export := MCPExportRepositoryCommand repository: repository.
				  export execute ]
		  successResult: [ :warnings |
				  self
					  successResultText: (self summaryForExport: export of: repository)
					  data: (self
							   dataForPackageNames: export packageNames
							   writtenPaths: export writtenPaths
							   deletedPaths: export deletedPaths
							   alsoUncommittedPaths: export alsoUncommittedPaths)
					  warnings: warnings , (self warningsForUnloadedPackages: export unloadedPackageNames of: repository) ]
]

{ #category : 'private - specs' }
MCPToolExportRepository >> repositoryToolSpec [

	^ {
		  (#title -> 'Export Repository').
		  (#description
		   ->
		   'Write the packages of a registered repository to its checkout, in the format the checkout declares, and name the files written. Nothing is staged or committed.').
		  (#action -> 'export') } asDictionary
]

{ #category : 'private - results' }
MCPToolExportRepository >> summaryForExport: anExport of: aRepository [
	"Name the packages export wrote; when it wrote no package file, the files it wrote outside every package, such as .project; and otherwise that there was nothing to write."

	| changedPaths |
	changedPaths := anExport writtenPaths , anExport deletedPaths.
	^ String streamContents: [ :stream |
			  stream << 'Exported repository ' << aRepository name << ': '.
			  anExport packageNames ifNotEmpty: [ :names | stream << 'wrote ' << (', ' join: names) << ', not committed yet.' ] ifEmpty: [
					  changedPaths
						  ifNotEmpty: [ stream << 'wrote ' << (', ' join: changedPaths asArray sort) << ', not committed yet.' ]
						  ifEmpty: [ stream << 'nothing to write, its files already hold what the image has.' ] ] ]
]
