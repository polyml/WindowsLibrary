(*
    Copyright (c) 2001-7, 2015
        David C.J. Matthews

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License version 2.1 as published by the Free Software Foundation.
    
    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.
    
    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*)

structure Message: MESSAGE =
struct
    local
        open Foreign
        open Memory
        open Base
        open Globals
        open WinBase
        fun user name = getSymbol(loadLibrary "user32.dll") name
        
        val toAddr = Memory.sysWord2VoidStar
        and fromAddr = Memory.voidStar2Sysword

        val RegisterMessage = winCall1 (user "RegisterWindowMessageA") cString cUint
        
        (* Used in WM_WINDOWPOSXXX and also WM_NCCALCSIZE *)
        val WINDOWPOS = cStruct7(cHWND, cHWND, cInt, cInt, cInt, cInt, cWINDOWPOSITIONSTYLE)    

        local (* WM_WINDOWPOSCHANGING and WM_WINDOWPOSCHANGED. The C structure is the same
                 but WM_WINDOWPOSCHANGING has refs in the ML to allow the call-back to
                 change the position. *)
            val {load=fromCwindowpos, store=toCwindowpos, ctype={size=sizeCwp, ...}, ...} = breakConversion WINDOWPOS
            type wmWINDOWPOSCHANGED =
                { hwnd: HWND, front: HWND, x: int, y: int, width: int, height: int, flags: WindowPositionStyle list }
            and wmWINDOWPOSCHANGING =
                {
                    hwnd: HWND, front: HWND ref, x: int ref, y: int ref,
                    width: int ref, height: int ref, flags: WindowPositionStyle list ref
                } 
        in
            fun cToMLWindowPosChanging{wp=_, lp}: wmWINDOWPOSCHANGING =
            let
                val (wh,front,x,y,width,height,flags) = fromCwindowpos(toAddr lp)
            in
                {hwnd = wh, front = ref front, x = ref x, y = ref y,
                 width = ref width, height = ref height, flags = ref flags}
            end
            and cToMLWindowPosChanged{wp=_, lp}: wmWINDOWPOSCHANGED =
            let
                val (wh,front,x,y,width,height,flags) = fromCwindowpos(toAddr lp)
            in
                {hwnd = wh, front = front, x = x, y = y, width = width, height = height, flags = flags}
            end

            fun mlToCWindowPosChanging(msgNo, {hwnd, front=ref front, x=ref x, y=ref y,
                                   width=ref width, height=ref height, flags=ref flags}: wmWINDOWPOSCHANGING) =
            let
                open Memory
                val mem = malloc sizeCwp
                val freeCwp = toCwindowpos(mem, (hwnd, front, x, y, width, height, flags))
            in
                (msgNo, 0w0, fromAddr mem, fn() => (freeCwp(); free mem))
            end
            and mlToCWindowPosChanged(msgNo, {hwnd, front, x, y, width, height, flags}: wmWINDOWPOSCHANGED) =
            let
                open Memory
                val mem = malloc sizeCwp
                val freeCwp = toCwindowpos(mem, (hwnd, front, x, y, width, height, flags))
            in
                (msgNo, 0w0, fromAddr mem, fn() => (freeCwp(); free mem))
            end

            fun updateCfromMLwmWindowPosChanging(
                    {wp=_, lp}, { front, x, y, width, height, flags, ...}:wmWINDOWPOSCHANGING) =
            let
                val (_,newfront,newx,newy,newwidth,newheight,newflags) = fromCwindowpos(toAddr lp) 
            in
                front := newfront;
                x := newx;
                y := newy;
                width := newwidth;
                height := newheight;
                flags := newflags
            end
            and updateWindowPosChangingParms({wp=_, lp}, { hwnd, front=ref front, x=ref x, y=ref y,
                                                           width=ref width, height=ref height, flags=ref flags}) =
               ignore(toCwindowpos(toAddr lp, (hwnd, front, x, y, width, height, flags)))
        end

        datatype ControlType = ODT_MENU | ODT_LISTBOX | ODT_COMBOBOX | ODT_BUTTON | ODT_STATIC
        local
            val 
            tab = [
                (ODT_MENU, 1),
                (ODT_LISTBOX, 2),
                (ODT_COMBOBOX, 3),
                (ODT_BUTTON, 4),
                (ODT_STATIC, 5)
                ]
        in
            val cCONTROLTYPE = tableConversion(tab, NONE) cUint
        end
 
        fun structAsAddr strConv =
        let
            val {load, store, ctype={size, ...}, ...} = breakConversion strConv

            fun make v =
            let
                open Memory
                val mem = malloc size
                val freeS = store(mem, v)
            in
                (fromAddr mem, fn () => (freeS(); free mem))
            end
        in
            (load o toAddr, make)
        end
        
        val (_, makePointStructAddr) = structAsAddr cPoint

        local
            val MDICREATESTRUCT = cStruct9(cCLASS,cString,cHINSTANCE,cInt,cInt,cInt,cInt,cDWORD,cLPARAM)
        in
            val (toMdiCreate, fromMdiCreate) = structAsAddr MDICREATESTRUCT
        end

        local (* WM_COMPAREITEM *)
            val COMPAREITEMSTRUCT = cStruct8(cCONTROLTYPE,cUint,cHWND,cUint,cUINT_PTRw,cUint,cUINT_PTRw, cDWORD)
            val MEASUREITEMSTRUCT = cStruct6(cCONTROLTYPE,cUint,cUint,cUint,cUint,cULONG_PTR)
            val DELETEITEMSTRUCT = cStruct5(cCONTROLTYPE,cUint,cUint,cHWND,cULONG_PTR)
            val {store=toMeasureItem, ...} = breakConversion MEASUREITEMSTRUCT
        in
            val (toMLCompareItem, fromMLCompareItem) = structAsAddr COMPAREITEMSTRUCT
            and (toMLMeasureItem, fromMLMeasureItem) = structAsAddr MEASUREITEMSTRUCT
            and (toMLDeleteItem, fromMLDeleteItem) = structAsAddr DELETEITEMSTRUCT
            
            fun updateMeasureItemFromWpLp({itemWidth, itemHeight, ...}, {wp=_, lp}) =
            let
                val (_, _, _, iWidth, iHeight, _) = toMLMeasureItem lp
            in
                itemWidth := iWidth;
                itemHeight := iHeight
            end
            and updateMeasureItemParms({wp=_, lp}, {itemWidth=ref itemWidth, itemHeight=ref itemHeight, ...}) =
            let
                val (ctlType, ctlID, itemID, _, _, itemData) = toMLMeasureItem lp
            in
                ignore(toMeasureItem(toAddr lp, (ctlType, ctlID, itemID, itemWidth, itemHeight, itemData)))
            end
        end

        local (* WM_CREATE and WM_NCCREATE *)
            val CREATESTRUCT = cStruct12(cPointer,cHINSTANCE,cHMENU,cHWND,cInt,cInt,cInt,cInt,cUlongw,cString,cCLASS,cDWORD)
            val (toMLCreate, fromMLCreate) = structAsAddr CREATESTRUCT
        in
            fun decompileCreate{wp=_, lp} =
            let
                val (cp,inst,menu,parent, cy,cx,y,x, style, name,class, extendedstyle) = toMLCreate lp
            in
                { instance = inst, creation = cp, menu = menu, parent = parent, cy = cy, cx = cx,
                  y = y, x = x, style = Style.fromWord(Word32.toLargeWord style), name = name,
                  class = class, extendedstyle = extendedstyle }
            end

            and compileCreate(code, { instance, creation, menu, parent, cy, cx,
                                y, x, style, name, class, extendedstyle}) =
            let
                val (addr, free) =
                    fromMLCreate(creation, instance, menu, parent,
                        cy, cx, y, x, Word32.fromLargeWord(Style.toWord style), name, class,
                        extendedstyle)
            in
                (code, 0w0, addr, free)
            end

        end

        local
            val MINMAXINFO = cStruct5(cPoint,cPoint,cPoint,cPoint,cPoint)
            val {store=toCminmaxinfo, ...} = breakConversion MINMAXINFO
            val (toMLMinMax, fromMLMinMax) = structAsAddr MINMAXINFO
        in
            fun decompileMinMax{wp=_, lp} =
            let  
                val (_, ptms, ptmp, ptts, ptmts) = toMLMinMax lp
            in
                    { maxSize = ref ptms, maxPosition = ref ptmp,
                      minTrackSize = ref ptts, maxTrackSize = ref ptmts}
            end
            and compileMinMax(code, { maxSize=ref maxSize, maxPosition=ref maxPosition,
                                minTrackSize=ref minTrackSize, maxTrackSize=ref maxTrackSize}) =
            let
                val (addr, free) = fromMLMinMax({x=0,y=0}, maxSize, maxPosition, minTrackSize, maxTrackSize)
            in
                (code, 0w0, addr, free)
            end
            
            fun updateMinMaxFromWpLp({maxSize, maxPosition, minTrackSize, maxTrackSize}, {wp=_, lp}) =
            let
                val (_, ptms, ptmp, ptts, ptmts) = toMLMinMax lp
            in
                maxSize := ptms;
                maxPosition := ptmp;
                minTrackSize := ptts;
                maxTrackSize := ptmts
            end
            and updateMinMaxParms({wp=_, lp}, {maxSize=ref maxSize, maxPosition=ref maxPosition,
                                               minTrackSize=ref minTrackSize, maxTrackSize=ref maxTrackSize}) =
            let
                val (ptres, _, _, _, _) = toMLMinMax lp
            in
                ignore(toCminmaxinfo(toAddr lp, (ptres, maxSize, maxPosition, minTrackSize, maxTrackSize)))
            end
        end

        local
            val DRAWITEMSTRUCT = cStruct9(cCONTROLTYPE,cUint,cUint,cUint,cUint,cHWND,cHDC,cRect,cULONG_PTR)
        in
            val (toMLDrawItem, fromMLDrawItem) = structAsAddr DRAWITEMSTRUCT
        end

        local (* WM_NCCALCSIZE *)
            val NCCALCSIZE_PARAMS = cStruct4(cRect,cRect,cRect, cConstStar WINDOWPOS)
            val {load=loadStruct, store=storeStruct, ctype={size=sizeStr, ...}, ...} = breakConversion NCCALCSIZE_PARAMS
            val {load=loadRect, store=storeRect, ctype={size=sizeRect, ...}, ...} = breakConversion cRect
        in
            fun decompileNCCalcSize{wp=0w0, lp} =
                let
                    val (newrect,oldrect,oldclientarea,winpos) = loadStruct (toAddr lp)
                    val (wh,front,x,y,cx,cy,style) = winpos 
                in
                    { validarea = true, newrect = ref newrect, oldrect = oldrect,
                      oldclientarea = oldclientarea, hwnd = wh, insertAfter = front,
                      x = x, y = y, cx = cx, cy = cy, style = style }
                end

            |   decompileNCCalcSize{wp=_, lp} =
                let
                    val newrect = loadRect (toAddr lp)
                    val zeroRect = {left=0, top=0, right=0, bottom=0}
                in 
                    { validarea = false, newrect = ref newrect, oldrect = zeroRect,
                      oldclientarea = zeroRect, insertAfter = hwndNull, hwnd = hwndNull,
                      x = 0, y = 0, cx = 0, cy = 0, style = [] }
                end

            and compileNCCalcSize{validarea=true, newrect=ref newrect, oldrect, oldclientarea,
                            hwnd, insertAfter, x, y, cx, cy, style} =
            let
                open Memory
                val mem = malloc sizeStr
                val freeRect =
                    storeStruct(mem, (newrect,oldrect,oldclientarea,
                                         (hwnd,insertAfter,x,y,cx,cy, style)))
            in
                (0x0083, 0w1, fromAddr mem, fn () => (freeRect(); free mem))
            end    
            |   compileNCCalcSize{validarea=false, newrect=ref newrect, ...} =
            let
                open Memory
                val mem = malloc sizeRect
                val () = ignore(storeRect(mem, newrect))
            in
                (0x0083, 0w0, fromAddr mem, fn () => free mem)
            end    
        end

        local
            val HELPINFO = cStruct6(cUint, cInt, cInt, cPointer (* HANDLE *), cDWORD, cPoint)
            val {ctype={size=sizeHelpInfo, ...}, ...} = breakConversion HELPINFO
            val (toHelpInfo, fromHelpInfo) = structAsAddr HELPINFO
        in
            datatype HelpHandle = MenuHandle of HMENU | WindowHandle of HWND

            fun compileHelpInfo(code, {ctrlId, itemHandle, contextId, mousePos}) =
            let
                val (ctype, handl) =
                    case itemHandle of
                        MenuHandle m => (2, voidStarOfHandle m)
                    |   WindowHandle w => (1, voidStarOfHandle w)
                val (addr, free) =
                    fromHelpInfo(Word.toInt sizeHelpInfo, ctype, ctrlId, handl, contextId, mousePos)
            in
                (code, 0w0, addr, free)
            end
            
            and decompileHelpInfo{wp=_, lp} =
            let
                val (_, ctype, ctrlId, itemHandle, contextId, mousePos) = toHelpInfo lp
                val hndl =
                    if ctype = 2 then MenuHandle(handleOfVoidStar itemHandle)
                    else WindowHandle(handleOfVoidStar itemHandle)
            in
                { ctrlId = ctrlId, itemHandle = hndl, contextId =  contextId, mousePos = mousePos}
            end
        end

        local
            val {store=storeScrollInfo, ctype = {size=sizeStruct, ...}, ...} =
                breakConversion ScrollBase.cSCROLLINFOSTRUCT
            val (toScrollInfoStruct, fromScrollInfoStruct) = structAsAddr ScrollBase.cSCROLLINFOSTRUCT
        in
            fun toScrollInfo lp =
            let
                val (_, options, minPos, maxPos, pageSize, pos, trackPos) = toScrollInfoStruct lp
                val info = { minPos = minPos, maxPos = maxPos, pageSize = pageSize, pos = pos, trackPos = trackPos }
            in
                (info, options)
            end
            and fromScrollInfo({minPos, maxPos, pageSize, pos, trackPos}, options) =
                fromScrollInfoStruct(Word.toInt sizeStruct, options, minPos, maxPos, pageSize, pos, trackPos)
            and updateScrollInfo({wp=_, lp=lp}, {info=ref {minPos, maxPos, pageSize, pos, trackPos}, options}) =
                ignore(storeScrollInfo(toAddr lp, (Word.toInt sizeStruct, options, minPos, maxPos, pageSize, pos, trackPos)))
        end

        local
            val {store=storeWord, load=loadWord, ctype={size=sizeWord, ...}, ...} = breakConversion cWORD
        in
            (* We have to allocate a buffer big enough to receive the text and
               set the first word to the length of the buffer. *)
            fun compileGetLine {lineNo, size, ...} =
            let
                open Memory
                (* Allocate one extra byte so there's space for a null terminator. *)
                val vec = malloc (Word.max(Word.fromInt(size+1), sizeWord))
            in
                ignore(storeWord(vec, size+1));
                (0x00C5, SysWord.fromInt lineNo, fromAddr vec, fn () => free vec)
            end

            and decompileGetLine{wp, lp} =
            let
                (* The first word is supposed to contain the length *)
                val size = loadWord(toAddr lp)
            in
                { lineNo = SysWord.toInt wp, size = size(*-1 ? *), result = ref "" }
            end
        end

        val {load=loadInt, store=storeInt, ctype={size=sizeInt, ...}, ...} = breakConversion cInt

        local (* EM_SETTABSTOPS and LB_SETTABSTOPS *)
            open Memory
            infix 6 ++
        in
            fun decompileTabStops{wp, lp} =
            let
                val v = toAddr lp
                fun getTab i = loadInt(v ++ Word.fromInt i * sizeInt)
            in
                IntVector.tabulate(SysWord.toInt wp, getTab)
            end
            and compileTabStops(code, tabs) =
            let
                val cTabs = IntVector.length tabs
                val vec = malloc(Word.fromInt cTabs * sizeInt)
                fun setVec(tab, addr) = (ignore(storeInt(addr, tab)); addr ++ sizeInt)
                val _ = IntVector.foldl setVec vec tabs
            in
                (code, SysWord.fromInt cTabs, fromAddr vec, fn () => free vec)
            end
        end

        local
            open Memory IntArray
            infix 6 ++
        in
            fun compileGetSelItems(code, {items}) =
            (* Allocate a buffer to receive the items.  Set each element of the buffer
               to ~1 so that the values are defined if not all of them are set. *)
            let
                open Memory IntArray
                val itemCount = length items
                infix 6 ++
                val v = malloc(Word.fromInt itemCount * sizeInt)
            in
                appi(fn (i, s) => ignore(storeInt(v ++ Word.fromInt i * sizeInt, s))) items;
                (code, SysWord.fromInt itemCount, fromAddr v, fn () => free v)
            end

            fun updateGetSelItemsParms({wp=_, lp=lp}, {items}) =
            let
                val v = toAddr lp
            in
                appi(fn (i, s) => ignore(storeInt(v ++ Word.fromInt i * sizeInt, s))) items
            end
            and updateGetSelItemsFromWpLp({items}, {wp=_, lp, reply}) =
            let
                (* The return value is the actual number of items copied *)
                val nItems = SysWord.toIntX reply
                val b = toAddr lp
                open Memory
                infix 6 ++
                fun newValue (i, old) = if i < nItems then loadInt(b ++ sizeInt * Word.fromInt i) else old
            in
                IntArray.modifyi newValue items
            end
        end

        (* Passed in the lpParam argument of a WM_NOTIFY message.
           TODO: Many of these have additional information. *)
        datatype Notification =
            NM_OUTOFMEMORY
        |   NM_CLICK
        |   NM_DBLCLK
        |   NM_RETURN
        |   NM_RCLICK
        |   NM_RDBLCLK
        |   NM_SETFOCUS
        |   NM_KILLFOCUS
        |   NM_CUSTOMDRAW
        |   NM_HOVER
        |   NM_NCHITTEST
        |   NM_KEYDOWN
        |   NM_RELEASEDCAPTURE
        |   NM_SETCURSOR
        |   NM_CHAR
        |   NM_TOOLTIPSCREATED
        |   NM_LDOWN
        |   NM_RDOWN
        |   NM_THEMECHANGED
        |   LVN_ITEMCHANGING
        |   LVN_ITEMCHANGED
        |   LVN_INSERTITEM
        |   LVN_DELETEITEM
        |   LVN_DELETEALLITEMS
        |   LVN_BEGINLABELEDIT
        |   LVN_ENDLABELEDIT
        |   LVN_COLUMNCLICK
        |   LVN_BEGINDRAG
        |   LVN_BEGINRDRAG
        |   LVN_GETDISPINFO
        |   LVN_SETDISPINFO
        |   LVN_KEYDOWN
        |   LVN_GETINFOTIP
        |   HDN_ITEMCHANGING
        |   HDN_ITEMCHANGED
        |   HDN_ITEMCLICK
        |   HDN_ITEMDBLCLICK
        |   HDN_DIVIDERDBLCLICK
        |   HDN_BEGINTRACK
        |   HDN_ENDTRACK
        |   HDN_TRACK
        |   HDN_ENDDRAG
        |   HDN_BEGINDRAG
        |   HDN_GETDISPINFO
        |   TVN_SELCHANGING
        |   TVN_SELCHANGED
        |   TVN_GETDISPINFO
        |   TVN_SETDISPINFO
        |   TVN_ITEMEXPANDING
        |   TVN_ITEMEXPANDED
        |   TVN_BEGINDRAG
        |   TVN_BEGINRDRAG
        |   TVN_DELETEITEM
        |   TVN_BEGINLABELEDIT
        |   TVN_ENDLABELEDIT
        |   TVN_KEYDOWN
        |   TVN_GETINFOTIP
        |   TVN_SINGLEEXPAND
        |   TTN_GETDISPINFO of string ref
        |   TTN_SHOW
        |   TTN_POP
        |   TCN_KEYDOWN
        |   TCN_SELCHANGE
        |   TCN_SELCHANGING
        |   TBN_GETBUTTONINFO
        |   TBN_BEGINDRAG
        |   TBN_ENDDRAG
        |   TBN_BEGINADJUST
        |   TBN_ENDADJUST
        |   TBN_RESET
        |   TBN_QUERYINSERT
        |   TBN_QUERYDELETE
        |   TBN_TOOLBARCHANGE
        |   TBN_CUSTHELP
        |   TBN_DROPDOWN
        |   TBN_HOTITEMCHANGE
        |   TBN_DRAGOUT
        |   TBN_DELETINGBUTTON
        |   TBN_GETDISPINFO
        |   TBN_GETINFOTIP
        |   UDN_DELTAPOS
        |   RBN_GETOBJECT
        |   RBN_LAYOUTCHANGED
        |   RBN_AUTOSIZE
        |   RBN_BEGINDRAG
        |   RBN_ENDDRAG
        |   RBN_DELETINGBAND
        |   RBN_DELETEDBAND
        |   RBN_CHILDSIZE
        |   CBEN_GETDISPINFO
        |   CBEN_DRAGBEGIN
        |   IPN_FIELDCHANGED
        |   SBN_SIMPLEMODECHANGE
        |   PGN_SCROLL
        |   PGN_CALCSIZE
        |   NM_OTHER of int (* Catch-all for other cases. *)

        local
            (* Notification structures *)
            val NMHDR = cStruct3(cHWND, cUINT_PTR, cUint)
            val (toMLNmhdr, fromMLNmhdr) = structAsAddr NMHDR
            val CHARARRAY80 = cCHARARRAY 80
            val NMTTDISPINFO =
                cStruct6(NMHDR, cPointer (* String or resource id *), CHARARRAY80, cHINSTANCE, cUint, cLPARAM);
            val (toMLNMTTDISPINFO, fromMLNMTTDISPINFO) = structAsAddr NMTTDISPINFO
        in
            fun compileNotification (from, idFrom, NM_OUTOFMEMORY) = fromMLNmhdr(from, idFrom, ~1)
            |  compileNotification (from, idFrom, NM_CLICK) = fromMLNmhdr(from, idFrom, ~2)
            |  compileNotification (from, idFrom, NM_DBLCLK) = fromMLNmhdr(from, idFrom, ~3)
            |  compileNotification (from, idFrom, NM_RETURN) = fromMLNmhdr(from, idFrom, ~4)
            |  compileNotification (from, idFrom, NM_RCLICK) = fromMLNmhdr(from, idFrom, ~5)
            |  compileNotification (from, idFrom, NM_RDBLCLK) = fromMLNmhdr(from, idFrom, ~6)
            |  compileNotification (from, idFrom, NM_SETFOCUS) = fromMLNmhdr(from, idFrom, ~7)
            |  compileNotification (from, idFrom, NM_KILLFOCUS) = fromMLNmhdr(from, idFrom, ~8)
            |  compileNotification (from, idFrom, NM_CUSTOMDRAW) = fromMLNmhdr(from, idFrom, ~12)
            |  compileNotification (from, idFrom, NM_HOVER) = fromMLNmhdr(from, idFrom, ~13)
            |  compileNotification (from, idFrom, NM_NCHITTEST) = fromMLNmhdr(from, idFrom, ~14)
            |  compileNotification (from, idFrom, NM_KEYDOWN) = fromMLNmhdr(from, idFrom, ~15)
            |  compileNotification (from, idFrom, NM_RELEASEDCAPTURE) = fromMLNmhdr(from, idFrom, ~16)
            |  compileNotification (from, idFrom, NM_SETCURSOR) = fromMLNmhdr(from, idFrom, ~17)
            |  compileNotification (from, idFrom, NM_CHAR) = fromMLNmhdr(from, idFrom, ~18)
            |  compileNotification (from, idFrom, NM_TOOLTIPSCREATED) = fromMLNmhdr(from, idFrom, ~19)
            |  compileNotification (from, idFrom, NM_LDOWN) = fromMLNmhdr(from, idFrom, ~20)
            |  compileNotification (from, idFrom, NM_RDOWN) = fromMLNmhdr(from, idFrom, ~21)
            |  compileNotification (from, idFrom, NM_THEMECHANGED) = fromMLNmhdr(from, idFrom, ~22)
            |  compileNotification (from, idFrom, LVN_ITEMCHANGING) = fromMLNmhdr(from, idFrom, ~100)
            |  compileNotification (from, idFrom, LVN_ITEMCHANGED) = fromMLNmhdr(from, idFrom, ~101)
            |  compileNotification (from, idFrom, LVN_INSERTITEM) = fromMLNmhdr(from, idFrom, ~102)
            |  compileNotification (from, idFrom, LVN_DELETEITEM) = fromMLNmhdr(from, idFrom, ~103)
            |  compileNotification (from, idFrom, LVN_DELETEALLITEMS) = fromMLNmhdr(from, idFrom, ~104)
            |  compileNotification (from, idFrom, LVN_BEGINLABELEDIT) = fromMLNmhdr(from, idFrom, ~105)
            |  compileNotification (from, idFrom, LVN_ENDLABELEDIT) = fromMLNmhdr(from, idFrom, ~106)
            |  compileNotification (from, idFrom, LVN_COLUMNCLICK) = fromMLNmhdr(from, idFrom, ~108)
            |  compileNotification (from, idFrom, LVN_BEGINDRAG) = fromMLNmhdr(from, idFrom, ~109)
            |  compileNotification (from, idFrom, LVN_BEGINRDRAG) = fromMLNmhdr(from, idFrom, ~111)
            |  compileNotification (from, idFrom, LVN_GETDISPINFO) = fromMLNmhdr(from, idFrom, ~150)
            |  compileNotification (from, idFrom, LVN_SETDISPINFO) = fromMLNmhdr(from, idFrom, ~151)
            |  compileNotification (from, idFrom, LVN_KEYDOWN) = fromMLNmhdr(from, idFrom, ~155)
            |  compileNotification (from, idFrom, LVN_GETINFOTIP) = fromMLNmhdr(from, idFrom, ~157)
            |  compileNotification (from, idFrom, HDN_ITEMCHANGING) = fromMLNmhdr(from, idFrom, ~300)
            |  compileNotification (from, idFrom, HDN_ITEMCHANGED) = fromMLNmhdr(from, idFrom, ~301)
            |  compileNotification (from, idFrom, HDN_ITEMCLICK) = fromMLNmhdr(from, idFrom, ~302)
            |  compileNotification (from, idFrom, HDN_ITEMDBLCLICK) = fromMLNmhdr(from, idFrom, ~303)
            |  compileNotification (from, idFrom, HDN_DIVIDERDBLCLICK) = fromMLNmhdr(from, idFrom, ~305)
            |  compileNotification (from, idFrom, HDN_BEGINTRACK) = fromMLNmhdr(from, idFrom, ~306)
            |  compileNotification (from, idFrom, HDN_ENDTRACK) = fromMLNmhdr(from, idFrom, ~307)
            |  compileNotification (from, idFrom, HDN_TRACK) = fromMLNmhdr(from, idFrom, ~308)
            |  compileNotification (from, idFrom, HDN_ENDDRAG) = fromMLNmhdr(from, idFrom, ~311)
            |  compileNotification (from, idFrom, HDN_BEGINDRAG) = fromMLNmhdr(from, idFrom, ~310)
            |  compileNotification (from, idFrom, HDN_GETDISPINFO) = fromMLNmhdr(from, idFrom, ~309)
            |  compileNotification (from, idFrom, TVN_SELCHANGING) = fromMLNmhdr(from, idFrom, ~401)
            |  compileNotification (from, idFrom, TVN_SELCHANGED) = fromMLNmhdr(from, idFrom, ~402)
            |  compileNotification (from, idFrom, TVN_GETDISPINFO) = fromMLNmhdr(from, idFrom, ~403)
            |  compileNotification (from, idFrom, TVN_SETDISPINFO) = fromMLNmhdr(from, idFrom, ~404)
            |  compileNotification (from, idFrom, TVN_ITEMEXPANDING) = fromMLNmhdr(from, idFrom, ~405)
            |  compileNotification (from, idFrom, TVN_ITEMEXPANDED) = fromMLNmhdr(from, idFrom, ~406)
            |  compileNotification (from, idFrom, TVN_BEGINDRAG) = fromMLNmhdr(from, idFrom, ~407)
            |  compileNotification (from, idFrom, TVN_BEGINRDRAG) = fromMLNmhdr(from, idFrom, ~408)
            |  compileNotification (from, idFrom, TVN_DELETEITEM) = fromMLNmhdr(from, idFrom, ~409)
            |  compileNotification (from, idFrom, TVN_BEGINLABELEDIT) = fromMLNmhdr(from, idFrom, ~410)
            |  compileNotification (from, idFrom, TVN_ENDLABELEDIT) = fromMLNmhdr(from, idFrom, ~411)
            |  compileNotification (from, idFrom, TVN_KEYDOWN) = fromMLNmhdr(from, idFrom, ~412)
            |  compileNotification (from, idFrom, TVN_GETINFOTIP) = fromMLNmhdr(from, idFrom, ~413)
            |  compileNotification (from, idFrom, TVN_SINGLEEXPAND) = fromMLNmhdr(from, idFrom, ~415)
            |  compileNotification (from, idFrom, TTN_GETDISPINFO(ref s)) =
                   fromMLNMTTDISPINFO((from, idFrom, ~520), Memory.null, s, Globals.hNull, 0, 0)
            |  compileNotification (from, idFrom, TTN_SHOW) = fromMLNmhdr(from, idFrom, ~521)
            |  compileNotification (from, idFrom, TTN_POP) = fromMLNmhdr(from, idFrom, ~522)
            |  compileNotification (from, idFrom, TCN_KEYDOWN) = fromMLNmhdr(from, idFrom, ~550)
            |  compileNotification (from, idFrom, TCN_SELCHANGE) = fromMLNmhdr(from, idFrom, ~551)
            |  compileNotification (from, idFrom, TCN_SELCHANGING) = fromMLNmhdr(from, idFrom, ~552)
            |  compileNotification (from, idFrom, TBN_GETBUTTONINFO) = fromMLNmhdr(from, idFrom, ~700)
            |  compileNotification (from, idFrom, TBN_BEGINDRAG) = fromMLNmhdr(from, idFrom, ~701)
            |  compileNotification (from, idFrom, TBN_ENDDRAG) = fromMLNmhdr(from, idFrom, ~702)
            |  compileNotification (from, idFrom, TBN_BEGINADJUST) = fromMLNmhdr(from, idFrom, ~703)
            |  compileNotification (from, idFrom, TBN_ENDADJUST) = fromMLNmhdr(from, idFrom, ~704)
            |  compileNotification (from, idFrom, TBN_RESET) = fromMLNmhdr(from, idFrom, ~705)
            |  compileNotification (from, idFrom, TBN_QUERYINSERT) = fromMLNmhdr(from, idFrom, ~706)
            |  compileNotification (from, idFrom, TBN_QUERYDELETE) = fromMLNmhdr(from, idFrom, ~707)
            |  compileNotification (from, idFrom, TBN_TOOLBARCHANGE) = fromMLNmhdr(from, idFrom, ~708)
            |  compileNotification (from, idFrom, TBN_CUSTHELP) = fromMLNmhdr(from, idFrom, ~709)
            |  compileNotification (from, idFrom, TBN_DROPDOWN) = fromMLNmhdr(from, idFrom, ~710)
            |  compileNotification (from, idFrom, TBN_HOTITEMCHANGE) = fromMLNmhdr(from, idFrom, ~713)
            |  compileNotification (from, idFrom, TBN_DRAGOUT) = fromMLNmhdr(from, idFrom, ~714)
            |  compileNotification (from, idFrom, TBN_DELETINGBUTTON) = fromMLNmhdr(from, idFrom, ~715)
            |  compileNotification (from, idFrom, TBN_GETDISPINFO) = fromMLNmhdr(from, idFrom, ~716)
            |  compileNotification (from, idFrom, TBN_GETINFOTIP) = fromMLNmhdr(from, idFrom, ~718)   
            |  compileNotification (from, idFrom, UDN_DELTAPOS) = fromMLNmhdr(from, idFrom, ~722)
            |  compileNotification (from, idFrom, RBN_GETOBJECT) = fromMLNmhdr(from, idFrom, ~832)
            |  compileNotification (from, idFrom, RBN_LAYOUTCHANGED) = fromMLNmhdr(from, idFrom, ~833)
            |  compileNotification (from, idFrom, RBN_AUTOSIZE) = fromMLNmhdr(from, idFrom, ~834)
            |  compileNotification (from, idFrom, RBN_BEGINDRAG) = fromMLNmhdr(from, idFrom, ~835)
            |  compileNotification (from, idFrom, RBN_ENDDRAG) = fromMLNmhdr(from, idFrom, ~836)
            |  compileNotification (from, idFrom, RBN_DELETINGBAND) = fromMLNmhdr(from, idFrom, ~837)
            |  compileNotification (from, idFrom, RBN_DELETEDBAND) = fromMLNmhdr(from, idFrom, ~838)
            |  compileNotification (from, idFrom, RBN_CHILDSIZE) = fromMLNmhdr(from, idFrom, ~839)
            |  compileNotification (from, idFrom, CBEN_GETDISPINFO) = fromMLNmhdr(from, idFrom, ~800)
            |  compileNotification (from, idFrom, CBEN_DRAGBEGIN) = fromMLNmhdr(from, idFrom, ~808)
            |  compileNotification (from, idFrom, IPN_FIELDCHANGED) = fromMLNmhdr(from, idFrom, ~860)
            |  compileNotification (from, idFrom, SBN_SIMPLEMODECHANGE) = fromMLNmhdr(from, idFrom, ~880)
            |  compileNotification (from, idFrom, PGN_SCROLL) = fromMLNmhdr(from, idFrom, ~901)
            |  compileNotification (from, idFrom, PGN_CALCSIZE) = fromMLNmhdr(from, idFrom, ~902)

            |  compileNotification (from, idFrom, NM_OTHER code) = fromMLNmhdr(from, idFrom, code)

            local
                fun decompileNotifyArg (_,   ~1) = NM_OUTOFMEMORY
                 |  decompileNotifyArg (_,   ~2) = NM_CLICK
                 |  decompileNotifyArg (_,   ~3) = NM_DBLCLK
                 |  decompileNotifyArg (_,   ~4) = NM_RETURN
                 |  decompileNotifyArg (_,   ~5) = NM_RCLICK
                 |  decompileNotifyArg (_,   ~6) = NM_RDBLCLK
                 |  decompileNotifyArg (_,   ~7) = NM_SETFOCUS
                 |  decompileNotifyArg (_,   ~8) = NM_KILLFOCUS
                 |  decompileNotifyArg (_,  ~12) = NM_CUSTOMDRAW
                 |  decompileNotifyArg (_,  ~13) = NM_HOVER
                 |  decompileNotifyArg (_,  ~14) = NM_NCHITTEST
                 |  decompileNotifyArg (_,  ~15) = NM_KEYDOWN
                 |  decompileNotifyArg (_,  ~16) = NM_RELEASEDCAPTURE
                 |  decompileNotifyArg (_,  ~17) = NM_SETCURSOR
                 |  decompileNotifyArg (_,  ~18) = NM_CHAR
                 |  decompileNotifyArg (_,  ~19) = NM_TOOLTIPSCREATED
                 |  decompileNotifyArg (_,  ~20) = NM_LDOWN
                 |  decompileNotifyArg (_,  ~21) = NM_RDOWN
                 |  decompileNotifyArg (_,  ~22) = NM_THEMECHANGED
                 |  decompileNotifyArg (_, ~100) = LVN_ITEMCHANGING
                 |  decompileNotifyArg (_, ~101) = LVN_ITEMCHANGED
                 |  decompileNotifyArg (_, ~102) = LVN_INSERTITEM
                 |  decompileNotifyArg (_, ~103) = LVN_DELETEITEM
                 |  decompileNotifyArg (_, ~104) = LVN_DELETEALLITEMS
                 |  decompileNotifyArg (_, ~105) = LVN_BEGINLABELEDIT
                 |  decompileNotifyArg (_, ~106) = LVN_ENDLABELEDIT
                 |  decompileNotifyArg (_, ~108) = LVN_COLUMNCLICK
                 |  decompileNotifyArg (_, ~109) = LVN_BEGINDRAG
                 |  decompileNotifyArg (_, ~111) = LVN_BEGINRDRAG
                 |  decompileNotifyArg (_, ~150) = LVN_GETDISPINFO
                 |  decompileNotifyArg (_, ~151) = LVN_SETDISPINFO
                 |  decompileNotifyArg (_, ~155) = LVN_KEYDOWN
                 |  decompileNotifyArg (_, ~157) = LVN_GETINFOTIP
                 |  decompileNotifyArg (_, ~300) = HDN_ITEMCHANGING
                 |  decompileNotifyArg (_, ~301) = HDN_ITEMCHANGED
                 |  decompileNotifyArg (_, ~302) = HDN_ITEMCLICK
                 |  decompileNotifyArg (_, ~303) = HDN_ITEMDBLCLICK
                 |  decompileNotifyArg (_, ~305) = HDN_DIVIDERDBLCLICK
                 |  decompileNotifyArg (_, ~306) = HDN_BEGINTRACK
                 |  decompileNotifyArg (_, ~307) = HDN_ENDTRACK
                 |  decompileNotifyArg (_, ~308) = HDN_TRACK
                 |  decompileNotifyArg (_, ~311) = HDN_ENDDRAG
                 |  decompileNotifyArg (_, ~310) = HDN_BEGINDRAG
                 |  decompileNotifyArg (_, ~309) = HDN_GETDISPINFO
                 |  decompileNotifyArg (_, ~401) = TVN_SELCHANGING
                 |  decompileNotifyArg (_, ~402) = TVN_SELCHANGED
                 |  decompileNotifyArg (_, ~403) = TVN_GETDISPINFO
                 |  decompileNotifyArg (_, ~404) = TVN_SETDISPINFO
                 |  decompileNotifyArg (_, ~405) = TVN_ITEMEXPANDING
                 |  decompileNotifyArg (_, ~406) = TVN_ITEMEXPANDED
                 |  decompileNotifyArg (_, ~407) = TVN_BEGINDRAG
                 |  decompileNotifyArg (_, ~408) = TVN_BEGINRDRAG
                 |  decompileNotifyArg (_, ~409) = TVN_DELETEITEM
                 |  decompileNotifyArg (_, ~410) = TVN_BEGINLABELEDIT
                 |  decompileNotifyArg (_, ~411) = TVN_ENDLABELEDIT
                 |  decompileNotifyArg (_, ~412) = TVN_KEYDOWN
                 |  decompileNotifyArg (_, ~413) = TVN_GETINFOTIP
                 |  decompileNotifyArg (_, ~415) = TVN_SINGLEEXPAND
                 |  decompileNotifyArg (lp, ~520) =
                     let
                         val nmt = toMLNMTTDISPINFO lp
                         (* Just look at the byte data at the moment. *)
                     in
                         TTN_GETDISPINFO(ref(#3 nmt))
                     end
                 |  decompileNotifyArg (_, ~521) = TTN_SHOW
                 |  decompileNotifyArg (_, ~522) = TTN_POP
                 |  decompileNotifyArg (_, ~550) = TCN_KEYDOWN
                 |  decompileNotifyArg (_, ~551) = TCN_SELCHANGE
                 |  decompileNotifyArg (_, ~552) = TCN_SELCHANGING
                 |  decompileNotifyArg (_, ~700) = TBN_GETBUTTONINFO
                 |  decompileNotifyArg (_, ~701) = TBN_BEGINDRAG
                 |  decompileNotifyArg (_, ~702) = TBN_ENDDRAG
                 |  decompileNotifyArg (_, ~703) = TBN_BEGINADJUST
                 |  decompileNotifyArg (_, ~704) = TBN_ENDADJUST
                 |  decompileNotifyArg (_, ~705) = TBN_RESET
                 |  decompileNotifyArg (_, ~706) = TBN_QUERYINSERT
                 |  decompileNotifyArg (_, ~707) = TBN_QUERYDELETE
                 |  decompileNotifyArg (_, ~708) = TBN_TOOLBARCHANGE
                 |  decompileNotifyArg (_, ~709) = TBN_CUSTHELP
                 |  decompileNotifyArg (_, ~710) = TBN_DROPDOWN
                 |  decompileNotifyArg (_, ~713) = TBN_HOTITEMCHANGE
                 |  decompileNotifyArg (_, ~714) = TBN_DRAGOUT
                 |  decompileNotifyArg (_, ~715) = TBN_DELETINGBUTTON
                 |  decompileNotifyArg (_, ~716) = TBN_GETDISPINFO
                 |  decompileNotifyArg (_, ~718) = TBN_GETINFOTIP (*<<<*)
                 |  decompileNotifyArg (_, ~722) = UDN_DELTAPOS
                 |  decompileNotifyArg (_, ~832) = RBN_GETOBJECT
                 |  decompileNotifyArg (_, ~833) = RBN_LAYOUTCHANGED
                 |  decompileNotifyArg (_, ~834) = RBN_AUTOSIZE
                 |  decompileNotifyArg (_, ~835) = RBN_BEGINDRAG
                 |  decompileNotifyArg (_, ~836) = RBN_ENDDRAG
                 |  decompileNotifyArg (_, ~837) = RBN_DELETINGBAND
                 |  decompileNotifyArg (_, ~838) = RBN_DELETEDBAND
                 |  decompileNotifyArg (_, ~839) = RBN_CHILDSIZE
                 |  decompileNotifyArg (_, ~800) = CBEN_GETDISPINFO
                 |  decompileNotifyArg (_, ~808) = CBEN_DRAGBEGIN
                 |  decompileNotifyArg (_, ~860) = IPN_FIELDCHANGED
                 |  decompileNotifyArg (_, ~880) = SBN_SIMPLEMODECHANGE
                 |  decompileNotifyArg (_, ~901) = PGN_SCROLL
                 |  decompileNotifyArg (_, ~902) = PGN_CALCSIZE     
                 |  decompileNotifyArg (_, code) = NM_OTHER code
            in
                fun decompileNotify {wp, lp} =
                let
                    val (hwndFrom, idFrom, code) = toMLNmhdr lp
                    val notification = decompileNotifyArg (lp, code)
                in
                    { idCtrl = SysWord.toInt wp, from = hwndFrom, idFrom = idFrom, notification = notification}
                end
            end

        end
        
        local
            val cFINDREPLACE =
                cStruct11(cDWORD, cHWND, cHINSTANCE, FindReplaceFlags.cFindReplaceFlags, cString, cString,
                          cWORD, cWORD, cPointer, cPointer, cPointer)
            val {load=loadFindReplace, store=storeFindReplace, ctype={size=sizeFindReplace, ...}, ...} =
                breakConversion cFINDREPLACE
            type findMsg = { flags: FindReplaceFlags.flags, findWhat: string, replaceWith: string }
        in
            fun compileFindMsg({flags, findWhat, replaceWith}: findMsg) =
            let
                open Memory
                val vec = malloc sizeFindReplace
                (* Is this right?  It's supposed to create a buffer to store the result. *)
                val freeFR =
                    storeFindReplace(vec,
                        (Word.toInt sizeFindReplace, hNull, hNull, flags,
                         findWhat, replaceWith, 0, 0, null, null, null))
            in
                (RegisterMessage "commdlg_FindReplace", 0w0, fromAddr vec, fn() => (freeFR(); free vec))
            end
            
            fun decompileFindMsg{wp=_, lp}: findMsg =
            let
                val (_, _, _, flags, findwhat, replace, _, _, _, _, _) =
                    loadFindReplace(toAddr lp)
                (* The argument is really a FINDREPLACE struct. *)
            in
                {flags=flags, findWhat=findwhat, replaceWith=replace}
            end
        end
        
        val toHMENU: SysWord.word -> HMENU = handleOfVoidStar o Memory.sysWord2VoidStar
        and fromHMENU: HMENU -> SysWord.word = Memory.voidStar2Sysword o voidStarOfHandle
        val toHWND: SysWord.word -> HWND = handleOfVoidStar o Memory.sysWord2VoidStar
        and fromHWND: HWND -> SysWord.word = Memory.voidStar2Sysword o voidStarOfHandle
        val toHDC: SysWord.word -> HDC = handleOfVoidStar o Memory.sysWord2VoidStar
        and fromHDC: HDC -> SysWord.word = Memory.voidStar2Sysword o voidStarOfHandle
        val toHFONT: SysWord.word -> HFONT = handleOfVoidStar o Memory.sysWord2VoidStar
        and fromHFONT: HFONT -> SysWord.word = Memory.voidStar2Sysword o voidStarOfHandle
        val toHRGN: SysWord.word -> HRGN = handleOfVoidStar o Memory.sysWord2VoidStar
        and fromHRGN: HRGN -> SysWord.word = Memory.voidStar2Sysword o voidStarOfHandle
        val toHDROP: SysWord.word -> HDROP = handleOfVoidStar o Memory.sysWord2VoidStar
        and fromHDROP: HDROP -> SysWord.word = Memory.voidStar2Sysword o voidStarOfHandle
        val toHICON: SysWord.word -> HICON = handleOfVoidStar o Memory.sysWord2VoidStar
        and fromHICON: HICON -> SysWord.word = Memory.voidStar2Sysword o voidStarOfHandle
        val toHGDIOBJ: SysWord.word -> HGDIOBJ = handleOfVoidStar o Memory.sysWord2VoidStar
        and fromHGDIOBJ: HGDIOBJ -> SysWord.word = Memory.voidStar2Sysword o voidStarOfHandle

        (* Maybe we should have two different types for horizontal and vertical. *)
        datatype ScrollDirection =
            SB_BOTTOM | SB_ENDSCROLL | SB_LINEDOWN | SB_LINEUP | SB_PAGEDOWN | SB_PAGEUP |
            SB_THUMBPOSITION | SB_THUMBTRACK | SB_TOP | SB_LEFT | SB_RIGHT | SB_LINELEFT |
            SB_LINERIGHT | SB_PAGELEFT | SB_PAGERIGHT
        local
            val tab = [
                (SB_LINEUP,     0w0: word),
                (SB_LINELEFT,   0w0),
                (SB_LINEDOWN,   0w1),
                (SB_LINERIGHT,  0w1),
                (SB_PAGEUP,     0w2),
                (SB_PAGELEFT,   0w2),
                (SB_PAGEDOWN,   0w3),
                (SB_PAGERIGHT,  0w3),
                (SB_THUMBPOSITION, 0w4),
                (SB_THUMBTRACK, 0w5),
                (SB_TOP,        0w6),
                (SB_LEFT,       0w6),
                (SB_BOTTOM,     0w7),
                (SB_RIGHT,      0w7),
                (SB_ENDSCROLL,  0w8)
                ]
        in
            val (toCsd, fromCsd) = tableLookup(tab, NONE)
        end

        (* This is a bit of a mess.  Various operations take or return handles to
           these types of image and also take this value as a parameter. *)
        datatype ImageType = IMAGE_BITMAP | IMAGE_CURSOR | IMAGE_ENHMETAFILE | IMAGE_ICON
    
        local
            val tab = [
                (IMAGE_BITMAP, 0),
                (IMAGE_ICON, 1),
                (IMAGE_CURSOR, 2),
                (IMAGE_ENHMETAFILE, 3)
                ]
        in
            val (toCit, fromCit) = tableLookup(tab, NONE)
        end

        val (toCcbf, fromCcbf) = clipLookup
        datatype MouseKeyFlags = MK_LBUTTON | MK_RBUTTON | MK_SHIFT | MK_CONTROL | MK_MBUTTON

        local
            val tab = [
                (MK_LBUTTON,        0wx0001),
                (MK_RBUTTON,        0wx0002),
                (MK_SHIFT,          0wx0004),
                (MK_CONTROL,        0wx0008),
                (MK_MBUTTON,        0wx0010)
                ]
        in
            val (toCmkf, fromCmkf) = tableSetLookup(tab, NONE)
        end
        

        datatype MDITileFlags = MDITILE_VERTICAL | MDITILE_HORIZONTAL | MDITILE_SKIPDISABLED

        local
            val tab = [
                (MDITILE_VERTICAL,      0wx0000),
                (MDITILE_HORIZONTAL,    0wx0001),
                (MDITILE_SKIPDISABLED,  0wx0002)
                ]
        in
            val (toCmdif, fromCmdif) = tableSetLookup(tab, NONE)
        end

        datatype WMPrintOption = 
            PRF_CHECKVISIBLE | PRF_NONCLIENT | PRF_CLIENT | PRF_ERASEBKGND |
            PRF_CHILDREN | PRF_OWNED

        local
            val tab = [
                (PRF_CHECKVISIBLE,      0wx00000001),
                (PRF_NONCLIENT,         0wx00000002),
                (PRF_CLIENT,            0wx00000004),
                (PRF_ERASEBKGND,        0wx00000008),
                (PRF_CHILDREN,          0wx00000010),
                (PRF_OWNED,             0wx00000020)
                ]
        in
            val (toCwmpl, fromCwmpl) = tableSetLookup(tab, NONE)
        end

        val (toCcbal, fromCcbal) = ComboBase.CBDIRATTRS
        val (toCesbf, fromCesbf) = ScrollBase.ENABLESCROLLBARFLAG

        (*fun itob i = i <> 0*)
        
        (* These deal with signed quantities.  LOWORD/HIWORD deal with words *)
        local
            val shift32 = Word.fromInt(SysWord.wordSize-32)
            and shift16 = Word.fromInt(SysWord.wordSize-16)
            open SysWord
            infix 5 << ~>>
            infix 7 andb
            infix 6 orb
            (* Y is the high order word, X is the low order word. *)
        in
            fun getYLParam (i: SysWord.word) = toIntX((i << shift32) ~>> shift16)
            and getXLParam (i: SysWord.word) = toIntX((i << shift16) ~>> shift16)
            
            fun makeXYParam (x, y) = ((fromInt y andb 0wxffff) << 0w16) orb (fromInt x andb 0wxffff)
        end
    in
        type flags = WinBase.Style.flags
        and WindowPositionStyle = WinBase.WindowPositionStyle
        
        datatype ControlType = datatype ControlType
        datatype ScrollDirection = datatype ScrollDirection

        datatype HitTest =
            HTBORDER
        |   HTBOTTOM
        |   HTBOTTOMLEFT
        |   HTBOTTOMRIGHT
        |   HTCAPTION
        |   HTCLIENT
        |   HTCLOSE
        |   HTERROR
        |   HTGROWBOX
        |   HTHELP
        |   HTHSCROLL
        |   HTLEFT
        |   HTMENU
        |   HTMAXBUTTON
        |   HTMINBUTTON
        |   HTNOWHERE
        |   HTREDUCE
        |   HTRIGHT
        |   HTSIZE
        |   HTSYSMENU
        |   HTTOP
        |   HTTOPLEFT
        |   HTTOPRIGHT
        |   HTTRANSPARENT
        |   HTVSCROLL
        |   HTZOOM

        datatype LRESULT =
            LRESINT of int
        |   LRESHANDLE of HGDIOBJ

        datatype ImageType = datatype ImageType

        (* WM_SIZE options. *)
        datatype WMSizeOptions =
            SIZE_RESTORED | SIZE_MINIMIZED | SIZE_MAXIMIZED | SIZE_MAXSHOW | SIZE_MAXHIDE
        local
            val tab = [
                (SIZE_RESTORED,       0w0: SysWord.word),
                (SIZE_MINIMIZED,      0w1),
                (SIZE_MAXIMIZED,      0w2),
                (SIZE_MAXSHOW,        0w3),
                (SIZE_MAXHIDE,        0w4)
                ]
        in
            val (fromWMSizeOpt, toWMSizeOpt) = tableLookup(tab, NONE)
        end

        (* WM_ACTIVATE options *)
        datatype WMActivateOptions = WA_INACTIVE | WA_ACTIVE | WA_CLICKACTIVE
        local
            val 
            tab = [
                (WA_INACTIVE,       0w0: word),
                (WA_ACTIVE,         0w1),
                (WA_CLICKACTIVE,    0w2)
                ]
        in
            val (fromWMactive, toWMactive) = tableLookup(tab, NONE)
        end

        datatype SystemCommand =
            SC_SIZE | SC_MOVE | SC_MINIMIZE | SC_MAXIMIZE | SC_NEXTWINDOW | SC_PREVWINDOW |
            SC_CLOSE | SC_VSCROLL | SC_HSCROLL | SC_MOUSEMENU | SC_KEYMENU | SC_ARRANGE |
            SC_RESTORE | SC_TASKLIST | SC_SCREENSAVE | SC_HOTKEY | SC_DEFAULT |
            SC_MONITORPOWER | SC_CONTEXTHELP | SC_SEPARATOR
        local
            val tab = [
                (SC_SIZE,           0xF000),
                (SC_MOVE,           0xF010),
                (SC_MINIMIZE,       0xF020),
                (SC_MAXIMIZE,       0xF030),
                (SC_NEXTWINDOW,     0xF040),
                (SC_PREVWINDOW,     0xF050),
                (SC_CLOSE,          0xF060),
                (SC_VSCROLL,        0xF070),
                (SC_HSCROLL,        0xF080),
                (SC_MOUSEMENU,      0xF090),
                (SC_KEYMENU,        0xF100),
                (SC_ARRANGE,        0xF110),
                (SC_RESTORE,        0xF120),
                (SC_TASKLIST,       0xF130),
                (SC_SCREENSAVE,     0xF140),
                (SC_HOTKEY,         0xF150),
                (SC_DEFAULT,        0xF160),
                (SC_MONITORPOWER,   0xF170),
                (SC_CONTEXTHELP,    0xF180)]
        in
            val (fromSysCommand, toSysCommand) = tableLookup(tab, NONE)
        end

        datatype EMCharFromPos =
            EMcfpEdit of POINT
        |   EMcfpRichEdit of POINT
        |   EMcfpUnknown of SysWord.word

        datatype WMPrintOption = datatype WMPrintOption

        (* Parameters to EM_SETMARGINS. *)
        datatype MarginSettings = 
            UseFontInfo | Margins of {left: int option, right: int option }

        datatype MouseKeyFlags = datatype MouseKeyFlags
        datatype MDITileFlags = datatype MDITileFlags

        (* TODO: Perhaps use a record for this.  It's always possible to use
           functions from Word32 though. *)
        type KeyData = Word32.word
        datatype Notification = datatype Notification
        datatype HelpHandle = datatype HelpHandle

        local
            val tab =
            [
                (HTBORDER,      18),
                (HTBOTTOM,      15),
                (HTBOTTOMLEFT,  16),
                (HTBOTTOMRIGHT, 17),
                (HTCAPTION,     2),
                (HTCLIENT,      1),
                (HTCLOSE,       20),
                (HTERROR,       ~2),
                (HTGROWBOX,     4),
                (HTHELP,        21),
                (HTHSCROLL,     6),
                (HTLEFT,        10),
                (HTMENU,        5),
                (HTMAXBUTTON,   9),
                (HTMINBUTTON,   8),
                (HTNOWHERE,     0),
                (HTREDUCE,      8),
                (HTRIGHT,       11),
                (HTSIZE,        4),
                (HTSYSMENU,     3),
                (HTTOP,         12),
                (HTTOPLEFT,     13),
                (HTTOPRIGHT,    14),
                (HTTRANSPARENT, ~1),
                (HTVSCROLL,     7),
                (HTZOOM,        9)
            ]
        in
            val (fromHitTest, toHitTest) =
                tableLookup(tab, SOME(fn _ => HTERROR, fn _ => ~2))
                    (* Include default just in case a new value is added some time *)
        end


        type findReplaceFlags = FindReplaceFlags.flags
        type windowFlags = flags

        datatype Message     =
            WM_NULL

        |   WM_ACTIVATE of {active: WMActivateOptions, minimize: bool }
                  (* Indicates a change in activation state *)

        |   WM_ACTIVATEAPP of {active: bool, threadid: int  } 
          (* Notifies applications when a new task activates *)

        |   WM_ASKCBFORMATNAME of { length: int, formatName: string ref} 
          (* Retrieves the name of the clipboard format *)

        |   WM_CANCELJOURNAL  
          (* Notifies application when user cancels journaling *)

        |   WM_CANCELMODE 
          (* Notifies a Window to cancel internal modes *)

        |   WM_CHANGECBCHAIN of { removed: HWND, next: HWND  }  
          (* Notifies clipboard viewer of removal from chain *)

        |   WM_CHAR of {charCode: char, data: KeyData }                     
          (* Indicates the user pressed a character key *)

        |   WM_CHARTOITEM of {key: int, caretpos: int, listbox: HWND  }
          (* Provides list-box keystrokes to owner Window *)

        |   WM_CHILDACTIVATE  
          (* Notifies a child Window of activation *)

        (* This is WM_USER+1.  It's only used in a GetFont dialogue box.
        |   WM_CHOOSEFONT_GETLOGFONT of LOGFONT ref *)
          (* Retrieves LOGFONT structure for Font dialog box *)

        |   WM_CLEAR
          (* Clears an edit control *)

        |   WM_CLOSE      
          (* System Close menu command was chosen *)

        |   WM_COMMAND of {notifyCode: int, wId: int, control: HWND }
          (* Specifies a command message *)

        |   WM_COMPAREITEM of (* Determines position of combo- or list-box item *)
            {
                controlid: int, ctlType: ControlType, ctlID: int, hItem: HWND,
                itemID1: int, itemData1: SysWord.word, itemID2: int, itemData2: SysWord.word                                        
            }

        |   WM_COPY (* Copies a selection to the clipboard *)

        |   WM_CREATE of
            { instance: HINSTANCE, creation: Foreign.Memory.voidStar, menu: HMENU, parent: HWND, cy: int, cx: int,
              y: int, x: int, style: windowFlags, name: string, (* The class may be a string or an atom. *)
              class: ClassType, extendedstyle: int }
          (* Indicates a Window is being created *)

        |   WM_CTLCOLORBTN of { displaycontext: HDC, button: HWND }
          (* Button is about to be drawn *)

        |   WM_CTLCOLORDLG of { displaycontext: HDC, dialogbox: HWND  }
          (* Dialog box is about to be drawn *)

        |   WM_CTLCOLOREDIT of {  displaycontext: HDC, editcontrol: HWND  }
          (* Control is about to be drawn *)

        |   WM_CTLCOLORLISTBOX of { displaycontext: HDC, listbox: HWND   }
          (* List box is about to be drawn *)

        |   WM_CTLCOLORMSGBOX of { displaycontext: HDC, messagebox: HWND  }
          (* Message box is about to be drawn *)

        |   WM_CTLCOLORSCROLLBAR of { displaycontext: HDC, scrollbar: HWND  }
          (* Indicates scroll bar is about to be drawn *)

        |   WM_CTLCOLORSTATIC of { displaycontext: HDC, staticcontrol: HWND }
          (* Control is about to be drawn *)
          (* Note the return value is an HBRUSH *)

        |   WM_CUT
          (* Deletes a selection and copies it to the clipboard *)

        |   WM_DEADCHAR of { charCode: char, data: KeyData }
          (* Indicates the user pressed a dead key *)

        |   WM_DELETEITEM of { senderId: int, ctlType: ControlType, ctlID: int, itemID: int, item: HWND, itemData: int }
          (* Indicates owner-draw item or control was altered *)

        |   WM_DESTROY    
          (* Indicates Window is about to be destroyed *)

        |   WM_DESTROYCLIPBOARD   
          (* Notifies owner that the clipboard was emptied *)

        |   WM_DEVMODECHANGE of { devicename: string }   
          (* Indicates the device-mode settings have changed *)

        |   WM_DRAWCLIPBOARD  
          (* Indicates the clipboard's contents have changed *) 

        |   WM_DRAWITEM of
                { senderId: int, ctlType: ControlType, ctlID: int, itemID: int, itemAction: int,
                  itemState: int, hItem: HWND , hDC: HDC, rcItem: RECT, itemData: int }   
          (* Indicates owner-draw control/menu needs redrawing *) 

        |   WM_DROPFILES of { hDrop: HDROP } 
          (* Indicates that a file has been dropped *)

        |   WM_ENABLE of { enabled: bool }
          (* Indicates a Window's enable state is changing *)

        |   WM_ENDSESSION of { endsession: bool }
          (* Indicates whether the Windows session is ending *)

        |   WM_ENTERIDLE of { flag: int, window: HWND }
          (* Indicates a modal dialog box or menu is idle *)

        |   WM_ENTERMENULOOP of { istrack: bool }
          (* Indicates entry into menu modal loop *)

        |   WM_EXITMENULOOP of { istrack: bool }
          (* Indicates exit from menu modal loop *)

        |   WM_ERASEBKGND of { devicecontext: HDC }
          (* Indicates a Window's background need erasing *)

        |   WM_FONTCHANGE
          (* Indicates a change in the font-resource pool *)

        |   WM_GETDLGCODE
          (* Allows dialog procedure to process control input
             TODO: This has parameters! *)

        |   WM_GETFONT    
          (* Retrieves the font that a control is using *)

        |   WM_GETHOTKEY
          (* Gets the virtual-key code of a Window's hot key *) 

        |   WM_GETMINMAXINFO of
             { maxSize: POINT ref, maxPosition: POINT ref,
               minTrackSize: POINT ref, maxTrackSize: POINT ref }
          (* Gets minimum and maximum sizing information *)

        |   WM_GETTEXT of { length: int, text: string ref  } 
          (* Gets the text that corresponds to a Window *)

        |   WM_GETTEXTLENGTH  
          (* Gets length of text associated with a Window *)

        |   WM_HOTKEY of { id: int }
          (* Hot key has been detected *)

        |   WM_HSCROLL of { value: ScrollDirection, position: int, scrollbar: HWND  }    
          (* Indicates a click in a horizontal scroll bar *)

        |   WM_HSCROLLCLIPBOARD of { viewer: HWND, code: int, position: int  }    
          (* Prompts owner to scroll clipboard contents *)

        |   WM_ICONERASEBKGND of { devicecontext: HDC }
          (* Notifies minimized Window to fill icon background *)

        |   WM_INITDIALOG of { dialog: HWND, initdata: int  }
          (* Initializes a dialog box *)

        |   WM_INITMENU of { menu: HMENU }   
          (* Indicates a menu is about to become active *)

        |   WM_INITMENUPOPUP of { menupopup: HMENU, itemposition: int, isSystemMenu: bool  }
          (* Indicates a pop-up menu is being created *)

        |   WM_KEYDOWN of { virtualKey: int, data: KeyData  }   
          (* Indicates a nonsystem key was pressed *)

        |   WM_KEYUP of { virtualKey: int, data: KeyData  } 
          (* Indicates a nonsystem key was released *)

        |   WM_KILLFOCUS of { receivefocus: HWND }
          (* Indicates the Window is losing keyboard focus *)

        |   WM_LBUTTONDBLCLK of { keyflags: MouseKeyFlags list, x: int, y: int  }
          (* Indicates double-click of left button *) 

        |   WM_LBUTTONDOWN of { keyflags: MouseKeyFlags list, x: int, y: int  }
          (* Indicates when left mouse button is pressed *)

        |   WM_LBUTTONUP of { keyflags: MouseKeyFlags list, x: int, y: int  }
          (* Indicates when left mouse button is released *)

        |   WM_MBUTTONDBLCLK of { keyflags: MouseKeyFlags list, x: int, y: int  }
          (* Indicates double-click of middle mouse button *)

        |   WM_MBUTTONDOWN of { keyflags: MouseKeyFlags list, x: int, y: int  }
          (* Indicates when middle mouse button is pressed *)

        |   WM_MBUTTONUP of { keyflags: MouseKeyFlags list, x: int, y: int  }
          (* Indicates when middle mouse button is released *)
  
        |   WM_MDICASCADE of { skipDisabled: bool  } 
          (* Arranges MDI child Windows in cascade format *)

        |   WM_MDICREATE of
            { class: ClassType, title: string, instance: HINSTANCE, x: int, y: int,
              cx: int, cy: int, style: int, cdata: int }  
          (* Prompts MDI client to create a child Window *) 

        |   WM_MDIDESTROY of { child: HWND  }    
          (* Closes an MDI child Window *) 

        |   WM_MDIGETACTIVE
          (* Retrieves data about the active MDI child Window *) 

        |   WM_MDIICONARRANGE 
          (* Arranges minimized MDI child Windows *) 

        |   WM_MDIMAXIMIZE of {  child: HWND  }   
          (* Maximizes an MDI child Window *) 

        |   WM_MDINEXT of { child: HWND, flagnext: bool  }
          (* Activates the next MDI child Window *) 

        |   WM_MDIREFRESHMENU
          (* Refreshes an MDI frame Window's menu *) 

        |   WM_MDIRESTORE of {  child: HWND  }
          (* Prompts MDI client to restore a child Window *) 

        |   WM_MDISETMENU  of { frameMenu: HMENU, windowMenu: HMENU  } 
          (* Replaces an MDI frame Window's menu *) 

        |   WM_MDITILE of { tilingflag: MDITileFlags list }
          (* Arranges MDI child Windows in tiled format *) 

        |   WM_MEASUREITEM of
            { senderId: int, ctlType: ControlType, ctlID: int, itemID: int, itemWidth: int ref, itemHeight: int ref, itemData: int }  
          (* Requests dimensions of owner-draw control or item *)

        |   WM_MENUCHAR of { ch: char, menuflag: MenuBase.MenuFlag, menu: HMENU }  
          (* Indicates an unknown menu mnemonic was pressed *)

        |   WM_MENUSELECT of { menuitem: int, menuflags: MenuBase.MenuFlag list, menu: HMENU  }
          (* Indicates that the user selected a menu item *)

        |   WM_MOUSEACTIVATE of { parent: HWND, hitTest: HitTest, message: int }
          (* Indicates a mouse click in an inactive Window *) 

        |   WM_MOUSEMOVE of { keyflags: MouseKeyFlags list, x: int, y: int }  
          (* Indicates mouse-cursor movement *)

        |   WM_MOUSEHOVER of { keyflags: MouseKeyFlags list, x: int, y: int }
            (* Indicates the mouse hovering in the client area *)
    
        |   WM_MOUSELEAVE
            (* Indicates the mouse leaving the client area *)

        |   WM_MOVE of { x: int, y: int  }  
          (* Indicates a Window's position has changed *)

        |   WM_NCACTIVATE of { active: bool }
          (* Changes the active state of nonclient area *)

        |   WM_NCCALCSIZE of
            { validarea: bool, newrect: RECT ref, oldrect: RECT, oldclientarea: RECT,
              hwnd: HWND, insertAfter: HWND, x: int, y: int, cx: int, cy: int, style: WindowPositionStyle list}
          (* Calculates the size of a Window's client area *)

        |   WM_NCCREATE of
            { instance: HINSTANCE, creation: Foreign.Memory.voidStar, menu: HMENU, parent: HWND, cy: int, cx: int,
              y: int, x: int, style: windowFlags, name: string, class: ClassType, extendedstyle: int } 
          (* Indicates a Window's nonclient area being created *)

        |   WM_NCDESTROY  
          (* Indicates Window's nonclient area being destroyed *)

        |   WM_NCHITTEST of { x: int, y: int  } 
          (* Indicates mouse-cursor movement *)

        |   WM_NCLBUTTONDBLCLK of { hitTest: HitTest, x: int, y: int  }    
          (* Indicates nonclient left button double-click *)

        |   WM_NCLBUTTONDOWN  of { hitTest: HitTest, x: int, y: int  } 
          (* Indicates left button pressed in nonclient area *)

        |   WM_NCLBUTTONUP of { hitTest: HitTest, x: int, y: int  }    
          (* Indicates left button released in nonclient area *)

        |   WM_NCMBUTTONDBLCLK of { hitTest: HitTest, x: int, y: int  }    
          (* Indicates nonclient middle button double-click *)

        |   WM_NCMBUTTONDOWN of { hitTest: HitTest, x: int, y: int  }  
          (* Indicates middle button pressed in nonclient area *)

        |   WM_NCMBUTTONUP of { hitTest: HitTest, x: int, y: int  }    
          (* Indicates middle button released in nonclient area *)

        |   WM_NCMOUSEMOVE of { hitTest: HitTest, x: int, y: int  }    
          (* Indicates mouse-cursor movement in nonclient area *)

        |   WM_NCMOUSEHOVER of { hitTest: HitTest, x: int, y: int  }
            (* Indicates the mouse hovering in the nonclient area *)
    
        |   WM_NCMOUSELEAVE
            (* Indicates the mouse leaving the nonclient area *)

        |   WM_NCPAINT of { region: HRGN  }  
          (* Indicates a Window's frame needs painting *)

        |   WM_NCRBUTTONDBLCLK of { hitTest: HitTest, x: int, y: int  }    
          (* Indicates nonclient right button double-click *)

        |   WM_NCRBUTTONDOWN of { hitTest: HitTest, x: int, y: int  }  
          (* Indicates right button pressed in nonclient area *)

        |   WM_NCRBUTTONUP of { hitTest: HitTest, x: int, y: int  }    
          (* Indicates right button released in nonclient area *)

        |   WM_NEXTDLGCTL of { control: int, handleflag: bool  } 
          (* Sets focus to different dialog box control *) 

        |   WM_PAINT  
          (* Indicates a Window's client area need painting *)

        |   WM_PAINTCLIPBOARD of { clipboard: HWND }
          (* Prompts owner to display clipboard contents *)

        |   WM_PAINTICON
          (* Icon is about to be painted *) 

        |   WM_PALETTECHANGED of { palChg: HWND  }   
          (* Indicates the focus-Window realized its palette *)

        |   WM_PALETTEISCHANGING of { realize: HWND  }   
          (* Informs Windows that palette is changing *) 

        |   WM_PARENTNOTIFY of { eventflag: int, idchild: int, value: int }  
          (* Notifies parent of child-Window activity *) 

        |   WM_PASTE  
          (* Inserts clipboard data into an edit control *)

        |   WM_POWER of { powerevent: int  } 
          (* Indicates the system is entering suspended mode *)

        |   WM_QUERYDRAGICON  
          (* Requests a cursor handle for a minimized Window *)

        |   WM_QUERYENDSESSION of { source: int  }
          (* Requests that the Windows session be ended *) 

        |   WM_QUERYNEWPALETTE
          (* Allows a Window to realize its logical palette *) 

        |   WM_QUERYOPEN
          (* Requests that a minimized Window be restored *) 

        |   WM_QUEUESYNC
          (* Delimits CBT messages *) 

        |   WM_QUIT of { exitcode: int  }    
          (* Requests that an application be terminated *)

        |   WM_RBUTTONDBLCLK of { keyflags: MouseKeyFlags list, x: int, y: int  }    
          (* Indicates double-click of right mouse button *)

        |   WM_RBUTTONDOWN of { keyflags: MouseKeyFlags list, x: int, y: int  }  
          (* Indicates when right mouse button is pressed *)

        |   WM_RBUTTONUP of { keyflags: MouseKeyFlags list, x: int, y: int  }
          (* Indicates when right mouse button is released *) 

        |   WM_RENDERALLFORMATS   
          (* Notifies owner to render all clipboard formats *) 

        |   WM_RENDERFORMAT of { format: ClipboardFormat  }  
          (* Notifies owner to render clipboard data *) 

        |   WM_SETCURSOR of { cursorwindow: HWND, hitTest: HitTest, mousemessage: int }
          (* Prompts a Window to set the cursor shape *) 

        |   WM_SETFOCUS of { losing: HWND  }

        |   WM_SETFONT of {font: HFONT, redrawflag: bool  } 

        |   WM_SETHOTKEY of { virtualKey: int  } 

        |   WM_SETREDRAW of { redrawflag: bool  }

        |   WM_SETTEXT of { text: string  }  

        |   WM_SHOWWINDOW of { showflag: bool, statusflag: int  } 

        |   WM_SIZE of { flag: WMSizeOptions, width: int, height: int  }   

        |   WM_SIZECLIPBOARD of { viewer: HWND}

        |   WM_SYSCHAR of { charCode: char, data: KeyData  }

        |   WM_SYSCOLORCHANGE

        |   WM_SYSCOMMAND of { commandvalue: SystemCommand, sysBits: int, p: POINT }

        |   WM_SYSDEADCHAR of { charCode: char, data: KeyData  }

        |   WM_SYSKEYDOWN of { virtualKey: int, data: KeyData  }

        |   WM_SYSKEYUP of { virtualKey: int, data: KeyData  }

        |   WM_TIMECHANGE 
          (* Indicates the system time has been set *)

        |   WM_TIMER of { timerid: int  }

        |   WM_UNDO   

        |   WM_SYSTEM_OTHER of { uMsg: int, wParam: SysWord.word, lParam: SysWord.word }
        |   WM_USER of { uMsg: int, wParam: SysWord.word, lParam: SysWord.word }
        |   WM_APP of { uMsg: int, wParam: SysWord.word, lParam: SysWord.word }
        |   WM_REGISTERED of { uMsg: int, wParam: SysWord.word, lParam: SysWord.word }

        |   WM_VKEYTOITEM of { virtualKey: int,
                             caretpos: int,
                             listbox: HWND  }

        |   WM_VSCROLL of { value: ScrollDirection,
                          position: int,
                          scrollbar: HWND  }

        |   WM_VSCROLLCLIPBOARD of { viewer: HWND,
                                   code: int,
                                   position: int  }

        |   WM_WINDOWPOSCHANGED of
                { hwnd: HWND, front: HWND, x: int, y: int, width: int, height: int, flags: WindowPositionStyle list }

        |   WM_WINDOWPOSCHANGING of
                {
                    hwnd: HWND, front: HWND ref, x: int ref, y: int ref,
                    width: int ref, height: int ref, flags: WindowPositionStyle list ref
                }

        |   WM_NOTIFY of {from: HWND, idCtrl: int, idFrom: int, notification: Notification }

        |   WM_CAPTURECHANGED of { newCapture: HWND }

        |   WM_ENTERSIZEMOVE

        |   WM_EXITSIZEMOVE

        |   WM_PRINT of {hdc: HDC, flags: WMPrintOption list }

        |   WM_PRINTCLIENT of {hdc: HDC, flags: WMPrintOption list }

        |   WM_HELP of { ctrlId: int, itemHandle: HelpHandle, contextId: int, mousePos: POINT }

        |   WM_GETICON of { big: bool }

        |   WM_SETICON of { big: bool, icon: HICON }

        |   WM_CONTEXTMENU of { hwnd: HWND, xPos: int, yPos: int }

        |   WM_DISPLAYCHANGE of { bitsPerPixel: int, xScreen: int, yScreen: int }

        |   EM_CANUNDO

        |   EM_CHARFROMPOS of EMCharFromPos

        |   EM_EMPTYUNDOBUFFER

        |   EM_FMTLINES of {addEOL: bool}

        |   EM_GETFIRSTVISIBLELINE

        |   EM_GETLIMITTEXT

        |   EM_GETLINE of { lineNo: int, size: int, result: string ref }

        |   EM_GETLINECOUNT

        |   EM_GETMARGINS

        |   EM_GETMODIFY

        |   EM_GETPASSWORDCHAR

        |   EM_GETRECT of {rect: RECT ref}

        |   EM_GETSEL of {startPos: int ref, endPos: int ref}

        |   EM_GETTHUMB

        |   EM_LIMITTEXT of {limit: int}

        |   EM_LINEFROMCHAR of {index: int}

        |   EM_LINEINDEX of {line: int}

        |   EM_LINELENGTH of {index: int}

        |   EM_LINESCROLL of {xScroll: int, yScroll: int}

        |   EM_POSFROMCHAR of {index: int}

        |   EM_REPLACESEL of {canUndo: bool, text: string}

        |   EM_SCROLL of {action: ScrollDirection}

        |   EM_SCROLLCARET

        |   EM_SETMARGINS of {margins: MarginSettings}

        |   EM_SETMODIFY of { modified: bool }

        |   EM_SETPASSWORDCHAR of { ch: char }

        |   EM_SETREADONLY of { readOnly: bool }

        |   EM_SETRECT of {rect: RECT}

        |   EM_SETRECTNP of {rect: RECT}

        |   EM_SETSEL of {startPos: int, endPos: int}

        |   EM_SETTABSTOPS of {tabs: IntVector.vector}

        |   EM_UNDO

        |   BM_CLICK

        |   BM_GETCHECK

        |   BM_GETIMAGE of {imageType: ImageType}

        |   BM_GETSTATE

        |   BM_SETCHECK of {state: int}

        |   BM_SETIMAGE of {image: HGDIOBJ, imageType: ImageType}

        |   BM_SETSTATE of {highlight: bool }

        |   BM_SETSTYLE of {redraw: bool, style: windowFlags}

        |   CB_GETEDITSEL of {startPos: int ref, endPos: int ref}

        |   CB_LIMITTEXT of {limit: int}

        |   CB_SETEDITSEL of {startPos: int, endPos: int}

        |   CB_ADDSTRING of { text: string }

        |   CB_DELETESTRING of { index: int }

        |   CB_GETCOUNT

        |   CB_GETCURSEL

        |   CB_DIR of { attrs: ComboBase.CBDirAttr list, fileSpec: string }

        |   CB_GETLBTEXT of { index: int, length: int, text: string ref }

        |   CB_GETLBTEXTLEN of { index: int }

        |   CB_INSERTSTRING of { index: int, text: string }

        |   CB_RESETCONTENT

        |   CB_FINDSTRING of { indexStart: int, text: string }

        |   CB_SELECTSTRING of { indexStart: int, text: string }

        |   CB_SETCURSEL of { index: int }

        |   CB_SHOWDROPDOWN of { show: bool }

        |   CB_GETITEMDATA of { index: int }

        |   CB_SETITEMDATA of { index: int, data: int }

        |   CB_GETDROPPEDCONTROLRECT of { rect: RECT ref }

        |   CB_SETITEMHEIGHT of { index: int, height: int }

        |   CB_GETITEMHEIGHT of { index: int }

        |   CB_SETEXTENDEDUI of { extended: bool }

        |   CB_GETEXTENDEDUI

        |   CB_GETDROPPEDSTATE

        |   CB_FINDSTRINGEXACT of { indexStart: int, text: string }

        |   CB_SETLOCALE of { locale: int }

        |   CB_GETLOCALE

        |   CB_GETTOPINDEX

        |   CB_SETTOPINDEX of { index: int }

        |   CB_GETHORIZONTALEXTENT

        |   CB_SETHORIZONTALEXTENT of { extent: int }

        |   CB_GETDROPPEDWIDTH

        |   CB_SETDROPPEDWIDTH of { width: int }

        |   CB_INITSTORAGE of { items: int, bytes: int }

        |   LB_ADDSTRING of { text: string }

        |   LB_INSERTSTRING of { index: int, text: string }

        |   LB_DELETESTRING of { index: int }

        |   LB_SELITEMRANGEEX of { first: int, last: int }

        |   LB_RESETCONTENT

        |   LB_SETSEL of { select: bool, index: int }

        |   LB_SETCURSEL of { index: int }

        |   LB_GETSEL of { index: int }

        |   LB_GETCURSEL

        |   LB_GETTEXT of { index: int, length: int, text: string ref }

        |   LB_GETTEXTLEN of { index: int }

        |   LB_GETCOUNT

        |   LB_SELECTSTRING of { indexStart: int, text: string }

        |   LB_DIR of { attrs: ComboBase.CBDirAttr list, fileSpec: string }

        |   LB_GETTOPINDEX

        |   LB_FINDSTRING of { indexStart: int, text: string }

        |   LB_GETSELCOUNT

        |   LB_GETSELITEMS of { items: IntArray.array }

        |   LB_SETTABSTOPS of { tabs: IntVector.vector }

        |   LB_GETHORIZONTALEXTENT

        |   LB_SETHORIZONTALEXTENT of { extent: int }

        |   LB_SETCOLUMNWIDTH of { column: int }

        |   LB_ADDFILE of { fileName: string }

        |   LB_SETTOPINDEX of { index: int }

        |   LB_GETITEMRECT of { rect: RECT ref, index: int }

        |   LB_GETITEMDATA of { index: int }

        |   LB_SETITEMDATA of { index: int, data: int }

        |   LB_SELITEMRANGE of { select: bool, first: int, last: int }

        |   LB_SETANCHORINDEX of { index: int }

        |   LB_GETANCHORINDEX

        |   LB_SETCARETINDEX of { index: int, scroll: bool }

        |   LB_GETCARETINDEX

        |   LB_SETITEMHEIGHT of { index: int, height: int }

        |   LB_GETITEMHEIGHT of { index: int }

        |   LB_FINDSTRINGEXACT of { indexStart: int, text: string }

        |   LB_SETLOCALE of { locale: int } (* Should be an abstract type? *)

        |   LB_GETLOCALE (* Result will be the type used above. *)

        |   LB_SETCOUNT of { items: int }

        |   LB_INITSTORAGE of { items: int, bytes: int }

        |   LB_ITEMFROMPOINT of { point: POINT }

        |   STM_GETICON

        |   STM_GETIMAGE of {imageType: ImageType}

        |   STM_SETICON of {icon: HICON}

        |   STM_SETIMAGE of {image: HGDIOBJ, imageType: ImageType}

        |   SBM_SETPOS of { pos: int, redraw: bool }

        |   SBM_GETPOS

        |   SBM_SETRANGE of { minPos: int, maxPos: int }

        |   SBM_SETRANGEREDRAW of { minPos: int, maxPos: int }

        |   SBM_GETRANGE of { minPos: int ref, maxPos: int ref }

        |   SBM_ENABLE_ARROWS of ScrollBase.enableArrows

        |   SBM_SETSCROLLINFO of { info: ScrollBase.SCROLLINFO,
                                 options: ScrollBase.ScrollInfoOption list }

        |   SBM_GETSCROLLINFO of { info: ScrollBase.SCROLLINFO ref,
                                 options: ScrollBase.ScrollInfoOption list }

        |   FINDMSGSTRING of
            { flags: findReplaceFlags, findWhat: string, replaceWith: string }


        (* GetMessage and PeekMessage return these values. *)
        type MSG = {
            msg: Message,
            hwnd: HWND,
            time: Time.time,
            pt: {x: int, y: int}
            }
            
        type HGDIOBJ = HGDIOBJ and HWND = HWND and RECT = RECT and POINT = POINT
        and HMENU = HMENU and HICON = HICON and HINSTANCE = HINSTANCE and HDC = HDC
        and HFONT = HFONT and HRGN = HRGN and HDROP = HDROP
        and ClipboardFormat = ClipboardFormat and ClassType = ClassType
        and findReplaceFlags = FindReplaceFlags.flags
        and windowFlags = flags

        (* WM_MOUSEMOVE etc *)
        fun decompileMouseMove(constr, wp, lp) =
        let
            val lp32 = Word32.fromLargeWord lp
        in
            constr { keyflags = fromCmkf(Word32.fromLargeWord wp), x = Word.toInt(LOWORD lp32), y = Word.toInt(HIWORD lp32)  }
        end
        
        fun compileMouseMove(code, { keyflags, x, y}) =
            (code, Word32.toLargeWord (toCmkf keyflags), Word32.toLargeWord(MAKELONG(Word.fromInt x, Word.fromInt y)), fn()=>())

        local (* EM_GETSEL and CB_GETEDITSEL *)
            val {load=loadDword, store=storeDword, ctype={size=sizeDword, ...}, ...} = breakConversion cDWORD
        in
            fun compileGetSel(code, {startPos=ref s, endPos=ref e}) =
            let
                open Memory
                infix 6 ++
                (* Allocate space for two DWORDs *)
                val mem = malloc(sizeDword * 0w2)
                val eAddr = mem ++ sizeDword
                val () = ignore(storeDword(mem, s)) (* Can ignore the results *)
                and () = ignore(storeDword(eAddr, e))
            in
                (code, fromAddr mem, fromAddr eAddr, fn () => free mem)
            end
            
            and decompileGetSel{wp, lp} =
            let
                val s = loadDword(toAddr wp)
                and e = loadDword(toAddr lp)
            in
                {startPos = ref s, endPos=ref e}
            end
            
            (* Update ML from wp/lp values *)
            fun updateGetSelFromWpLp({startPos, endPos}, {wp, lp}) =
                ( startPos := loadDword(toAddr wp); endPos := loadDword(toAddr lp) )
            (* Update wp/lp from ML *)
            and updateGetSelParms({wp, lp}, {startPos = ref s, endPos = ref e}) =
                ( ignore(storeDword(toAddr wp, s)); ignore(storeDword(toAddr lp, e)) )
        end

        local (* EM_GETRECT and CB_GETDROPPEDCONTROLRECT.  LB_GETITEMRECT and WM_NCCALCSIZE are similar *)
            val {load=loadRect, store=storeRect, ctype={size=sizeRect, ...}, ...} = breakConversion cRect
        in
            fun compileGetRect(code, wp, r) =
            let
                open Memory
                val mem = malloc sizeRect
                val () = ignore(storeRect(mem, r)) (* Can ignore the result *)
            in
                (code, wp, fromAddr mem, fn () => free mem)
            end
            
            and compileSetRect(code, rect) =
            let
                open Memory
                val mem = malloc sizeRect
                val () = ignore(storeRect(mem, rect))
            in
                (code, 0w0, fromAddr mem, fn () => free mem)
            end
            
            (* These can be used for updating *)
            val fromCrect = loadRect (* For the moment *)
            and toCrect = ignore o storeRect
        end

    val hiWord = Word.toInt o HIWORD o Word32.fromLargeWord
    and loWord = Word.toInt o LOWORD o Word32.fromLargeWord

    (* Decode a received message. *)
    fun decompileMessage (0x0000, _: SysWord.word, _: SysWord.word) = WM_NULL
    
    |   decompileMessage (0x0001, wp, lp) = WM_CREATE(decompileCreate{wp=wp, lp=lp})

    |   decompileMessage (0x0002, _, _) = WM_DESTROY
     
    |   decompileMessage (0x0003, _, lp) = WM_MOVE { x = loWord lp, y = hiWord lp }

    |   decompileMessage (0x0005, wp, lp) = WM_SIZE { flag = toWMSizeOpt wp, width = loWord lp, height = hiWord lp }

    |   decompileMessage (0x0006, wp, _) =
        let
            val wp32 = Word32.fromLargeWord wp
        in
            WM_ACTIVATE { active = toWMactive (LOWORD wp32), minimize = HIWORD wp32 <> 0w0 }
        end

    |   decompileMessage (0x0007, wp, _) = WM_SETFOCUS { losing = handleOfVoidStar(toAddr wp) } 

    |   decompileMessage (0x0008, wp, _) = WM_KILLFOCUS { receivefocus = handleOfVoidStar(toAddr wp) }

    |   decompileMessage (0x000A, wp, _) = WM_ENABLE { enabled = wp <> 0w0 }

    |   decompileMessage (0x000B, wp, _) = WM_SETREDRAW { redrawflag = wp <> 0w0  }

    |   decompileMessage (0x000C, _, lp) = WM_SETTEXT { text = fromCstring(toAddr lp)  }

        (* When the message arrives we don't know what the text is. *)
    |   decompileMessage (0x000D, wp, _) = WM_GETTEXT { length = SysWord.toInt wp, text = ref ""  }

    |   decompileMessage ( 0x000E, _, _) = WM_GETTEXTLENGTH
    
    |   decompileMessage ( 0x000F, _, _) = WM_PAINT
    
    |   decompileMessage ( 0x0010, _, _) = WM_CLOSE

    |   decompileMessage ( 0x0011, wp, _) = WM_QUERYENDSESSION { source = SysWord.toInt wp }
    
    |   decompileMessage (0x0012, wp, _) = WM_QUIT {exitcode = SysWord.toInt wp }

    |   decompileMessage ( 0x0013, _, _) = WM_QUERYOPEN
 
    |   decompileMessage ( 0x0014, wp, _) = WM_ERASEBKGND { devicecontext = toHDC wp }

    |   decompileMessage ( 0x0015, _, _) = WM_SYSCOLORCHANGE

    |   decompileMessage ( 0x0016, wp, _) = WM_ENDSESSION { endsession = wp <> 0w0 }
    
    |   decompileMessage ( 0x0018, wp, lp) = WM_SHOWWINDOW  { showflag = wp <> 0w0, statusflag = SysWord.toInt lp  }
    
    |   decompileMessage ( 0x001B, _, lp) = WM_DEVMODECHANGE { devicename = fromCstring(toAddr lp) } (* "0x001B" *)
    
    |   decompileMessage ( 0x001C, wp, lp) = WM_ACTIVATEAPP { active = wp <> 0w0, threadid = SysWord.toInt lp } (* "0x001C" *)
    
    |   decompileMessage ( 0x001D, _, _) = WM_FONTCHANGE
    
    |   decompileMessage ( 0x001E, _, _) = WM_TIMECHANGE (* "0x001E" *)
    
    |   decompileMessage ( 0x001F, _, _) = WM_CANCELMODE (* "0x001F" *)
    
    |   decompileMessage ( 0x0020, wp, lp) =
            WM_SETCURSOR
                { cursorwindow = toHWND wp, hitTest = toHitTest(loWord lp), mousemessage = hiWord lp }
    
    |   decompileMessage ( 0x0021, wp, lp) =
            WM_MOUSEACTIVATE
                { parent = toHWND wp, hitTest = toHitTest(loWord lp), message = hiWord lp }
    
    |   decompileMessage (0x0022, _, _) = WM_CHILDACTIVATE (* "0x0022" *)
    
    |   decompileMessage (0x0023, _, _) = WM_QUEUESYNC (* "0x0023" *)
    
    |   decompileMessage (0x0024, wp, lp) = WM_GETMINMAXINFO(decompileMinMax{lp=lp, wp=wp})

    |   decompileMessage ( 0x0026, _, _) = WM_PAINTICON
    
    |   decompileMessage ( 0x0027, wp, _) = WM_ICONERASEBKGND { devicecontext = toHDC wp } (* "0x0027" *)
    
    |   decompileMessage ( 0x0028, wp, lp) = WM_NEXTDLGCTL { control = SysWord.toInt wp, handleflag = lp <> 0w0  } (* "0x0028" *)

    |   decompileMessage (0x002B, wp, lp) =
        let
            val (ctlType,ctlID,itemID,itemAction,itemState,hItem,hDC, rcItem,itemData) = 
                toMLDrawItem lp
        in
            WM_DRAWITEM{ senderId = SysWord.toInt wp, ctlType = ctlType, ctlID = ctlID, itemID = itemID,
              itemAction = itemAction, itemState = itemState, hItem = hItem, hDC = hDC,
              rcItem = rcItem, itemData = itemData }
        end

    |   decompileMessage (0x002C, wp, lp) =
        let
            val (ctlType,ctlID,itemID, itemWidth,itemHeight,itemData) = toMLMeasureItem lp       
        in
            WM_MEASUREITEM
            {
                senderId = SysWord.toInt wp, ctlType = ctlType, ctlID = ctlID,
                itemID = itemID, itemWidth = ref itemWidth, itemHeight = ref itemHeight, itemData = itemData 
            }
        end

    |   decompileMessage (0x002D, wp, lp) =
        let
            val (ctlType,ctlID,itemID,hItem,itemData) = toMLDeleteItem lp
        in
            WM_DELETEITEM
                { senderId = SysWord.toInt wp, ctlType = ctlType, ctlID = ctlID, itemID = itemID,
                  item = hItem, itemData = itemData }
        end

    |   decompileMessage ( 0x002E, wp, lp) =
            WM_VKEYTOITEM  { virtualKey = loWord wp, caretpos = hiWord wp, listbox = toHWND lp  } (* "0x002E" *)
    
    |   decompileMessage ( 0x002F, wp, lp) =
            WM_CHARTOITEM { key = loWord wp, caretpos = hiWord wp,listbox  = toHWND lp  } (* "0x002F" *)

    |   decompileMessage ( 0x0030, wp, lp) =
            (* The definition of WM_SETFONT says that it is the low order word of lp that says whether the
               control should be redrawn immediately. *)
            WM_SETFONT { font = toHFONT wp, redrawflag = SysWord.andb(0wxffff, lp) <> 0w0  } (* "0x0030" *)

    |   decompileMessage ( 0x0031, _, _) = WM_GETFONT (* "0x0031" *)
    
    |   decompileMessage ( 0x0032, wp, _) = WM_SETHOTKEY { virtualKey = SysWord.toInt wp  } (* "0x0032" *)
    
    |   decompileMessage ( 0x0033, _, _) = WM_GETHOTKEY (* "0x0033" *)
    
    |   decompileMessage ( 0x0037, _, _) = WM_QUERYDRAGICON (* "0x0037" *)
    
    |   decompileMessage (0x0039, wp, lp) =
        let
            val (ctlType, ctlID, hItem, itemID1, itemData1, itemID2, itemData2, _) = toMLCompareItem lp       
        in
            WM_COMPAREITEM
            {
                controlid = SysWord.toInt wp, ctlType = ctlType, ctlID = ctlID, hItem = hItem,
                itemID1 = itemID1, itemData1 = itemData1, itemID2 = itemID2, itemData2 = itemData2
            }
        end

    |   decompileMessage (0x0046, wp, lp) = WM_WINDOWPOSCHANGING(cToMLWindowPosChanging{wp=wp, lp=lp})

    |   decompileMessage (0x0047, wp, lp) = WM_WINDOWPOSCHANGED(cToMLWindowPosChanged{wp=wp, lp=lp})

    |   decompileMessage ( 0x0048, wp, _) = WM_POWER { powerevent = SysWord.toInt wp  } (* "0x0048" *)

    |   decompileMessage ( 0x004B, _, _) = WM_CANCELJOURNAL (* "0x004B" *)

    |   decompileMessage ( 0x004E, wp, lp) = WM_NOTIFY(decompileNotify{wp=wp, lp=lp})

    |   decompileMessage ( 0x0053, wp, lp) = WM_HELP(decompileHelpInfo{wp=wp, lp=lp})

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

    |   decompileMessage ( 0x007B, wp, lp) =
            WM_CONTEXTMENU { hwnd = toHWND wp, xPos = loWord lp, yPos = hiWord lp}

    |   decompileMessage ( 0x007E, wp, lp) =
            WM_DISPLAYCHANGE { bitsPerPixel = SysWord.toInt wp, xScreen = loWord lp, yScreen = hiWord lp}

    |   decompileMessage ( 0x007F, wp, _) = WM_GETICON { big = SysWord.toInt wp = 1}

    |   decompileMessage ( 0x0080, wp, lp) = WM_SETICON { big = SysWord.toInt wp = 1, icon = toHICON lp}

    |   decompileMessage ( 0x0081, wp, lp) = WM_NCCREATE(decompileCreate{wp=wp, lp=lp})

    |   decompileMessage ( 0x0082, _, _) = WM_NCDESTROY

    |   decompileMessage ( 0x0083, wp, lp) = WM_NCCALCSIZE(decompileNCCalcSize{wp=wp, lp=lp})

    |   decompileMessage ( 0x0084, _, lp) = WM_NCHITTEST { x = loWord lp, y = hiWord lp  } (* "0x0084" *)

    |   decompileMessage ( 0x0085, wp, _) = WM_NCPAINT { region = toHRGN wp  } (* "0x0085" *)
    
    |   decompileMessage ( 0x0086, wp, _) = WM_NCACTIVATE  { active = wp <> 0w0 } (* "0x0086" *)

    |   decompileMessage ( 0x0087, _, _) = WM_GETDLGCODE (* "0x0087" *)
    
    |   decompileMessage ( 0x00A0, wp, lp) = WM_NCMOUSEMOVE { hitTest = toHitTest(SysWord.toInt wp), x = getXLParam lp, y = getYLParam lp  }
    
    |   decompileMessage ( 0x00A1, wp, lp) = WM_NCLBUTTONDOWN { hitTest = toHitTest(SysWord.toInt wp), x = getXLParam lp, y = getYLParam lp  }
    
    |   decompileMessage ( 0x00A2, wp, lp) = WM_NCLBUTTONUP { hitTest = toHitTest(SysWord.toInt wp), x = getXLParam lp, y = getYLParam lp  }
    
    |   decompileMessage ( 0x00A3, wp, lp) = WM_NCLBUTTONDBLCLK { hitTest = toHitTest(SysWord.toInt wp), x = getXLParam lp, y = getYLParam lp  }
    
    |   decompileMessage ( 0x00A4, wp, lp) = WM_NCRBUTTONDOWN { hitTest = toHitTest(SysWord.toInt wp), x = getXLParam lp, y = getYLParam lp  }
    
    |   decompileMessage ( 0x00A5, wp, lp) = WM_NCRBUTTONUP { hitTest = toHitTest(SysWord.toInt wp), x = getXLParam lp, y = getYLParam lp  }
    
    |   decompileMessage ( 0x00A6, wp, lp) = WM_NCRBUTTONDBLCLK { hitTest = toHitTest(SysWord.toInt wp), x = getXLParam lp, y = getYLParam lp  }
    
    |   decompileMessage ( 0x00A7, wp, lp) = WM_NCMBUTTONDOWN { hitTest = toHitTest(SysWord.toInt wp), x = getXLParam lp, y = getYLParam lp  }
    
    |   decompileMessage ( 0x00A8, wp, lp) = WM_NCMBUTTONUP { hitTest = toHitTest(SysWord.toInt wp), x = getXLParam lp, y = getYLParam lp  }
    
    |   decompileMessage ( 0x00A9, wp, lp) = WM_NCMBUTTONDBLCLK { hitTest = toHitTest(SysWord.toInt wp), x = getXLParam lp, y = getYLParam lp  }

(* Edit control messages *)
    |   decompileMessage ( 0x00B0, wp, lp) = EM_GETSEL (decompileGetSel{wp=wp, lp=lp})

    |   decompileMessage ( 0x00B1, wp, lp) = EM_SETSEL { startPos = SysWord.toInt wp, endPos = SysWord.toInt lp }

    |   decompileMessage ( 0x00B2, _, lp) = EM_GETRECT {rect = ref(fromCrect(toAddr lp))}

    |   decompileMessage ( 0x00B3, _, lp) = EM_SETRECT { rect = fromCrect(toAddr lp) }

    |   decompileMessage ( 0x00B4, _, lp) = EM_SETRECTNP { rect = fromCrect(toAddr lp) }

    |   decompileMessage ( 0x00B5, wp, _) = EM_SCROLL{action = fromCsd(Word.fromLargeWord wp)}

    |   decompileMessage ( 0x00B6, wp, lp) = EM_LINESCROLL{xScroll = SysWord.toInt wp, yScroll = SysWord.toInt lp}

    |   decompileMessage ( 0x00B7, _, _) = EM_SCROLLCARET

    |   decompileMessage ( 0x00B8, _, _) = EM_GETMODIFY

    |   decompileMessage ( 0x00B9, wp, _) = EM_SETMODIFY{modified = wp <> 0w0}

    |   decompileMessage ( 0x00BA, _, _) = EM_GETLINECOUNT

    |   decompileMessage ( 0x00BB, wp, _) = EM_LINEINDEX {line = SysWord.toIntX (* -1 = current line *) wp}
(*
EM_SETHANDLE            0x00BC
*)
    |   decompileMessage ( 0x00BE, _, _) = EM_GETTHUMB

    |   decompileMessage ( 0x00C1, wp, _) = EM_LINELENGTH {index = SysWord.toIntX (* May be -1 *) wp}

    |   decompileMessage ( 0x00C2, wp, lp) = EM_REPLACESEL {canUndo = wp <> 0w0, text = fromCstring(toAddr lp)}

    |   decompileMessage ( 0x00C4, wp, lp) = EM_GETLINE(decompileGetLine{wp=wp, lp=lp})

    |   decompileMessage ( 0x00C5, wp, _) = EM_LIMITTEXT {limit = SysWord.toInt wp}

    |   decompileMessage ( 0x00C6, _, _) = EM_CANUNDO

    |   decompileMessage ( 0x00C7, _, _) = EM_UNDO

    |   decompileMessage ( 0x00C8, wp, _) = EM_FMTLINES{addEOL = wp <> 0w0}

    |   decompileMessage ( 0x00C9, wp, _) = EM_LINEFROMCHAR{index = SysWord.toInt wp}

    |   decompileMessage ( 0x00CB, wp, lp) = EM_SETTABSTOPS{tabs=decompileTabStops{wp=wp, lp=lp}}

    |   decompileMessage ( 0x00CC, wp, _) = EM_SETPASSWORDCHAR{ch = chr (SysWord.toInt wp)}

    |   decompileMessage ( 0x00CD, _, _) = EM_EMPTYUNDOBUFFER

    |   decompileMessage ( 0x00CE, _, _) = EM_GETFIRSTVISIBLELINE

    |   decompileMessage ( 0x00CF, wp, _) = EM_SETREADONLY{readOnly = wp <> 0w0}
(*
EM_SETWORDBREAKPROC     0x00D0
EM_GETWORDBREAKPROC     0x00D1
*)

    |   decompileMessage (0x00D2, _, _) = EM_GETPASSWORDCHAR

    |   decompileMessage (0x00D3, wp, lp) =
            if wp = 0wxffff then EM_SETMARGINS{margins=UseFontInfo}
            else
            let
                val left =
                    if SysWord.andb(wp, 0w1) <> 0w0
                    then SOME(loWord lp)
                    else NONE
                val right =
                    if SysWord.andb(wp, 0w2) <> 0w0
                    then SOME(hiWord lp)
                    else NONE
            in
                EM_SETMARGINS{margins=Margins{left=left, right=right}}
            end

    |   decompileMessage (0x00D4, _, _) = EM_GETMARGINS

    |   decompileMessage (0x00D5, _, _) = EM_GETLIMITTEXT

    |   decompileMessage (0x00D6, wp, _) = EM_POSFROMCHAR {index = SysWord.toInt wp}

    |   decompileMessage (0x00D7, _, lp) =
            (* The value in lParam is different depending on whether this is an edit control
               or a rich edit control.  Since we don't know we just pass the lp value. *)
            EM_CHARFROMPOS(EMcfpUnknown lp)

(* Scroll bar messages *)

    |   decompileMessage (0x00E0, wp, lp) = SBM_SETPOS {pos = SysWord.toInt wp, redraw = lp <> 0w0}

    |   decompileMessage (0x00E1, _, _) = SBM_GETPOS

    |   decompileMessage (0x00E2, wp, lp) = SBM_SETRANGE {minPos = SysWord.toInt wp, maxPos = SysWord.toInt lp}

    |   decompileMessage (0x00E6, wp, lp) = SBM_SETRANGEREDRAW {minPos = SysWord.toInt wp, maxPos = SysWord.toInt lp}

    |   decompileMessage (0x00E3, wp, lp) =
            SBM_GETRANGE { minPos = ref(loadInt(toAddr wp)), maxPos = ref(loadInt(toAddr lp)) }

    |   decompileMessage (0x00E4, wp, _) = SBM_ENABLE_ARROWS(fromCesbf(SysWord.toInt wp))

    |   decompileMessage (0x00E9, _, lp) =
        let
            val (info, options) = toScrollInfo lp
        in
            SBM_SETSCROLLINFO{ info = info, options = options }
        end

     |  decompileMessage (0x00EA, _, lp) =
        let
            (* The values may not be correct at this point but the mask
               should have been set. *)
            val (info, options) = toScrollInfo lp
        in
            SBM_GETSCROLLINFO{ info = ref info, options = options }
        end

(* Button control messages *)
    |   decompileMessage (0x00F0, _, _) = BM_GETCHECK

    |   decompileMessage (0x00F1, wp, _) = BM_SETCHECK{state = SysWord.toInt wp}

    |   decompileMessage (0x00F2, _, _) = BM_GETSTATE

    |   decompileMessage (0x00F3, wp, _) = BM_SETSTATE{highlight = SysWord.toInt wp <> 0}

    |   decompileMessage (0x00F4, wp, lp) = BM_SETSTYLE{redraw = SysWord.toInt lp <> 0, style = Style.fromWord wp}

    |   decompileMessage (0x00F5, _, _) = BM_CLICK

    |   decompileMessage (0x00F6, wp, _) = BM_GETIMAGE{imageType = fromCit(SysWord.toInt wp)}

    |   decompileMessage (0x00F7, wp, lp) = BM_SETIMAGE{imageType = fromCit (SysWord.toInt wp), image = toHGDIOBJ lp}

    |   decompileMessage (0x0100, wp, lp) = WM_KEYDOWN { virtualKey = SysWord.toInt wp, data = Word32.fromLargeWord lp }
    
    |   decompileMessage (0x0101, wp, lp) = WM_KEYUP { virtualKey = SysWord.toInt wp, data = Word32.fromLargeWord lp }
    
    |   decompileMessage (0x0102, wp, lp) = WM_CHAR { charCode = chr (SysWord.toInt wp), data = Word32.fromLargeWord lp }
    
    |   decompileMessage (0x0103, wp, lp) = WM_DEADCHAR { charCode = chr (SysWord.toInt wp), data = Word32.fromLargeWord lp  }
    
    |   decompileMessage (0x0104, wp, lp) = WM_SYSKEYDOWN { virtualKey = SysWord.toInt wp, data = Word32.fromLargeWord lp }
    
    |   decompileMessage (0x0105, wp, lp) = WM_SYSKEYUP { virtualKey = SysWord.toInt wp, data = Word32.fromLargeWord lp }
    
    |   decompileMessage (0x0106, wp, lp) = WM_SYSCHAR { charCode = chr (SysWord.toInt wp), data = Word32.fromLargeWord lp }
    
    |   decompileMessage (0x0107, wp, lp) = WM_SYSDEADCHAR { charCode = chr (SysWord.toInt wp), data = Word32.fromLargeWord lp }
(*
WM_IME_STARTCOMPOSITION         0x010D
WM_IME_ENDCOMPOSITION           0x010E
WM_IME_COMPOSITION              0x010F
WM_IME_KEYLAST                  0x010F
*)
    
    |   decompileMessage (0x0110, wp, lp) = WM_INITDIALOG { dialog   = toHWND wp, initdata = SysWord.toInt lp } (* "0x0110" *)

    |   decompileMessage (0x0111, wp, lp) =
        let
            val wp32 = Word32.fromLargeWord wp
        in
            WM_COMMAND { notifyCode = Word.toInt(HIWORD wp32), wId = Word.toInt(LOWORD wp32), control = toHWND lp  }
        end

    |   decompileMessage (0x0112, wp, lp) =
            WM_SYSCOMMAND
                { commandvalue = toSysCommand(SysWord.toInt(SysWord.andb(wp, 0wxFFF0))),
                  sysBits = SysWord.toInt(SysWord.andb(wp, 0wxF)),
                  p = {x= getXLParam lp, y= getYLParam lp}}

    |   decompileMessage (0x0113, wp, _) = WM_TIMER  { timerid = SysWord.toInt wp  } (* "0x0113" *)

    |   decompileMessage (0x0114, wp, lp) =
            WM_HSCROLL { value = fromCsd(LOWORD(Word32.fromLargeWord wp)), position = hiWord wp, scrollbar = toHWND lp } (* "0x0114" *)
    
    |   decompileMessage (0x0115, wp, lp) =
            WM_VSCROLL { value = fromCsd(LOWORD(Word32.fromLargeWord wp)), position  = hiWord wp, scrollbar = toHWND lp } (* "0x0115" *)

    |   decompileMessage (0x0116, wp, _) = WM_INITMENU { menu = toHMENU wp } (* "0x0116" *)

    |   decompileMessage (0x0117, wp, lp) =
            WM_INITMENUPOPUP { menupopup  = toHMENU wp, itemposition = loWord lp, isSystemMenu = hiWord lp <> 0 } (* "0x0117" *)
    
    |   decompileMessage (0x011F, wp, lp) =
        let
            val wp32 = Word32.fromLargeWord wp
        in
            WM_MENUSELECT { menuitem = Word.toInt(LOWORD wp32),
                            menuflags =
                                MenuBase.toMenuFlagSet(Word32.fromLargeWord(Word.toLargeWord(Word.andb(HIWORD wp32, 0wxffff)))),
                            menu = toHMENU lp } (* "0x011F" *)
        end
    
    |   decompileMessage (0x0120, wp, lp) =
        let
            val wp32 = Word32.fromLargeWord wp
        in
            WM_MENUCHAR { ch = chr(Word.toInt(LOWORD wp32)),
                          menuflag = (* Just a single flag *)
                                MenuBase.toMenuFlag(Word32.fromLargeWord(Word.toLargeWord(Word.andb(HIWORD wp32, 0wxffff)))),
                          menu= toHMENU lp  } (* "0x0120" *)
        end
    
    |   decompileMessage (0x0121, wp, lp) = WM_ENTERIDLE { flag = SysWord.toInt wp, window = toHWND lp } (* "0x0121" *)

    |   decompileMessage (0x0132, wp, lp) = WM_CTLCOLORMSGBOX { displaycontext = toHDC wp, messagebox = toHWND lp  } (* "0x0132" *)
    
    |   decompileMessage (0x0133, wp, lp) = WM_CTLCOLOREDIT { displaycontext = toHDC wp, editcontrol = toHWND lp  } (* "0x0133" *)
    
    |   decompileMessage (0x0134, wp, lp) = WM_CTLCOLORLISTBOX { displaycontext = toHDC wp, listbox = toHWND lp   } (* "0x0134" *)
    
    |   decompileMessage (0x0135, wp, lp) = WM_CTLCOLORBTN { displaycontext = toHDC wp, button = toHWND lp  }(* "0x0135" *)
    
    |   decompileMessage (0x0136, wp, lp) = WM_CTLCOLORDLG { displaycontext = toHDC wp, dialogbox = toHWND lp  } (* "0x0136" *)
    
    |   decompileMessage (0x0137, wp, lp) = WM_CTLCOLORSCROLLBAR { displaycontext = toHDC wp, scrollbar = toHWND lp  } (* "0x0137" *)
    
    |   decompileMessage (0x0138, wp, lp) = WM_CTLCOLORSTATIC { displaycontext = toHDC wp, staticcontrol = toHWND lp  } (* "0x0138" *)

(* Combobox messages. *)
    |   decompileMessage (0x0140, wp, lp) = CB_GETEDITSEL (decompileGetSel{wp=wp, lp=lp})

    |   decompileMessage (0x0141, wp, _) = CB_LIMITTEXT {limit = SysWord.toInt wp}

    |   decompileMessage (0x0142, _, lp) = CB_SETEDITSEL { startPos = loWord lp, endPos = hiWord lp }

    |   decompileMessage (0x0143, _, lp) = CB_ADDSTRING {text = fromCstring(toAddr lp) }

    |   decompileMessage (0x0144, wp, _) = CB_DELETESTRING {index = SysWord.toInt wp}

    |   decompileMessage (0x0145, wp, lp) =
            CB_DIR {attrs = fromCcbal(Word32.fromLargeWord wp), fileSpec = fromCstring(toAddr lp) }

    |   decompileMessage (0x0146, _, _) = CB_GETCOUNT

    |   decompileMessage (0x0147, _, _) = CB_GETCURSEL

    |   decompileMessage (0x0148, wp, _) = CB_GETLBTEXT { index = SysWord.toInt wp, length = 0, text = ref ""  }

    |   decompileMessage (0x0149, wp, _) = CB_GETLBTEXTLEN {index = SysWord.toInt wp}

    |   decompileMessage (0x014A, wp, lp) = CB_INSERTSTRING {text = fromCstring(toAddr lp), index = SysWord.toInt wp }

    |   decompileMessage (0x014B, _, _) = CB_RESETCONTENT

    |   decompileMessage (0x014C, wp, lp) = CB_FINDSTRING {text = fromCstring(toAddr lp), indexStart = SysWord.toInt wp }

    |   decompileMessage (0x014D, wp, lp) = CB_SELECTSTRING {text = fromCstring(toAddr lp), indexStart = SysWord.toInt wp }

    |   decompileMessage (0x014E, wp, _) = CB_SETCURSEL {index = SysWord.toInt wp}

    |   decompileMessage (0x014F, wp, _) = CB_SHOWDROPDOWN {show = wp <> 0w0}

    |   decompileMessage (0x0150, wp, _) = CB_GETITEMDATA {index = SysWord.toInt wp}

    |   decompileMessage (0x0151, wp, lp) = CB_SETITEMDATA {index = SysWord.toInt wp, data = SysWord.toInt lp}

    |   decompileMessage (0x0152, _, lp) = CB_GETDROPPEDCONTROLRECT {rect = ref(fromCrect(toAddr lp))}

    |   decompileMessage (0x0153, wp, lp) = CB_SETITEMHEIGHT {index = SysWord.toInt wp, height = SysWord.toInt lp}

    |   decompileMessage (0x0154, wp, _) = CB_GETITEMHEIGHT {index = SysWord.toInt wp}

    |   decompileMessage (0x0155, wp, _) = CB_SETEXTENDEDUI {extended = wp <> 0w0}

    |   decompileMessage (0x0156, _, _) = CB_GETEXTENDEDUI

    |   decompileMessage (0x0157, _, _) = CB_GETDROPPEDSTATE

    |   decompileMessage (0x0158, wp, lp) = CB_FINDSTRINGEXACT {text = fromCstring(toAddr lp), indexStart = SysWord.toInt wp }

    |   decompileMessage (0x0159, wp, _) = CB_SETLOCALE {locale = SysWord.toInt wp}

    |   decompileMessage (0x015A, _, _) = CB_GETLOCALE

    |   decompileMessage (0x015b, _, _) = CB_GETTOPINDEX

    |   decompileMessage (0x015c, wp, _) = CB_SETTOPINDEX {index = SysWord.toInt wp}

    |   decompileMessage (0x015d, _, _) = CB_GETHORIZONTALEXTENT

    |   decompileMessage (0x015e, wp, _) = CB_SETHORIZONTALEXTENT {extent = SysWord.toInt wp}

    |   decompileMessage (0x015f, _, _) = CB_GETDROPPEDWIDTH

    |   decompileMessage (0x0160, wp, _) = CB_SETDROPPEDWIDTH {width = SysWord.toInt wp}

    |   decompileMessage (0x0161, wp, lp) = CB_INITSTORAGE {items = SysWord.toInt wp, bytes = SysWord.toInt lp}

(* Static control messages. *)
    |   decompileMessage (0x0170, wp, _) = STM_SETICON{icon = toHICON wp}

    |   decompileMessage (0x0171, _, _) = STM_GETICON

    |   decompileMessage (0x0172, wp, lp) = STM_SETIMAGE{imageType = fromCit(SysWord.toInt wp), image = toHGDIOBJ lp}

    |   decompileMessage (0x0173, wp, _) = STM_GETIMAGE{imageType = fromCit(SysWord.toInt wp)}

(* Listbox messages *)
    |   decompileMessage (0x0180, _, lp) = LB_ADDSTRING {text = fromCstring(toAddr lp) }

    |   decompileMessage (0x0181, wp, lp) = LB_INSERTSTRING {text = fromCstring(toAddr lp), index = SysWord.toInt wp }

    |   decompileMessage (0x0182, wp, _) = LB_DELETESTRING {index = SysWord.toInt wp}

    |   decompileMessage (0x0183, wp, lp) = LB_SELITEMRANGEEX {first = SysWord.toInt wp, last = SysWord.toInt lp}

    |   decompileMessage (0x0184, _, _) = LB_RESETCONTENT

    |   decompileMessage (0x0185, wp, lp) = LB_SETSEL {select = wp <> 0w0, index = SysWord.toInt lp}

    |   decompileMessage (0x0186, wp, _) = LB_SETCURSEL {index = SysWord.toInt wp}

    |   decompileMessage (0x0187, wp, _) = LB_GETSEL {index = SysWord.toInt wp}

    |   decompileMessage (0x0188, _, _) = LB_GETCURSEL

    |   decompileMessage (0x0189, wp, _) = LB_GETTEXT { index = SysWord.toInt wp, length = 0, text = ref ""  }

    |   decompileMessage (0x018A, wp, _) = LB_GETTEXTLEN {index = SysWord.toInt wp}

    |   decompileMessage (0x018B, _, _) = LB_GETCOUNT

    |   decompileMessage (0x018C, wp, lp) = LB_SELECTSTRING {text = fromCstring(toAddr lp), indexStart = SysWord.toInt wp }

    |   decompileMessage (0x018D, wp, lp) = LB_DIR {attrs = fromCcbal(Word32.fromLargeWord wp), fileSpec = fromCstring(toAddr lp) }

    |   decompileMessage (0x018E, _, _) = LB_GETTOPINDEX

    |   decompileMessage (0x018F, wp, lp) = LB_FINDSTRING {text = fromCstring(toAddr lp), indexStart = SysWord.toInt wp }

    |   decompileMessage (0x0190, _, _) = LB_GETSELCOUNT

    |   decompileMessage (0x0191, wp, _) = LB_GETSELITEMS { items = IntArray.array(SysWord.toInt wp, ~1) }

    |   decompileMessage (0x0192, wp, lp) = LB_SETTABSTOPS{tabs=decompileTabStops{wp=wp, lp=lp}}

    |   decompileMessage (0x0193, _, _) = LB_GETHORIZONTALEXTENT

    |   decompileMessage (0x0194, wp, _) = LB_SETHORIZONTALEXTENT {extent = SysWord.toInt wp}

    |   decompileMessage (0x0195, wp, _) = LB_SETCOLUMNWIDTH {column = SysWord.toInt wp}

    |   decompileMessage (0x0196, _, lp) = LB_ADDFILE {fileName = fromCstring(toAddr lp) }

    |   decompileMessage (0x0197, wp, _) = LB_SETTOPINDEX {index = SysWord.toInt wp}

    |   decompileMessage (0x0198, wp, lp) = LB_GETITEMRECT {index = SysWord.toInt wp, rect = ref(fromCrect(toAddr lp))}

    |   decompileMessage (0x0199, wp, _) = LB_GETITEMDATA {index = SysWord.toInt wp}

    |   decompileMessage (0x019A, wp, lp) = LB_SETITEMDATA {index = SysWord.toInt wp, data = SysWord.toInt lp}

    |   decompileMessage (0x019B, wp, lp) = LB_SELITEMRANGE {select = wp <> 0w0, first = loWord lp, last = hiWord lp}

    |   decompileMessage (0x019C, wp, _) = LB_SETANCHORINDEX {index = SysWord.toInt wp}

    |   decompileMessage (0x019D, _, _) = LB_GETANCHORINDEX

    |   decompileMessage (0x019E, wp, lp) = LB_SETCARETINDEX {index = SysWord.toInt wp, scroll = lp <> 0w0}

    |   decompileMessage (0x019F, _, _) = LB_GETCARETINDEX

    |   decompileMessage (0x01A0, wp, lp) = LB_SETITEMHEIGHT {index = SysWord.toInt wp, height = loWord lp}

    |   decompileMessage (0x01A1, wp, _) = LB_GETITEMHEIGHT {index = SysWord.toInt wp}

    |   decompileMessage (0x01A2, wp, lp) = LB_FINDSTRINGEXACT {text = fromCstring(toAddr lp), indexStart = SysWord.toInt wp }

    |   decompileMessage (0x01A5, wp, _) = LB_SETLOCALE {locale = SysWord.toInt wp}

    |   decompileMessage (0x01A6, _, _) = LB_GETLOCALE

    |   decompileMessage (0x01A7, wp, _) = LB_SETCOUNT {items = SysWord.toInt wp}

    |   decompileMessage (0x01A8, wp, lp) = LB_INITSTORAGE {items = SysWord.toInt wp, bytes = SysWord.toInt lp}

    |   decompileMessage (0x01A9, _, lp) = LB_ITEMFROMPOINT {point = {x = loWord lp, y = hiWord lp }}

    |   decompileMessage (0x0200, wp, lp) = decompileMouseMove(WM_MOUSEMOVE, wp, lp)
    
    |   decompileMessage (0x0201, wp, lp) = decompileMouseMove(WM_LBUTTONDOWN, wp, lp)

    |   decompileMessage (0x0202, wp, lp) = decompileMouseMove(WM_LBUTTONUP, wp, lp)

    |   decompileMessage (0x0203, wp, lp) = decompileMouseMove(WM_LBUTTONDBLCLK, wp, lp)

    |   decompileMessage (0x0204, wp, lp) = decompileMouseMove(WM_RBUTTONDOWN, wp, lp)

    |   decompileMessage (0x0205, wp, lp) = decompileMouseMove(WM_RBUTTONUP, wp, lp)

    |   decompileMessage (0x0206, wp, lp) = decompileMouseMove(WM_RBUTTONDBLCLK, wp, lp)

    |   decompileMessage (0x0207, wp, lp) = decompileMouseMove(WM_MBUTTONDOWN, wp, lp)

    |   decompileMessage (0x0208, wp, lp) = decompileMouseMove(WM_MBUTTONUP, wp, lp)

    |   decompileMessage (0x0209, wp, lp) = decompileMouseMove(WM_MBUTTONDBLCLK, wp, lp)

(*
WM_MOUSEWHEEL                   0x020A
*)
    |   decompileMessage (0x0210, wp, lp) = WM_PARENTNOTIFY { eventflag = loWord wp, idchild = hiWord wp, value     = SysWord.toInt lp  }
    
    |   decompileMessage (0x0211, wp, _) = WM_ENTERMENULOOP { istrack= wp <> 0w0 } (* "0x0211" *)
    
    |   decompileMessage (0x0212, wp, _) = WM_EXITMENULOOP { istrack= wp <> 0w0 } (* "0x0212" *)
(*
WM_NEXTMENU                     0x0213
WM_SIZING                       0x0214
*)
    |   decompileMessage (0x0215, _, lp) = WM_CAPTURECHANGED { newCapture = toHWND lp }
(*
WM_MOVING                       0x0216
WM_POWERBROADCAST               0x0218
WM_DEVICECHANGE                 0x0219
*)

    |   decompileMessage (0x0220, _, lp) =
        let
            val (class, title, hinst, x,y,cx,cy, style, lParam) = toMdiCreate lp
        in
            WM_MDICREATE
                { class = class, title = title, instance = hinst, x = x, y = y,
                  cx = cx, cy = cy, style = style, cdata = lParam }
        end

    |   decompileMessage (0x0221, wp, _) = WM_MDIDESTROY  { child = toHWND wp } (* "0x0221" *)
    
    |   decompileMessage (0x0223, wp, _) = WM_MDIRESTORE { child = toHWND wp } (* "0x0223" *)
    
    |   decompileMessage (0x0224, wp, lp) = WM_MDINEXT { child = toHWND wp, flagnext = lp <> 0w0  } (* "0x0224" *)
    
    |   decompileMessage (0x0225, wp, _) = WM_MDIMAXIMIZE { child = toHWND wp }  (* "0x0225" *)
    
    |   decompileMessage (0x0226, wp, _) = WM_MDITILE { tilingflag = fromCmdif(Word32.fromLargeWord wp)  } (* "0x0226" *)
    
    |   decompileMessage (0x0227, wp, _) = WM_MDICASCADE { skipDisabled = IntInf.andb((SysWord.toInt wp), 2) <> 0 }
 
    |   decompileMessage (0x0228, _, _) = WM_MDIICONARRANGE
    
    |   decompileMessage (0x0229, _, _) = WM_MDIGETACTIVE
    
    |   decompileMessage (0x0230, wp, lp) = WM_MDISETMENU { frameMenu  = toHMENU wp, windowMenu = toHMENU lp } (* "0x0230" *)

    |   decompileMessage (0x0231, _, _) = WM_ENTERSIZEMOVE

    |   decompileMessage (0x0232, _, _) = WM_EXITSIZEMOVE

    |   decompileMessage (0x0233, wp, _) = WM_DROPFILES { hDrop = toHDROP wp }

    |   decompileMessage (0x0234, _, _) = WM_MDIREFRESHMENU (* "0x0234" *)
(*
WM_IME_SETCONTEXT               0x0281
WM_IME_NOTIFY                   0x0282
WM_IME_CONTROL                  0x0283
WM_IME_COMPOSITIONFULL          0x0284
WM_IME_SELECT                   0x0285
WM_IME_CHAR                     0x0286
WM_IME_KEYDOWN                  0x0290
WM_IME_KEYUP                    0x0291
*)
    |   decompileMessage (0x02A0, wp, lp) = WM_NCMOUSEHOVER { hitTest = toHitTest(SysWord.toInt wp), x = getXLParam lp, y = getYLParam lp }

    |   decompileMessage (0x02A1, wp, lp) = decompileMouseMove(WM_MOUSEHOVER, wp, lp)(* "0x02A1" *)

    |   decompileMessage (0x02A2, _, _) = WM_NCMOUSELEAVE (* "0x02A2" *)

    |   decompileMessage (0x02A3, _, _) = WM_MOUSELEAVE (* "0x02A3" *)

    |   decompileMessage (0x0300, _, _) = WM_CUT (* "0x0300" *)
    
    |   decompileMessage (0x0301, _, _) = WM_COPY (* "0x0301" *)
    
    |   decompileMessage (0x0302, _, _) = WM_PASTE (* "0x0302" *)
    
    |   decompileMessage (0x0303, _, _) = WM_CLEAR (* "0x0303" *)
    
    |   decompileMessage (0x0304, _, _) = WM_UNDO (* "0x0304" *)
    
    |   decompileMessage (0x0305, wp, _) = WM_RENDERFORMAT { format = fromCcbf(SysWord.toInt wp) } (* "0x0305" *)
    
    |   decompileMessage (0x0306, _, _) = WM_RENDERALLFORMATS (* "0x0306" *)
    
    |   decompileMessage (0x0307, _, _) = WM_DESTROYCLIPBOARD (* "0x0307" *)
    
    |   decompileMessage (0x0308, _, _) = WM_DRAWCLIPBOARD (* "0x0308" *)
    
    |   decompileMessage (0x0309, wp, _) = WM_PAINTCLIPBOARD { clipboard = toHWND wp  } (* "0x0309" *)

    |   decompileMessage (0x030A, wp, lp) =
            WM_VSCROLLCLIPBOARD { viewer = toHWND wp, code = loWord lp, position = hiWord lp  } (* "0x030A" *)
    
    |   decompileMessage (0x030B, _, lp) = WM_SIZECLIPBOARD { viewer = toHWND lp  } (* "0x030B" *)

            (* The format name is inserted by the window procedure so any
               incoming message won't have the information.  Indeed the
               buffer may not have been initialised. *)
    |   decompileMessage (0x030C, wp, _) = WM_ASKCBFORMATNAME { length = SysWord.toInt wp, formatName = ref ""  }
    
    |   decompileMessage (0x030D, wp, lp) = WM_CHANGECBCHAIN { removed = toHWND wp, next = toHWND lp }
    
    |   decompileMessage (0x030E, wp, lp) =
            WM_HSCROLLCLIPBOARD { viewer   = toHWND wp, code = loWord lp, position = hiWord lp  } (* "0x030E" *)

    |   decompileMessage (0x030F, _, _) = WM_QUERYNEWPALETTE (* "0x030F" *)

    |   decompileMessage (0x0310, wp, _) = WM_PALETTEISCHANGING { realize = toHWND wp } (* "0x0310" *)

    |   decompileMessage (0x0311, wp, _) = WM_PALETTECHANGED { palChg = toHWND wp } (* "0x0311" *)

    |   decompileMessage (0x0312, wp, _) = WM_HOTKEY { id = SysWord.toInt wp } (* "0x0312" *)

    |   decompileMessage (0x0317, wp, lp) = WM_PRINT { hdc = toHDC wp, flags = fromCwmpl(Word32.fromLargeWord lp) }

    |   decompileMessage (0x0318, wp, lp) = WM_PRINTCLIENT { hdc = toHDC wp, flags = fromCwmpl(Word32.fromLargeWord lp) }

    |   decompileMessage (m, wp, lp) =
            (* User, application and registered messages. *)
            (* Rich edit controls use WM_USER+37 to WM_USER+122.  As and when we implement
               rich edit controls we may want to treat those messages specially. *)
            if m >= 0x0400 andalso m <= 0x7FFF
            then WM_USER { uMsg = m, wParam = wp, lParam = lp }
            else if m >= 0x8000 andalso m <= 0xBFFF
            then WM_APP { uMsg = m, wParam = wp, lParam = lp }
            else if m >= 0x8000 andalso m <= 0xFFFF
            then
                (
                (* We could use PolyML.OnEntry or use a weak byte ref to initialise the registered messages. *)
                if m = RegisterMessage "commdlg_FindReplace"
                then FINDMSGSTRING(decompileFindMsg{wp=wp, lp=lp})
                else WM_REGISTERED { uMsg = m, wParam = wp, lParam = lp }
                )
            else (* Other system messages. *)
                WM_SYSTEM_OTHER { uMsg = m, wParam = wp, lParam = lp }

    fun btoi false = 0 | btoi true = 1
    
    fun makeLong(x, y) = Word32.toLargeWord(MAKELONG(Word.fromInt x, Word.fromInt y))
 
    (* If we return a string we need to ensure it's freed *)
    fun compileStringAsLp(code, wp, string) =
    let
        val s = toCstring string
    in
        (code, wp, fromAddr s, fn () => Memory.free s)
    end
    
    (* Requests for strings.  Many of these don't pass the length as an argument. *)
    fun compileStringRequest(code, wparam, length) =
    let
        open Memory
        val mem = malloc(Word.fromInt length)
    in
        (code, wparam, fromAddr mem, fn () => free mem)
    end

    fun strAddrAsLp(code, wp, (addr, free)) = (code, wp, addr, free)

    fun noFree () = ()

    fun compileMessage WM_NULL = (0x0000, 0w0: SysWord.word, 0w0: SysWord.word, noFree)

    |   compileMessage (WM_CREATE args) = compileCreate(0x0001, args)

    |   compileMessage WM_DESTROY = (0x0002, 0w0, 0w0, noFree)

    |   compileMessage (WM_MOVE {x, y}) = (0x0003, 0w0, makeLong(x, y), noFree)

    |   compileMessage (WM_SIZE {flag, width, height}) =
            (0x0005, fromWMSizeOpt flag, makeLong(width, height), noFree)

    |   compileMessage (WM_ACTIVATE {active, minimize}) =
            (0x0006, Word32.toLargeWord(MAKELONG(fromWMactive active, if minimize then 0w1 else 0w1)), 0w0, noFree)

    |   compileMessage (WM_SETFOCUS {losing}) = (0x0007, 0w0, fromHWND losing, noFree)

    |   compileMessage (WM_KILLFOCUS {receivefocus}) = (0x0008, 0w0, fromHWND receivefocus, noFree)

    |   compileMessage (WM_ENABLE {enabled}) = (0x000A, if enabled then 0w1 else 0w0, 0w0, noFree)

    |   compileMessage (WM_SETREDRAW {redrawflag}) = (0x000B, if redrawflag then 0w1 else 0w0, 0w0, noFree)

    |   compileMessage (WM_SETTEXT {text}) = compileStringAsLp(0x000C, 0w0, text)

    |   compileMessage (WM_GETTEXT {length, ...}) = compileStringRequest(0x000D, SysWord.fromInt length, length)

    |   compileMessage WM_GETTEXTLENGTH = (0x000E, 0w0, 0w0, noFree)

    |   compileMessage WM_PAINT = (0x000F, 0w0, 0w0, noFree)

    |   compileMessage WM_CLOSE = (0x0010, 0w0, 0w0, noFree)

    |   compileMessage (WM_QUERYENDSESSION { source}) = (0x0011, SysWord.fromInt source, 0w0, noFree)

    |   compileMessage (WM_QUIT {exitcode}) = (0x0012, SysWord.fromInt exitcode, 0w0, noFree)

    |   compileMessage WM_QUERYOPEN = (0x0013, 0w0, 0w0, noFree)

    |   compileMessage (WM_ERASEBKGND {devicecontext}) = (0x0014, 0w0, fromHDC devicecontext, noFree)

    |   compileMessage WM_SYSCOLORCHANGE = (0x0015, 0w0, 0w0, noFree)

    |   compileMessage (WM_ENDSESSION {endsession}) = (0x0016, SysWord.fromInt(btoi endsession), 0w0, noFree)

    |   compileMessage (WM_SHOWWINDOW {showflag, statusflag}) =
                (0x0018, SysWord.fromInt(btoi showflag), SysWord.fromInt statusflag, noFree)

    |   compileMessage (WM_DEVMODECHANGE {devicename}) = compileStringAsLp(0x001B, 0w0, devicename)

    |   compileMessage (WM_ACTIVATEAPP {active, threadid}) =
                (0x001B, SysWord.fromInt(btoi active), SysWord.fromInt threadid, noFree)

    |   compileMessage WM_FONTCHANGE = (0x001D, 0w0, 0w0, noFree)

    |   compileMessage WM_TIMECHANGE = (0x001E, 0w0, 0w0, noFree)

    |   compileMessage WM_CANCELMODE = (0x001F, 0w0, 0w0, noFree)

    |   compileMessage (WM_SETCURSOR {cursorwindow, hitTest, mousemessage}) =
            (0x0020, fromHWND cursorwindow, makeLong(fromHitTest hitTest, mousemessage), noFree)

    |   compileMessage (WM_MOUSEACTIVATE {parent, hitTest, message}) =
            (0x0021, fromHWND parent, makeLong(fromHitTest hitTest, message), noFree)

    |   compileMessage WM_CHILDACTIVATE = (0x0022, 0w0, 0w0, noFree)

    |   compileMessage WM_QUEUESYNC = (0x0023, 0w0, 0w0, noFree)
    
    |   compileMessage(WM_GETMINMAXINFO args) = compileMinMax(0x0024, args)

    |   compileMessage WM_PAINTICON = (0x0026, 0w0, 0w0, noFree)

    |   compileMessage (WM_ICONERASEBKGND {devicecontext}) =
                (0x0027, fromHDC devicecontext, 0w0, noFree)

    |   compileMessage (WM_NEXTDLGCTL {control, handleflag}) =
                (0x0028, SysWord.fromInt control, SysWord.fromInt(btoi handleflag), noFree)

    |   compileMessage (WM_DRAWITEM { senderId, ctlType, ctlID, itemID, itemAction,itemState,
                                 hItem, hDC, rcItem, itemData}) =
            strAddrAsLp(0x002B, SysWord.fromInt senderId,
                fromMLDrawItem(ctlType, ctlID, itemID, itemAction,itemState, hItem, hDC,rcItem,itemData))

    |   compileMessage (WM_MEASUREITEM{ senderId, ctlType, ctlID, itemID, itemWidth=ref itemWidth, itemHeight=ref itemHeight, itemData}) =
            strAddrAsLp(0x002C, SysWord.fromInt senderId,
                fromMLMeasureItem(ctlType, ctlID, itemID, itemWidth, itemHeight, itemData))

    |   compileMessage (WM_DELETEITEM{ senderId, ctlType, ctlID, itemID, item, itemData}) =
            strAddrAsLp(0x002D, SysWord.fromInt senderId,
                fromMLDeleteItem(ctlType, ctlID, itemID, item, itemData))

    |   compileMessage (WM_VKEYTOITEM {virtualKey, caretpos, listbox}) =
            (0x002E, makeLong(virtualKey, caretpos), fromHWND listbox, noFree)

    |   compileMessage (WM_CHARTOITEM {key, caretpos, listbox}) =
            (0x002F, makeLong(key, caretpos), fromHWND listbox, noFree)

    |   compileMessage (WM_SETFONT {font, redrawflag}) =
            (0x0030, fromHFONT font, if redrawflag then 0w1 else 0w0, noFree)

    |   compileMessage WM_GETFONT = (0x0031, 0w0, 0w0, noFree)

    |   compileMessage (WM_SETHOTKEY {virtualKey}) = (0x0032, SysWord.fromInt virtualKey, 0w0, noFree)

    |   compileMessage WM_GETHOTKEY = (0x0033, 0w0, 0w0, noFree)

    |   compileMessage WM_QUERYDRAGICON = (0x0037, 0w0, 0w0, noFree)

    |   compileMessage (WM_COMPAREITEM { controlid, ctlType, ctlID, hItem, itemID1,itemData1, itemID2,itemData2}) =
        let
            (* TODO: Perhaps we should have locale Id in the argument record. *)
            val LOCALE_USER_DEFAULT = 0x0400
        in
            strAddrAsLp(0x0039, SysWord.fromInt controlid,
                fromMLCompareItem (ctlType, ctlID, hItem, itemID1, itemData1, itemID2, itemData2, LOCALE_USER_DEFAULT))
        end

    |   compileMessage (WM_WINDOWPOSCHANGING wpc) = mlToCWindowPosChanging(0x0046, wpc)

    |   compileMessage (WM_WINDOWPOSCHANGED wpc) = mlToCWindowPosChanged(0x0047, wpc)

    |   compileMessage (WM_POWER {powerevent}) = (0x0048, SysWord.fromInt powerevent, 0w0, noFree)

    |   compileMessage WM_CANCELJOURNAL = (0x004B, 0w0, 0w0, noFree)

    |   compileMessage (WM_NOTIFY {idCtrl, from, idFrom, notification}) =
            strAddrAsLp (0x004E, SysWord.fromInt idCtrl, compileNotification(from, idFrom, notification))

(*
WM_INPUTLANGCHANGEREQUEST       0x0050
WM_INPUTLANGCHANGE              0x0051
WM_TCARD                        0x0052
WM_USERCHANGED                  0x0054
WM_NOTIFYFORMAT                 0x0055

WM_STYLECHANGING                0x007C
WM_STYLECHANGED                 0x007D
*)

    |   compileMessage (WM_HELP args) = compileHelpInfo(0x0053, args)

    |   compileMessage (WM_CONTEXTMENU { hwnd, xPos, yPos }) =
            (0x007B, fromHWND hwnd, makeLong(xPos, yPos), noFree)

    |   compileMessage (WM_DISPLAYCHANGE { bitsPerPixel, xScreen, yScreen}) =
            (0x007E, SysWord.fromInt bitsPerPixel, makeLong(xScreen, yScreen), noFree)

    |   compileMessage (WM_GETICON {big}) = (0x007F, SysWord.fromInt(btoi big), 0w0, noFree)

    |   compileMessage (WM_SETICON { big, icon }) =
            (0x0080, SysWord.fromInt(btoi big), fromAddr(voidStarOfHandle icon), noFree)

    |   compileMessage (WM_NCCREATE args) = compileCreate(0x0081, args)

    |   compileMessage WM_NCDESTROY = (0x0082, 0w0, 0w0, noFree)

    |   compileMessage (WM_NCCALCSIZE args) = compileNCCalcSize args

    |   compileMessage (WM_NCHITTEST {x, y}) = (0x0084, 0w0, makeLong(x, y), noFree)

    |   compileMessage (WM_NCPAINT {region}) = (0x0085, fromHRGN region, 0w0, noFree)

    |   compileMessage (WM_NCACTIVATE {active}) = (0x0086, SysWord.fromInt(btoi active), 0w0, noFree)

    |   compileMessage WM_GETDLGCODE = (0x0087, 0w0, 0w0, noFree)

    |   compileMessage (WM_NCMOUSEMOVE {hitTest, x, y}) =
                (0x00A0, SysWord.fromInt(fromHitTest hitTest), makeXYParam(x, y), noFree)

    |   compileMessage (WM_NCLBUTTONDOWN {hitTest, x, y}) =
                (0x00A1, SysWord.fromInt(fromHitTest hitTest), makeXYParam(x, y), noFree)

    |   compileMessage (WM_NCLBUTTONUP {hitTest, x, y}) =
                (0x00A2, SysWord.fromInt(fromHitTest hitTest), makeXYParam(x, y), noFree)

    |   compileMessage (WM_NCLBUTTONDBLCLK {hitTest, x, y}) =
                (0x00A3, SysWord.fromInt(fromHitTest hitTest), makeXYParam(x, y), noFree)

    |   compileMessage (WM_NCRBUTTONDOWN {hitTest, x, y}) =
                (0x00A4, SysWord.fromInt(fromHitTest hitTest), makeXYParam(x, y), noFree)

    |   compileMessage (WM_NCRBUTTONUP {hitTest, x, y}) =
                (0x00A5, SysWord.fromInt(fromHitTest hitTest), makeXYParam(x, y), noFree)

    |   compileMessage (WM_NCRBUTTONDBLCLK {hitTest, x, y}) =
                (0x00A6, SysWord.fromInt(fromHitTest hitTest), makeXYParam(x, y), noFree)

    |   compileMessage (WM_NCMBUTTONDOWN {hitTest, x, y}) =
                (0x00A7, SysWord.fromInt(fromHitTest hitTest), makeXYParam(x, y), noFree)

    |   compileMessage (WM_NCMBUTTONUP {hitTest, x, y}) =
                (0x00A8, SysWord.fromInt(fromHitTest hitTest), makeXYParam(x, y), noFree)

    |   compileMessage (WM_NCMBUTTONDBLCLK {hitTest, x, y}) =
                (0x00A9, SysWord.fromInt(fromHitTest hitTest), makeXYParam(x, y), noFree)

(* Edit control messages *)
    |   compileMessage (EM_GETSEL args) = compileGetSel(0x00B0, args)

    |   compileMessage (EM_SETSEL{startPos, endPos}) =
            (0x00B1, SysWord.fromInt startPos, SysWord.fromInt endPos, noFree)

    |   compileMessage (EM_GETRECT {rect=ref r}) = compileGetRect(0x00B2, 0w0, r)

    |   compileMessage (EM_SETRECT {rect}) = compileSetRect(0x00B3, rect)

    |   compileMessage (EM_SETRECTNP {rect}) = compileSetRect(0x00B4, rect)

    |   compileMessage (EM_SCROLL{action}) = (0x00B5, Word.toLargeWord(toCsd action), 0w0, noFree)

    |   compileMessage (EM_LINESCROLL{xScroll, yScroll}) =
            (0x00B6, SysWord.fromInt xScroll, SysWord.fromInt yScroll, noFree)

    |   compileMessage EM_SCROLLCARET = (0x00B7, 0w0, 0w0, noFree)

    |   compileMessage EM_GETMODIFY = (0x00B8, 0w0, 0w0, noFree)

    |   compileMessage (EM_SETMODIFY{modified}) = (0x00B9, if modified then 0w1 else 0w0, 0w0, noFree)

    |   compileMessage EM_GETLINECOUNT = (0x00BA, 0w0, 0w0, noFree)

    |   compileMessage (EM_LINEINDEX{line}) = (0x00BB, SysWord.fromInt line, 0w0, noFree)
(*
EM_SETHANDLE            0x00BC
*)
    |   compileMessage EM_GETTHUMB = (0x00BE, 0w0, 0w0, noFree)

    |   compileMessage (EM_LINELENGTH{index}) = (0x00BB, SysWord.fromInt index, 0w0, noFree)

    |   compileMessage (EM_REPLACESEL{canUndo, text}) = compileStringAsLp(0x00C2, SysWord.fromInt(btoi canUndo), text)

    |   compileMessage (EM_GETLINE args) = compileGetLine args

    |   compileMessage (EM_LIMITTEXT{limit}) = (0x00C5, SysWord.fromInt limit, 0w0, noFree)

    |   compileMessage EM_CANUNDO = (0x00C6, 0w0, 0w0, noFree)

    |   compileMessage EM_UNDO = (0x00C7, 0w0, 0w0, noFree)

    |   compileMessage (EM_FMTLINES{addEOL}) = (0x00C8, SysWord.fromInt(btoi addEOL), 0w0, noFree)

    |   compileMessage (EM_LINEFROMCHAR{index}) = (0x00C9, SysWord.fromInt index, 0w0, noFree)

    |   compileMessage (EM_SETTABSTOPS{tabs}) = compileTabStops(0x00CB, tabs)

    |   compileMessage (EM_SETPASSWORDCHAR{ch}) = (0x00CC, SysWord.fromInt(ord ch), 0w0, noFree)

    |   compileMessage EM_EMPTYUNDOBUFFER = (0x00CD, 0w0, 0w0, noFree)

    |   compileMessage EM_GETFIRSTVISIBLELINE = (0x00CE, 0w0, 0w0, noFree)

    |   compileMessage (EM_SETREADONLY{readOnly}) = (0x00CF, SysWord.fromInt(btoi readOnly), 0w0, noFree)
(*
EM_SETWORDBREAKPROC     0x00D0
EM_GETWORDBREAKPROC     0x00D1
*)
    |   compileMessage EM_GETPASSWORDCHAR = (0x00D2, 0w0, 0w0, noFree)

    |   compileMessage (EM_SETMARGINS{margins}) =
        (
            case margins of
                UseFontInfo => (0x00D3, SysWord.fromInt 0xffff, 0w0, noFree)
            |   Margins{left, right} =>
                let
                    val (b0, lo) = case left of SOME l => (0w1, l) | NONE => (0w0, 0)
                    val (b1, hi) = case right of SOME r => (0w2, r) | NONE => (0w0, 0)
                in
                    (0x00D3, SysWord.orb(b0, b1), makeLong(hi,lo), noFree)
                end
       )

    |   compileMessage EM_GETMARGINS = (0x00D4, 0w0, 0w0, noFree) (* Returns margins in lResult *)

    |   compileMessage EM_GETLIMITTEXT = (0x00D5, 0w0, 0w0, noFree)

    |   compileMessage (EM_POSFROMCHAR {index}) = (0x00D6, SysWord.fromInt index, 0w0, noFree)

    |   compileMessage (EM_CHARFROMPOS arg) =
        let
            val (lParam, toFree) =
                case arg of
                    EMcfpEdit{x,y} => (makeLong(x, y), noFree)
                |   EMcfpRichEdit pt => makePointStructAddr pt
                |   EMcfpUnknown lp => (lp, noFree)
        in
            (0x00D7, 0w0, lParam, toFree)
        end

(* Scroll bar messages *)

    |   compileMessage (SBM_SETPOS {pos, redraw}) = (0x00E0, SysWord.fromInt pos, SysWord.fromInt(btoi redraw), noFree)

    |   compileMessage SBM_GETPOS = (0x00E1, 0w0, 0w0, noFree)

    |   compileMessage (SBM_SETRANGE {minPos, maxPos}) = (0x00E2, SysWord.fromInt minPos, SysWord.fromInt maxPos, noFree)

    |   compileMessage (SBM_SETRANGEREDRAW {minPos, maxPos}) = (0x00E6, SysWord.fromInt minPos, SysWord.fromInt maxPos, noFree)

    |   compileMessage (SBM_GETRANGE _) =
        let
            (* An application should use GetScrollRange rather than sending this.*)
            open Memory
            (* We need to allocate two ints and pass their addresses *)
            val mem = malloc(0w2 * sizeInt)
            infix 6 ++
        in
            (0x00E3, fromAddr mem, fromAddr(mem ++ sizeInt), fn () => free mem)
        end

    |   compileMessage (SBM_ENABLE_ARROWS flags) = (0x00E4, SysWord.fromInt(toCesbf flags), 0w0, noFree)

    |   compileMessage (SBM_SETSCROLLINFO {info, options}) =
            strAddrAsLp(0x00E9, 0w0, fromScrollInfo(info, options))

    |   compileMessage (SBM_GETSCROLLINFO {info = ref info, options}) =
            strAddrAsLp(0x00EA, 0w0, fromScrollInfo(info, options))

(* Button control messages *)

    |   compileMessage BM_GETCHECK = (0x00F0, 0w0, 0w0, noFree)

    |   compileMessage (BM_SETCHECK{state}) = (0x00F1, SysWord.fromInt state, 0w0, noFree)

    |   compileMessage BM_GETSTATE = (0x00F2, 0w0, 0w0, noFree)

    |   compileMessage (BM_SETSTATE{highlight}) = (0x00F3, SysWord.fromInt(btoi highlight), 0w0, noFree)

    |   compileMessage (BM_SETSTYLE{redraw, style})
            = (0x00F3, SysWord.fromInt(LargeWord.toInt(Style.toWord style)), SysWord.fromInt(btoi redraw), noFree)

    |   compileMessage BM_CLICK = (0x00F5, 0w0, 0w0, noFree)

    |   compileMessage (BM_GETIMAGE{imageType}) = (0x00F6, SysWord.fromInt(toCit imageType), 0w0, noFree)

    |   compileMessage (BM_SETIMAGE{imageType, image}) =
                (0x00F7, SysWord.fromInt(toCit imageType), fromHGDIOBJ image, noFree)

    |   compileMessage (WM_KEYDOWN {virtualKey, data}) = (0x0100, SysWord.fromInt virtualKey, Word32.toLargeWord data, noFree)

    |   compileMessage (WM_KEYUP {virtualKey, data}) = (0x0101, SysWord.fromInt virtualKey, Word32.toLargeWord data, noFree)

    |   compileMessage (WM_CHAR {charCode, data}) = (0x0102, SysWord.fromInt(ord charCode), Word32.toLargeWord data, noFree)

    |   compileMessage (WM_DEADCHAR {charCode, data}) = (0x0103, SysWord.fromInt(ord charCode), Word32.toLargeWord data, noFree)

    |   compileMessage (WM_SYSKEYDOWN {virtualKey, data}) = (0x0104, SysWord.fromInt virtualKey, Word32.toLargeWord data, noFree)

    |   compileMessage (WM_SYSKEYUP {virtualKey, data}) = (0x0105, SysWord.fromInt virtualKey, Word32.toLargeWord data, noFree)

    |   compileMessage (WM_SYSCHAR {charCode, data}) = (0x0106, SysWord.fromInt(ord charCode), Word32.toLargeWord data, noFree)

    |   compileMessage (WM_SYSDEADCHAR {charCode, data}) = (0x0107, SysWord.fromInt(ord charCode), Word32.toLargeWord data, noFree)
(*
WM_IME_STARTCOMPOSITION         0x010D
WM_IME_ENDCOMPOSITION           0x010E
WM_IME_COMPOSITION              0x010F
WM_IME_KEYLAST                  0x010F

*)

    |   compileMessage (WM_INITDIALOG { dialog, initdata}) =
            (0x0110, fromHWND dialog, SysWord.fromInt initdata, noFree)

    |   compileMessage (WM_COMMAND {notifyCode, wId, control}) =
            (0x0111, makeLong(wId, notifyCode), fromHWND control, noFree)

    |   compileMessage (WM_SYSCOMMAND {commandvalue, sysBits, p={x,y}}) =
            (0x0112, SysWord.fromInt(IntInf.orb(sysBits, fromSysCommand commandvalue)),
             makeLong(x,y), noFree)

    |   compileMessage (WM_TIMER {timerid}) = (0x0113, SysWord.fromInt timerid, 0w0, noFree)

    |   compileMessage (WM_HSCROLL {value, position, scrollbar}) =
            (0x0114, makeLong(Word.toInt(toCsd value), position), fromHWND scrollbar, noFree)

    |   compileMessage (WM_VSCROLL {value, position, scrollbar}) =
            (0x0115, makeLong(Word.toInt(toCsd value), position), fromHWND scrollbar, noFree)

    |   compileMessage (WM_INITMENU {menu}) =
            (0x0116, fromHMENU menu, 0w0, noFree)

    |   compileMessage (WM_INITMENUPOPUP {menupopup, itemposition, isSystemMenu}) =
            (0x0117, fromHMENU menupopup, makeLong(itemposition, btoi isSystemMenu), noFree)

    |   compileMessage (WM_MENUSELECT {menuitem, menuflags, menu}) =
            (0x011F, makeLong(menuitem, Word32.toInt(MenuBase.fromMenuFlagSet menuflags)), fromHMENU menu, noFree)

    |   compileMessage (WM_MENUCHAR { ch, menuflag, menu}) =
            (0x0120, makeLong(ord ch, Word32.toInt(MenuBase.fromMenuFlag menuflag)), fromHMENU menu, noFree)

    |   compileMessage (WM_ENTERIDLE { flag, window}) = (0x0121, SysWord.fromInt flag, fromHWND window, noFree)

    |   compileMessage (WM_CTLCOLORMSGBOX { displaycontext, messagebox}) =
            (0x0132, fromHDC displaycontext, fromHWND messagebox, noFree)

    |   compileMessage (WM_CTLCOLOREDIT { displaycontext, editcontrol}) =
            (0x0133, fromHDC displaycontext, fromHWND editcontrol, noFree)

    |   compileMessage (WM_CTLCOLORLISTBOX { displaycontext, listbox}) =
            (0x0134, fromHDC displaycontext, fromHWND listbox, noFree)

    |   compileMessage (WM_CTLCOLORBTN { displaycontext, button}) =
            (0x0135, fromHDC displaycontext, fromHWND button, noFree)

    |   compileMessage (WM_CTLCOLORDLG { displaycontext, dialogbox}) =
            (0x0136, fromHDC displaycontext, fromHWND dialogbox, noFree)

    |   compileMessage (WM_CTLCOLORSCROLLBAR { displaycontext, scrollbar}) =
            (0x0137, fromHDC displaycontext, fromHWND scrollbar, noFree)

    |   compileMessage (WM_CTLCOLORSTATIC { displaycontext, staticcontrol}) =
            (0x0138, fromHDC displaycontext, fromHWND staticcontrol, noFree)

(* Combobox messages. *)

    |   compileMessage (CB_GETEDITSEL args) = compileGetSel(0x0140, args)

    |   compileMessage (CB_LIMITTEXT{limit}) = (0x0141, SysWord.fromInt limit, 0w0, noFree)

    |   compileMessage (CB_SETEDITSEL{startPos, endPos}) =
            (0x0142, 0w0, makeLong(startPos, endPos), noFree)

    |   compileMessage (CB_ADDSTRING{text}) = compileStringAsLp(0x0143, 0w0, text)

    |   compileMessage (CB_DELETESTRING{index}) = (0x0144, SysWord.fromInt index, 0w0, noFree)

    |   compileMessage (CB_DIR{attrs, fileSpec}) = compileStringAsLp(0x0145, Word32.toLargeWord(toCcbal attrs), fileSpec)

    |   compileMessage CB_GETCOUNT = (0x0146, 0w0, 0w0, noFree)

    |   compileMessage CB_GETCURSEL = (0x0147, 0w0, 0w0, noFree)

    |   compileMessage (CB_GETLBTEXT {length, index, ...}) = compileStringRequest(0x0148, SysWord.fromInt index, length)

    |   compileMessage (CB_GETLBTEXTLEN{index}) = (0x0149, SysWord.fromInt index, 0w0, noFree)

    |   compileMessage (CB_INSERTSTRING{text, index}) = compileStringAsLp(0x014A, SysWord.fromInt index, text)

    |   compileMessage CB_RESETCONTENT = (0x014B, 0w0, 0w0, noFree)

    |   compileMessage (CB_FINDSTRING{text, indexStart}) = compileStringAsLp(0x014C, SysWord.fromInt indexStart, text)

    |   compileMessage (CB_SELECTSTRING{text, indexStart}) = compileStringAsLp(0x014D, SysWord.fromInt indexStart, text)

    |   compileMessage (CB_SETCURSEL{index}) = (0x014E, SysWord.fromInt index, 0w0, noFree)

    |   compileMessage (CB_SHOWDROPDOWN{show}) = (0x014F, SysWord.fromInt(btoi show), 0w0, noFree)

    |   compileMessage (CB_GETITEMDATA{index}) = (0x0150, SysWord.fromInt index, 0w0, noFree)

    |   compileMessage (CB_SETITEMDATA{index, data}) = (0x0151, SysWord.fromInt index, SysWord.fromInt data, noFree)

    |   compileMessage (CB_GETDROPPEDCONTROLRECT {rect=ref rect}) = compileGetRect(0x0152, 0w0, rect)

    |   compileMessage (CB_SETITEMHEIGHT{index, height}) = (0x0153, SysWord.fromInt index, SysWord.fromInt height, noFree)

    |   compileMessage (CB_GETITEMHEIGHT{index}) = (0x0154, SysWord.fromInt index, 0w0, noFree)

    |   compileMessage (CB_SETEXTENDEDUI{extended}) = (0x0155, SysWord.fromInt(btoi extended), 0w0, noFree)

    |   compileMessage CB_GETEXTENDEDUI = (0x0156, 0w0, 0w0, noFree)

    |   compileMessage CB_GETDROPPEDSTATE = (0x0157, 0w0, 0w0, noFree)

    |   compileMessage (CB_FINDSTRINGEXACT{text, indexStart}) = compileStringAsLp(0x0158, SysWord.fromInt indexStart, text)

    |   compileMessage (CB_SETLOCALE{locale}) = (0x0159, SysWord.fromInt locale, 0w0, noFree)

    |   compileMessage CB_GETLOCALE = (0x015A, 0w0, 0w0, noFree)

    |   compileMessage CB_GETTOPINDEX = (0x015b, 0w0, 0w0, noFree)

    |   compileMessage (CB_SETTOPINDEX{index}) = (0x015c, SysWord.fromInt index, 0w0, noFree)

    |   compileMessage CB_GETHORIZONTALEXTENT = (0x015d, 0w0, 0w0, noFree)

    |   compileMessage (CB_SETHORIZONTALEXTENT{extent}) = (0x015e, SysWord.fromInt extent, 0w0, noFree)

    |   compileMessage CB_GETDROPPEDWIDTH = (0x015f, 0w0, 0w0, noFree)

    |   compileMessage (CB_SETDROPPEDWIDTH{width}) = (0x0160, SysWord.fromInt width, 0w0, noFree)

    |   compileMessage (CB_INITSTORAGE{items, bytes}) = (0x0161, SysWord.fromInt items, SysWord.fromInt bytes, noFree)

(* Static control messages. *)

    |   compileMessage (STM_SETICON{icon}) = (0x0170, fromHICON icon, 0w0, noFree)

    |   compileMessage STM_GETICON = (0x0171, 0w0, 0w0, noFree)

    |   compileMessage (STM_SETIMAGE{imageType, image}) =
                (0x0172, SysWord.fromInt(toCit imageType), fromHGDIOBJ image, noFree)

    |   compileMessage (STM_GETIMAGE{imageType}) = (0x0173, SysWord.fromInt(toCit imageType), 0w0, noFree)

(* Listbox messages *)
    |   compileMessage (LB_ADDSTRING{text}) = compileStringAsLp(0x0180, 0w0, text)

    |   compileMessage (LB_INSERTSTRING{text, index}) = compileStringAsLp(0x0181, SysWord.fromInt index, text)

    |   compileMessage (LB_DELETESTRING{index}) = (0x0182, SysWord.fromInt index, 0w0, noFree)

    |   compileMessage (LB_SELITEMRANGEEX{first, last}) = (0x0183, SysWord.fromInt first, SysWord.fromInt last, noFree)

    |   compileMessage LB_RESETCONTENT = (0x0184, 0w0, 0w0, noFree)

    |   compileMessage (LB_SETSEL{select, index}) = (0x0185, SysWord.fromInt(btoi select), SysWord.fromInt index, noFree)

    |   compileMessage (LB_SETCURSEL{index}) = (0x0186, SysWord.fromInt index, 0w0, noFree)

    |   compileMessage (LB_GETSEL{index}) = (0x0187, SysWord.fromInt index, 0w0, noFree)

    |   compileMessage LB_GETCURSEL = (0x0188, 0w0, 0w0, noFree)

    |   compileMessage (LB_GETTEXT {length, index, ...}) = compileStringRequest(0x0189, SysWord.fromInt index, length)

    |   compileMessage (LB_GETTEXTLEN{index}) = (0x018A, SysWord.fromInt index, 0w0, noFree)

    |   compileMessage LB_GETCOUNT = (0x018B, 0w0, 0w0, noFree)

    |   compileMessage (LB_SELECTSTRING{text, indexStart}) = compileStringAsLp(0x018C, SysWord.fromInt indexStart, text)

    |   compileMessage (LB_DIR{attrs, fileSpec}) = compileStringAsLp(0x018D, Word32.toLargeWord(toCcbal attrs), fileSpec)

    |   compileMessage LB_GETTOPINDEX = (0x018E, 0w0, 0w0, noFree)

    |   compileMessage (LB_FINDSTRING{text, indexStart}) = compileStringAsLp (0x018F, SysWord.fromInt indexStart, text)

    |   compileMessage LB_GETSELCOUNT = (0x0190, 0w0, 0w0, noFree)

    |   compileMessage (LB_GETSELITEMS args) = compileGetSelItems(0x0191, args)

    |   compileMessage (LB_SETTABSTOPS{tabs}) = compileTabStops(0x0192, tabs)

    |   compileMessage LB_GETHORIZONTALEXTENT = (0x0193, 0w0, 0w0, noFree)

    |   compileMessage (LB_SETHORIZONTALEXTENT{extent}) = (0x0194, SysWord.fromInt extent, 0w0, noFree)

    |   compileMessage (LB_SETCOLUMNWIDTH{column}) = (0x0195, SysWord.fromInt column, 0w0, noFree)

    |   compileMessage (LB_ADDFILE{fileName}) = compileStringAsLp(0x0196, 0w0, fileName)

    |   compileMessage (LB_SETTOPINDEX{index}) = (0x0197, SysWord.fromInt index, 0w0, noFree)

    |   compileMessage (LB_GETITEMRECT{rect=ref rect, index}) = compileGetRect(0x0198, SysWord.fromInt index, rect)

    |   compileMessage (LB_GETITEMDATA{index}) = (0x0199, SysWord.fromInt index, 0w0, noFree)

    |   compileMessage (LB_SETITEMDATA{index, data}) = (0x019A, SysWord.fromInt index, SysWord.fromInt data, noFree)

    |   compileMessage (LB_SELITEMRANGE{select, first, last}) =
            (0x019B, SysWord.fromInt(btoi select), makeLong(first, last), noFree)

    |   compileMessage (LB_SETANCHORINDEX{index}) = (0x019C, SysWord.fromInt index, 0w0, noFree)

    |   compileMessage LB_GETANCHORINDEX = (0x019D, 0w0, 0w0, noFree)

    |   compileMessage (LB_SETCARETINDEX{index, scroll}) = (0x019E, SysWord.fromInt index, SysWord.fromInt(btoi scroll), noFree)

    |   compileMessage LB_GETCARETINDEX = (0x019F, 0w0, 0w0, noFree)

    |   compileMessage (LB_SETITEMHEIGHT{index, height}) =
                (0x01A0, SysWord.fromInt index, makeLong(height, 0), noFree)

    |   compileMessage (LB_GETITEMHEIGHT{index}) = (0x01A1, SysWord.fromInt index, 0w0, noFree)

    |   compileMessage (LB_FINDSTRINGEXACT{text, indexStart}) =
            compileStringAsLp(0x01A2, SysWord.fromInt indexStart, text)

    |   compileMessage (LB_SETLOCALE{locale}) = (0x01A5, SysWord.fromInt locale, 0w0, noFree)

    |   compileMessage LB_GETLOCALE = (0x01A6, 0w0, 0w0, noFree)

    |   compileMessage (LB_SETCOUNT{items}) = (0x01A7, SysWord.fromInt items, 0w0, noFree)

    |   compileMessage (LB_INITSTORAGE{items, bytes}) = (0x01A8, SysWord.fromInt items, SysWord.fromInt bytes, noFree)

    |   compileMessage (LB_ITEMFROMPOINT { point = {x, y}}) = (0x01A9, 0w0, makeLong(x,y), noFree)

    |   compileMessage (WM_MOUSEMOVE margs) = compileMouseMove(0x0200, margs)

    |   compileMessage (WM_LBUTTONDOWN margs) = compileMouseMove(0x0201, margs)

    |   compileMessage (WM_LBUTTONUP margs) = compileMouseMove(0x0202, margs)

    |   compileMessage (WM_LBUTTONDBLCLK margs) = compileMouseMove(0x0203, margs)

    |   compileMessage (WM_RBUTTONDOWN margs) = compileMouseMove(0x0204, margs)

    |   compileMessage (WM_RBUTTONUP margs) = compileMouseMove(0x0205, margs)

    |   compileMessage (WM_RBUTTONDBLCLK margs) = compileMouseMove(0x0206, margs)

    |   compileMessage (WM_MBUTTONDOWN margs) = compileMouseMove(0x0207, margs)

    |   compileMessage (WM_MBUTTONUP margs) = compileMouseMove(0x0208, margs)

    |   compileMessage (WM_MBUTTONDBLCLK margs) = compileMouseMove(0x0209, margs)
 (*
WM_MOUSEWHEEL                   0x020A
*)

    |   compileMessage (WM_PARENTNOTIFY { eventflag, idchild, value}) =
            (0x0210, makeLong(eventflag,idchild), SysWord.fromInt value, noFree)

    |   compileMessage (WM_ENTERMENULOOP {istrack}) = (0x0211, SysWord.fromInt(btoi istrack), 0w0, noFree)

    |   compileMessage (WM_EXITMENULOOP {istrack}) = (0x0212, SysWord.fromInt(btoi istrack), 0w0, noFree)

(*
WM_NEXTMENU                     0x0213
WM_SIZING                       0x0214
*)

    |   compileMessage (WM_CAPTURECHANGED {newCapture}) = (0x0215, 0w0, fromHWND newCapture, noFree)
(*
WM_MOVING                       0x0216
WM_POWERBROADCAST               0x0218
WM_DEVICECHANGE                 0x0219
*)

    |   compileMessage (WM_MDICREATE{class, title, instance, x, y, cx, cy, style, cdata}) =
            strAddrAsLp (0x0220, 0w0, fromMdiCreate(class,title,instance,x,y,cx,cy,style,cdata))

    |   compileMessage (WM_MDIDESTROY{child}) =
            (0x0221, fromHWND child, 0w0, noFree)

    |   compileMessage (WM_MDIRESTORE{child}) =
            (0x0223, fromHWND child, 0w0, noFree)

    |   compileMessage (WM_MDINEXT{child, flagnext}) =
            (0x0224, fromHWND child, SysWord.fromInt(btoi flagnext), noFree)

    |   compileMessage (WM_MDIMAXIMIZE{child}) =
            (0x0225, fromHWND child, 0w0, noFree)

    |   compileMessage (WM_MDITILE{tilingflag}) = (0x0226, Word32.toLargeWord(toCmdif tilingflag), 0w0, noFree)

    |   compileMessage (WM_MDICASCADE{skipDisabled}) =
            (0x0227, SysWord.fromInt(if skipDisabled then 2 else 0), 0w0, noFree)

    |   compileMessage WM_MDIICONARRANGE = (0x0228, 0w0, 0w0, noFree)

    |   compileMessage WM_MDIGETACTIVE = (0x0229, 0w0, 0w0 (* MUST be null *), noFree)

    |   compileMessage (WM_MDISETMENU{frameMenu, windowMenu}) =
            (0x0230, fromHMENU frameMenu, fromHMENU windowMenu, noFree)

    |   compileMessage WM_ENTERSIZEMOVE = (0x0231, 0w0, 0w0, noFree)

    |   compileMessage WM_EXITSIZEMOVE = (0x0232, 0w0, 0w0, noFree)

    |   compileMessage (WM_DROPFILES{hDrop}) = (0x0233, fromHDROP hDrop, 0w0, noFree)

    |   compileMessage WM_MDIREFRESHMENU = (0x0234, 0w0, 0w0, noFree)
(*
WM_IME_SETCONTEXT               0x0281
WM_IME_NOTIFY                   0x0282
WM_IME_CONTROL                  0x0283
WM_IME_COMPOSITIONFULL          0x0284
WM_IME_SELECT                   0x0285
WM_IME_CHAR                     0x0286
WM_IME_KEYDOWN                  0x0290
WM_IME_KEYUP                    0x0291
*)
    |   compileMessage (WM_NCMOUSEHOVER {hitTest, x, y}) =
            (0x02A0, SysWord.fromInt(fromHitTest hitTest), makeXYParam(x, y), noFree)

    |   compileMessage (WM_MOUSEHOVER margs) = compileMouseMove(0x02A1, margs)

    |   compileMessage WM_NCMOUSELEAVE = (0x02A2, 0w0, 0w0, noFree)

    |   compileMessage WM_MOUSELEAVE = (0x02A3, 0w0, 0w0, noFree)

    |   compileMessage WM_CUT = (0x0300, 0w0, 0w0, noFree)

    |   compileMessage WM_COPY = (0x0301, 0w0, 0w0, noFree)

    |   compileMessage WM_PASTE = (0x0302, 0w0, 0w0, noFree)

    |   compileMessage WM_CLEAR = (0x0303, 0w0, 0w0, noFree)

    |   compileMessage WM_UNDO = (0x0304, 0w0, 0w0, noFree)

    |   compileMessage (WM_RENDERFORMAT {format}) = (0x0305, SysWord.fromInt(toCcbf format), 0w0, noFree)

    |   compileMessage WM_RENDERALLFORMATS = (0x0306, 0w0, 0w0, noFree)

    |   compileMessage WM_DESTROYCLIPBOARD = (0x0307, 0w0, 0w0, noFree)

    |   compileMessage WM_DRAWCLIPBOARD = (0x0308, 0w0, 0w0, noFree)

    |   compileMessage (WM_PAINTCLIPBOARD{clipboard}) =
            (0x030A, fromHWND clipboard, 0w0, noFree)

    |   compileMessage (WM_VSCROLLCLIPBOARD{viewer, code, position}) =
            (0x030A, fromHWND viewer, makeLong(code, position), noFree)

    |   compileMessage (WM_SIZECLIPBOARD{viewer}) = (0x030B, 0w0, fromHWND viewer, noFree)

    |   compileMessage (WM_ASKCBFORMATNAME {length, ...}) = compileStringRequest(0x030C, SysWord.fromInt length, length)

    |   compileMessage (WM_CHANGECBCHAIN{removed, next}) =
            (0x030D, fromHWND removed, fromHWND next, noFree)

    |   compileMessage (WM_HSCROLLCLIPBOARD{viewer, code, position}) =
            (0x030E, fromHWND viewer, makeLong(code, position), noFree)

    |   compileMessage WM_QUERYNEWPALETTE = (0x030F, 0w0, 0w0, noFree)

    |   compileMessage (WM_PALETTEISCHANGING{realize}) =
            (0x0310, fromHWND realize, 0w0, noFree)

    |   compileMessage (WM_PALETTECHANGED{palChg}) =
            (0x0311, fromHWND palChg, 0w0, noFree)

    |   compileMessage (WM_HOTKEY{id}) = (0x0312, SysWord.fromInt id, 0w0, noFree)

    |   compileMessage (WM_PRINT{hdc, flags}) =
            (0x0317, fromHDC hdc, Word32.toLargeWord(toCwmpl flags), noFree)

    |   compileMessage (WM_PRINTCLIENT{hdc, flags}) =
            (0x0318, fromHDC hdc, Word32.toLargeWord(toCwmpl flags), noFree)

    |   compileMessage (FINDMSGSTRING args) = compileFindMsg args

    |   compileMessage (WM_SYSTEM_OTHER{uMsg, wParam, lParam}) = (uMsg, wParam, lParam, noFree)

    |   compileMessage (WM_USER{uMsg, wParam, lParam}) = (uMsg, wParam, lParam, noFree)

    |   compileMessage (WM_APP{uMsg, wParam, lParam}) = (uMsg, wParam, lParam, noFree)

    |   compileMessage (WM_REGISTERED{uMsg, wParam, lParam}) = (uMsg, wParam, lParam, noFree)

        local
            val msgStruct = cStruct6(cHWND, cUint, cUINT_PTRw, cUINT_PTRw, cDWORD, cPoint)
            val { load=loadMsg, store=storeMsg, ctype={size=msgSize, ... }, ... } =
                breakConversion msgStruct
        in
            (* Store the address of the message in the memory. *)
            fun storeMessage(v: voidStar, {msg, hwnd, time, pt}: MSG) =
            let
                val (msgId: int, wParam, lParam, freeMem) = compileMessage msg
                val mem = Memory.malloc msgSize
                val f = storeMsg(mem, (hwnd, msgId, wParam, lParam, Time.toMilliseconds time, pt))
            in
                setAddress(v, 0w0, mem);
                fn () => (freeMem(); f(); Memory.free mem)
            end
        
            fun loadMessage(v: voidStar): MSG =
            let
                val (hWnd, msgId, wParam, lParam, t, pt) = loadMsg v
                val msg = decompileMessage(msgId, wParam, lParam)
                val () =
                    case msg of WM_USER _ => TextIO.print(Int.toString msgId ^ "\n") | _ => ()
            in
                {
                    msg = msg,
                    hwnd = hWnd,
                    time = Time.fromMilliseconds t,
                    pt = pt
                }
            end
            
            val LPMSG: MSG conversion =
                makeConversion { load = loadMessage, store = storeMessage, ctype=LowLevel.cTypePointer }
            
            val msgSize = msgSize
        end

    (* Update the lParam/wParam values from the values in a returned message. This is needed
       if an ML callback makes a modification that has to be passed back to C. *)
    (* TODO: The rest of these. *)
    local
        fun copyString(_, _, 0) = () (* If the length is zero do nothing *)
        |   copyString(ptr: voidStar, s: string, length: int) =
        let
            open Memory
            fun copyChar(i, c) =
                if i < length then set8(ptr, Word.fromInt i, Byte.charToByte c) else ()
        in
            CharVector.appi copyChar s;
            (* Null terminate either at the end of the string or the buffer *)
            set8(ptr, Word.fromInt(Int.min(size s + 1, length-1)), 0w0)
        end
    in
        fun updateParamsFromMessage(msg: Message, wp: SysWord.word, lp: SysWord.word): unit =
            case msg of
                WM_GETTEXT{text = ref t, ...} => copyString(toAddr lp, t, SysWord.toInt wp)
            |   WM_ASKCBFORMATNAME{formatName = ref t, ...} => copyString(toAddr lp, t, SysWord.toInt wp)
            |   EM_GETLINE{result = ref t, size, ...} => copyString(toAddr lp, t, size)
            |   EM_GETRECT {rect = ref r} => toCrect(toAddr lp, r)
            |   EM_GETSEL args => updateGetSelParms({wp=wp, lp=lp}, args)
            |   CB_GETEDITSEL args => updateGetSelParms({wp=wp, lp=lp}, args)
            |   CB_GETLBTEXT {text = ref t, length, ...} => copyString(toAddr lp, t, length)
            |   CB_GETDROPPEDCONTROLRECT {rect = ref r} => toCrect(toAddr lp, r)
            |   SBM_GETRANGE {minPos=ref minPos, maxPos=ref maxPos} =>  
                    (ignore(storeInt(toAddr wp, minPos)); ignore(storeInt(toAddr lp, maxPos)))
            |   SBM_GETSCROLLINFO args => updateScrollInfo({wp=wp, lp=lp}, args)
            |   LB_GETTEXT {text = ref t, length, ...} => copyString(toAddr lp, t, length)
            |   LB_GETSELITEMS args => updateGetSelItemsParms({wp=wp, lp=lp}, args)
            |   LB_GETITEMRECT{rect = ref r, ...} => toCrect(toAddr lp, r)
            |   WM_NCCALCSIZE { newrect = ref r, ...} => toCrect(toAddr lp, r) (* This sets the first rect *)
            |   WM_MEASUREITEM args => updateMeasureItemParms({wp=wp, lp=lp}, args)
            |   WM_GETMINMAXINFO args => updateMinMaxParms({wp=wp, lp=lp}, args)
            |   WM_WINDOWPOSCHANGING args => updateWindowPosChangingParms({wp=wp, lp=lp}, args)
    (*      |   WM_NOTIFY{ notification=TTN_GETDISPINFO(ref s), ...} =>
                        (* This particular notification allows the result to be fed
                           back in several ways.  We copy into the char array. *)
                        assign charArray80 (offset 1 (Cpointer Cvoid) (offset 1 nmhdr (deref lp)))
                                (toCcharArray80 s) *)
                
            |   _ => ()
    end

    (* Update the message contents from the values of wParam/lParam.  This is used
       when a message has been sent or passed into C code that may have updated
       the message contents.  Casts certain message results to HGDIOBJ. *)
    fun messageReturnFromParams(msg: Message, wp: SysWord.word, lp: SysWord.word, reply: SysWord.word): LRESULT =
    let
        val () =
            (* For certain messages we need to extract the reply from the arguments. *)
        case msg of
            WM_GETTEXT{text, ...} =>
                text := (if reply = 0w0 then "" else fromCstring(toAddr lp))
        |   WM_ASKCBFORMATNAME{formatName, ...} =>
                formatName := (if reply = 0w0 then "" else fromCstring(toAddr lp))
        |   EM_GETLINE{result, ...} =>
                result := (if reply = 0w0 then "" else fromCstring(toAddr lp))
        |   EM_GETRECT { rect } => rect := fromCrect(toAddr lp)
        |   EM_GETSEL args => updateGetSelFromWpLp(args, {wp=wp, lp=lp})
        |   CB_GETEDITSEL args => updateGetSelFromWpLp(args, {wp=wp, lp=lp})
        |   CB_GETLBTEXT {text, ...} =>
                text := (if reply = 0w0 then "" else fromCstring(toAddr lp))
        |   CB_GETDROPPEDCONTROLRECT  { rect } => rect := fromCrect(toAddr lp)
        |   SBM_GETRANGE {minPos, maxPos} => (minPos := loadInt(toAddr wp); maxPos := loadInt(toAddr lp))

        |   SBM_GETSCROLLINFO {info, ...} =>
            let
                val ({minPos, maxPos, pageSize, pos, trackPos}, _) = toScrollInfo lp
            in
                info := {minPos = minPos, maxPos = maxPos, pageSize = pageSize,
                      pos = pos, trackPos = trackPos}
            end

        |   LB_GETTEXT {text, ...} =>
                text := (if reply = 0w0 then "" else fromCstring(toAddr lp))

        |   LB_GETSELITEMS args => updateGetSelItemsFromWpLp(args, {wp=wp, lp=lp, reply=reply})
        |   LB_GETITEMRECT{rect, ...} => rect := fromCrect(toAddr lp) (* This also has an item index *)
        |   WM_NCCALCSIZE { newrect, ...} =>
               (* Whatever the value of "validarea" we just look at the first rectangle. *)
                newrect := fromCrect (toAddr lp)

        |   WM_GETMINMAXINFO args => updateMinMaxFromWpLp(args, {wp=wp, lp=lp})

        |   WM_WINDOWPOSCHANGING wpCh =>
                updateCfromMLwmWindowPosChanging({wp=wp, lp=lp}, wpCh)

        |   WM_MEASUREITEM args => updateMeasureItemFromWpLp(args, {wp=wp, lp=lp})
        |   _ => ()
        
            val fromHgdi = handleOfVoidStar o toAddr
        in
            (* We need to "cast" some of the results. *)
        case msg of
            WM_GETFONT => LRESHANDLE(fromHgdi reply)
        |   WM_GETICON _ => LRESHANDLE(fromHgdi reply)
        |   WM_SETICON _ => LRESHANDLE(fromHgdi reply)
        |   BM_GETIMAGE _ => LRESHANDLE(fromHgdi reply)
        |   BM_SETIMAGE _ => LRESHANDLE(fromHgdi reply)
        |   STM_GETICON => LRESHANDLE(fromHgdi reply)
        |   STM_GETIMAGE _ => LRESHANDLE(fromHgdi reply)
        |   STM_SETICON _ => LRESHANDLE(fromHgdi reply)
        |   STM_SETIMAGE _ => LRESHANDLE(fromHgdi reply)
        |   _ => LRESINT (SysWord.toInt reply)
        end

        (* Window callback table. *)
        local
            type callback = HWND * int * SysWord.word * SysWord.word -> SysWord.word
            (* *)
            datatype tableEntry = TableEntry of {hWnd: HWND, callBack: callback}
            (* Windows belong to the thread that created them so each thread has
               its own list of windows.  Any thread could have one outstanding
               callback waiting to be assigned to a window that is being created. *)
            val threadWindows = Universal.tag(): tableEntry list Universal.tag
            val threadOutstanding = Universal.tag(): callback option Universal.tag

            (* This message is used to test if we are using the Poly callback.  We use
               the same number as MFC uses so it's unlikely that any Windows class will
               use this. *)
            val WMTESTPOLY = 0x0360
            fun getWindowList (): tableEntry list =
                getOpt (Thread.Thread.getLocal threadWindows, [])
            and setWindowList(t: tableEntry list): unit =
                Thread.Thread.setLocal(threadWindows, t)
                
            fun getOutstanding(): callback option =
                Option.join(Thread.Thread.getLocal threadOutstanding)
            and setOutstanding(t: callback option): unit =
                Thread.Thread.setLocal(threadOutstanding, t)

            (* Get the callback for this window.  If it's the first time we've
               had a message for this window we need to use the outstanding callback. *)
            fun getCallback(hw: HWND): callback =
                case List.find (fn (TableEntry{hWnd, ...}) =>
                        hw = hWnd) (getWindowList ())
                of
                     SOME(TableEntry{callBack, ...}) => callBack
                |    NONE => (* See if this has just been set up. *)
                        (case getOutstanding() of
                            SOME cb => (* It has.  We now know the window handle so link it up. *)
                                (
                                setWindowList(TableEntry{hWnd=hw, callBack=cb} :: getWindowList ());
                                setOutstanding NONE;
                                cb
                                )
                         |  NONE => raise Fail "No callback found"
                        )

            fun removeCallback(hw: HWND): unit =
                setWindowList(List.filter
                    (fn(TableEntry{hWnd, ...}) => hw <> hWnd) (getWindowList ()))

            fun mainCallbackFunction(hw:HWND, msgId:int, wParam:SysWord.word, lParam:SysWord.word): SysWord.word =
            if msgId = WMTESTPOLY
            then SysWord.fromInt ~1 (* This tests whether we are already installed. *)
            else getCallback hw (hw, msgId, wParam, lParam)

            val mainWinProc =
                buildClosure4withAbi(mainCallbackFunction, winAbi, (cHWND, cUint, cUINT_PTRw, cUINT_PTRw), cUINT_PTRw)
            
            val WNDPROC: (HWND * int * SysWord.word * SysWord.word -> SysWord.word) closure conversion = cFunction

            (* This is used to set the window proc.  The result is also a window proc. *)
            val SetWindowLong = winCall3 (user "SetWindowLongPtrA") (cHWND, cInt, WNDPROC) cPointer
            val CallWindowProc = winCall5 (user "CallWindowProcA") (cPointer, cHWND, cUint, cUINT_PTRw, cUINT_PTRw) cUINT_PTRw

        in
            val mainWinProc = mainWinProc
            and removeCallback = removeCallback

            fun windowCallback (call: HWND * Message * 'a -> LRESULT * 'a, init: 'a):
                    (HWND * int * SysWord.word * SysWord.word -> SysWord.word) =
                let
                    val state = ref init

                    fun callBack(h: HWND, uMsg:int, wParam: SysWord.word, lParam: SysWord.word): SysWord.word =
                    let
                        val msg = decompileMessage(uMsg, wParam, lParam)
                            handle exn =>
                                (
                                print(concat["Exception with message ",
                                        Int.toString uMsg, exnMessage exn ]);
                                WM_NULL
                                )
                        val (result, newState) =
                            call(h, msg, !state)
                                handle exn =>
                                (
                                print(concat["Exception with message ",
                                        PolyML.makestring msg,
                                        exnMessage exn ]);
                                (LRESINT 0, !state)
                                )
                    in
                        (* For a few messages we have to update the value pointed to
                           by wParam/lParam after we've handled it. *)
                        updateParamsFromMessage(msg, wParam, lParam);
                        state := newState;
                        (* If our callback returned SOME x we use that as the result,
                           otherwise we call the default.  We do it this way rather
                           than having the caller call DefWindowProc because that
                           would involve recompiling the message and we can't
                           guarantee that all the parameters of the original message
                           would be correctly set. *)
                        case result of
                            LRESINT res => SysWord.fromInt res
                        |   LRESHANDLE res => fromAddr(voidStarOfHandle res)
                    end;
                in
                    callBack
                end

            (* When we first set up a callback we don't know the window handle so we use null. *)
            fun setCallback(call, init) = setOutstanding(SOME(windowCallback(call, init)))

            val sendMsg = winCall4(user "SendMessageA") (cHWND, cUint, cUINT_PTRw, cUINT_PTRw) cUINT_PTRw

            fun subclass(w: HWND, f: HWND * Message * 'a -> LRESULT * 'a, init: 'a):
                    (HWND * Message -> LRESULT) =
            let
                
                val testPoly = sendMsg(w, WMTESTPOLY, 0w0, 0w0)

                fun addCallback (hWnd, call: HWND * Message * 'a -> LRESULT * 'a, init: 'a): unit =
                    setWindowList(
                        TableEntry{ hWnd = hWnd, callBack = windowCallback(call, init) } :: getWindowList ())

                val oldDefProc: callback =
                    if SysWord.toIntX testPoly = ~1
                    then (* We already have our Window proc installed. *)
                    let
                        (* We should have a callback already installed. *)
                        val oldCallback = getCallback w
                    in
                        removeCallback w;
                        addCallback(w, f, init);
                        oldCallback
                    end
                    else
                    let
                        (* Set up the new window proc and get the existing one. *)
                        val oldWProc = SetWindowLong(w, ~4, mainWinProc)
        
                        val defProc =
                            fn (h, m, w, l) => CallWindowProc(oldWProc, h, m, w, l)
                    in
                        (* Remove any existing callback function and install the new one. *)
                        removeCallback w;
                        addCallback(w, f, init);
                        defProc
                    end
            in
                fn (hw: HWND, msg: Message) =>
                let
                    val (m: int, w: SysWord.word, l: SysWord.word, freeMem) = compileMessage msg
                    val res: SysWord.word = oldDefProc(hw, m, w, l)
                in
                    messageReturnFromParams(msg, w, l, res)
                        before freeMem()
                end
            end
        end


        (* Keyboard operations on modeless dialogues are performed by isDialogMessage.
           We keep a list of modeless dialogues and process them in the main
           message loop.
           This also has an important function for dialogues created by FindText.
           They allocate memory which can't be freed until the dialogue has gone. *)
        local
            val modeless = ref []
            val isDialogMessage = winCall2 (user "IsDialogMessage") (cHWND, cPointer) cBool
            val isWindow = winCall1 (user "IsWindow") (cHWND) cBool
        in
            fun addModelessDialogue (hWnd: HWND, doFree) =
                modeless := (hWnd, doFree) :: (!modeless)

            fun isDialogueMsg(msg: voidStar) =
            let
                (* Take this opportunity to filter any dialogues that have gone away. *)
                (* If this has gone away run any "free" function.*)
                fun filter(w, f) =
                    if isWindow w
                    then true (* Still there *)
                    else (case f of NONE => () | SOME f => f(); false)
            in
                modeless := List.filter filter (!modeless);
                (* See if isDialogMessage returns true for any of these. *)
                List.foldl (fn ((w, _), b) => b orelse isDialogMessage(w, msg)) false (!modeless)
            end
        end

        datatype PeekMessageOptions = PM_NOREMOVE | PM_REMOVE
        (* TODO: We can also include PM_NOYIELD. *)

        val peekMsg = winCall5(user "PeekMessageA") (cPointer, cHWND, cUint, cUint, cUint) cBool

        fun PeekMessage(hWnd: HWND option, wMsgFilterMin: int,
                        wMsgFilterMax: int, remove: PeekMessageOptions): MSG option =
        let
            val msg = malloc msgSize
            
            val opts = case remove of PM_REMOVE => 1 | PM_NOREMOVE => 0
            val res = peekMsg(msg, getOpt(hWnd, hNull), wMsgFilterMin, wMsgFilterMax, opts)
        in
            (if not res
            then NONE
            else SOME(loadMessage msg)) before free msg
        end;

        (* TODO: This was originally implemented before we had threads.  The only reason
           for continuing with it is to allow the thread to be interrupted. *)
        local
            val callWin = RunCall.run_call2 RuntimeCalls.POLY_SYS_os_specific
        in
            fun pauseForMessage(hwnd: HWND, min, max): unit =
                callWin(1101, (hwnd, min, max))

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
            |   NONE =>
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
            val peekMsg = winCall5(user "PeekMessageA") (cPointer, cHWND, cUint, cUint, cUint) cBool
            val transMsg = winCall1(user "TranslateMessage") (cPointer) cBool
            val dispMsg = winCall1(user "DispatchMessageA") (cPointer) cInt
            val msg = malloc msgSize
            val res = peekMsg(msg, hNull, 0, 0, 1)
        in
            if not res
            then (* There's no message at the moment.  Wait for one. *)
                (free msg; WaitMessage(); RunApplication())
            else case loadMessage msg of
                { msg = WM_QUIT{exitcode}, ...} => (free msg; exitcode)
            |   _ =>
                (
                    if isDialogueMsg msg then ()
                    else ( transMsg msg; dispMsg msg; () );
                    free msg;
                    RunApplication()
                )
        end

        local
            val sendMsg = winCall4(user "SendMessageA") (cHWND, cUint, cUINT_PTRw, cUINT_PTRw) cUINT_PTRw
        in
            fun SendMessage(hWnd: HWND, msg: Message) =
            let
                val (msgId, wp, lp, freeMem) = compileMessage msg
                val reply = sendMsg(hWnd, msgId, wp, lp)
            in
                (* Update any result values and cast the results if necessary. *)
                messageReturnFromParams(msg, wp, lp, reply)
                    before freeMem()
            end
        end

        local
            val postMessage =
                winCall4(user "PostMessageA") (cHWND, cUint, cUINT_PTRw, cUINT_PTRw)
                    (successState "PostMessage")
        in
            fun PostMessage(hWnd: HWND, msg: Message) =
            let
                val (msgId, wp, lp, _) = compileMessage msg
                (* This could result in a memory leak. *)
            in
                postMessage(hWnd, msgId, wp, lp)
            end
        end

        val HWND_BROADCAST: HWND  = handleOfVoidStar(sysWord2VoidStar 0wxffff)

        val PostQuitMessage = winCall1 (user "PostQuitMessage") cInt cVoid
        val RegisterWindowMessage = winCall1 (user "RegisterWindowMessageA") (cString) cUint
        val InSendMessage = winCall0 (user "InSendMessage") () cBool
        val GetInputState = winCall0 (user "GetInputState") () cBool

        local
            val getMessagePos = winCall0 (user "GetMessagePos") () cDWORDw
        in
            fun GetMessagePos(): POINT =
            let
                val r = getMessagePos ()
            in
                { x = Word.toInt(LOWORD r), y = Word.toInt(HIWORD r) }
            end
        end

        val GetMessageTime = Time.fromMilliseconds o 
            winCall0 (user "GetMessageTime") () cLong

        datatype QueueStatus =
            QS_KEY | QS_MOUSEMOVE | QS_MOUSEBUTTON | QS_POSTMESSAGE | QS_TIMER |
            QS_PAINT | QS_SENDMESSAGE | QS_HOTKEY | QS_ALLPOSTMESSAGE
        local
            val tab = [
                (QS_KEY,              0wx0001),
                (QS_MOUSEMOVE,        0wx0002),
                (QS_MOUSEBUTTON,      0wx0004),
                (QS_POSTMESSAGE,      0wx0008),
                (QS_TIMER,            0wx0010),
                (QS_PAINT,            0wx0020),
                (QS_SENDMESSAGE,      0wx0040),
                (QS_HOTKEY,           0wx0080),
                (QS_ALLPOSTMESSAGE,   0wx0100)
            ]
        in
            val (fromQS, toQS) = tableSetLookup(tab, NONE)
        end

        val QS_MOUSE = [QS_MOUSEMOVE, QS_MOUSEBUTTON]
        val QS_INPUT = QS_KEY :: QS_MOUSE
        val QS_ALLEVENTS = QS_POSTMESSAGE :: QS_TIMER :: QS_PAINT :: QS_HOTKEY :: QS_INPUT
        val QS_ALLINPUT = QS_SENDMESSAGE :: QS_ALLEVENTS

        local
            val getQueueStatus = winCall1 (user "GetQueueStatus") (cUintw) cDWORDw
        in
            fun GetQueueStatus flags =
            let
                val res = getQueueStatus(fromQS flags)
            in
                (* The RTS uses PeekMessage internally so the "new messages"
                   value in the LOWORD is meaningless. *)
                toQS(Word32.fromLargeWord(Word.toLargeWord(HIWORD(res))))
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
