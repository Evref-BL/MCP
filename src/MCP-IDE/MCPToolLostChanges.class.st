"
Shared implementation of the tools that recover what a crash, or a stop without saving, lost: history_lost_change_list shows it and history_lost_change_restore puts it back. Both take it from MCPLostChangeQuery, read once per image session and compared with the image at each call, and name each change by its element, the way restoring takes it.

They sit in the history group beside the tools that act on history entries, and answer for themselves rather than through MCPToolChangeHistory: an entry, its index and its file are not what they show.
"
Class {
	#name : 'MCPToolLostChanges',
	#superclass : 'MCPTool',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolLostChanges class >> groupName [

	^ self historyGroupName
]

{ #category : 'testing' }
MCPToolLostChanges class >> isAbstract [

	^ self = MCPToolLostChanges
]

{ #category : 'metadata' }
MCPToolLostChanges >> additionalKeywords [
	"The words an agent reaches for after a crash or an image stopped unsaved."

	^ #( 'history' 'lost' 'crash' 'unsaved' 'recover' 'epicea' )
]

{ #category : 'private - execution' }
MCPToolLostChanges >> dataFor: request from: aLostChangeQuery [
	"The data the answer carries, read from aLostChangeQuery as the request asks."

	^ self subclassResponsibility
]

{ #category : 'private - results' }
MCPToolLostChanges >> entryNameKeys [
	"A change opens with the element it changed, as restoring takes it."

	^ #( element )
]

{ #category : 'executing' }
MCPToolLostChanges >> executeWithRequest: request [
	"The history is read once per image session and the image compared with it at each call, so the answer is for the image as it is. A session file that cannot be read in full qualifies the answer rather than failing it."

	^ self
		  executeRequest: request
		  do: [
				  | data query |
				  query := MCPLostChangeQuery ofSessionInProgress.
				  data := self dataFor: request from: query.
				  self successResultText: (self successSummaryForData: data) data: data warnings: query warnings ]
		  onError: [ :error | self errorResultFor: error ]
]

{ #category : 'private - results' }
MCPToolLostChanges >> keyOrder [
	"A change says what it is and what restoring installs before what stands in the way. The sessions come before the changes they hold, and what was restored before what was not."

	^ #( sessions changes restored notRestored element change protocol source definition classSideDefinition comment conflict
	     inImage reason )
]

{ #category : 'private - results' }
MCPToolLostChanges >> successSummaryForData: data [
	"The sentence that says what the data holds."

	^ self subclassResponsibility
]
