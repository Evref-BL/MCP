"
Command that inspects class metadata and returns DTO dictionaries for inspect-class.
"
Class {
	#name : 'MCPInspectClassCommand',
	#superclass : 'Object',
	#instVars : [
		'request',
		'tool'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPInspectClassCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'executing' }
MCPInspectClassCommand >> execute [

	| data subclasses superclasses targetClass |
	targetClass := tool resolvedClassNamed: request className.
	superclasses := self superclassesForClass: targetClass.
	subclasses := self subclassesForClass: targetClass.
	data := tool
		        descriptionDictionaryForClass: targetClass
		        includeComment: request includeComment.
	data at: #superclasses put: (tool
			 descriptionDictionariesForClasses: superclasses
			 includeComment: request includeComment).
	data at: #subclasses put: (tool
			 descriptionDictionariesForClasses: subclasses
			 includeComment: request includeComment).
	^ MCPInspectClassResult
		  className: request className
		  data: data
		  superclasses: superclasses
		  subclasses: subclasses
]

{ #category : 'initialization' }
MCPInspectClassCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'accessing' }
MCPInspectClassCommand >> request [

	^ request
]

{ #category : 'private' }
MCPInspectClassCommand >> subclassesForClass: aClass [

	| subclasses |
	request subclassDepth = 0 ifTrue: [ ^ #(  ) ].
	subclasses := OrderedCollection new.
	aClass
		allSubclassesWithLevelDo: [ :eachClass :level |
			(level between: 1 and: request subclassDepth) ifTrue: [
				subclasses add: eachClass ] ]
		startingLevel: 0.
	^ subclasses asArray
]

{ #category : 'private' }
MCPInspectClassCommand >> superclassesForClass: aClass [

	| targetSuperclass targetSuperclassName |
	targetSuperclassName := request upToSuperclassName.
	targetSuperclassName ifNil: [ ^ #(  ) ].
	targetSuperclass := Smalltalk globals
		                    at: targetSuperclassName asSymbol
		                    ifAbsent: [
			                    MCPCommandError
				                    signalMissingSuperclassNamed:
				                    targetSuperclassName
				                    forClassNamed: aClass name asString ].
	^ aClass allSuperclasses asArray copyUpTo: targetSuperclass
]

{ #category : 'accessing' }
MCPInspectClassCommand >> tool [

	^ tool
]
