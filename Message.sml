(*
	Copyright (c) 2001
		David C.J. Matthews

	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 2.1 of the License, or (at your option) any later version.
	
	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	Lesser General Public License for more details.
	
	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*)

(*
Messaging functions.
This is based on Panos' version but substantially modified.
*)
structure Message :
  sig
    datatype ControlType =
          ODT_BUTTON
        | ODT_COMBOBOX
        | ODT_LISTBOX
        | ODT_MENU
        | ODT_STATIC
    datatype ImageType =
          IMAGE_BITMAP
        | IMAGE_CURSOR
        | IMAGE_ENHMETAFILE
        | IMAGE_ICON

	type HGDIOBJ and HWND and HMENU and HICON and HINSTANCE and HDC
	and HFONT and HRGN and HDROP
	type RECT =  { left: int, top: int, right: int, bottom: int }
	type POINT = { x: int, y: int }

    datatype LRESULT = LRESHANDLE of HGDIOBJ | LRESINT of int
    type KeyData
    type windowFlags and findReplaceFlags
    datatype ScrollDirection =
          SB_BOTTOM
        | SB_ENDSCROLL
        | SB_LEFT
        | SB_LINEDOWN
        | SB_LINELEFT
        | SB_LINERIGHT
        | SB_LINEUP
        | SB_PAGEDOWN
        | SB_PAGELEFT
        | SB_PAGERIGHT
        | SB_PAGEUP
        | SB_RIGHT
        | SB_THUMBPOSITION
        | SB_THUMBTRACK
        | SB_TOP

    type WindowPositionStyle
	
	datatype MouseKeyFlags = MK_LBUTTON | MK_RBUTTON | MK_SHIFT | MK_CONTROL | MK_MBUTTON

	type ClipboardFormat and ClassType 

	datatype MarginSettings = 
		UseFontInfo | Margins of {left: int option, right: int option }

	datatype MDITileFlags = MDITILE_VERTICAL | MDITILE_HORIZONTAL | MDITILE_SKIPDISABLED

    datatype
      SystemCommand =
          SC_ARRANGE
        | SC_CLOSE
        | SC_CONTEXTHELP
        | SC_DEFAULT
        | SC_HOTKEY
        | SC_HSCROLL
        | SC_KEYMENU
        | SC_MAXIMIZE
        | SC_MINIMIZE
        | SC_MONITORPOWER
        | SC_MOUSEMENU
        | SC_MOVE
        | SC_NEXTWINDOW
        | SC_PREVWINDOW
        | SC_RESTORE
        | SC_SCREENSAVE
        | SC_SEPARATOR
        | SC_SIZE
        | SC_TASKLIST
        | SC_VSCROLL
    datatype WMActivateOptions = WA_ACTIVE | WA_CLICKACTIVE | WA_INACTIVE

    datatype
      WMPrintOption =
          PRF_CHECKVISIBLE
        | PRF_CHILDREN
        | PRF_CLIENT
        | PRF_ERASEBKGND
        | PRF_NONCLIENT
        | PRF_OWNED

    datatype WMSizeOptions =
		SIZE_MAXHIDE | SIZE_MAXIMIZED | SIZE_MAXSHOW | SIZE_MINIMIZED | SIZE_RESTORED
	datatype HelpHandle = MenuHandle of HMENU | WindowHandle of HWND

		datatype Message     =
					WM_ACTIVATE of {active : WMActivateOptions, minimize : bool }
                      (* Indicates a change in activation state *)

                    | WM_ACTIVATEAPP of {active  : bool, threadid: int  } 
                      (* Notifies applications when a new task activates *)

                    | WM_ASKCBFORMATNAME of { length: int, formatName : string ref}	
                      (* Retrieves the name of the clipboard format *)

                    | WM_CANCELJOURNAL	
                      (* Notifies application when user cancels journaling *)

                    | WM_CANCELMODE	
                      (* Notifies a Window to cancel internal modes *)

                    | WM_CHANGECBCHAIN of { removed : HWND, next : HWND  }	
                      (* Notifies clipboard viewer of removal from chain *)

                    | WM_CHAR of {charCode : char, data : KeyData }                   	
                      (* Indicates the user pressed a character key *)

                    | WM_CHARTOITEM of {key : int, caretpos : int, listbox  : HWND  }
                      (* Provides list-box keystrokes to owner Window *)

                    | WM_CHILDACTIVATE	
                      (* Notifies a child Window of activation *)

(* This is WM_USER+1.  It's only used in a GetFont dialogue box.
                   | WM_CHOOSEFONT_GETLOGFONT of LOGFONT ref *)
                      (* Retrieves LOGFONT structure for Font dialog box *)

                    | WM_CLEAR
                      (* Clears an edit control *)

                    | WM_CLOSE   	
                      (* System Close menu command was chosen *)

                    | WM_COMMAND of {notifyCode : int,
                                  wId        : int,
                                  control    : HWND  }
                      (* Specifies a command message *)
                       
                    | WM_COMPACTING	of { compactratio : int }
                      (* Indicates a low memory condition *)

                    | WM_COMPAREITEM of {controlid : int,
				                           ctlType : ControlType,
                                           ctlID : int,
                                           hItem : HWND,
                                           itemID1 : int,
                                           itemData1 : int,
                                           itemID2 : int,
                                           itemData2 : int 				                          
				                           }
                      (* Determines position of combo- or list-box item *)

                    | WM_COPY
                      (* Copies a selection to the clipboard *)

                    | WM_COPYDATA of { sender : HWND, data : int, pdata: Word8Vector.vector }
                      (* Passes data to another application  *)

                    | WM_CREATE	of { instance: HINSTANCE,
									 creation: int,
                                     menu : HMENU,
                                     parent : HWND,
                                     cy : int,
                                     cx : int,
                                     y : int,
                                     x : int,
                                     style : windowFlags,
                                     name : string,
									 (* The class may be a string or an atom. *)
                                     class : ClassType,
                                     extendedstyle : int                                                                          
                                     }
                      (* Indicates a Window is being created *)

                    | WM_CTLCOLORBTN of { displaycontext : HDC, button : HWND  }
                      (* Button is about to be drawn *)

                    | WM_CTLCOLORDLG of { displaycontext : HDC,
                                       dialogbox      : HWND  }
                      (* Dialog box is about to be drawn *)
                     
                    | WM_CTLCOLOREDIT of {  displaycontext : HDC, editcontrol : HWND  }
                      (* Control is about to be drawn *)

                    | WM_CTLCOLORLISTBOX of { displaycontext : HDC, listbox : HWND   }
                      (* List box is about to be drawn *)

                    | WM_CTLCOLORMSGBOX	of { displaycontext : HDC,
                                             messagebox     : HWND  }
                      (* Message box is about to be drawn *)

                    | WM_CTLCOLORSCROLLBAR of { displaycontext : HDC,
                                             scrollbar      : HWND  }
                      (* Indicates scroll bar is about to be drawn *)

                    | WM_CTLCOLORSTATIC	of { displaycontext : HDC,
                                             staticcontrol  : HWND  }
                      (* Control is about to be drawn *)
					  (* Note the return value is an HBRUSH *)

                    | WM_CUT
                      (* Deletes a selection and copies it to the clipboard *)
