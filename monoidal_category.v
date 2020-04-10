From mathcomp Require Import all_ssreflect.
From mathcomp Require Import boolp.
Require Import monae_lib category.

(*
In this file:

- product category (product of two categories)

M1. monoidal cateogories
M2. monoidal closed categories
*)

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

(* A concrete category isomorphic to the product category of C and D *)
(* sum version *)
Module ProductCategory.
Section def.
Variable C D : category.
Definition obj := (C * D)%type.
Definition el (X : obj) : Type := (El X.1 + El X.2)%type.
Definition separated (X Y : obj) (f : el X -> el Y) : Prop :=
  (forall x : El X.1, exists y : El Y.1, f (inl x) = inl y) /\
  (forall x : El X.2, exists y : El Y.2, f (inr x) = inr y).

Section homfstsnd.
Let _homfst (X Y : obj) (f : el X -> el Y) : separated f -> El X.1 -> El Y.1.
case=> H _ x.
move/cid: (H x)=> [] y _.
exact y.
Defined.
Definition homfst := Eval hnf in _homfst.
Let _homsnd (X Y : obj) (f : el X -> el Y) : separated f -> El X.2 -> El Y.2.
case=> _ H x.
move/cid: (H x)=> [] y _.
exact y.
Defined.
Definition homsnd := Eval hnf in _homsnd.
End homfstsnd.

Lemma homfstK X Y (f : el X -> el Y) (Hf : separated f) (x : El X.1) :
  inl (homfst Hf x) = f (inl x).
Proof.
move: f Hf x.
case: X=> X1 X2; case:Y=> Y1 Y2 /= f [] /= Hf1 Hf2 x.
by case: (cid (Hf1 x))=> y ->.
Qed.
Lemma homsndK X Y (f : el X -> el Y) (Hf : separated f) (x : El X.2) :
  inr (homsnd Hf x) = f (inr x).
Proof.
move: f Hf x.
case: X=> X1 X2; case:Y=> Y1 Y2 /= f [] /= Hf1 Hf2 x.
by case: (cid (Hf2 x))=> y ->.
Qed.
Definition inhom (A B : obj) (f : el A -> el B) : Prop :=
  exists H : separated f, InHom (homfst H) /\ InHom (homsnd H).
Lemma idfun_separated (X : obj) : @separated X X idfun.
Proof. by split; move=> x; exists x. Qed.
Lemma comp_separated (X Y Z : obj) (f :el X -> el Y) (g : el Y -> el Z) :
  separated f -> separated g -> separated (g \o f).
Proof.
move: f g.
case: X=> X1 X2; case: Y=> Y1 Y2; case: Z=> Z1 Z2 f g [] /= Hf1 Hf2 [] /= Hg1 Hg2; split.
- by move=> x; case/cid: (Hf1 x)=> y /= ->; case/cid: (Hg1 y)=> z /= ->; exists z.
- by move=> x; case/cid: (Hf2 x)=> y /= ->; case/cid: (Hg2 y)=> z /= ->; exists z.
Qed.
Lemma homfst_idfun X : homfst (idfun_separated X) = idfun.
Proof.
apply funext=> x /=.
suff: inl (B:=El X.2) (homfst (idfun_separated X) x) = inl x by move=> [=].
by rewrite homfstK.
Qed.
Lemma homsnd_idfun X : homsnd (idfun_separated X) = idfun.
Proof.
apply funext=> x /=.
suff: inr (A:=El X.1) (homsnd (idfun_separated X) x) = inr x by move=> [=].
by rewrite homsndK.
Qed.
Lemma homfst_comp X Y Z (f : el X -> el Y) (g : el Y -> el Z)
      (Hf : separated f) (Hg : separated g) :
  homfst (comp_separated Hf Hg) = homfst Hg \o homfst Hf.
Proof.
apply funext=> x /=.
suff: inl (B:=El Z.2) (homfst (comp_separated Hf Hg) x) = inl (homfst Hg (homfst Hf x))
  by move => [=].
by rewrite 3!homfstK.
Qed.
Lemma homsnd_comp X Y Z (f : el X -> el Y) (g : el Y -> el Z)
      (Hf : separated f) (Hg : separated g) :
  homsnd (comp_separated Hf Hg) = homsnd Hg \o homsnd Hf.
