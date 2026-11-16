"
Returns structured metadata for one class, with optional superclass and subclass context. It is meant for single-class lookup rather than broad search.
"
Class {
	#name : 'MCPToolGetClass',
	#superclass : 'MCPTool',
	#traits : 'TMCPClassTool',
	#classTraits : 'TMCPClassTool classTrait',
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

	| includeCommentProperty includeSourceProperty subclassDepthProperty upToSuperclassNameProperty nameProperty |
	includeCommentProperty := MCPStructureProperties new
		                          name: 'includeComment';
		                          type: 'boolean';
		                          description: 'Include class comments.';
		                          default: false;
		                          yourself.
	includeSourceProperty := MCPStructureProperties new
		                         name: 'includeSource';
		                         type: 'boolean';
		                         description:
			                         ('Answer each class as its Tonel file, as an export writes it: definition, comment, and the methods its package defines on both sides. offset pages it: a page holds up to {1} methods and {2} characters, but at least one method.'
				                          format: {
						                          self defaultPageLimit.
						                          self pageCharacterLimit asStringWithCommas });
		                         default: false;
		                         yourself.
	upToSuperclassNameProperty := MCPStructureProperties new
		                              name: 'upToSuperclass';
		                              type: 'string';
		                              description: 'Also list superclasses up to, not including, this class.';
		                              yourself.
	subclassDepthProperty := MCPStructureProperties new
		                         name: 'subclassDepth';
		                         type: 'integer';
		                         description: 'Return subclasses down to the given level.';
		                         default: 0;
		                         minimum: 0;
		                         maximum: self maximumSubclassDepth;
		                         yourself.
	nameProperty := MCPStructureProperties new
		                name: 'name';
		                type: #( 'string' 'array' );
		                description: 'Class name, or several class names.';
		                items: (MCPStructureProperties new
				                 type: 'string';
				                 yourself);
		                yourself.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  nameProperty.
				  includeCommentProperty.
				  includeSourceProperty.
				  upToSuperclassNameProperty.
				  subclassDepthProperty.
				  self offsetInputProperty };
		  required: #( 'name' );
		  yourself
]

