"
The JSON file format of the spans the call graph reads: { format, version, spans: [ { name, spanId, parentSpanId, startTime, endTime, status, attributes } ] }, times in ISO 8601, status one of error, ok or unset. It writes the snapshots of a span store and reads them back as MCPOcelRecordedSpan.
"
Class {
	#name : 'MCPOcelSpanArchive',
	#superclass : 'Object',
	#category : 'MCP-OpenTelemetry',
	#package : 'MCP-OpenTelemetry'
}

{ #category : 'writing' }
MCPOcelSpanArchive class >> dictionaryFor: aSpanSnapshot [
	"What a MCPOcelLog reads of a span, and nothing else."

	| attributes |
	attributes := Dictionary new.
	aSpanSnapshot attributes keysAndValuesDo: [ :key :value | attributes at: key asString put: (self jsonValueOf: value) ].
	^ Dictionary new
		  at: 'name' put: aSpanSnapshot name;
		  at: 'spanId' put: aSpanSnapshot spanId;
		  at: 'parentSpanId' put: (aSpanSnapshot parentSpanContext ifNotNil: [ :context | context spanId ]);
		  at: 'startTime' put: aSpanSnapshot startTime printString;
		  at: 'endTime' put: aSpanSnapshot endTime printString;
		  at: 'status' put: (self statusNameOf: aSpanSnapshot status);
		  at: 'attributes' put: attributes;
		  yourself
]

{ #category : 'constants' }
MCPOcelSpanArchive class >> formatName [

	^ 'mcp-ocel-spans'
]

{ #category : 'writing' }
MCPOcelSpanArchive class >> jsonFor: someSpanSnapshots [
	"The file text of these spans."

	^ STONJSON toStringPretty: (Dictionary new
			   at: 'format' put: self formatName;
			   at: 'version' put: 1;
			   at: 'spans' put: (someSpanSnapshots collect: [ :snapshot | self dictionaryFor: snapshot ]) asArray;
			   yourself)
]

{ #category : 'writing' }
MCPOcelSpanArchive class >> jsonValueOf: anAttributeValue [
	"Strings, numbers and booleans as they are, lists of them, and anything else as its text."

	^ (anAttributeValue isString or: [ anAttributeValue isNumber or: [ anAttributeValue == true or: [ anAttributeValue == false ] ] ])
		  ifTrue: [ anAttributeValue ]
		  ifFalse: [
				  anAttributeValue isArray
					  ifTrue: [ anAttributeValue collect: [ :each | self jsonValueOf: each ] ]
					  ifFalse: [ anAttributeValue printString ] ]
]

{ #category : 'files' }
MCPOcelSpanArchive class >> readSpansFrom: aFileReference [

	^ self spansFromJson: (aFileReference readStreamEncoded: 'utf-8' do: [ :stream | stream upToEnd ])
]

{ #category : 'reading' }
MCPOcelSpanArchive class >> spanFrom: aDictionary [

	^ MCPOcelRecordedSpan new
		  name: (aDictionary at: 'name')
		  spanId: (aDictionary at: 'spanId')
		  parentSpanId: (aDictionary at: 'parentSpanId' ifAbsent: [ nil ])
		  startTime: (DateAndTime fromString: (aDictionary at: 'startTime'))
		  endTime: (DateAndTime fromString: (aDictionary at: 'endTime'))
		  status: (self statusFrom: (aDictionary at: 'status' ifAbsent: [ 'unset' ]))
		  attributes: (OrderedDictionary newFrom: (aDictionary at: 'attributes' ifAbsent: [ Dictionary new ]));
		  yourself
]

{ #category : 'reading' }
MCPOcelSpanArchive class >> spansFromJson: aString [
	"The spans a file text holds, as MCPOcelRecordedSpan, whether it is of this format or OCEL 2.0. An Error says why a text is not one."

	| root |
	root := [ STONJSON fromString: aString ]
		        on: Error
		        do: [ :error | self error: 'Not a JSON file: ' , error messageText ].
	(MCPOcel2Archive isOcelRoot: root) ifTrue: [ ^ MCPOcel2Archive spansFromRoot: root ].
	(root isDictionary and: [ (root at: 'format' ifAbsent: [ nil ]) = self formatName ]) ifFalse: [
		self error: 'Neither a file of spans nor an OCEL 2.0 file' ].
	^ (root at: 'spans' ifAbsent: [ #(  ) ]) collect: [ :each | self spanFrom: each ]
]

{ #category : 'reading' }
MCPOcelSpanArchive class >> statusFrom: aName [

	aName = 'error' ifTrue: [ ^ OTSpan error ].
	aName = 'ok' ifTrue: [ ^ OTSpan ok ].
	^ OTSpan unset
]

{ #category : 'writing' }
MCPOcelSpanArchive class >> statusNameOf: aStatus [

	aStatus = OTSpan error ifTrue: [ ^ 'error' ].
	aStatus = OTSpan ok ifTrue: [ ^ 'ok' ].
	^ 'unset'
]

{ #category : 'files' }
MCPOcelSpanArchive class >> write: someSpanSnapshots to: aFileReference [
	"Writes the file, replacing one of that name."

	aFileReference ensureDelete.
	aFileReference writeStreamEncoded: 'utf-8' do: [ :stream | stream nextPutAll: (self jsonFor: someSpanSnapshots) ].
	^ aFileReference
]

{ #category : 'files' }
MCPOcelSpanArchive class >> writeOcel2: someSpanSnapshots to: aFileReference [
	"The log of these spans in OCEL 2.0, replacing a file of that name."

	aFileReference ensureDelete.
	aFileReference
		writeStreamEncoded: 'utf-8'
		do: [ :stream | stream nextPutAll: (MCPOcel2Archive jsonFor: (MCPOcelLog fromSpanSnapshots: someSpanSnapshots)) ].
	^ aFileReference
]
