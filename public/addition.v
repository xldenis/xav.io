Require Import  Coq.Classes.EquivDec.
Require Import  Coq.Arith.PeanoNat.
(*
  Boss: Hey, I need you to make a function called [add] which takes two naturals and returns a new one.
*)

Definition add_1 (a b : nat) : nat := a.

(* This isn't what I asked!
   add_1 1 2 is not the same thing as add_1 2 1!

   I need you to fix it! 
*)

Definition add_2 (a b : nat) : nat := if a == 1 then b else a.

Lemma test_1 : add_2 1 2 = add_2 2 1.
Proof.
  compute.
  reflexivity.
Qed.

(* I didn't mean for _ONLY_ 2 and 1, I meant that add n m = add m n!!! *)

Require Import Nat.

Definition add_3 (a b : nat) : nat := 0.

Lemma test_2 : forall a b : nat, add_3 a b = add_3 b a.
Proof.
  reflexivity.
Qed.

(* ok smart alec... Also, add n 1 should be the number after n *)

Definition add_4 (a b : nat) : nat :=
  match a, b with
  | 1, b => S b
  | a, 1 => S a
  | _, _ => 0
  end.

Lemma test_3 : forall a b : nat, add_4 a b = add_4 b a.
Proof.
  intros.
  destruct a, b.
  - reflexivity. 
  - reflexivity.
  - reflexivity.
  - simpl. destruct a, b; reflexivity.
Qed.

Lemma test_4 : forall n : nat, add_4 1 n = S n.
Proof.
  reflexivity.
Qed.

(* also, if we add 0 it shouldn't do anything *)

Definition add_5 (a b : nat) : nat :=
  match a, b with
  | 0, b => b
  | 1, b => S b
  | a, 0 => a
  | a, 1 => S a
  | _, _ => 0
  end.

Lemma test_5 : forall a b : nat, add_5 a b = add_5 b a.
Proof.
  intros.
  destruct a, b.
  - reflexivity.
  - simpl. destruct b; reflexivity.
  - simpl. destruct a; reflexivity.
  - simpl. destruct a, b; reflexivity.
Qed.

Lemma test_5_2 : forall n, add_5 1 n = S n.
Proof.
  reflexivity.
Qed.

Lemma test_5_3 : forall n, add_5 0 n = n.
Proof.
  reflexivity.
Qed.

  (* Well that's a lot better but I'd also like it if  add (add a b) c = add a (add b c) *)

Lemma test_6 : forall a b c : nat, add_5 a (add_5 b c) = add_5 (add_5 a b) c.
Proof.
  intros.
  destruct a, b, c.
  - reflexivity.
  - reflexivity.
  - reflexivity.
  - reflexivity.
  - simpl. rewrite test_5, test_5_3. reflexivity.
  - simpl. destruct a; simpl; try reflexivity.
  - rewrite test_5 with (a := S b), test_5 with (b := 0), !test_5_3.
    reflexivity.
  - simpl. destruct a, b, c; try reflexivity; simpl.
Abort.

Fixpoint add_6 (a b : nat) : nat :=
  match a with
  | 0 => b
  | (S n) => S (add_6 n b) 
  end.

Definition succ_prop f := forall n, f 1 n = S n.
Definition comm_prop (f : nat -> nat -> nat) := forall a b : nat, f a b = f b a.
Definition zero_prop (f : nat -> nat -> nat) := forall n : nat, f n 0 = n.
Definition assoc_prop (f : nat -> nat -> nat) := forall a b c, f a (f b c) = f (f a b) c.  

Lemma test_6_1 : forall n, add_6 n 0 = n.  
Proof.
  induction n; intros.
  - reflexivity.
  - simpl. rewrite IHn.
    reflexivity.
Qed.

Lemma test_6_2 : forall n, add_6 1 n = S n.
Proof.
  reflexivity.
Qed.

Lemma test_6 : forall a b : nat, add_6 a b = add_6 b a.
Proof.
  induction a; intros.
  - simpl. rewrite test_6_1.
    reflexivity.
  - induction b. 
    + simpl. rewrite test_6_1.
      easy.
    + simpl.
      rewrite <- IHb, IHa.
      simpl.
      rewrite IHa.
      reflexivity.
Qed.

Lemma test_6_3 : forall a b c, add_6 a (add_6 b c) = add_6 (add_6 a b) c.
Proof.
  induction a; intros.
  - rewrite test_6, test_6 with (a := 0), !test_6_1.
    reflexivity.
  - simpl. f_equal.
    apply IHa.
Qed.


Program Definition  add_6' : { f : nat -> nat -> nat | succ_prop f /\ comm_prop f /\ zero_prop f /\ assoc_prop f} := add_6.

Next Obligation.
  intuition.
  exact test_6_2.
  exact test_6.
  exact test_6_1.
  exact test_6_3.
Qed.
