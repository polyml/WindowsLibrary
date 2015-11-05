(*
    Copyright (c) 2001, 2015
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

structure Resource :
  sig
    datatype ResourceType =
        RT_CURSOR | RT_BITMAP | RT_ICON | RT_MENU | RT_DIALOG | RT_STRING | RT_FONTDIR |
        RT_FONT | RT_ACCELERATOR | RT_RCDATA | RT_MESSAGETABLE | RT_GROUP_CURSOR |
        RT_GROUP_ICON | RT_VERSION | RT_DLGINCLUDE | RT_ANICURSOR | RT_ANIICON |
        RT_PLUGPLAY | RT_VXD

    type HRSRC
    type HRSRCGLOBAL
    type HINSTANCE

    datatype RESID = IdAsInt of int | IdAsString of string
    val MAKEINTRESOURCE : int -> RESID

    type HUPDATE

    val BeginUpdateResource : string * bool -> HUPDATE
    val EndUpdateResource : HUPDATE * bool -> unit
    val FindResource : HINSTANCE * RESID * ResourceType -> HRSRC
    val FindResourceEx : HINSTANCE * ResourceType * RESID * Locale.LANGID -> HRSRC
    val FreeLibrary : HINSTANCE -> unit
    val LoadLibrary : string -> HINSTANCE
    val LoadResource : HINSTANCE * HRSRC -> HRSRCGLOBAL
    val LoadString : HINSTANCE * RESID -> string
    val LockResource : HRSRCGLOBAL -> Word8Vector.vector
    val SizeofResource : HINSTANCE * HRSRC -> int
    val UpdateResource :
       HUPDATE * ResourceType * RESID * Locale.LANGID * Word8Vector.vector option -> unit
  end
 =
struct
    open Foreign
    open Base

    datatype RESID = datatype RESID

    fun MAKEINTRESOURCE i = 
        if i >= 0 andalso i < 65536 then IdAsInt i
        else raise Fail "resource id out of range"

    fun checkHandle h = (checkResult(not(isHNull h)); h)

    datatype ResourceType =
        RT_CURSOR | RT_BITMAP | RT_ICON | RT_MENU | RT_DIALOG | RT_STRING | RT_FONTDIR |
        RT_FONT | RT_ACCELERATOR | RT_RCDATA | RT_MESSAGETABLE | RT_GROUP_CURSOR |
        RT_GROUP_ICON | RT_VERSION | RT_DLGINCLUDE | RT_ANICURSOR | RT_ANIICON |
        RT_PLUGPLAY | RT_VXD

    local

        fun toRes 1 = RT_CURSOR | toRes 2 = RT_BITMAP | toRes 3 = RT_ICON | toRes 4 = RT_MENU
         |  toRes 5 = RT_DIALOG | toRes 6 = RT_STRING | toRes 7 = RT_FONTDIR | toRes 8 = RT_FONT
         |  toRes 9 = RT_ACCELERATOR | toRes 10 = RT_RCDATA | toRes 11 = RT_MESSAGETABLE
         |  toRes 12 = RT_GROUP_CURSOR | toRes 14 = RT_GROUP_ICON | toRes 16 = RT_VERSION
         |  toRes 17 = RT_DLGINCLUDE | toRes 19 = RT_PLUGPLAY | toRes 20 = RT_VXD
         |  toRes 21 = RT_ANICURSOR |  toRes 22 = RT_ANIICON
         |  toRes _ = raise Fail "Unknown Resource Type"

        fun fromRes RT_CURSOR = 1 | fromRes RT_BITMAP = 2 | fromRes RT_ICON = 3
         |  fromRes RT_MENU = 4 | fromRes RT_DIALOG = 5 | fromRes RT_STRING = 6
         |  fromRes RT_FONTDIR = 7 | fromRes RT_FONT = 8 | fromRes RT_ACCELERATOR = 9
         |  fromRes RT_RCDATA = 10 | fromRes RT_MESSAGETABLE = 11 | fromRes RT_GROUP_CURSOR = 12
         |  fromRes RT_GROUP_ICON = 14 | fromRes RT_VERSION = 16 | fromRes RT_DLGINCLUDE = 17
         |  fromRes RT_PLUGPLAY = 19 | fromRes RT_VXD = 20 | fromRes RT_ANICURSOR = 21
         |  fromRes RT_ANIICON = 22 
    in
        val RESOURCETYPE = 
            absConversion {abs = toRes, rep = fromRes} cInt
    end

    local
        datatype HRSRCGLOBAL = HRSRCGLOBAL of Memory.voidStar * int
    in
        type HRSRCGLOBAL = HRSRCGLOBAL

        val LoadLibrary = checkHandle o winCall1 (kernel "LoadLibraryA") (cString) cHINSTANCE
        and FreeLibrary = winCall1 (kernel "FreeLibrary") (cHINSTANCE) (successState "FreeLibrary")
        and FindResource = checkHandle o
            winCall3 (kernel "FindResourceA")
                (cHINSTANCE, cRESID, RESOURCETYPE) cHRSRC
        and SizeofResource = winCall2 (kernel "SizeofResource") (cHINSTANCE, cHRSRC) cDWORD
        (* The name and type are in the reverse order in FindResource and FindResourceEx *)
        and FindResourceEx = checkHandle o
             winCall4 (kernel "FindResourceExA")
                (cHINSTANCE, RESOURCETYPE, cRESID, LocaleBase.LANGID) cHRSRC

        (* LoadResource - load a resource into memory and get a handle to it. *)
        local
            val loadResource = winCall2 (kernel  "LoadResource") (cHINSTANCE, cHRSRC)
            and lockResource = winCall1 (kernel "LockResource") (cPointer) cPointer
            and loadString = winCall4 (user "LoadStringA") (cHINSTANCE, cRESID, cPointer, cInt) cInt
        in
            fun LoadResource (hInst, hRsrc) =
            let
                val size = SizeofResource (hInst, hRsrc)
                val load = loadResource cPointer
                val rsrc = load(hInst, hRsrc)
            in
                HRSRCGLOBAL(rsrc, size)
            end

            (* LockResource - get the resource as a piece of binary store. *)
            fun LockResource (HRSRCGLOBAL(hg, size)) =
            let
                val res = lockResource hg
            in
                Word8Vector.tabulate(size, fn i => Memory.get8(res, Word.fromInt i))
            end

            fun LoadString (hInst, resId): string =
            let
                (* The underlying call returns the number of bytes copied EXCLUDING the terminating null. *)
                (* The easiest way to make sure we have enough store is to loop. *)
                open Memory
                fun tryLoad n =
                let
                    val store = malloc n
                    val used = Word.fromInt(loadString(hInst, resId, store, Word.toInt n))
                in
                    (* We can't distinguish the empty string from a missing resource. *)
                    if used = 0w0 then ""
                    else if used < n-0w1
                    then fromCstring store before free store
                    else (free store; tryLoad(n*0w2))
                end
            in
                tryLoad 0w100
            end
        end

        val BeginUpdateResource =
            (fn c => (checkResult(not(isHNull c)); c)) o
            winCall2 (user "BeginUpdateResourceA") (cString, cBool) cHUPDATE

        val EndUpdateResource =
            winCall2 (user "EndUpdateResource") (cHUPDATE, cBool) (successState "EndUpdateResource")

        local
            val updateResource =
                winCall6 (user "UpdateResource")
                    (cHUPDATE, RESOURCETYPE, cRESID, LocaleBase.LANGID, cOptionPtr cByteArray, cInt)
                    (successState "UpdateResource")
        in
            (* NONE here means delete the resource, SOME means a value to store.  *)
            (* N.B. If updating a string the new value must be in Unicode. *)
            fun UpdateResource(hup, rt, resid, lang, v as SOME vec) =
                updateResource(hup, rt, resid, lang, v, Word8Vector.length vec)
            |   UpdateResource(hup, rt, resid, lang, NONE) =
                updateResource(hup, rt, resid, lang, NONE, 0)
        end
    end
end;
