"
Command that returns class metadata DTO dictionaries for class_get.
"
Class {
	#name : 'MCPGetClassCommand',
	#superclass : 'MCPToolRequestCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPGetClassCommand >> execute [

	| data subclasses superclasses targetClass |
	targetClass := tool resolvedClassNamed: request className.
	superclasses := self superclassesForClass: targetClass.
	subclasses := self subclassesForClass: targetClass.
	data := tool descriptionDictionaryForClass: targetClass includeComment: request includeComment.
	superclasses ifNotEmpty: [
		data at: #superclasses put: (tool descriptionDictionariesForClasses: superclasses includeComment: request includeComment) ].
	subclasses ifNotEmpty: [
		data at: #subclasses put: (tool descriptionDictionariesForClasses: subclasses includeComment: request includeComment) ].
	^ MCPGetClassResult
		  className: request className
		  data: data
		  superclasses: superclasses
		  subclasses: subclasses
]

{ #category : 'private' }
MCPGetClassCommand >> subclassesForClass: aClass [

	| subclasses |
	request subclassDepth = 0 ifTrue: [ ^ #(  ) ].
	subclasses := OrderedCollection new.
	aClass
		allSubclassesWithLevelDo: [ :eachClass :level |
		(level between: 1 and: request subclassDepth) ifTrue: [ subclasses add: eachClass ] ]
		startingLevel: 0.
	^ subclasses asArray
]

{ #category : 'private' }
MCPGetClassCommand >> superclassesForClass: aClass [

	| targetSuperclass targetSuperclassName |
	targetSuperclassName := request upToSuperclassName.
	targetSuperclassName ifNil: [ ^ #(  ) ].
	targetSuperclass := Smalltalk globals
		                    at: targetSuperclassName asSymbol
		                    ifAbsent: [
		                    MCPCommandError signalMissingSuperclassNamed: targetSuperclassName forClassNamed: aClass name asString ].
	^ aClass allSuperclasses asArray copyUpTo: targetSuperclass
]
