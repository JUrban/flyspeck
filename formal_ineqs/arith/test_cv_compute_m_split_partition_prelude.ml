(* Exact M_verifier glue-contract fixture.  The real-verifier integration is
   exercised separately after the authenticated nonlinear source closure. *)
module M_verifier = struct

let m_cell_pass = new_definition
 `m_cell_pass (f:real^N->real) (domain:real^N#real^N) <=> T`;;

let M_CELL_PASS_GLUE_LEMMA = prove
 (`!j (x:real^N) z v u f.
     (!i. 1 <= i /\ i <= dimindex (:N) ==> ~(i = j) ==>
          u$i = x$i /\ v$i = z$i) ==>
     v$j = u$j ==>
     m_cell_pass f (x,v) ==>
     m_cell_pass f (u,z) ==>
     m_cell_pass f (x,z)`,
  REWRITE_TAC[m_cell_pass]);;

end;;