(*
                    | WM_DDE_ACK
                      (* Acknowledges a DDE message *)

                    | WM_DDE_ADVISE	
                      (* Requests a DDE data-change update *)

                    | WM_DDE_DATA
                      (* Sends data to a DDE client *)
                       
                    | WM_DDE_EXECUTE
                      (* Sends a string to a DDE server *)

                    | WM_DDE_INITIATE	
                      (* Initiates a DDE conversation *)

                    | WM_DDE_POKE	
                      (* Send unsolicited data to a server *)
                       
                    | WM_DDE_REQUEST	
                      (* Requests data from a DDE server *)

                    | WM_DDE_TERMINATE	
                      (* Ends a DDE conversation *)

                    | WM_DDE_UNADVISE	
                      (* Stops a DDE data-update request *)
*)

                    | WM_DEADCHAR of { charCode : char, data  : KeyData   }
                      (* Indicates the user pressed a dead key *)

                    | WM_DELETEITEM	of { controlid : int,
                                             ctlType : ControlType,
                                             ctlID : int,
                                             itemID : int,
                                             item : HWND,
                                             itemData : int                                         
                                           }
                      (* Indicates owner-draw item or control was altered *)

                    | WM_DESTROY	
                      (* Indicates Window is about to be destroyed *)

                    | WM_DESTROYCLIPBOARD	
                      (* Notifies owner that the clipboard was emptied *)
                     
                    | WM_DEVMODECHANGE of { devicename : string }	
                      (* Indicates the device-mode settings have changed *)
                     
                    | WM_DRAWCLIPBOARD	
                      (* Indicates the clipboard's contents have changed *) 
                    
                    | WM_DRAWITEM of { controlid : int,
                                       ctlType : ControlType,
                                       ctlID : int,
                                       itemID : int,
                                       itemAction : int,
                                       itemState : int,
                                       hItem : HWND ,
                                       hDC : HDC,
                                       rcItem : RECT,
                                       itemData : int
                                        }	
                      (* Indicates owner-draw control/menu needs redrawing *) 
                     
                    | WM_DROPFILES of { hDrop : HDROP }	
                      (* Indicates that a file has been dropped *)
                    
                    | WM_ENABLE	of { enabled : bool }
                      (* Indicates a Window's enable state is changing *)
                    
                    | WM_ENDSESSION	of { endsession : bool }
                      (* Indicates whether the Windows session is ending *)
                    
                    | WM_ENTERIDLE of { flag : int, window : HWND }
                      (* Indicates a modal dialog box or menu is idle *)
                    
                    | WM_ENTERMENULOOP of { istrack: bool }
                      (* Indicates entry into menu modal loop *)
                    
                    | WM_EXITMENULOOP of { istrack: bool }
                      (* Indicates exit from menu modal loop *)
                    
                    | WM_ERASEBKGND	of { devicecontext : HDC }
                      (* Indicates a Window's background need erasing *)
                    
                    | WM_FONTCHANGE
                      (* Indicates a change in the font-resource pool *)
                     
                    | WM_GETDLGCODE
                      (* Allows dialog procedure to process control input *)
                    
                    | WM_GETFONT	
                      (* Retrieves the font that a control is using *)
                    
                    | WM_GETHOTKEY
                      (* Gets the virtual-key code of a Window's hot key *) 
                    
                    | WM_GETMINMAXINFO of { MaxSizex      : int,
	                                        MaxSizey      : int,
                                            MaxPositionx  : int,
	                                        MaxPositiony  : int,
                                            MinTrackSizex : int,
	                                        MinTrackSizey : int,
                                            MaxTrackSizex : int,
                                            MaxTrackSizey : int                                            
                                             }
                      (* Gets minimum and maximum sizing information *)
                    
                    | WM_GETTEXT of { length: int, text : string ref  }	
                      (* Gets the text that corresponds to a Window *)
                    
                    | WM_GETTEXTLENGTH	
                      (* Gets length of text associated with a Window *)
                    
                    | WM_HOTKEY	of { id : int }
                      (* Hot key has been detected *)
                    
                    | WM_HSCROLL of { value    : ScrollDirection,
                                       position : int,
                                       scrollbar   : HWND  }	
                      (* Indicates a click in a horizontal scroll bar *)
                    
                    | WM_HSCROLLCLIPBOARD of { viewer   : HWND,
                                               code     : int,
                                               position : int  }	
                      (* Prompts owner to scroll clipboard contents *)
                    
                    | WM_ICONERASEBKGND	of { devicecontext : HDC }
                      (* Notifies minimized Window to fill icon background *)
                    
                    | WM_INITDIALOG	of { dialog   : HWND, initdata : int  }
                      (* Initializes a dialog box *)
                    
                    | WM_INITMENU of { menu : HMENU }	
                      (* Indicates a menu is about to become active *)
                    
                    | WM_INITMENUPOPUP of { menupopup  : HMENU,
                                            itemposition : int,
					                        isSystemMenu : bool  }
                      (* Indicates a pop-up menu is being created *)
                    
                    | WM_KEYDOWN of { virtualKey : int, data : KeyData  }	
                      (* Indicates a nonsystem key was pressed *)
                    
                    | WM_KEYUP of { virtualKey : int, data : KeyData  }	
                      (* Indicates a nonsystem key was released *)
                    
                    | WM_KILLFOCUS of { receivefocus : HWND }
                      (* Indicates the Window is losing keyboard focus *)
                    
                    | WM_LBUTTONDBLCLK of { keyflags : MouseKeyFlags list, x : int, y : int  }
                      (* Indicates double-click of left button *) 
                    
                    | WM_LBUTTONDOWN of { keyflags : MouseKeyFlags list, x : int, y : int  }
                      (* Indicates when left mouse button is pressed *)
                    
                    | WM_LBUTTONUP of { keyflags : MouseKeyFlags list, x : int, y : int  }
                      (* Indicates when left mouse button is released *)
                    
                    | WM_MBUTTONDBLCLK of { keyflags : MouseKeyFlags list, x : int, y : int  }
                      (* Indicates double-click of middle mouse button *)
                    
                    | WM_MBUTTONDOWN of { keyflags : MouseKeyFlags list, x : int, y : int  }
                      (* Indicates when middle mouse button is pressed *)
                    
                    | WM_MBUTTONUP of { keyflags : MouseKeyFlags list, x : int, y : int  }
                      (* Indicates when middle mouse button is released *)
                          
                    | WM_MDICASCADE of { skipDisabled : bool  }	
                      (* Arranges MDI child Windows in cascade format *)
                    
                    | WM_MDICREATE of { class : ClassType,
                                         title : string,
										 instance: HINSTANCE,
                                         x : int,
                                         y : int,
                                         cx : int,
                                         cy : int,
                                         style : int,
                                         cdata : int }	
                      (* Prompts MDI client to create a child Window *) 
                    
                    | WM_MDIDESTROY of { child : HWND  }	
                      (* Closes an MDI child Window *) 
                    
                    | WM_MDIGETACTIVE
                      (* Retrieves data about the active MDI child Window *) 
                    
                    | WM_MDIICONARRANGE	
                      (* Arranges minimized MDI child Windows *) 
                    
                    | WM_MDIMAXIMIZE of {  child: HWND  }	
                      (* Maximizes an MDI child Window *) 
                    
                    | WM_MDINEXT of { child    : HWND, flagnext : bool  }
                      (* Activates the next MDI child Window *) 
                    
                    | WM_MDIREFRESHMENU
                      (* Refreshes an MDI frame Window's menu *) 
                     
                    | WM_MDIRESTORE	of {  child : HWND  }
                      (* Prompts MDI client to restore a child Window *) 
                    
                    | WM_MDISETMENU  of { frameMenu  : HMENU, windowMenu : HMENU  } 
                      (* Replaces an MDI frame Window's menu *) 
                    
                    | WM_MDITILE of { tilingflag : MDITileFlags list }
                      (* Arranges MDI child Windows in tiled format *) 
                    
                    | WM_MEASUREITEM of { controlid  : int,
                                          ctlType    : ControlType,
                                          ctlID      : int,
                                          itemID     : int,
                                          itemWidth  : int,
                                          itemHeight : int,
                                          itemData   : int
                                         }	
                      (* Requests dimensions of owner-draw control or item *)

                    | WM_MENUCHAR of { ch : char, menuflag : MenuBase.MenuFlag, menu : HMENU }	
                      (* Indicates an unknown menu mnemonic was pressed *)
                     
                    | WM_MENUSELECT	of { menuitem  : int,
					                     menuflags : MenuBase.MenuFlag list,
									     menu      : HMENU  }
                      (* Indicates that the user selected a menu item *)
                    
                    | WM_MOUSEACTIVATE of { parent   : HWND,
                                            hitTest : int,
                                            message  : int  }	
                      (* Indicates a mouse click in an inactive Window *) 
                    
                    | WM_MOUSEMOVE of { keyflags : MouseKeyFlags list, x : int, y : int  }	
                      (* Indicates mouse-cursor movement *)
                    
                    | WM_MOVE of { x : int, y : int  }	
                      (* Indicates a Window's position has changed *)
                    
                    | WM_NCACTIVATE of { active : bool }
                      (* Changes the active state of nonclient area *)
                    
                    | WM_NCCALCSIZE	of { validarea     : bool,
										     newrect       : RECT,
										     oldrect       : RECT,
										     oldclientarea : RECT,
											 hwnd		   : HWND,
										     insertAfter   : HWND,
                                             x     : int,
                                             y     : int,
                                             cx    : int,
                                             cy    : int,
                                             style : WindowPositionStyle list
					                       }
                      (* Calculates the size of a Window's client area *)
                    
                    | WM_NCCREATE of { instance: HINSTANCE,
									creation: int,
                                       menu : HMENU,
                                       parent : HWND,
                                       cy : int,
                                       cx : int,
                                       y : int,
                                       x : int,
                                       style : windowFlags,
                                       name : string,
                                       class : ClassType,
                                       extendedstyle : int                      
                                      }	
                      (* Indicates a Window's nonclient area being created *)

                    | WM_NCDESTROY	
                      (* Indicates Window's nonclient area being destroyed *)

                    | WM_NCHITTEST of { x : int, y : int  }	
                      (* Indicates mouse-cursor movement *)
                    
                    | WM_NCLBUTTONDBLCLK of { hitTest : int,
                                              x     : int,
                                              y     : int  }	
                      (* Indicates nonclient left button double-click *)
                     
                    | WM_NCLBUTTONDOWN	of { hitTest : int, x : int, y : int  }	
                      (* Indicates left button pressed in nonclient area *)
                    
                    | WM_NCLBUTTONUP of { hitTest : int, x : int, y : int  }	
                      (* Indicates left button released in nonclient area *)
                    
                    | WM_NCMBUTTONDBLCLK of { hitTest : int, x : int, y : int  }	
                      (* Indicates nonclient middle button double-click *)
                    
                    | WM_NCMBUTTONDOWN of { hitTest : int, x : int, y : int  }	
                      (* Indicates middle button pressed in nonclient area *)
                    
                    | WM_NCMBUTTONUP of { hitTest : int, x : int, y : int  }	
                      (* Indicates middle button released in nonclient area *)
                    
                    | WM_NCMOUSEMOVE of { hitTest : int, x : int, y : int  }	
                      (* Indicates mouse-cursor movement in nonclient area *)
                    
                    | WM_NCPAINT of { region : HRGN  }	
                      (* Indicates a Window's frame needs painting *)
                    
                    | WM_NCRBUTTONDBLCLK of { hitTest : int, x : int, y : int  }	
                      (* Indicates nonclient right button double-click *)
                    
                    | WM_NCRBUTTONDOWN of { hitTest : int, x : int, y : int  }	
                      (* Indicates right button pressed in nonclient area *)
                    
                    | WM_NCRBUTTONUP of { hitTest : int, x : int, y : int  }	
                      (* Indicates right button released in nonclient area *)
                    
                    | WM_NEXTDLGCTL	of { control    : int, handleflag : bool  } 
                      (* Sets focus to different dialog box control *) 
                    
                    | WM_PAINT	
                      (* Indicates a Window's client area need painting *)
                    
                    | WM_PAINTCLIPBOARD of { clipboard : HWND }
                      (* Prompts owner to display clipboard contents *)
                    
                    | WM_PAINTICON
                      (* Icon is about to be painted *) 

                    | WM_PALETTECHANGED of { palChg : HWND  }	
                      (* Indicates the focus-Window realized its palette *)
                    
                    | WM_PALETTEISCHANGING of { realize : HWND  }	
                      (* Informs Windows that palette is changing *) 
                    
                    | WM_PARENTNOTIFY of { eventflag : int, idchild   : int, value : int }	
                      (* Notifies parent of child-Window activity *) 
                    
                    | WM_PASTE	
                      (* Inserts clipboard data into an edit control *)
                    
                    | WM_POWER of { powerevent : int  }	
                      (* Indicates the system is entering suspended mode *)
                    
                    | WM_QUERYDRAGICON	
                      (* Requests a cursor handle for a minimized Window *)
                    
                    | WM_QUERYENDSESSION of { source : int  }
                      (* Requests that the Windows session be ended *) 
                    
                    | WM_QUERYNEWPALETTE
                      (* Allows a Window to realize its logical palette *) 
                    
                    | WM_QUERYOPEN
                      (* Requests that a minimized Window be restored *) 
                    
                    | WM_QUEUESYNC
                      (* Delimits CBT messages *) 
                    
                    | WM_QUIT of { exitcode : int  }	
                      (* Requests that an application be terminated *)
                    
                    | WM_RBUTTONDBLCLK of { keyflags : MouseKeyFlags list, x: int, y: int  }	
                      (* Indicates double-click of right mouse button *)
                    
                    | WM_RBUTTONDOWN of { keyflags : MouseKeyFlags list, x: int, y: int  }	
                      (* Indicates when right mouse button is pressed *)

                    | WM_RBUTTONUP of { keyflags : MouseKeyFlags list, x: int, y: int  }
                      (* Indicates when right mouse button is released *) 
                    
                    | WM_RENDERALLFORMATS	
                      (* Notifies owner to render all clipboard formats *) 
                    
                    | WM_RENDERFORMAT of { format : ClipboardFormat  }	
                      (* Notifies owner to render clipboard data *) 
                    
                    | WM_SETCURSOR of { cursorwindow : HWND, hitTest : int, mousemessage : int  }	
                      (* Prompts a Window to set the cursor shape *) 
                    
                    | WM_SETFOCUS of { losing : HWND  }
                    
                    | WM_SETFONT of {font : HFONT, redrawflag : bool  }	
                    
                    | WM_SETHOTKEY of { virtualKey : int  }	
                    
                    | WM_SETREDRAW of { redrawflag : int  }
                    
                    | WM_SETTEXT of { text : string  }	
                    
                    | WM_SHOWWINDOW	of { showflag   : bool, statusflag : int  } 
                    
                    | WM_SIZE of { flag : WMSizeOptions, width : int, height : int  }	
                    
                    | WM_SIZECLIPBOARD of { viewer : HWND}
                    
                    | WM_SPOOLERSTATUS of { jobstatus : int, jobsleft  : int  }	
                    
                    | WM_SYSCHAR of { charCode : char, data : KeyData  }
                    
                    | WM_SYSCOLORCHANGE
                    
                    | WM_SYSCOMMAND of { commandvalue : SystemCommand, p: POINT }
                    
                    | WM_SYSDEADCHAR of { charCode : char, data : KeyData  }
                   
                    | WM_SYSKEYDOWN of { virtualKey : int, data : KeyData  }

                    | WM_SYSKEYUP of { virtualKey : int, data : KeyData  }
                    
                    | WM_TIMECHANGE	
                      (* Indicates the system time has been set *)
                    
                    | WM_TIMER of { timerid : int  }
                    
                    | WM_UNDO	
                     
                    | WM_USER of { uMsg: int, wParam: int, lParam: int }
                    | WM_APP of { uMsg: int, wParam: int, lParam: int }
                    | WM_REGISTERED of { uMsg: int, wParam: int, lParam: int }
                    
                    | WM_VKEYTOITEM	of { virtualKey : int,
                                         caretpos   : int,
                                         listbox    : HWND  }
                     
                    | WM_VSCROLL of { value     : ScrollDirection,
                                      position  : int,
                                      scrollbar : HWND  }

                    | WM_VSCROLLCLIPBOARD of { viewer   : HWND,
                                               code     : int,
                                               position : int  }
                    
                    | WM_WINDOWPOSCHANGED of { hwnd: HWND, front  : HWND,
                                               x   : int,
                                               y   : int,
                                               width  : int,
                                               height : int,
                                               flags  : WindowPositionStyle list }
                    
                    | WM_WINDOWPOSCHANGING of { hwnd: HWND, front  : HWND,
                                                x   : int,
                                                y   : int,
                                                width  : int,
                                                height : int,
                                                flags  : WindowPositionStyle list }	
                     
                    | WM_SETTINGCHANGE of { section_name : string  }	

					| WM_NOTIFY of {from: HWND, idCtrl: int, idFrom : int, code: int }

					| WM_CAPTURECHANGED of { newCapture: HWND }

					| WM_ENTERSIZEMOVE

					| WM_EXITSIZEMOVE

					| WM_PRINT of {hdc: HDC, flags: WMPrintOption list }

					| WM_PRINTCLIENT of {hdc: HDC, flags: WMPrintOption list }

					| WM_HELP of { ctrlId: int, itemHandle: HelpHandle, contextId: int,
								   mousePos: POINT }

					| WM_GETICON of { big: bool }

					| WM_SETICON of { big: bool, icon: HICON }

					| WM_CONTEXTMENU of { hwnd: HWND, xPos: int, yPos: int }

					| WM_DISPLAYCHANGE of { bitsPerPixel: int, xScreen: int, yScreen: int }

					| EM_CANUNDO

					| EM_CHARFROMPOS of { point: POINT }

					| EM_EMPTYUNDOBUFFER

					| EM_FMTLINES of {addEOL: bool}

					| EM_GETFIRSTVISIBLELINE

					| EM_GETLIMITTEXT

					| EM_GETLINE of { lineNo: int, size: int, result: string ref }

					| EM_GETLINECOUNT

					| EM_GETMARGINS

					| EM_GETMODIFY

					| EM_GETPASSWORDCHAR

					| EM_GETRECT of {rect: RECT ref}

					| EM_GETSEL of {startPos: int ref, endPos: int ref}

					| EM_GETTHUMB

					| EM_LIMITTEXT of {limit: int}

					| EM_LINEFROMCHAR of {index: int}

					| EM_LINEINDEX of {line: int}

					| EM_LINELENGTH of {index: int}

					| EM_LINESCROLL of {xScroll: int, yScroll: int}

					| EM_POSFROMCHAR of {index: int}

					| EM_REPLACESEL of {canUndo: bool, text: string}

					| EM_SCROLL of {action: ScrollDirection}

					| EM_SCROLLCARET

					| EM_SETMARGINS of {margins: MarginSettings}

					| EM_SETMODIFY of { modified: bool }

					| EM_SETPASSWORDCHAR of { ch: char }

					| EM_SETREADONLY of { readOnly: bool }

					| EM_SETRECT of {rect: RECT}

					| EM_SETRECTNP of {rect: RECT}

					| EM_SETSEL of {startPos: int, endPos: int}

					| EM_SETTABSTOPS of {tabs: int list}

					| EM_UNDO

					| BM_CLICK

					| BM_GETCHECK

					| BM_GETIMAGE of {imageType: ImageType}

					| BM_GETSTATE

					| BM_SETCHECK of {state: int}

					| BM_SETIMAGE of {image: HGDIOBJ, imageType: ImageType}

					| BM_SETSTATE of {highlight: bool }

					| BM_SETSTYLE of {redraw: bool, style: windowFlags}

					| CB_GETEDITSEL of {startPos: int ref, endPos: int ref}

					| CB_LIMITTEXT of {limit: int}

					| CB_SETEDITSEL of {startPos: int, endPos: int}

					| CB_ADDSTRING of { text: string }

					| CB_DELETESTRING of { index: int }

					| CB_GETCOUNT

					| CB_GETCURSEL

					| CB_DIR of { attrs: ComboBase.CBDirAttr list, fileSpec: string }

					| CB_GETLBTEXT of { index: int, length: int, text: string ref }

					| CB_GETLBTEXTLEN of { index: int }

					| CB_INSERTSTRING of { index: int, text: string }

					| CB_RESETCONTENT

					| CB_FINDSTRING of { indexStart: int, text: string }

					| CB_SELECTSTRING of { indexStart: int, text: string }

					| CB_SETCURSEL of { index: int }

					| CB_SHOWDROPDOWN of { show: bool }

					| CB_GETITEMDATA of { index: int }

					| CB_SETITEMDATA of { index: int, data: int }

					| CB_GETDROPPEDCONTROLRECT of { rect: RECT ref }

					| CB_SETITEMHEIGHT of { index: int, height: int }

					| CB_GETITEMHEIGHT of { index: int }

					| CB_SETEXTENDEDUI of { extended: bool }

					| CB_GETEXTENDEDUI

					| CB_GETDROPPEDSTATE

					| CB_FINDSTRINGEXACT of { indexStart: int, text: string }

					| CB_SETLOCALE of { locale: int }

					| CB_GETLOCALE

					| CB_GETTOPINDEX

					| CB_SETTOPINDEX of { index: int }

					| CB_GETHORIZONTALEXTENT

					| CB_SETHORIZONTALEXTENT of { extent: int }

					| CB_GETDROPPEDWIDTH

					| CB_SETDROPPEDWIDTH of { width: int }

					| CB_INITSTORAGE of { items: int, bytes: int }

					| LB_ADDSTRING of { text: string }

					| LB_INSERTSTRING of { index: int, text: string }

					| LB_DELETESTRING of { index: int }

					| LB_SELITEMRANGEEX of { first: int, last: int }

					| LB_RESETCONTENT

					| LB_SETSEL of { select: bool, index: int }

					| LB_SETCURSEL of { index: int }

					| LB_GETSEL of { index: int }

					| LB_GETCURSEL

					| LB_GETTEXT of { index: int, length: int, text: string ref }

					| LB_GETTEXTLEN of { index: int }

					| LB_GETCOUNT

					| LB_SELECTSTRING of { indexStart: int, text: string }

					| LB_DIR of { attrs: ComboBase.CBDirAttr list, fileSpec: string }

					| LB_GETTOPINDEX

					| LB_FINDSTRING of { indexStart: int, text: string }

					| LB_GETSELCOUNT

					| LB_GETSELITEMS of { itemCount: int, items: int list ref }

					| LB_SETTABSTOPS of { tabs: int list }

					| LB_GETHORIZONTALEXTENT

					| LB_SETHORIZONTALEXTENT of { extent: int }

					| LB_SETCOLUMNWIDTH of { column: int }

					| LB_ADDFILE of { fileName: string }

					| LB_SETTOPINDEX of { index: int }

					| LB_GETITEMRECT of { rect: RECT ref, index: int }

					| LB_GETITEMDATA of { index: int }

					| LB_SETITEMDATA of { index: int, data: int }

					| LB_SELITEMRANGE of { select: bool, first: int, last: int }

					| LB_SETANCHORINDEX of { index: int }

					| LB_GETANCHORINDEX

					| LB_SETCARETINDEX of { index: int, scroll: bool }

					| LB_GETCARETINDEX

					| LB_SETITEMHEIGHT of { index: int, height: int }

					| LB_GETITEMHEIGHT of { index: int }

					| LB_FINDSTRINGEXACT of { indexStart: int, text: string }

					| LB_SETLOCALE of { locale: int } (* Should be an abstract type? *)

					| LB_GETLOCALE (* Result will be the type used above. *)

					| LB_SETCOUNT of { items: int }

					| LB_INITSTORAGE of { items: int, bytes: int }

					| LB_ITEMFROMPOINT of { point: POINT }

					| STM_GETICON

					| STM_GETIMAGE of {imageType: ImageType}

					| STM_SETICON of {icon: HICON}

					| STM_SETIMAGE of {image: HGDIOBJ, imageType: ImageType}

					| SBM_SETPOS of { pos: int, redraw: bool }

					| SBM_GETPOS

					| SBM_SETRANGE of { minPos: int, maxPos: int }

					| SBM_SETRANGEREDRAW of { minPos: int, maxPos: int }

					| SBM_GETRANGE of { minPos: int ref, maxPos: int ref }

					| SBM_ENABLE_ARROWS of ScrollBase.enableArrows

					| SBM_SETSCROLLINFO of { info: ScrollBase.SCROLLINFO,
											 options: ScrollBase.ScrollInfoOption list }

					| SBM_GETSCROLLINFO of { info: ScrollBase.SCROLLINFO ref,
											 options: ScrollBase.ScrollInfoOption list }

					| FINDMSGSTRING of
						{ flags: findReplaceFlags, findWhat: string, replaceWith: string }

					| NULL


	type MSG = {
		msg: Message,
		hwnd: HWND,
		time: Time.time,
		pt: {x: int, y: int}
		}

    val GetInputState : unit -> bool
    val GetMessage : HWND option * int * int -> MSG
    val GetMessagePos : unit -> POINT
    val GetMessageTime : unit -> Time.time

    datatype
      QueueStatus =
          QS_ALLPOSTMESSAGE
        | QS_HOTKEY
        | QS_KEY
        | QS_MOUSEBUTTON
        | QS_MOUSEMOVE
        | QS_PAINT
        | QS_POSTMESSAGE
        | QS_SENDMESSAGE
        | QS_TIMER
    val QS_ALLEVENTS : QueueStatus list
    val QS_ALLINPUT : QueueStatus list
    val QS_INPUT : QueueStatus list
    val QS_MOUSE : QueueStatus list
    val GetQueueStatus : QueueStatus list -> QueueStatus list

    val InSendMessage : unit -> bool

    datatype PeekMessageOptions = PM_NOREMOVE | PM_REMOVE
    val PeekMessage : HWND option * int * int * PeekMessageOptions -> MSG option
    val PostQuitMessage : int -> unit
    val RegisterWindowMessage : string -> int
    val RunApplication : unit -> int
    val SendMessage : HWND * Message -> LRESULT
	val PostMessage : HWND * Message -> unit
	val HWND_BROADCAST: HWND
    val WaitMessage : unit -> bool

	(* These last few are just used internally. *)
    val subclass :
       HWND * (HWND * Message * 'a -> LRESULT option * 'a) * 'a -> unit

    val addCallback :
		HWND * ( HWND * Message * 'a -> LRESULT option * 'a) * 'a * (int * int * int * int -> int) -> unit
    val addModelessDialogue : HWND * CInterface.vol -> unit
    val removeCallback : HWND -> unit
	val updateWindowHandle: HWND -> unit
	val compileMessage: Message -> int * CInterface.vol * CInterface.vol
	val LPMSG: MSG CInterface.Conversion
  end
 =
struct
	local
		open CInterface
		open Base
		open Globals
		open WinBase
	    fun user name = load_sym (load_lib "user32.dll") name
		
		val COPYDATASTRUCT = STRUCT3(LONG, LONG, POINTER)
		val (fromCcopydata, toCcopydata, _) = breakConversion COPYDATASTRUCT
		val WINDOWPOS = STRUCT7(HWND, HWND, INT, INT, INT, INT, WINDOWPOSITIONSTYLE)    
		val (fromCwindowpos, toCwindowpos, _) = breakConversion WINDOWPOS
		val NMHDR = STRUCT3(HWND, INT, INT)
		val (fromCnmhdr, toCnmhdr, _) = breakConversion NMHDR
		val MDICREATESTRUCT = STRUCT9(CLASS,STRING,HINSTANCE,INT,INT,INT,INT,LONG,LONG)
		val (fromCmdicreatestruct, toCmdicreatestruct, _) = breakConversion MDICREATESTRUCT
		val MEASUREITEMSTRUCT = STRUCT6(MessageBase.CONTROLTYPE,INT,INT,INT,INT,INT)
		val (fromCmeasureitemstruct, toCmeasureitemstruct, _) = breakConversion MEASUREITEMSTRUCT
		val DELETEITEMSTRUCT = STRUCT5(MessageBase.CONTROLTYPE,INT,INT,HWND,INT)
		val (fromCdeleteitemstruct, toCdeleteitemstruct, _) = breakConversion DELETEITEMSTRUCT
		val COMPAREITEMSTRUCT = STRUCT7(MessageBase.CONTROLTYPE,INT,HWND,INT,LONG,INT,LONG)
		val (fromCcompareitemstruct, toCcompareitemstruct, _) = breakConversion COMPAREITEMSTRUCT
		val CREATESTRUCT = STRUCT12(INT,HINSTANCE,HMENU,HWND,INT,INT,INT,INT,WORD,STRING,CLASS,LONG)
		val (fromCcreatestruct, toCcreatestruct, _) = breakConversion CREATESTRUCT
		val MINMAXINFO = STRUCT10(INT,INT,INT,INT,INT,INT,INT,INT,INT,INT)
		val (fromCminmaxinfo, toCminmaxinfo, _) = breakConversion MINMAXINFO
		val DRAWITEMSTRUCT = STRUCT9(MessageBase.CONTROLTYPE,INT,INT,INT,INT,HWND,HDC,RECT,LONG)
		val (fromCdrawitemstruct, toCdrawitemstruct, _) = breakConversion DRAWITEMSTRUCT
		val NCCALCSIZE_PARAMS = STRUCT4(RECT,RECT,RECT,POINTERTO WINDOWPOS)
		val (fromCncalcsizestruct, toCncalcsizestruct, _) = breakConversion NCCALCSIZE_PARAMS
		val HELPINFO = STRUCT6(INT, INT, INT, INT, INT, POINT)
		val (fromChelpinfo, toChelpinfo, helpStruct) = breakConversion HELPINFO
		
		val (toHMENU, fromHMENU, _) = breakConversion HMENU
		and (toHWND,  fromHWND, _)  = breakConversion HWND
		and (toHDC,   fromHDC, _)   = breakConversion HDC
		and (toHFONT, fromHFONT, _) = breakConversion HFONT
		and (toHRGN,  fromHRGN, _)  = breakConversion HRGN
		and (toHDROP, fromHDROP, _) = breakConversion HDROP
		and (toHINST, fromHINST, _) = breakConversion HINSTANCE
		and (fromCrect, toCrect, _) = breakConversion RECT
		and (fromCsd, toCsd, _)     = breakConversion MessageBase.SCROLLDIRECTION
		and (fromCit, toCit, _)     = breakConversion MessageBase.IMAGETYPE
		and (fromCcbf, toCcbf, _)	= breakConversion CLIPFORMAT
		and (fromCwmsf, toCwmsf, _) = breakConversion MessageBase.WMSIZEOPTIONS
		val (fromCscrollinfo, toCscrollinfo, _) = breakConversion ScrollBase.SCROLLINFO
		val (fromCesbf, toCesbf, _) = breakConversion ScrollBase.ENABLESCROLLBARFLAG
		val (fromCsysc, toCsysc, _) = breakConversion MessageBase.SYSTEMCOMMAND
		val (fromCcbal, toCcbal, _) = breakConversion ComboBase.CBDIRATTRS
		val (fromCwmpl, toCwmpl, _) = breakConversion MessageBase.WMPRINTOPS
		val (fromCmkf,  toCmkf, _)  = breakConversion MessageBase.MOUSEKEYFLAGS
		val (fromCmdif, toCmdif, _) = breakConversion MessageBase.MDITILEFLAGS

		fun itob i = i <> 0

		val RegisterMessage = call1 (user "RegisterWindowMessageA") STRING UINT
	in
		open MessageBase (* Get Message, MSG and ImageType *)
		type HGDIOBJ = HGDIOBJ and HWND = HWND and RECT = RECT and POINT = POINT
		and HMENU = HMENU and HICON = HICON and HINSTANCE = HINSTANCE and HDC = HDC
		and HFONT = HFONT and HRGN = HRGN and HDROP = HDROP
		and ClipboardFormat = ClipboardFormat and ClassType = ClassType
		and findReplaceFlags = FindReplaceFlags.flags
		and windowFlags = flags
	
	fun decompileMessage (m: int, wp: int, lp: int) =
	(* Decode a received message.  All the parameters are ints at this stage 
	   because the parameters are passed from the callback mechanism which
	   doesn't go through the CInterface structure. *)
	case m of  

		 0x0000 => NULL

	  |  0x0001 =>
		 	let
				val (cp,inst,menu,parent, cy,cx,y,x, style, name,class, extendedstyle) =
				 	fromCcreatestruct (deref (toClong lp))
            in
	            WM_CREATE { instance = inst,
						 creation = cp,
	                     menu = menu,
	                     parent = parent,
	                     cy = cy,
	                     cx = cx,
	                     y = y,
	                     x = x,
	                     style = Style.fromWord style,
	                     name = name,
	                     class = class,
	                     extendedstyle = extendedstyle }
			end
	
	  |  0x0002 =>  WM_DESTROY
	
	  |  0x0003 =>  WM_MOVE { x = LOWORD lp, y = HIWORD lp }
	
	  |  0x0005 =>  WM_SIZE { flag = fromCwmsf(toCint wp), width = LOWORD lp, height = HIWORD lp }

	  |  0x0006 =>  WM_ACTIVATE { active = toWMactive (LOWORD wp), minimize = itob (HIWORD wp) }
	
	  |  0x0007 =>  WM_SETFOCUS { losing = toHWND (toClong wp) } 
	
	  |  0x0008 =>  WM_KILLFOCUS { receivefocus = toHWND (toClong wp) }
	
	  |  0x000A =>  WM_ENABLE { enabled = itob wp }
	
	  |  0x000B =>  WM_SETREDRAW { redrawflag = wp  }
	
	  |  0x000C =>  WM_SETTEXT { text = fromCstring (toClong lp)  }

		  (* When the message arrives we don't know what the text is. *)
	  |  0x000D =>  WM_GETTEXT { length = wp, text = ref ""  }
	
	  |  0x000E =>  WM_GETTEXTLENGTH
	
	  |  0x000F =>  WM_PAINT
	
	  |  0x0010 =>  WM_CLOSE
	
	  |  0x0011 =>  WM_QUERYENDSESSION { source = wp  }
	
	  |  0x0012 =>  WM_QUIT { exitcode = wp  }
	
	  |  0x0013 =>  WM_QUERYOPEN
	
	  |  0x0014 =>  WM_ERASEBKGND { devicecontext = toHDC (toClong wp) }
	
	  |  0x0015 =>  WM_SYSCOLORCHANGE
	
	  |  0x0016 =>  WM_ENDSESSION { endsession = itob wp }
	
	  |  0x0018 =>  WM_SHOWWINDOW  { showflag = itob wp, statusflag = lp  }
	
	  |  0x001A =>  WM_SETTINGCHANGE { section_name = fromCstring (toClong lp)  } (* "0x001A" *)
	
	  |  0x001B =>  WM_DEVMODECHANGE { devicename = fromCstring (toClong lp) } (* "0x001B" *)
	
	  |  0x001C =>  WM_ACTIVATEAPP { active   = itob wp, threadid = lp } (* "0x001C" *)
	
	  |  0x001D =>  WM_FONTCHANGE
	
	  |  0x001E =>  WM_TIMECHANGE (* "0x001E" *)
	
	  |  0x001F =>  WM_CANCELMODE (* "0x001F" *)
	
	  |  0x0020 =>  WM_SETCURSOR { cursorwindow = toHWND (toClong wp), hitTest      = LOWORD lp,
	                            mousemessage = HIWORD lp  } (* "0x0020" *)
	
	  |  0x0021 =>  WM_MOUSEACTIVATE { parent   = toHWND (toClong wp),
									hitTest = LOWORD lp, message  = HIWORD lp  }(* "0x0021" *)
	
	  |  0x0022 =>  WM_CHILDACTIVATE (* "0x0022" *)
	
	  |  0x0023 =>  WM_QUEUESYNC (* "0x0023" *)
	
	  |  0x0024 =>
	  		let  
			  val (ptresx,ptresy, ptmsx,ptmsy, ptmpx,ptmpy, pttsx,pttsy, ptmtsx,ptmtsy) =
			  	fromCminmaxinfo(deref (toClong lp))
            in
             WM_GETMINMAXINFO { MaxSizex = ptmsx, MaxSizey = ptmsy,
                             MaxPositionx = ptmpx, MaxPositiony = ptmpy,
                             MinTrackSizex = pttsx, MinTrackSizey = pttsy,
                             MaxTrackSizex = ptmtsx, MaxTrackSizey = ptmtsy  }
			end
	
	  |  0x0026 =>  WM_PAINTICON
	
	  |  0x0027 =>  WM_ICONERASEBKGND { devicecontext = toHDC (toClong wp) } (* "0x0027" *)
	
	  |  0x0028 =>  WM_NEXTDLGCTL { control = wp, handleflag = itob lp  } (* "0x0028" *)
	
	  |  0x002A =>  WM_SPOOLERSTATUS { jobstatus = wp, jobsleft  = LOWORD lp  } (* "0x002A" *)
	 
	  |  0x002B =>
	  		let
			  val (ctlType,ctlID,itemID,itemAction,itemState,hItem,hDC,
				   rcItem,itemData) = 
				fromCdrawitemstruct(deref (toClong lp)) 
            in
				WM_DRAWITEM  { controlid = wp,
                            ctlType = ctlType,
                            ctlID = ctlID,
                            itemID = itemID,
                            itemAction = itemAction,
                            itemState = itemState,
                            hItem = hItem,
                            hDC = hDC,
                            rcItem = rcItem,
                            itemData = itemData
                           }
		    end
	
	  |  0x002C =>
	  		let
				val (ctlType,ctlID,itemID, itemWidth,itemHeight,itemData) =
					fromCmeasureitemstruct (deref (toClong lp))
            in
            	WM_MEASUREITEM {controlid = wp,
                              ctlType = ctlType,
                              ctlID = ctlID,
                              itemID = itemID,
                              itemWidth = itemWidth,
                              itemHeight = itemHeight,
                              itemData = itemData 
                         }
			end
	
	  |  0x002D =>
			let
				val (ctlType,ctlID,itemID,hItem,itemData) = 
				      fromCdeleteitemstruct(deref (toClong lp))
            in
				WM_DELETEITEM { controlid = wp,
                             ctlType = ctlType,
                             ctlID = ctlID,
                             itemID = itemID,
                             item = hItem,
                             itemData = itemData                                         
                            }
			end
	
	  |  0x002E =>  WM_VKEYTOITEM  { virtualKey = LOWORD wp,
								  caretpos = HIWORD wp, listbox = toHWND (toClong lp)  } (* "0x002E" *)
	
	  |  0x002F =>  WM_CHARTOITEM { key = LOWORD wp,
	                             caretpos = HIWORD wp,listbox  = toHWND (toClong lp)  } (* "0x002F" *)
	
	  |  0x0030 =>  WM_SETFONT { font = toHFONT (toClong wp), redrawflag = itob lp  } (* "0x0030" *)
	
	  |  0x0031 =>  WM_GETFONT (* "0x0031" *)
	
	  |  0x0032 =>  WM_SETHOTKEY { virtualKey = wp  } (* "0x0032" *)
	
	  |  0x0033 =>  WM_GETHOTKEY (* "0x0033" *)
	
	  |  0x0037 =>  WM_QUERYDRAGICON (* "0x0037" *)
	
	  |  0x0039 =>
			let
				val (ctlType,ctlID, hItem, itemID1,itemData1, itemID2,itemData2) =
				      fromCcompareitemstruct(deref (toClong lp))		 
            in
            	WM_COMPAREITEM { controlid = wp, 
                              ctlType = ctlType,
                              ctlID = ctlID,
                              hItem = hItem,
                              itemID1 = itemID1,
                              itemData1 = itemData1,
                              itemID2 = itemID2,
                              itemData2 = itemData2
                             } (* "0x0039" *)
			end
	
	  |  0x0041 =>  WM_COMPACTING { compactratio = wp } (* "0x0041" *)
	
	  |  0x0046 =>
			let
			  val (wh,front,x,y,width,height,flags) = fromCwindowpos(deref(toClong lp)) 
            in
            	WM_WINDOWPOSCHANGING {  hwnd = wh, front  = front, x   = x,
                                     y   = y, width  = width, height = height,
                                     flags  = flags}
			end 

	  |  0x0047 =>
			let
			  val (wh,front,x,y,width,height,flags) = fromCwindowpos(deref(toClong lp)) 
            in
            	WM_WINDOWPOSCHANGED {  hwnd = wh, front  = front, x   = x,
                                     y   = y, width  = width, height = height,
                                     flags  = flags}
			end
	
	  |  0x0048 =>  WM_POWER { powerevent = wp  } (* "0x0048" *)
	
	  |  0x004A =>
			let
				val (data,cbData,lpData) = fromCcopydata(deref (toClong lp))
				(* Extract the memory block as a Word8Vector.vector. *)
				(* TODO: Test this.  Have we got the correct level of indirection? *)
				val pdata = toWord8vec (lpData, cbData)
			in
				WM_COPYDATA  { sender = toHWND (toClong wp), data = data, pdata = pdata }
			end
	
	  |  0x004B =>  WM_CANCELJOURNAL (* "0x004B" *)

	  |  0x004E =>
			let
				val (hwndFrom, idFrom, code) = fromCnmhdr (deref (toClong lp))
			in
				WM_NOTIFY  { idCtrl = wp, from = hwndFrom, idFrom = idFrom, code = code}
			end

	  |  0x0053 =>
	  		let
				val (_, contextType, ctrlId, itemHandle, contextId, mousePos) =
					fromChelpinfo(deref (toClong lp))
				val hndl =
					if ctrlId = 2 then MenuHandle(handleOfInt itemHandle)
					else WindowHandle(handleOfInt itemHandle)
			in
				WM_HELP { ctrlId = ctrlId, itemHandle = hndl, contextId =  contextId,
						  mousePos = mousePos}
			end
(*
WM_INPUTLANGCHANGEREQUEST       0x0050
WM_INPUTLANGCHANGE              0x0051
WM_TCARD                        0x0052
WM_USERCHANGED                  0x0054
WM_NOTIFYFORMAT                 0x0055

NFR_ANSI                             1
NFR_UNICODE                          2
NF_QUERY                             3
NF_REQUERY                           4

WM_CONTEXTMENU                  0x007B
WM_STYLECHANGING                0x007C
WM_STYLECHANGED                 0x007D
*)

	  |  0x007B =>
	  		WM_CONTEXTMENU { hwnd = toHWND (toClong wp), xPos = LOWORD lp, yPos = HIWORD lp}

	  |  0x007E =>
			WM_DISPLAYCHANGE { bitsPerPixel = wp, xScreen = LOWORD lp, yScreen = HIWORD lp}

	  |  0x007F => WM_GETICON { big = wp = 1}

	  |  0x0080 => WM_SETICON { big = wp = 1, icon = handleOfInt lp}

	  |  0x0081 =>
			let
				val (cp,inst,menu,parent, cy,cx,y,x, style, name,class, extendedstyle) =
				 	fromCcreatestruct (deref (toClong lp))
            in
            	WM_NCCREATE { instance = inst,
						 creation = cp,
	                     menu = menu,
	                     parent = parent,
	                     cy = cy,
	                     cx = cx,
	                     y = y,
	                     x = x,
	                     style = Style.fromWord style,
	                     name = name,
	                     class = class,
	                     extendedstyle = extendedstyle }
			end
	
	  |  0x0082 =>  WM_NCDESTROY
	
	
	  |  0x0083 =>
	  		if itob wp
			then
				let
					val (newrect,oldrect,oldclientarea,winpos) =
						fromCncalcsizestruct (deref (toClong lp))
			  		val (wh,front,x,y,cx,cy,style) = winpos 
				in
					WM_NCCALCSIZE 
                          { 
                            validarea = true,
					        newrect = newrect,
					        oldrect = oldrect,
					        oldclientarea = oldclientarea,
							hwnd = wh,
					        insertAfter = front,
                            x = x,
                            y = y,
                            cx = cx,
                            cy = cy,
                            style = style 
                            }
				end
			else (* lParam points to a rect. *)
				let
					val newrect = fromCrect (deref (toClong lp))
				in
					WM_NCCALCSIZE 
                      { 
                        validarea = false,
				        newrect = newrect,
				        oldrect = {left=0, top=0, right=0, bottom=0},
				        oldclientarea = {left=0, top=0, right=0, bottom=0},
				        insertAfter = hwndNull,
				        hwnd = hwndNull,
                        x = 0,
                        y = 0,
                        cx = 0,
                        cy = 0,
                        style = [] 
                        }
				end

	  |  0x0084 =>  WM_NCHITTEST { x = LOWORD lp, y = HIWORD lp  } (* "0x0084" *)
	
	  |  0x0085 =>  WM_NCPAINT { region = toHRGN (toClong wp)  } (* "0x0085" *)
	
	  |  0x0086 =>  WM_NCACTIVATE  { active = itob wp } (* "0x0086" *)
	
	  |  0x0087 =>  WM_GETDLGCODE (* "0x0087" *)
	
	  |  0x00A0 =>  WM_NCMOUSEMOVE { hitTest = wp, x = LOWORD lp, y = HIWORD lp  }
	
	  |  0x00A1 =>  WM_NCLBUTTONDOWN { hitTest = wp, x = LOWORD lp, y = HIWORD lp  }
	
	  |  0x00A2 =>  WM_NCLBUTTONUP { hitTest = wp, x = LOWORD lp, y = HIWORD lp  }
	
	  |  0x00A3 =>  WM_NCLBUTTONDBLCLK { hitTest = wp, x = LOWORD lp, y = HIWORD lp  }
	
	  |  0x00A4 =>  WM_NCRBUTTONDOWN { hitTest = wp, x = LOWORD lp, y = HIWORD lp  }
	
	  |  0x00A5 =>  WM_NCRBUTTONUP { hitTest = wp, x = LOWORD lp, y = HIWORD lp  }
	
	  |  0x00A6 =>  WM_NCRBUTTONDBLCLK { hitTest = wp, x = LOWORD lp, y = HIWORD lp  }
	
	  |  0x00A7 =>  WM_NCMBUTTONDOWN { hitTest = wp, x = LOWORD lp, y = HIWORD lp  }
	
	  |  0x00A8 =>  WM_NCMBUTTONUP { hitTest = wp, x = LOWORD lp, y = HIWORD lp  }
	
	  |  0x00A9 =>  WM_NCMBUTTONDBLCLK { hitTest = wp, x = LOWORD lp, y = HIWORD lp  }

(* Edit control messages *)
	  |  0x00B0 =>  EM_GETSEL { startPos = ref(fromCint(deref(toClong wp))),
	  						    endPos = ref(fromCint(deref(toClong lp))) }

	  |  0x00B1 =>  EM_SETSEL { startPos = wp, endPos = lp }

	  |  0x00B2 =>  EM_GETRECT { rect = ref(fromCrect(deref(toClong lp))) }

	  |  0x00B3 =>  EM_SETRECT { rect = fromCrect(deref(toClong lp)) }

	  |  0x00B4 =>  EM_SETRECTNP { rect = fromCrect(deref(toClong lp)) }

	  |  0x00B5 =>  EM_SCROLL{action = fromCsd(toCint wp)}

	  |  0x00B6 =>  EM_LINESCROLL{xScroll = wp, yScroll = lp}

	  |  0x00B7 =>  EM_SCROLLCARET

	  |  0x00B8 =>  EM_GETMODIFY

	  |  0x00B9 =>  EM_SETMODIFY{modified = itob wp}

	  |  0x00BA =>  EM_GETLINECOUNT

	  |  0x00BB =>  EM_LINEINDEX {line = wp}
(*
EM_SETHANDLE            0x00BC
*)
	  |  0x00BE =>  EM_GETTHUMB

	  |  0x00C1 =>  EM_LINELENGTH {index = wp}

	  |  0x00C2 =>  EM_REPLACESEL {canUndo = itob wp, text = fromCstring(toClong lp)}

	  		(* All we know at this stage is the number of characters. *)
	  |  0x00C4 =>
				EM_GETLINE { lineNo = wp, size = fromCint(deref(toClong lp)), result = ref "" }

	  |  0x00C5 =>  EM_LIMITTEXT {limit = wp}

	  |  0x00C6 =>  EM_CANUNDO

	  |  0x00C7 =>  EM_UNDO

	  |  0x00C8 =>  EM_FMTLINES{addEOL = itob wp}

	  |  0x00C9 =>  EM_LINEFROMCHAR{index = wp}

	  |  0x00CB =>
	  		let
				val v = deref(toClong lp)
				fun getTab i = fromCint(offset i Cint v)
			in
	  			EM_SETTABSTOPS{tabs=List.tabulate(wp, getTab)}
			end

	  |  0x00CC =>  EM_SETPASSWORDCHAR{ch = chr wp}

	  |  0x00CD =>  EM_EMPTYUNDOBUFFER

	  |  0x00CE =>  EM_GETFIRSTVISIBLELINE

	  |  0x00CF =>  EM_SETREADONLY{readOnly = itob wp}
(*
EM_SETWORDBREAKPROC     0x00D0
EM_GETWORDBREAKPROC     0x00D1
*)
	  |  0x00D2 =>	EM_GETPASSWORDCHAR

	  |  0x00D3 =>
	  		if wp = 0xffff then EM_SETMARGINS{margins=UseFontInfo}
			else
			let
				val left =
					if IntInf.andb(wp, 1) <> 0
					then SOME(LOWORD lp)
					else NONE
				val right =
					if IntInf.andb(wp, 2) <> 0
					then SOME(HIWORD lp)
					else NONE
			in
				EM_SETMARGINS{margins=Margins{left=left, right=right}}
			end

	  |  0x00D4 =>  EM_GETMARGINS

	  |  0x00D5 =>  EM_GETLIMITTEXT

	  |  0x00D6 =>  EM_POSFROMCHAR {index = wp}

	  |  0x00D7 =>
	  		let
				val pt = fromCint (deref (toClong lp))
			in
				EM_CHARFROMPOS { point = {x = LOWORD pt, y = HIWORD pt} }
			end

(* Scroll bar messages *)

	  |  0x00E0 =>  SBM_SETPOS {pos = wp, redraw = itob lp}

	  |  0x00E1 =>  SBM_GETPOS

	  |  0x00E2 =>  SBM_SETRANGE {minPos = wp, maxPos = lp}

	  |  0x00E6 =>  SBM_SETRANGEREDRAW {minPos = wp, maxPos = lp}

	  |  0x00E3 =>  SBM_GETRANGE { minPos = ref(fromCint(deref(toClong wp))),
	  						       maxPos = ref(fromCint(deref(toClong lp))) }

	  |  0x00E4 =>  SBM_ENABLE_ARROWS(fromCesbf(toCint wp))

	  |  0x00E9 =>
	  		let
				val (info, options) = fromCscrollinfo(deref(toCint lp))
			in
				SBM_SETSCROLLINFO{ info = info, options = options }
			end

	 |	0x00EA =>
	  		let
				(* The values may not be correct at this point but the mask
				   should have been set. *)
				val (info, options) = fromCscrollinfo(deref(toCint lp))
			in
				SBM_GETSCROLLINFO{ info = ref info, options = options }
			end


(* Button control messages *)
	  |  0x00F0 =>  BM_GETCHECK

	  |  0x00F1 =>  BM_SETCHECK{state = wp}

	  |  0x00F2 =>  BM_GETSTATE

	  |  0x00F3 =>  BM_SETSTATE{highlight = wp <> 0}

	  |  0x00F4 =>  BM_SETSTYLE{redraw = lp <> 0, style = Style.fromWord(LargeWord.fromInt wp)}

	  |  0x00F5 =>  BM_CLICK

	  |  0x00F6 =>  BM_GETIMAGE{imageType = fromCit(toCint wp)}

	  |  0x00F7 =>  BM_SETIMAGE{imageType = fromCit(toCint wp), image = intAsHgdi lp}
	
	  |  0x0100 =>  WM_KEYDOWN { virtualKey = wp, data = lp  }
	
	  |  0x0101 =>  WM_KEYUP { virtualKey = wp, data = lp  }
	
	  |  0x0102 =>  WM_CHAR { charCode = chr wp, data = lp  }
	
	  |  0x0103 =>  WM_DEADCHAR { charCode = chr wp, data  = lp   }
	
	  |  0x0104 =>  WM_SYSKEYDOWN { virtualKey = wp, data = lp  }
	
	  |  0x0105 =>  WM_SYSKEYUP { virtualKey = wp, data = lp  }
	
	  |  0x0106 =>  WM_SYSCHAR { charCode = chr wp, data = lp  }
	
	  |  0x0107 =>  WM_SYSDEADCHAR { charCode = chr wp, data = lp  }
(*
WM_IME_STARTCOMPOSITION         0x010D
WM_IME_ENDCOMPOSITION           0x010E
WM_IME_COMPOSITION              0x010F
WM_IME_KEYLAST                  0x010F
*)
	
	  |  0x0110 =>  WM_INITDIALOG { dialog   = toHWND (toClong wp), initdata = lp } (* "0x0110" *)
	
	  |  0x0111 =>  WM_COMMAND { notifyCode = (HIWORD wp), wId = LOWORD wp, control = toHWND (toClong lp)  }
	
	  |  0x0112 =>  WM_SYSCOMMAND
	  		{ commandvalue = fromCsysc(toCint(IntInf.andb(wp, 0xFFF0))), p = {x= LOWORD lp,y= HIWORD lp} }
	
	  |  0x0113 =>  WM_TIMER  { timerid = wp  } (* "0x0113" *)
	
	  |  0x0114 =>  WM_HSCROLL { value = fromCsd(toCint(LOWORD wp)),
	  						  position = HIWORD wp, scrollbar = toHWND (toClong lp) } (* "0x0114" *)
	
	  |  0x0115 =>  WM_VSCROLL { value = fromCsd(toCint(LOWORD wp)), position  = HIWORD wp,
	                          scrollbar = toHWND (toClong lp) } (* "0x0115" *)
	
	  |  0x0116 =>  WM_INITMENU { menu = toHMENU (toClong wp) } (* "0x0116" *)
	
	  |  0x0117 =>  WM_INITMENUPOPUP { menupopup  = toHMENU (toClong wp),
	                                itemposition = LOWORD lp, isSystemMenu = itob (HIWORD lp) } (* "0x0117" *)
	
	  |  0x011F =>  WM_MENUSELECT { menuitem  = LOWORD wp,
	  								menuflags = MenuBase.toMenuFlagSet(IntInf.andb(HIWORD wp, 65535)),
								    menu= toHMENU (toClong lp) } (* "0x011F" *)
	
	  |  0x0120 =>  WM_MENUCHAR { ch = chr (LOWORD wp),
	  							  menuflag = MenuBase.toMenuFlag(IntInf.andb(HIWORD wp, 65535)),
								  menu= toHMENU (toClong lp)  } (* "0x0120" *)
	
	  |  0x0121 =>  WM_ENTERIDLE { flag = wp, window = toHWND (toClong lp) } (* "0x0121" *)
	
	  |  0x0132 =>  WM_CTLCOLORMSGBOX { displaycontext = toHDC (toClong wp),
	                                 messagebox     = toHWND (toClong lp)  } (* "0x0132" *)
	
	  |  0x0133 =>  WM_CTLCOLOREDIT { displaycontext = toHDC (toClong wp),
	                               editcontrol    = toHWND (toClong lp)  } (* "0x0133" *)
	
	  |  0x0134 =>  WM_CTLCOLORLISTBOX { displaycontext = toHDC (toClong wp),
	                                  listbox        = toHWND (toClong lp)   } (* "0x0134" *)
	
	  |  0x0135 =>  WM_CTLCOLORBTN { displaycontext = toHDC (toClong wp),
								  button = toHWND (toClong lp)  }(* "0x0135" *)
	
	  |  0x0136 =>  WM_CTLCOLORDLG { displaycontext = toHDC (toClong wp),
	                              dialogbox      = toHWND (toClong lp)  } (* "0x0136" *)
	
	  |  0x0137 =>  WM_CTLCOLORSCROLLBAR { displaycontext = toHDC (toClong wp),
	                                    scrollbar      = toHWND (toClong lp)  } (* "0x0137" *)
	
	  |  0x0138 =>  WM_CTLCOLORSTATIC { displaycontext = toHDC (toClong wp),
	                                 staticcontrol  = toHWND (toClong lp)  } (* "0x0138" *)
(* Combobox messages. *)
	  |  0x0140 =>	CB_GETEDITSEL { startPos = ref(fromCint(deref(toClong wp))),
	  						    endPos = ref(fromCint(deref(toClong lp))) }

	  |	 0x0141 =>	CB_LIMITTEXT {limit = wp}

	  |	 0x0142 =>	CB_SETEDITSEL { startPos = LOWORD lp, endPos = HIWORD lp }

	  |	 0x0143 =>	CB_ADDSTRING {text = fromCstring(toCint lp) }

	  |	 0x0144 =>	CB_DELETESTRING {index = wp}

	  |	 0x0145 =>	CB_DIR {attrs = fromCcbal (toCint wp), fileSpec = fromCstring(toCint lp) }

	  |	 0x0146 =>	CB_GETCOUNT

	  |	 0x0147 =>	CB_GETCURSEL

	  |  0x0148 =>  CB_GETLBTEXT { index = wp, length = ~1, text = ref ""  }

	  |	 0x0149 =>	CB_GETLBTEXTLEN {index = wp}

	  |	 0x014A =>	CB_INSERTSTRING {text = fromCstring(toCint lp), index = wp }

	  |	 0x014B =>	CB_RESETCONTENT

	  |	 0x014C =>	CB_FINDSTRING {text = fromCstring(toCint lp), indexStart = wp }

	  |	 0x014D =>	CB_SELECTSTRING {text = fromCstring(toCint lp), indexStart = wp }

	  |	 0x014E =>	CB_SETCURSEL {index = wp}

	  |	 0x014F =>	CB_SHOWDROPDOWN {show = itob wp}

	  |	 0x0150 =>	CB_GETITEMDATA {index = wp}

	  |	 0x0151 =>	CB_SETITEMDATA {index = wp, data = lp}

	  |	 0x0152 =>	CB_GETDROPPEDCONTROLRECT {rect = ref(fromCrect (deref (toClong lp))) }

	  |	 0x0153 =>	CB_SETITEMHEIGHT {index = wp, height = lp}

	  |	 0x0154 =>	CB_GETITEMHEIGHT {index = wp}

	  |	 0x0155 =>	CB_SETEXTENDEDUI {extended = itob wp}

	  |	 0x0156 =>	CB_GETEXTENDEDUI

	  |	 0x0157 =>	CB_GETDROPPEDSTATE

	  |	 0x0158 =>	CB_FINDSTRINGEXACT {text = fromCstring(toCint lp), indexStart = wp }

	  |	 0x0159 =>	CB_SETLOCALE {locale = wp}

	  |	 0x015A =>	CB_GETLOCALE

	  |	 0x015b =>	CB_GETTOPINDEX

	  |	 0x015c =>	CB_SETTOPINDEX {index = wp}

	  |	 0x015d =>	CB_GETHORIZONTALEXTENT

	  |	 0x015e =>	CB_SETHORIZONTALEXTENT {extent = wp}

	  |	 0x015f =>	CB_GETDROPPEDWIDTH

	  |	 0x0160 =>	CB_SETDROPPEDWIDTH {width = wp}

	  |	 0x0161 =>	CB_INITSTORAGE {items = wp, bytes = lp}


(* Static control messages. *)

	  |  0x0170 =>  STM_SETICON{icon = intAsHgdi wp}

	  |  0x0171 =>  STM_GETICON

	  |  0x0172 =>  STM_SETIMAGE{imageType = fromCit(toCint wp), image = intAsHgdi lp}

	  |  0x0173 =>  STM_GETIMAGE{imageType = fromCit(toCint wp)}

(* Listbox messages *)

	  |	 0x0180 =>	LB_ADDSTRING {text = fromCstring(toCint lp) }

	  |	 0x0181 =>	LB_INSERTSTRING {text = fromCstring(toCint lp), index = wp }

	  |	 0x0182 =>	LB_DELETESTRING {index = wp}

	  |	 0x0183 =>	LB_SELITEMRANGEEX {first = wp, last = lp}

	  |	 0x0184 =>	LB_RESETCONTENT

	  |	 0x0185 =>	LB_SETSEL {select = itob wp, index = lp}

	  |	 0x0186 =>	LB_SETCURSEL {index = wp}

	  |	 0x0187 =>	LB_GETSEL {index = wp}

	  |	 0x0188 =>	LB_GETCURSEL

	  |  0x0189 =>  LB_GETTEXT { index = wp, length = ~1, text = ref ""  }

	  |	 0x018A =>	LB_GETTEXTLEN {index = wp}

	  |	 0x018B =>	LB_GETCOUNT

	  |	 0x018C =>	LB_SELECTSTRING {text = fromCstring(toCint lp), indexStart = wp }

	  |	 0x018D =>	LB_DIR {attrs = fromCcbal (toCint wp), fileSpec = fromCstring(toCint lp) }

	  |	 0x018E =>	LB_GETTOPINDEX

	  |	 0x018F =>	LB_FINDSTRING {text = fromCstring(toCint lp), indexStart = wp }

	  |	 0x0190 =>	LB_GETSELCOUNT

	  |	 0x0191 =>	LB_GETSELITEMS { itemCount = wp, items = ref [] }

	  |  0x0192 =>
	  		let
				val v = deref(toClong lp)
				fun getTab i = fromCint(offset i Cint v)
			in
	  			LB_SETTABSTOPS{tabs=List.tabulate(wp, getTab)}
			end

	  |	 0x0193 =>	LB_GETHORIZONTALEXTENT

	  |	 0x0194 =>	LB_SETHORIZONTALEXTENT {extent = wp}

	  |	 0x0195 =>	LB_SETCOLUMNWIDTH {column = wp}

	  |	 0x0196 =>	LB_ADDFILE {fileName = fromCstring(toCint lp) }

	  |	 0x0197 =>	LB_SETTOPINDEX {index = wp}

	  |	 0x0198 =>	LB_GETITEMRECT {index = wp, rect = ref(fromCrect (deref (toClong lp))) }

	  |	 0x0199 =>	LB_GETITEMDATA {index = wp}

	  |	 0x019A =>	LB_SETITEMDATA {index = wp, data = lp}

	  |	 0x019B =>	LB_SELITEMRANGE {select = itob wp, first = LOWORD lp, last = HIWORD lp}

	  |	 0x019C =>	LB_SETANCHORINDEX {index = wp}

	  |	 0x019D =>	LB_GETANCHORINDEX

	  |	 0x019E =>	LB_SETCARETINDEX {index = wp, scroll = itob lp}

	  |	 0x019F =>	LB_GETCARETINDEX

	  |	 0x01A0 =>	LB_SETITEMHEIGHT {index = wp, height = LOWORD lp}

	  |	 0x01A1 =>	LB_GETITEMHEIGHT {index = wp}

	  |	 0x01A2 =>	LB_FINDSTRINGEXACT {text = fromCstring(toCint lp), indexStart = wp }

	  |	 0x01A5 =>	LB_SETLOCALE {locale = wp}

	  |	 0x01A6 =>	LB_GETLOCALE

	  |	 0x01A7 =>	LB_SETCOUNT {items = wp}

	  |	 0x01A8 =>	LB_INITSTORAGE {items = wp, bytes = lp}

	  |	 0x01A9 =>	LB_ITEMFROMPOINT {point = {x = LOWORD lp, y = HIWORD lp }}

	  |  0x0200 =>  WM_MOUSEMOVE { keyflags = fromCmkf(toCint wp), x = LOWORD lp, y = HIWORD lp  }
	
	  |  0x0201 =>  WM_LBUTTONDOWN { keyflags = fromCmkf(toCint wp), x = LOWORD lp, y = HIWORD lp  }
	
	  |  0x0202 =>  WM_LBUTTONUP { keyflags = fromCmkf(toCint wp), x = LOWORD lp, y = HIWORD lp  }
	
	  |  0x0203 =>  WM_LBUTTONDBLCLK { keyflags = fromCmkf(toCint wp), x = LOWORD lp, y = HIWORD lp  }
	
	  |  0x0204 =>  WM_RBUTTONDOWN { keyflags = fromCmkf(toCint wp), x = LOWORD lp, y = HIWORD lp  }
	
	  |  0x0205 =>  WM_RBUTTONUP { keyflags = fromCmkf(toCint wp), x = LOWORD lp, y = HIWORD lp  }
	
	  |  0x0206 =>  WM_RBUTTONDBLCLK { keyflags = fromCmkf(toCint wp), x = LOWORD lp, y = HIWORD lp  }
	
	  |  0x0207 =>  WM_MBUTTONDOWN { keyflags = fromCmkf(toCint wp), x = LOWORD lp, y = HIWORD lp  }
	
	  |  0x0208 =>  WM_MBUTTONUP { keyflags = fromCmkf(toCint wp), x = LOWORD lp, y = HIWORD lp  }
	
	  |  0x0209 =>  WM_MBUTTONDBLCLK { keyflags = fromCmkf(toCint wp), x = LOWORD lp, y = HIWORD lp  }
(*
WM_MOUSEWHEEL                   0x020A
*)
	
	  |  0x0210 =>  WM_PARENTNOTIFY { eventflag = LOWORD wp, idchild = HIWORD wp, value     = lp  }
	
	  |  0x0211 =>  WM_ENTERMENULOOP { istrack= itob wp } (* "0x0211" *)
	
	  |  0x0212 =>  WM_EXITMENULOOP { istrack= itob wp } (* "0x0212" *)
(*
WM_NEXTMENU                     0x0213
WM_SIZING                       0x0214
*)
	
	  |  0x0215 =>  WM_CAPTURECHANGED { newCapture = toHWND (toClong lp) }
(*
WM_MOVING                       0x0216
WM_POWERBROADCAST               0x0218
WM_DEVICECHANGE                 0x0219
*)
	  |  0x0220 =>
			let
              val (class,title,hinst, x,y,cx,cy, style,lParam) = 
				 fromCmdicreatestruct (deref (toClong lp))
			in
            	WM_MDICREATE { class = class,
                            title = title,
							instance = hinst,
                            x = x,
                            y = y,
                            cx = cx,
                            cy = cy,
                            style = style,
                            cdata = lParam                                        
                          }
            end
	
	  |  0x0221 =>  WM_MDIDESTROY  { child = toHWND (toClong wp) } (* "0x0221" *)
	
	  |  0x0223 =>  WM_MDIRESTORE { child = toHWND (toClong wp) } (* "0x0223" *)
	
	  |  0x0224 =>  WM_MDINEXT { child = toHWND (toClong wp), flagnext = itob lp  } (* "0x0224" *)
	
	  |  0x0225 =>  WM_MDIMAXIMIZE { child = toHWND (toClong wp) }  (* "0x0225" *)
	
	  |  0x0226 =>  WM_MDITILE { tilingflag = fromCmdif(toCint wp)  } (* "0x0226" *)
	
	  |  0x0227 =>  WM_MDICASCADE { skipDisabled = IntInf.andb(wp, 2) <> 0 }
	
	  |  0x0228 =>  WM_MDIICONARRANGE
	
	  |  0x0229 =>  WM_MDIGETACTIVE
	
	  |  0x0230 =>  WM_MDISETMENU { frameMenu  = toHMENU (toClong wp),
						         windowMenu = toHMENU (toClong lp) } (* "0x0230" *)

	  |  0x0231 =>  WM_ENTERSIZEMOVE

	  |  0x0232 =>  WM_EXITSIZEMOVE

	  |  0x0233 =>  WM_DROPFILES { hDrop = toHDROP (toClong wp) }
	
	  |  0x0234 =>  WM_MDIREFRESHMENU (* "0x0234" *)
(*
WM_IME_SETCONTEXT               0x0281
WM_IME_NOTIFY                   0x0282
WM_IME_CONTROL                  0x0283
WM_IME_COMPOSITIONFULL          0x0284
WM_IME_SELECT                   0x0285
WM_IME_CHAR                     0x0286
WM_IME_KEYDOWN                  0x0290
WM_IME_KEYUP                    0x0291
WM_MOUSEHOVER                   0x02A1
WM_MOUSELEAVE                   0x02A3
*)
	
	  |  0x0300 =>  WM_CUT (* "0x0300" *)
	
	  |  0x0301 =>  WM_COPY (* "0x0301" *)
	
	  |  0x0302 =>  WM_PASTE (* "0x0302" *)
	
	  |  0x0303 =>  WM_CLEAR (* "0x0303" *)
	
	  |  0x0304 =>  WM_UNDO (* "0x0304" *)
	
	  |  0x0305 =>  WM_RENDERFORMAT { format = fromCcbf (toClong wp)  } (* "0x0305" *)
	
	  |  0x0306 =>  WM_RENDERALLFORMATS (* "0x0306" *)
	
	  |  0x0307 =>  WM_DESTROYCLIPBOARD (* "0x0307" *)
	
	  |  0x0308 =>  WM_DRAWCLIPBOARD (* "0x0308" *)
	
	  |  0x0309 =>  WM_PAINTCLIPBOARD { clipboard = toHWND (toClong wp)  } (* "0x0309" *)
	
	  |  0x030A =>  WM_VSCROLLCLIPBOARD { viewer = toHWND (toClong wp),
	                                   code = LOWORD lp, position = HIWORD lp  } (* "0x030A" *)
	
	  |  0x030B =>  WM_SIZECLIPBOARD { viewer = toHWND (toClong lp)  } (* "0x030B" *)

			(* The format name is inserted by the window procedure so any
			   incoming message won't have the information.  Indeed the
			   buffer may not have been initialised. *)
	  |  0x030C =>  WM_ASKCBFORMATNAME { length = wp, formatName = ref ""  }
	
	  |  0x030D =>  WM_CHANGECBCHAIN { removed = toHWND (toClong wp), next = toHWND (toClong lp) }
	
	  |  0x030E =>  WM_HSCROLLCLIPBOARD { viewer   = toHWND (toClong wp),
	                                   code     = LOWORD lp, position = HIWORD lp  } (* "0x030E" *)

	  |  0x030F =>  WM_QUERYNEWPALETTE (* "0x030F" *)

	  |  0x0310 =>  WM_PALETTEISCHANGING { realize = toHWND (toClong wp) } (* "0x0310" *)

	  |  0x0311 =>  WM_PALETTECHANGED { palChg = toHWND (toClong wp) } (* "0x0311" *)

	  |  0x0312 =>  WM_HOTKEY { id = wp } (* "0x0312" *)

	  |  0x0317 =>  WM_PRINT { hdc = toHDC (toClong wp), flags = fromCwmpl(toCint lp) }

	  |  0x0318 =>  WM_PRINTCLIENT { hdc = toHDC (toClong wp), flags = fromCwmpl(toCint lp) }

	  |  i		=>
	  		(* User, application and registered messages. *)
			(* Rich edit controls use WM_USER+37 to WM_USER+122.  As and when we implement
			   rich edit controls we may want to treat those messages specially. *)
	  		if i >= 0x0400 andalso i <= 0x7FFF
			then WM_USER { uMsg = m, wParam = wp, lParam = lp }
			else if i >= 0x8000 andalso i <= 0xBFFF
			then WM_APP { uMsg = m, wParam = wp, lParam = lp }
			else if i >= 0x8000 andalso i <= 0xFFFF
			then
				(
				(* We could use PolyML.OnEntry to initialise the registered messages. *)
				if i = RegisterMessage "commdlg_FindReplace"
				then
				let
					(* The argument is really a FINDREPLACE struct. *)
					val flags = FindReplaceFlags.fromWord(LargeWord.fromInt(
									fromCuint(offset 3 Cuint (deref(toClong lp)))))
					val findwhat = fromCstring(offset 4 Cuint (deref(toClong lp)))
					val replace = fromCstring(offset 5 Cuint (deref(toClong lp)))
				in
					FINDMSGSTRING{flags=flags, findWhat=findwhat, replaceWith=replace}
				end
				else WM_REGISTERED { uMsg = m, wParam = wp, lParam = lp }
				)
			else (*NULL*) (* Generate USER messages at the moment so we know what they are. *)
				WM_USER { uMsg = m, wParam = wp, lParam = lp }


	(* Create a general message. *)
	fun createMessage (msgId: int, hwnd: HWND, wParam: vol, lParam: vol,
					   time: Time.time, pt: {x: int, y: int}): vol =
		CInterface.make_struct[
			(Cint, toCint msgId),
			(voidStar, fromHWND hwnd),
			(Cint, wParam),
			(Clong, lParam),
			(Clong, toCint(Time.toMilliseconds time)),
			(Cint, toCint (#x pt)),
			(Cint, toCint (#y pt))]

	fun btoi false = 0 | btoi true = 1

	fun compileMessage NULL = (0x0000, toCint 0, toCint 0)

	 | compileMessage (
	            WM_CREATE { instance, creation, menu, parent, cy, cx,
	                     y, x, style, name, class, extendedstyle}) =
			(0x0001, toCint 0, address(toCcreatestruct(creation, instance, menu, parent,
					cy, cx, y, x, Style.toWord style, name, class,
					extendedstyle)))

	  | compileMessage WM_DESTROY = (0x0002, toCint 0, toCint 0)

	  | compileMessage (WM_MOVE {x, y}) = (0x0003, toCint 0, toCint(MAKELONG(x, y)))

	  | compileMessage (WM_SIZE {flag, width, height}) =
	  		(0x0005, toCwmsf flag, toCint(MAKELONG(width, height)))

	  | compileMessage (WM_ACTIVATE {active, minimize}) =
	  		(0x0006, toCint(MAKELONG(fromWMactive active, btoi minimize)), toCint 0)

	  | compileMessage (WM_SETFOCUS {losing}) = (0x0007, toCint 0, fromHWND losing)

	  | compileMessage (WM_KILLFOCUS {receivefocus}) = (0x0008, toCint 0, fromHWND receivefocus)

	  | compileMessage (WM_ENABLE {enabled}) = (0x000A, toCint (btoi enabled), toCint 0)

	  | compileMessage (WM_SETREDRAW {redrawflag}) = (0x000B, toCint redrawflag, toCint 0)

	  | compileMessage (WM_SETTEXT {text}) = (0x000C, toCint 0, toCstring text)

	  | compileMessage (WM_GETTEXT {length, text}) =
	  		(* We have to allocate a buffer big enough to receive the text. *)
	  		(0x000D, toCint length, address(alloc(length+1) Cchar))

	  | compileMessage WM_GETTEXTLENGTH = (0x000E, toCint 0, toCint 0)

	  | compileMessage WM_PAINT = (0x000F, toCint 0, toCint 0)

	  | compileMessage WM_CLOSE = (0x0010, toCint 0, toCint 0)

	  | compileMessage (WM_QUERYENDSESSION { source}) = (0x0011, toCint source, toCint 0)

	  | compileMessage (WM_QUIT {exitcode}) = (0x0012, toCint exitcode, toCint 0)

	  | compileMessage WM_QUERYOPEN = (0x0013, toCint 0, toCint 0)

	  | compileMessage (WM_ERASEBKGND {devicecontext}) = (0x0014, toCint 0, fromHDC devicecontext)

	  | compileMessage WM_SYSCOLORCHANGE = (0x0015, toCint 0, toCint 0)

	  | compileMessage (WM_ENDSESSION {endsession}) = (0x0016, toCint(btoi endsession), toCint 0)

	  | compileMessage (WM_SHOWWINDOW {showflag, statusflag}) =
	  			(0x0018, toCint(btoi showflag), toCint statusflag)

	  | compileMessage (WM_SETTINGCHANGE {section_name}) = (0x001A, toCint 0, toCstring section_name)

	  | compileMessage (WM_DEVMODECHANGE {devicename}) = (0x001B, toCint 0, toCstring devicename)

	  | compileMessage (WM_ACTIVATEAPP {active, threadid}) =
	  			(0x001B, toCint(btoi active), toCint threadid)

	  | compileMessage WM_FONTCHANGE = (0x001D, toCint 0, toCint 0)

	  | compileMessage WM_TIMECHANGE = (0x001E, toCint 0, toCint 0)

	  | compileMessage WM_CANCELMODE = (0x001F, toCint 0, toCint 0)

	  | compileMessage (WM_SETCURSOR {cursorwindow, hitTest, mousemessage}) =
	  			(0x0020, fromHWND cursorwindow, toClong(MAKELONG(hitTest, mousemessage)))

	  | compileMessage (WM_MOUSEACTIVATE {parent, hitTest, message}) =
	  			(0x0021, fromHWND parent, toClong(MAKELONG(hitTest, message)))

	  | compileMessage WM_CHILDACTIVATE = (0x0022, toCint 0, toCint 0)

	  | compileMessage WM_QUEUESYNC = (0x0023, toCint 0, toCint 0)

	  | compileMessage (WM_GETMINMAXINFO{ MaxSizex, MaxSizey, MaxPositionx, MaxPositiony,
                             MinTrackSizex, MinTrackSizey, MaxTrackSizex, MaxTrackSizey}) =
			(0x0024, toCint 0, address(toCminmaxinfo(0,0,MaxSizex, MaxSizey, MaxPositionx, MaxPositiony,
                             MinTrackSizex, MinTrackSizey, MaxTrackSizex, MaxTrackSizey)))

	  | compileMessage WM_PAINTICON = (0x0026, toCint 0, toCint 0)

	  | compileMessage (WM_ICONERASEBKGND {devicecontext}) =
	  			(0x0027, fromHDC devicecontext, toCint 0)

	  | compileMessage (WM_NEXTDLGCTL {control, handleflag}) =
	  			(0x0028, toCint control, toCint(btoi handleflag))

	  | compileMessage (WM_SPOOLERSTATUS {jobstatus, jobsleft}) =
	  			(0x002A, toCint jobstatus, toCint jobsleft)

	  | compileMessage (WM_DRAWITEM{ controlid, ctlType, ctlID, itemID, itemAction,itemState,
	  							  hItem, hDC, rcItem, itemData}) =
			(0x002B, toCint controlid, address(toCdrawitemstruct(ctlType, ctlID, itemID, itemAction,itemState,
	  							  hItem, hDC,rcItem,itemData)))

	  | compileMessage (WM_MEASUREITEM{ controlid, ctlType, ctlID, itemID, itemWidth, itemHeight,
	  							     itemData}) =
			(0x002C, toCint controlid, address(toCmeasureitemstruct(ctlType, ctlID, itemID,
									 itemWidth, itemHeight,itemData)))

	  | compileMessage (WM_DELETEITEM{ controlid, ctlType, ctlID, itemID, item, itemData}) =
			(0x002D, toCint controlid, address(toCdeleteitemstruct(ctlType, ctlID, itemID,
									 item, itemData)))

	  | compileMessage (WM_VKEYTOITEM {virtualKey, caretpos, listbox}) =
			(0x002E, toCint(MAKELONG(virtualKey, caretpos)), fromHWND listbox)

	  | compileMessage (WM_CHARTOITEM {key, caretpos, listbox}) =
			(0x002F, toCint(MAKELONG(key, caretpos)), fromHWND listbox)

	  | compileMessage (WM_SETFONT {font, redrawflag}) =
			(0x0030, fromHFONT font, toCint(btoi redrawflag))

	  | compileMessage WM_GETFONT = (0x0031, toCint 0, toCint 0)

	  | compileMessage (WM_SETHOTKEY {virtualKey}) = (0x0032, toCint virtualKey, toCint 0)

	  | compileMessage WM_GETHOTKEY = (0x0033, toCint 0, toCint 0)

	  | compileMessage WM_QUERYDRAGICON = (0x0037, toCint 0, toCint 0)

	  | compileMessage (
	  			WM_COMPAREITEM{ controlid, ctlType, ctlID, hItem, itemID1,itemData1, itemID2,itemData2}) =
			(0x0039, toCint controlid, address(toCcompareitemstruct(ctlType, ctlID, hItem,
										itemID1, itemData1, itemID2,itemData2)))

	  | compileMessage (WM_COMPACTING { compactratio}) = (0x0041, toCint compactratio, toCint 0)

	  | compileMessage (WM_WINDOWPOSCHANGING{hwnd, front, x, y, width, height, flags}) =
			(0x0046, toCint 0, address(toCwindowpos(hwnd, front, x, y, width, height, flags)))

	  | compileMessage (WM_WINDOWPOSCHANGED{hwnd, front, x, y, width, height, flags}) =
			(0x0047, toCint 0, address(toCwindowpos(hwnd, front, x, y, width, height, flags)))

	  | compileMessage (WM_POWER {powerevent}) = (0x0048, toCint powerevent, toCint 0)

	  | compileMessage (WM_COPYDATA {sender, data, pdata}) =
	  		(0x004A, fromHWND sender,
				address(toCcopydata(data, Word8Vector.length pdata, fromWord8vec pdata)))

	  | compileMessage WM_CANCELJOURNAL = (0x004B, toCint 0, toCint 0)

	  | compileMessage (WM_NOTIFY {idCtrl, from, idFrom, code}) =
	  		(0x004E, toCint idCtrl, address(toCnmhdr(from, idFrom, code)))
(*
WM_INPUTLANGCHANGEREQUEST       0x0050
WM_INPUTLANGCHANGE              0x0051
WM_TCARD                        0x0052
WM_USERCHANGED                  0x0054
WM_NOTIFYFORMAT                 0x0055

WM_STYLECHANGING                0x007C
WM_STYLECHANGED                 0x007D
*)
	  | compileMessage (WM_HELP {ctrlId, itemHandle, contextId, mousePos}) =
	  		let
				val (ctype, handl) =
					case itemHandle of
						MenuHandle m => (2, intOfHandle m)
					|	WindowHandle w => (1, intOfHandle w)
			in
	  			(0x0053, toCint 0,
					address(toChelpinfo(sizeof helpStruct, ctype, ctrlId,
							handl, contextId, mousePos)))
			end

	  | compileMessage (WM_CONTEXTMENU { hwnd, xPos, yPos }) =
			(0x007B, fromHWND hwnd, toClong(MAKELONG(xPos, yPos)))

	  | compileMessage (WM_DISPLAYCHANGE { bitsPerPixel, xScreen, yScreen}) =
			(0x007E, toCint bitsPerPixel, toClong(MAKELONG(xScreen, yScreen)))

	  | compileMessage (WM_GETICON {big}) = (0x007F, toCint(btoi big), toClong 0)

	  | compileMessage (WM_SETICON { big, icon }) =
			(0x0080, toCint(btoi big), toClong(intOfHandle icon))

	  | compileMessage (
	            WM_NCCREATE { instance, creation, menu, parent, cy, cx,
	                       y, x, style, name, class, extendedstyle}) =
			(0x0081, toCint 0, address(toCcreatestruct(creation, instance, menu, parent,
					cy, cx, y, x, Style.toWord style, name, class,
					extendedstyle)))

	  | compileMessage WM_NCDESTROY = (0x0082, toCint 0, toCint 0)

	  | compileMessage (
	            WM_NCCALCSIZE {validarea, newrect, oldrect, oldclientarea,
							hwnd, insertAfter, x, y, cx, cy, style}) =
			if validarea
			then (0x0083, toCint 1, address(toCncalcsizestruct(newrect,oldrect,oldclientarea,
								(hwnd,insertAfter,x,y,cx,cy, style))))
			else (0x0083, toCint 0, address(toCrect newrect))

	  | compileMessage (WM_NCHITTEST {x, y}) =
	  		(0x0084, toCint 0, toClong(MAKELONG(x, y)))

	  | compileMessage (WM_NCPAINT {region}) = (0x0085, fromHRGN region, toCint 0)

	  | compileMessage (WM_NCACTIVATE {active}) = (0x0086, toCint(btoi active), toCint 0)

	  | compileMessage WM_GETDLGCODE = (0x0087, toCint 0, toCint 0)

	  | compileMessage (WM_NCMOUSEMOVE {hitTest, x, y}) =
	  			(0x00A0, toCint hitTest, toClong(MAKELONG(x, y)))

	  | compileMessage (WM_NCLBUTTONDOWN {hitTest, x, y}) =
	  			(0x00A1, toCint hitTest, toClong(MAKELONG(x, y)))

	  | compileMessage (WM_NCLBUTTONUP {hitTest, x, y}) =
	  			(0x00A2, toCint hitTest, toClong(MAKELONG(x, y)))

	  | compileMessage (WM_NCLBUTTONDBLCLK {hitTest, x, y}) =
	  			(0x00A3, toCint hitTest, toClong(MAKELONG(x, y)))

	  | compileMessage (WM_NCRBUTTONDOWN {hitTest, x, y}) =
	  			(0x00A4, toCint hitTest, toClong(MAKELONG(x, y)))

	  | compileMessage (WM_NCRBUTTONUP {hitTest, x, y}) =
	  			(0x00A5, toCint hitTest, toClong(MAKELONG(x, y)))

	  | compileMessage (WM_NCRBUTTONDBLCLK {hitTest, x, y}) =
	  			(0x00A6, toCint hitTest, toClong(MAKELONG(x, y)))

	  | compileMessage (WM_NCMBUTTONDOWN {hitTest, x, y}) =
	  			(0x00A7, toCint hitTest, toClong(MAKELONG(x, y)))

	  | compileMessage (WM_NCMBUTTONUP {hitTest, x, y}) =
	  			(0x00A8, toCint hitTest, toClong(MAKELONG(x, y)))

	  | compileMessage (WM_NCMBUTTONDBLCLK {hitTest, x, y}) =
	  			(0x00A9, toCint hitTest, toClong(MAKELONG(x, y)))

(* Edit control messages *)
	  | compileMessage (EM_GETSEL{startPos=ref s, endPos=ref e}) =
	  		(0x00B0, address(toCint s), address(toCint e))

	  | compileMessage (EM_SETSEL{startPos, endPos}) =
	  		(0x00B1, toCint startPos, toCint endPos)

	  | compileMessage (EM_GETRECT{rect=ref r}) = (0x00B2, toCint 0, address(toCrect r))

	  | compileMessage (EM_SETRECT{rect}) = (0x00B3, toCint 0, address(toCrect rect))

	  | compileMessage (EM_SETRECTNP{rect}) = (0x00B4, toCint 0, address(toCrect rect))

	  | compileMessage (EM_SCROLL{action}) = (0x00B5, toCsd action, toCint 0)

	  | compileMessage (EM_LINESCROLL{xScroll, yScroll}) =
	  		(0x00B6, toCint xScroll, toCint yScroll)

	  | compileMessage EM_SCROLLCARET = (0x00B7, toCint 0, toCint 0)

	  | compileMessage EM_GETMODIFY = (0x00B8, toCint 0, toCint 0)

	  | compileMessage (EM_SETMODIFY{modified}) = (0x00B9, toCint(btoi modified), toCint 0)

	  | compileMessage EM_GETLINECOUNT = (0x00BA, toCint 0, toCint 0)

	  | compileMessage (EM_LINEINDEX{line}) = (0x00BB, toCint line, toCint 0)
(*
EM_SETHANDLE            0x00BC
*)
	  | compileMessage EM_GETTHUMB = (0x00BE, toCint 0, toCint 0)

	  | compileMessage (EM_LINELENGTH{index}) = (0x00BB, toCint index, toCint 0)

	  | compileMessage (EM_REPLACESEL{canUndo, text}) =
	  			(0x00C2, toCint(btoi canUndo), toCstring text)

	  | compileMessage (EM_GETLINE {lineNo, size, result}) =
	  		(* We have to allocate a buffer big enough to receive the text and
			   set the first word to the length of the buffer. *)
			let
				val vec = alloc (Int.max(size+1, sizeof Cint)) Cchar
			in
				assign Cint vec (toCint(size+1));
	  			(0x00C5, toCint lineNo, address vec)
			end

	  | compileMessage (EM_LIMITTEXT{limit}) = (0x00C5, toCint limit, toCint 0)


	  | compileMessage EM_CANUNDO = (0x00C6, toCint 0, toCint 0)

	  | compileMessage EM_UNDO = (0x00C7, toCint 0, toCint 0)

	  | compileMessage (EM_FMTLINES{addEOL}) = (0x00C8, toCint(btoi addEOL), toCint 0)

	  | compileMessage (EM_LINEFROMCHAR{index}) = (0x00C9, toCint index, toCint 0)

	  | compileMessage (EM_SETTABSTOPS{tabs}) =
	  		let
				val cTabs = List.length tabs
				val vec = alloc cTabs Cint
				fun setVec(tab, i) = (assign Cint vec (toCint tab); i+1)
			in
				List.foldl setVec 0 tabs;
	  			(0x00CB, toCint cTabs, address vec)
			end

	  | compileMessage (EM_SETPASSWORDCHAR{ch}) = (0x00CC, toCchar ch, toCint 0)

	  | compileMessage EM_EMPTYUNDOBUFFER = (0x00CD, toCint 0, toCint 0)

	  | compileMessage EM_GETFIRSTVISIBLELINE = (0x00CE, toCint 0, toCint 0)

	  | compileMessage (EM_SETREADONLY{readOnly}) = (0x00CF, toCint(btoi readOnly), toCint 0)
(*
EM_SETWORDBREAKPROC     0x00D0
EM_GETWORDBREAKPROC     0x00D1
*)
	  | compileMessage EM_GETPASSWORDCHAR = (0x00D2, toCint 0, toCint 0)

	  | compileMessage (EM_SETMARGINS{margins}) =
	  		(
			case margins of
				UseFontInfo => (0x00D3, toCint 0xffff, toCint 0)
			|	Margins{left, right} =>
				let
					val (b0, lo) = case left of SOME l => (1, l) | NONE => (0, 0)
					val (b1, hi) = case right of SOME r => (2, r) | NONE => (0, 0)
				in
					(0x00D3, toCint (IntInf.orb(b0, b1)), toCint(MAKELONG(hi,lo)))
				end
			)
(*
#if(WINVER >= 0x0400)
EM_SETMARGINS           0x00D3
*)
	  | compileMessage EM_GETMARGINS = (0x00D4, toCint 0, toCint 0)

	  | compileMessage EM_GETLIMITTEXT = (0x00D5, toCint 0, toCint 0)

	  | compileMessage (EM_POSFROMCHAR {index}) = (0x00D6, toCint index, toCint 0)

	  | compileMessage (EM_CHARFROMPOS{point = {x,y}}) =
	  		let
				val v = alloc 1 Clong
			in
				assign Cint v (toCint(MAKELONG(x,y)));
				(0x00D7, toCint 0, address v)
			end

(* Scroll bar messages *)

	  | compileMessage (SBM_SETPOS {pos, redraw}) = (0x00E0, toCint pos, toCint(btoi redraw))

	  | compileMessage SBM_GETPOS = (0x00E1, toCint 0, toCint 0)

	  | compileMessage (SBM_SETRANGE {minPos, maxPos}) = (0x00E2, toCint minPos, toCint maxPos)

	  | compileMessage (SBM_SETRANGEREDRAW {minPos, maxPos}) = (0x00E6, toCint minPos, toCint maxPos)

	  | compileMessage (SBM_GETRANGE {minPos = ref min, maxPos = ref max}) =
	  		(0x00E3, address(toCint min), address(toCint max))

	  | compileMessage (SBM_ENABLE_ARROWS flags) = (0x00E4, toCesbf flags, toCint 0)

	  | compileMessage (SBM_SETSCROLLINFO {info, options}) =
	  		(0x00E9, toCint 0, address(toCscrollinfo(info, options)))

	  | compileMessage (SBM_GETSCROLLINFO {info = ref info, options}) =
	  		(0x00EA, toCint 0, address(toCscrollinfo(info, options)))


(* Button control messages *)

	  | compileMessage BM_GETCHECK = (0x00F0, toCint 0, toCint 0)

	  | compileMessage (BM_SETCHECK{state}) = (0x00F1, toCint state, toCint 0)

	  | compileMessage BM_GETSTATE = (0x00F2, toCint 0, toCint 0)

	  | compileMessage (BM_SETSTATE{highlight}) = (0x00F3, toCint(btoi highlight), toCint 0)

	  | compileMessage (BM_SETSTYLE{redraw, style})
	  		= (0x00F3, toCint(LargeWord.toInt(Style.toWord style)), toCint(btoi redraw))

	  | compileMessage BM_CLICK = (0x00F5, toCint 0, toCint 0)

	  | compileMessage (BM_GETIMAGE{imageType}) = (0x00F6, toCit imageType, toCint 0)

	  | compileMessage (BM_SETIMAGE{imageType, image}) =
	  			(0x00F7, toCit imageType, toCint(hgdiAsInt image))

	  | compileMessage (WM_KEYDOWN {virtualKey, data}) = (0x0100, toCint virtualKey, toCint data)

	  | compileMessage (WM_KEYUP {virtualKey, data}) = (0x0101, toCint virtualKey, toCint data)

	  | compileMessage (WM_CHAR {charCode, data}) = (0x0102, toCchar charCode, toCint data)

	  | compileMessage (WM_DEADCHAR {charCode, data}) = (0x0103, toCchar charCode, toCint data)

	  | compileMessage (WM_SYSKEYDOWN {virtualKey, data}) = (0x0104, toCint virtualKey, toCint data)

	  | compileMessage (WM_SYSKEYUP {virtualKey, data}) = (0x0105, toCint virtualKey, toCint data)

	  | compileMessage (WM_SYSCHAR {charCode, data}) = (0x0106, toCchar charCode, toCint data)

	  | compileMessage (WM_SYSDEADCHAR {charCode, data}) = (0x0107, toCchar charCode, toCint data)
(*
WM_IME_STARTCOMPOSITION         0x010D
WM_IME_ENDCOMPOSITION           0x010E
WM_IME_COMPOSITION              0x010F
WM_IME_KEYLAST                  0x010F

*)

	  | compileMessage (WM_INITDIALOG { dialog, initdata}) =
	  		(0x0110, fromHWND dialog, toCint initdata)

	  | compileMessage (WM_COMMAND {notifyCode, wId, control}) =
	  		(0x0111, toCint(MAKELONG(wId, notifyCode)), fromHWND control)

	  | compileMessage (WM_SYSCOMMAND {commandvalue, p={x,y}}) =
	  		(0x0112, toCsysc commandvalue, toClong(MAKELONG(x,y)))

	  | compileMessage (WM_TIMER {timerid}) = (0x0113, toCint timerid, toCint 0)

	  | compileMessage (WM_HSCROLL {value, position, scrollbar}) =
	  		(0x0114, toCint(MAKELONG(fromCint(toCsd value), position)), fromHWND scrollbar)

	  | compileMessage (WM_VSCROLL {value, position, scrollbar}) =
	  		(0x0115, toCint(MAKELONG(fromCint(toCsd value), position)), fromHWND scrollbar)

	  | compileMessage (WM_INITMENU {menu}) =
	  		(0x0116, fromHMENU menu, toCint 0)

	  | compileMessage (WM_INITMENUPOPUP {menupopup, itemposition, isSystemMenu}) =
	  		(0x0117, fromHMENU menupopup,
				toCint(MAKELONG(itemposition, btoi isSystemMenu)))

	  | compileMessage (WM_MENUSELECT {menuitem, menuflags, menu}) =
	  		(0x011F, toCint(MAKELONG(menuitem, MenuBase.fromMenuFlagSet menuflags)),
					fromHMENU menu)

	  | compileMessage (WM_MENUCHAR { ch, menuflag, menu}) =
	  		(0x0120, toCint(MAKELONG(ord ch, MenuBase.fromMenuFlag menuflag)), fromHMENU menu)

	  | compileMessage (WM_ENTERIDLE { flag, window}) = (0x0121, toCint flag, fromHWND window)

	  | compileMessage (WM_CTLCOLORMSGBOX { displaycontext, messagebox}) =
	  		(0x0132, fromHDC displaycontext, fromHWND messagebox)

	  | compileMessage (WM_CTLCOLOREDIT { displaycontext, editcontrol}) =
	  		(0x0133, fromHDC displaycontext, fromHWND editcontrol)

	  | compileMessage (WM_CTLCOLORLISTBOX { displaycontext, listbox}) =
	  		(0x0134, fromHDC displaycontext, fromHWND listbox)

	  | compileMessage (WM_CTLCOLORBTN { displaycontext, button}) =
	  		(0x0135, fromHDC displaycontext, fromHWND button)

	  | compileMessage (WM_CTLCOLORDLG { displaycontext, dialogbox}) =
	  		(0x0136, fromHDC displaycontext, fromHWND dialogbox)

	  | compileMessage (WM_CTLCOLORSCROLLBAR { displaycontext, scrollbar}) =
	  		(0x0137, fromHDC displaycontext, fromHWND scrollbar)

	  | compileMessage (WM_CTLCOLORSTATIC { displaycontext, staticcontrol}) =
	  		(0x0138, fromHDC displaycontext, fromHWND staticcontrol)

(* Combobox messages. *)
	  | compileMessage (CB_GETEDITSEL{startPos=ref s, endPos=ref e}) =
	  		(0x0140, address(toCint s), address(toCint e))

	  | compileMessage (CB_LIMITTEXT{limit}) = (0x0141, toCint limit, toCint 0)

	  | compileMessage (CB_SETEDITSEL{startPos, endPos}) =
	  		(0x0142, toCint 0, toClong(MAKELONG(startPos, endPos)))

	  | compileMessage (CB_ADDSTRING{text}) = (0x0143, toCint 0, toCstring text)

	  | compileMessage (CB_DELETESTRING{index}) = (0x0144, toCint index, toCint 0)

	  | compileMessage (CB_DIR{attrs, fileSpec}) = (0x0145, toCcbal attrs, toCstring fileSpec)

	  | compileMessage CB_GETCOUNT = (0x0146, toCint 0, toCint 0)

	  | compileMessage CB_GETCURSEL = (0x0147, toCint 0, toCint 0)

	  | compileMessage (CB_GETLBTEXT {length, index, text}) =
	  		(* This is messy.  There's no actual argument that passes the size of
			   the buffer so we have to add an extra argument to the ML message
			   to pass it. *)
	  		(0x0148, toCint index, address(alloc(length+1) Cchar))

	  | compileMessage (CB_GETLBTEXTLEN{index}) = (0x0149, toCint index, toCint 0)

	  | compileMessage (CB_INSERTSTRING{text, index}) = (0x014A, toCint index, toCstring text)

	  | compileMessage CB_RESETCONTENT = (0x014B, toCint 0, toCint 0)

	  | compileMessage (CB_FINDSTRING{text, indexStart}) =
	  		(0x014C, toCint indexStart, toCstring text)

	  | compileMessage (CB_SELECTSTRING{text, indexStart}) =
	  		(0x014D, toCint indexStart, toCstring text)

	  | compileMessage (CB_SETCURSEL{index}) = (0x014E, toCint index, toCint 0)

	  | compileMessage (CB_SHOWDROPDOWN{show}) = (0x014F, toCint(btoi show), toCint 0)

	  | compileMessage (CB_GETITEMDATA{index}) = (0x0150, toCint index, toCint 0)

	  | compileMessage (CB_SETITEMDATA{index, data}) = (0x0151, toCint index, toCint data)

	  | compileMessage (CB_GETDROPPEDCONTROLRECT{rect = ref r}) =
	  		(0x0152, toCint 0, address(toCrect r))

	  | compileMessage (CB_SETITEMHEIGHT{index, height}) = (0x0153, toCint index, toCint height)

	  | compileMessage (CB_GETITEMHEIGHT{index}) = (0x0154, toCint index, toCint 0)

	  | compileMessage (CB_SETEXTENDEDUI{extended}) = (0x0155, toCint(btoi extended), toCint 0)

	  | compileMessage CB_GETEXTENDEDUI = (0x0156, toCint 0, toCint 0)

	  | compileMessage CB_GETDROPPEDSTATE = (0x0157, toCint 0, toCint 0)

	  | compileMessage (CB_FINDSTRINGEXACT{text, indexStart}) =
	  		(0x0158, toCint indexStart, toCstring text)

	  | compileMessage (CB_SETLOCALE{locale}) = (0x0159, toCint locale, toCint 0)

	  | compileMessage CB_GETLOCALE = (0x015A, toCint 0, toCint 0)

	  | compileMessage CB_GETTOPINDEX = (0x015b, toCint 0, toCint 0)

	  | compileMessage (CB_SETTOPINDEX{index}) = (0x015c, toCint index, toCint 0)

	  | compileMessage CB_GETHORIZONTALEXTENT = (0x015d, toCint 0, toCint 0)

	  | compileMessage (CB_SETHORIZONTALEXTENT{extent}) = (0x015e, toCint extent, toCint 0)

	  | compileMessage CB_GETDROPPEDWIDTH = (0x015f, toCint 0, toCint 0)

	  | compileMessage (CB_SETDROPPEDWIDTH{width}) = (0x0160, toCint width, toCint 0)

	  | compileMessage (CB_INITSTORAGE{items, bytes}) = (0x0161, toCint items, toCint bytes)


(* Static control messages. *)

	  | compileMessage (STM_SETICON{icon}) = (0x0170, toCint(hgdiAsInt icon), toCint 0)

	  | compileMessage STM_GETICON = (0x0171, toCint 0, toCint 0)

	  | compileMessage (STM_SETIMAGE{imageType, image}) =
	  			(0x0172, toCit imageType, toCint(hgdiAsInt image))

	  | compileMessage (STM_GETIMAGE{imageType}) = (0x0173, toCit imageType, toCint 0)

(* Listbox messages *)

	  | compileMessage (LB_ADDSTRING{text}) = (0x0180, toCint 0, toCstring text)

	  | compileMessage (LB_INSERTSTRING{text, index}) = (0x0181, toCint index, toCstring text)

	  | compileMessage (LB_DELETESTRING{index}) = (0x0182, toCint index, toCint 0)

	  | compileMessage (LB_SELITEMRANGEEX{first, last}) = (0x0183, toCint first, toCint last)

	  | compileMessage LB_RESETCONTENT = (0x0184, toCint 0, toCint 0)

	  | compileMessage (LB_SETSEL{select, index}) = (0x0185, toCint(btoi select), toCint index)

	  | compileMessage (LB_SETCURSEL{index}) = (0x0186, toCint index, toCint 0)

	  | compileMessage (LB_GETSEL{index}) = (0x0187, toCint index, toCint 0)

	  | compileMessage LB_GETCURSEL = (0x0188, toCint 0, toCint 0)

	  | compileMessage (LB_GETTEXT {length, index, text}) =
	  		(* This is messy.  There's no actual argument that passes the size of
			   the buffer so we have to add an extra argument to the ML message
			   to pass it. *)
	  		(0x0189, toCint index, address(alloc (length+1) Cchar))

	  | compileMessage (LB_GETTEXTLEN{index}) = (0x018A, toCint index, toCint 0)

	  | compileMessage LB_GETCOUNT = (0x018B, toCint 0, toCint 0)

	  | compileMessage (LB_SELECTSTRING{text, indexStart}) =
	  		(0x018C, toCint indexStart, toCstring text)

	  | compileMessage (LB_DIR{attrs, fileSpec}) = (0x018D, toCcbal attrs, toCstring fileSpec)

	  | compileMessage LB_GETTOPINDEX = (0x018E, toCint 0, toCint 0)

	  | compileMessage (LB_FINDSTRING{text, indexStart}) =
	  		(0x018F, toCint indexStart, toCstring text)

	  | compileMessage LB_GETSELCOUNT = (0x0190, toCint 0, toCint 0)

	  | compileMessage (LB_GETSELITEMS{itemCount, ...}) =
	  		(* Allocate a buffer to receive the items.  Set each element of the buffer
			   to ~1 so that the values are defined if not all of them are set. *)
		let
			val v = alloc itemCount Cint
			fun fill a 0 = ()
			 |  fill a n = (assign Cint a (toCint ~1); fill (offset 1 Cint a) (n-1))
		in
			fill v itemCount;
	  		(0x0191, toCint itemCount, address v)
		end

	  | compileMessage (LB_SETTABSTOPS{tabs}) =
	  		let
				val cTabs = List.length tabs
				val vec = alloc cTabs Cint
				fun setVec(tab, i) = (assign Cint vec (toCint tab); i+1)
			in
				List.foldl setVec 0 tabs;
	  			(0x0192, toCint cTabs, address vec)
			end

	  | compileMessage LB_GETHORIZONTALEXTENT = (0x0193, toCint 0, toCint 0)

	  | compileMessage (LB_SETHORIZONTALEXTENT{extent}) = (0x0194, toCint extent, toCint 0)

	  | compileMessage (LB_SETCOLUMNWIDTH{column}) = (0x0195, toCint column, toCint 0)

	  | compileMessage (LB_ADDFILE{fileName}) = (0x0196, toCint 0, toCstring fileName)

	  | compileMessage (LB_SETTOPINDEX{index}) = (0x0197, toCint index, toCint 0)

	  | compileMessage (LB_GETITEMRECT{rect = ref r, index}) =
	  		(0x0198, toCint index, address(toCrect r))

	  | compileMessage (LB_GETITEMDATA{index}) = (0x0199, toCint index, toCint 0)

	  | compileMessage (LB_SETITEMDATA{index, data}) = (0x019A, toCint index, toCint data)

	  | compileMessage (LB_SELITEMRANGE{select, first, last}) =
	  		(0x019B, toCint(btoi select), toClong(MAKELONG(first, last)))

	  | compileMessage (LB_SETANCHORINDEX{index}) = (0x019C, toCint index, toCint 0)

	  | compileMessage LB_GETANCHORINDEX = (0x019D, toCint 0, toCint 0)

	  | compileMessage (LB_SETCARETINDEX{index, scroll}) = (0x019E, toCint index, toCint(btoi scroll))

	  | compileMessage LB_GETCARETINDEX = (0x019F, toCint 0, toCint 0)

	  | compileMessage (LB_SETITEMHEIGHT{index, height}) =
	  			(0x01A0, toCint index, toCint(MAKELONG(height, 0)))

	  | compileMessage (LB_GETITEMHEIGHT{index}) = (0x01A1, toCint index, toCint 0)

	  | compileMessage (LB_FINDSTRINGEXACT{text, indexStart}) =
	  		(0x01A2, toCint indexStart, toCstring text)

	  | compileMessage (LB_SETLOCALE{locale}) = (0x01A5, toCint locale, toCint 0)

	  | compileMessage LB_GETLOCALE = (0x01A6, toCint 0, toCint 0)

	  | compileMessage (LB_SETCOUNT{items}) = (0x01A7, toCint items, toCint 0)

	  | compileMessage (LB_INITSTORAGE{items, bytes}) = (0x01A8, toCint items, toCint bytes)

	  | compileMessage (LB_ITEMFROMPOINT { point = {x, y}}) =
	  		(0x01A9, toCint 0, toCint(MAKELONG(x,y)))

	  | compileMessage (WM_MOUSEMOVE { keyflags, x, y}) =
	  		(0x0200, toCmkf keyflags, toCint(MAKELONG(x,y)))

	  | compileMessage (WM_LBUTTONDOWN { keyflags, x, y}) =
	  		(0x0201, toCmkf keyflags, toCint(MAKELONG(x,y)))

	  | compileMessage (WM_LBUTTONUP { keyflags, x, y}) =
	  		(0x02022, toCmkf keyflags, toCint(MAKELONG(x,y)))

	  | compileMessage (WM_LBUTTONDBLCLK { keyflags, x, y}) =
	  		(0x0203, toCmkf keyflags, toCint(MAKELONG(x,y)))

	  | compileMessage (WM_RBUTTONDOWN { keyflags, x, y}) =
	  		(0x0204, toCmkf keyflags, toCint(MAKELONG(x,y)))

	  | compileMessage (WM_RBUTTONUP { keyflags, x, y}) =
	  		(0x02025, toCmkf keyflags, toCint(MAKELONG(x,y)))

	  | compileMessage (WM_RBUTTONDBLCLK { keyflags, x, y}) =
	  		(0x0206, toCmkf keyflags, toCint(MAKELONG(x,y)))

	  | compileMessage (WM_MBUTTONDOWN { keyflags, x, y}) =
	  		(0x0207, toCmkf keyflags, toCint(MAKELONG(x,y)))

	  | compileMessage (WM_MBUTTONUP { keyflags, x, y}) =
	  		(0x02028, toCmkf keyflags, toCint(MAKELONG(x,y)))

	  | compileMessage (WM_MBUTTONDBLCLK { keyflags, x, y}) =
	  		(0x0209, toCmkf keyflags, toCint(MAKELONG(x,y)))
(*
WM_MOUSEWHEEL                   0x020A
*)

	  | compileMessage (WM_PARENTNOTIFY { eventflag, idchild, value}) =
	  		(0x0210, toCint(MAKELONG(eventflag,idchild)), toCint value)

	  | compileMessage (WM_ENTERMENULOOP {istrack}) = (0x0211, toCint(btoi istrack), toCint 0)

	  | compileMessage (WM_EXITMENULOOP {istrack}) = (0x0212, toCint(btoi istrack), toCint 0)

(*
WM_NEXTMENU                     0x0213
WM_SIZING                       0x0214
*)

	  | compileMessage (WM_CAPTURECHANGED {newCapture}) = (0x0215, toCint 0, fromHWND newCapture)
(*
WM_MOVING                       0x0216
WM_POWERBROADCAST               0x0218
WM_DEVICECHANGE                 0x0219
*)

	  | compileMessage (WM_MDICREATE{class, title, instance, x, y, cx, cy, style, cdata}) =
	  		(0x0220, toCint 0,
				address(toCmdicreatestruct(class,title,instance,x,y,cx,cy,style,cdata)))

	  | compileMessage (WM_MDIDESTROY{child}) =
	  		(0x0221, fromHWND child, toCint 0)

	  | compileMessage (WM_MDIRESTORE{child}) =
	  		(0x0223, fromHWND child, toCint 0)

	  | compileMessage (WM_MDINEXT{child, flagnext}) =
	  		(0x0224, fromHWND child, toCint(btoi flagnext))

	  | compileMessage (WM_MDIMAXIMIZE{child}) =
	  		(0x0225, fromHWND child, toCint 0)

	  | compileMessage (WM_MDITILE{tilingflag}) = (0x0226, toCmdif tilingflag, toCint 0)

	  | compileMessage (WM_MDICASCADE{skipDisabled}) =
	  		(0x0227, toCint(if skipDisabled then 2 else 0), toCint 0)

	  | compileMessage WM_MDIICONARRANGE = (0x0228, toCint 0, toCint 0)

	  | compileMessage WM_MDIGETACTIVE = (0x0229, toCint 0, toCint 0 (* MUST be null *))

	  | compileMessage (WM_MDISETMENU{frameMenu, windowMenu}) =
	  		(0x0230, fromHMENU frameMenu, fromHMENU windowMenu)

	  | compileMessage WM_ENTERSIZEMOVE = (0x0231, toCint 0, toCint 0)

	  | compileMessage WM_EXITSIZEMOVE = (0x0232, toCint 0, toCint 0)

	  | compileMessage (WM_DROPFILES{hDrop}) = (0x0233, fromHDROP hDrop, toCint 0)

	  | compileMessage WM_MDIREFRESHMENU = (0x0234, toCint 0, toCint 0)
(*
WM_IME_SETCONTEXT               0x0281
WM_IME_NOTIFY                   0x0282
WM_IME_CONTROL                  0x0283
WM_IME_COMPOSITIONFULL          0x0284
WM_IME_SELECT                   0x0285
WM_IME_CHAR                     0x0286
WM_IME_KEYDOWN                  0x0290
WM_IME_KEYUP                    0x0291
WM_MOUSEHOVER                   0x02A1
WM_MOUSELEAVE                   0x02A3
*)
	  | compileMessage WM_CUT = (0x0300, toCint 0, toCint 0)

	  | compileMessage WM_COPY = (0x0301, toCint 0, toCint 0)

	  | compileMessage WM_PASTE = (0x0302, toCint 0, toCint 0)

	  | compileMessage WM_CLEAR = (0x0303, toCint 0, toCint 0)

	  | compileMessage WM_UNDO = (0x0304, toCint 0, toCint 0)

	  | compileMessage (WM_RENDERFORMAT {format}) = (0x0305, toCcbf format, toCint 0)

	  | compileMessage WM_RENDERALLFORMATS = (0x0306, toCint 0, toCint 0)

	  | compileMessage WM_DESTROYCLIPBOARD = (0x0307, toCint 0, toCint 0)

	  | compileMessage WM_DRAWCLIPBOARD = (0x0308, toCint 0, toCint 0)

	  | compileMessage (WM_PAINTCLIPBOARD{clipboard}) =
	  		(0x030A, fromHWND clipboard, toCint 0)

	  | compileMessage (WM_VSCROLLCLIPBOARD{viewer, code, position}) =
	  		(0x030A, fromHWND viewer, toCint(MAKELONG(code, position)))

	  | compileMessage (WM_SIZECLIPBOARD{viewer}) = (0x030B, toCint 0, fromHWND viewer)

	  | compileMessage (WM_ASKCBFORMATNAME {length, formatName}) =
	  		(* We have to allocate a buffer big enough to receive the text. *)
	  		(0x030C, toCint length, address(alloc(length+1) Cchar))

	  | compileMessage (WM_CHANGECBCHAIN{removed, next}) =
	  		(0x030D, fromHWND removed, fromHWND next)

	  | compileMessage (WM_HSCROLLCLIPBOARD{viewer, code, position}) =
	  		(0x030E, fromHWND viewer, toCint(MAKELONG(code, position)))

	  | compileMessage WM_QUERYNEWPALETTE = (0x030F, toCint 0, toCint 0)

	  | compileMessage (WM_PALETTEISCHANGING{realize}) =
	  		(0x0310, fromHWND realize, toCint 0)

	  | compileMessage (WM_PALETTECHANGED{palChg}) =
	  		(0x0311, fromHWND palChg, toCint 0)

	  | compileMessage (WM_HOTKEY{id}) = (0x0312, toCint id, toCint 0)

	  | compileMessage (WM_PRINT{hdc, flags}) = (0x0317, fromHDC hdc, toCwmpl flags)

	  | compileMessage (WM_PRINTCLIENT{hdc, flags}) = (0x0318, fromHDC hdc, toCwmpl flags)

	  | compileMessage (FINDMSGSTRING{flags, findWhat, replaceWith}) =
	  		let
				val vec = alloc 10 Cint
			in
				assign Clong (offset 0 Clong vec) (toCint(10 * sizeof Cint));
				assign Clong (offset 3 Clong vec) (toCuint(LargeWord.toInt(
														 FindReplaceFlags.toWord flags)));
				assign Clong (offset 4 Clong vec) (toCstring findWhat);
				assign Clong (offset 5 Clong vec) (toCstring replaceWith);
				(RegisterMessage "commdlg_FindReplace", toCint 0, vec)
			end

	  | compileMessage (WM_USER{uMsg, wParam, lParam}) = (uMsg, toCint wParam, toCint lParam)

	  | compileMessage (WM_APP{uMsg, wParam, lParam}) = (uMsg, toCint wParam, toCint lParam)

	  | compileMessage (WM_REGISTERED{uMsg, wParam, lParam}) = (uMsg, toCint wParam, toCint lParam)

	  	local
			val msgStruct = STRUCT6(HWND, INT, POINTER, POINTER, INT, POINT)
			val (toMsg, fromMsg, msgType) = breakConversion msgStruct
		in
			(* Return the address of a vol containing the message. *)
			fun packMessage({msg, hwnd, time, pt}: MSG): vol =
			let
				val (msgId: int, wParam: vol, lParam: vol) = compileMessage msg
				val msgVol =
					fromMsg(hwnd, msgId, wParam, lParam, Time.toMilliseconds time, pt)
			in
				address msgVol
			end
		
			(* v is the address of a message structure.  The result is the unpacked
			   message. *)
			fun unpackMessage(v: vol): MSG =
			let
				val (hWnd, msgId, wParam, lParam, t, pt) = toMsg(deref v)
			in
				{
				msg = decompileMessage(msgId, fromCint wParam, fromCint lParam),
				hwnd = hWnd,
				time = Time.fromMilliseconds t,
				pt = pt
				}
			end
	
			val LPMSG = mkConversion unpackMessage packMessage (Cpointer msgType)
		end

		(* Window callback table. *)
		local
			type callback = int * int * int * int -> int
			(* *)
			datatype tableEntry = TableEntry of {hWnd: HWND, callBack: callback}
			val windowTable = ref [] : tableEntry list ref

			val SetWindowLong = call3 (user "SetWindowLongA") (HWND, INT, INT) INT
			val CallWindowProc = call5 (user "CallWindowProcA") (INT, INT, INT, INT, INT) INT
		
			fun deliverResult i = RunCall.run_call2 RuntimeCalls.POLY_SYS_os_specific (1106, i)
			fun installFun f = RunCall.run_call2 RuntimeCalls.POLY_SYS_os_specific (1105, f)

		in
			fun getCallback(hw: int) =
				List.find (fn (TableEntry{hWnd, ...}) => hw = intOfHandle hWnd) (! windowTable)

			fun removeCallback(hw: HWND): unit =
				windowTable := List.filter
					(fn(TableEntry{hWnd, ...}) => intOfHandle hw <> intOfHandle hWnd) (!windowTable)

			(* Update a window handle entry once we know it. *)
			fun updateWindowHandle(hwnd: HWND): unit =
				case getCallback 0 of
					NONE => () (* Ok. *)
				|	SOME(TableEntry{callBack, ...}) =>
					(
						removeCallback hwndNull;
						windowTable := TableEntry{callBack=callBack, hWnd=hwnd} :: ! windowTable
					)

			(* The callback function receives its arguments as ints.  They may well
			   actually be C addresses but the conversion process gets all that
			   right.  Unlike ML objects they can't move as a result of garbage
			   colection. *)
			fun mainCallbackFunction(hw:int, msgId:int, wParam:int, lParam:int) =
			let
				(* Normally we will have a callback for this window.  The only
				   case when we haven't will be if we've just created it in
				   which case we will have a dummy entry with zero.  This is a mess!

				   The difficulty is that we want to associate the state with a particular
				   window handle but we only find out about the handle when we receive the
				   first message.  That would be fine if it was WM_NCCREATE since we could put
				   something in the CreateWindow argument but it appears we get a WM_GETMINMAXINFO
				   before the WM_NCCREATE.  There may be a similar situation with dialogue boxes. *)
				val TableEntry{callBack, ...} =
					case getCallback hw of
						SOME c => c
					|	NONE =>
						(
						updateWindowHandle(handleOfInt hw);
						valOf(getCallback hw) (* Should now be there, we hope! *)
						)
			in
				deliverResult(callBack(hw, msgId, wParam, lParam))
			end

			fun addCallback (hWnd,
							 call: HWND * Message * 'a -> LRESULT option * 'a,
							 init: 'a,
							 defProc: callback): unit =
				let
					val state = ref init

					fun callBack(h, uMsg, wParam, lParam): int =
					let
						val msg = decompileMessage(uMsg, wParam, lParam)
							handle exn =>
								(
								print(concat["Exception with message ",
										Int.toString uMsg(*, exnMessage exn*) ]);
								NULL
								)
						val hWnd = handleOfInt h
						val (result, newState) =
							call(hWnd, msg, !state)
								handle exn =>
							 	(
								print(concat["Exception with message "(*,
										PolyML.makestring msg,
										exnMessage exn*) ]);
								(NONE, !state)
								)
					in
						state := newState;
						(* If our callback returned SOME x we use that as the result,
						   otherwise we call the default.  We do it this way rather
						   than having the caller call DefWindowProc because that
						   would involve recompiling the message and we can't
						   guarantee that all the parameters of the original message
						   would be correctly set. *)
						case result of
							SOME(LRESINT res) => res
						|	SOME(LRESHANDLE res) => intOfHandle res
						|	NONE => defProc(h, uMsg, wParam, lParam)
					end;
				in
					(* We need to ensure that callback is installed whenever we might create a window. *)
					installFun mainCallbackFunction;

					windowTable :=
						TableEntry{ hWnd = hWnd, callBack = callBack } :: ! windowTable
				end

			fun subclass(w: HWND, f: HWND * Message * 'a -> LRESULT option * 'a, init: 'a) =
			let
				val ourWProc = RunCall.run_call2 RuntimeCalls.POLY_SYS_os_specific (1102, ())
				(* Set up the new window proc and get the existing one. *)
				val oldWProc = SetWindowLong(w, ~4, ourWProc)

				(* TODO: What if it's not there? *)
				val TableEntry{hWnd, callBack} = valOf(getCallback(intOfHandle w))
				
				val newDefProc =
					if oldWProc = ourWProc
					then (* Our function was already installed - chain this callback onto
						    the result. *)
						callBack
					else fn (h, m, w, l) => CallWindowProc(oldWProc, h, m, w, l)
			in
				(* Remove any existing callback function and install the new one. *)
				removeCallback w;
				addCallback(w, f, init, newDefProc)
			end
		end


		(* Keyboard operations on modeless dialogues are performed by isDialogMessage.
		   We keep a list of modeless dialogues and process them in the main
		   message loop.
		   This also has an important function for dialogues created by FindText.
		   FindText creates a FINDREPLACE structure which must not be GC'd while
		   the dialogue exists.  We include the vol in this table which holds onto
		   the underlying C structure. *)
		local
			val modeless = ref []
			val isDialogMessage = call2 (user "IsDialogMessage") (HWND, POINTER) BOOL
			val isWindow = call1 (user "IsWindow") (HWND) BOOL
		in
			fun addModelessDialogue (hWnd: HWND, retain: vol) =
				modeless := (hWnd, retain) :: (!modeless)

			fun isDialogueMsg(msg: vol) =
			(
				(* Take this opportunity to filter any dialogues that have gone away. *)
				modeless := List.filter (isWindow o #1) (!modeless);
				(* See if isDialogMessage returns true for any of these. *)
				List.foldl (fn ((w, _), b) => b orelse isDialogMessage(w, msg)) false (!modeless)
			)
		end

		datatype PeekMessageOptions = PM_NOREMOVE | PM_REMOVE
		(* TODO: We can also include PM_NOYIELD. *)

		fun PeekMessage(hWnd: HWND option, wMsgFilterMin: int,
					    wMsgFilterMax: int, remove: PeekMessageOptions): MSG option =
		let
			val msg = alloc 7 Cint
			val peekMsg = call5(user "PeekMessageA") (POINTER, HWNDOPT, INT, INT, INT) INT
			val opts = case remove of PM_REMOVE => 1 | PM_NOREMOVE => 0
			val res = peekMsg(address msg, hWnd, wMsgFilterMin, wMsgFilterMax, opts)
		in
			if res = 0
			then NONE
			else SOME(unpackMessage(address msg))
		end;

		local
			val callWin = RunCall.run_call2 RuntimeCalls.POLY_SYS_os_specific
		in
			fun pauseForMessage(hwnd: HWND, min, max): unit =
				callWin(1101, (intOfHandle hwnd, min, max))

			(* We implement WaitMessage within the RTS. *)
			fun WaitMessage(): bool =
				(pauseForMessage(hwndNull, 0, 0); true)
		end

		(* We don't use the underlying GetMessage function because that blocks the
		   thread which would prevent other ML processes from running.  Instead we
		   use PeekMessage and an RTS call which allows other threads to run. *)
		fun GetMessage(hWnd: HWND option, wMsgFilterMin: int, wMsgFilterMax: int): MSG =
			case PeekMessage(hWnd, wMsgFilterMin, wMsgFilterMax, PM_REMOVE) of
				SOME msg => msg
			|	NONE =>
				let
					val hwnd = getOpt(hWnd, hwndNull)
				in
					pauseForMessage(hwnd, wMsgFilterMin, wMsgFilterMax);
					GetMessage(hWnd, wMsgFilterMin, wMsgFilterMax)
				end

		(* Wait for messages and dispatch them.  It only returns when a QUIT message
		   has been received. *)
		fun RunApplication() =
		let
			val peekMsg = call5(user "PeekMessageA") (POINTER, HWND, INT, INT, INT) INT
			val transMsg = call1(user "TranslateMessage") (POINTER) INT
			val dispMsg = call1(user "DispatchMessageA") (POINTER) INT
			val callWin = RunCall.run_call2 RuntimeCalls.POLY_SYS_os_specific
			val msg = alloc 7 Cint
			val res = peekMsg(address msg, toHWND(toCint 0), 0, 0, 1)
		in
			if res = 0
			then (* There's no message at the moment.  Wait for one. *)
				(WaitMessage(); RunApplication())
			else case unpackMessage(address msg) of
				{ msg = WM_QUIT{exitcode}, ...} => exitcode
			|	_ =>
				(
					if isDialogueMsg(address msg) then ()
					else ( transMsg(address msg); dispMsg(address msg); () );
				RunApplication()
				)
		end

		fun SendMessage(hWnd: HWND, msg: Message) =
		let
			val sendMsg = call4(user "SendMessageA") (HWND, INT, POINTER, POINTER) INT
			val (msgId: int, wp: vol, lp: vol) = compileMessage msg
			val reply = sendMsg(hWnd, msgId, wp, lp)
		in
			(* For certain messages we need to extract the reply from the arguments. *)
			case msg of
				WM_GETTEXT{text, ...} =>
					text := (if reply = 0 then "" else fromCstring lp)
			|	WM_ASKCBFORMATNAME{formatName, ...} =>
					formatName := (if reply = 0 then "" else fromCstring lp)
			|	EM_GETLINE{result, ...} =>
					result := (if reply = 0 then "" else fromCstring lp)
			|	EM_GETRECT{rect, ...} => rect := fromCrect(deref lp)
			|	EM_GETSEL{startPos, endPos} =>
					(startPos := fromCint(deref wp); endPos := fromCint(deref lp))
			|	CB_GETEDITSEL{startPos, endPos} =>
					(startPos := fromCint(deref wp); endPos := fromCint(deref lp))
			|	CB_GETLBTEXT {text, ...} =>
					text := (if reply = 0 then "" else fromCstring lp)
			|	CB_GETDROPPEDCONTROLRECT{rect, ...} => rect := fromCrect(deref lp)
			|	SBM_GETRANGE {minPos, maxPos} =>
					(minPos := fromCint(deref wp); maxPos := fromCint(deref lp))
			|	SBM_GETSCROLLINFO {info, ...} =>
				let val (inf, _) = fromCscrollinfo(deref lp) in info := inf end
			|	LB_GETTEXT {text, ...} =>
					text := (if reply = 0 then "" else fromCstring lp)
			|	LB_GETSELITEMS{itemCount, items} =>
				let
					val b = deref lp
				in
					items := List.tabulate(itemCount, fn n => fromCint(offset n Cint b))
				end
			|	LB_GETITEMRECT{rect, ...} => rect := fromCrect(deref lp)
			|	_ => ();

			(* We need to "cast" some of the results. *)
			case msg of
				WM_GETFONT => LRESHANDLE(handleOfInt reply)
			|	WM_GETICON _ => LRESHANDLE(handleOfInt reply)
			|	WM_SETICON _ => LRESHANDLE(handleOfInt reply)
			|	BM_GETIMAGE _ => LRESHANDLE(handleOfInt reply)
			|	BM_SETIMAGE _ => LRESHANDLE(handleOfInt reply)
			|	STM_GETICON => LRESHANDLE(handleOfInt reply)
			|	STM_GETIMAGE _ => LRESHANDLE(handleOfInt reply)
			|	STM_SETICON _ => LRESHANDLE(handleOfInt reply)
			|	STM_SETIMAGE _ => LRESHANDLE(handleOfInt reply)
			|	_ => LRESINT reply
		end


		local
			val postMessage =
				call4(user "PostMessageA") (HWND, INT, POINTER, POINTER)
					(SUCCESSSTATE "PostMessage")
		in
			fun PostMessage(hWnd: HWND, msg: Message) =
			let
				val (msgId: int, wp: vol, lp: vol) = compileMessage msg
			in
				postMessage(hWnd, msgId, wp, lp)
			end
		end

		val HWND_BROADCAST: HWND  = handleOfInt 0xffff

		val PostQuitMessage = call1 (user "PostQuitMessage") INT VOID
		val RegisterWindowMessage = call1 (user "RegisterWindowMessageA") (STRING) INT
		val InSendMessage = call0 (user "InSendMessage") () BOOL
		val GetInputState = call0 (user "GetInputState") () BOOL

		local
			val getMessagePos = call0 (user "GetMessagePos") () INT
		in
			fun GetMessagePos(): POINT =
			let
				val r = getMessagePos ()
			in
				{ x = LOWORD r, y = HIWORD r }
			end
		end

		val GetMessageTime = Time.fromMilliseconds o 
			call0 (user "GetMessageTime") () INT

		datatype QueueStatus =
			QS_KEY | QS_MOUSEMOVE | QS_MOUSEBUTTON | QS_POSTMESSAGE | QS_TIMER |
			QS_PAINT | QS_SENDMESSAGE | QS_HOTKEY | QS_ALLPOSTMESSAGE
		local
			val tab = [
				(QS_KEY,              0x0001),
				(QS_MOUSEMOVE,        0x0002),
				(QS_MOUSEBUTTON,      0x0004),
				(QS_POSTMESSAGE,      0x0008),
				(QS_TIMER,            0x0010),
				(QS_PAINT,            0x0020),
				(QS_SENDMESSAGE,      0x0040),
				(QS_HOTKEY,           0x0080),
				(QS_ALLPOSTMESSAGE,   0x0100)
			]
		in
			val (fromQS, toQS) = tableSetLookup(tab, NONE)
		end

		val QS_MOUSE = [QS_MOUSEMOVE, QS_MOUSEBUTTON]
	    val QS_INPUT = QS_KEY :: QS_MOUSE
	    val QS_ALLEVENTS = QS_POSTMESSAGE :: QS_TIMER :: QS_PAINT :: QS_HOTKEY :: QS_INPUT
	    val QS_ALLINPUT = QS_SENDMESSAGE :: QS_ALLEVENTS

		local
			val getQueueStatus = call1 (user "GetQueueStatus") (INT) INT
		in
			fun GetQueueStatus flags =
			let
				val res = getQueueStatus(fromQS flags)
			in
				(* The RTS uses PeekMessage internally so the "new messages"
				   value in the LOWORD is meaningless. *)
				toQS(HIWORD(res))
			end
		end

(*
BroadcastSystemMessage  
DispatchMessage  
GetMessageExtraInfo  
InSendMessageEx  - NT 5.0 and Windows 98  
PostThreadMessage  
ReplyMessage  
SendAsyncProc  
SendMessageCallback  
SendMessageTimeout  
SendNotifyMessage  
SetMessageExtraInfo  
TranslateMessage  

Obsolete Functions

PostAppMessage  
SetMessageQueue   

*)
	end
end;
