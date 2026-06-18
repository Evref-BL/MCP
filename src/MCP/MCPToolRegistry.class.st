"
Builds the concrete MCP tool set for a server instance.

The registry centralizes tool construction, exposure policy defaults, and catalog membership so static and discoverable surfaces stay consistent.
"
Class {
	#name : 'MCPToolRegistry',
	#superclass : 'Object',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'tools' }
MCPToolRegistry class >> activationRequirementsForTool: aTool [

	^ #(  )
]

{ #category : 'tools' }
MCPToolRegistry class >> additionalKeywordsForTool: aTool [

	| toolName |
	toolName := aTool name.
	toolName = 'tool_get' ifTrue: [
		^ #( 'tool' 'catalog' 'contract' 'schema' 'metadata' ) ].
	toolName = 'repository_search' ifTrue: [
		^ #( 'repo' 'iceberg' 'git' 'branch' 'commit' 'remote' 'head' ) ].
	toolName = 'repository_identity_verify' ifTrue: [
		^ #( 'repo' 'iceberg' 'git' 'guard' 'identity' ) ].
	toolName = 'repository_change_list' ifTrue: [
		^ #( 'repo' 'iceberg' 'git' 'diff' 'status' 'change' ) ].
	toolName = 'repository_create' ifTrue: [
		^ #( 'repo' 'iceberg' 'git' 'create' 'package' ) ].
	toolName = 'repository_attach' ifTrue: [
		^ #( 'repo' 'iceberg' 'git' 'attach' 'package' ) ].
	toolName = 'repository_update' ifTrue: [
		^ #( 'repo' 'iceberg' 'update' 'package' 'metadata' ) ].
	toolName = 'repository_export' ifTrue: [
		^ #( 'repo' 'iceberg' 'tonel' 'export' 'write' ) ].
	toolName = 'repository_commit' ifTrue: [
		^ #( 'repo' 'iceberg' 'git' 'commit' ) ].
	toolName = 'repository_fetch' ifTrue: [
		^ #( 'repo' 'iceberg' 'git' 'remote' 'fetch' ) ].
	toolName = 'repository_pull' ifTrue: [
		^ #( 'repo' 'iceberg' 'git' 'remote' 'pull' ) ].
	toolName = 'repository_push' ifTrue: [
		^ #( 'repo' 'iceberg' 'git' 'remote' 'push' ) ].
	toolName = 'repository_branch_create' ifTrue: [
		^ #( 'repo' 'iceberg' 'git' 'branch' 'create' ) ].
	toolName = 'repository_branch_switch' ifTrue: [
		^ #( 'repo' 'iceberg' 'git' 'branch' 'switch' ) ].
	toolName = 'repository_branch_checkout' ifTrue: [
		^ #( 'repo' 'iceberg' 'git' 'branch' 'checkout' 'reload' 'stale' 'verification' ) ].
	toolName = 'repository_head_adopt' ifTrue: [
		^ #( 'repo' 'iceberg' 'git' 'head' 'adopt' ) ].
	toolName = 'baseline_load' ifTrue: [
		^ #( 'baseline' 'metacello' 'load' 'package' ) ].
	toolName = 'repository_load' ifTrue: [
		^ #( 'repo' 'baseline' 'metacello' 'load' 'package' ) ].
	toolName = 'package_search' ifTrue: [
		^ #( 'package' 'project' 'tag' ) ].
	toolName = 'class_search' ifTrue: [
		^ #( 'class' 'package' 'tag' 'slot' 'trait' 'hierarchy' ) ].
	toolName = 'class_get' ifTrue: [
		^ #( 'class' 'inspect' 'superclass' 'subclass' 'slot' 'trait'
		     'comment' ) ].
	toolName = 'class_create' ifTrue: [
		^ #( 'class' 'create' 'package' 'superclass' 'slot' 'trait' ) ].
	toolName = 'class_name_update' ifTrue: [
		^ #( 'class' 'name' 'rename' 'update' 'refactor' 'refactoring' ) ].
	toolName = 'class_superclass_update' ifTrue: [
			^ #( 'class' 'superclass' 'parent' 'update' 'reparent' 'refactor'
			     'refactoring' ) ].
	toolName = 'class_package_update' ifTrue: [
			^ #( 'class' 'package' 'tag' 'category' 'move' 'update' 'refactor'
			     'refactoring' ) ].
	toolName = 'class_comment_update' ifTrue: [
		^ #( 'class' 'comment' 'update' ) ].
	toolName = 'class_slots_update' ifTrue: [
		^ #( 'class' 'slot' 'definition' 'update' ) ].
	toolName = 'class_traits_update' ifTrue: [
		^ #( 'class' 'trait' 'composition' 'definition' 'update' ) ].
	toolName = 'class_side_traits_update' ifTrue: [
			^ #( 'class' 'trait' 'side' 'metaclass' 'composition' 'definition'
			     'update' ) ].
	toolName = 'class_shared_variables_update' ifTrue: [
		^ #( 'class' 'variable' 'shared' 'classvar' 'binding' 'update' ) ].
	toolName = 'class_shared_pools_update' ifTrue: [
			^ #( 'class' 'pool' 'shared' 'pooldictionary' 'dictionary'
			     'update' ) ].
	toolName = 'class_layout_update' ifTrue: [
			^ #( 'class' 'layout' 'shape' 'format' 'fixed' 'variable'
			     'weak' 'immediate' 'word' 'byte' 'update' ) ].
	toolName = 'class_slot_add' ifTrue: [
		^ #( 'class' 'slot' 'add' 'refactor' 'refactoring' ) ].
	toolName = 'class_slot_remove' ifTrue: [
		^ #( 'class' 'slot' 'remove' 'refactor' 'refactoring' ) ].
	toolName = 'class_slot_name_update' ifTrue: [
		^ #( 'class' 'slot' 'name' 'rename' 'update' 'refactor' 'refactoring' ) ].
	toolName = 'class_slot_pull_up' ifTrue: [
		^ #( 'class' 'slot' 'pull' 'up' 'refactor' 'refactoring' ) ].
	toolName = 'class_slot_push_down' ifTrue: [
		^ #( 'class' 'slot' 'push' 'down' 'refactor' 'refactoring' ) ].
	toolName = 'class_remove' ifTrue: [
		^ #( 'class' 'remove' 'refactor' 'refactoring' ) ].
	toolName = 'method_metadata_search' ifTrue: [
		^ #( 'method' 'selector' 'protocol' 'metadata' 'search' ) ].
	toolName = 'method_source_search' ifTrue: [
		^ #( 'method' 'source' 'code' 'text' 'search' ) ].
	toolName = 'method_equivalent_search' ifTrue: [
		^ #( 'method' 'equivalent' 'ast' 'duplicate' 'semantic' 'search' ) ].
	toolName = 'method_implementor_search' ifTrue: [
		^ #( 'method' 'selector' 'implementor' 'implementation' ) ].
	toolName = 'method_sender_search' ifTrue: [
		^ #( 'method' 'selector' 'sender' 'send' 'reference' ) ].
	toolName = 'method_class_reference_search' ifTrue: [
		^ #( 'method' 'class' 'reference' 'binding' ) ].
	toolName = 'method_variable_reference_search' ifTrue: [
			^ #( 'method' 'variable' 'reference' 'slot' 'temporary' 'classvar'
			     'binding' ) ].
	toolName = 'method_get' ifTrue: [
		^ #( 'method' 'selector' 'protocol' 'source' 'reference' 'variable' ) ].
	toolName = 'method_compile' ifTrue: [
		^ #( 'method' 'source' 'protocol' 'create' 'compile' ) ].
	toolName = 'method_selector_update' ifTrue: [
			^ #( 'method' 'selector' 'signature' 'rename' 'update' 'refactor'
			     'refactoring' ) ].
	toolName = 'method_protocol_update' ifTrue: [
		^ #( 'method' 'protocol' 'category' 'update' ) ].
	toolName = 'method_rewrite' ifTrue: [
			^ #( 'method' 'rewrite' 'preview' 'apply' 'ast' 'pattern' 'refactor'
			     'refactoring' ) ].
	toolName = 'test_run' ifTrue: [ ^ #( 'test' 'sunit' 'timeout' ) ].
	toolName = 'test_coverage_run' ifTrue: [
		^ #( 'test' 'sunit' 'coverage' 'timeout' ) ].
	toolName = 'history_file_list' ifTrue: [
		^ #( 'history' 'change' 'file' 'list' 'ombu' 'epicea' ) ].
	toolName = 'history_entry_list' ifTrue: [
			^ #( 'history' 'change' 'entry' 'browse' 'list' 'inspect' 'ombu'
			     'epicea' ) ].
	toolName = 'history_entry_apply' ifTrue: [
			^ #( 'history' 'change' 'entry' 'preview' 'apply' 'recover'
			     'epicea' 'ombu' ) ].
	toolName = 'history_entry_revert' ifTrue: [
			^ #( 'history' 'change' 'entry' 'preview' 'revert' 'recover'
			     'epicea' 'ombu' ) ].
	toolName = 'screenshot_capture' ifTrue: [
		^ #( 'screenshot' 'capture' 'window' 'display' 'world' 'ui' ) ].
	toolName = 'image_evaluate' ifTrue: [
		^ #( 'expression' 'smalltalk' 'code' ) ].
	(toolName beginsWith: 'debug_') ifTrue: [
			^ #( 'debug' 'session' 'state' 'frame' 'variable' 'breakpoint'
			     'capture' 'control' 'repair' 'exception' ) ].
	^ #(  )
]

{ #category : 'tools' }
MCPToolRegistry class >> contractForTool: aTool [

	^ self contractForTool: aTool usingPolicy: aTool toolExposurePolicy
]

{ #category : 'tools' }
MCPToolRegistry class >> contractForTool: aTool usingPolicy: aToolExposurePolicy [

	^ self
		  contractForTool: aTool
		  usingPolicy: aToolExposurePolicy
		  includeOutputSchema: true
]

{ #category : 'tools' }
MCPToolRegistry class >> contractForTool: aTool usingPolicy: aToolExposurePolicy includeOutputSchema: includeOutputSchema [

	| activationRequirements data examples |
	data := (self metadataForTool: aTool usingPolicy: aToolExposurePolicy)
		        copy.
	data at: #inputSchema put: aTool inputSchema asJRPCJSON.
	includeOutputSchema ifTrue: [
		data at: #outputSchema put: aTool outputSchema asJRPCJSON ].
	examples := self examplesForTool: aTool.
	examples ifNotEmpty: [ data at: #examples put: examples ].
	activationRequirements := self activationRequirementsForTool: aTool.
	activationRequirements ifNotEmpty: [
		data at: #activationRequirements put: activationRequirements ].
	^ data
]

{ #category : 'tools' }
MCPToolRegistry class >> defaultStaticToolNames [

	^ self staticToolClasses collect: [ :each | each toolName ]
]

{ #category : 'tools' }
MCPToolRegistry class >> examplesForTool: aTool [

	^ #(  )
]

{ #category : 'tools' }
MCPToolRegistry class >> exposureForTool: aTool [

	^ self exposureForTool: aTool usingPolicy: aTool toolExposurePolicy
]

{ #category : 'tools' }
MCPToolRegistry class >> exposureForTool: aTool usingPolicy: aToolExposurePolicy [

	^ aToolExposurePolicy exposureForTool: aTool
]

{ #category : 'tools' }
MCPToolRegistry class >> groupNameForToolClass: aToolClass [

	self publicToolGroups do: [ :group |
		(group value includes: aToolClass) ifTrue: [ ^ group key ] ].
	^ 'other'
]

{ #category : 'testing' }
MCPToolRegistry class >> includesToolNamed: aToolName [

	^ self publicToolNames includes: aToolName asString
]

{ #category : 'testing' }
MCPToolRegistry class >> isStaticTool: aToolName [

	^ self
		  isStaticTool: aToolName
		  usingPolicy: MCPToolExposurePolicy default
]

{ #category : 'testing' }
MCPToolRegistry class >> isStaticTool: aToolName usingPolicy: aToolExposurePolicy [

	^ aToolExposurePolicy isStaticTool: aToolName
]

{ #category : 'tools' }
MCPToolRegistry class >> keywordsForTool: aTool [

	| keywords normalizedKeywords |
	keywords := OrderedCollection new.
	keywords addAll: (aTool name findTokens: '-_').
	keywords addAll: (aTool title findTokens: ' -').
	keywords addAll:
		((self groupNameForToolClass: aTool class) findTokens: '-_').
	keywords addAll: (self additionalKeywordsForTool: aTool).
	normalizedKeywords := OrderedCollection new.
	keywords do: [ :each |
		normalizedKeywords addAll: (each asString findTokens: '-_ ') ].
	^ (normalizedKeywords collect: [ :each | each asLowercase ]) asSet
		  asArray
]

{ #category : 'tools' }
MCPToolRegistry class >> metadataForTool: aTool [

	^ self metadataForTool: aTool usingPolicy: aTool toolExposurePolicy
]

{ #category : 'tools' }
MCPToolRegistry class >> metadataForTool: aTool usingPolicy: aToolExposurePolicy [

	^ {
		  (#name -> aTool name).
		  (#title -> aTool title).
		  (#description -> aTool description).
		  (#group -> (self groupNameForToolClass: aTool class)).
		  (#exposure
		   -> (self exposureForTool: aTool usingPolicy: aToolExposurePolicy)).
		  (#mutability -> (self mutabilityForTool: aTool)).
		  (#risk -> (self riskForTool: aTool)).
		  (#keywords -> (self keywordsForTool: aTool)).
		  (#schemaInspectionRequired -> (self
			    schemaInspectionRequiredForTool: aTool
			    usingPolicy: aToolExposurePolicy)) } asDictionary
]

{ #category : 'tools' }
MCPToolRegistry class >> mutabilityForTool: aTool [

	| executeTools readTools toolName |
	toolName := aTool name.
	readTools := #( 'tool_search' 'tool_get' 'repository_search'
	                'repository_identity_verify'
	                'repository_change_list' 'package_search'
	                'class_search' 'class_get' 'method_metadata_search'
	                'method_source_search' 'method_equivalent_search'
	                'method_implementor_search'
	                'method_sender_search' 'method_class_reference_search'
	                'method_variable_reference_search'
	                'method_get' 'history_file_list' 'history_entry_list'
	                'screenshot_capture' 'debug_session_list'
	                'debug_session_get' 'debug_candidate_search'
	                'debug_state_get' 'debug_variable_get'
	                'debug_breakpoint_list' ).
	executeTools := #( 'tool_call' 'test_run' 'test_coverage_run'
	                   'image_evaluate' 'debug_expression_evaluate'
	                   'debug_capture' 'debug_test_run' ).
	(readTools includes: toolName) ifTrue: [ ^ 'read' ].
	(executeTools includes: toolName) ifTrue: [ ^ 'execute' ].
	^ 'write'
]

{ #category : 'tools' }
MCPToolRegistry class >> publicToolClasses [

	| classes |
	classes := OrderedCollection new.
	self publicToolGroups do: [ :group | classes addAll: group value ].
	^ classes asArray
]

{ #category : 'tools' }
MCPToolRegistry class >> publicToolGroups [

	^ {
		  ('tool-catalog' -> {
			   MCPToolSearchTools.
			   MCPToolGetTool.
			   MCPToolCallTool }).
		  ('repositories' -> {
			   MCPToolSearchRepositories.
			   MCPToolVerifyRepositoryIdentity.
			   MCPToolListRepositoryChanges.
			   MCPToolCreateRepository.
			   MCPToolAttachRepository.
			   MCPToolUpdateRepository.
			   MCPToolExportRepository.
			   MCPToolCommitRepository.
			   MCPToolFetchRepository.
			   MCPToolPullRepository.
			   MCPToolPushRepository.
			   MCPToolCreateRepositoryBranch.
			   MCPToolSwitchRepositoryBranch.
			   MCPToolCheckoutRepositoryBranch.
			   MCPToolAdoptRepositoryHead.
			   MCPToolLoadBaseline.
			   MCPToolLoadRepository }).
		  ('packages' -> { MCPToolSearchPackages }).
		  ('classes' -> {
			   MCPToolSearchClasses.
			   MCPToolGetClass.
			   MCPToolCreateClass.
			   MCPToolUpdateClassName.
			   MCPToolUpdateClassSuperclass.
			   MCPToolUpdateClassPackage.
			   MCPToolUpdateClassComment.
			   MCPToolUpdateClassSlots.
			   MCPToolUpdateClassTraits.
			   MCPToolUpdateClassSideTraits.
			   MCPToolUpdateClassSharedVariables.
			   MCPToolUpdateClassSharedPools.
			   MCPToolUpdateClassLayout.
			   MCPToolAddClassSlot.
			   MCPToolRemoveClassSlot.
			   MCPToolUpdateClassSlotName.
			   MCPToolPullUpClassSlot.
			   MCPToolPushDownClassSlot.
			   MCPToolRemoveClasses }).
		  ('methods' -> {
			   MCPToolSearchMethodMetadata.
			   MCPToolSearchMethodSource.
			   MCPToolSearchEquivalentMethods.
			   MCPToolSearchMethodImplementors.
			   MCPToolSearchMethodSenders.
			   MCPToolSearchClassReferences.
			   MCPToolSearchVariableReferences.
			   MCPToolGetMethod.
			   MCPToolCompileMethod.
			   MCPToolUpdateMethodSelector.
			   MCPToolUpdateMethodProtocol.
			   MCPToolRewriteMethods.
			   MCPToolRemoveMethods }).
		  ('history' -> {
			   MCPToolListChangeHistoryFiles.
			   MCPToolListChangeHistoryEntries.
			   MCPToolApplyChangeHistoryEntries.
			   MCPToolRevertChangeHistoryEntries }).
		  ('tests' -> {
			   MCPToolRunTests.
			   MCPToolRunTestCoverage }).
		  ('ui' -> { MCPToolCaptureScreenshot }).
		  ('debugging' -> {
			   MCPToolListDebugSessions.
			   MCPToolGetDebugSession.
			   MCPToolRemoveDebugSession.
			   MCPToolSearchDebugCandidates.
			   MCPToolAttachDebugCandidate.
			   MCPToolDebugState.
			   MCPToolDebugVariables.
			   MCPToolDebugEvaluate.
			   MCPToolStepIntoDebugSession.
			   MCPToolStepOverDebugSession.
			   MCPToolStepThroughDebugSession.
			   MCPToolRestartDebugSession.
			   MCPToolResumeDebugSession.
			   MCPToolTerminateDebugSession.
			   MCPToolListDebugBreakpoints.
			   MCPToolSetDebugBreakpoint.
			   MCPToolRemoveDebugBreakpoint.
			   MCPToolEnableDebugBreakpoint.
			   MCPToolDisableDebugBreakpoint.
			   MCPToolClearDebugBreakpoints.
			   MCPToolDebugCapture.
			   MCPToolDebugTest.
			   MCPToolUpdateDebugMethod }).
		  ('image-runtime' -> { MCPToolEvaluate }) }
]

{ #category : 'tools' }
MCPToolRegistry class >> publicToolNames [

	^ self publicToolClasses collect: [ :each | each toolName ]
]

{ #category : 'tools' }
MCPToolRegistry class >> publicTools [

	^ self publicToolsUsingPolicy: MCPToolExposurePolicy default
]

{ #category : 'tools' }
MCPToolRegistry class >> publicToolsUsingPolicy: aToolExposurePolicy [

	^ self publicToolClasses collect: [ :each |
			  each new
				  toolExposurePolicy: aToolExposurePolicy;
				  yourself ]
]

{ #category : 'tools' }
MCPToolRegistry class >> queryTermAlternativesFor: aTerm [

	| alternatives singular term |
	term := aTerm asString asLowercase.
	alternatives := OrderedCollection with: term.
	singular := self singularSearchTermFor: term.
	singular = term ifFalse: [ alternatives add: singular ].
	^ alternatives asSet asArray
]

{ #category : 'tools' }
MCPToolRegistry class >> queryTermsFrom: queryString [

	| normalized |
	normalized := queryString
		              ifNil: [ ^ #(  ) ]
		              ifNotNil: [ :value |
		              value asString trimBoth asLowercase ].
	normalized isEmpty ifTrue: [ ^ #(  ) ].
	^ normalized findTokens: ' -_'
]

{ #category : 'tools' }
MCPToolRegistry class >> riskForTool: aTool [

	| lowRisk mediumRisk toolName |
	toolName := aTool name.
	lowRisk := #( 'tool_search' 'tool_get' 'repository_search'
	              'repository_identity_verify'
	              'repository_change_list' 'package_search'
	              'class_search' 'class_get' 'method_metadata_search'
	              'method_source_search' 'method_equivalent_search'
	              'method_implementor_search' 'method_sender_search'
	              'method_class_reference_search'
	              'method_variable_reference_search'
	              'method_get' 'history_file_list' 'history_entry_list'
	              'screenshot_capture' 'debug_session_list'
	              'debug_session_get' 'debug_candidate_search'
	              'debug_state_get' 'debug_variable_get'
	              'debug_breakpoint_list' ).
	mediumRisk := #( 'tool_call' 'baseline_load' 'repository_load'
	                 'test_run' 'test_coverage_run' 'image_evaluate'
	                 'debug_expression_evaluate'
	                 'debug_capture' 'debug_test_run' ).
	(lowRisk includes: toolName) ifTrue: [ ^ 'low' ].
	(mediumRisk includes: toolName) ifTrue: [ ^ 'medium' ].
	^ 'high'
]

{ #category : 'tools' }
MCPToolRegistry class >> schemaInspectionRequiredForTool: aTool [

	^ self
		  schemaInspectionRequiredForTool: aTool
		  usingPolicy: aTool toolExposurePolicy
]

{ #category : 'tools' }
MCPToolRegistry class >> schemaInspectionRequiredForTool: aTool usingPolicy: aToolExposurePolicy [

	^ (self isStaticTool: aTool name usingPolicy: aToolExposurePolicy)
		  not
]

{ #category : 'tools' }
MCPToolRegistry class >> searchableTextForTool: aTool [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: aTool name;
				  space;
				  nextPutAll: aTool title;
				  space;
				  nextPutAll: aTool description;
				  space;
				  nextPutAll: (self groupNameForToolClass: aTool class).
			  (self keywordsForTool: aTool) do: [ :keyword |
					  stream
						  space;
						  nextPutAll: keyword ] ]
]

{ #category : 'tools' }
MCPToolRegistry class >> singularSearchTermFor: aTerm [

	| term |
	term := aTerm asString asLowercase.
	term = 'classes' ifTrue: [ ^ 'class' ].
	term = 'repositories' ifTrue: [ ^ 'repository' ].
	term = 'histories' ifTrue: [ ^ 'history' ].
	(term endsWith: 'ies') ifTrue: [ ^ (term allButLast: 3) , 'y' ].
	(term endsWith: 'ses') ifTrue: [ ^ term allButLast: 2 ].
	((term endsWith: 's') and: [ (term endsWith: 'ss') not ]) ifTrue: [
		^ term allButLast ].
	^ term
]

{ #category : 'accessing' }
MCPToolRegistry class >> staticToolClasses [

	^ {
		  MCPToolSearchTools.
		  MCPToolGetTool.
		  MCPToolCallTool.
		  MCPToolSearchPackages.
		  MCPToolSearchClasses.
		  MCPToolGetClass.
		  MCPToolCreateClass.
		  MCPToolSearchMethodMetadata.
		  MCPToolSearchMethodSource.
		  MCPToolSearchMethodImplementors.
		  MCPToolSearchMethodSenders.
		  MCPToolGetMethod.
		  MCPToolCompileMethod.
		  MCPToolUpdateMethodSelector.
		  MCPToolEvaluate.
		  MCPToolRunTests }
]

{ #category : 'tools' }
MCPToolRegistry class >> staticToolNames [

	^ self defaultStaticToolNames
]

{ #category : 'tools' }
MCPToolRegistry class >> staticTools [

	^ self staticToolsUsingPolicy: MCPToolExposurePolicy default
]

{ #category : 'tools' }
MCPToolRegistry class >> staticToolsDictionary [

	^ self staticToolsDictionaryUsingPolicy:
		  MCPToolExposurePolicy default
]

{ #category : 'tools' }
MCPToolRegistry class >> staticToolsDictionaryUsingPolicy: aToolExposurePolicy [

	| dictionary |
	dictionary := Dictionary new.
	(self staticToolsUsingPolicy: aToolExposurePolicy) do: [ :tool |
		dictionary at: tool name put: tool ].
	^ dictionary
]

{ #category : 'tools' }
MCPToolRegistry class >> staticToolsUsingPolicy: aToolExposurePolicy [

	^ (self publicToolClasses
		   select: [ :toolClass |
		   aToolExposurePolicy isStaticTool: toolClass toolName ]
		   thenCollect: [ :toolClass |
				   toolClass new
					   toolExposurePolicy: aToolExposurePolicy;
					   yourself ]) asArray
]

{ #category : 'tools' }
MCPToolRegistry class >> tool: aTool matchesQuery: queryString group: groupString [

	^ self
		  tool: aTool
		  matchesQuery: queryString
		  group: groupString
		  usingPolicy: aTool toolExposurePolicy
]

{ #category : 'tools' }
MCPToolRegistry class >> tool: aTool matchesQuery: queryString group: groupString usingPolicy: aToolExposurePolicy [

	| group queryTerms searchableText |
	group := groupString ifNotNil: [ :value |
		         value asString trimBoth asLowercase ].
	(group isNotNil and: [
			 group isNotEmpty and: [
				 group ~= (self groupNameForToolClass: aTool class) ] ]) ifTrue: [
		^ false ].
	queryTerms := self queryTermsFrom: queryString.
	queryTerms ifEmpty: [ ^ true ].
	searchableText := (self searchableTextForTool: aTool) asLowercase.
	^ queryTerms allSatisfy: [ :each |
			  (self queryTermAlternativesFor: each) anySatisfy: [ :alternative |
				  searchableText includesSubstring: alternative ] ]
]

{ #category : 'tools' }
MCPToolRegistry class >> toolNamed: aToolName ifAbsent: absentBlock [

	^ self
		  toolNamed: aToolName
		  ifAbsent: absentBlock
		  usingPolicy: MCPToolExposurePolicy default
]

{ #category : 'tools' }
MCPToolRegistry class >> toolNamed: aToolName ifAbsent: absentBlock usingPolicy: aToolExposurePolicy [

	self publicToolClasses do: [ :toolClass |
			toolClass toolName = aToolName ifTrue: [
					^ toolClass new
						  toolExposurePolicy: aToolExposurePolicy;
						  yourself ] ].
	^ absentBlock value
]

{ #category : 'tools' }
MCPToolRegistry class >> toolsMatchingQuery: queryString group: groupString limit: anInteger [

	^ self
		  toolsMatchingQuery: queryString
		  group: groupString
		  limit: anInteger
		  usingPolicy: MCPToolExposurePolicy default
]

{ #category : 'tools' }
MCPToolRegistry class >> toolsMatchingQuery: queryString group: groupString limit: anInteger usingPolicy: aToolExposurePolicy [

	| limit matches |
	matches := (self publicToolsUsingPolicy: aToolExposurePolicy)
		           select: [ :tool |
				           self
					           tool: tool
					           matchesQuery: queryString
					           group: groupString
					           usingPolicy: aToolExposurePolicy ].
	limit := anInteger ifNil: [ 25 ].
	(limit > 0 and: [ matches size > limit ]) ifTrue: [
		^ (matches first: limit) asArray ].
	^ matches asArray
]
