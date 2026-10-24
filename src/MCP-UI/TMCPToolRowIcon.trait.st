"
A tool's icon, sized for a table row, for the presenters that list tools.

The icon a client is served is 32 square, which a table row clips, so it is scaled once per tool class. The user of this trait says where that scaling is kept, since a presenter should let go of its cache when it goes.
"
Trait {
	#name : 'TMCPToolRowIcon',
	#category : 'MCP-UI',
	#package : 'MCP-UI'
}

{ #category : 'tool icons' }
TMCPToolRowIcon >> rowIconCache [

	^ self explicitRequirement
]

{ #category : 'tool icons' }
TMCPToolRowIcon >> rowIconColumn [

	^ (SpImageTableColumn evaluated: [ :tool | self rowIconFor: tool ])
		  width: self rowIconSize + 8;
		  yourself
]

{ #category : 'tool icons' }
TMCPToolRowIcon >> rowIconFor: aTool [

	^ self rowIconCache at: aTool class ifAbsentPut: [ (MCPTool toolIconFormOf: aTool class) scaledIntoFormOfSize: self rowIconSize ]
]

{ #category : 'tool icons' }
TMCPToolRowIcon >> rowIconSize [

	^ 16
]
