;http://www.autohotkey.com/forum/topic56306.html
;v1.02
;v1.02

#Persistent
#SingleInstance force

ClipBoardHistory()
return


initializeClipBoardHistory:
SendMode Input
AList_new("clph_concatenators")

;set constants
clph_trimText:=true ;trim leading and tailing spaces of text put into history, only history entries will be trimmed, not the text in clipboard
clph_maxHistoryEntryLength:=1000 ; do not put strings longer than this number into history
clph_listAppearOnPress := 2 ; Listview should appear if paste button is pressed for the 2nd time

;generate list of joining strings
AList_insert(" - ", "last", "clph_concatenators")
AList_insert(" ", "last", "clph_concatenators")
AList_insert("-", "last", "clph_concatenators")
AList_insert("`n", "last", "clph_concatenators") ;line break
clph_selectedConcatenator := 1


;initialize variables

;clph_listPosition:=-1

monitorClipboardEnabled:=true
;initialize the 1st list
ArrayList()
AList_new("clph_selectedEntries")

;add an entry to the tray icon menu
Menu, TRAY, Add, Clear History, clph_clearHistory





;can be called by scripts that #include this one
ClipBoardHistory()
{
  global clph_maxHistoryEntries
  clph_maxHistoryEntries:=30 ;how many history entries to keep
  rowCount := clph_maxHistoryEntries + 1
  ;create the gui
  Gui, 2: +AlwaysOnTop
  Gui, 2: Margin, 0,0 ;must be called before the Listview control is added
  Gui, 2: Add, ListView,-Hdr w500  R%rowCount% AltSubmit gClph_ListView, index|content
  Gui, 2: -caption
  gui, 2:+ToolWindow ;don't make taskbar button
  Gui, 2: Show, Hide, ClipboardHistory9874358 ;used to set the title without actually showing the window
  gosub, initializeClipBoardHistory
}




OnClipboardChange: ; runs once at startup btw
;don't do anything if disabled. Can be used by other included scripts when using the clipboard temporarily
if(!monitorClipboardEnabled)
  return

;clph_listPosition:=-1

clph_addToHistory()
if (A_EventInfo=1) ;1 if it contains something that can be expressed as text (this includes files copied from an Explorer window)
  {

  if(StrLen(Clipboard) <=clph_maxHistoryEntryLength)
    {
      if(clph_trimText)
        ;trim the text
        clph_tempClipBoardText=%Clipboard%
        else
          ;don't trim the text
          clph_tempClipBoardText:=Clipboard

    }
  }
  else if (A_EventInfo=0)
    { ; 0 if the clipboard is now empty;

      ;clph_listPosition:=0
    }
    
  
    

return

#IfWinExist, Clipboard History9874358
^c::
  clph_concatenatorButtonPressed()
return
#IfWinExist

$^v::

clph_pasteButtonPressed()

return

clph_concatenatorButtonPressed()
{
  global clph_selectedConcatenator
  concatenatorCount := AList_getSize("clph_concatenators")
  if(clph_selectedConcatenator == concatenatorCount)
    {
      clph_selectedConcatenator := 1
    }
    else
      {
        clph_selectedConcatenator++
      }
  clph_updateTooltip()
  
}


clph_pasteButtonPressed()
{
  global clph_pastePressCount, clph_ListViewLeftClickCount, clph_pasteMode, clph_listAppearOnPress
  
  clph_pastePressCount++
  if(!clph_pasteMode)
    {
      clph_pasteMode:=true
      
    }
  
  if(AList_getSize("clph_selectedEntries")>0)
    {
      ;get first selected entry
      firstSelectedEntry := AList_get(1, "clph_selectedEntries")
      
      if(firstSelectedEntry==AList_getSize())
        {
          entryToSelect := clph_rowToHistoryEntry(1) 
          
        }
        else
          {
            entryToSelect := firstSelectedEntry + 1
          }
      
    }
    else
      {
        entryToSelect := clph_rowToHistoryEntry(1)
      }
  ;remove the current selection
  AList_clear("clph_selectedEntries")    
  AList_insert(entryToSelect, 1, "clph_selectedEntries")
    
    
  
  
  if(clph_pastePressCount == clph_listAppearOnPress) ; appear only on 2nd press
    clph_showGui()
  
  ; must be called after the LV has been created
  clph_updateGui(entryToSelect)
  
  
  
  clph_updateTooltip()
  
  
  
;  clph_updateGui(clph_listPosition)
  clph_ListViewLeftClickCount := 0

}


$^q:: ;$ is against self triggering by send command
if(clph_pasteMode)
  {
    clph_selectPrevious()


  }
  else
    {
      send, ^q
    }
return

