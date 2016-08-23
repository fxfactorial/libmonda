(***************************************************************************)
(*                                                                         *)
(*                 Make OCaml native debugging awesome!                    *)
(*                                                                         *)
(*                   Mark Shinwell, Jane Street Europe                     *)
(*                                                                         *)
(*  Copyright (c) 2016 Jane Street Group, LLC                              *)
(*                                                                         *)
(*  Permission is hereby granted, free of charge, to any person obtaining  *)
(*  a copy of this software and associated documentation files             *)
(*  (the "Software"), to deal in the Software without restriction,         *)
(*  including without limitation the rights to use, copy, modify, merge,   *)
(*  publish, distribute, sublicense, and/or sell copies of the Software,   *)
(*  and to permit persons to whom the Software is furnished to do so,      *)
(*  subject to the following conditions:                                   *)
(*                                                                         *)
(*  The above copyright notice and this permission notice shall be         *)
(*  included in all copies or substantial portions of the Software.        *)
(*                                                                         *)
(*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,        *)
(*  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     *)
(*  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. *)
(*  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   *)
(*  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   *)
(*  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      *)
(*  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 *)
(*                                                                         *)
(***************************************************************************)

(* This module provides functions that navigate around GDB "values".  The
   upper levels of such a value may include synthetic parts that are constructed
   in the debugger's address space by virtue of DW_OP_implicit_pointer.  Once
   we get into a non-synthetic part, i.e. values that actually exist in the
   target program's memory, we never return to the synthetic world.  The
   value printer doesn't need to have any knowledge of which world is being
   traversed at any particular time. *)

module Make (D : Debugger_intf.S) = struct
  module Obj = D.Obj
  module Synthetic_ptr = D.Synthetic_ptr

  type t =
    | Exists_on_target of Obj.t
    | Synthetic_ptr of Synthetic_ptr.t

  let is_block t =
    match t with
    | Exists_on_target obj -> Obj.is_block obj
    | Synthetic_ptr _ -> true

  let is_int t = not (is_block t)

  let tag_exn t =
    match t with
    | Exists_on_target obj -> Obj.tag_exn obj
    | Synthetic_ptr ptr -> Synthetic_ptr.tag ptr

  let size_exn t =
    match t with
    | Exists_on_target obj -> Obj.size_exn obj
    | Synthetic_ptr ptr -> Synthetic_ptr.size ptr

  let field_exn t index =
    match t with
    | Exists_on_target obj -> Obj.field_exn obj index
    | Synthetic_ptr ptr -> Synthetic_ptr.field ptr index

  let field_as_addr_exn t index =
    match t with
    | Exists_on_target obj -> Obj.field_as_addr_exn obj index
    | Synthetic_ptr ptr -> Synthetic_ptr.field_as_addr_exn ptr index

  let address_of_field t index =
    match t with
    | Exists_on_target obj -> Some (Obj.address_of_field_exn t index)
    | Synthetic_ptr _ -> None

  let c_string_field_exn t index =
    match t with
    | Exists_on_target obj -> Obj.c_string_field_exn obj index
    | Synthetic_ptr ptr -> Synthetic_ptr.c_string_field_exn ptr index

  let float_field_exn t index =
    match t with
    | Exists_on_target obj -> Obj.c_float_field_exn obj index
    | Synthetic_ptr ptr -> Synthetic_ptr.c_float_field_exn ptr index

  let int t =
    match t with
    | Exists_on_target obj -> Some (Obj.int obj)
    | Synthetic_ptr _ -> None

  let string t =
    match t with
    | Exists_on_target obj -> Obj.string obj
    | Synthetic_ptr ptr -> Synthetic_ptr.string ptr

  let raw t =
    match t with
    | Exists_on_target obj -> Some (Obj.string obj)
    | Synthetic_ptr ptr -> None

  let print ppf t =
    match t with
    | Exists_on_target obj -> Obj.print ppf obj
    | Synthetic_ptr ptr -> Synthetic_ptr.print ppf obj
end
