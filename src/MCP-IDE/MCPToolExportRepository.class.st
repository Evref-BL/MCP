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
MCPToolExportRepository >> keyOrder [

	^ #( written deleted alsoUncommitted )
]

{ #category : 'private - results' }
MCPToolExportRepository >> keysStatedInSummary [

	^ #( packages )
]

{ #category : 'private - specs' }
MCPToolExportRepository >> repositoryToolSpec [

	^ {
		  (#title -> 'Export Repository').
		  (#description
		   ->
		   'Write the packages of a registered repository to its checkout, in the format the checkout declares, and name the files written. Nothing is staged or committed.').
		  (#action -> 'export').
		  (#requestClass -> MCPRepositoryExportRequest).
		  (#commandClass -> MCPExportRepositoryCommand) } asDictionary
]

{ #category : 'private - results' }
MCPToolExportRepository >> summaryForExportResult: anExportResult [
	"Name the packages export wrote; when it wrote no package file, the files it wrote outside every package, such as .project; and otherwise that there was nothing to write."

	| changedPaths |
	changedPaths := anExportResult writtenPaths , anExportResult deletedPaths.
	^ String streamContents: [ :stream |
			  stream << 'Exported repository ' << anExportResult repositoryInfo name << ': '.
			  anExportResult packageNames
				  ifNotEmpty: [ :names | stream << 'wrote ' << (', ' join: names) << ', not committed yet.' ]
				  ifEmpty: [
						  changedPaths
							  ifNotEmpty: [ stream << 'wrote ' << (', ' join: changedPaths asArray sort) << ', not committed yet.' ]
							  ifEmpty: [ stream << 'nothing to write, its files already hold what the image has.' ] ] ]
]