Proof.
apply funext=> x /=.
suff: inr (A:=El Z.1) (homsnd (comp_separated Hf Hg) x) = inr (homsnd Hg (homsnd Hf x))
  by move => [=].
by rewrite 3!homsndK.
Qed.
Definition mixin : Category.mixin_of (C * D).
refine (@Category.Mixin obj el inhom _ _).
- by move=> X; exists (idfun_separated X); rewrite homfst_idfun homsnd_idfun; split; apply id_in_hom.
- by move=> X Y Z f g [] sf [] homfl homfr [] sg [] homgl homgr ; exists (comp_separated sf sg); rewrite homfst_comp homsnd_comp; split; apply funcomp_in_hom.
Defined.
End def.
End ProductCategory.
Definition productCategory (C D : category) := Category.Pack (ProductCategory.mixin C D).

Canonical productCategory.

Section prodcat_homfstsnd.
Variables A B : category.
Let _homfst (x y : A * B) (f : {hom x,y}) : {hom x.1, y.1}.
case:f => f.
case/cid=> sf [] Hf _.
exact: (HomPack Hf).
Defined.
Definition homfst := Eval hnf in _homfst.
Let _homsnd (x y : A * B) (f : {hom x,y}) : {hom x.2, y.2}.
case:f => f.
case/cid=> sf [] _ Hf.
exact: (HomPack Hf).
Defined.
Definition homsnd := Eval hnf in _homsnd.
End prodcat_homfstsnd.

Section prodCat_pairhom.
Variables A B : category.
Variables a1 a2 : A.
Variables b1 b2 : B.
Variables (f : {hom a1, a2}) (g : {hom b1, b2}).
Let C := productCategory A B.
Definition pairhom' (ab : El a1 + El b1) : El a2 + El b2 :=
  match ab with
  | inl a => inl (f a)
  | inr b => inr (g b)
  end.
Lemma pairhom'_in_hom :
  @InHom C _ _ (pairhom' : El (a1,b1).1 + El (a1,b1).2 ->
                           El (a2,b2).1 + El (a2,b2).2).
Proof.
rewrite /InHom /= /ProductCategory.inhom /=.
set s := ProductCategory.separated _.
have [/= s1 s2] : s by split => /= x; [exists (f x) | exists (g x)].
exists (conj s1 s2); split.
- set h := ProductCategory.homfst _.
  rewrite (_ : h = f); first exact: Hom.class.
  by rewrite boolp.funeqE => ?; rewrite /h /=; case: cid => ? [].
- set h := ProductCategory.homsnd _.
  rewrite (_ : h = g); first exact: Hom.class.
  by rewrite boolp.funeqE => ?; rewrite /h /=; case: cid => ? [].
Qed.
Definition pairhom : {hom (a1, b1), (a2, b2)} := Hom.Pack _ pairhom'_in_hom.
End prodCat_pairhom.

Module papply_left.
Section def.
Variables A B C : category.
Variable F' : functor (productCategory A B) C.
Variable a : A.
Definition F_obj : B -> C := fun b => F' (a, b).
Definition F_mor (b1 b2 : B) (f : {hom b1, b2}) : {hom F_obj b1, F_obj b2} :=
  F' # pairhom (idfun_hom a) f.
Program Definition mixin_of := @Functor.Mixin _ _ F_obj F_mor _ _.
Next Obligation.
move=> D; rewrite /F_mor; set h := pairhom _ _.
rewrite (_ : h = [hom of idfun]) ?functor_id_hom //.
by apply/hom_ext => /=; rewrite boolp.funeqE; case.
Qed.
Next Obligation.
move=> b b0 b1 g h; rewrite /F_mor; set i := pairhom _ _.
rewrite (_ : i = [hom of [fun of (pairhom (idfun_hom a) g)] \o
                         [fun of (pairhom (idfun_hom a) h)]]) ?functor_o_hom //.
by apply/hom_ext => /=; rewrite boolp.funeqE; case.
Qed.
Definition F := Functor.Pack mixin_of.
End def.
End papply_left.

Module papply_right.
Section def.
Variables A B C : category.
Variable F' : functor (productCategory A B) C.
Variable b : B.
Definition F_obj : A -> C := fun a => F' (a, b).
Definition F_mor (a1 a2 : A) (f : {hom a1, a2}) : {hom F_obj a1, F_obj a2} :=
  F' # pairhom f (idfun_hom b).