clph_selectPrevious()
  {
    global
    local firstSelectedEntry, entryToSelect
    if(AList_getSize("clph_selectedEntries")>0)
      {
        ;get first currently selected entry
        firstSelectedEntry := AList_get(1, "clph_selectedEntries")
        
        if(firstSelectedEntry==1)
          {
            if(clipboard=="")
              {
                entryToSelect := AList_getSize()
              }
              else
                {
                  entryToSelect := 0
                }
            
            
          }
          else if(firstSelectedEntry==0)
            {
              entryToSelect := AList_getSize()
            }
          else 
            {
              entryToSelect := firstSelectedEntry - 1
            }
        
      }

    ;remove the current selection
    AList_clear("clph_selectedEntries")    
    AList_insert(entryToSelect, 1, "clph_selectedEntries")


;     clph_listPosition--
;     if(clph_listPosition <= 0 && (clph_listPosition == -1 || clipboard == "") )
;       {
;         clph_listPosition:= AList_getSize()
;       
;       }
    clph_updateGui(entryToSelect)
    clph_updateTooltip()
    clph_ListViewLeftClickCount := 0
    
  }



$^l::
if(clph_pasteMode)
  {
    clph_endPaste()
    AList_clear("clph_selectedEntries")
    
  }
  else
    {
      send, ^l
    }
return



~Control UP::
if(clph_pasteMode){
  clph_paste()
 
  
}

clph_paste()
{
  clph_endPaste()
  if(AList_getSize("clph_selectedEntries")>0)
    {
      ;if only 0 is selected i.e. current clipboard don't generate it because it could be something else than text e.g. pasting files in explorer
      if(AList_get(1, "clph_selectedEntries")!=0 || AList_getSize("clph_selectedEntries")>1)
        {
          pasteText := clph_generatePasteText()
          ;check ;if only 1 entry was selected
          if(AList_getSize("clph_selectedEntries")==1)
            {
              ;delete it from history because it will become current clipboard and later be added again
              AList_remove(AList_get(1, "clph_selectedEntries"))
              
            }
          ;insert it into clipboard so it can be pasted
          clipboard := pasteText
        
        }
      

      
      Send, ^v      
      AList_clear("clph_selectedEntries")
    
    
    }
  ;clph_endPaste()
  ;if(AList_getSize("clph_selectedEntries")>0 && AList_get(1 , "clph_selectedEntries"))

}

return

clph_endPaste()
{
  global
    Gui, 2: hide
    ToolTip
    clph_pasteMode:=false
    ;clph_listPosition:=-1
    Gui 2:Default
    LV_Delete()
    Gui 1:Default
    clph_pastePressCount := 0
    clph_ListViewLeftClickCount := 0
    AList_move(clph_selectedConcatenator, 1, "clph_concatenators")
    clph_selectedConcatenator := 1
    
    
}

clph_addToHistory()
{
  global clph_tempClipBoardText, clph_maxHistoryEntryLength, clph_maxHistoryEntries
  ;check if already in list
  foundAtPosition:=AList_find(clph_tempClipBoardText)
  if (foundAtPosition!=0){
    ;if already in list move to top of list
  
    AList_move(foundAtPosition, 1)
    }
    ;else add at top of the list
    else{
      
      ;first check if clipboard has really changed because may apps copy the same text to clipboard twice
      ;only add to history if text is shorter than the specified clph_maxHistoryEntryLength
      ;if ( clipboard != clph_tempClipBoardText && 0 < StrLen(clph_tempClipBoardText) && StrLen(clph_tempClipBoardText) <=clph_maxHistoryEntryLength){  ;&& StrLen(clph_tempClipBoardText)
      if ( clipboard != clph_tempClipBoardText && 0 < StrLen(clph_tempClipBoardText))
        {  ;&& StrLen(clph_tempClipBoardText)        
          AList_insert(clph_tempClipBoardText, 1)
  
          ;trim the number of entries
          AList_trim(clph_maxHistoryEntries)
  
        }
      }
      
}



clph_clearHistory:
  AList_clear()
return


clph_updateTooltip()
{
  
  if(AList_getSize("clph_selectedEntries")==1)
    {
      ;if only one entry is selected
      ;insert the position in front of the text
      selectedEntryNum := AList_get(1, "clph_selectedEntries")
      ToolTip, % selectedEntryNum . ": "clph_generatePasteText()
    }
    else
      ;otherwise just show the text
      {
        ToolTip, % clph_generatePasteText()
      }
      
  
  
  
  
}

clph_generatePasteText()
{
  global clph_selectedConcatenator
  concatenatedString := ""
  entriesCount := AList_getSize("clph_selectedEntries")
  Loop , % entriesCount
    {
      ;assuming clph_selectedEntries is the position in the history not the ListView
      selectedEntryNum := AList_get(A_Index, "clph_selectedEntries")
      if(selectedEntryNum == 0)
        {
          concatenatedString .= Clipboard
        }
        else
          {
            concatenatedString .= AList_get(selectedEntryNum)
          }
      if(!(entriesCount==A_Index))
        {
          concatenatedString .= AList_get(clph_selectedConcatenator, "clph_concatenators")
        }
    
     
    }
  return concatenatedString
}
    

Clph_ListView:
if(A_GuiEvent=="Normal")
  {
    clph_ListViewLeftClicked(A_EventInfo)
    ;msgbox, left clicked
  }
  else if(A_GuiEvent=="RightClick")
    {
      clph_ListViewRightClicked(A_EventInfo)
    }
return



clph_ListViewLeftClicked(rowNumber)
{

      ;only if the clicked entry was not the currently seleted one by keyboard
      if(clph_rowToHistoryEntry(rowNumber)!=AList_get(1, "clph_selectedEntries"))
        {
          ;LV_Modify(0, "-Select")
          ;AList_remove(1, "clph_selectedEntries")
          ;LV_Modify(rowNumber, "Select")
        }
;     }
  ;msgbox, %rowNumber%
  positionInSelectedEntries := AList_find(clph_rowToHistoryEntry(rowNumber), "clph_selectedEntries")
  ;if clicked entry was selected i.e. was in selectedEntries list
  if(positionInSelectedEntries > 0)
    {
      AList_remove(positionInSelectedEntries, "clph_selectedEntries")
      
    }
      else
      {
        AList_insert(clph_rowToHistoryEntry(rowNumber), "last", "clph_selectedEntries")
        
      }
    



  clph_updateTooltip()
}


