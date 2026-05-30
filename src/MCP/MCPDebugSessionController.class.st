"
MCPDebugSessionController controls a debugger through the DebugSession model. It is used for captured worker sessions and as the fallback when an attached visible debugger does not own the session being controlled.
"
Class {
	#name : 'MCPDebugSessionController',
	#superclass : 'MCPDebugController',
	#instVars : [
		'debugSession'
	],
	#category : 'MCP-Debugging',
	#package : 'MCP',
	#tag : 'Debugging'
}

{ #category : 'instance creation' }
MCPDebugSessionController class >> debugSession: aDebugSession [

	^ self new
		  debugSession: aDebugSession;
		  yourself
]

{ #category : 'accessing' }
MCPDebugSessionController >> debugSession [

	^ debugSession
]

{ #category : 'accessing' }
MCPDebugSessionController >> debugSession: aDebugSession [

	debugSession := aDebugSession
]

{ #category : 'controlling' }
MCPDebugSessionController >> performOperation: selector context: aContext [

	selector numArgs = 0 ifTrue: [ ^ debugSession perform: selector ].
	^ debugSession perform: selector with: aContext
]
