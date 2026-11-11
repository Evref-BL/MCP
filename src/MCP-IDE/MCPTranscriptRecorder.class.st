"
I stand in for Transcript while an evaluation runs, so its caller, who cannot see a Transcript window, gets back what it wrote there. Every write also goes on to the Transcript I replaced, through nextPutAll: and cr, which every Transcript understands.

I keep at most limit characters, with line ends as line feeds, and say when I dropped some. Afterwards I put the Transcript back only if I am still the one installed. When two evaluations overlap, the one that finishes last may be holding the other's recorder as the Transcript it replaced; a finished recorder is not put back, the Transcript it replaced is.
"
Class {
	#name : 'MCPTranscriptRecorder',
	#superclass : 'Object',
	#instVars : [
		'replaced',
		'contents',
		'limit',
		'truncated',
		'finished'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPTranscriptRecorder class >> limit: anInteger [

	^ self new limit: anInteger
]

{ #category : 'streaming' }
MCPTranscriptRecorder >> << anObject [

	self nextPutAll: anObject asString
]

{ #category : 'streaming' }
MCPTranscriptRecorder >> clear [

	contents := WriteStream on: String new.
	truncated := false
]

{ #category : 'accessing' }
MCPTranscriptRecorder >> contents [

	^ contents contents
]

{ #category : 'streaming' }
MCPTranscriptRecorder >> cr [

	self record: (String with: Character lf).
	replaced cr
]

{ #category : 'streaming' }
MCPTranscriptRecorder >> crShow: anObject [

	self
		cr;
		show: anObject
]

{ #category : 'streaming' }
MCPTranscriptRecorder >> critical: aBlock [

	^ aBlock value
]

{ #category : 'streaming' }
MCPTranscriptRecorder >> display: anObject [

	self nextPutAll: anObject displayString
]

{ #category : 'streaming' }
MCPTranscriptRecorder >> endEntry [

	replaced endEntry
]

{ #category : 'recording' }
MCPTranscriptRecorder >> finish [

	finished := true.
	(Smalltalk globals at: #Transcript) == self ifTrue: [ Smalltalk globals at: #Transcript put: replaced mcpTranscriptToRestore ]
]

{ #category : 'streaming' }
MCPTranscriptRecorder >> flush [

	replaced endEntry
]

{ #category : 'initialization' }
MCPTranscriptRecorder >> initialize [

	super initialize.
	finished := false.
	self clear
]

{ #category : 'accessing' }
MCPTranscriptRecorder >> isTruncated [

	^ truncated
]

{ #category : 'streaming' }
MCPTranscriptRecorder >> lf [

	self cr
]

{ #category : 'initialization' }
MCPTranscriptRecorder >> limit: anInteger [

	limit := anInteger
]

{ #category : 'accessing' }
MCPTranscriptRecorder >> mcpTranscriptToRestore [

	^ finished
		  ifTrue: [ replaced mcpTranscriptToRestore ]
		  ifFalse: [ self ]
]

{ #category : 'streaming' }
MCPTranscriptRecorder >> newLine [

	self cr
]

{ #category : 'streaming' }
MCPTranscriptRecorder >> nextPut: aCharacter [

	self nextPutAll: (String with: aCharacter)
]

{ #category : 'streaming' }
MCPTranscriptRecorder >> nextPutAll: aString [

	self record: aString.
	replaced nextPutAll: aString
]

{ #category : 'streaming' }
MCPTranscriptRecorder >> print: anObject [

	self nextPutAll: (String streamContents: [ :stream | stream print: anObject ])
]

{ #category : 'recording' }
MCPTranscriptRecorder >> record: aString [

	| room |
	room := limit - contents position.
	room >= aString size ifTrue: [ ^ contents nextPutAll: aString ].
	truncated := true.
	room > 0 ifTrue: [ contents nextPutAll: (aString first: room) ]
]

{ #category : 'recording' }
MCPTranscriptRecorder >> recordDuring: aBlock [

	replaced := Smalltalk globals at: #Transcript.
	Smalltalk globals at: #Transcript put: self.
	^ aBlock ensure: [ self finish ]
]

{ #category : 'streaming' }
MCPTranscriptRecorder >> show: anObject [

	self nextPutAll: anObject asString
]

{ #category : 'streaming' }
MCPTranscriptRecorder >> space [

	self nextPut: Character space
]

{ #category : 'streaming' }
MCPTranscriptRecorder >> tab [

	self nextPut: Character tab
]