clph_ListViewRightClicked(rowNumber)
{ ;geht nicht da rechtsklick keine rows selektiert, daher linksklick simulieren
  ;msgbox, %rowNumber%
  AList_clear("clph_selectedEntries")
  ;AList_insert(clph_rowToHistoryEntry(rowNumber), "last", "clph_selectedEntries")
  LV_Modify(0, "-Select")
  Click
  ;LV_Modify(rowNumber, "Select")
}




clph_showGui()
{
      Gui 2:Default
      if(clipboard!="")
        {
          LV_Add("","0 ",clipboard)
          rowCount++
        }
      Loop, % AList_getSize()
        {
      
          LV_Add("",a_index,AList_get(a_index))
        
        }
      Gui, 2: show, NA ;NA makes the gui window not get activated
      Gui 1:Default
}



clph_updateGui(entryToSelect)
{ 
  ;global ListView1
  
  
  if(clipboard=="")
    {
      
      listPosAdd := 0
    }
    else
      {
        listPosAdd := 1
      }
    
  Gui 2:Default
  ;0 will apply command to all rows
  LV_Modify(0,"-Select")
  LV_Modify(0,"-Focus")

  LV_Modify(entryToSelect + listPosAdd,"Select Focus")
  Gui 1:Default

    
}

;convert a row number to the Entry number in the history 
clph_rowToHistoryEntry(row)
  {
    if(clipboard=="")
      return  row
    else
      return row - 1
      
  
  }



initializeArrayList:

AListInst_1_length :=0
AList_listCount := 1 
return

ArrayList()
{
  gosub, initializeArrayList
}

AList_new(listId = "")
{
  global
  if(listId = "")
    {
      listId := ++AList_listCount
    }
  AListInst_%listId%_length :=0
  
  
  return listId
}

; removes all list entries
; tries to free some memory via :="". To free more use AList_destroy() instead
AList_clear(listId = 1)
{
  global
  local contentsIndex
  loop, % AListInst_%listId%_length
    {
      contentsIndex := AListInst_%listId%_index_%a_index%
      AListInst_%listId%_%contentsIndex% := "" ;clear the content
      AListInst_%listId%_index_%a_index% := "" ;clear the index
        
    }
  AListInst_%listId%_length := 0 ;set the list length to 0
  AListInst_%listId%_itemIndexFreeLast := 0

}

; try to free as much memory as possible via VarSetCapacity
AList_destroy(listId = 1)
{
  global
  local contentsIndex
  loop, % AListInst_%listId%_length
    {
      contentsIndex := AListInst_%listId%_index_%a_index%
      VarSetCapacity(AListInst_%listId%_%contentsIndex% ,0)
      VarSetCapacity(AListInst_%listId%_index_%a_index% ,0)
    }
    VarSetCapacity(AListInst_%listId%_length ,0)
    VarSetCapacity(AListInst_%listId%_itemIndexFreeLast ,0)

}

