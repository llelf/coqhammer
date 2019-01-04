From Hammer Require Import Hammer.












Require Import Arith.
Require Import Ascii.
Declare ML Module "string_syntax_plugin".





Inductive string : Set :=
| EmptyString : string
| String : ascii -> string -> string.

Delimit Scope string_scope with string.
Bind Scope string_scope with string.
Local Open Scope string_scope.



Definition string_dec : forall s1 s2 : string, {s1 = s2} + {s1 <> s2}.
Proof. hammer_hook "String" "String.string_dec". Restart. 
decide equality; apply ascii_dec.
Defined.



Reserved Notation "x ++ y" (right associativity, at level 60).

Fixpoint append (s1 s2 : string) : string :=
match s1 with
| EmptyString => s2
| String c s1' => String c (s1' ++ s2)
end
where "s1 ++ s2" := (append s1 s2) : string_scope.





Fixpoint length (s : string) : nat :=
match s with
| EmptyString => 0
| String c s' => S (length s')
end.





Fixpoint get (n : nat) (s : string) {struct s} : option ascii :=
match s with
| EmptyString => None
| String c s' => match n with
| O => Some c
| S n' => get n' s'
end
end.



Theorem get_correct :
forall s1 s2 : string, (forall n : nat, get n s1 = get n s2) <-> s1 = s2.
Proof. hammer_hook "String" "String.get_correct". Restart. 
intros s1; elim s1; simpl.
intros s2; case s2; simpl; split; auto.
intros H; generalize (H 0); intros H1; inversion H1.
intros; discriminate.
intros a s1' Rec s2; case s2; simpl; split; auto.
intros H; generalize (H 0); intros H1; inversion H1.
intros; discriminate.
intros H; generalize (H 0); simpl; intros H1; inversion H1.
case (Rec s).
intros H0; rewrite H0; auto.
intros n; exact (H (S n)).
intros H; injection H as H1 H2.
rewrite H2; trivial.
rewrite H1; auto.
Qed.



Theorem append_correct1 :
forall (s1 s2 : string) (n : nat),
n < length s1 -> get n s1 = get n (s1 ++ s2).
Proof. hammer_hook "String" "String.append_correct1". Restart. 
intros s1; elim s1; simpl; auto.
intros s2 n H; inversion H.
intros a s1' Rec s2 n; case n; simpl; auto.
intros n0 H; apply Rec; auto.
apply lt_S_n; auto.
Qed.



Theorem append_correct2 :
forall (s1 s2 : string) (n : nat),
get n s2 = get (n + length s1) (s1 ++ s2).
Proof. hammer_hook "String" "String.append_correct2". Restart. 
intros s1; elim s1; simpl; auto.
intros s2 n; rewrite plus_comm; simpl; auto.
intros a s1' Rec s2 n; case n; simpl; auto.
generalize (Rec s2 0); simpl; auto. intros.
rewrite <- Plus.plus_Snm_nSm; auto.
Qed.





Fixpoint substring (n m : nat) (s : string) : string :=
match n, m, s with
| 0, 0, _ => EmptyString
| 0, S m', EmptyString => s
| 0, S m', String c s' => String c (substring 0 m' s')
| S n', _, EmptyString => s
| S n', _, String c s' => substring n' m s'
end.



Theorem substring_correct1 :
forall (s : string) (n m p : nat),
p < m -> get p (substring n m s) = get (p + n) s.
Proof. hammer_hook "String" "String.substring_correct1". Restart. 
intros s; elim s; simpl; auto.
intros n; case n; simpl; auto.
intros m; case m; simpl; auto.
intros a s' Rec; intros n; case n; simpl; auto.
intros m; case m; simpl; auto.
intros p H; inversion H.
intros m' p; case p; simpl; auto.
intros n0 H; apply Rec; simpl; auto.
apply Lt.lt_S_n; auto.
intros n' m p H; rewrite <- Plus.plus_Snm_nSm; simpl; auto.
Qed.



Theorem substring_correct2 :
forall (s : string) (n m p : nat), m <= p -> get p (substring n m s) = None.
Proof. hammer_hook "String" "String.substring_correct2". Restart. 
intros s; elim s; simpl; auto.
intros n; case n; simpl; auto.
intros m; case m; simpl; auto.
intros a s' Rec; intros n; case n; simpl; auto.
intros m; case m; simpl; auto.
intros m' p; case p; simpl; auto.
intros H; inversion H.
intros n0 H; apply Rec; simpl; auto.
apply Le.le_S_n; auto.
Qed.





Fixpoint prefix (s1 s2 : string) {struct s2} : bool :=
match s1 with
| EmptyString => true
| String a s1' =>
match s2 with
| EmptyString => false
| String b s2' =>
match ascii_dec a b with
| left _ => prefix s1' s2'
| right _ => false
end
end
end.



