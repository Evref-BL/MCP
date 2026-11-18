"
A lost change to the comment of one class or trait. Its states are the comment texts; the stamp of the last one is installed with it.
"
Class {
	#name : 'MCPLostCommentChange',
	#superclass : 'MCPLostChange',
	#instVars : [
		'className',
		'targetStamp'
	],
	#category : 'MCP-IDE-Queries',
	#package : 'MCP-IDE',
	#tag : 'Queries'
}

{ #category : 'instance creation' }
MCPLostCommentChange class >> className: aClassName saved: aComment [
	"The change to the comment of aClassName, which was aComment at the save."

	^ self new
		  setClassName: aClassName;
		  savedState: aComment;
		  yourself
]

{ #category : 'converting' }
MCPLostCommentChange >> addTargetTo: aDictionary [

	aDictionary at: #comment put: targetState
]

{ #category : 'accessing' }
MCPLostCommentChange >> affectedClassName [

	^ className
]

{ #category : 'updating' }
MCPLostCommentChange >> becomes: aComment stamped: aStamp at: anInteger [

	targetStamp := aStamp.
	self becomes: aComment at: anInteger
]

{ #category : 'accessing' }
MCPLostCommentChange >> changeDescription [

	^ 'comment changed'
]

{ #category : 'accessing' }
MCPLostCommentChange >> element [
	"A comment is restored with its class's definition, under the class's name."

	^ className
]

{ #category : 'testing' }
MCPLostCommentChange >> imageHolds: aComment [
	"A class the image lacks holds no comment, not even the one a lost change gave it."

	^ self imageClassIfPresent: [ :class | class comment = aComment ] ifAbsent: [ false ]
]

{ #category : 'testing' }
MCPLostCommentChange >> imageHoldsSavedState [
	"A comment cannot conflict with a class the image lacks: the lost sessions may have added the class, and restoring its definition first brings it back."

	^ self imageClassIfPresent: [ :class | class comment = savedState ] ifAbsent: [ true ]
]

{ #category : 'converting' }
MCPLostCommentChange >> imageVersionIfPresent: presentBlock ifAbsent: absentBlock [

	^ self imageClassIfPresent: [ :class | presentBlock value: class comment ] ifAbsent: absentBlock
]

{ #category : 'restoring' }
MCPLostCommentChange >> restoreIfImpossible: aBlock [

	self
		imageClassIfPresent: [ :class | class comment: targetState stamp: targetStamp ]
		ifAbsent: [ aBlock value: (String streamContents: [ :stream | stream << 'Its class ' << className << ' is not in the image.' ]) ]
]

{ #category : 'restoring' }
MCPLostCommentChange >> restorePhase [

	^ 3
]

{ #category : 'initialization' }
MCPLostCommentChange >> setClassName: aClassName [

	className := aClassName asString
]