;never insert an empty value!
AList_insert(value, position = "last", listId = 1)
{
  global
  local indexInd, listIndexToUse
  listIndexToUse := _AList_getItemFreeIndex(listId)
  
  if(position="last")
    {
      position := AListInst_%listId%_length + 1

    }
  else if (position="first")
        {
          position:=1
        }
  AListInst_%listId%_%listIndexToUse% := value
  _AList_pushBackward(listId, position)
  ;pushBackward(listId, position)
  AListInst_%listId%_index_%position% := listIndexToUse
  AListInst_%listId%_itemIndexFreeLast := ""
  AListInst_%listId%_length++
  

}


AList_find(value, listId = 1)
{
  global
  local listIndex
  
  Loop % AListInst_%listId%_length
    {
      listIndex := AListInst_%listId%_index_%a_index%
      if (AListInst_%listId%_%listIndex% == value) ;== means case sensitive
        return %a_index%
    }
  return 0
  
}

; removes all entries with a position greater than maxSize
AList_trim(maxSize, listId = 1)
{
  global
  local indexInd, listIndex
  if(AListInst_%listId%_length > maxSize)
    {
      indexInd := maxSize + 1
      while (indexInd <= AListInst_%listId%_length)
        {
        
          listIndex := AListInst_%listId%_index_%indexInd%
          AListInst_%listId%_%listIndex% := ""
          AListInst_%listId%_index_%indexInd% := ""
          indexInd++
        
        }
      AListInst_%listId%_itemIndexFreeLast := listIndex
      AListInst_%listId%_length := maxSize
    
    }
    

  

    

}

; usage of "last" and "first" is allowed for position parameter
AList_remove(position, listId = 1)
{
  global
  local listIndexToUse
  
  if(position="last")
    {
      position := AListInst_%listId%_length

    }
    else if (position="first")
        {
          position:=1
        }
  listIndexToUse := AListInst_%listId%_index_%position%
  AListInst_%listId%_%listIndexToUse% := ""
  AListInst_%listId%_itemIndexFreeLast := listIndexToUse
  _AList_pushRemove(listId, position)
  AListInst_%listId%_length--
}

AList_get(position, listId = 1)
{ 
  global
  local listIndex
  
  if(position = "last")
    position := AListInst_%listId%_length 
  listIndex:= AListInst_%listId%_index_%position%
  return AListInst_%listId%_%listIndex%
}

AList_swap(oldPosition, newPosition, listId = 1)
{
  global
  local temp
  temp := AListInst_%listId%_index_%newPosition%
  AListInst_%listId%_index_%newPosition% := AListInst_%listId%_index_%oldPosition%
  AListInst_%listId%_index_%oldPosition% := temp
}

; for newPosition parameter usage of "last" is possible
AList_move(oldPosition, newPosition, listId = 1)
{
  global
  local tempItemListIndex, indToPush, newInd
  if(newPosition = "last")
    newPosition := AListInst_%listId%_length
  tempItemListIndex := AListInst_%listId%_index_%oldPosition%
  if(oldPosition > newPosition)
    {
      indToPush := oldPosition - 1
      While (indToPush >= newPosition)
        {
          newInd := indToPush + 1
          AListInst_%listId%_index_%newInd% := AListInst_%listId%_index_%indToPush%
          indToPush--
        }
    }
  else if(oldPosition < newPosition)
    {
      indToPush := oldPosition + 1
      While (indToPush <= newPosition)
        {
          newInd := indToPush - 1
          AListInst_%listId%_index_%newInd% := AListInst_%listId%_index_%indToPush%
          indToPush++
        }
    }
  AListInst_%listId%_index_%newPosition% := tempItemListIndex

}

AList_getSize(listId = 1)
{
  global
  return AListInst_%listId%_length
}

_AList_getItemFreeIndex(listId)
{
  global
  if(AListInst_%listId%_itemIndexFreeLast !="")
    return AListInst_%listId%_itemIndexFreeLast
    else
      {
        Loop
          {
            if(AListInst_%listId%_%a_index% = "")
              return %a_index%
          }
      }
    
}

_AList_pushBackward(listId, position)
{
  global
  local indToPush, newInd
  indToPush := AListInst_%listId%_length
  While (indToPush >= position)
    {
      newInd := indToPush + 1
      AListInst_%listId%_index_%newInd% := AListInst_%listId%_index_%indToPush%
      indToPush--
    }
}

_AList_pushRemove(listId, position)
{
  global
  local indToPush, newInd
  
  indToPush := position
  While (indToPush < AListInst_%listId%_length)
    {
      indToPush++
      newInd := indToPush - 1
      AListInst_%listId%_index_%newInd% := AListInst_%listId%_index_%indToPush%
    }
  AListInst_%listId%_index_%indToPush% := ""
  
}