Theorem prefix_correct :
forall s1 s2 : string,
prefix s1 s2 = true <-> substring 0 (length s1) s2 = s1.
Proof. hammer_hook "String" "String.prefix_correct". Restart. 
intros s1; elim s1; simpl; auto.
intros s2; case s2; simpl; split; auto.
intros a s1' Rec s2; case s2; simpl; auto.
split; intros; discriminate.
intros b s2'; case (ascii_dec a b); simpl; auto.
intros e; case (Rec s2'); intros H1 H2; split; intros H3; auto.
rewrite e; rewrite H1; auto.
apply H2; injection H3; auto.
intros n; split; intros; try discriminate.
case n; injection H; auto.
Qed.



Fixpoint index (n : nat) (s1 s2 : string) : option nat :=
match s2, n with
| EmptyString, 0 =>
match s1 with
| EmptyString => Some 0
| String a s1' => None
end
| EmptyString, S n' => None
| String b s2', 0 =>
if prefix s1 s2 then Some 0
else
match index 0 s1 s2' with
| Some n => Some (S n)
| None => None
end
| String b s2', S n' =>
match index n' s1 s2' with
| Some n => Some (S n)
| None => None
end
end.


Opaque prefix.



Theorem index_correct1 :
forall (n m : nat) (s1 s2 : string),
index n s1 s2 = Some m -> substring m (length s1) s2 = s1.
Proof. hammer_hook "String" "String.index_correct1". Restart. 
intros n m s1 s2; generalize n m s1; clear n m s1; elim s2; simpl;
auto.
intros n; case n; simpl; auto.
intros m s1; case s1; simpl; auto.
intros H; injection H as <-; auto.
intros; discriminate.
intros; discriminate.
intros b s2' Rec n m s1.
case n; simpl; auto.
generalize (prefix_correct s1 (String b s2'));
case (prefix s1 (String b s2')).
intros H0 H; injection H as <-; auto.
case H0; simpl; auto.
case m; simpl; auto.
case (index 0 s1 s2'); intros; discriminate.
intros m'; generalize (Rec 0 m' s1); case (index 0 s1 s2'); auto.
intros x H H0 H1; apply H; injection H1; auto.
intros; discriminate.
intros n'; case m; simpl; auto.
case (index n' s1 s2'); intros; discriminate.
intros m'; generalize (Rec n' m' s1); case (index n' s1 s2'); auto.
intros x H H1; apply H; injection H1; auto.
intros; discriminate.
Qed.



Theorem index_correct2 :
forall (n m : nat) (s1 s2 : string),
index n s1 s2 = Some m ->
forall p : nat, n <= p -> p < m -> substring p (length s1) s2 <> s1.
Proof. hammer_hook "String" "String.index_correct2". Restart. 
intros n m s1 s2; generalize n m s1; clear n m s1; elim s2; simpl;
auto.
intros n; case n; simpl; auto.
intros m s1; case s1; simpl; auto.
intros H; injection H as <-.
intros p H0 H2; inversion H2.
intros; discriminate.
intros; discriminate.
intros b s2' Rec n m s1.
case n; simpl; auto.
generalize (prefix_correct s1 (String b s2'));
case (prefix s1 (String b s2')).
intros H0 H; injection H as <-; auto.
intros p H2 H3; inversion H3.
case m; simpl; auto.
case (index 0 s1 s2'); intros; discriminate.
intros m'; generalize (Rec 0 m' s1); case (index 0 s1 s2'); auto.
intros x H H0 H1 p; try case p; simpl; auto.
intros H2 H3; red; intros H4; case H0.
intros H5 H6; absurd (false = true); auto with bool.
intros n0 H2 H3; apply H; auto.
injection H1; auto.
apply Le.le_O_n.
apply Lt.lt_S_n; auto.
intros; discriminate.
intros n'; case m; simpl; auto.
case (index n' s1 s2'); intros; discriminate.
intros m'; generalize (Rec n' m' s1); case (index n' s1 s2'); auto.
intros x H H0 p; case p; simpl; auto.
intros H1; inversion H1; auto.
intros n0 H1 H2; apply H; auto.
injection H0; auto.
apply Le.le_S_n; auto.
apply Lt.lt_S_n; auto.
intros; discriminate.
Qed.



Theorem index_correct3 :
forall (n m : nat) (s1 s2 : string),
index n s1 s2 = None ->
s1 <> EmptyString -> n <= m -> substring m (length s1) s2 <> s1.
Proof. hammer_hook "String" "String.index_correct3". Restart. 
intros n m s1 s2; generalize n m s1; clear n m s1; elim s2; simpl;
auto.
intros n; case n; simpl; auto.
intros m s1; case s1; simpl; auto.
case m; intros; red; intros; discriminate.
intros n' m; case m; auto.
intros s1; case s1; simpl; auto.
intros b s2' Rec n m s1.
case n; simpl; auto.
generalize (prefix_correct s1 (String b s2'));
case (prefix s1 (String b s2')).
intros; discriminate.
case m; simpl; auto with bool.
case s1; simpl; auto.
intros a s H H0 H1 H2; red; intros H3; case H.
intros H4 H5; absurd (false = true); auto with bool.
case s1; simpl; auto.
intros a s n0 H H0 H1 H2;
change (substring n0 (length (String a s)) s2' <> String a s);
apply (Rec 0); auto.
generalize H0; case (index 0 (String a s) s2'); simpl; auto; intros;
discriminate.
apply Le.le_O_n.
intros n'; case m; simpl; auto.
intros H H0 H1; inversion H1.
intros n0 H H0 H1; apply (Rec n'); auto.
generalize H; case (index n' s1 s2'); simpl; auto; intros;
discriminate.
apply Le.le_S_n; auto.
Qed.


Transparent prefix.



Theorem index_correct4 :
forall (n : nat) (s : string),
index n EmptyString s = None -> length s < n.
Proof. hammer_hook "String" "String.index_correct4". Restart. 
intros n s; generalize n; clear n; elim s; simpl; auto.
intros n; case n; simpl; auto.
intros; discriminate.
intros; apply Lt.lt_O_Sn.
intros a s' H n; case n; simpl; auto.
intros; discriminate.
intros n'; generalize (H n'); case (index n' EmptyString s'); simpl;
auto.
intros; discriminate.
intros H0 H1; apply Lt.lt_n_S; auto.
Qed.



Definition findex n s1 s2 :=
match index n s1 s2 with
| Some n => n
| None => 0
end.




