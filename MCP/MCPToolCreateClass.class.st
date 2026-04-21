Class {
	#name : 'MCPToolCreateClass',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolCreateClass >> buildClassFromArguments: arguments [

	| builder packageName tag |
	packageName := self packageNameFromArguments: arguments.
	self ensurePackageNamed: packageName.
	builder := (self superclassFromArguments: arguments)
	           << (self classNameSymbolFromArguments: arguments).
	builder package: packageName.
	tag := arguments at: #tag ifAbsent: [ nil ].
	(tag notNil and: [ tag isNotEmpty ]) ifTrue: [ builder tag: tag ].
	builder slots: (self slotsFromArguments: arguments).
	(arguments includesKey: #classSlots) ifTrue: [
		builder classSlots: (self classSlotsFromArguments: arguments) ].
	^ builder install
]

{ #category : 'private' }
MCPToolCreateClass >> classNameSymbolFromArguments: arguments [

	^ (arguments at: #className) asSymbol
]

{ #category : 'private' }
MCPToolCreateClass >> classSlotsFromArguments: arguments [

	| classSlots |
	classSlots := arguments at: #classSlots ifAbsent: [ #(  ) ].
	^ classSlots
		  ifNil: [ #(  ) ]
		  ifNotNil: [ classSlots collect: [ :each | each asSymbol ] ]
]

{ #category : 'private' }
MCPToolCreateClass >> ensurePackageNamed: aPackageName [

	self packageOrganizer ensurePackage: aPackageName
]

{ #category : 'executing' }
MCPToolCreateClass >> executeWithArguments: arguments [

	| classNameSymbol createdClass |
	classNameSymbol := self classNameSymbolFromArguments: arguments.
	(self class environment includesKey: classNameSymbol) ifTrue: [
		self error: 'Class ' , classNameSymbol asString , ' already exists.' ].
	createdClass := self buildClassFromArguments: arguments.
	^ { (MCPStructureTextContent text:
		   (self successMessageFor: createdClass)) }
]

{ #category : 'initialization' }
MCPToolCreateClass >> initialize [

	super initialize.
	name := 'pharo-create-class'.
	title := 'Create Pharo Class'.
	description := 'Creates a new class in the Pharo image using the class builder.'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: {
				               (MCPStructureProperties new
					                name: 'className';
					                type: 'string';
					                description: 'The name of the class to create.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'superclassName';
					                type: 'string';
					                description:
						                'The name of the superclass for the new class.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'packageName';
					                type: 'string';
					                description:
						                'The package that will own the new class.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'tag';
					                type: 'string';
					                description:
						                'An optional package tag for the new class.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'slots';
					                type: 'array';
					                description:
						                'Optional instance-side slot names for the new class.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'classSlots';
					                type: 'array';
					                description:
						                'Optional class-side slot names for the new class.';
					                yourself) };
		               required:
		               #( 'className' 'superclassName' 'packageName' );
		               yourself.
	icons := {  }
]

{ #category : 'private' }
MCPToolCreateClass >> packageNameFromArguments: arguments [

	^ arguments at: #packageName
]

{ #category : 'private' }
MCPToolCreateClass >> slotsFromArguments: arguments [

	| slots |
	slots := arguments at: #slots ifAbsent: [ #(  ) ].
	^ slots
		  ifNil: [ #(  ) ]
		  ifNotNil: [ slots collect: [ :each | each asSymbol ] ]
]

{ #category : 'private' }
MCPToolCreateClass >> successMessageFor: aClass [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Created class ';
			  nextPutAll: aClass name;
			  nextPutAll: ' < ';
			  nextPutAll: aClass superclass name;
			  nextPutAll: ' in package ';
			  nextPutAll: aClass packageName asString.
		  aClass packageTagName ~= #Uncategorized ifTrue: [
			  stream
				  nextPutAll: ' with tag ';
				  nextPutAll: aClass packageTagName asString ].
		  stream
			  nextPutAll: ' (';
			  print: aClass slots size;
			  nextPutAll: ' instance slot'.
		  aClass slots size = 1 ifFalse: [ stream nextPut: $s ].
		  stream
			  nextPutAll: ', ';
			  print: aClass classSide slots size;
			  nextPutAll: ' class slot'.
		  aClass classSide slots size = 1 ifFalse: [ stream nextPut: $s ].
		  stream nextPutAll: ').' ]
]

{ #category : 'private' }
MCPToolCreateClass >> superclassFromArguments: arguments [

	^ self class environment at: (arguments at: #superclassName) asSymbol
]