Program Definition mixin_of := @Functor.Mixin _ _ F_obj F_mor _ _.
Next Obligation.
move=> D; rewrite /F_mor; set h := pairhom _ _.
rewrite (_ : h = [hom of idfun]) ?functor_id_hom //.
by apply/hom_ext => /=; rewrite boolp.funeqE; case.
Qed.
Next Obligation.
move=> a a0 a1 g h; rewrite /F_mor; set i := pairhom _ _.
rewrite (_ : i = [hom of [fun of (pairhom g (idfun_hom b))] \o
                         [fun of (pairhom h (idfun_hom b))]]) ?functor_o_hom //.
by apply/hom_ext => /=; rewrite boolp.funeqE; case.
Qed.
Definition F := Functor.Pack mixin_of.
End def.
End papply_right.

Module ProductFunctor.
(* This notion does not have a proper name in the literature.
   "Product functor" is just a tentative naming,
   which unfortunately suffers a collision to another notion:
   the functor which maps two objects a, b \in C to their product a*b \in C 
*)
Section def.
Variables A1 B1 A2 B2 : category.
Variables (F1 : functor A1 B1) (F2 : functor A2 B2).
Local Notation A := (A1 * A2)%type.
Local Notation B := (B1 * B2)%type.
Definition acto (x : A) : B := pair (F1 x.1) (F2 x.2).
Definition actm (x y : A) (f : {hom x,y}) : {hom acto x, acto y} :=
  pairhom (F1 # ProductCategory.homfst f) (F2 # ProductCategory.homsnd f).
  F # 

End def.
End ProductFunctor.

Module alpha_left.
Section alpha_left.
Variables A B C D : category.
Variable F' : functor (productCategory (productCategory A B) C) D.
Variables (a : A) (b : B).
Definition acto : C -> D := papply_left.F F' (a, b).
Definition actm (c1 c2 : C) (f : {hom c1, c2}) : {hom acto c1, acto c2} :=
  F' # pairhom (idfun_hom (a, b)) f.
Program Definition mixin_of := @Functor.Mixin _ _ acto actm _ _.
Next Obligation.
move=> c0; rewrite /actm; set h := pairhom _ _.
rewrite (_ : h = [hom of idfun]) ?functor_id_hom //.
by apply/hom_ext => /=; rewrite boolp.funeqE; case.
Qed.
Next Obligation.
move=> c c0 c1 g h; rewrite /actm; set i := pairhom _ _.
rewrite (_ : i = [hom of [fun of (pairhom (idfun_hom (a, b)) g)] \o
                         [fun of (pairhom (idfun_hom (a, b)) h)]]) ?functor_o_hom //.
by apply/hom_ext => /=; rewrite boolp.funeqE; case.
Qed.
Definition F : functor C D := Functor.Pack mixin_of.
End alpha_left.
End alpha_left.

Module alpha_right.
Section alpha_right.
Variables A B C D : category.
Variable F' : functor (productCategory A (productCategory B C)) D.
Variables (a : A) (b : B).
Definition acto : C -> D := papply_left.F (papply_left.F F' a) b.
Definition actm (c1 c2 : C) (f : {hom c1, c2}) : {hom acto c1, acto c2}.
Admitted.
Program Definition mixin_of := @Functor.Mixin _ _ acto actm _ _.
Next Obligation.
Admitted.
Next Obligation.
Admitted.
Definition F : functor C D := Functor.Pack mixin_of.
End alpha_right.
End alpha_right.

Module prod_left.
Section prod_left.
Variable C : category.
Variable F' : functor (productCategory C C) C.
Let CCC := productCategory (productCategory C C) C.
Definition acto : CCC -> C := fun ccc => F' (F' ccc.1, ccc.2).
Definition actm (c1 c2 : CCC) (f : {hom c1, c2}) : {hom acto c1, acto c2}.
Admitted.
Program Definition mixin_of := @Functor.Mixin _ _ acto actm _ _.
Next Obligation.
Admitted.
Next Obligation.
Admitted.
Definition F : functor CCC C := Functor.Pack mixin_of.
End prod_left.
End prod_left.

Section prodCat_fsthom.
Variables A B : category.
Variables a1 a2 : A.
Let C := productCategory A B.
Variables c1 c2 : C.
Variables (f : {hom c1, c2}).
Definition fsthom : {hom a1, a2}. Admitted.
End prodCat_fsthom.

Section prodCat_sndhom.
Variables A B : category.
Variables b1 b2 : B.
Let C := productCategory A B.
Variables c1 c2 : C.
Variables (f : {hom c1, c2}).
Definition sndhom : {hom b1, b2}. Admitted.
End prodCat_sndhom.

Module prod_right.
Section prod_right.
Variable C : category.
Variable F' : functor (productCategory C C) C.
Let CCC := productCategory C (productCategory C C).
Definition acto : CCC -> C := fun ccc => F' (ccc.1, F' ccc.2).
Definition actm (c1 c2 : CCC) (f : {hom c1, c2}) : {hom acto c1, acto c2} :=
  F' # (pairhom (fsthom _ _ f) (F' # (sndhom _ _ f))).
