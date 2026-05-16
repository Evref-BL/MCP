"
Parsed recursive predicate for Find tool where clauses. Instances are built from MCPToolRequest input and consumed by query execution; raw request dictionaries should not flow past this boundary.
"
Class {
	#name : 'MCPWhereSpec',
	#superclass : 'Object',
	#instVars : [
		'kind',
		'children',
		'field',
		'value',
		'mode',
		'caseSensitive',
		'filterTargets',
		'relation',
		'whereSpec',
		'methodReferenceSpec'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPWhereSpec class >> absent [

	^ self new
		  kind: #absent;
		  yourself
]

{ #category : 'instance creation' }
MCPWhereSpec class >> all: childSpecs [

	^ self new
		  kind: #all;
		  children: childSpecs asArray;
		  yourself
]

{ #category : 'instance creation' }
MCPWhereSpec class >> any: childSpecs [

	^ self new
		  kind: #any;
		  children: childSpecs asArray;
		  yourself
]

{ #category : 'private - parsing' }
MCPWhereSpec class >> booleanValueNamed: aName in: aDictionary default: defaultValue [

	^ self valueNamed: aName in: aDictionary ifAbsent: [ defaultValue ]
]

{ #category : 'instance creation' }
MCPWhereSpec class >> equivalentTo: aMethodReferenceSpec [

	^ self new
		  kind: #equivalentTo;
		  methodReferenceSpec: aMethodReferenceSpec;
		  yourself
]

{ #category : 'private - parsing' }
MCPWhereSpec class >> equivalentToSpecFrom: aDictionary [

	^ self equivalentTo: (MCPMethodReferenceSpec fromValue: (self
				    valueNamed: 'equivalentTo'
				    in: aDictionary
				    ifAbsent: [
				    Error signal:
					    'equivalentTo where predicate requires equivalentTo.' ]))
]

{ #category : 'instance creation' }
MCPWhereSpec class >> exists: aRelation where: aWhereSpec [

	^ self new
		  kind: #exists;
		  relation: aRelation;
		  whereSpec: aWhereSpec;
		  yourself
]

{ #category : 'private - parsing' }
MCPWhereSpec class >> existsSpecFrom: aDictionary [

	^ self
		  exists:
		  (self
			   requiredStringValueNamed: 'exists'
			   in: aDictionary
			   for: 'exists')
		  where: (self nestedWhereIn: aDictionary)
]

{ #category : 'instance creation' }
MCPWhereSpec class >> field: aField value: aValue mode: aMode caseSensitive: aBoolean [

	^ self new
		  kind: #field;
		  field: aField;
		  value: aValue;
		  mode: aMode;
		  caseSensitive: aBoolean;
		  yourself
]

{ #category : 'private - parsing' }
MCPWhereSpec class >> fieldSpecFrom: aDictionary [

	^ self
		  field:
		  (self
			   requiredStringValueNamed: 'field'
			   in: aDictionary
			   for: 'field')
		  value:
		  (self
			   requiredStringValueNamed: 'value'
			   in: aDictionary
			   for: 'field')
		  mode:
		  (self
			   stringValueNamed: 'mode'
			   in: aDictionary
			   default: 'substring')
		  caseSensitive:
		  (self
			   booleanValueNamed: 'caseSensitive'
			   in: aDictionary
			   default: true)
]

{ #category : 'instance creation' }
MCPWhereSpec class >> filter: aPattern mode: aMode targets: targets caseSensitive: aBoolean [

	^ self new
		  kind: #filter;
		  value: aPattern;
		  mode: aMode;
		  filterTargets: targets;
		  caseSensitive: aBoolean;
		  yourself
]

{ #category : 'private - parsing' }
MCPWhereSpec class >> filterSpecFrom: aDictionary [

	^ self
		  filter:
		  (self
			   requiredStringValueNamed: 'filter'
			   in: aDictionary
			   for: 'filter')
		  mode: (self
				   stringValueNamed: 'filterMode'
				   in: aDictionary
				   default: 'substring')
		  targets: (self
				   stringCollectionValueNamed: 'filterTargets'
				   in: aDictionary
				   default: nil)
		  caseSensitive:
		  (self
			   booleanValueNamed: 'caseSensitive'
			   in: aDictionary
			   default: true)
]

{ #category : 'instance creation' }
MCPWhereSpec class >> fromToolRequest: request [

	| rawWhere |
	rawWhere := request
		            argumentNamed: 'where'
		            ifAbsent: [ ^ self absent ].
	rawWhere ifNil: [ ^ self absent ].
	^ self fromValue: rawWhere
]

{ #category : 'instance creation' }
MCPWhereSpec class >> fromValue: rawValue [

	(self isDictionaryLike: rawValue) ifFalse: [
		Error signal: 'where must be an object.' ].
	(self hasKey: 'all' in: rawValue) ifTrue: [
		^ self all: (self predicateArrayNamed: 'all' in: rawValue) ].
	(self hasKey: 'any' in: rawValue) ifTrue: [
		^ self any: (self predicateArrayNamed: 'any' in: rawValue) ].
	(self hasKey: 'not' in: rawValue) ifTrue: [
		^ self not: (self fromValue:
				   (self valueNamed: 'not' in: rawValue ifAbsent: [ nil ])) ].
	(self hasKey: 'exists' in: rawValue) ifTrue: [
		^ self existsSpecFrom: rawValue ].
	(self hasKey: 'none' in: rawValue) ifTrue: [
		^ self noneSpecFrom: rawValue ].
	(self hasKey: 'equivalentTo' in: rawValue) ifTrue: [
		^ self equivalentToSpecFrom: rawValue ].
	((self hasKey: 'filter' in: rawValue) or: [
		 self hasKey: 'filterMode' in: rawValue ]) ifTrue: [
		^ self filterSpecFrom: rawValue ].
	(self hasKey: 'field' in: rawValue) ifTrue: [
		^ self fieldSpecFrom: rawValue ].
	Error signal:
		'where predicate must use one of filter, field, equivalentTo, all, any, not, exists, or none.'
]

{ #category : 'private - parsing' }
MCPWhereSpec class >> hasKey: aName in: aDictionary [

	^ (aDictionary includesKey: aName asSymbol) or: [
		  aDictionary includesKey: aName asString ]
]

{ #category : 'private - parsing' }
MCPWhereSpec class >> isDictionaryLike: aValue [

	aValue ifNil: [ ^ false ].
	^ aValue isDictionary
]

{ #category : 'private - parsing' }
MCPWhereSpec class >> nestedWhereIn: aDictionary [

	| rawWhere |
	rawWhere := self
		            valueNamed: 'where'
		            in: aDictionary
		            ifAbsent: [ ^ self absent ].
	rawWhere ifNil: [ ^ self absent ].
	^ self fromValue: rawWhere
]

{ #category : 'instance creation' }
MCPWhereSpec class >> none: aRelation where: aWhereSpec [

	^ self new
		  kind: #none;
		  relation: aRelation;
		  whereSpec: aWhereSpec;
		  yourself
]

{ #category : 'private - parsing' }
MCPWhereSpec class >> noneSpecFrom: aDictionary [

	^ self
		  none:
		  (self requiredStringValueNamed: 'none' in: aDictionary for: 'none')
		  where: (self nestedWhereIn: aDictionary)
]

{ #category : 'instance creation' }
MCPWhereSpec class >> not: aWhereSpec [

	^ self new
		  kind: #not;
		  whereSpec: aWhereSpec;
		  yourself
]

{ #category : 'private - parsing' }
MCPWhereSpec class >> predicateArrayNamed: aName in: aDictionary [

	| rawValue specs |
	rawValue := self
		            valueNamed: aName
		            in: aDictionary
		            ifAbsent: [
		            Error signal:
			            aName , ' must be an array of where predicates.' ].
	(rawValue isNil or: [
		 rawValue isString or: [ self isDictionaryLike: rawValue ] ])
		ifTrue: [
		Error signal: aName , ' must be an array of where predicates.' ].
	(rawValue respondsTo: #do:) ifFalse: [
		Error signal: aName , ' must be an array of where predicates.' ].
	specs := OrderedCollection new.
	rawValue do: [ :each | specs add: (self fromValue: each) ].
	^ specs asArray
]

{ #category : 'private - parsing' }
MCPWhereSpec class >> requiredStringValueNamed: aName in: aDictionary for: predicateName [

	| valueString |
	valueString := self
		               stringValueNamed: aName
		               in: aDictionary
		               default: nil.
	valueString ifNil: [
		Error signal:
			predicateName , ' where predicate requires ' , aName , '.' ].
	^ valueString
]

{ #category : 'private - parsing' }
MCPWhereSpec class >> stringCollectionValueNamed: aName in: aDictionary default: defaultCollection [

	| collection rawValue values |
	rawValue := self
		            valueNamed: aName
		            in: aDictionary
		            ifAbsent: [ ^ defaultCollection ].
	rawValue ifNil: [ ^ defaultCollection ].
	(rawValue isString or: [ self isDictionaryLike: rawValue ]) ifTrue: [
		Error signal: aName , ' must be an array of strings.' ].
	(rawValue respondsTo: #do:) ifFalse: [
		Error signal: aName , ' must be an array of strings.' ].
	values := OrderedCollection new.
	rawValue do: [ :each |
		(self stringValueFrom: each) ifNotNil: [ :stringValue |
			(values includes: stringValue) ifFalse: [ values add: stringValue ] ] ].
	^ values asArray
]

{ #category : 'private - parsing' }
MCPWhereSpec class >> stringValueFrom: aValue [

	| normalized |
	aValue ifNil: [ ^ nil ].
	normalized := aValue asString trimBoth.
	^ normalized isEmpty
		  ifTrue: [ nil ]
		  ifFalse: [ normalized ]
]

{ #category : 'private - parsing' }
MCPWhereSpec class >> stringValueNamed: aName in: aDictionary default: defaultValue [

	| rawValue |
	rawValue := self
		            valueNamed: aName
		            in: aDictionary
		            ifAbsent: [ ^ defaultValue ].
	^ (self stringValueFrom: rawValue)
		  ifNil: [ defaultValue ]
		  ifNotNil: [ :valueString | valueString ]
]

{ #category : 'private - parsing' }
MCPWhereSpec class >> valueNamed: aName in: aDictionary ifAbsent: absentBlock [

	^ aDictionary
		  at: aName asSymbol
		  ifAbsent: [ aDictionary at: aName asString ifAbsent: absentBlock ]
]

{ #category : 'accessing' }
MCPWhereSpec >> caseSensitive [

	^ caseSensitive ifNil: [ true ]
]

{ #category : 'accessing' }
MCPWhereSpec >> caseSensitive: aBoolean [

	caseSensitive := aBoolean
]

{ #category : 'accessing' }
MCPWhereSpec >> children [

	^ children ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPWhereSpec >> children: anObject [

	children := anObject ifNil: [ #(  ) ] ifNotNil: [ anObject asArray ]
]

{ #category : 'accessing' }
MCPWhereSpec >> field [

	^ field
]

{ #category : 'accessing' }
MCPWhereSpec >> field: anObject [

	field := anObject
]

{ #category : 'accessing' }
MCPWhereSpec >> filterTargets [

	^ filterTargets
]

{ #category : 'accessing' }
MCPWhereSpec >> filterTargets: aCollection [

	filterTargets := aCollection
		                 ifNil: [ nil ]
		                 ifNotNil: [ aCollection asArray ]
]

{ #category : 'initialization' }
MCPWhereSpec >> initialize [

	super initialize.
	kind := #absent.
	children := #(  ).
	caseSensitive := true
]

{ #category : 'testing' }
MCPWhereSpec >> isAbsent [

	^ self kind = #absent
]

{ #category : 'accessing' }
MCPWhereSpec >> kind [

	^ kind
]

{ #category : 'accessing' }
MCPWhereSpec >> kind: anObject [

	kind := anObject
]

{ #category : 'evaluating' }
MCPWhereSpec >> matchesEvaluation: evaluation [

	self kind = #absent ifTrue: [ ^ true ].
	self kind = #all ifTrue: [
		^ self children allSatisfy: [ :each |
			  each matchesEvaluation: evaluation ] ].
	self kind = #any ifTrue: [
		^ self children anySatisfy: [ :each |
			  each matchesEvaluation: evaluation ] ].
	self kind = #not ifTrue: [
		^ (self whereSpec matchesEvaluation: evaluation) not ].
	self kind = #field ifTrue: [
		^ evaluation tool whereFieldSpec: self matchesEvaluation: evaluation ].
	self kind = #filter ifTrue: [
		^ evaluation tool
			  whereFilterSpec: self
			  matchesEvaluation: evaluation ].
	self kind = #equivalentTo ifTrue: [
		^ evaluation tool
			  whereEquivalentToSpec: self
			  matchesEvaluation: evaluation ].
	self kind = #exists ifTrue: [
		^ evaluation tool
			  whereRelationSpec: self
			  matchesEvaluation: evaluation
			  expectAny: true ].
	self kind = #none ifTrue: [
		^ evaluation tool
			  whereRelationSpec: self
			  matchesEvaluation: evaluation
			  expectAny: false ].
	Error signal:
		'Unsupported where predicate kind: ' , self kind asString
]

{ #category : 'accessing' }
MCPWhereSpec >> methodReferenceSpec [

	^ methodReferenceSpec
]

{ #category : 'accessing' }
MCPWhereSpec >> methodReferenceSpec: aMethodReferenceSpec [

	methodReferenceSpec := aMethodReferenceSpec
]

{ #category : 'accessing' }
MCPWhereSpec >> mode [

	^ mode
]

{ #category : 'accessing' }
MCPWhereSpec >> mode: anObject [

	mode := anObject
]

{ #category : 'accessing' }
MCPWhereSpec >> relation [

	^ relation
]

{ #category : 'accessing' }
MCPWhereSpec >> relation: anObject [

	relation := anObject
]

{ #category : 'accessing' }
MCPWhereSpec >> value [

	^ value
]

{ #category : 'accessing' }
MCPWhereSpec >> value: anObject [

	value := anObject
]

{ #category : 'accessing' }
MCPWhereSpec >> whereSpec [

	^ whereSpec ifNil: [ MCPWhereSpec absent ]
]

{ #category : 'accessing' }
MCPWhereSpec >> whereSpec: anObject [

	whereSpec := anObject
]
