"
Shared method-domain helper behavior for MCP tools. Kept as a trait so method tools can combine it with query or edit tool behavior.
"
Trait {
	#name : 'TMCPMethodTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - methods' }
TMCPMethodTool >> behaviorNamed: aClassName classSide: aBoolean [

	| targetClass |
	targetClass := self class environment at: aClassName asSymbol.
	^ aBoolean
		  ifTrue: [ targetClass classSide ]
		  ifFalse: [ targetClass ]
]

{ #category : 'private - methods' }
TMCPMethodTool >> methodEntryLabel: anEntry [

	^ self
		  methodReferenceForClassName: (anEntry at: #className)
		  selector: (anEntry at: #selector)
		  isClassSide: (anEntry at: #classSide)
]

{ #category : 'private - methods' }
TMCPMethodTool >> methodForClassNamed: className selector: selectorString classSide: classSide [

	| behavior selectorSymbol |
	behavior := self behaviorNamed: className classSide: classSide.
	selectorSymbol := selectorString asSymbol.
	(behavior includesSelector: selectorSymbol) ifFalse: [
		MCPCommandError
			signalMissingMethodInClassName: className
			classSide: classSide
			selector: selectorString ].
	^ behavior compiledMethodAt: selectorSymbol
]

{ #category : 'private - schema' }
TMCPMethodTool >> methodQueryScopeInputProperties [

	^ {
		  self methodSideSchemaProperty.
		  self methodScopePackageNamesProperty.
		  self methodScopeClassNamesProperty.
		  self methodScopeHierarchyClassNamesProperty.
		  self methodScopeSubclassClassNamesProperty.
		  self methodScopeParentClassNamesProperty }
]

{ #category : 'private - methods' }
TMCPMethodTool >> methodReferenceForBehavior: aBehavior selector: aSelector [

	^ String streamContents: [ :stream |
		  stream nextPutAll: (self targetNameForBehavior: aBehavior).
		  stream nextPutAll: '>>'.
		  stream nextPutAll: aSelector asString ]
]

{ #category : 'private - methods' }
TMCPMethodTool >> methodReferenceForClassName: aClassName selector: aSelector isClassSide: isClassSide [

	^ String streamContents: [ :stream |
		  stream nextPutAll: aClassName.
		  isClassSide ifTrue: [ stream nextPutAll: ' class' ].
		  stream
			  nextPutAll: '>>';
			  nextPutAll: aSelector ]
]

{ #category : 'private - schema' }
TMCPMethodTool >> methodScopeClassNamesProperty [

	^ self
		  stringArraySchemaNamed: 'classNames'
		  description:
		  'Method scope. Exact class names whose methods are included. Omit all method scope properties to search all methods. Combine with other method scope properties to union scopes.'
		  itemDescription: 'A class name.'
]

{ #category : 'private - schema' }
TMCPMethodTool >> methodScopeHierarchyClassNamesProperty [

	^ self
		  stringArraySchemaNamed: 'hierarchyClassNames'
		  description:
		  'Method scope. Class names whose superclasses, subclasses, and own methods are included. Omit all method scope properties to search all methods. Combine with other method scope properties to union scopes.'
		  itemDescription: 'A hierarchy root class name.'
]

{ #category : 'private - schema' }
TMCPMethodTool >> methodScopePackageNamesProperty [

	^ self
		  stringArraySchemaNamed: 'packageNames'
		  description:
		  'Method scope. Package names whose defined methods and extension methods are included. Omit all method scope properties to search all methods. Combine with other method scope properties to union scopes.'
		  itemDescription: 'A package name.'
]

{ #category : 'private - schema' }
TMCPMethodTool >> methodScopeParentClassNamesProperty [

	^ self
		  stringArraySchemaNamed: 'parentClassNames'
		  description:
		  'Method scope. Class names whose superclass methods are included. The named classes are excluded unless classNames also includes them. Combine with other method scope properties to union scopes.'
		  itemDescription: 'A class name whose superclasses are included.'
]

{ #category : 'private - methods' }
TMCPMethodTool >> methodScopeQueryFromRequest: request [

	^ MCPCompiledMethodScopeQuery new
		  packageNames:
			  (request stringCollectionArgumentNamed: 'packageNames');
		  classNames: (request stringCollectionArgumentNamed: 'classNames');
		  hierarchyClassNames:
			  (request stringCollectionArgumentNamed: 'hierarchyClassNames');
		  subclassClassNames:
			  (request stringCollectionArgumentNamed: 'subclassClassNames');
		  parentClassNames:
			  (request stringCollectionArgumentNamed: 'parentClassNames');
		  side: (request stringArgumentNamed: 'side' default: 'both');
		  yourself
]

{ #category : 'private - schema' }
TMCPMethodTool >> methodScopeSubclassClassNamesProperty [

	^ self
		  stringArraySchemaNamed: 'subclassClassNames'
		  description:
		  'Method scope. Class names whose subclass methods are included. The named classes are excluded unless classNames also includes them. Combine with other method scope properties to union scopes.'
		  itemDescription: 'A class name whose subclasses are included.'
]

{ #category : 'private - schema' }
TMCPMethodTool >> methodSideSchemaProperty [

	^ self
		  stringEnumSchemaPropertyNamed: 'side'
		  description:
		  'Which method side to search. instance searches instance-side methods, class searches class-side methods, and both searches both sides.'
		  values: #( 'instance' 'class' 'both' )
		  default: 'both'
]

{ #category : 'private - request' }
TMCPMethodTool >> selectorStringFromRequest: request [

	^ request stringArgumentNamed: 'selector'
]

{ #category : 'private - methods' }
TMCPMethodTool >> targetNameForBehavior: aBehavior [

	^ aBehavior isMeta
		  ifTrue: [ aBehavior instanceSide name , ' class' ]
		  ifFalse: [ aBehavior name ]
]
