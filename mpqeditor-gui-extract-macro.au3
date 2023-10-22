#include <GuiTreeView.au3>
#include <MsgBoxConstants.au3>
#include <TrayConstants.au3>
#include <WinAPISysWin.au3>
#include <WindowsConstants.au3>
#include <WinAPIError.au3>
#include <WinAPIvkeysConstants.au3>


; $map = Target map to add entry to
; $indentLevel = additionally filter by indentLevel. -1 means no filtering
; $searchStr = find this string to match. "*" means anything will match
; -1 and "" together means every item (including root, don't do this. if you need root, just indent = 0 and "*")
Func MPQ_filterListAdd(ByRef $map, $indentLevel, ByRef $searchStr)
	; abandoned
	MsgBox(0, "NYI", "MPQ_filterListAdd")
	Exit(1)
endfunc

Func MPQ_makeFilterList()
	local $mapIndentStr[12]
	
	;MPQ_filterListAdd($mapIndentStr, 1, "Doodads")
	
	return $mapIndentStr
endfunc

Func MPQ_isFilterMatch(ByRef $filterMap, $itemIndent, $itemText)
	
	; 1 for classic layout, 2 for casc layout of reforged
	if $itemIndent = 1 or $itemIndent = 2 then
		if $itemText = "Scripts" then
			
			return True
		endif
	endif
	
	if $itemIndent = 2 then
		; ./war3.w3mod:_balance, contains custom_v0 etc.
		if $itemText = "_balance" then
			return True
		endif
	endif
	
	; 3 for reforged
	if $itemIndent = 3 then
		
	endif
	return False
endfunc

; Display Status Tooltip / Traytip
Func ShowStatus($text, $title = "MPQ Extractor Status")
	TrayTip($title, $text, 5, $TIP_ICONASTERISK + $TIP_NOSOUND)
	Sleep(200)
endfunc

; waits until the TreeView on the left has items. That's the definitive safety check
Func MPQE_waitTreeViewCount($treeviewCtrlHandle)
	while _GUICtrlTreeView_GetCount($treeviewCtrlHandle) < 1
		Sleep(1000)
	wend
endfunc

; Opening MPQ is in progress (e.g. deep file verification, big MPQ, IO delay etc)
Func MPQE_waitOpenProgress()
	local $mpqOpenProgressH = WinWait("[TITLE:Opening MPQ ...]", "", 1)
	
	if $mpqOpenProgressH <> 0 then
		ShowStatus("Waiting for Open in Progress to close...")
		WinWaitClose($mpqOpenProgressH)
	endif
endfunc

; MPQEditor has the advanced MPQ Open dialog open
Func MPQE_waitOpenOptions()
	local $mpqOpenOptionsH = WinWait("[TITLE:Open MPQ(s) Options]", "", 1)
	
	if $mpqOpenOptionsH <> 0 then
		ShowStatus("Waiting for Advanced Open to close...")
		WinWaitClose($mpqOpenOptionsH)
	endif
endfunc

; Child window while extraction in progress
Func MPQE_waitExtracting()
	local $mpqProgressH = WinWait("[TITLE:Extracting files from MPQ ...]", "", 2)
	if $mpqProgressH <> 0 then
		ShowStatus("Waiting for Extraction in Progress to close...")
		; 1. detect "Extracting files from MPQ ..." and wait
		; Window exists, wait for completion
		WinWaitClose($mpqProgressH)
		
		; We dont need to wait for 2, because the user is here to help us.
		; Though the replace all could be automated...
		; but actually the entire folder should be 100% clean to avoid dirty data
		;2. "File already exists" title
		;	(Y)es, Yes (A)ll, (N)o, No All, Cancel
	endif
endfunc

Func MPQE_sendExtract($mpqWinH)
	; handle, message type, keycode, keystroke flags
	_WinAPI_PostMessage($mpqWinH, $WM_KEYDOWN, $VK_F5, 0)
	_WinAPI_PostMessage($mpqWinH, $WM_KEYUP, $VK_F5, 0)
	
	MPQE_waitExtracting()
endfunc

Func main()
	local $filterList = Null
	
	local $mpqWinSelector = "[CLASS:MPQEditor_MainWindow]"
	local $mpqCtrlTreeSelector = "[Class:SysTreeView32;INSTANCE:1]"
	local $mpqWinHList
	local $mpqWinCount
	local $mpqWinH ; handle to window
	
	while True
		$mpqWinHList = WinList($mpqWinSelector)
		$mpqWinCount = $mpqWinHList[0][0]
		local $buttonPressed = -1
		
		if $mpqWinCount = 1 then
			; Good, found single window (target)
			$mpqWinH = $mpqWinHList[1][1] 
			ExitLoop
			
		elseif $mpqWinCount = 0 then
			$buttonPressed = MsgBox($MB_ICONERROR + $MB_RETRYCANCEL, "MPQEditor not found", "Is MPQEditor running? I didn't find it!")
			
			if $buttonPressed = $IDRETRY then
				ContinueLoop 
			else
				Exit(1)
			endif
		elseif $mpqWinCount > 1 then
			$buttonPressed = MsgBox($MB_ICONERROR + $MB_RETRYCANCEL, "Multiple MPQEditors found", "There are multiple MPQEditors running. Please only have 1 open at a time!")
			
			if $buttonPressed = $IDRETRY then
				ContinueLoop
			else
				Exit(1)
			endif
		endif	
	WEnd
	
	
	
	; Check if MPQEditor has the advanced MPQ Open dialog open
	ShowStatus("Waiting for MPQ Advanced Open dialog. Check 'Read-Only' and Press OK.")
	MPQE_waitOpenOptions()
		
	; Check if MPQEditor is in process of opening the MPQ
	ShowStatus("Waiting for MPQ to be opened")
	MPQE_waitOpenProgress()
	
	; Use Au3Info for Control info
	; Wait until MPQ is ready to work (TreeView not empty)
	local $treeviewCtrlH = ControlGetHandle($mpqWinSelector, "", $mpqCtrlTreeSelector)
	ShowStatus("Waiting for TreeView to be populated")
	MPQE_waitTreeViewCount($treeviewCtrlH)
	
	local $rootItemH = _GUICtrlTreeView_GetFirstItem($treeviewCtrlH)
	local $rootItemStr
	
	if $rootItemH <> 0 then
		$rootItemStr = _GUICtrlTreeView_GetText($treeviewCtrlH, $rootItemH)
		
		if $rootItemStr <> "" then
			
			local $indentLevel = _GUICtrlTreeView_Level($treeviewCtrlH, $rootItemH)
			;MsgBox(0, "Root Text", $rootItemStr & @CRLF & "Indent level: " & $indentLevel)
			
		else
			MsgBox($MB_ICONERROR, "error", "Root item text is empty. AutoIt bug? Try to update.")
			Exit(1)
		endif 
	else
		MsgBox($MB_ICONERROR, "error", "Root item not found in TreeView. No MPQ Archive open?")
		Exit(1)
	endif
	
	local $oldDelimeter = AutoItSetOption("GUIDataSeparatorChar", "|")
	AutoItSetOption("GUIDataSeparatorChar", $oldDelimeter)
	
	;; TEST CODE
	; local $clv = _GUICtrlTreeView_FindItem($treeviewCtrlH, "Doodads")
	; local $text = _GUICtrlTreeView_GetText($treeviewCtrlH, $clv)
	; if @error <> 0 then
		; MsgBox(16, "error", @error)
	; else
		; MsgBox(0, "MPQTest", $clv & "=" & $text)
		; local $indentLevel = _GUICtrlTreeView_Level($treeviewCtrlH, $clv)
		; MsgBox(0, $text, "Indent level: " & $indentLevel)
	; endif
	
	
	local $curItem = _GUICtrlTreeView_GetFirstItem($treeviewCtrlH)
	if $curItem < 1 then
		; MsgBox($MB_ICONERROR, "_GUICtrlTreeView_GetFirstItem, while iteration", _
			; "Root item not found in TreeView. No MPQ Archive open?")
	endif
	
	ShowStatus("Extracting items...")
	local $itemCount = 0
	while $curItem <> 0
		$itemCount = $itemCount + 1
		local $curLevel = _GUICtrlTreeView_Level($treeviewCtrlH, $curItem)
		local $itemText = _GUICtrlTreeView_GetText($treeviewCtrlH, $curItem)
		
		if MPQ_isFilterMatch($filterList, $curLevel, $itemText) then
			
			;MsgBox(0, "Found next item to be extracted", $itemText)
			ShowStatus("Extracting: '" + $itemText + "'")
			; must focus TreeView else it might focus and extract the ListView on the right
			ControlFocus($mpqWinH, "", $treeviewCtrlH)
			_GUICtrlTreeView_SelectItem($treeviewCtrlH, $curItem, $TVGN_CARET)
			MPQE_sendExtract($mpqWinH)
			
		endif
		
		$curItem = _GUICtrlTreeView_GetNext($treeviewCtrlH, $curItem)
	wend
	;MsgBox(0, "End of tree view reached", "Items iterated: " & $itemCount)
EndFunc

main()

Func TreeView()

	Local $ctrHndl = ControlGetHandle("[CLASS:MPQEditor_MainWindow]", "", 10005)

	MsgBox ($MB_SYSTEMMODAL,"","Display Control Handle $ctrHndl : "  & $ctrHndl)

	Local $Result1 = _GUICtrlTreeView_GetCount($ctrHndl)
	MsgBox ($MB_SYSTEMMODAL,"","Display ControlTreeView Count : "  & $Result1)

	Local $hFound = _GUICtrlTreeView_FindItem($ctrHndl, "Doodads")
	MsgBox ($MB_SYSTEMMODAL,"hFound:", $hFound)

	$iItem = _GUICtrlTreeView_GetFirstItem($ctrHndl)

	While $iItem
		$hItem = _GUICtrlTreeView_GetItemHandle($iItem, $iItem)
		
		;_GUICtrlTreeView_Expand($ctrHndl, $hItem, True)
		
		$sItem = _GUICtrlTreeView_GetText($ctrHndl, $hItem)
		MsgBox(0, "item", $hItem & "=" & $sItem & @CRLF)

		$iChild = _GUICtrlTreeView_GetChildCount($ctrHndl, $iItem)
		If $iChild <> -1 Then
			$iItem = _GUICtrlTreeView_GetFirstChild($ctrHndl, $iItem)
		Else
			$iItem = _GUICtrlTreeView_GetNext($ctrHndl, $iItem)
		EndIf
	WEnd
EndFunc

Func AutoitHelp()

	Local $hTreeView = ControlGetHandle("AutoIt Help", "", "SysTreeView321")
	MsgBox ($MB_SYSTEMMODAL,"","$hTreeView=" & $hTreeView & @CRLF)

	;Local $hTreeView = ControlGetHandle("SciTE4AutoIt3", "", "SysTreeView321") ; works correctly
	Local $hFirstItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
	MsgBox ($MB_SYSTEMMODAL,"",_GUICtrlTreeView_GetText($hTreeView, $hFirstItem) & @CRLF)
Endfunc
