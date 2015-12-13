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

structure Pen :
  sig
    type HPEN 
    datatype
      PenStyle =
          PS_ALTERNATE
        | PS_COSMETIC
        | PS_DASH
        | PS_DASHDOT
        | PS_DASHDOTDOT
        | PS_DOT
        | PS_ENDCAP_FLAT
        | PS_ENDCAP_ROUND
        | PS_ENDCAP_SQUARE
        | PS_GEOMETRIC
        | PS_INSIDEFRAME
        | PS_JOIN_BEVEL
        | PS_JOIN_MITER
        | PS_JOIN_ROUND
        | PS_NULL
        | PS_SOLID
        | PS_USERSTYLE

    type COLORREF = Color.COLORREF
    type LOGBRUSH = Brush.LOGBRUSH
    type LOGPEN = PenStyle * int option * COLORREF

    val CreatePen : PenStyle list * int * COLORREF -> HPEN
    val CreatePenIndirect : LOGPEN -> HPEN
    val ExtCreatePen : PenStyle list * int * LOGBRUSH * (int * int) list -> HPEN

  end =
struct
    local
        open Foreign Base
    in
        open GdiBase
        type HPEN = HPEN

        val CreatePen = winCall3 (gdi "CreatePen") (cPENSTYLE,cInt,cCOLORREF) (cHPEN)
        val CreatePenIndirect = winCall1 (gdi "CreatePenIndirect") (cConstStar cLOGPEN) (cHPEN)
        
        local
            val extCreatePen =
                winCall5 (gdi "ExtCreatePen")
                 (cPENSTYLE,cDWORD,cConstStar cLOGBRUSH,cDWORD,cPointer) (cHPEN)
            val PAIR = absConversion {abs = fn _ => raise Fail "PAIR", rep = MAKELONG} cDWORDw
            val list2v = list2Vector PAIR
        in

            fun ExtCreatePen (ps: PenStyle list, width, log: LOGBRUSH, dashSp: (int*int) list) = 
            let
                (* custom is supposed to be NULL if ps <> PS_USERSTYLE.  Make sure it is at least
                   NULL if the list is empty. *)
                val (custom, len) =
                    case dashSp of
                        [] => (Memory.null, 0)
                    |   _ => list2v (map (fn (i, j) => (Word.fromInt i, Word.fromInt j)) dashSp)
            in
                (extCreatePen(ps, width, log, len, custom)
                    handle ex => (Memory.free custom; raise ex)) before Memory.free custom
            end
        end
        
    end
end;
