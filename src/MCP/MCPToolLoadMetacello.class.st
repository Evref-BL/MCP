"
Common behavior for tools that load Metacello baselines.
"
Class {
	#name : 'MCPToolLoadMetacello',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolLoadMetacello class >> isAbstract [

	^ self = MCPToolLoadMetacello
]

{ #category : 'metadata' }
MCPToolLoadMetacello >> additionalKeywords [

	^ #( 'baseline' 'metacello' 'load' 'package' )
]

{ #category : 'private - execution' }
MCPToolLoadMetacello >> commandForRequest: loadRequest [

	self subclassResponsibility
]

{ #category : 'defaults' }
MCPToolLoadMetacello >> defaultOnConflict [

	^ 'useLoaded'
]

{ #category : 'defaults' }
MCPToolLoadMetacello >> defaultOnDowngrade [

	^ MCPLoadPolicySpec defaultOnDowngrade
]

{ #category : 'defaults' }
MCPToolLoadMetacello >> defaultOnLock [

	^ MCPLoadPolicySpec defaultOnLock
]

{ #category : 'defaults' }
MCPToolLoadMetacello >> defaultOnUpgrade [

	^ MCPLoadPolicySpec defaultOnUpgrade
]

{ #category : 'defaults' }
MCPToolLoadMetacello >> defaultOnWarning [

	^ 'log'
]

{ #category : 'private - errors' }
MCPToolLoadMetacello >> errorDetailsForError: anError loadRequest: loadRequest rawRequest: rawRequest [

	| context details |
	details := anError
		           mcpCommandErrorDo: [ :commandError |
		           commandError structuredDetails copy ]
		           otherwise: [ self errorDetailsFor: anError ].
	context := self
		           requestedContextForErrorFromLoadRequest: loadRequest
		           rawRequest: rawRequest.
	context keysAndValuesDo: [ :key :value |
		value ifNotNil: [ details at: key ifAbsentPut: [ value ] ] ].
	^ details
]

{ #category : 'private - errors' }
MCPToolLoadMetacello >> errorResultForError: anError loadRequest: loadRequest rawRequest: rawRequest [

	^ self
		  errorResultText: (self
				   failureSummaryForError: anError
				   loadRequest: loadRequest
				   rawRequest: rawRequest)
		  details: (self
				   errorDetailsForError: anError
				   loadRequest: loadRequest
				   rawRequest: rawRequest)
]

{ #category : 'executing' }
MCPToolLoadMetacello >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :loadRequest |
				  | result |
				  result := (self commandForRequest: loadRequest) execute.
				  self
					  successResultText: (self successSummaryForResult: result)
					  data: result asDictionary ]
		  onError: [ :error :loadRequest |
				  self
					  errorResultForError: error
					  loadRequest: loadRequest
					  rawRequest: request ]
]

{ #category : 'private - errors' }
MCPToolLoadMetacello >> failureSummaryForError: anError loadRequest: loadRequest rawRequest: rawRequest [

	| baseline message |
	message := anError messageText
		           ifNil: [ anError asString ]
		           ifNotNil: [ :text | text asString ].
	loadRequest ifNil: [ ^ 'Failed to load baseline: ' , message ].
	baseline := loadRequest baseline ifNil: [ '' ].
	^ String streamContents: [ :stream |
			  stream nextPutAll: 'Failed to load baseline'.
			  baseline isEmpty ifFalse: [
					  stream
						  space;
						  nextPutAll: baseline ].
			  stream
				  nextPutAll: ': ';
				  nextPutAll: message ]
]

{ #category : 'metadata' }
MCPToolLoadMetacello >> groupName [

	^ 'repositories'
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> groupsSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'groups'
		  description: 'Metacello load groups.'
		  itemDescription: nil
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> loadBaselineDataProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'baseline'
			   type: 'string'
			   description: 'The Metacello baseline name loaded.').
		  self loadPolicyOutputSchemaProperty.
		  (self
			   stringArraySchemaNamed: 'newPackageNames'
			   description: 'Packages that appeared in the image after load.'
			   itemDescription: 'A package name.').
		  self repositoriesOutputSchemaProperty }
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> loadBaselineOutputSchemaProperty [

	^ (self
		   schemaPropertyNamed: 'load'
		   type: 'object'
		   description: 'Baseline load details for Metacello load.')
		  properties: self loadBaselineDataProperties;
		  required: #( 'baseline' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> loadPolicyDataProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'warning'
			   type: 'string'
			   description: 'Warning policy used.').
		  (self
			   schemaPropertyNamed: 'conflict'
			   type: 'string'
			   description: 'Conflict policy used.').
		  (self stringArraySchemaNamed: 'conflictUseIncoming').
		  (self stringArraySchemaNamed: 'conflictUseLoaded').
		  (self
			   schemaPropertyNamed: 'upgrade'
			   type: 'string'
			   description: 'Upgrade policy used.').
		  (self stringArraySchemaNamed: 'upgradeUseLoaded').
		  (self
			   schemaPropertyNamed: 'downgrade'
			   type: 'string'
			   description: 'Downgrade policy used.').
		  (self stringArraySchemaNamed: 'downgradeUseIncoming').
		  (self
			   schemaPropertyNamed: 'lock'
			   type: 'string'
			   description: 'Lock policy used.').
		  (self stringArraySchemaNamed: 'lockBreak') }
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> loadPolicyInputSchemaProperties [

	^ { self loadPolicyInputSchemaProperty }
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> loadPolicyInputSchemaProperty [

	^ (self
		   schemaPropertyNamed: 'policy'
		   type: 'object'
		   description: 'Metacello load policy.')
		  properties: {
				  self onWarningSchemaProperty.
				  self onConflictSchemaProperty.
				  self onConflictUseIncomingSchemaProperty.
				  self onConflictUseLoadedSchemaProperty.
				  self onUpgradeSchemaProperty.
				  self onUpgradeUseLoadedSchemaProperty.
				  self onDowngradeSchemaProperty.
				  self onDowngradeUseIncomingSchemaProperty.
				  self onLockSchemaProperty.
				  self onLockBreakSchemaProperty };
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> loadPolicyOutputSchemaProperty [

	^ (self
		   schemaPropertyNamed: 'policy'
		   type: 'object'
		   description:
			   'Metacello load policy values that differ from defaults.')
		  properties: self loadPolicyDataProperties;
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> nonEmptyStringSchemaPropertyNamed: propertyName description: propertyDescription [

	^ (self
		   schemaPropertyNamed: propertyName
		   type: 'string'
		   description: propertyDescription)
		  minLength: 1;
		  yourself
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> onConflictSchemaProperty [

	^ self
		  stringEnumSchemaPropertyNamed: 'conflict'
		  description: 'Conflict policy.'
		  values: #( 'useLoaded' 'useIncoming' 'pass' )
		  default: self defaultOnConflict
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> onConflictUseIncomingSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'conflictUseIncoming'
		  description: 'Projects using incoming registrations on conflict.'
		  itemDescription: nil
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> onConflictUseLoadedSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'conflictUseLoaded'
		  description: 'Projects keeping loaded registrations on conflict.'
		  itemDescription: nil
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> onDowngradeSchemaProperty [

	^ self
		  stringEnumSchemaPropertyNamed: 'downgrade'
		  description: 'Downgrade policy.'
		  values: #( 'useIncoming' 'pass' )
		  default: self defaultOnDowngrade
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> onDowngradeUseIncomingSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'downgradeUseIncoming'
		  description: 'Projects using incoming registrations on downgrade.'
		  itemDescription: nil
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> onLockBreakSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'lockBreak'
		  description: 'Projects with locks to break.'
		  itemDescription: nil
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> onLockSchemaProperty [

	^ self
		  stringEnumSchemaPropertyNamed: 'lock'
		  description: 'Lock policy.'
		  values: #( 'break' 'pass' )
		  default: self defaultOnLock
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> onUpgradeSchemaProperty [

	^ self
		  stringEnumSchemaPropertyNamed: 'upgrade'
		  description: 'Upgrade policy.'
		  values: #( 'useLoaded' 'pass' )
		  default: self defaultOnUpgrade
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> onUpgradeUseLoadedSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'upgradeUseLoaded'
		  description: 'Projects keeping loaded registrations on upgrade.'
		  itemDescription: nil
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> onWarningSchemaProperty [

	^ self
		  stringEnumSchemaPropertyNamed: 'warning'
		  description: 'Warning policy.'
		  values: #( 'log' 'resume' 'pass' )
		  default: self defaultOnWarning
]

{ #category : 'private - request' }
MCPToolLoadMetacello >> parsedRequestFromToolRequest: request [

	self subclassResponsibility
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> repositoriesOutputSchemaProperty [

	| property |
	property := self
		            schemaPropertyNamed: 'repositories'
		            type: 'array'
		            description:
		            'Iceberg repositories newly registered during the load, when detectable.'.
	property items: self repositoryInfoOutputSchemaProperty.
	^ property
]

{ #category : 'private - schema' }
MCPToolLoadMetacello >> repositoryInfoOutputSchemaProperty [

	^ MCPStructureProperties new
		  type: 'object';
		  description:
			  'Structured metadata for one Iceberg repository newly registered during the load.';
		  additionalProperties: true;
		  yourself
]

{ #category : 'private - errors' }
MCPToolLoadMetacello >> requestedContextForErrorFromLoadRequest: loadRequest rawRequest: rawRequest [

	loadRequest ifNotNil: [ ^ loadRequest requestedContext ].
	^ rawRequest asDictionary copy
]

{ #category : 'private - results' }
MCPToolLoadMetacello >> successSummaryForResult: aResult [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Loaded baseline ';
				  nextPutAll: aResult baseline;
				  nextPut: $..
			  aResult newPackageNames isEmpty ifFalse: [
					  stream
						  space;
						  nextPutAll: aResult newPackageNames size asString;
						  nextPutAll: ' new packages were detected.' ] ]
]