{ #category : 'private - request' }
MCPToolGetClass >> classNameFromRequest: request [

	^ request stringArgumentNamed: 'name'
]

{ #category : 'metadata' }
MCPToolGetClass >> defaultExposure [

	^ 'static'
]

{ #category : 'metadata' }
MCPToolGetClass >> defaultPageLimit [
	"With includeSource, how many methods a page of a class's Tonel file holds at most. A page also keeps within pageCharacterLimit, so a page of long methods holds fewer."

	^ 50
]

{ #category : 'metadata' }
MCPToolGetClass >> description [

	^ 'Get class or trait definitions by name: superclass, slots, traits, package. includeSource answers each as its Tonel file, a page of methods at a time. method_search lists their methods.'
]

{ #category : 'private - hierarchy' }
MCPToolGetClass >> descriptionDictionariesForClasses: someClasses includeComment: includeComment [

	^ someClasses collect: [ :each | self descriptionDictionaryForClass: each includeComment: includeComment ] as: Array
]

{ #category : 'private - hierarchy' }
MCPToolGetClass >> descriptionDictionaryForClass: aClass includeComment: includeComment [

	| data |
	data := (MCPClassDescriptionInfo fromClass: aClass) asDictionary copy.
	includeComment ifTrue: [ data at: #comment put: (aClass comment ifNil: [ '' ]) ].
	^ data
]

{ #category : 'private - results' }
MCPToolGetClass >> entryNameKeys [
	"A superclass or subclass record is a class."

	^ #( class )
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
	"The answer names the class found, not the name asked for: Foo class reads as Foo, and the summary says Foo. With includeSource, the class's Tonel file stands in for its description, which the file's definition holds."

	| data includeComment includeSource offset subclasses superclasses targetClass |
	targetClass := self resolvedClassNamed: (self classNameFromRequest: request).
	superclasses := self superclassesOf: targetClass upTo: (request stringArgumentNamed: 'upToSuperclass').
	subclasses := self subclassesOf: targetClass downTo: (request integerArgumentNamed: 'subclassDepth').
	includeComment := request booleanArgumentNamed: 'includeComment'.
	includeSource := request booleanArgumentNamed: 'includeSource'.
	offset := request integerArgumentNamed: 'offset'.
	data := includeSource
		        ifTrue: [ self tonelDictionaryForClass: targetClass offset: offset ]
		        ifFalse: [ self descriptionDictionaryForClass: targetClass includeComment: includeComment ].
	superclasses ifNotEmpty: [
		data at: #superclasses put: (self descriptionDictionariesForClasses: superclasses includeComment: includeComment) ].
	subclasses ifNotEmpty: [
		data at: #subclasses put: (self descriptionDictionariesForClasses: subclasses includeComment: includeComment) ].
	^ self
		  successResultText: (includeSource
				   ifTrue: [
						   self
							   tonelSummaryForClass: targetClass
							   page: data
							   offset: offset
							   superclasses: superclasses
							   subclasses: subclasses ]
				   ifFalse: [ self successSummaryForClass: targetClass superclasses: superclasses subclasses: subclasses ])
		  data: data
]

{ #category : 'private - results' }
MCPToolGetClass >> hierarchySummaryOn: aStream superclassCount: superclassCount subclassCount: subclassCount [
	"How many superclasses and subclasses the answer lists, said only when it lists some."

	superclassCount + subclassCount = 0 ifTrue: [ ^ self ].
	aStream
		space;
		nextPutAll: 'Included ';
		print: superclassCount;
		nextPutAll: ' superclass';
		nextPutAll: (superclassCount = 1
				 ifTrue: [ '' ]
				 ifFalse: [ 'es' ]);
		nextPutAll: ' and ';
		print: subclassCount;
		nextPutAll: ' subclass';
		nextPutAll: (subclassCount = 1
				 ifTrue: [ '' ]
				 ifFalse: [ 'es' ]);
		nextPut: $.
]

{ #category : 'private - source' }
MCPToolGetClass >> isMethod: aMethod filedWith: aClass [
	"Whether the class's own Tonel file holds the method, which it does when the method's package is the class's. A method with no package of its own is the class's."

	^ (aMethod package ifNil: [ aClass package ]) = aClass package
]

{ #category : 'private - results' }
MCPToolGetClass >> keyOrder [
	"What a class is, then where it lives, then how big it is. The comment is not named, so it lands after the inline values like any block of text."

	^ #( superclass package tag layout methods classMethods traits instanceSlots classSlots sharedVariables sharedPools users )
]

{ #category : 'private - results' }
MCPToolGetClass >> keysStatedInSummary [
	"The summary opens with the class name and says whether it is a trait, so repeating either says it twice. With includeSource, it also says which methods the page holds, how many methods other packages add, and where the next page starts."

	^ #( class isTrait pagination nextOffset extensionMethods )
]

{ #category : 'private - results' }
MCPToolGetClass >> kindAndNameOf: aClass [
	"class Foo or trait Foo, as an answer names it: a trait is not a class."

	^ (aClass isTrait
		   ifTrue: [ 'trait ' ]
		   ifFalse: [ 'class ' ]) , aClass name
]

{ #category : 'defaults' }
MCPToolGetClass >> maximumSubclassDepth [

	^ 10
]

{ #category : 'metadata' }
MCPToolGetClass >> pageCharacterLimit [
	"With includeSource, how many characters of a class's Tonel file a page holds at most, so that a large class comes in pages a model's context holds several of. A method longer than that still comes, alone on its page, since a page holds at least one method."

	^ 10000
]

{ #category : 'private - hierarchy' }
MCPToolGetClass >> subclassesOf: aClass downTo: aDepth [

	| subclasses |
	aDepth = 0 ifTrue: [ ^ #(  ) ].
	subclasses := OrderedCollection new.
	aClass
		allSubclassesWithLevelDo: [ :eachClass :level | (level between: 1 and: aDepth) ifTrue: [ subclasses add: eachClass ] ]
		startingLevel: 0.
	^ subclasses asArray
]

{ #category : 'private - results' }
MCPToolGetClass >> successSummaryForClass: aClass superclasses: superclasses subclasses: subclasses [
	"A trait is named as one. It is not a class, and it has users rather than superclasses and subclasses."

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Got ';
				  nextPutAll: (self kindAndNameOf: aClass);
				  nextPut: $..
			  self hierarchySummaryOn: stream superclassCount: superclasses size subclassCount: subclasses size ]
]

{ #category : 'private - hierarchy' }
MCPToolGetClass >> superclassesOf: aClass upTo: aSuperclassName [
	"The superclasses of aClass up to, not including, the one aSuperclassName names. None when no name is given."

	| targetSuperclass |
	aSuperclassName ifNil: [ ^ #(  ) ].
	targetSuperclass := MCPImageLookup classNamed: aSuperclassName role: #superclass details: { (#class -> aClass name asString) }.
	^ aClass allSuperclasses asArray copyUpTo: targetSuperclass
]

{ #category : 'metadata' }
MCPToolGetClass >> title [

	^ 'Get Class'
]

{ #category : 'private - source' }
MCPToolGetClass >> tonelDictionaryForClass: aClass offset: anOffset [
	"The class's Tonel file, a page of methods at a time. The first page opens with the definition and the comment, and a later one holds its methods alone, so the pages put end to end are the file. What other packages add to the class is in their own files, so it is counted and their names given instead. No file holds the users of a trait, so they come beside it, as in the description the file stands for."

	| data definition extensions methods opening page source |
	definition := aClass asClassDefinition.
	methods := self tonelMethodDefinitionsOf: aClass.
	opening := self tonelTextOf: definition methods: #(  ).
	page := MCPPaginationResult
		        fromEntries: methods
		        limit: (self
				         tonelMethodCountFrom: anOffset
				         of: methods
				         in: definition
				         opening: opening)
		        offset: anOffset.
	source := self tonelTextOf: definition methods: page entries.
	anOffset > 0 ifTrue: [ source := source allButFirst: opening size ].
	data := Dictionary new.
	data
		at: #class put: aClass name asString;
		at: #pagination put: page paginationDictionary.
	aClass isTrait ifTrue: [
			data at: #isTrait put: true.
			(MCPClassDescriptionInfo fromClass: aClass) userNames ifNotEmpty: [ :names | data at: #users put: names ] ].
	source ifNotEmpty: [ data at: #source put: source ].
	page nextOffset ifNotNil: [ :nextOffset | data at: #nextOffset put: nextOffset ].
	extensions := self extensionMethodsOf: aClass.
	extensions ifNotEmpty: [
			data
				at: #extensionMethods put: extensions size;
				at: #extensionPackages put: (extensions collect: [ :each | each package name asString ] as: Set) asArray sort ].
	^ data
]

{ #category : 'private - source' }
MCPToolGetClass >> tonelMethodCountFrom: anOffset of: someMethodDefinitions in: aClassDefinition opening: anOpeningString [
	"How many methods the page from anOffset holds: up to defaultPageLimit, and as many as keep its text within pageCharacterLimit, but at least one, so a method longer than a page is read too. The first page opens with the definition and the comment, anOpeningString, which counts toward it. A method adds to the file what the writer writes for it after the opening."

	| count size |
	count := 0.
	size := anOffset = 0
		        ifTrue: [ anOpeningString size ]
		        ifFalse: [ 0 ].
	someMethodDefinitions from: anOffset + 1 to: (someMethodDefinitions size min: anOffset + self defaultPageLimit) do: [ :each |
			size := size + (self tonelTextOf: aClassDefinition methods: { each }) size - anOpeningString size.
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

{ #category : 'private - results' }
MCPToolGetClass >> tonelPageSummaryForClass: aClass pagination: pagination offset: anOffset [
	"What the page holds of the class's Tonel file: the whole file, its definition with the first methods, or later methods alone."

	| name range returned total |
	name := self kindAndNameOf: aClass.
	returned := pagination at: #returnedCount.
	total := pagination at: #totalCount.
	range := self tonelMethodRangeFrom: anOffset + 1 count: returned.
	anOffset = 0 ifTrue: [
			^ (pagination at: #truncated)
				  ifTrue: [
						  'Got {1} as its Tonel file, with {2} of {3}.' format: {
								  name.
								  range.
								  total } ]
				  ifFalse: [ 'Got {1} as its Tonel file.' format: { name } ] ].
	returned = 0 ifTrue: [
			^ 'No methods from offset {1}: the Tonel file of {2} holds {3}.' format: {
					  anOffset.
					  name.
					  (self textForCount: total noun: 'method') } ].
	^ 'Got {1} of {2} in the Tonel file of {3}.' format: {
			  range.
			  total.
			  name }
]

{ #category : 'private - results' }
MCPToolGetClass >> tonelSummaryForClass: aClass page: data offset: anOffset superclasses: superclasses subclasses: subclasses [
	"What the page holds of the class's Tonel file, then what else the answer lists, what the file leaves out, and where the next page starts."

	^ String streamContents: [ :stream |
			  stream nextPutAll: (self tonelPageSummaryForClass: aClass pagination: (data at: #pagination) offset: anOffset).
			  self hierarchySummaryOn: stream superclassCount: superclasses size subclassCount: subclasses size.
			  data at: #extensionMethods ifPresent: [ :count |
					  self
						  extensionSummaryOn: stream
						  of: aClass
						  methodCount: count
						  packageCount: (data at: #extensionPackages) size ].
			  data at: #nextOffset ifPresent: [ :nextOffset |
					  stream
						  nextPutAll: ' Next page: offset ';
						  print: nextOffset;
						  nextPut: $. ] ]
]

{ #category : 'private - source' }
MCPToolGetClass >> tonelTextOf: aClassDefinition methods: someMethodDefinitions [
	"What Pharo's Tonel writer writes for the class holding these methods, which is what an export writes in its file."

	| writer |
	writer := TonelWriter new.
	writer snapshot: (MCSnapshot fromDefinitions: { aClassDefinition } , someMethodDefinitions).
	^ String streamContents: [ :stream | writer writeClass: aClassDefinition on: stream ]
]

{ #category : 'validating' }
MCPToolGetClass >> validateRequest: aToolRequest [
	"offset pages the Tonel file includeSource answers. Without includeSource the answer is a description, which has no pages, so an offset past the first would be ignored; it is refused instead, saying what it goes with."

	super validateRequest: aToolRequest.
	((aToolRequest integerArgumentNamed: 'offset') > 0 and: [ (aToolRequest booleanArgumentNamed: 'includeSource') not ]) ifFalse: [
		^ self ].
	MCPInvalidToolInput signalForTool: self violations: { (MCPJSONSchemaViolation
			 path: #( 'offset' )
			 keyword: #dependentRequired
			 message: 'offset pages the Tonel file that includeSource answers; pass includeSource: true with it, or leave offset out.'
			 expected: #( 'includeSource' )
			 actual: nil) }
]
