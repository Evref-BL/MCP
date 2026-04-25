"
Tests for edit-repository create/update behavior. These tests execute the tool directly so temporary Iceberg repository registry changes are not saved by the MCP RPC wrapper.
"
Class {
	#name : 'MCPToolEditRepositoryTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private - calling' }
MCPToolEditRepositoryTest >> callToolWith: someArguments [

	| request result tool |
	tool := MCPToolEditRepository new.
	request := tool requestFromToolCallArguments: someArguments.
	result := tool executeWithRequest: request.
	^ result asJRPCJSON
]

{ #category : 'private - classes' }
MCPToolEditRepositoryTest >> createClassNamed: aClassName inPackageNamed: aPackageName [

	^ self withoutEpiceaDuring: [
		  | builder |
		  builder := Object << aClassName asSymbol.
		  builder package: aPackageName.
		  builder tag: 'Generated'.
		  builder install ]
]

{ #category : 'private' }
MCPToolEditRepositoryTest >> deleteDirectoryIfExists: aFileReference [

	aFileReference exists ifTrue: [ aFileReference deleteAll ]
]

{ #category : 'private' }
MCPToolEditRepositoryTest >> directChildNamesOf: aFileReference [

	^ aFileReference exists
		  ifTrue: [
		  aFileReference children collect: [ :each | each basename ] ]
		  ifFalse: [ #(  ) ]
]

{ #category : 'private' }
MCPToolEditRepositoryTest >> newRepositoryNamed: aRepositoryName location: aFileReference packageNames: somePackageNames [

	| repository |
	repository := IceLibgitRepository new.
	repository name: aRepositoryName.
	repository location: aFileReference.
	somePackageNames do: [ :each |
		repository workingCopy addPackageNamed: each ].
	^ repository
]

{ #category : 'private' }
MCPToolEditRepositoryTest >> packageNamesIn: aRepository [

	^ aRepository workingCopy packageNames asArray asSortedCollection
		  asArray
]

{ #category : 'private' }
MCPToolEditRepositoryTest >> removeRegisteredRepositoriesNamed: aRepositoryName [

	| registry repositories |
	registry := IceRepository registry.
	repositories := registry select: [ :each |
		                each name asString = aRepositoryName ].
	repositories do: [ :each | registry remove: each ifAbsent: [  ] ]
]

{ #category : 'private' }
MCPToolEditRepositoryTest >> temporaryRepositoryLocationNamed: aName [

	^ FileLocator imageDirectory / aName
]

{ #category : 'tests' }
MCPToolEditRepositoryTest >> testCreateCreatesAndRegistersRepository [

	| data location repository repositoryName result |
	repositoryName := 'MCP Edit Repository Create Test'.
	location := self temporaryRepositoryLocationNamed:
		            'MCPToolEditRepositoryTestCreate'.
	self
		withCleanRepositoryNamed: repositoryName
		location: location
		do: [
			result := self callToolWith: {
					          (#operation -> 'create').
					          (#name -> repositoryName).
					          (#location -> location pathString).
					          (#subdirectory -> 'src').
					          (#packageNames -> #( 'MCP' 'MCP-Tests' )) }
					          asDictionary.
			data := self dataFrom: result.
			repository := IceRepository repositories detect: [ :each |
				              each name asString = repositoryName ].
			self deny: (result at: #isError ifAbsent: [ false ]).
			self
				assert: repository location pathString
				equals: location pathString.
			self assert: repository subdirectory equals: 'src'.
			self
				assert: (self packageNamesIn: repository)
				equals: #( 'MCP' 'MCP-Tests' ).
			self assert: (data at: #operation) equals: 'create'.
			self
				assert: ((data at: #repository) at: #name)
				equals: repositoryName.
			self
				assert: (data at: #packageNames)
				equals: #( 'MCP' 'MCP-Tests' ) ]
]

{ #category : 'tests' }
MCPToolEditRepositoryTest >> testExportUpdatesDiskAndIndexWithoutCommitting [

	| childNames data location packageName repository repositoryName result |
	repositoryName := 'MCP Edit Repository Export Test'.
	packageName := 'MCPToolEditRepositoryExportPackage'.
	location := self temporaryRepositoryLocationNamed:
		            'MCPToolEditRepositoryTestExport'.
	self
		withExportPackageNamed: packageName
		className: 'MCPToolEditRepositoryExportClass'
		do: [
			self
				withCleanRepositoryNamed: repositoryName
				location: location
				do: [
					self callToolWith: {
							(#operation -> 'create').
							(#name -> repositoryName).
							(#location -> location pathString).
							(#packageNames -> { packageName }) } asDictionary.
					repository := IceRepository repositories detect: [ :each |
						              each name asString = repositoryName ].
					self assert: repository headCommit isNoCommit.
					self assert: repository index isEmpty.
					result := self callToolWith: {
							          (#operation -> 'export').
							          (#repositoryName -> repositoryName) } asDictionary.
					data := self dataFrom: result.
					childNames := self directChildNamesOf: location.
					self deny: (result at: #isError ifAbsent: [ false ]).
					self assert: (data at: #operation) equals: 'export'.
					self assert: (data at: #didChange) equals: true.
					self
						assert: (data at: #changedPackageNames)
						equals: { packageName }.
					self assert: (data at: #modifiedPaths) notEmpty.
					self
						assert: (data at: #repositoryLocation)
						equals: location pathString.
					self assert:
						(childNames anySatisfy: [ :each |
							 each includesSubstring: packageName ]).
					self deny: repository index isEmpty.
					self assert: repository headCommit isNoCommit ] ]
]

{ #category : 'tests' }
MCPToolEditRepositoryTest >> testUpdateAddsPackageToWorkingCopy [

	| data packageName repository result |
	packageName := 'MCPToolEditRepositoryAddedPackage'.
	repository := self
		              newRepositoryNamed: 'MCP Edit Repository Add Test'
		              location: FileLocator imageDirectory
		              packageNames: #(  ).
	self withRegisteredRepository: repository do: [
		result := self callToolWith: {
				          (#operation -> 'update').
				          (#repositoryName -> repository name).
				          (#addPackageNames -> { packageName }) } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self
			assert: (self packageNamesIn: repository)
			equals: { packageName }.
		self assert: (data at: #operation) equals: 'update'.
		self assert: (data at: #updateActions) equals: #( 'addPackages' ).
		self assert: (data at: #addedPackageNames) equals: { packageName }.
		self assert: (data at: #removedPackageNames) equals: #(  ) ]
]

{ #category : 'tests' }
MCPToolEditRepositoryTest >> testUpdateCanReplacePackageMembership [

	| data repository result |
	repository := self
		              newRepositoryNamed: 'MCP Edit Repository Replace Test'
		              location: FileLocator imageDirectory
		              packageNames:
		              #( 'MCPToolEditRepositoryOldA'
		                 'MCPToolEditRepositoryOldB' ).
	self withRegisteredRepository: repository do: [
		result := self callToolWith: {
				          (#operation -> 'update').
				          (#repositoryName -> repository name).
				          (#packageNames
				           ->
				           #( 'MCPToolEditRepositoryNewC'
				              'MCPToolEditRepositoryOldB' )) } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self
			assert: (self packageNamesIn: repository)
			equals:
			#( 'MCPToolEditRepositoryNewC' 'MCPToolEditRepositoryOldB' ).
		self
			assert: (data at: #updateActions)
			equals: #( 'replacePackages' ).
		self
			assert: (data at: #addedPackageNames)
			equals: #( 'MCPToolEditRepositoryNewC' ).
		self
			assert: (data at: #removedPackageNames)
			equals: #( 'MCPToolEditRepositoryOldA' ) ]
]

{ #category : 'tests' }
MCPToolEditRepositoryTest >> testUpdateRemovesPackageWithoutUnloading [

	| data packageName repository result |
	packageName := 'MCPToolEditRepositoryRemovalPackage'.
	self withoutEpiceaDuring: [
		PackageOrganizer default ensurePackage: packageName ].
	[
	repository := self
		              newRepositoryNamed: 'MCP Edit Repository Remove Test'
		              location: FileLocator imageDirectory
		              packageNames: { packageName }.
	self withRegisteredRepository: repository do: [
		result := self callToolWith: {
				          (#operation -> 'update').
				          (#repositoryName -> repository name).
				          (#removePackageNames -> { packageName }) } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (self packageNamesIn: repository) equals: #(  ).
		self assert: (PackageOrganizer default hasPackage: packageName).
		self assert: (data at: #operation) equals: 'update'.
		self assert: (data at: #updateActions) equals: #( 'removePackages' ).
		self assert: (data at: #addedPackageNames) equals: #(  ).
		self assert: (data at: #removedPackageNames) equals: { packageName } ] ]
		ensure: [ self removePackageNamed: packageName ]
]

{ #category : 'private - calling' }
MCPToolEditRepositoryTest >> toolName [

	^ 'edit-repository'
]

{ #category : 'private' }
MCPToolEditRepositoryTest >> withCleanRepositoryNamed: aRepositoryName location: aFileReference do: aBlock [

	[
	self removeRegisteredRepositoriesNamed: aRepositoryName.
	self deleteDirectoryIfExists: aFileReference.
	aBlock value ] ensure: [
		self removeRegisteredRepositoriesNamed: aRepositoryName.
		self deleteDirectoryIfExists: aFileReference ]
]

{ #category : 'private - classes' }
MCPToolEditRepositoryTest >> withExportPackageNamed: aPackageName className: aClassName do: aBlock [

	[
	self removeClassNamed: aClassName.
	self removePackageNamed: aPackageName.
	self createClassNamed: aClassName inPackageNamed: aPackageName.
	aBlock value ] ensure: [
		self removeClassNamed: aClassName.
		self removePackageNamed: aPackageName ]
]

{ #category : 'private' }
MCPToolEditRepositoryTest >> withRegisteredRepository: aRepository do: aBlock [

	| registry |
	registry := IceRepository registry.
	registry add: aRepository.
	[ aBlock value ] ensure: [
		registry remove: aRepository ifAbsent: [  ] ]
]
