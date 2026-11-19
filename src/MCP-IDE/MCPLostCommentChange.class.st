"
A lost change to the comment of one class or trait. Its states are the comment texts; the stamp of the last one is installed with it.
"
Class {
	#name : 'MCPLostCommentChange',
	#superclass : 'MCPLostChange',
	#instVars : [
		'targetStamp'
	],
	#category : 'MCP-IDE-Queries',
	#package : 'MCP-IDE',
	#tag : 'Queries'
}

{ #category : 'converting' }
MCPLostCommentChange >> addTargetTo: aDictionary [

	aDictionary at: #comment put: targetState
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
		ifAbsent: [
		aBlock value: (String streamContents: [ :stream | stream << 'Its class ' << affectedClassName << ' is not in the image.' ]) ]
]

{ #category : 'restoring' }
MCPLostCommentChange >> restorePhase [

	^ 3
]
