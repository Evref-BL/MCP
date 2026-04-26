"
DTO for registered Iceberg repository metadata.

It is read-only and intended for find-repositories responses. The DTO normalizes repository state that may come from different Iceberg repository implementations and keeps tool output independent from Iceberg objects.
"
Class {
	#name : 'MCPRepositoryInfo',
	#superclass : 'Object',
	#instVars : [
		'name',
		'className',
		'location',
		'subdirectory',
		'branchName',
		'headDescription',
		'isMissing',
		'isModified',
		'packageNames',
		'modifiedPackageNames',
		'remoteNames'
	],
	#category : 'MCP-DTOs',
	#package : 'MCP',
	#tag : 'DTOs'
}

{ #category : 'instance creation' }
MCPRepositoryInfo class >> fromRepository: aRepository [

	^ self new initializeFromRepository: aRepository
]

{ #category : 'converting' }
MCPRepositoryInfo >> asDictionary [

	^ {
		  (#name -> self name).
		  (#className -> self className).
		  (#location -> self location).
		  (#subdirectory -> self subdirectory).
		  (#branchName -> self branchName).
		  (#headDescription -> self headDescription).
		  (#isMissing -> self isMissing).
		  (#isModified -> self isModified).
		  (#packageNames -> self packageNames).
		  (#modifiedPackageNames -> self modifiedPackageNames).
		  (#remoteNames -> self remoteNames) } asDictionary
]

{ #category : 'converting' }
MCPRepositoryInfo >> asQueryDictionary [

	^ self asDictionary
]

{ #category : 'private' }
MCPRepositoryInfo >> booleanFrom: aBlock default: defaultBoolean [

	^ [ aBlock value ifNil: [ defaultBoolean ] ]
		  on: Error
		  do: [ :ignored | defaultBoolean ]
]

{ #category : 'accessing' }
MCPRepositoryInfo >> branchName [

	^ branchName
]

{ #category : 'accessing' }
MCPRepositoryInfo >> className [

	^ className
]

{ #category : 'accessing' }
MCPRepositoryInfo >> headDescription [

	^ headDescription
]

{ #category : 'initialization' }
MCPRepositoryInfo >> initializeFromRepository: aRepository [

	name := self stringFrom: [ aRepository name ] default: ''.
	className := aRepository class name asString.
	location := self repositoryLocationFor: aRepository.
	subdirectory := self repositorySubdirectoryFor: aRepository.
	branchName := self stringFrom: [ aRepository branchName ] default: ''.
	headDescription := self
		                   stringFrom: [ aRepository headDescription ]
		                   default: ''.
	isMissing := self
		             booleanFrom: [
			             (aRepository respondsTo: #isMissing)
				             ifTrue: [ aRepository isMissing ]
				             ifFalse: [ false ] ]
		             default: false.
	isModified := self
		              booleanFrom: [ aRepository isModified ]
		              default: false.
	packageNames := self repositoryPackageNamesFor: aRepository.
	modifiedPackageNames := self repositoryModifiedPackageNamesFor:
		                        aRepository.
	remoteNames := self repositoryRemoteNamesFor: aRepository.
	^ self
]

{ #category : 'accessing' }
MCPRepositoryInfo >> isMissing [

	^ isMissing
]

{ #category : 'accessing' }
MCPRepositoryInfo >> isModified [

	^ isModified
]

{ #category : 'accessing' }
MCPRepositoryInfo >> location [

	^ location
]

{ #category : 'accessing' }
MCPRepositoryInfo >> modifiedPackageNames [

	^ modifiedPackageNames
]

{ #category : 'accessing' }
MCPRepositoryInfo >> name [

	^ name
]

{ #category : 'accessing' }
MCPRepositoryInfo >> packageNames [

	^ packageNames
]

{ #category : 'accessing' }
MCPRepositoryInfo >> remoteNames [

	^ remoteNames
]

{ #category : 'private' }
MCPRepositoryInfo >> repositoryLocationFor: aRepository [

	^ self
		  stringFrom: [
			  (aRepository respondsTo: #location)
				  ifTrue: [ aRepository location ]
				  ifFalse: [ '' ] ]
		  default: ''
]

{ #category : 'private' }
MCPRepositoryInfo >> repositoryModifiedPackageNamesFor: aRepository [

	^ self sortedStringsFrom: [
		  (aRepository respondsTo: #modifiedPackages)
			  ifTrue: [
			  aRepository modifiedPackages collect: [ :each | each name ] ]
			  ifFalse: [ #(  ) ] ]
]

{ #category : 'private' }
MCPRepositoryInfo >> repositoryPackageNamesFor: aRepository [

	^ self sortedStringsFrom: [
		  (aRepository respondsTo: #workingCopy)
			  ifTrue: [ aRepository workingCopy packageNames ]
			  ifFalse: [ #(  ) ] ]
]

{ #category : 'private' }
MCPRepositoryInfo >> repositoryRemoteNamesFor: aRepository [

	^ self sortedStringsFrom: [
		  (aRepository respondsTo: #remotes)
			  ifTrue: [ aRepository remotes collect: [ :each | each name ] ]
			  ifFalse: [ #(  ) ] ]
]

{ #category : 'private' }
MCPRepositoryInfo >> repositorySubdirectoryFor: aRepository [

	^ self
		  stringFrom: [
			  (aRepository respondsTo: #subdirectory)
				  ifTrue: [ aRepository subdirectory ]
				  ifFalse: [ '' ] ]
		  default: ''
]

{ #category : 'private' }
MCPRepositoryInfo >> sortedStringsFrom: aBlock [

	| normalized values |
	values := [ aBlock value ifNil: [ #(  ) ] ]
		          on: Error
		          do: [ :ignored | #(  ) ].
	normalized := OrderedCollection new.
	values do: [ :each |
		| string |
		string := self stringValue: each default: ''.
		string isEmpty ifFalse: [ normalized add: string ] ].
	^ normalized asArray asSortedCollection asArray
]

{ #category : 'private' }
MCPRepositoryInfo >> stringFrom: aBlock default: defaultString [

	^ [ self stringValue: aBlock value default: defaultString ]
		  on: Error
		  do: [ :ignored | defaultString ]
]

{ #category : 'private' }
MCPRepositoryInfo >> stringValue: aValue default: defaultString [

	aValue ifNil: [ ^ defaultString ].
	(aValue respondsTo: #pathString) ifTrue: [
		^ aValue pathString asString ].
	^ aValue asString
]

{ #category : 'accessing' }
MCPRepositoryInfo >> subdirectory [

	^ subdirectory
]
