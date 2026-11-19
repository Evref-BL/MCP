"
Answers a class or trait as its Tonel file, a page at a time: offset 0 is the comment and definition, as the file opens, and offset n starts at the nth method, so the pages put end to end are the file. A class's superclasses and subclasses are class_search's, through its scope.
"
Class {
	#name : 'MCPToolGetClass',
	#superclass : 'MCPTool',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolGetClass class >> groupName [

	^ self classesGroupName
]

{ #category : 'metadata' }
MCPToolGetClass class >> toolName [

	^ 'class_get'
]

{ #category : 'metadata' }
MCPToolGetClass >> annotations [

	^ MCPStructureToolAnnotations readOnly
]

{ #category : 'metadata' }
MCPToolGetClass >> batchArgumentName [

	^ 'name'
]

{ #category : 'metadata' }
MCPToolGetClass >> batchSummaryNoun [

	^ 'classes'
]

{ #category : 'metadata' }
MCPToolGetClass >> batchSummaryVerb [

	^ 'Got'
]

{ #category : 'metadata' }
MCPToolGetClass >> buildInputSchema [

	^ MCPStructureInputSchema
		  properties: {
				  (self stringOrArraySchemaNamed: 'name' description: 'Class name, or several class names.' itemDescription: 'Class name.').
				  self offsetInputProperty }
		  required: #( 'name' )
]

{ #category : 'metadata' }
MCPToolGetClass >> defaultExposure [

	^ 'static'
]

{ #category : 'metadata' }
MCPToolGetClass >> defaultPageLimit [
	"How many methods a page after the definition holds at most. A page also keeps within pageCharacterLimit, so a page of long methods holds fewer."

	^ 50
]

{ #category : 'private - source' }
MCPToolGetClass >> definitionDictionaryForClass: aClass [
	"The first page: the comment and the definition, as the class's Tonel file opens, and how many methods the pages after it hold on each side. What other packages add to the class is in their own files, so it is counted and their names given instead. No file holds the users of a trait, so they come beside it."

	| data extensions methods |
	methods := self tonelMethodDefinitionsOf: aClass.
	data := Dictionary new.
	data
		at: #class put: aClass name asString;
		at: #source put: (self tonelTextOf: aClass asClassDefinition methods: #(  ));
		at: #methods put: (methods count: [ :each | each classIsMeta not ]);
		at: #classMethods put: (methods count: [ :each | each classIsMeta ]).
	aClass isTrait ifTrue: [
			data at: #isTrait put: true.
			(self userNamesOf: aClass) ifNotEmpty: [ :names | data at: #users put: names ] ].
	extensions := self extensionMethodsOf: aClass.
	extensions ifNotEmpty: [
			data
				at: #extensionMethods put: extensions size;
				at: #extensionPackages put: (extensions collect: [ :each | each package name asString ] as: Set) asArray sort ].
	methods ifNotEmpty: [ data at: #nextOffset put: 1 ].
	^ data
]

{ #category : 'private - results' }
MCPToolGetClass >> definitionSummaryForClass: aClass data: data [
	"What the first page holds, how many methods the pages after it hold, what the file leaves out, and where the methods start."

	^ String streamContents: [ :stream |
			  stream << 'Got the definition of ' << (self kindAndNameOf: aClass) << ', as its Tonel file opens.'.
			  self methodCountSummaryOn: stream instanceSide: (data at: #methods) classSide: (data at: #classMethods).
			  data at: #extensionMethods ifPresent: [ :count |
					  self
						  extensionSummaryOn: stream
						  of: aClass
						  methodCount: count
						  packageCount: (data at: #extensionPackages) size ].
			  data at: #nextOffset ifPresent: [ :nextOffset | stream << ' Next page: offset ' << nextOffset printString << '.' ] ]
]

{ #category : 'metadata' }
MCPToolGetClass >> description [

	^ 'Get classes or traits by name as their Tonel files, a page at a time. Offset 0 answers the comment and definition (superclass, slots, traits, variables, pools, package), later offsets the methods of both sides. class_search lists superclasses and subclasses.'
]

{ #category : 'private' }
MCPToolGetClass >> errorResultForError: anError className: className [

	^ anError
		  mcpCommandErrorDo: [ :commandError | self errorResultText: commandError messageText details: commandError structuredDetails ]
		  otherwise: [ :toolError |
				  self errorResultText: (self failureMessageForClassName: className error: toolError) details: {
						  (#errorClass -> toolError class name).
						  (#message -> toolError messageText).
						  (#class -> className) } asDictionary ]
]

{ #category : 'executing' }
MCPToolGetClass >> executeWithRequest: request [
	"An error names the class as the name argument gives it, the same name before and after it is checked."

	^ self executeBatchedRequest: request do: [ :targetRequest |
			  self
				  executeRequest: targetRequest
				  do: [ self getClassWith: targetRequest ]
				  onError: [ :error | self errorResultForError: error className: ((targetRequest stringArgumentNamed: 'name') ifNil: [ '' ]) ] ]
]

{ #category : 'private - source' }
MCPToolGetClass >> extensionMethodsOf: aClass [
	"The methods other packages add to the class, on either side. Each is in the file of the package that adds it, so the class's file leaves it out."

	^ aClass instanceSide localMethods , aClass classSide localMethods reject: [ :each | self isMethod: each filedWith: aClass ]
]

{ #category : 'private - results' }
MCPToolGetClass >> extensionSummaryOn: aStream of: aClass methodCount: methodCount packageCount: packageCount [
	"A method another package adds to the class is in that package's file, so the class's file leaves it out. The extensionPackages line names the packages, and an extension method's protocol is the star and the name of its package, which method_search matches."

	aStream
		nextPutAll: ' The file leaves out ';
		nextPutAll: (self textForCount: methodCount noun: 'method');
		nextPutAll: ' that ';
		nextPutAll: (packageCount = 1
				 ifTrue: [ 'another package adds' ]
				 ifFalse: [ (self textForCount: packageCount noun: 'other package') , ' add' ]);
		nextPutAll: ' to ';
		nextPutAll: (self kindAndNameOf: aClass);
		nextPutAll: (packageCount = 1
				 ifTrue: [ ', in that package''s own file.' ]
				 ifFalse: [ ', each in its own package''s file.' ]);
		nextPutAll: ' method_search with protocol "*" and scope.classes lists ';
		nextPutAll: (methodCount = 1
				 ifTrue: [ 'it.' ]
				 ifFalse: [ 'them.' ])
]

{ #category : 'private' }
MCPToolGetClass >> failureMessageForClassName: className error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to get class ';
				  nextPutAll: className;
				  nextPutAll: ' (';
				  nextPutAll: anError class name;
				  nextPutAll: '): ';
				  nextPutAll: anError messageText ]
]

{ #category : 'private - execution' }
MCPToolGetClass >> getClassWith: request [
	"The class's Tonel file, a page at a time: offset 0 is its comment and definition, and offset n starts at its nth method. The answer names the class found, not the name asked for: Foo class reads as Foo. Every page says what the image lost of the class since its last save."

	| data offset summary targetClass |
	targetClass := MCPImageLookup classNamed: (request stringArgumentNamed: 'name').
	offset := request integerArgumentNamed: 'offset'.
	data := offset = 0
		        ifTrue: [ self definitionDictionaryForClass: targetClass ]
		        ifFalse: [ self methodsDictionaryForClass: targetClass from: offset ].
	summary := offset = 0
		           ifTrue: [ self definitionSummaryForClass: targetClass data: data ]
		           ifFalse: [ self methodsSummaryForClass: targetClass data: data from: offset ].
	^ self
		  successResultText: (MCPToolListLostChanges
				   summary: summary
				   notingLostChangesToPackagesNamed: #(  )
				   classesNamed: { targetClass instanceSide name asString })
		  data: data
]

{ #category : 'private - source' }
MCPToolGetClass >> isMethod: aMethod filedWith: aClass [
	"Whether the class's own Tonel file holds the method, which it does when the method's package is the class's. A method with no package of its own is the class's."

	^ (aMethod package ifNil: [ aClass package ]) = aClass package
]

{ #category : 'private - results' }
MCPToolGetClass >> keyOrder [
	"The users of a trait and the packages that add to the class are short lists, read before the file's text."

	^ #( users extensionPackages )
]

{ #category : 'private - results' }
MCPToolGetClass >> keysStatedInSummary [
	"The summary opens with the class name and says whether it is a trait, how many methods its file holds on each side, which methods the page holds, how many methods other packages add, and where the next page starts."

	^ #( class isTrait methods classMethods pagination nextOffset extensionMethods )
]

{ #category : 'private - results' }
MCPToolGetClass >> kindAndNameOf: aClass [
	"class Foo or trait Foo, as an answer names it: a trait is not a class."

	^ (aClass isTrait
		   ifTrue: [ 'trait ' ]
		   ifFalse: [ 'class ' ]) , aClass name
]

{ #category : 'private - results' }
MCPToolGetClass >> methodCountSummaryOn: aStream instanceSide: instanceCount classSide: classCount [
	"How many methods the class's file holds, and on which side: 3 methods, 2 on the instance side and 1 on the class side."

	| sides |
	instanceCount + classCount = 0 ifTrue: [ ^ aStream << ' Its file holds no methods.' ].
	sides := OrderedCollection new.
	instanceCount > 0 ifTrue: [ sides add: instanceCount printString , ' on the instance side' ].
	classCount > 0 ifTrue: [ sides add: classCount printString , ' on the class side' ].
	aStream << ' Its file holds ' << (self textForCount: instanceCount + classCount noun: 'method') << ', ' << (' and ' join: sides)
	<< '.'
]

{ #category : 'private - source' }
MCPToolGetClass >> methodsDictionaryForClass: aClass from: anOffset [
	"A page of the methods of the class's Tonel file, from its anOffset-th method on: what the file writes for them after its definition, so the pages put end to end after the first are the rest of the file."

	| data definition methods page pagination source |
	definition := aClass asClassDefinition.
	methods := self tonelMethodDefinitionsOf: aClass.
	page := MCPPaginationResult
		        fromEntries: methods
		        limit: (self tonelMethodCountFrom: anOffset of: methods in: definition)
		        offset: anOffset - 1.
	pagination := page paginationDictionary.
	data := Dictionary new.
	data
		at: #class put: aClass name asString;
		at: #pagination put: pagination.
	aClass isTrait ifTrue: [ data at: #isTrait put: true ].
	page entries ifNotEmpty: [ :entries |
			source := (self tonelTextOf: definition methods: entries) allButFirst: (self tonelTextOf: definition methods: #(  )) size.
			data at: #source put: source ].
	page nextOffset ifNotNil: [ :index |
			pagination at: #nextOffset put: index + 1.
			data at: #nextOffset put: index + 1 ].
	^ data
]

{ #category : 'private - results' }
MCPToolGetClass >> methodsSummaryForClass: aClass data: data from: anOffset [
	"Which methods the page holds of the class's Tonel file, or that there are none from anOffset, and where the next page starts."

	| name pagination returned total |
	name := self kindAndNameOf: aClass.
	pagination := data at: #pagination.
	returned := pagination at: #returnedCount.
	total := pagination at: #totalCount.
	^ String streamContents: [ :stream |
			  returned = 0
				  ifTrue: [
						  stream << 'No methods from offset ' << anOffset printString << ': the Tonel file of ' << name << ' holds '
						  << (self textForCount: total noun: 'method') << '.' ]
				  ifFalse: [
						  stream << 'Got ' << (self tonelMethodRangeFrom: anOffset count: returned) << ' of ' << total printString
						  << ' in the Tonel file of ' << name << '.' ].
			  data at: #nextOffset ifPresent: [ :nextOffset | stream << ' Next page: offset ' << nextOffset printString << '.' ] ]
]

{ #category : 'metadata' }
MCPToolGetClass >> pageCharacterLimit [
	"How many characters of a class's Tonel file a page of methods holds at most, so that a large class comes in pages a model's context holds several of. A method longer than that still comes, alone on its page, since a page holds at least one method."

	^ 10000
]

{ #category : 'metadata' }
MCPToolGetClass >> title [

	^ 'Get Class'
]

{ #category : 'private - source' }
MCPToolGetClass >> tonelMethodCountFrom: anOffset of: someMethodDefinitions in: aClassDefinition [
	"How many methods the page from the anOffset-th method holds: up to defaultPageLimit, and as many as keep its text within pageCharacterLimit, but at least one, so a method longer than a page is read too. A method adds to the file what the writer writes for it after the definition."

	| count opening size |
	count := 0.
	size := 0.
	opening := (self tonelTextOf: aClassDefinition methods: #(  )) size.
	someMethodDefinitions from: anOffset to: (someMethodDefinitions size min: anOffset + self defaultPageLimit - 1) do: [ :each |
			size := size + (self tonelTextOf: aClassDefinition methods: { each }) size - opening.
			(count > 0 and: [ size > self pageCharacterLimit ]) ifTrue: [ ^ count ].
			count := count + 1 ].
	^ count
]

{ #category : 'private - source' }
MCPToolGetClass >> tonelMethodDefinitionsOf: aClass [
	"The methods the class's file holds, in the order the Tonel writer writes them: the class side, then the instance side, each by selector. A method a trait gives is the trait's, and one another package adds is in that package's file."

	| definitions |
	definitions := OrderedCollection new.
	{
		aClass classSide.
		aClass instanceSide } do: [ :side |
			definitions addAll:
				((side localMethods
					  select: [ :each | self isMethod: each filedWith: aClass ]
					  thenCollect: [ :each | each asMCMethodDefinition ]) asArray sort: [ :left :right | left selector < right selector ]) ].
	^ definitions asArray
]

{ #category : 'private - results' }
MCPToolGetClass >> tonelMethodRangeFrom: aFirstIndex count: aCount [
	"Which methods a page holds, counting from one: methods 3 to 7, or method 3 when it holds one, as a page of long methods may."

	aCount = 1 ifTrue: [ ^ 'method ' , aFirstIndex printString ].
	^ 'methods {1} to {2}' format: {
			  aFirstIndex.
			  (aFirstIndex + aCount - 1) }
]

{ #category : 'private - source' }
MCPToolGetClass >> tonelTextOf: aClassDefinition methods: someMethodDefinitions [
	"What Pharo's Tonel writer writes for the class holding these methods, which is what an export writes in its file."

	| writer |
	writer := TonelWriter new.
	writer snapshot: (MCSnapshot fromDefinitions: { aClassDefinition } , someMethodDefinitions).
	^ String streamContents: [ :stream | writer writeClass: aClassDefinition on: stream ]
]

{ #category : 'private - source' }
MCPToolGetClass >> userNamesOf: aTrait [
	"The classes using the trait, which is what a trait has instead of subclasses, by name."

	^ (aTrait users collect: [ :each | each instanceSide name asString ] as: Array) sort
]