Program Definition mixin_of := @Functor.Mixin _ _ acto actm _ _.
Next Obligation.
Admitted.
Next Obligation.
Admitted.
Definition F : functor (productCategory C (productCategory C C)) C.
Admitted.
End prod_right.
End prod_right.

Module MonoidalCategory.
Section def.
Import homcomp_notation.
Record mixin_of (C : category) : Type := Mixin {
  I : C;
  prod : functor (productCategory C C) C;
  lambda : papply_left.F prod I ~> FId ;
  rho : papply_right.F prod I ~> FId ;
(*  alpha' : forall (x y z : C), El (prod (prod (x,y), z)) -> El (prod (x, prod (y, z))) ;*)
  alpha : forall a b, alpha_left.F (prod_left.F prod) a b ~> alpha_right.F (prod_right.F prod) a b ;
}.
Section scratch_pad.
Variable C : category.
Variable m : mixin_of C.
Variable x : C.
Variable y : C.
Check (prod m # pairhom (rho m x) (NId FId y)).
Definition h : {hom alpha_right.F (prod_right.F (prod m)) x (I m) y, prod m (FId x, papply_left.F (prod m) (I m) y)}.
have f : El (alpha_right.F (prod_right.F (prod m)) x (I m) y) -> El (prod m (FId x, papply_left.F (prod m) (I m) y)).
  rewrite /alpha_right.F /=.
  rewrite /alpha_right.acto /=.
  rewrite /papply_left.F_obj /=.
Abort.
End scratch_pad.
Record class_of (T : Type) : Type := Class {
 base : Category.mixin_of T;
 mixin : mixin_of (Category.Pack base);
}.
Structure t : Type := Pack { T : Type; class : class_of T }.
End def.
Module Exports.
End Exports.
End MonoidalCategory.
Export MonoidalCategory.Exports.


(* Attic *)
(*
Module BifunctorLaws.
Section def.
Variable (A B C : category).
Variable (M : A * B -> C) (f : forall A B, {hom A,B} -> {hom M A, M B}).
Definition id := forall A, f [hom of idfun] = [hom of idfun] :> {hom M A,M A}.
Definition comp := forall A B C (g : {hom B,C}) (h : {hom A,B}),
  f [hom of g \o h] = [hom of f g \o f h] :> {hom M A,M C}.
End def.
End FunctorLaws.

Module Bifunctor.
Record mixin_of (C D : category) (m : C -> D) : Type := Mixin {
  f : forall A B, {hom A, B} -> {hom m A, m B} ;
  _ : FunctorLaws.id f ;
  _ : FunctorLaws.comp f }.
Structure t (C D : category) : Type := Pack { m : C -> D ; class : mixin_of m }.
Module Exports.
Section exports.
Variables (C D : category).
Definition Fun (F : t C D) : forall A B, {hom A, B} -> {hom m F A, m F B} :=
  let: Pack _ (Mixin f _ _) := F return forall A B, {hom A, B} -> {hom m F A, m F B} in f.
Arguments Fun _ [A] [B] : simpl never.
End exports.
Notation functor := t.
Coercion m : functor >-> Funclass.
End Exports.
End Functor.
Export Functor.Exports.
Notation "F # f" := (Fun F f).
 *)

(*
(* A similar construction.
   Related to another tensor product in Cat, like the funny tensor? *)
Module WeirdProductCategory.
Section def.
Variable C D : category.
Definition obj := (C * D)%type.
Definition el (X : obj) : Type := (El X.1 * El X.2)%type.
Definition independent (X Y : obj) (f : el X -> el Y) : Prop :=
  (forall (x : El X.1) (y y' : El X.2), fst (f (x,y)) = fst (f (x,y'))) /\
  (forall (x x': El X.1) (y : El X.2), snd (f (x,y)) = snd (f (x',y))).

Section homfstsnd.
Let _homfst (X Y : obj) (f : el X -> el Y) : independent f -> El X.1 -> El Y.1.
case=> H _ x.
move/cid: (H x)=> [] y _.
exact y.
Defined.
Definition homfst := Eval hnf in _homfst.
Let _homsnd (X Y : obj) (f : el X -> el Y) : separated f -> El X.2 -> El Y.2.
case=> _ H x.
move/cid: (H x)=> [] y _.
exact y.
Defined.
Definition homsnd := Eval hnf in _homsnd.
End homfstsnd.

Lemma homfstK X Y (f : el X -> el Y) (Hf : separated f) (x : El X.1) :
  inl (homfst Hf x) = f (inl x).
Proof.
move: f Hf x.
case: X=> X1 X2; case:Y=> Y1 Y2 /= f [] /= Hf1 Hf2 x.
by case: (cid (Hf1 x))=> y ->.
Qed.
Lemma homsndK X Y (f : el X -> el Y) (Hf : separated f) (x : El X.2) :
  inr (homsnd Hf x) = f (inr x).
Proof.
move: f Hf x.
case: X=> X1 X2; case:Y=> Y1 Y2 /= f [] /= Hf1 Hf2 x.
by case: (cid (Hf2 x))=> y ->.
Qed.
Definition inhom (A B : obj) (f : el A -> el B) : Prop :=
  exists H : separated f, InHom (homfst H) /\ InHom (homsnd H).
Lemma idfun_separated (X : obj) : @separated X X idfun.
Proof. by split; move=> x; exists x. Qed.
Lemma comp_separated (X Y Z : obj) (f :el X -> el Y) (g : el Y -> el Z) :
  separated f -> separated g -> separated (g \o f).
Proof.
move: f g.
case: X=> X1 X2; case: Y=> Y1 Y2; case: Z=> Z1 Z2 f g [] /= Hf1 Hf2 [] /= Hg1 Hg2; split.
- by move=> x; case/cid: (Hf1 x)=> y /= ->; case/cid: (Hg1 y)=> z /= ->; exists z.
- by move=> x; case/cid: (Hf2 x)=> y /= ->; case/cid: (Hg2 y)=> z /= ->; exists z.
Qed.
Lemma homfst_idfun X : homfst (idfun_separated X) = idfun.
Proof.
apply funext=> x /=.
suff: inl (B:=El X.2) (homfst (idfun_separated X) x) = inl x by move=> [=].
by rewrite homfstK.
Qed.
Lemma homsnd_idfun X : homsnd (idfun_separated X) = idfun.
Proof.
apply funext=> x /=.
suff: inr (A:=El X.1) (homsnd (idfun_separated X) x) = inr x by move=> [=].
by rewrite homsndK.
Qed.
Lemma homfst_comp X Y Z (f : el X -> el Y) (g : el Y -> el Z)
      (Hf : separated f) (Hg : separated g) :
  homfst (comp_separated Hf Hg) = homfst Hg \o homfst Hf.
Proof.
apply funext=> x /=.
suff: inl (B:=El Z.2) (homfst (comp_separated Hf Hg) x) = inl (homfst Hg (homfst Hf x))
  by move => [=].
by rewrite 3!homfstK.
Qed.
Lemma homsnd_comp X Y Z (f : el X -> el Y) (g : el Y -> el Z)
      (Hf : separated f) (Hg : separated g) :
  homsnd (comp_separated Hf Hg) = homsnd Hg \o homsnd Hf.
Proof.
apply funext=> x /=.
suff: inr (A:=El Z.1) (homsnd (comp_separated Hf Hg) x) = inr (homsnd Hg (homsnd Hf x))
  by move => [=].
by rewrite 3!homsndK.
Qed.
Definition mixin : Category.mixin_of (C * D).
refine (@Category.Mixin obj el inhom _ _).
- by move=> X; exists (idfun_separated X); rewrite homfst_idfun homsnd_idfun; split; apply id_in_hom.
- by move=> X Y Z f g [] sf [] homfl homfr [] sg [] homgl homgr ; exists (comp_separated sf sg); rewrite homfst_comp homsnd_comp; split; apply funcomp_in_hom.
Defined.
End def.
End WeirdProductCategory.
*)