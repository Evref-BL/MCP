"
Tests the method_reference_search and method_source_search tools.
"
Class {
	#name : 'MCPToolMethodLookupTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolMethodLookupTest >> referenceSummaryFor: arguments [

	^ self summaryFrom: (self callToolNamed: 'method_reference_search' withArguments: arguments asDictionary)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testAClassNameThatNamesNoClassIsSaidByTheLookup [

	| error result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#kind -> 'class').
			          (#query -> 'MCPToolMethodSearchReferenceTargt') } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: ((error at: #message) beginsWith: 'Class MCPToolMethodSearchReferenceTargt does not exist. Did you mean: ').
	self assert: ((error at: #suggestions) includes: 'MCPToolMethodSearchReferenceTarget').
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#kind -> 'class').
			          (#query -> 'Transcript') } asDictionary.
	error := self errorFrom: result.
	self assert: (error at: #errorCode) equals: 'NotAClass'.
	self assert: (error at: #message) equals: 'Transcript is a global variable, not a class.'
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testAClassOverridingATraitMethodKeepsItsOwnAnswer [

	| entries entry |
	entries := self traitFixtureImplementors.
	entry := self entryForReference: 'MCPToolMethodSearchTraitOverrider>>mcpTraitFixtureValue' in: entries.
	self deny: (entry includesKey: #installedIn).
	self deny: (entry includesKey: #trait)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testAClassSideNameAnswersReferencesToItsClass [
	"Foo class names no global of its own, so its spelling alone would read it as a variable. Its base name decides, and the references are those of Foo."

	| data references |
	data := self
		        toolNamed: 'method_reference_search'
		        dataFromArguments: { (#query -> 'MCPToolMethodSearchReferenceTarget class') } asDictionary.
	references := self
		              toolNamed: 'method_reference_search'
		              dataFromArguments: { (#query -> 'MCPToolMethodSearchReferenceTarget') } asDictionary.
	self denyEmpty: (data at: #methods).
	(data at: #methods) do: [ :each | self assert: (each at: #reference) equals: 'class' ].
	self assert: (data at: #methods) equals: (references at: #methods)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testALowercaseNameNothingUsesFindsNoImplementorsOrSenders [
	"A lowercase name reads as a selector, and then as a variable. When nothing implements or sends it and no variable has that name, nothing was found: the answer says so, rather than that the name is unknown."

	| result |
	result := self callToolNamed: 'method_reference_search' withArguments: { (#query -> 'mcpNoSuchSelectorAnywhere') } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
	self assert: (self summaryFrom: result) equals: 'No implementors or senders of mcpNoSuchSelectorAnywhere in the image.'
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testANameThatIsNotASelectorIsUnknownRatherThanUnused [
	"A name with no letter first, or one with a space, is read as a selector but is not one: nothing implements or sends #printString, although printString is sent everywhere. Saying that nothing uses it would be false, so the name is unknown, as a name no reading resolves is."

	#( '#printString' 'self printString' ) do: [ :name |
			| error result |
			result := self callToolNamed: 'method_reference_search' withArguments: { (#query -> name) } asDictionary.
			self assert: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
			error := self errorFrom: result.
			self assert: (error at: #errorCode) equals: 'ReferenceSubjectNotFound'.
			self
				assert: (error at: #message)
				equals: ('There is no class, variable or selector named {1} in the requested scope.' format: { name }) ]
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testASourceSearchForASelectorThatFindsNothingNamesTheSelectorSearches [
	"Source writes an argument after each keyword of a selector, so a filter spelled as a selector of several keywords misses the methods that send it. The answer says why and names the tools that look for a selector, with the scope the call gave, if any; an empty page stands in for a sweep of the image. A scope that names nothing that exists looked nowhere, so its miss says only that and leaves the next step to the warning. A filter that is no selector misses with nothing more to say."

	| result tool |
	result := self callToolNamed: 'method_source_search' withArguments: {
			          (#query -> 'with:with:with:').
			          (self searchScope: { (#classes -> #( 'MCPToolGetMethodTestTarget' )) }) } asDictionary.
	self deny: (self resultIndicatesError: result).
	self
		assert: (self summaryFrom: result)
		equals:
		'No methods match in MCPToolGetMethodTestTarget. with:with:with: is a selector: source writes an argument after each of its keywords, so a method that implements or sends it does not contain that text. With the same scope, method_reference_search with query with:with:with: finds its implementors and senders, and method_search with query with:with:with: finds its implementors.'.
	tool := MCPToolSearchMethodSource new.
	self
		assert: (self
				 summaryOf: tool
				 forArguments: { (#query -> 'with:with:with:') } asDictionary
				 page: (tool queryPageForEntries: #(  ) limit: 25 offset: 0))
		equals:
		'No methods match in the image. with:with:with: is a selector: source writes an argument after each of its keywords, so a method that implements or sends it does not contain that text. method_reference_search with query with:with:with: finds its implementors and senders, and method_search with query with:with:with: finds its implementors.'.
	result := self callToolNamed: 'method_source_search' withArguments: {
			          (#query -> 'with:with:with:').
			          (self searchScope: { (#classes -> #( 'MCPToolGetMethodTestTarget' 'MCPNoSuchSourceSearchClass' )) }) } asDictionary.
	self assert:
		((self summaryFrom: result) beginsWith: 'No methods match in MCPToolGetMethodTestTarget. with:with:with: is a selector: ').
	result := self callToolNamed: 'method_source_search' withArguments: {
			          (#query -> 'with:with:with:').
			          (self searchScope: { (#classes -> #( 'MCPNoSuchSourceSearchClass' )) }) } asDictionary.
	self deny: (self resultIndicatesError: result).
	self assert: (self summaryFrom: result) equals: 'No methods match: the scope names nothing that exists.'.
	self assert: ((self warningsFrom: result) first includesSubstring: 'MCPNoSuchSourceSearchClass').
	result := self callToolNamed: 'method_source_search' withArguments: {
			          (#query -> 'with: nothing with:').
			          (self searchScope: { (#classes -> #( 'MCPToolGetMethodTestTarget' )) }) } asDictionary.
	self assert: (self summaryFrom: result) equals: 'No methods match in MCPToolGetMethodTestTarget.'
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testClassNameAnswersClassReferences [

	| data |
	data := self
		        toolNamed: 'method_reference_search'
		        dataFromArguments: { (#query -> 'MCPToolMethodSearchReferenceTarget') } asDictionary.
	(data at: #methods) do: [ :each | self assert: (each at: #reference) equals: 'class' ]
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testClassReferenceClassScopeReturnsClassGlobalReferences [

	| data result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#query -> 'MCPToolMethodSearchReferenceTarget').
			          (self searchScope: { (#classes -> #( 'MCPToolMethodSearchReferenceFixture' )) }) } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #methods) size equals: 2.
	self entryForReference: 'MCPToolMethodSearchReferenceFixture>>referenceExtensionTarget' in: (data at: #methods).
	self entryForReference: 'MCPToolMethodSearchReferenceFixture class>>referenceExtensionTarget' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testClassReferenceDoesNotIncludeSelectorSendsNamedLikeClass [

	| data result selectors |
	result := self
		          callToolNamed: 'method_reference_search'
		          withArguments: { (#query -> 'MCPToolMethodSearchReferenceTarget') } asDictionary.
	data := self dataFrom: result.
	selectors := (data at: #methods) collect: [ :each | each at: #selector ].
	self assert: (data at: #methods) size equals: 2.
	self deny: (selectors includes: 'sendExistingClassNamedSelector')
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testClassReferenceFindsAMethodThatNamesTheClassByAnAlias [
	"A global may hold a class under another name, as Pharo 14's deprecated aliases do, such as RBParser for OCParser. A method that names the alias refers to the class, in its body or in a block, so a search by either name finds it beside the methods that name the class itself. The classes are named by string, so that this test adds no reference to them."

	| aliasName writer writerName |
	aliasName := 'MCPToolMethodSearchReferenceTargetAlias'.
	writerName := 'MCPToolMethodSearchAliasWriter'.
	[
		self class environment at: aliasName asSymbol put: (self classNamed: 'MCPToolMethodSearchReferenceTarget').
		writer := self
			          createClassNamed: writerName
			          superclassName: 'Object'
			          slots: #(  )
			          classSlots: #(  ).
		self ensureMethodSource: 'writesAlias ^ ' , aliasName protocol: 'testing' on: writer.
		self ensureMethodSource: ('writesAliasInABlock ^ [ {1} ] value' format: { aliasName }) protocol: 'testing' on: writer.
		{
			'MCPToolMethodSearchReferenceTarget'.
			aliasName } do: [ :name |
				| methods result |
				result := self callToolNamed: 'method_reference_search' withArguments: {
						          (#query -> name).
						          (#kind -> 'class').
						          (self searchScope: { (#classes -> {
								            writerName.
								            'MCPToolMethodSearchReferenceFixture' }) }) } asDictionary.
				self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
				methods := (self dataFrom: result) at: #methods.
				self assert: methods size equals: 4.
				self entryForReference: writerName , '>>writesAlias' in: methods.
				self entryForReference: writerName , '>>writesAliasInABlock' in: methods.
				self entryForReference: 'MCPToolMethodSearchReferenceFixture>>referenceExtensionTarget' in: methods.
				self entryForReference: 'MCPToolMethodSearchReferenceFixture class>>referenceExtensionTarget' in: methods ] ] ensure: [
			self removeClassNamed: writerName.
			self class environment removeKey: aliasName asSymbol ifAbsent: [ ] ]
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testClassReferenceReturnsInstanceAndClassGlobalReferences [

	| data result |
	result := self
		          callToolNamed: 'method_reference_search'
		          withArguments: { (#query -> 'MCPToolMethodSearchReferenceTarget') } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #methods) size equals: 2.
	self entryForReference: 'MCPToolMethodSearchReferenceFixture>>referenceExtensionTarget' in: (data at: #methods).
	self entryForReference: 'MCPToolMethodSearchReferenceFixture class>>referenceExtensionTarget' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testClassReferenceReturnsStructuredErrorWhenClassIsMissing [

	| error result |
	result := self
		          callToolNamed: 'method_reference_search'
		          withArguments: { (#query -> 'MCPDefinitelyMissingReferenceClass') } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert:
		((error at: #message) includesSubstring: 'There is no class, variable or selector named MCPDefinitelyMissingReferenceClass')
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testImageScopeReturnsInstanceAndClassImplementors [

	| entries scopeQuery selector tool |
	selector := #mcpImageScopeUniqueTarget.
	scopeQuery := MCPMethodSearchImageScopeQueryTestDouble new
		              behaviors: {
				              MCPToolMethodSearchReferenceFixture.
				              MCPToolMethodSearchReferenceFixture class };
		              yourself.
	tool := MCPToolSearchMethodReferences new.
	entries := tool
		           queryEntriesForRequest: (tool requestFromToolCallArguments: {
					            (#query -> selector asString).
					            (#kind -> 'implementors') } asDictionary)
		           scopeQuery: scopeQuery.
	self assert: entries size equals: 2.
	self
		entryForReference: (String streamContents: [ :stream | stream << MCPToolMethodSearchReferenceFixture name << '>>' << selector ])
		in: entries.
	self
		entryForReference:
		(String streamContents: [ :stream | stream << MCPToolMethodSearchReferenceFixture name << ' class>>' << selector ])
		in: entries
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testImplementorsLeaveOutWhatTraitedClassInstalls [
	"An implementor lookup reads the behaviors of its scope itself, and leaves out the copies TraitedClass installs as a sweep does."

	| result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#kind -> 'implementors').
			          (#query -> 'allTraits').
			          (self searchScope: { (#classes -> { MCPToolMethodSearchTraitUser name }) }) } asDictionary.
	self assert: ((self dataFrom: result) at: #methods) isEmpty
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testKindNarrowsWhatIsLookedFor [

	| data |
	data := self toolNamed: 'method_reference_search' dataFromArguments: {
			        (#kind -> 'implementors').
			        (#query -> 'sharedTarget') } asDictionary.
	(data at: #methods) do: [ :each | self assert: (each at: #reference) equals: 'implementors' ]
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testLookupSchemasRequireDedicatedArguments [

	self
		assert: (MCPToolSearchMethodReferences new inputSchema properties collect: [ :each | each name ] as: Set)
		equals: #( 'scope' 'offset' 'query' 'kind' ) asSet
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testLookupToolsArePublicStaticReadTools [

	#( 'method_source_search' 'method_reference_search' ) do: [ :each |
			| tool |
			self assert: (self toolRegistry toolNames includes: each).
			self assert: (self toolRegistry advertisedToolNames includes: each).
			tool := self toolRegistry toolNamed: each ifAbsent: [ self fail: 'Missing tool ' , each ].
			self assert: tool defaultExposure equals: 'static'.
			self assert: tool annotations readOnlyHint ]
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testMatchAcrossBlanksIsReadOnTheLineItStarts [
	"The line a match over several lines starts on is counted in characters, the way lines splits the text: a CR, an LF or a CR and LF each end one, and a character outside ASCII counts once."

	| finder source tool |
	source := String streamContents: [ :stream |
			          stream
				          nextPutAll: (String new: 10 withAll: $é);
				          cr;
				          nextPutAll: 'b';
				          lf;
				          nextPutAll: 'c';
				          crlf;
				          nextPutAll: 'x isNil';
				          cr;
				          tab;
				          nextPutAll: 'ifTrue: [ ^ x ]' ].
	tool := MCPToolSearchMethodSource new.
	finder := tool matchStartFinderForPiecesAcrossBlanks: #( 'isNil' 'ifTrue:' ) caseSensitive: true.
	self assert: (tool lineNumberOfMatchIn: source lines: source lines finder: finder) equals: 4
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testMatcherAcrossBlanksMatchesEachPieceAsWritten [
	"Each piece is escaped in the regex that joins them, so a colon, a bracket, a caret or a period matches itself, and pieces need blanks between them."

	| matcher source |
	source := String streamContents: [ :stream |
			          stream
				          nextPutAll: 'x ifNil:';
				          cr;
				          tab;
				          nextPutAll: '[ ^ nil ].' ].
	matcher := MCPToolSearchMethodSource new matcherForPiecesAcrossBlanks: #( 'ifNil:' '[' '^' 'nil' '].' ) caseSensitive: true.
	self assert: (matcher value: source).
	self deny: (matcher value: 'x ifNil [ ^ nil ].').
	self deny: (matcher value: 'x ifNil: [ ^ nil ]!').
	self deny: (matcher value: 'x ifNil:[ ^ nil ].')
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testMethodSourceSearchSearchesSourceText [

	| data result |
	result := self callToolNamed: 'method_source_search' withArguments: {
			          (self searchScope: { (#classes -> { MCPToolMethodSearchTestTarget name }) }).
			          (#query -> 'gamma value') } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	data := self dataFrom: result.
	self assert: (data at: #methods) size equals: 1.
	self assert: ((data at: #methods) first at: #selector) equals: 'gammaUtility'.
	self deny: ((data at: #methods) first includesKey: #source)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testNoHitsForAClassPointToKindClass [
	"A class or trait name finds no implementor or sender; the answer says that kind class finds what refers to it. The name is read as every class name is, so Foo class names Foo."

	self
		assert: (self referenceSummaryFor: {
					 (#query -> 'MCPToolMethodSearchReferenceFixture').
					 (#kind -> 'senders') })
		equals:
		'No senders of MCPToolMethodSearchReferenceFixture in the image. MCPToolMethodSearchReferenceFixture is a class; kind: class finds the methods that refer to it.'.
	self
		assert: (self referenceSummaryFor: {
					 (#query -> 'TMCPToolMethodSearchFixture').
					 (#kind -> 'implementors') })
		equals:
		'No implementors of TMCPToolMethodSearchFixture in the image. TMCPToolMethodSearchFixture is a trait; kind: class finds the methods that refer to it.'.
	self
		assert: (self referenceSummaryFor: {
					 (#query -> 'MCPToolMethodSearchReferenceFixture class').
					 (#kind -> 'senders') })
		equals:
		'No senders of MCPToolMethodSearchReferenceFixture class in the image. MCPToolMethodSearchReferenceFixture is a class; kind: class finds the methods that refer to it.'
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testNoHitsForAMethodNameTheSelector [
	"A method written with its class finds no sender; the answer names the selector to ask for instead."

	self
		assert: (self referenceSummaryFor: {
					 (#query -> 'MCPToolMethodSearchReferenceFixture>>#sharedTarget').
					 (#kind -> 'senders') })
		equals:
		'No senders of MCPToolMethodSearchReferenceFixture>>#sharedTarget in the image. MCPToolMethodSearchReferenceFixture>>#sharedTarget names a method; name its selector alone: sharedTarget.'
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testNoHitsSayWhatWasLookedFor [
	"Nothing found names the kinds that were looked for and the name."

	self
		assert: (self referenceSummaryFor: {
					 (#query -> 'mcpNoSuchSelectorAnywhere').
					 (#kind -> 'senders') })
		equals: 'No senders of mcpNoSuchSelectorAnywhere in the image.'.
	self
		assert: (self referenceSummaryFor: {
					 (#query -> 'trackedSlot').
					 (#kind -> 'implementors') })
		equals: 'No implementors of trackedSlot in the image.'.
	self
		assert: (self referenceSummaryFor: {
					 (#query -> 'MCPToolMethodSearchReferenceTarget').
					 (#kind -> 'class').
					 (self searchScope: { (#classes -> #( 'MCPToolMethodSearchVariableReferenceTarget' )) }) })
		equals: 'No methods refer to MCPToolMethodSearchReferenceTarget in MCPToolMethodSearchVariableReferenceTarget.'
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testRegexSourceSearchReadsAMatchOverLinesWhereItStarts [
	"A regex hit that no line holds by itself is read at the line its match starts on. When that match starts with a blank or a line break, that line would show none of it, so the hit names no line."

	| methods search |
	search := [ :filter |
		          (self dataFrom: (self callToolNamed: 'method_source_search' withArguments: {
					            (#query -> filter).
					            (#queryMode -> 'regex').
					            (self searchScope: { (#classes -> #( 'MCPToolGetMethodTestTarget' )) }) } asDictionary)) at: #methods ].
	methods := search value: 'OrderedCollection\s+with: anArgument\s+with: local'.
	self assert: (methods collect: [ :each | each at: #selector ] as: Array) equals: #( 'readInstanceWith:' ).
	self assert: (methods first at: #lineNumber) equals: 5.
	self assert: (methods first at: #line) equals: '^ OrderedCollection'.
	methods := search value: '\s+with: anArgument\s+with: local'.
	self assert: (methods collect: [ :each | each at: #selector ] as: Array) equals: #( 'readInstanceWith:' ).
	self deny: (methods first includesKey: #lineNumber)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testReturnsStructuredErrorForInvalidRegex [

	| error result |
	result := self callToolNamed: 'method_source_search' withArguments: {
			          (self searchScope: { (#classes -> { MCPToolMethodSearchTestTarget name }) }).
			          (#queryMode -> 'regex').
			          (#query -> '[') } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorClass) equals: 'RegexSyntaxError'.
	self assert: ((error at: #message) includesSubstring: 'terminating')
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSearchFailureNamesTheScope [
	"A search that fails names what it was asked to search, a name that does not exist included, and leaves the scope key of the details to the schema path of a scope entry."

	| error result |
	result := self callToolNamed: 'method_source_search' withArguments: {
			          (self searchScope: { (#classes -> #( 'MCPToolMethodSearchTestTarget' 'MCPNoSuchSummaryClass' )) }).
			          (#queryMode -> 'regex').
			          (#query -> '[') } asDictionary.
	error := self errorFrom: result.
	self assert: (self resultIndicatesError: result).
	self assert: ((self summaryFrom: result) beginsWith:
			 'Unable to search methods in MCPToolMethodSearchTestTarget and MCPNoSuchSummaryClass (RegexSyntaxError): ').
	self deny: (error includesKey: #scope)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSearchMethodImplementorsReturnsExactSelectorMatches [

	| data |
	data := self toolNamed: 'method_reference_search' dataFromArguments: {
			        (#query -> 'alphaNeedleSelector').
			        (self searchScope: { (#classes -> { MCPToolMethodSearchTestTarget name }) }) } asDictionary.
	self assert: (data at: #methods) size equals: 1.
	self entryForReference: MCPToolMethodSearchTestTarget name , '>>alphaNeedleSelector' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSelectorNameAnswersImplementorsAndSendersLabelled [

	| data kinds |
	data := self toolNamed: 'method_reference_search' dataFromArguments: { (#query -> 'sharedTarget') } asDictionary.
	kinds := (data at: #methods) collect: [ :each | each at: #reference ] as: Set.
	self assert: kinds equals: #( 'implementors' 'senders' ) asSet
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSelectorReferenceClassNamesLimitToExactClasses [

	| data result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#kind -> 'senders').
			          (#query -> 'hierarchyTarget').
			          (self searchScope: { (#classes -> #( 'MCPToolHierarchyTestChild' )) }) } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #methods) size equals: 1.
	self entryForReference: 'MCPToolHierarchyTestChild>>childHierarchySender' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSelectorReferencePackageNamesIncludeExtensionMethods [

	| data method result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#kind -> 'senders').
			          (#query -> 'extensionTarget').
			          (self searchScope: { (#packages -> #( 'MCP-Tests-Resources-Extensions' )) }) } asDictionary.
	data := self dataFrom: result.
	method := self entryForReference: 'MCPToolMethodSearchReferenceTarget>>extensionSender' in: (data at: #methods).
	self assert: (data at: #methods) size equals: 1.
	self assert: (method at: #package) equals: 'MCP-Tests-Resources-Extensions'.
	self assert: (method at: #isExtension)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSelectorReferenceParentClassNamesSearchParents [

	| data result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#kind -> 'senders').
			          (#query -> 'hierarchyTarget').
			          (self searchScope: { (#superclassesOf -> #( 'MCPToolHierarchyTestMid' )) }) } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #methods) size equals: 1.
	self entryForReference: 'MCPToolHierarchyTestBase>>baseHierarchySender' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSelectorReferenceRejectsEmptyFilter [

	| error result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#kind -> 'senders').
			          (#query -> '') } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorClass) equals: 'MCPInvalidToolInput'
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSelectorReferenceReturnsInstanceAndClassSenders [

	| data result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#kind -> 'senders').
			          (#query -> 'sharedTarget') } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #methods) size equals: 2.
	self entryForReference: 'MCPToolMethodSearchReferenceFixture>>instanceSendShared' in: (data at: #methods).
	self entryForReference: 'MCPToolMethodSearchReferenceFixture class>>classSendShared' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSelectorReferenceReturnsSelectorSendsNamedLikeClass [

	| data result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#kind -> 'senders').
			          (#query -> 'MCPToolMethodSearchReferenceTarget') } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #methods) size equals: 2.
	self entryForReference: 'MCPToolMethodSearchReferenceFixture>>sendExistingClassNamedSelector' in: (data at: #methods).
	self entryForReference: 'MCPToolMethodSearchReferenceFixture class>>sendExistingClassNamedSelector' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSelectorReferenceSubclassClassNamesSearchSubclasses [

	| data result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#kind -> 'senders').
			          (#query -> 'hierarchyTarget').
			          (self searchScope: { (#subclassesOf -> #( 'MCPToolHierarchyTestMid' )) }) } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #methods) size equals: 1.
	self entryForReference: 'MCPToolHierarchyTestChild>>childHierarchySender' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSelectorReferenceSuperclassAndSubclassScopesSearchRelatedMethods [

	| data result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#kind -> 'senders').
			          (#query -> 'hierarchyTarget').
			          (self searchScope: {
					           (#superclassesOf -> #( 'MCPToolHierarchyTestMid' )).
					           (#subclassesOf -> #( 'MCPToolHierarchyTestMid' )) }) } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #methods) size equals: 2.
	self entryForReference: 'MCPToolHierarchyTestBase>>baseHierarchySender' in: (data at: #methods).
	self entryForReference: 'MCPToolHierarchyTestChild>>childHierarchySender' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSourceHitsReadAsLineNumberAndText [
	"A source hit reads like grep: the method, then the number and text of the line that matched, unquoted; the data keeps both as fields."

	| contentText result |
	result := self callToolNamed: 'method_source_search' withArguments: {
			          (#query -> 'SharedLimit').
			          (self searchScope: { (#classes -> #( 'MCPToolGetMethodTestTarget' )) }) } asDictionary.
	contentText := (result at: #content) first at: #text.
	self assert: (contentText lines includes:
			 '  MCPToolGetMethodTestTarget>>readInstanceWith: line 4: local := instanceCounter ifNil: [ SharedLimit ].').
	self assert: (contentText lines includes:
			 '  MCPToolGetMethodTestTarget class>>readClassSide line 4: local := classCounter ifNil: [ SharedLimit ].').
	self deny: (contentText includesSubstring: 'lineNumber=').
	self deny: (contentText includesSubstring: 'line="').
	self deny: (contentText includesSubstring: 'protocol=').
	self assert: (((self dataFrom: result) at: #methods) allSatisfy: [ :each |
			 (each at: #lineNumber) = 4 and: [ (each includesKey: #line) and: [ each includesKey: #protocol ] ] ])
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSourceSearchMatchesAnyRunOfBlanks [
	"Blanks of any kind and number between the pieces of a substring filter match the single space the source has there, and the rest of the filter, colon, brackets and period included, matches as written."

	| filter methods |
	filter := String streamContents: [ :stream |
			          stream
				          nextPutAll: 'ifNil:  [';
				          tab;
				          nextPutAll: 'SharedLimit  ].' ].
	methods := (self dataFrom: (self callToolNamed: 'method_source_search' withArguments: {
				             (#query -> filter).
				             (self searchScope: { (#classes -> #( 'MCPToolGetMethodTestTarget' )) }) } asDictionary)) at: #methods.
	self assert: (methods collect: [ :each | each at: #selector ] as: Set) equals: #( 'readClassSide' 'readInstanceWith:' ) asSet.
	self assert: (methods allSatisfy: [ :each | (each at: #lineNumber) = 4 ])
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSourceSearchMatchesBlanksAcrossLines [
	"A run of blanks in a substring filter matches any run of blanks in the source, a line break included, and the hit is read at the line the match starts on. Blanks in the filter still need blanks in the source."

	| methods |
	methods := (self dataFrom: (self callToolNamed: 'method_source_search' withArguments: {
				             (#query -> 'OrderedCollection with: anArgument').
				             (self searchScope: { (#classes -> #( 'MCPToolGetMethodTestTarget' )) }) } asDictionary)) at: #methods.
	self assert: (methods collect: [ :each | each at: #selector ] as: Array) equals: #( 'readInstanceWith:' ).
	self assert: (methods first at: #lineNumber) equals: 5.
	self assert: (methods first at: #line) equals: '^ OrderedCollection'.
	self assert: ((self dataFrom: (self callToolNamed: 'method_source_search' withArguments: {
					   (#query -> 'Ordered Collection').
					   (self searchScope: { (#classes -> #( 'MCPToolGetMethodTestTarget' )) }) } asDictionary)) at: #methods) isEmpty
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSourceSearchReadsAMatchOverThreeLinesAtItsFirst [
	"A substring filter whose blanks fall on two line breaks is read at the line the match starts on, not at a line it runs through."

	| methods |
	methods := (self dataFrom: (self callToolNamed: 'method_source_search' withArguments: {
				             (#query -> '^ OrderedCollection with: anArgument with: local').
				             (self searchScope: { (#classes -> #( 'MCPToolGetMethodTestTarget' )) }) } asDictionary)) at: #methods.
	self assert: (methods collect: [ :each | each at: #selector ] as: Array) equals: #( 'readInstanceWith:' ).
	self assert: (methods first at: #lineNumber) equals: 5.
	self assert: (methods first at: #line) equals: '^ OrderedCollection'
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSourceSearchSchemaUsesDedicatedInputs [

	| queryModeProperty sourceSchema |
	sourceSchema := MCPToolSearchMethodSource new inputSchema.
	queryModeProperty := self inputPropertyNamed: 'queryMode' inTool: MCPToolSearchMethodSource new.
	self assert: sourceSchema required asArray equals: #( 'query' ).
	self
		assert: (sourceSchema properties collect: [ :each | each name ] as: Set)
		equals: #( 'scope' 'query' 'queryMode' 'offset' ) asSet.
	self assert: (queryModeProperty extraProperties at: #enum) asArray equals: #( 'substring' 'regex' )
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSourceSearchShowsTheLineThatMatched [

	| data result |
	result := self callToolNamed: 'method_source_search' withArguments: {
			          (#query -> 'instanceCounter').
			          (self searchScope: { (#classes -> #( 'MCPToolGetMethodTestTarget' )) }) } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #methods) isNotEmpty.
	self assert: ((data at: #methods) allSatisfy: [ :each | (each at: #line) includesSubstring: 'instanceCounter' ]).
	self assert: ((data at: #methods) allSatisfy: [ :each | (each at: #lineNumber) > 0 ]).
	self deny: ((data at: #methods) anySatisfy: [ :each | each includesKey: #source ])
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testSummaryNamesTheKindAndTheName [
	"The summary says what was looked for and counts every hit of each kind, not only the page."

	| pagedSummary |
	self
		assert: (self referenceSummaryFor: { (#query -> 'sharedTarget') })
		equals: '2 implementors and 2 senders of sharedTarget in the image.'.
	self
		assert: (self referenceSummaryFor: {
					 (#query -> 'sharedTarget').
					 (#kind -> 'senders') })
		equals: '2 senders of sharedTarget in the image.'.
	self
		assert: (self referenceSummaryFor: { (#query -> 'MCPToolMethodSearchReferenceTarget') })
		equals: '2 methods refer to MCPToolMethodSearchReferenceTarget in the image.'.
	self
		assert: (self referenceSummaryFor: {
					 (#query -> 'trackedSlot').
					 (self searchScope: { (#classes -> #( 'MCPToolMethodSearchVariableReferenceTarget' )) } side: 'instance') })
		equals: '2 methods use trackedSlot in MCPToolMethodSearchVariableReferenceTarget, instance side.'.
	self
		assert: (self referenceSummaryFor: {
					 (#query -> 'sharedTarget').
					 (#offset -> 30) })
		equals: 'No implementors or senders from offset 30; 2 implementors and 2 senders of sharedTarget in the image.'.
	pagedSummary := self referenceSummaryFor: {
			                (#query -> 'printString').
			                (#kind -> 'senders') }.
	self assert: (pagedSummary beginsWith: '25 of ').
	self assert: (pagedSummary endsWith: ' senders of printString in the image. Next page: offset 25, or narrow the search.')
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testTextGroupsHitsByKind [
	"Hits read under the kind of reference they are, so no row repeats it; the data keeps reference on each entry."

	| contentText lines result |
	result := self callToolNamed: 'method_reference_search' withArguments: { (#query -> 'sharedTarget') } asDictionary.
	contentText := (result at: #content) first at: #text.
	lines := contentText lines.
	self assert: (lines at: 2) equals: 'implementors (each package=MCP-Tests-Resources):'.
	self
		assert: (lines copyFrom: 3 to: 4) asSet
		equals:
		#( '  MCPToolMethodSearchReferenceFixture class>>sharedTarget' '  MCPToolMethodSearchReferenceFixture>>sharedTarget' ) asSet.
	self assert: (lines at: 5) equals: 'senders (each package=MCP-Tests-Resources):'.
	self
		assert: (lines copyFrom: 6 to: 7) asSet
		equals:
			#( '  MCPToolMethodSearchReferenceFixture class>>classSendShared'
			   '  MCPToolMethodSearchReferenceFixture>>instanceSendShared' ) asSet.
	self deny: (contentText includesSubstring: 'reference=').
	self deny: (contentText includesSubstring: 'protocol=').
	self assert: (((self dataFrom: result) at: #methods) allSatisfy: [ :each | each includesKey: #reference ])
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testTraitMethodCopiesAreAnsweredOnceAsTheTraitDefiningThem [

	| entries entry |
	entries := self traitFixtureImplementors.
	entry := self entryForReference: 'TMCPToolMethodSearchFixture>>mcpTraitFixtureValue' in: entries.
	self assert: (entry at: #installedIn) asArray equals: {
			MCPToolMethodSearchTraitOtherUser name.
			MCPToolMethodSearchTraitUser name }.
	self deny: (entries anySatisfy: [ :each | (each at: #class) = MCPToolMethodSearchTraitUser name ])
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testTraitMethodCopiesAreAnsweredOncePerSide [

	| entries entry |
	entries := self traitFixtureImplementors.
	self assert: entries size equals: 3.
	entry := self entryForReference: 'TMCPToolMethodSearchFixture class>>mcpTraitFixtureValue' in: entries.
	self assert: (entry at: #installedIn) asArray equals: {
			MCPToolMethodSearchTraitOtherUser name.
			MCPToolMethodSearchTraitOverrider name.
			MCPToolMethodSearchTraitUser name }
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testVariableReferenceLooksForASlotOnlyInTheClassesThatHaveIt [
	"A method reaches a slot by its index, which another class gives to a slot of its own. Here sharedSlot is the third slot of one class and the second of another, so the first class's betaSlot, its second slot, is not a use of sharedSlot. A subclass's method uses the sharedSlot it inherits."

	| heirName methods ownerName strangerName |
	ownerName := 'MCPToolMethodSearchSlotOwner'.
	strangerName := 'MCPToolMethodSearchSlotStranger'.
	heirName := 'MCPToolMethodSearchSlotHeir'.
	[
		| heir owner stranger |
		owner := self
			         createClassNamed: ownerName
			         superclassName: 'Object'
			         slots: #( alphaSlot betaSlot sharedSlot )
			         classSlots: #(  ).
		stranger := self
			            createClassNamed: strangerName
			            superclassName: 'Object'
			            slots: #( gammaSlot sharedSlot )
			            classSlots: #(  ).
		heir := self
			        createClassNamed: heirName
			        superclassName: ownerName
			        slots: #(  )
			        classSlots: #(  ).
		self ensureMethodSource: 'readBetaSlot ^ betaSlot' protocol: 'accessing' on: owner.
		self ensureMethodSource: 'readSharedSlot ^ sharedSlot' protocol: 'accessing' on: owner.
		self ensureMethodSource: 'readSharedSlot ^ sharedSlot' protocol: 'accessing' on: stranger.
		self ensureMethodSource: 'writeSharedSlot: anObject sharedSlot := anObject' protocol: 'accessing' on: heir.
		methods := (self dataFrom: (self callToolNamed: 'method_reference_search' withArguments: {
					             (#query -> 'sharedSlot').
					             (#kind -> 'variable').
					             (self searchScope: { (#packages -> { self generatedPackageName }) }) } asDictionary)) at: #methods.
		self assert: (self referencesOf: methods) equals: {
				(heirName , '>>writeSharedSlot:').
				(ownerName , '>>readSharedSlot').
				(strangerName , '>>readSharedSlot') } ] ensure: [
			{
				heirName.
				ownerName.
				strangerName } do: [ :each | self removeClassNamed: each ] ]
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testVariableReferenceReturnsClassSideVariableReferences [

	| data result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#query -> 'trackedClassSlot').
			          (self searchScope: { (#classes -> #( 'MCPToolMethodSearchVariableReferenceTarget' )) } side: 'class') } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #methods) size equals: 2.
	self entryForReference: 'MCPToolMethodSearchVariableReferenceTarget class>>readTrackedClassSlot' in: (data at: #methods).
	self entryForReference: 'MCPToolMethodSearchVariableReferenceTarget class>>writeTrackedClassSlot' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testVariableReferenceReturnsInstanceVariableReferences [

	| data result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#query -> 'trackedSlot').
			          (self searchScope: { (#classes -> { MCPToolMethodSearchVariableReferenceTarget name }) } side: 'instance') }
			          asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #methods) size equals: 2.
	self entryForReference: MCPToolMethodSearchVariableReferenceTarget name , '>>readTrackedSlot' in: (data at: #methods).
	self entryForReference: MCPToolMethodSearchVariableReferenceTarget name , '>>writeTrackedSlot' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodLookupTest >> testVariableReferenceReturnsStructuredErrorWhenVariableIsMissing [

	| error result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#query -> 'missingTrackedSlot').
			          (#kind -> 'variable').
			          (self searchScope: { (#classes -> #( 'MCPToolMethodSearchVariableReferenceTarget' )) }) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert:
		((error at: #message) includesSubstring: 'No variable named missingTrackedSlot is accessible in the requested scope.')
]

{ #category : 'private' }
MCPToolMethodLookupTest >> toolNamed: aToolName dataFromArguments: arguments [

	^ self dataFrom: (self callToolNamed: aToolName withArguments: arguments)
]

{ #category : 'private' }
MCPToolMethodLookupTest >> traitFixtureImplementors [

	| result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#kind -> 'implementors').
			          (#query -> 'mcpTraitFixtureValue').
			          (self searchScope: { (#classes -> {
					            TMCPToolMethodSearchFixture name.
					            MCPToolMethodSearchTraitUser name.
					            MCPToolMethodSearchTraitOtherUser name.
					            MCPToolMethodSearchTraitOverrider name }) }) } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	^ (self dataFrom: result) at: #methods
]
