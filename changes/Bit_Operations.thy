(*  Author:  Florian Haftmann, TUM
*)

section \<open>Bit operations in suitable algebraic structures\<close>

theory Bit_Operations
  imports Presburger Groups_List
begin

subsection \<open>Abstract bit structures\<close>

class semiring_bits = semiring_parity +
  assumes bits_induct [case_names stable rec]:
    \<open>(\<And>a. a div 2 = a \<Longrightarrow> P a)
     \<Longrightarrow> (\<And>a b. P a \<Longrightarrow> (of_bool b + 2 * a) div 2 = a \<Longrightarrow> P (of_bool b + 2 * a))
        \<Longrightarrow> P a\<close>
  assumes bits_div_0 [simp]: \<open>0 div a = 0\<close>
    and bits_div_by_1 [simp]: \<open>a div 1 = a\<close>
    and bits_mod_div_trivial [simp]: \<open>a mod b div b = 0\<close>
    and even_succ_div_2 [simp]: \<open>even a \<Longrightarrow> (1 + a) div 2 = a div 2\<close>
    and even_mask_div_iff: \<open>even ((2 ^ m - 1) div 2 ^ n) \<longleftrightarrow> 2 ^ n = 0 \<or> m \<le> n\<close>
    and exp_div_exp_eq: \<open>2 ^ m div 2 ^ n = of_bool (2 ^ m \<noteq> 0 \<and> m \<ge> n) * 2 ^ (m - n)\<close>
    and div_exp_eq: \<open>a div 2 ^ m div 2 ^ n = a div 2 ^ (m + n)\<close>
    and mod_exp_eq: \<open>a mod 2 ^ m mod 2 ^ n = a mod 2 ^ min m n\<close>
    and mult_exp_mod_exp_eq: \<open>m \<le> n \<Longrightarrow> (a * 2 ^ m) mod (2 ^ n) = (a mod 2 ^ (n - m)) * 2 ^ m\<close>
    and div_exp_mod_exp_eq: \<open>a div 2 ^ n mod 2 ^ m = a mod (2 ^ (n + m)) div 2 ^ n\<close>
    and even_mult_exp_div_exp_iff: \<open>even (a * 2 ^ m div 2 ^ n) \<longleftrightarrow> m > n \<or> 2 ^ n = 0 \<or> (m \<le> n \<and> even (a div 2 ^ (n - m)))\<close>
  fixes bit :: \<open>'a \<Rightarrow> nat \<Rightarrow> bool\<close>
  assumes bit_iff_odd: \<open>bit a n \<longleftrightarrow> odd (a div 2 ^ n)\<close>
begin

text \<open>
  Having \<^const>\<open>bit\<close> as definitional class operation
  takes into account that specific instances can be implemented
  differently wrt. code generation.
\<close>

lemma bits_div_by_0 [simp]:
  \<open>a div 0 = 0\<close>
  by (metis add_cancel_right_right bits_mod_div_trivial mod_mult_div_eq mult_not_zero)

lemma bits_1_div_2 [simp]:
  \<open>1 div 2 = 0\<close>
  using even_succ_div_2 [of 0] by simp

lemma bits_1_div_exp [simp]:
  \<open>1 div 2 ^ n = of_bool (n = 0)\<close>
  using div_exp_eq [of 1 1] by (cases n) simp_all

lemma even_succ_div_exp [simp]:
  \<open>(1 + a) div 2 ^ n = a div 2 ^ n\<close> if \<open>even a\<close> and \<open>n > 0\<close>
proof (cases n)
  case 0
  with that show ?thesis
    by simp
next
  case (Suc n)
  with \<open>even a\<close> have \<open>(1 + a) div 2 ^ Suc n = a div 2 ^ Suc n\<close>
  proof (induction n)
    case 0
    then show ?case
      by simp
  next
    case (Suc n)
    then show ?case
      using div_exp_eq [of _ 1 \<open>Suc n\<close>, symmetric]
      by simp
  qed
  with Suc show ?thesis
    by simp
qed

lemma even_succ_mod_exp [simp]:
  \<open>(1 + a) mod 2 ^ n = 1 + (a mod 2 ^ n)\<close> if \<open>even a\<close> and \<open>n > 0\<close>
  using div_mult_mod_eq [of \<open>1 + a\<close> \<open>2 ^ n\<close>] that
  apply simp
  by (metis local.add.left_commute local.add_left_cancel local.div_mult_mod_eq)

lemma bits_mod_by_1 [simp]:
  \<open>a mod 1 = 0\<close>
  using div_mult_mod_eq [of a 1] by simp

lemma bits_mod_0 [simp]:
  \<open>0 mod a = 0\<close>
  using div_mult_mod_eq [of 0 a] by simp

lemma bits_one_mod_two_eq_one [simp]:
  \<open>1 mod 2 = 1\<close>
  by (simp add: mod2_eq_if)

lemma bit_0 [simp]:
  \<open>bit a 0 \<longleftrightarrow> odd a\<close>
  by (simp add: bit_iff_odd)

lemma bit_Suc:
  \<open>bit a (Suc n) \<longleftrightarrow> bit (a div 2) n\<close>
  using div_exp_eq [of a 1 n] by (simp add: bit_iff_odd)

lemma bit_rec:
  \<open>bit a n \<longleftrightarrow> (if n = 0 then odd a else bit (a div 2) (n - 1))\<close>
  by (cases n) (simp_all add: bit_Suc)

lemma bit_0_eq [simp]:
  \<open>bit 0 = bot\<close>
  by (simp add: fun_eq_iff bit_iff_odd)

context
  fixes a
  assumes stable: \<open>a div 2 = a\<close>
begin

lemma bits_stable_imp_add_self:
  \<open>a + a mod 2 = 0\<close>
proof -
  have \<open>a div 2 * 2 + a mod 2 = a\<close>
    by (fact div_mult_mod_eq)
  then have \<open>a * 2 + a mod 2 = a\<close>
    by (simp add: stable)
  then show ?thesis
    by (simp add: mult_2_right ac_simps)
qed

lemma stable_imp_bit_iff_odd:
  \<open>bit a n \<longleftrightarrow> odd a\<close>
  by (induction n) (simp_all add: stable bit_Suc)

end

lemma bit_iff_idd_imp_stable:
  \<open>a div 2 = a\<close> if \<open>\<And>n. bit a n \<longleftrightarrow> odd a\<close>
using that proof (induction a rule: bits_induct)
  case (stable a)
  then show ?case
    by simp
next
  case (rec a b)
  from rec.prems [of 1] have [simp]: \<open>b = odd a\<close>
    by (simp add: rec.hyps bit_Suc)
  from rec.hyps have hyp: \<open>(of_bool (odd a) + 2 * a) div 2 = a\<close>
    by simp
  have \<open>bit a n \<longleftrightarrow> odd a\<close> for n
    using rec.prems [of \<open>Suc n\<close>] by (simp add: hyp bit_Suc)
  then have \<open>a div 2 = a\<close>
    by (rule rec.IH)
  then have \<open>of_bool (odd a) + 2 * a = 2 * (a div 2) + of_bool (odd a)\<close>
    by (simp add: ac_simps)
  also have \<open>\<dots> = a\<close>
    using mult_div_mod_eq [of 2 a]
    by (simp add: of_bool_odd_eq_mod_2)
  finally show ?case
    using \<open>a div 2 = a\<close> by (simp add: hyp)
qed

lemma exp_eq_0_imp_not_bit:
  \<open>\<not> bit a n\<close> if \<open>2 ^ n = 0\<close>
  using that by (simp add: bit_iff_odd)

definition
  possible_bit :: "'a itself \<Rightarrow> nat \<Rightarrow> bool"
  where
  "possible_bit tyrep n = (2 ^ n \<noteq> (0 :: 'a))"

lemma possible_bit_0[simp]:
  "possible_bit ty 0"
  by (simp add: possible_bit_def)

lemma fold_possible_bit:
  "2 ^ n = (0 :: 'a) \<longleftrightarrow> \<not> possible_bit TYPE('a) n"
  by (simp add: possible_bit_def)

lemmas impossible_bit = exp_eq_0_imp_not_bit[simplified fold_possible_bit]

lemma bit_imp_possible_bit:
  "bit a n \<Longrightarrow> possible_bit TYPE('a) n"
  by (rule ccontr) (simp add: impossible_bit)

lemma possible_bit_less_imp:
  "possible_bit tyrep i \<Longrightarrow> j \<le> i \<Longrightarrow> possible_bit tyrep j"
  using power_add[of "2 :: 'a" j "i - j"]
  by (clarsimp simp: possible_bit_def eq_commute[where a=0])

lemma possible_bit_min[simp]:
  "possible_bit tyrep (min i j) \<longleftrightarrow> possible_bit tyrep i \<or> possible_bit tyrep j"
  by (auto simp: min_def elim: possible_bit_less_imp)

lemma bit_eqI:
  \<open>a = b\<close> if \<open>\<And>n. possible_bit TYPE('a) n \<Longrightarrow> bit a n \<longleftrightarrow> bit b n\<close>
proof -
  have \<open>bit a n \<longleftrightarrow> bit b n\<close> for n
  proof (cases \<open>2 ^ n = 0\<close>)
    case True
    then show ?thesis
      by (simp add: exp_eq_0_imp_not_bit)
  next
    case False
    then show ?thesis
      by (rule that[unfolded possible_bit_def])
  qed
  then show ?thesis proof (induction a arbitrary: b rule: bits_induct)
    case (stable a)
    from stable(2) [of 0] have **: \<open>even b \<longleftrightarrow> even a\<close>
      by simp
    have \<open>b div 2 = b\<close>
    proof (rule bit_iff_idd_imp_stable)
      fix n
      from stable have *: \<open>bit b n \<longleftrightarrow> bit a n\<close>
        by simp
      also have \<open>bit a n \<longleftrightarrow> odd a\<close>
        using stable by (simp add: stable_imp_bit_iff_odd)
      finally show \<open>bit b n \<longleftrightarrow> odd b\<close>
        by (simp add: **)
    qed
    from ** have \<open>a mod 2 = b mod 2\<close>
      by (simp add: mod2_eq_if)
    then have \<open>a mod 2 + (a + b) = b mod 2 + (a + b)\<close>
      by simp
    then have \<open>a + a mod 2 + b = b + b mod 2 + a\<close>
      by (simp add: ac_simps)
    with \<open>a div 2 = a\<close> \<open>b div 2 = b\<close> show ?case
      by (simp add: bits_stable_imp_add_self)
  next
    case (rec a p)
    from rec.prems [of 0] have [simp]: \<open>p = odd b\<close>
      by simp
    from rec.hyps have \<open>bit a n \<longleftrightarrow> bit (b div 2) n\<close> for n
      using rec.prems [of \<open>Suc n\<close>] by (simp add: bit_Suc)
    then have \<open>a = b div 2\<close>
      by (rule rec.IH)
    then have \<open>2 * a = 2 * (b div 2)\<close>
      by simp
    then have \<open>b mod 2 + 2 * a = b mod 2 + 2 * (b div 2)\<close>
      by simp
    also have \<open>\<dots> = b\<close>
      by (fact mod_mult_div_eq)
    finally show ?case
      by (auto simp add: mod2_eq_if)
  qed
qed

lemma bit_eq_iff:
  \<open>a = b \<longleftrightarrow> (\<forall>n. possible_bit TYPE('a) n \<longrightarrow> bit a n \<longleftrightarrow> bit b n)\<close>
  by (auto intro: bit_eqI)

named_theorems bit_simps \<open>Simplification rules for \<^const>\<open>bit\<close>\<close>

lemma bit_exp_iff [bit_simps]:
  \<open>bit (2 ^ m) n \<longleftrightarrow> possible_bit TYPE('a) n \<and> m = n\<close>
  by (auto simp add: bit_iff_odd exp_div_exp_eq possible_bit_def)

lemma bit_1_iff [bit_simps]:
  \<open>bit 1 n \<longleftrightarrow> n = 0\<close>
  using bit_exp_iff [of 0 n]
  by auto

lemma bit_2_iff [bit_simps]:
  \<open>bit 2 n \<longleftrightarrow> possible_bit TYPE('a) 1 \<and> n = 1\<close>
  using bit_exp_iff [of 1 n] by auto

lemma even_bit_succ_iff:
  \<open>bit (1 + a) n \<longleftrightarrow> bit a n \<or> n = 0\<close> if \<open>even a\<close>
  using that by (cases \<open>n = 0\<close>) (simp_all add: bit_iff_odd)

lemma bit_double_iff [bit_simps]:
  \<open>bit (2 * a) n \<longleftrightarrow> bit a (n - 1) \<and> n \<noteq> 0 \<and> possible_bit TYPE('a) n\<close>
  using even_mult_exp_div_exp_iff [of a 1 n]
  by (cases n, auto simp add: bit_iff_odd ac_simps possible_bit_def)

lemma odd_bit_iff_bit_pred:
  \<open>bit a n \<longleftrightarrow> bit (a - 1) n \<or> n = 0\<close> if \<open>odd a\<close>
proof -
  from \<open>odd a\<close> obtain b where \<open>a = 2 * b + 1\<close> ..
  moreover have \<open>bit (2 * b) n \<or> n = 0 \<longleftrightarrow> bit (1 + 2 * b) n\<close>
    using even_bit_succ_iff by simp
  ultimately show ?thesis by (simp add: ac_simps)
qed

lemma bit_eq_rec:
  \<open>a = b \<longleftrightarrow> (even a \<longleftrightarrow> even b) \<and> a div 2 = b div 2\<close> (is \<open>?P = ?Q\<close>)
proof
  assume ?P
  then show ?Q
    by simp
next
  assume ?Q
  then have \<open>even a \<longleftrightarrow> even b\<close> and \<open>a div 2 = b div 2\<close>
    by simp_all
  show ?P
  proof (rule bit_eqI)
    fix n
    show \<open>bit a n \<longleftrightarrow> bit b n\<close>
    proof (cases n)
      case 0
      with \<open>even a \<longleftrightarrow> even b\<close> show ?thesis
        by simp
    next
      case (Suc n)
      moreover from \<open>a div 2 = b div 2\<close> have \<open>bit (a div 2) n = bit (b div 2) n\<close>
        by simp
      ultimately show ?thesis
        by (simp add: bit_Suc)
    qed
  qed
qed

lemma bit_mod_2_iff [simp]:
  \<open>bit (a mod 2) n \<longleftrightarrow> n = 0 \<and> odd a\<close>
  by (cases a rule: parity_cases) (simp_all add: bit_iff_odd)

lemma bit_mask_sub_iff:
  \<open>bit (2 ^ m - 1) n \<longleftrightarrow> possible_bit TYPE('a) n \<and> n < m\<close>
  by (simp add: bit_iff_odd even_mask_div_iff not_le possible_bit_def)

lemma exp_add_not_zero_imp:
  \<open>2 ^ m \<noteq> 0\<close> and \<open>2 ^ n \<noteq> 0\<close> if \<open>2 ^ (m + n) \<noteq> 0\<close>
proof -
  have \<open>\<not> (2 ^ m = 0 \<or> 2 ^ n = 0)\<close>
  proof (rule notI)
    assume \<open>2 ^ m = 0 \<or> 2 ^ n = 0\<close>
    then have \<open>2 ^ (m + n) = 0\<close>
      by (rule disjE) (simp_all add: power_add)
    with that show False ..
  qed
  then show \<open>2 ^ m \<noteq> 0\<close> and \<open>2 ^ n \<noteq> 0\<close>
    by simp_all
qed

lemma bit_disjunctive_add_iff:
  \<open>bit (a + b) n \<longleftrightarrow> bit a n \<or> bit b n\<close>
  if \<open>\<And>n. \<not> bit a n \<or> \<not> bit b n\<close>
proof (cases \<open>2 ^ n = 0\<close>)
  case True
  then show ?thesis
    by (simp add: exp_eq_0_imp_not_bit)
next
  case False
  with that show ?thesis proof (induction n arbitrary: a b)
    case 0
    from "0.prems"(1) [of 0] show ?case
      by auto
  next
    case (Suc n)
    from Suc.prems(1) [of 0] have even: \<open>even a \<or> even b\<close>
      by auto
    have bit: \<open>\<not> bit (a div 2) n \<or> \<not> bit (b div 2) n\<close> for n
      using Suc.prems(1) [of \<open>Suc n\<close>] by (simp add: bit_Suc)
    from Suc.prems(2) have \<open>2 * 2 ^ n \<noteq> 0\<close> \<open>2 ^ n \<noteq> 0\<close>
      by (auto simp add: mult_2)
    have \<open>a + b = (a div 2 * 2 + a mod 2) + (b div 2 * 2 + b mod 2)\<close>
      using div_mult_mod_eq [of a 2] div_mult_mod_eq [of b 2] by simp
    also have \<open>\<dots> = of_bool (odd a \<or> odd b) + 2 * (a div 2 + b div 2)\<close>
      using even by (auto simp add: algebra_simps mod2_eq_if)
    finally have \<open>bit ((a + b) div 2) n \<longleftrightarrow> bit (a div 2 + b div 2) n\<close>
      using \<open>2 * 2 ^ n \<noteq> 0\<close> by simp (simp_all flip: bit_Suc add: bit_double_iff possible_bit_def)
    also have \<open>\<dots> \<longleftrightarrow> bit (a div 2) n \<or> bit (b div 2) n\<close>
      using bit \<open>2 ^ n \<noteq> 0\<close> by (rule Suc.IH)
    finally show ?case
      by (simp add: bit_Suc)
  qed
qed

lemma
  exp_add_not_zero_imp_left: \<open>2 ^ m \<noteq> 0\<close>
  and exp_add_not_zero_imp_right: \<open>2 ^ n \<noteq> 0\<close>
  if \<open>2 ^ (m + n) \<noteq> 0\<close>
proof -
  have \<open>\<not> (2 ^ m = 0 \<or> 2 ^ n = 0)\<close>
  proof (rule notI)
    assume \<open>2 ^ m = 0 \<or> 2 ^ n = 0\<close>
    then have \<open>2 ^ (m + n) = 0\<close>
      by (rule disjE) (simp_all add: power_add)
    with that show False ..
  qed
  then show \<open>2 ^ m \<noteq> 0\<close> and \<open>2 ^ n \<noteq> 0\<close>
    by simp_all
qed

lemma exp_not_zero_imp_exp_diff_not_zero:
  \<open>2 ^ (n - m) \<noteq> 0\<close> if \<open>2 ^ n \<noteq> 0\<close>
proof (cases \<open>m \<le> n\<close>)
  case True
  moreover define q where \<open>q = n - m\<close>
  ultimately have \<open>n = m + q\<close>
    by simp
  with that show ?thesis
    by (simp add: exp_add_not_zero_imp_right)
next
  case False
  with that show ?thesis
    by simp
qed

end

lemma nat_bit_induct [case_names zero even odd]:
  "P n" if zero: "P 0"
    and even: "\<And>n. P n \<Longrightarrow> n > 0 \<Longrightarrow> P (2 * n)"
    and odd: "\<And>n. P n \<Longrightarrow> P (Suc (2 * n))"
proof (induction n rule: less_induct)
  case (less n)
  show "P n"
  proof (cases "n = 0")
    case True with zero show ?thesis by simp
  next
    case False
    with less have hyp: "P (n div 2)" by simp
    show ?thesis
    proof (cases "even n")
      case True
      then have "n \<noteq> 1"
        by auto
      with \<open>n \<noteq> 0\<close> have "n div 2 > 0"
        by simp
      with \<open>even n\<close> hyp even [of "n div 2"] show ?thesis
        by simp
    next
      case False
      with hyp odd [of "n div 2"] show ?thesis
        by simp
    qed
  qed
qed

instantiation nat :: semiring_bits
begin

definition bit_nat :: \<open>nat \<Rightarrow> nat \<Rightarrow> bool\<close>
  where \<open>bit_nat m n \<longleftrightarrow> odd (m div 2 ^ n)\<close>

instance
proof
  show \<open>P n\<close> if stable: \<open>\<And>n. n div 2 = n \<Longrightarrow> P n\<close>
    and rec: \<open>\<And>n b. P n \<Longrightarrow> (of_bool b + 2 * n) div 2 = n \<Longrightarrow> P (of_bool b + 2 * n)\<close>
    for P and n :: nat
  proof (induction n rule: nat_bit_induct)
    case zero
    from stable [of 0] show ?case
      by simp
  next
    case (even n)
    with rec [of n False] show ?case
      by simp
  next
    case (odd n)
    with rec [of n True] show ?case
      by simp
  qed
  show \<open>q mod 2 ^ m mod 2 ^ n = q mod 2 ^ min m n\<close>
    for q m n :: nat
    apply (auto simp add: less_iff_Suc_add power_add mod_mod_cancel split: split_min_lin)
    apply (metis div_mult2_eq mod_div_trivial mod_eq_self_iff_div_eq_0 mod_mult_self2_is_0 power_commutes)
    done
  show \<open>(q * 2 ^ m) mod (2 ^ n) = (q mod 2 ^ (n - m)) * 2 ^ m\<close> if \<open>m \<le> n\<close>
    for q m n :: nat
    using that
    apply (auto simp add: mod_mod_cancel div_mult2_eq power_add mod_mult2_eq le_iff_add split: split_min_lin)
    done
  show \<open>even ((2 ^ m - (1::nat)) div 2 ^ n) \<longleftrightarrow> 2 ^ n = (0::nat) \<or> m \<le> n\<close>
    for m n :: nat
    using even_mask_div_iff' [where ?'a = nat, of m n] by simp
  show \<open>even (q * 2 ^ m div 2 ^ n) \<longleftrightarrow> n < m \<or> (2::nat) ^ n = 0 \<or> m \<le> n \<and> even (q div 2 ^ (n - m))\<close>
    for m n q r :: nat
    apply (auto simp add: not_less power_add ac_simps dest!: le_Suc_ex)
    apply (metis (full_types) dvd_mult dvd_mult_imp_div dvd_power_iff_le not_less not_less_eq order_refl power_Suc)
    done
qed (auto simp add: div_mult2_eq mod_mult2_eq power_add power_diff bit_nat_def)

end

lemma possible_bit_nat[simp]:
  "possible_bit TYPE(nat) n"
  by (simp add: possible_bit_def)

lemma not_bit_Suc_0_Suc [simp]:
  \<open>\<not> bit (Suc 0) (Suc n)\<close>
  by (simp add: bit_Suc)

lemma not_bit_Suc_0_numeral [simp]:
  \<open>\<not> bit (Suc 0) (numeral n)\<close>
  by (simp add: numeral_eq_Suc)

lemma int_bit_induct [case_names zero minus even odd]:
  "P k" if zero_int: "P 0"
    and minus_int: "P (- 1)"
    and even_int: "\<And>k. P k \<Longrightarrow> k \<noteq> 0 \<Longrightarrow> P (k * 2)"
    and odd_int: "\<And>k. P k \<Longrightarrow> k \<noteq> - 1 \<Longrightarrow> P (1 + (k * 2))" for k :: int
proof (cases "k \<ge> 0")
  case True
  define n where "n = nat k"
  with True have "k = int n"
    by simp
  then show "P k"
  proof (induction n arbitrary: k rule: nat_bit_induct)
    case zero
    then show ?case
      by (simp add: zero_int)
  next
    case (even n)
    have "P (int n * 2)"
      by (rule even_int) (use even in simp_all)
    with even show ?case
      by (simp add: ac_simps)
  next
    case (odd n)
    have "P (1 + (int n * 2))"
      by (rule odd_int) (use odd in simp_all)
    with odd show ?case
      by (simp add: ac_simps)
  qed
next
  case False
  define n where "n = nat (- k - 1)"
  with False have "k = - int n - 1"
    by simp
  then show "P k"
  proof (induction n arbitrary: k rule: nat_bit_induct)
    case zero
    then show ?case
      by (simp add: minus_int)
  next
    case (even n)
    have "P (1 + (- int (Suc n) * 2))"
      by (rule odd_int) (use even in \<open>simp_all add: algebra_simps\<close>)
    also have "\<dots> = - int (2 * n) - 1"
      by (simp add: algebra_simps)
    finally show ?case
      using even.prems by simp
  next
    case (odd n)
    have "P (- int (Suc n) * 2)"
      by (rule even_int) (use odd in \<open>simp_all add: algebra_simps\<close>)
    also have "\<dots> = - int (Suc (2 * n)) - 1"
      by (simp add: algebra_simps)
    finally show ?case
      using odd.prems by simp
  qed
qed

context semiring_bits
begin

lemma bit_of_bool_iff [bit_simps]:
  \<open>bit (of_bool b) n \<longleftrightarrow> b \<and> n = 0\<close>
  by (simp add: bit_1_iff)

lemma bit_of_nat_iff [bit_simps]:
  \<open>bit (of_nat m) n \<longleftrightarrow> possible_bit TYPE('a) n \<and> bit m n\<close>
proof (cases \<open>(2::'a) ^ n = 0\<close>)
  case True
  then show ?thesis
    by (simp add: exp_eq_0_imp_not_bit possible_bit_def)
next
  case False
  then have \<open>bit (of_nat m) n \<longleftrightarrow> bit m n\<close>
  proof (induction m arbitrary: n rule: nat_bit_induct)
    case zero
    then show ?case
      by simp
  next
    case (even m)
    then show ?case
      by (cases n)
        (auto simp add: bit_double_iff Bit_Operations.bit_double_iff possible_bit_def dest: mult_not_zero)
  next
    case (odd m)
    then show ?case
      by (cases n)
         (auto simp add: bit_double_iff even_bit_succ_iff possible_bit_def Bit_Operations.bit_Suc dest: mult_not_zero)
  qed
  with False show ?thesis
    by (simp add: possible_bit_def)
qed

end

instantiation int :: semiring_bits
begin

definition bit_int :: \<open>int \<Rightarrow> nat \<Rightarrow> bool\<close>
  where \<open>bit_int k n \<longleftrightarrow> odd (k div 2 ^ n)\<close>

instance
proof
  show \<open>P k\<close> if stable: \<open>\<And>k. k div 2 = k \<Longrightarrow> P k\<close>
    and rec: \<open>\<And>k b. P k \<Longrightarrow> (of_bool b + 2 * k) div 2 = k \<Longrightarrow> P (of_bool b + 2 * k)\<close>
    for P and k :: int
  proof (induction k rule: int_bit_induct)
    case zero
    from stable [of 0] show ?case
      by simp
  next
    case minus
    from stable [of \<open>- 1\<close>] show ?case
      by simp
  next
    case (even k)
    with rec [of k False] show ?case
      by (simp add: ac_simps)
  next
    case (odd k)
    with rec [of k True] show ?case
      by (simp add: ac_simps)
  qed
  show \<open>(2::int) ^ m div 2 ^ n = of_bool ((2::int) ^ m \<noteq> 0 \<and> n \<le> m) * 2 ^ (m - n)\<close>
    for m n :: nat
  proof (cases \<open>m < n\<close>)
    case True
    then have \<open>n = m + (n - m)\<close>
      by simp
    then have \<open>(2::int) ^ m div 2 ^ n = (2::int) ^ m div 2 ^ (m + (n - m))\<close>
      by simp
    also have \<open>\<dots> = (2::int) ^ m div (2 ^ m * 2 ^ (n - m))\<close>
      by (simp add: power_add)
    also have \<open>\<dots> = (2::int) ^ m div 2 ^ m div 2 ^ (n - m)\<close>
      by (simp add: zdiv_zmult2_eq)
    finally show ?thesis using \<open>m < n\<close> by simp
  next
    case False
    then show ?thesis
      by (simp add: power_diff)
  qed
  show \<open>k mod 2 ^ m mod 2 ^ n = k mod 2 ^ min m n\<close>
    for m n :: nat and k :: int
    using mod_exp_eq [of \<open>nat k\<close> m n]
    apply (auto simp add: mod_mod_cancel zdiv_zmult2_eq power_add zmod_zmult2_eq le_iff_add split: split_min_lin)
     apply (auto simp add: less_iff_Suc_add mod_mod_cancel power_add)
    apply (simp only: flip: mult.left_commute [of \<open>2 ^ m\<close>])
    apply (subst zmod_zmult2_eq) apply simp_all
    done
  show \<open>(k * 2 ^ m) mod (2 ^ n) = (k mod 2 ^ (n - m)) * 2 ^ m\<close>
    if \<open>m \<le> n\<close> for m n :: nat and k :: int
    using that
    apply (auto simp add: power_add zmod_zmult2_eq le_iff_add split: split_min_lin)
    done
  show \<open>even ((2 ^ m - (1::int)) div 2 ^ n) \<longleftrightarrow> 2 ^ n = (0::int) \<or> m \<le> n\<close>
    for m n :: nat
    using even_mask_div_iff' [where ?'a = int, of m n] by simp
  show \<open>even (k * 2 ^ m div 2 ^ n) \<longleftrightarrow> n < m \<or> (2::int) ^ n = 0 \<or> m \<le> n \<and> even (k div 2 ^ (n - m))\<close>
    for m n :: nat and k l :: int
    apply (auto simp add: not_less power_add ac_simps dest!: le_Suc_ex)
    apply (metis Suc_leI dvd_mult dvd_mult_imp_div dvd_power_le dvd_refl power.simps(2))
    done
qed (auto simp add: zdiv_zmult2_eq zmod_zmult2_eq power_add power_diff not_le bit_int_def)

end

lemma possible_bit_int[simp]:
  "possible_bit TYPE(int) n"
  by (simp add: possible_bit_def)

lemma bit_not_int_iff':
  \<open>bit (- k - 1) n \<longleftrightarrow> \<not> bit k n\<close>
  for k :: int
proof (induction n arbitrary: k)
  case 0
  show ?case
    by simp
next
  case (Suc n)
  have \<open>- k - 1 = - (k + 2) + 1\<close>
    by simp
  also have \<open>(- (k + 2) + 1) div 2 = - (k div 2) - 1\<close>
  proof (cases \<open>even k\<close>)
    case True
    then have \<open>- k div 2 = - (k div 2)\<close>
      by rule (simp flip: mult_minus_right)
    with True show ?thesis
      by simp
  next
    case False
    have \<open>4 = 2 * (2::int)\<close>
      by simp
    also have \<open>2 * 2 div 2 = (2::int)\<close>
      by (simp only: nonzero_mult_div_cancel_left)
    finally have *: \<open>4 div 2 = (2::int)\<close> .
    from False obtain l where k: \<open>k = 2 * l + 1\<close> ..
    then have \<open>- k - 2 = 2 * - (l + 2) + 1\<close>
      by simp
    then have \<open>(- k - 2) div 2 + 1 = - (k div 2) - 1\<close>
      by (simp flip: mult_minus_right add: *) (simp add: k)
    with False show ?thesis
      by simp
  qed
  finally have \<open>(- k - 1) div 2 = - (k div 2) - 1\<close> .
  with Suc show ?case
    by (simp add: bit_Suc)
qed

lemma bit_nat_iff [bit_simps]:
  \<open>bit (nat k) n \<longleftrightarrow> k \<ge> 0 \<and> bit k n\<close>
proof (cases \<open>k \<ge> 0\<close>)
  case True
  moreover define m where \<open>m = nat k\<close>
  ultimately have \<open>k = int m\<close>
    by simp
  then show ?thesis
    by (simp add: bit_simps)
next
  case False
  then show ?thesis
    by simp
qed


subsection \<open>Bit operations\<close>

class semiring_bit_operations = semiring_bits +
  fixes "and" :: \<open>'a \<Rightarrow> 'a \<Rightarrow> 'a\<close>  (infixr \<open>AND\<close> 64)
    and or :: \<open>'a \<Rightarrow> 'a \<Rightarrow> 'a\<close>  (infixr \<open>OR\<close> 59)
    and xor :: \<open>'a \<Rightarrow> 'a \<Rightarrow> 'a\<close>  (infixr \<open>XOR\<close> 59)
    and mask :: \<open>nat \<Rightarrow> 'a\<close>
    and set_bit :: \<open>nat \<Rightarrow> 'a \<Rightarrow> 'a\<close>
    and unset_bit :: \<open>nat \<Rightarrow> 'a \<Rightarrow> 'a\<close>
    and flip_bit :: \<open>nat \<Rightarrow> 'a \<Rightarrow> 'a\<close>
    and push_bit :: \<open>nat \<Rightarrow> 'a \<Rightarrow> 'a\<close>
    and drop_bit :: \<open>nat \<Rightarrow> 'a \<Rightarrow> 'a\<close>
    and take_bit :: \<open>nat \<Rightarrow> 'a \<Rightarrow> 'a\<close>
  assumes bit_and_iff [bit_simps]: \<open>bit (a AND b) n \<longleftrightarrow> bit a n \<and> bit b n\<close>
    and bit_or_iff [bit_simps]: \<open>bit (a OR b) n \<longleftrightarrow> bit a n \<or> bit b n\<close>
    and bit_xor_iff [bit_simps]: \<open>bit (a XOR b) n \<longleftrightarrow> bit a n \<noteq> bit b n\<close>
    and mask_eq_exp_minus_1: \<open>mask n = 2 ^ n - 1\<close>
    and set_bit_eq_or: \<open>set_bit n a = a OR push_bit n 1\<close>
    and bit_unset_bit_iff [bit_simps]: \<open>bit (unset_bit m a) n \<longleftrightarrow> bit a n \<and> m \<noteq> n\<close>
    and flip_bit_eq_xor: \<open>flip_bit n a = a XOR push_bit n 1\<close>
    and push_bit_eq_mult: \<open>push_bit n a = a * 2 ^ n\<close>
    and drop_bit_eq_div: \<open>drop_bit n a = a div 2 ^ n\<close>
    and take_bit_eq_mod: \<open>take_bit n a = a mod 2 ^ n\<close>
begin

text \<open>
  We want the bitwise operations to bind slightly weaker
  than \<open>+\<close> and \<open>-\<close>.

  Logically, \<^const>\<open>push_bit\<close>,
  \<^const>\<open>drop_bit\<close> and \<^const>\<open>take_bit\<close> are just aliases; having them
  as separate operations makes proofs easier, otherwise proof automation
  would fiddle with concrete expressions \<^term>\<open>2 ^ n\<close> in a way obfuscating the basic
  algebraic relationships between those operations.

  For the sake of code generation operations 
  are specified as definitional class operations,
  taking into account that specific instances of these can be implemented
  differently wrt. code generation.
\<close>

sublocale "and": semilattice \<open>(AND)\<close>
  by standard (auto simp add: bit_eq_iff bit_and_iff)

sublocale or: semilattice_neutr \<open>(OR)\<close> 0
  by standard (auto simp add: bit_eq_iff bit_or_iff)

sublocale xor: comm_monoid \<open>(XOR)\<close> 0
  by standard (auto simp add: bit_eq_iff bit_xor_iff)

lemma even_and_iff:
  \<open>even (a AND b) \<longleftrightarrow> even a \<or> even b\<close>
  using bit_and_iff [of a b 0] by auto

lemma even_or_iff:
  \<open>even (a OR b) \<longleftrightarrow> even a \<and> even b\<close>
  using bit_or_iff [of a b 0] by auto

lemma even_xor_iff:
  \<open>even (a XOR b) \<longleftrightarrow> (even a \<longleftrightarrow> even b)\<close>
  using bit_xor_iff [of a b 0] by auto

lemma zero_and_eq [simp]:
  \<open>0 AND a = 0\<close>
  by (simp add: bit_eq_iff bit_and_iff)

lemma and_zero_eq [simp]:
  \<open>a AND 0 = 0\<close>
  by (simp add: bit_eq_iff bit_and_iff)

lemma one_and_eq:
  \<open>1 AND a = a mod 2\<close>
  by (simp add: bit_eq_iff bit_and_iff) (auto simp add: bit_1_iff)

lemma and_one_eq:
  \<open>a AND 1 = a mod 2\<close>
  using one_and_eq [of a] by (simp add: ac_simps)

lemma one_or_eq:
  \<open>1 OR a = a + of_bool (even a)\<close>
  by (simp add: bit_eq_iff bit_or_iff add.commute [of _ 1] even_bit_succ_iff) (auto simp add: bit_1_iff)

lemma or_one_eq:
  \<open>a OR 1 = a + of_bool (even a)\<close>
  using one_or_eq [of a] by (simp add: ac_simps)

lemma one_xor_eq:
  \<open>1 XOR a = a + of_bool (even a) - of_bool (odd a)\<close>
  by (simp add: bit_eq_iff bit_xor_iff add.commute [of _ 1] even_bit_succ_iff) (auto simp add: bit_1_iff odd_bit_iff_bit_pred elim: oddE)

lemma xor_one_eq:
  \<open>a XOR 1 = a + of_bool (even a) - of_bool (odd a)\<close>
  using one_xor_eq [of a] by (simp add: ac_simps)

lemma xor_self_eq [simp]:
  \<open>a XOR a = 0\<close>
  by (rule bit_eqI) (simp add: bit_simps)

lemma bit_iff_odd_drop_bit:
  \<open>bit a n \<longleftrightarrow> odd (drop_bit n a)\<close>
  by (simp add: bit_iff_odd drop_bit_eq_div)

lemma even_drop_bit_iff_not_bit:
  \<open>even (drop_bit n a) \<longleftrightarrow> \<not> bit a n\<close>
  by (simp add: bit_iff_odd_drop_bit)

lemma div_push_bit_of_1_eq_drop_bit:
  \<open>a div push_bit n 1 = drop_bit n a\<close>
  by (simp add: push_bit_eq_mult drop_bit_eq_div)

lemma bits_ident:
  "push_bit n (drop_bit n a) + take_bit n a = a"
  using div_mult_mod_eq by (simp add: push_bit_eq_mult take_bit_eq_mod drop_bit_eq_div)

lemma push_bit_push_bit [simp]:
  "push_bit m (push_bit n a) = push_bit (m + n) a"
  by (simp add: push_bit_eq_mult power_add ac_simps)

lemma push_bit_0_id [simp]:
  "push_bit 0 = id"
  by (simp add: fun_eq_iff push_bit_eq_mult)

lemma push_bit_of_0 [simp]:
  "push_bit n 0 = 0"
  by (simp add: push_bit_eq_mult)

lemma push_bit_of_1 [simp]:
  "push_bit n 1 = 2 ^ n"
  by (simp add: push_bit_eq_mult)

lemma push_bit_Suc [simp]:
  "push_bit (Suc n) a = push_bit n (a * 2)"
  by (simp add: push_bit_eq_mult ac_simps)

lemma push_bit_double:
  "push_bit n (a * 2) = push_bit n a * 2"
  by (simp add: push_bit_eq_mult ac_simps)

lemma push_bit_add:
  "push_bit n (a + b) = push_bit n a + push_bit n b"
  by (simp add: push_bit_eq_mult algebra_simps)

lemma push_bit_numeral [simp]:
  \<open>push_bit (numeral l) (numeral k) = push_bit (pred_numeral l) (numeral (Num.Bit0 k))\<close>
  by (simp add: numeral_eq_Suc mult_2_right) (simp add: numeral_Bit0)

lemma take_bit_0 [simp]:
  "take_bit 0 a = 0"
  by (simp add: take_bit_eq_mod)

lemma take_bit_Suc:
  \<open>take_bit (Suc n) a = take_bit n (a div 2) * 2 + a mod 2\<close>
proof -
  have \<open>take_bit (Suc n) (a div 2 * 2 + of_bool (odd a)) = take_bit n (a div 2) * 2 + of_bool (odd a)\<close>
    using even_succ_mod_exp [of \<open>2 * (a div 2)\<close> \<open>Suc n\<close>]
      mult_exp_mod_exp_eq [of 1 \<open>Suc n\<close> \<open>a div 2\<close>]
    by (auto simp add: take_bit_eq_mod ac_simps)
  then show ?thesis
    using div_mult_mod_eq [of a 2] by (simp add: mod_2_eq_odd)
qed

lemma take_bit_rec:
  \<open>take_bit n a = (if n = 0 then 0 else take_bit (n - 1) (a div 2) * 2 + a mod 2)\<close>
  by (cases n) (simp_all add: take_bit_Suc)

lemma take_bit_Suc_0 [simp]:
  \<open>take_bit (Suc 0) a = a mod 2\<close>
  by (simp add: take_bit_eq_mod)

lemma take_bit_of_0 [simp]:
  "take_bit n 0 = 0"
  by (simp add: take_bit_eq_mod)

lemma take_bit_of_1 [simp]:
  "take_bit n 1 = of_bool (n > 0)"
  by (cases n) (simp_all add: take_bit_Suc)

lemma drop_bit_of_0 [simp]:
  "drop_bit n 0 = 0"
  by (simp add: drop_bit_eq_div)

lemma drop_bit_of_1 [simp]:
  "drop_bit n 1 = of_bool (n = 0)"
  by (simp add: drop_bit_eq_div)

lemma drop_bit_0 [simp]:
  "drop_bit 0 = id"
  by (simp add: fun_eq_iff drop_bit_eq_div)

lemma drop_bit_Suc:
  "drop_bit (Suc n) a = drop_bit n (a div 2)"
  using div_exp_eq [of a 1] by (simp add: drop_bit_eq_div)

lemma drop_bit_rec:
  "drop_bit n a = (if n = 0 then a else drop_bit (n - 1) (a div 2))"
  by (cases n) (simp_all add: drop_bit_Suc)

lemma drop_bit_half:
  "drop_bit n (a div 2) = drop_bit n a div 2"
  by (induction n arbitrary: a) (simp_all add: drop_bit_Suc)

lemma drop_bit_of_bool [simp]:
  "drop_bit n (of_bool b) = of_bool (n = 0 \<and> b)"
  by (cases n) simp_all

lemma even_take_bit_eq [simp]:
  \<open>even (take_bit n a) \<longleftrightarrow> n = 0 \<or> even a\<close>
  by (simp add: take_bit_rec [of n a])

lemma take_bit_take_bit [simp]:
  "take_bit m (take_bit n a) = take_bit (min m n) a"
  by (simp add: take_bit_eq_mod mod_exp_eq ac_simps)

lemma drop_bit_drop_bit [simp]:
  "drop_bit m (drop_bit n a) = drop_bit (m + n) a"
  by (simp add: drop_bit_eq_div power_add div_exp_eq ac_simps)

lemma push_bit_take_bit:
  "push_bit m (take_bit n a) = take_bit (m + n) (push_bit m a)"
  apply (simp add: push_bit_eq_mult take_bit_eq_mod power_add ac_simps)
  using mult_exp_mod_exp_eq [of m \<open>m + n\<close> a] apply (simp add: ac_simps power_add)
  done 

lemma take_bit_push_bit:
  "take_bit m (push_bit n a) = push_bit n (take_bit (m - n) a)"
proof (cases "m \<le> n")
  case True
  then show ?thesis
    apply (simp add:)
    apply (simp_all add: push_bit_eq_mult take_bit_eq_mod)
    apply (auto dest!: le_Suc_ex simp add: power_add ac_simps)
    using mult_exp_mod_exp_eq [of m m \<open>a * 2 ^ n\<close> for n]
    apply (simp add: ac_simps)
    done
next
  case False
  then show ?thesis
    using push_bit_take_bit [of n "m - n" a]
    by simp
qed

lemma take_bit_drop_bit:
  "take_bit m (drop_bit n a) = drop_bit n (take_bit (m + n) a)"
  by (simp add: drop_bit_eq_div take_bit_eq_mod ac_simps div_exp_mod_exp_eq)

lemma drop_bit_take_bit:
  "drop_bit m (take_bit n a) = take_bit (n - m) (drop_bit m a)"
proof (cases "m \<le> n")
  case True
  then show ?thesis
    using take_bit_drop_bit [of "n - m" m a] by simp
next
  case False
  then obtain q where \<open>m = n + q\<close>
    by (auto simp add: not_le dest: less_imp_Suc_add)
  then have \<open>drop_bit m (take_bit n a) = 0\<close>
    using div_exp_eq [of \<open>a mod 2 ^ n\<close> n q]
    by (simp add: take_bit_eq_mod drop_bit_eq_div)
  with False show ?thesis
    by simp
qed

lemma even_push_bit_iff [simp]:
  \<open>even (push_bit n a) \<longleftrightarrow> n \<noteq> 0 \<or> even a\<close>
  by (simp add: push_bit_eq_mult) auto

lemma bit_push_bit_iff [bit_simps]:
  \<open>bit (push_bit m a) n \<longleftrightarrow> m \<le> n \<and> possible_bit TYPE('a) n \<and> bit a (n - m)\<close>
  by (auto simp add: bit_iff_odd push_bit_eq_mult even_mult_exp_div_exp_iff possible_bit_def)

lemma bit_drop_bit_eq [bit_simps]:
  \<open>bit (drop_bit n a) = bit a \<circ> (+) n\<close>
  by (simp add: bit_iff_odd fun_eq_iff ac_simps flip: drop_bit_eq_div)

lemma bit_take_bit_iff [bit_simps]:
  \<open>bit (take_bit m a) n \<longleftrightarrow> n < m \<and> bit a n\<close>
  by (simp add: bit_iff_odd drop_bit_take_bit not_le flip: drop_bit_eq_div)

lemma stable_imp_drop_bit_eq:
  \<open>drop_bit n a = a\<close>
  if \<open>a div 2 = a\<close>
  by (induction n) (simp_all add: that drop_bit_Suc)

lemma stable_imp_take_bit_eq:
  \<open>take_bit n a = (if even a then 0 else 2 ^ n - 1)\<close>
    if \<open>a div 2 = a\<close>
proof (rule bit_eqI[unfolded possible_bit_def])
  fix m
  assume \<open>2 ^ m \<noteq> 0\<close>
  with that show \<open>bit (take_bit n a) m \<longleftrightarrow> bit (if even a then 0 else 2 ^ n - 1) m\<close>
    by (simp add: bit_take_bit_iff bit_mask_sub_iff possible_bit_def stable_imp_bit_iff_odd)
qed

lemma exp_dvdE:
  assumes \<open>2 ^ n dvd a\<close>
  obtains b where \<open>a = push_bit n b\<close>
proof -
  from assms obtain b where \<open>a = 2 ^ n * b\<close> ..
  then have \<open>a = push_bit n b\<close>
    by (simp add: push_bit_eq_mult ac_simps)
  with that show thesis .
qed

lemma take_bit_eq_0_iff:
  \<open>take_bit n a = 0 \<longleftrightarrow> 2 ^ n dvd a\<close> (is \<open>?P \<longleftrightarrow> ?Q\<close>)
proof
  assume ?P
  then show ?Q
    by (simp add: take_bit_eq_mod mod_0_imp_dvd)
next
  assume ?Q
  then obtain b where \<open>a = push_bit n b\<close>
    by (rule exp_dvdE)
  then show ?P
    by (simp add: take_bit_push_bit)
qed

lemma take_bit_tightened:
  \<open>take_bit m a = take_bit m b\<close> if \<open>take_bit n a = take_bit n b\<close> and \<open>m \<le> n\<close> 
proof -
  from that have \<open>take_bit m (take_bit n a) = take_bit m (take_bit n b)\<close>
    by simp
  then have \<open>take_bit (min m n) a = take_bit (min m n) b\<close>
    by simp
  with that show ?thesis
    by (simp add: min_def)
qed 

lemma take_bit_eq_self_iff_drop_bit_eq_0:
  \<open>take_bit n a = a \<longleftrightarrow> drop_bit n a = 0\<close> (is \<open>?P \<longleftrightarrow> ?Q\<close>)
proof
  assume ?P
  show ?Q
  proof (rule bit_eqI)
    fix m
    from \<open>?P\<close> have \<open>a = take_bit n a\<close> ..
    also have \<open>\<not> bit (take_bit n a) (n + m)\<close>
      unfolding bit_simps
      by (simp add: bit_simps) 
    finally show \<open>bit (drop_bit n a) m \<longleftrightarrow> bit 0 m\<close>
      by (simp add: bit_simps)
  qed
next
  assume ?Q
  show ?P
  proof (rule bit_eqI)
    fix m
    from \<open>?Q\<close> have \<open>\<not> bit (drop_bit n a) (m - n)\<close>
      by simp
    then have \<open> \<not> bit a (n + (m - n))\<close>
      by (simp add: bit_simps)
    then show \<open>bit (take_bit n a) m \<longleftrightarrow> bit a m\<close>
      by (cases \<open>m < n\<close>) (auto simp add: bit_simps)
  qed
qed

lemma drop_bit_exp_eq:
  \<open>drop_bit m (2 ^ n) = of_bool (m \<le> n \<and> possible_bit TYPE('a) n) * 2 ^ (n - m)\<close>
  by (auto simp add: bit_eq_iff bit_simps)

lemma take_bit_and [simp]:
  \<open>take_bit n (a AND b) = take_bit n a AND take_bit n b\<close>
  by (auto simp add: bit_eq_iff bit_simps)

lemma take_bit_or [simp]:
  \<open>take_bit n (a OR b) = take_bit n a OR take_bit n b\<close>
  by (auto simp add: bit_eq_iff bit_simps)

lemma take_bit_xor [simp]:
  \<open>take_bit n (a XOR b) = take_bit n a XOR take_bit n b\<close>
  by (auto simp add: bit_eq_iff bit_simps)

lemma push_bit_and [simp]:
  \<open>push_bit n (a AND b) = push_bit n a AND push_bit n b\<close>
  by (auto simp add: bit_eq_iff bit_simps)

lemma push_bit_or [simp]:
  \<open>push_bit n (a OR b) = push_bit n a OR push_bit n b\<close>
  by (auto simp add: bit_eq_iff bit_simps)

lemma push_bit_xor [simp]:
  \<open>push_bit n (a XOR b) = push_bit n a XOR push_bit n b\<close>
  by (auto simp add: bit_eq_iff bit_simps)

lemma drop_bit_and [simp]:
  \<open>drop_bit n (a AND b) = drop_bit n a AND drop_bit n b\<close>
  by (auto simp add: bit_eq_iff bit_simps)

lemma drop_bit_or [simp]:
  \<open>drop_bit n (a OR b) = drop_bit n a OR drop_bit n b\<close>
  by (auto simp add: bit_eq_iff bit_simps)

lemma drop_bit_xor [simp]:
  \<open>drop_bit n (a XOR b) = drop_bit n a XOR drop_bit n b\<close>
  by (auto simp add: bit_eq_iff bit_simps) 

lemma bit_mask_iff [bit_simps]:
  \<open>bit (mask m) n \<longleftrightarrow> possible_bit TYPE('a) n \<and> n < m\<close>
  by (simp add: mask_eq_exp_minus_1 bit_mask_sub_iff)

lemma even_mask_iff:
  \<open>even (mask n) \<longleftrightarrow> n = 0\<close>
  using bit_mask_iff [of n 0] by auto

lemma mask_0 [simp]:
  \<open>mask 0 = 0\<close>
  by (simp add: mask_eq_exp_minus_1)

lemma mask_Suc_0 [simp]:
  \<open>mask (Suc 0) = 1\<close>
  by (simp add: mask_eq_exp_minus_1 add_implies_diff sym)

lemma mask_Suc_exp:
  \<open>mask (Suc n) = 2 ^ n OR mask n\<close>
  by (auto simp add: bit_eq_iff bit_simps)

lemma mask_Suc_double:
  \<open>mask (Suc n) = 1 OR 2 * mask n\<close>
  by (auto simp add: bit_eq_iff bit_simps elim: possible_bit_less_imp)

lemma mask_numeral:
  \<open>mask (numeral n) = 1 + 2 * mask (pred_numeral n)\<close>
  by (simp add: numeral_eq_Suc mask_Suc_double one_or_eq ac_simps)

lemma take_bit_of_mask [simp]:
  \<open>take_bit m (mask n) = mask (min m n)\<close>
  by (rule bit_eqI) (simp add: bit_simps)

lemma take_bit_eq_mask:
  \<open>take_bit n a = a AND mask n\<close>
  by (auto simp add: bit_eq_iff bit_simps)

lemma or_eq_0_iff:
  \<open>a OR b = 0 \<longleftrightarrow> a = 0 \<and> b = 0\<close>
  by (auto simp add: bit_eq_iff bit_or_iff)

lemma disjunctive_add:
  \<open>a + b = a OR b\<close> if \<open>\<And>n. \<not> bit a n \<or> \<not> bit b n\<close>
  by (rule bit_eqI) (use that in \<open>simp add: bit_disjunctive_add_iff bit_or_iff\<close>)

lemma bit_iff_and_drop_bit_eq_1:
  \<open>bit a n \<longleftrightarrow> drop_bit n a AND 1 = 1\<close>
  by (simp add: bit_iff_odd_drop_bit and_one_eq odd_iff_mod_2_eq_one)

lemma bit_iff_and_push_bit_not_eq_0:
  \<open>bit a n \<longleftrightarrow> a AND push_bit n 1 \<noteq> 0\<close>
  apply (cases \<open>2 ^ n = 0\<close>)
  apply (simp_all add: bit_eq_iff bit_and_iff bit_push_bit_iff exp_eq_0_imp_not_bit)
  apply (simp_all add: bit_exp_iff)
  done 

lemmas set_bit_def = set_bit_eq_or

lemma bit_set_bit_iff [bit_simps]:
  \<open>bit (set_bit m a) n \<longleftrightarrow> bit a n \<or> (m = n \<and> possible_bit TYPE('a) n)\<close>
  by (auto simp add: set_bit_def bit_or_iff bit_exp_iff)

lemma even_set_bit_iff:
  \<open>even (set_bit m a) \<longleftrightarrow> even a \<and> m \<noteq> 0\<close>
  using bit_set_bit_iff [of m a 0] by auto

lemma even_unset_bit_iff:
  \<open>even (unset_bit m a) \<longleftrightarrow> even a \<or> m = 0\<close>
  using bit_unset_bit_iff [of m a 0] by auto

lemma and_exp_eq_0_iff_not_bit:
  \<open>a AND 2 ^ n = 0 \<longleftrightarrow> \<not> bit a n\<close> (is \<open>?P \<longleftrightarrow> ?Q\<close>)
  using bit_imp_possible_bit[of a n]
  by (auto simp add: bit_eq_iff bit_simps)

lemmas flip_bit_def = flip_bit_eq_xor

lemma bit_flip_bit_iff [bit_simps]:
  \<open>bit (flip_bit m a) n \<longleftrightarrow> (m = n \<longleftrightarrow> \<not> bit a n) \<and> possible_bit TYPE('a) n\<close>
  by (auto simp add: bit_eq_iff bit_simps flip_bit_eq_xor bit_imp_possible_bit)

lemma even_flip_bit_iff:
  \<open>even (flip_bit m a) \<longleftrightarrow> \<not> (even a \<longleftrightarrow> m = 0)\<close>
  using bit_flip_bit_iff [of m a 0] by (auto simp: possible_bit_def)

lemma set_bit_0 [simp]:
  \<open>set_bit 0 a = 1 + 2 * (a div 2)\<close>
  by (auto simp add: bit_eq_iff bit_simps even_bit_succ_iff simp flip: bit_Suc)

lemma bit_sum_mult_2_cases:
  assumes a: "\<forall>j. \<not> bit a (Suc j)"
  shows "bit (a + 2 * b) n = (if n = 0 then odd a else bit (2 * b) n)"
proof -
  have a_eq: "bit a i \<longleftrightarrow> i = 0 \<and> odd a" for i
    by (cases i, simp_all add: a)
  show ?thesis
    by (simp add: disjunctive_add[simplified disj_imp] a_eq bit_simps)
qed 

lemma set_bit_Suc:
  \<open>set_bit (Suc n) a = a mod 2 + 2 * set_bit n (a div 2)\<close>
  by (auto simp add: bit_eq_iff bit_sum_mult_2_cases bit_simps bit_Suc[symmetric]
    elim: possible_bit_less_imp)

lemma unset_bit_0 [simp]:
  \<open>unset_bit 0 a = 2 * (a div 2)\<close>
  by (auto simp add: bit_eq_iff bit_simps even_bit_succ_iff simp flip: bit_Suc)

lemma unset_bit_Suc:
  \<open>unset_bit (Suc n) a = a mod 2 + 2 * unset_bit n (a div 2)\<close>
  by (auto simp add: bit_eq_iff bit_sum_mult_2_cases bit_simps bit_Suc[symmetric]
    elim: possible_bit_less_imp)

lemma flip_bit_0 [simp]:
  \<open>flip_bit 0 a = of_bool (even a) + 2 * (a div 2)\<close>
  by (auto simp add: bit_eq_iff bit_simps even_bit_succ_iff simp flip: bit_Suc)

lemma flip_bit_Suc:
  \<open>flip_bit (Suc n) a = a mod 2 + 2 * flip_bit n (a div 2)\<close>
  by (auto simp add: bit_eq_iff bit_sum_mult_2_cases bit_simps bit_Suc[symmetric]
    elim: possible_bit_less_imp) 

lemma flip_bit_eq_if:
  \<open>flip_bit n a = (if bit a n then unset_bit else set_bit) n a\<close>
  by (rule bit_eqI) (auto simp add: bit_set_bit_iff bit_unset_bit_iff bit_flip_bit_iff)

lemma take_bit_set_bit_eq:
  \<open>take_bit n (set_bit m a) = (if n \<le> m then take_bit n a else set_bit m (take_bit n a))\<close>
  by (rule bit_eqI) (auto simp add: bit_take_bit_iff bit_set_bit_iff)

lemma take_bit_unset_bit_eq:
  \<open>take_bit n (unset_bit m a) = (if n \<le> m then take_bit n a else unset_bit m (take_bit n a))\<close>
  by (rule bit_eqI) (auto simp add: bit_take_bit_iff bit_unset_bit_iff)

lemma take_bit_flip_bit_eq:
  \<open>take_bit n (flip_bit m a) = (if n \<le> m then take_bit n a else flip_bit m (take_bit n a))\<close>
  by (rule bit_eqI) (auto simp add: bit_take_bit_iff bit_flip_bit_iff)

lemma not_bit_1_Suc [simp]:
  \<open>\<not> bit 1 (Suc n)\<close>
  by (simp add: bit_Suc)

lemma push_bit_Suc_numeral [simp]:
  \<open>push_bit (Suc n) (numeral k) = push_bit n (numeral (Num.Bit0 k))\<close>
  by (simp add: numeral_eq_Suc mult_2_right) (simp add: numeral_Bit0)

lemma mask_eq_0_iff [simp]:
  \<open>mask n = 0 \<longleftrightarrow> n = 0\<close>
  by (cases n) (simp_all add: mask_Suc_double or_eq_0_iff)

end



class ring_bit_operations = semiring_bit_operations + ring_parity +
  fixes not :: \<open>'a \<Rightarrow> 'a\<close>  (\<open>NOT\<close>)
  assumes bit_not_iff_eq: \<open>\<And>n. bit (NOT a) n \<longleftrightarrow> 2 ^ n \<noteq> 0 \<and> \<not> bit a n\<close>
  assumes minus_eq_not_minus_1: \<open>- a = NOT (a - 1)\<close>
begin

lemmas bit_not_iff[bit_simps] = bit_not_iff_eq[unfolded fold_possible_bit]

text \<open>
  For the sake of code generation \<^const>\<open>not\<close> is specified as
  definitional class operation.  Note that \<^const>\<open>not\<close> has no
  sensible definition for unlimited but only positive bit strings
  (type \<^typ>\<open>nat\<close>).
\<close>

lemma bits_minus_1_mod_2_eq [simp]:
  \<open>(- 1) mod 2 = 1\<close>
  by (simp add: mod_2_eq_odd)

lemma not_eq_complement:
  \<open>NOT a = - a - 1\<close>
  using minus_eq_not_minus_1 [of \<open>a + 1\<close>] by simp

lemma minus_eq_not_plus_1:
  \<open>- a = NOT a + 1\<close>
  using not_eq_complement [of a] by simp

lemma bit_minus_iff [bit_simps]:
  \<open>bit (- a) n \<longleftrightarrow> possible_bit TYPE('a) n \<and> \<not> bit (a - 1) n\<close>
  by (simp add: minus_eq_not_minus_1 bit_not_iff)

lemma even_not_iff [simp]:
  \<open>even (NOT a) \<longleftrightarrow> odd a\<close> 
  using bit_not_iff [of a 0] by auto

lemma bit_not_exp_iff [bit_simps]:
  \<open>bit (NOT (2 ^ m)) n \<longleftrightarrow> possible_bit TYPE('a) n \<and> n \<noteq> m\<close>
  by (auto simp add: bit_not_iff bit_exp_iff)

lemma bit_minus_1_iff [simp]:
  \<open>bit (- 1) n \<longleftrightarrow> possible_bit TYPE('a) n\<close>
  by (simp add: bit_minus_iff)

lemma bit_minus_exp_iff [bit_simps]:
  \<open>bit (- (2 ^ m)) n \<longleftrightarrow> possible_bit TYPE('a) n \<and> n \<ge> m\<close>
  by (auto simp add: bit_simps simp flip: mask_eq_exp_minus_1)

lemma bit_minus_2_iff [simp]:
  \<open>bit (- 2) n \<longleftrightarrow> possible_bit TYPE('a) n \<and> n > 0\<close>
  by (simp add: bit_minus_iff bit_1_iff)

lemma not_one_eq [simp]:
  \<open>NOT 1 = - 2\<close>
  by (simp add: bit_eq_iff bit_not_iff) (simp add: bit_1_iff)

sublocale "and": semilattice_neutr \<open>(AND)\<close> \<open>- 1\<close>
  by standard (rule bit_eqI, simp add: bit_and_iff)

sublocale bit: abstract_boolean_algebra \<open>(AND)\<close> \<open>(OR)\<close> NOT 0 \<open>- 1\<close>
  by standard (auto simp add: bit_and_iff bit_or_iff bit_not_iff intro: bit_eqI)

sublocale bit: abstract_boolean_algebra_sym_diff \<open>(AND)\<close> \<open>(OR)\<close> NOT 0 \<open>- 1\<close> \<open>(XOR)\<close>
  apply standard
  apply (rule bit_eqI)
  apply (auto simp add: bit_simps)
  done

lemma and_eq_not_not_or:
  \<open>a AND b = NOT (NOT a OR NOT b)\<close>
  by simp

lemma or_eq_not_not_and:
  \<open>a OR b = NOT (NOT a AND NOT b)\<close>
  by simp

lemma not_add_distrib:
  \<open>NOT (a + b) = NOT a - b\<close>
  by (simp add: not_eq_complement algebra_simps)

lemma not_diff_distrib:
  \<open>NOT (a - b) = NOT a + b\<close>
  using not_add_distrib [of a \<open>- b\<close>] by simp

lemma and_eq_minus_1_iff:
  \<open>a AND b = - 1 \<longleftrightarrow> a = - 1 \<and> b = - 1\<close>
  by (auto simp: bit_eq_iff bit_simps)

lemma disjunctive_diff:
  \<open>a - b = a AND NOT b\<close> if \<open>\<And>n. bit b n \<Longrightarrow> bit a n\<close>
proof -
  have \<open>NOT a + b = NOT a OR b\<close>
    by (rule disjunctive_add) (auto simp add: bit_not_iff dest: that)
  then have \<open>NOT (NOT a + b) = NOT (NOT a OR b)\<close>
    by simp
  then show ?thesis
    by (simp add: not_add_distrib)
qed

lemma push_bit_minus:
  \<open>push_bit n (- a) = - push_bit n a\<close>
  by (simp add: push_bit_eq_mult)

lemma take_bit_not_take_bit:
  \<open>take_bit n (NOT (take_bit n a)) = take_bit n (NOT a)\<close>
  by (auto simp add: bit_eq_iff bit_take_bit_iff bit_not_iff)

lemma take_bit_not_iff:
  \<open>take_bit n (NOT a) = take_bit n (NOT b) \<longleftrightarrow> take_bit n a = take_bit n b\<close>
  apply (simp add: bit_eq_iff)
  apply (simp add: bit_not_iff bit_take_bit_iff bit_exp_iff)
  apply (use exp_eq_0_imp_not_bit in blast)
  done

lemma take_bit_not_eq_mask_diff:
  \<open>take_bit n (NOT a) = mask n - take_bit n a\<close>
proof -
  have \<open>take_bit n (NOT a) = take_bit n (NOT (take_bit n a))\<close>
    by (simp add: take_bit_not_take_bit)
  also have \<open>\<dots> = mask n AND NOT (take_bit n a)\<close>
    by (simp add: take_bit_eq_mask ac_simps)
  also have \<open>\<dots> = mask n - take_bit n a\<close>
    by (subst disjunctive_diff)
      (auto simp add: bit_take_bit_iff bit_mask_iff bit_imp_possible_bit)
  finally show ?thesis
    by simp
qed

lemma mask_eq_take_bit_minus_one:
  \<open>mask n = take_bit n (- 1)\<close>
  by (simp add: bit_eq_iff bit_mask_iff bit_take_bit_iff conj_commute)

lemma take_bit_minus_one_eq_mask [simp]:
  \<open>take_bit n (- 1) = mask n\<close>
  by (simp add: mask_eq_take_bit_minus_one)

lemma minus_exp_eq_not_mask:
  \<open>- (2 ^ n) = NOT (mask n)\<close>
  by (rule bit_eqI) (simp add: bit_minus_iff bit_not_iff flip: mask_eq_exp_minus_1)

lemma push_bit_minus_one_eq_not_mask [simp]:
  \<open>push_bit n (- 1) = NOT (mask n)\<close>
  by (simp add: push_bit_eq_mult minus_exp_eq_not_mask)

lemma take_bit_not_mask_eq_0:
  \<open>take_bit m (NOT (mask n)) = 0\<close> if \<open>n \<ge> m\<close>
  by (rule bit_eqI) (use that in \<open>simp add: bit_take_bit_iff bit_not_iff bit_mask_iff\<close>)

lemma unset_bit_eq_and_not:
  \<open>unset_bit n a = a AND NOT (push_bit n 1)\<close>
  by (rule bit_eqI) (auto simp add: bit_simps)

lemmas unset_bit_def = unset_bit_eq_and_not

lemma push_bit_Suc_minus_numeral [simp]:
  \<open>push_bit (Suc n) (- numeral k) = push_bit n (- numeral (Num.Bit0 k))\<close>
  apply (simp only: numeral_Bit0)
  apply simp
  apply (simp only: numeral_mult mult_2_right numeral_add)
  done

lemma push_bit_minus_numeral [simp]:
  \<open>push_bit (numeral l) (- numeral k) = push_bit (pred_numeral l) (- numeral (Num.Bit0 k))\<close>
  by (simp only: numeral_eq_Suc push_bit_Suc_minus_numeral)

lemma take_bit_Suc_minus_1_eq:
  \<open>take_bit (Suc n) (- 1) = 2 ^ Suc n - 1\<close>
  by (simp add: mask_eq_exp_minus_1)

lemma take_bit_numeral_minus_1_eq:
  \<open>take_bit (numeral k) (- 1) = 2 ^ numeral k - 1\<close>
  by (simp add: mask_eq_exp_minus_1)

lemma push_bit_mask_eq:
  \<open>push_bit m (mask n) = mask (n + m) AND NOT (mask m)\<close>
  apply (rule bit_eqI)
  apply (auto simp add: bit_simps not_less possible_bit_def)
  apply (drule sym [of 0])
  apply (simp only:)
  using exp_not_zero_imp_exp_diff_not_zero apply (blast dest: exp_not_zero_imp_exp_diff_not_zero)
  done

lemma slice_eq_mask:
  \<open>push_bit n (take_bit m (drop_bit n a)) = a AND mask (m + n) AND NOT (mask n)\<close>
  by (rule bit_eqI) (auto simp add: bit_simps)

lemma push_bit_numeral_minus_1 [simp]:
  \<open>push_bit (numeral n) (- 1) = - (2 ^ numeral n)\<close>
  by (simp add: push_bit_eq_mult)

end


subsection \<open>Instance \<^typ>\<open>int\<close>\<close>

instantiation int :: ring_bit_operations
begin

definition not_int :: \<open>int \<Rightarrow> int\<close>
  where \<open>not_int k = - k - 1\<close>

lemma not_int_rec:
  \<open>NOT k = of_bool (even k) + 2 * NOT (k div 2)\<close> for k :: int
  by (auto simp add: not_int_def elim: oddE)

lemma even_not_iff_int:
  \<open>even (NOT k) \<longleftrightarrow> odd k\<close> for k :: int
  by (simp add: not_int_def)

lemma not_int_div_2:
  \<open>NOT k div 2 = NOT (k div 2)\<close> for k :: int
  by (cases k) (simp_all add: not_int_def divide_int_def nat_add_distrib)

lemma bit_not_int_iff:
  \<open>bit (NOT k) n \<longleftrightarrow> \<not> bit k n\<close>
  for k :: int
  by (simp add: bit_not_int_iff' not_int_def)

function and_int :: \<open>int \<Rightarrow> int \<Rightarrow> int\<close>
  where \<open>(k::int) AND l = (if k \<in> {0, - 1} \<and> l \<in> {0, - 1}
    then - of_bool (odd k \<and> odd l)
    else of_bool (odd k \<and> odd l) + 2 * ((k div 2) AND (l div 2)))\<close>
  by auto

termination proof (relation \<open>measure (\<lambda>(k, l). nat (\<bar>k\<bar> + \<bar>l\<bar>))\<close>)
  show \<open>wf (measure (\<lambda>(k, l). nat (\<bar>k\<bar> + \<bar>l\<bar>)))\<close>
    by simp
  show \<open>((k div 2, l div 2), k, l) \<in> measure (\<lambda>(k, l). nat (\<bar>k\<bar> + \<bar>l\<bar>))\<close>
    if \<open>\<not> (k \<in> {0, - 1} \<and> l \<in> {0, - 1})\<close> for k l
  proof -
    have less_eq: \<open>\<bar>k div 2\<bar> \<le> \<bar>k\<bar>\<close> for k :: int
      by (cases k) (simp_all add: divide_int_def nat_add_distrib)
    have less: \<open>\<bar>k div 2\<bar> < \<bar>k\<bar>\<close> if \<open>k \<notin> {0, - 1}\<close> for k :: int
    proof (cases k)
      case (nonneg n)
      with that show ?thesis
        by (simp add: int_div_less_self)
    next
      case (neg n)
      with that have \<open>n \<noteq> 0\<close>
        by simp
      then have \<open>n div 2 < n\<close>
        by (simp add: div_less_iff_less_mult)
      with neg that show ?thesis
        by (simp add: divide_int_def nat_add_distrib)
    qed
    from that have *: \<open>k \<notin> {0, - 1} \<or> l \<notin> {0, - 1}\<close>
      by simp
    then have \<open>0 < \<bar>k\<bar> + \<bar>l\<bar>\<close>
      by auto
    moreover from * have \<open>\<bar>k div 2\<bar> + \<bar>l div 2\<bar> < \<bar>k\<bar> + \<bar>l\<bar>\<close>
    proof
      assume \<open>k \<notin> {0, - 1}\<close>
      then have \<open>\<bar>k div 2\<bar> < \<bar>k\<bar>\<close>
        by (rule less)
      with less_eq [of l] show ?thesis
        by auto
    next
      assume \<open>l \<notin> {0, - 1}\<close>
      then have \<open>\<bar>l div 2\<bar> < \<bar>l\<bar>\<close>
        by (rule less)
      with less_eq [of k] show ?thesis
        by auto
    qed
    ultimately show ?thesis
      by simp
  qed
qed

declare and_int.simps [simp del]

lemma and_int_rec:
  \<open>k AND l = of_bool (odd k \<and> odd l) + 2 * ((k div 2) AND (l div 2))\<close>
    for k l :: int
proof (cases \<open>k \<in> {0, - 1} \<and> l \<in> {0, - 1}\<close>)
  case True
  then show ?thesis
    by auto (simp_all add: and_int.simps)
next
  case False
  then show ?thesis
    by (auto simp add: ac_simps and_int.simps [of k l])
qed

lemma bit_and_int_iff:
  \<open>bit (k AND l) n \<longleftrightarrow> bit k n \<and> bit l n\<close> for k l :: int
proof (induction n arbitrary: k l)
  case 0
  then show ?case
    by (simp add: and_int_rec [of k l])
next
  case (Suc n)
  then show ?case
    by (simp add: and_int_rec [of k l] bit_Suc)
qed

lemma even_and_iff_int:
  \<open>even (k AND l) \<longleftrightarrow> even k \<or> even l\<close> for k l :: int
  using bit_and_int_iff [of k l 0] by auto

definition or_int :: \<open>int \<Rightarrow> int \<Rightarrow> int\<close>
  where \<open>k OR l = NOT (NOT k AND NOT l)\<close> for k l :: int

lemma or_int_rec:
  \<open>k OR l = of_bool (odd k \<or> odd l) + 2 * ((k div 2) OR (l div 2))\<close>
  for k l :: int
  using and_int_rec [of \<open>NOT k\<close> \<open>NOT l\<close>]
  by (simp add: or_int_def even_not_iff_int not_int_div_2)
    (simp_all add: not_int_def)

lemma bit_or_int_iff:
  \<open>bit (k OR l) n \<longleftrightarrow> bit k n \<or> bit l n\<close> for k l :: int
  by (simp add: or_int_def bit_not_int_iff bit_and_int_iff)

definition xor_int :: \<open>int \<Rightarrow> int \<Rightarrow> int\<close>
  where \<open>k XOR l = k AND NOT l OR NOT k AND l\<close> for k l :: int

lemma xor_int_rec:
  \<open>k XOR l = of_bool (odd k \<noteq> odd l) + 2 * ((k div 2) XOR (l div 2))\<close>
  for k l :: int
  by (simp add: xor_int_def or_int_rec [of \<open>k AND NOT l\<close> \<open>NOT k AND l\<close>] even_and_iff_int even_not_iff_int)
    (simp add: and_int_rec [of \<open>NOT k\<close> \<open>l\<close>] and_int_rec [of \<open>k\<close> \<open>NOT l\<close>] not_int_div_2)

lemma bit_xor_int_iff:
  \<open>bit (k XOR l) n \<longleftrightarrow> bit k n \<noteq> bit l n\<close> for k l :: int
  by (auto simp add: xor_int_def bit_or_int_iff bit_and_int_iff bit_not_int_iff)

definition mask_int :: \<open>nat \<Rightarrow> int\<close>
  where \<open>mask n = (2 :: int) ^ n - 1\<close>

definition push_bit_int :: \<open>nat \<Rightarrow> int \<Rightarrow> int\<close>
  where \<open>push_bit_int n k = k * 2 ^ n\<close>

definition drop_bit_int :: \<open>nat \<Rightarrow> int \<Rightarrow> int\<close>
  where \<open>drop_bit_int n k = k div 2 ^ n\<close>

definition take_bit_int :: \<open>nat \<Rightarrow> int \<Rightarrow> int\<close>
  where \<open>take_bit_int n k = k mod 2 ^ n\<close>

definition set_bit_int :: \<open>nat \<Rightarrow> int \<Rightarrow> int\<close>
  where \<open>set_bit n k = k OR push_bit n 1\<close> for k :: int

definition unset_bit_int :: \<open>nat \<Rightarrow> int \<Rightarrow> int\<close>
  where \<open>unset_bit n k = k AND NOT (push_bit n 1)\<close> for k :: int

definition flip_bit_int :: \<open>nat \<Rightarrow> int \<Rightarrow> int\<close>
  where \<open>flip_bit n k = k XOR push_bit n 1\<close> for k :: int

instance proof
  fix k l :: int and m n :: nat
  show \<open>- k = NOT (k - 1)\<close>
    by (simp add: not_int_def)
  show \<open>bit (k AND l) n \<longleftrightarrow> bit k n \<and> bit l n\<close>
    by (fact bit_and_int_iff)
  show \<open>bit (k OR l) n \<longleftrightarrow> bit k n \<or> bit l n\<close>
    by (fact bit_or_int_iff)
  show \<open>bit (k XOR l) n \<longleftrightarrow> bit k n \<noteq> bit l n\<close>
    by (fact bit_xor_int_iff)
  show \<open>bit (unset_bit m k) n \<longleftrightarrow> bit k n \<and> m \<noteq> n\<close>
  proof -
    have \<open>unset_bit m k = k AND NOT (push_bit m 1)\<close>
      by (simp add: unset_bit_int_def)
    also have \<open>NOT (push_bit m 1 :: int) = - (push_bit m 1 + 1)\<close>
      by (simp add: not_int_def)
    finally show ?thesis by (simp only: bit_simps bit_and_int_iff)
      (auto simp add: bit_simps bit_not_int_iff' push_bit_int_def)
  qed
qed (simp_all add: bit_not_int_iff mask_int_def set_bit_int_def flip_bit_int_def
  push_bit_int_def drop_bit_int_def take_bit_int_def)

end

lemma bit_push_bit_iff_int:
  \<open>bit (push_bit m k) n \<longleftrightarrow> m \<le> n \<and> bit k (n - m)\<close> for k :: int
  by (auto simp add: bit_push_bit_iff)

lemma take_bit_nonnegative [simp]:
  \<open>take_bit n k \<ge> 0\<close> for k :: int
  by (simp add: take_bit_eq_mod)

lemma not_take_bit_negative [simp]:
  \<open>\<not> take_bit n k < 0\<close> for k :: int
  by (simp add: not_less)

lemma take_bit_int_less_exp [simp]:
  \<open>take_bit n k < 2 ^ n\<close> for k :: int
  by (simp add: take_bit_eq_mod)

lemma take_bit_int_eq_self_iff:
  \<open>take_bit n k = k \<longleftrightarrow> 0 \<le> k \<and> k < 2 ^ n\<close> (is \<open>?P \<longleftrightarrow> ?Q\<close>)
  for k :: int
proof
  assume ?P
  moreover note take_bit_int_less_exp [of n k] take_bit_nonnegative [of n k]
  ultimately show ?Q
    by simp
next
  assume ?Q
  then show ?P
    by (simp add: take_bit_eq_mod)
qed

lemma take_bit_int_eq_self:
  \<open>take_bit n k = k\<close> if \<open>0 \<le> k\<close> \<open>k < 2 ^ n\<close> for k :: int
  using that by (simp add: take_bit_int_eq_self_iff)

lemma mask_half_int:
  \<open>mask n div 2 = (mask (n - 1) :: int)\<close>
  by (cases n) (simp_all add: mask_eq_exp_minus_1 algebra_simps)

lemma mask_nonnegative_int [simp]:
  \<open>mask n \<ge> (0::int)\<close>
  by (simp add: mask_eq_exp_minus_1)

lemma not_mask_negative_int [simp]:
  \<open>\<not> mask n < (0::int)\<close>
  by (simp add: not_less)

lemma not_nonnegative_int_iff [simp]:
  \<open>NOT k \<ge> 0 \<longleftrightarrow> k < 0\<close> for k :: int
  by (simp add: not_int_def)

lemma not_negative_int_iff [simp]:
  \<open>NOT k < 0 \<longleftrightarrow> k \<ge> 0\<close> for k :: int
  by (subst Not_eq_iff [symmetric]) (simp add: not_less not_le)

lemma and_nonnegative_int_iff [simp]:
  \<open>k AND l \<ge> 0 \<longleftrightarrow> k \<ge> 0 \<or> l \<ge> 0\<close> for k l :: int
proof (induction k arbitrary: l rule: int_bit_induct)
  case zero
  then show ?case
    by simp
next
  case minus
  then show ?case
    by simp
next
  case (even k)
  then show ?case
    using and_int_rec [of \<open>k * 2\<close> l]
    by (simp add: pos_imp_zdiv_nonneg_iff zero_le_mult_iff)
next
  case (odd k)
  from odd have \<open>0 \<le> k AND l div 2 \<longleftrightarrow> 0 \<le> k \<or> 0 \<le> l div 2\<close>
    by simp
  then have \<open>0 \<le> (1 + k * 2) div 2 AND l div 2 \<longleftrightarrow> 0 \<le> (1 + k * 2) div 2 \<or> 0 \<le> l div 2\<close>
    by simp
  with and_int_rec [of \<open>1 + k * 2\<close> l]
  show ?case
    by (auto simp add: zero_le_mult_iff not_le)
qed

lemma and_negative_int_iff [simp]:
  \<open>k AND l < 0 \<longleftrightarrow> k < 0 \<and> l < 0\<close> for k l :: int
  by (subst Not_eq_iff [symmetric]) (simp add: not_less)

lemma and_less_eq:
  \<open>k AND l \<le> k\<close> if \<open>l < 0\<close> for k l :: int
using that proof (induction k arbitrary: l rule: int_bit_induct)
  case zero
  then show ?case
    by simp
next
  case minus
  then show ?case
    by simp
next
  case (even k)
  from even.IH [of \<open>l div 2\<close>] even.hyps even.prems
  show ?case
    by (simp add: and_int_rec [of _ l])
next
  case (odd k)
  from odd.IH [of \<open>l div 2\<close>] odd.hyps odd.prems
  show ?case
    by (simp add: and_int_rec [of _ l]) linarith
qed

lemma or_nonnegative_int_iff [simp]:
  \<open>k OR l \<ge> 0 \<longleftrightarrow> k \<ge> 0 \<and> l \<ge> 0\<close> for k l :: int
  by (simp only: or_eq_not_not_and not_nonnegative_int_iff) simp

lemma or_negative_int_iff [simp]:
  \<open>k OR l < 0 \<longleftrightarrow> k < 0 \<or> l < 0\<close> for k l :: int
  by (subst Not_eq_iff [symmetric]) (simp add: not_less)

lemma or_greater_eq:
  \<open>k OR l \<ge> k\<close> if \<open>l \<ge> 0\<close> for k l :: int
using that proof (induction k arbitrary: l rule: int_bit_induct)
  case zero
  then show ?case
    by simp
next
  case minus
  then show ?case
    by simp
next
  case (even k)
  from even.IH [of \<open>l div 2\<close>] even.hyps even.prems
  show ?case
    by (simp add: or_int_rec [of _ l]) linarith
next
  case (odd k)
  from odd.IH [of \<open>l div 2\<close>] odd.hyps odd.prems
  show ?case
    by (simp add: or_int_rec [of _ l])
qed

lemma xor_nonnegative_int_iff [simp]:
  \<open>k XOR l \<ge> 0 \<longleftrightarrow> (k \<ge> 0 \<longleftrightarrow> l \<ge> 0)\<close> for k l :: int
  by (simp only: bit.xor_def or_nonnegative_int_iff) auto

lemma xor_negative_int_iff [simp]:
  \<open>k XOR l < 0 \<longleftrightarrow> (k < 0) \<noteq> (l < 0)\<close> for k l :: int
  by (subst Not_eq_iff [symmetric]) (auto simp add: not_less)

lemma OR_upper: \<^marker>\<open>contributor \<open>Stefan Berghofer\<close>\<close>
  fixes x y :: int
  assumes \<open>0 \<le> x\<close> \<open>x < 2 ^ n\<close> \<open>y < 2 ^ n\<close>
  shows \<open>x OR y < 2 ^ n\<close>
using assms proof (induction x arbitrary: y n rule: int_bit_induct)
  case zero
  then show ?case
    by simp
next
  case minus
  then show ?case
    by simp
next
  case (even x)
  from even.IH [of \<open>n - 1\<close> \<open>y div 2\<close>] even.prems even.hyps
  show ?case 
    by (cases n) (auto simp add: or_int_rec [of \<open>_ * 2\<close>] elim: oddE)
next
  case (odd x)
  from odd.IH [of \<open>n - 1\<close> \<open>y div 2\<close>] odd.prems odd.hyps
  show ?case
    by (cases n) (auto simp add: or_int_rec [of \<open>1 + _ * 2\<close>], linarith)
qed

lemma XOR_upper: \<^marker>\<open>contributor \<open>Stefan Berghofer\<close>\<close>
  fixes x y :: int
  assumes \<open>0 \<le> x\<close> \<open>x < 2 ^ n\<close> \<open>y < 2 ^ n\<close>
  shows \<open>x XOR y < 2 ^ n\<close>
using assms proof (induction x arbitrary: y n rule: int_bit_induct)
  case zero
  then show ?case
    by simp
next
  case minus
  then show ?case
    by simp
next
  case (even x)
  from even.IH [of \<open>n - 1\<close> \<open>y div 2\<close>] even.prems even.hyps
  show ?case 
    by (cases n) (auto simp add: xor_int_rec [of \<open>_ * 2\<close>] elim: oddE)
next
  case (odd x)
  from odd.IH [of \<open>n - 1\<close> \<open>y div 2\<close>] odd.prems odd.hyps
  show ?case
    by (cases n) (auto simp add: xor_int_rec [of \<open>1 + _ * 2\<close>])
qed

lemma AND_lower [simp]: \<^marker>\<open>contributor \<open>Stefan Berghofer\<close>\<close>
  fixes x y :: int
  assumes \<open>0 \<le> x\<close>
  shows \<open>0 \<le> x AND y\<close>
  using assms by simp

lemma OR_lower [simp]: \<^marker>\<open>contributor \<open>Stefan Berghofer\<close>\<close>
  fixes x y :: int
  assumes \<open>0 \<le> x\<close> \<open>0 \<le> y\<close>
  shows \<open>0 \<le> x OR y\<close>
  using assms by simp

lemma XOR_lower [simp]: \<^marker>\<open>contributor \<open>Stefan Berghofer\<close>\<close>
  fixes x y :: int
  assumes \<open>0 \<le> x\<close> \<open>0 \<le> y\<close>
  shows \<open>0 \<le> x XOR y\<close>
  using assms by simp

lemma AND_upper1 [simp]: \<^marker>\<open>contributor \<open>Stefan Berghofer\<close>\<close>
  fixes x y :: int
  assumes \<open>0 \<le> x\<close>
  shows \<open>x AND y \<le> x\<close>
using assms proof (induction x arbitrary: y rule: int_bit_induct)
  case (odd k)
  then have \<open>k AND y div 2 \<le> k\<close>
    by simp
  then show ?case 
    by (simp add: and_int_rec [of \<open>1 + _ * 2\<close>])
qed (simp_all add: and_int_rec [of \<open>_ * 2\<close>])

lemmas AND_upper1' [simp] = order_trans [OF AND_upper1] \<^marker>\<open>contributor \<open>Stefan Berghofer\<close>\<close>
lemmas AND_upper1'' [simp] = order_le_less_trans [OF AND_upper1] \<^marker>\<open>contributor \<open>Stefan Berghofer\<close>\<close>

lemma AND_upper2 [simp]: \<^marker>\<open>contributor \<open>Stefan Berghofer\<close>\<close>
  fixes x y :: int
  assumes \<open>0 \<le> y\<close>
  shows \<open>x AND y \<le> y\<close>
  using assms AND_upper1 [of y x] by (simp add: ac_simps)

lemmas AND_upper2' [simp] = order_trans [OF AND_upper2] \<^marker>\<open>contributor \<open>Stefan Berghofer\<close>\<close>
lemmas AND_upper2'' [simp] = order_le_less_trans [OF AND_upper2] \<^marker>\<open>contributor \<open>Stefan Berghofer\<close>\<close>

lemma plus_and_or: \<open>(x AND y) + (x OR y) = x + y\<close> for x y :: int
proof (induction x arbitrary: y rule: int_bit_induct)
  case zero
  then show ?case
    by simp
next
  case minus
  then show ?case
    by simp
next
  case (even x)
  from even.IH [of \<open>y div 2\<close>]
  show ?case
    by (auto simp add: and_int_rec [of _ y] or_int_rec [of _ y] elim: oddE)
next
  case (odd x)
  from odd.IH [of \<open>y div 2\<close>]
  show ?case
    by (auto simp add: and_int_rec [of _ y] or_int_rec [of _ y] elim: oddE)
qed

lemma push_bit_minus_one:
  "push_bit n (- 1 :: int) = - (2 ^ n)"
  by (simp add: push_bit_eq_mult)

lemma minus_1_div_exp_eq_int:
  \<open>- 1 div (2 :: int) ^ n = - 1\<close>
  by (induction n) (use div_exp_eq [symmetric, of \<open>- 1 :: int\<close> 1] in \<open>simp_all add: ac_simps\<close>)

lemma drop_bit_minus_one [simp]:
  \<open>drop_bit n (- 1 :: int) = - 1\<close>
  by (simp add: drop_bit_eq_div minus_1_div_exp_eq_int)

lemma take_bit_Suc_from_most:
  \<open>take_bit (Suc n) k = 2 ^ n * of_bool (bit k n) + take_bit n k\<close> for k :: int
  by (simp only: take_bit_eq_mod power_Suc2) (simp_all add: bit_iff_odd odd_iff_mod_2_eq_one zmod_zmult2_eq)

lemma take_bit_minus:
  \<open>take_bit n (- take_bit n k) = take_bit n (- k)\<close>
    for k :: int
  by (simp add: take_bit_eq_mod mod_minus_eq)

lemma take_bit_diff:
  \<open>take_bit n (take_bit n k - take_bit n l) = take_bit n (k - l)\<close>
    for k l :: int
  by (simp add: take_bit_eq_mod mod_diff_eq)

lemma bit_imp_take_bit_positive:
  \<open>0 < take_bit m k\<close> if \<open>n < m\<close> and \<open>bit k n\<close> for k :: int
proof (rule ccontr)
  assume \<open>\<not> 0 < take_bit m k\<close>
  then have \<open>take_bit m k = 0\<close>
    by (auto simp add: not_less intro: order_antisym)
  then have \<open>bit (take_bit m k) n = bit 0 n\<close>
    by simp
  with that show False
    by (simp add: bit_take_bit_iff)
qed

lemma take_bit_mult:
  \<open>take_bit n (take_bit n k * take_bit n l) = take_bit n (k * l)\<close>
  for k l :: int
  by (simp add: take_bit_eq_mod mod_mult_eq)

lemma (in ring_1) of_nat_nat_take_bit_eq [simp]:
  \<open>of_nat (nat (take_bit n k)) = of_int (take_bit n k)\<close>
  by simp

lemma take_bit_minus_small_eq:
  \<open>take_bit n (- k) = 2 ^ n - k\<close> if \<open>0 < k\<close> \<open>k \<le> 2 ^ n\<close> for k :: int
proof -
  define m where \<open>m = nat k\<close>
  with that have \<open>k = int m\<close> and \<open>0 < m\<close> and \<open>m \<le> 2 ^ n\<close>
    by simp_all
  have \<open>(2 ^ n - m) mod 2 ^ n = 2 ^ n - m\<close>
    using \<open>0 < m\<close> by simp
  then have \<open>int ((2 ^ n - m) mod 2 ^ n) = int (2 ^ n - m)\<close>
    by simp
  then have \<open>(2 ^ n - int m) mod 2 ^ n = 2 ^ n - int m\<close>
    using \<open>m \<le> 2 ^ n\<close> by (simp only: of_nat_mod of_nat_diff) simp
  with \<open>k = int m\<close> have \<open>(2 ^ n - k) mod 2 ^ n = 2 ^ n - k\<close>
    by simp
  then show ?thesis
    by (simp add: take_bit_eq_mod)
qed

lemma drop_bit_push_bit_int:
  \<open>drop_bit m (push_bit n k) = drop_bit (m - n) (push_bit (n - m) k)\<close> for k :: int
  by (cases \<open>m \<le> n\<close>) (auto simp add: mult.left_commute [of _ \<open>2 ^ n\<close>] mult.commute [of _ \<open>2 ^ n\<close>] mult.assoc
    mult.commute [of k] drop_bit_eq_div push_bit_eq_mult not_le power_add dest!: le_Suc_ex less_imp_Suc_add)

lemma push_bit_nonnegative_int_iff [simp]:
  \<open>push_bit n k \<ge> 0 \<longleftrightarrow> k \<ge> 0\<close> for k :: int
  by (simp add: push_bit_eq_mult zero_le_mult_iff power_le_zero_eq)

lemma push_bit_negative_int_iff [simp]:
  \<open>push_bit n k < 0 \<longleftrightarrow> k < 0\<close> for k :: int
  by (subst Not_eq_iff [symmetric]) (simp add: not_less)

lemma drop_bit_nonnegative_int_iff [simp]:
  \<open>drop_bit n k \<ge> 0 \<longleftrightarrow> k \<ge> 0\<close> for k :: int
  by (induction n) (auto simp add: drop_bit_Suc drop_bit_half)

lemma drop_bit_negative_int_iff [simp]:
  \<open>drop_bit n k < 0 \<longleftrightarrow> k < 0\<close> for k :: int
  by (subst Not_eq_iff [symmetric]) (simp add: not_less)

lemma set_bit_nonnegative_int_iff [simp]:
  \<open>set_bit n k \<ge> 0 \<longleftrightarrow> k \<ge> 0\<close> for k :: int
  by (simp add: set_bit_def)

lemma set_bit_negative_int_iff [simp]:
  \<open>set_bit n k < 0 \<longleftrightarrow> k < 0\<close> for k :: int
  by (simp add: set_bit_def)

lemma unset_bit_nonnegative_int_iff [simp]:
  \<open>unset_bit n k \<ge> 0 \<longleftrightarrow> k \<ge> 0\<close> for k :: int
  by (simp add: unset_bit_def)

lemma unset_bit_negative_int_iff [simp]:
  \<open>unset_bit n k < 0 \<longleftrightarrow> k < 0\<close> for k :: int
  by (simp add: unset_bit_def)

lemma flip_bit_nonnegative_int_iff [simp]:
  \<open>flip_bit n k \<ge> 0 \<longleftrightarrow> k \<ge> 0\<close> for k :: int
  by (simp add: flip_bit_def)

lemma flip_bit_negative_int_iff [simp]:
  \<open>flip_bit n k < 0 \<longleftrightarrow> k < 0\<close> for k :: int
  by (simp add: flip_bit_def)

lemma set_bit_greater_eq:
  \<open>set_bit n k \<ge> k\<close> for k :: int
  by (simp add: set_bit_def or_greater_eq)

lemma unset_bit_less_eq:
  \<open>unset_bit n k \<le> k\<close> for k :: int
  by (simp add: unset_bit_def and_less_eq)

lemma set_bit_eq:
  \<open>set_bit n k = k + of_bool (\<not> bit k n) * 2 ^ n\<close> for k :: int
proof (rule bit_eqI)
  fix m
  show \<open>bit (set_bit n k) m \<longleftrightarrow> bit (k + of_bool (\<not> bit k n) * 2 ^ n) m\<close>
  proof (cases \<open>m = n\<close>)
    case True
    then show ?thesis
      apply (simp add: bit_set_bit_iff)
      apply (simp add: bit_iff_odd div_plus_div_distrib_dvd_right)
      done
  next
    case False
    then show ?thesis
      apply (clarsimp simp add: bit_set_bit_iff)
      apply (subst disjunctive_add)
      apply (clarsimp simp add: bit_exp_iff)
      apply (clarsimp simp add: bit_or_iff bit_exp_iff)
      done
  qed
qed 

lemma unset_bit_eq:
  \<open>unset_bit n k = k - of_bool (bit k n) * 2 ^ n\<close> for k :: int
proof (rule bit_eqI)
  fix m
  show \<open>bit (unset_bit n k) m \<longleftrightarrow> bit (k - of_bool (bit k n) * 2 ^ n) m\<close>
  proof (cases \<open>m = n\<close>)
    case True
    then show ?thesis
      apply (simp add: bit_unset_bit_iff)
      apply (simp add: bit_iff_odd)
      using div_plus_div_distrib_dvd_right [of \<open>2 ^ n\<close> \<open>- (2 ^ n)\<close> k]
      apply (simp add: dvd_neg_div)
      done
  next
    case False
    then show ?thesis
      apply (clarsimp simp add: bit_unset_bit_iff)
      apply (subst disjunctive_diff)
      apply (clarsimp simp add: bit_exp_iff)
      apply (clarsimp simp add: bit_and_iff bit_not_iff bit_exp_iff)
      done
  qed
qed (*Here*)

lemma and_int_unfold [code]:
  \<open>k AND l = (if k = 0 \<or> l = 0 then 0 else if k = - 1 then l else if l = - 1 then k
    else (k mod 2) * (l mod 2) + 2 * ((k div 2) AND (l div 2)))\<close> for k l :: int
  apply (auto split: if_splits)
  by (simp add: and_int_rec[of k l] odd_iff_mod_2_eq_one)

lemma or_int_unfold [code]:
  \<open>k OR l = (if k = - 1 \<or> l = - 1 then - 1 else if k = 0 then l else if l = 0 then k
    else max (k mod 2) (l mod 2) + 2 * ((k div 2) OR (l div 2)))\<close> for k l :: int
  by (auto simp add: or_int_rec[of k l] elim: oddE) 

lemma xor_int_unfold [code]:
  \<open>k XOR l = (if k = - 1 then NOT l else if l = - 1 then NOT k else if k = 0 then l else if l = 0 then k
    else \<bar>k mod 2 - l mod 2\<bar> + 2 * ((k div 2) XOR (l div 2)))\<close> for k l :: int
  apply (auto split: if_splits)
  apply (simp add: xor_int_rec[of k l] odd_iff_mod_2_eq_one)
  by auto

lemma bit_minus_int_iff:
  \<open>bit (- k) n \<longleftrightarrow> bit (NOT (k - 1)) n\<close>
  for k :: int
  by (simp add: bit_simps) (*Here*)

lemma take_bit_incr_eq:
  \<open>take_bit n (k + 1) = 1 + take_bit n k\<close> if \<open>take_bit n k \<noteq> 2 ^ n - 1\<close>
  for k :: int
proof -
  from that have \<open>2 ^ n \<noteq> k mod 2 ^ n + 1\<close>
    by (simp add: take_bit_eq_mod)
  moreover have \<open>k mod 2 ^ n < 2 ^ n\<close>
    by simp
  ultimately have *: \<open>k mod 2 ^ n + 1 < 2 ^ n\<close>
    by linarith
  have \<open>(k + 1) mod 2 ^ n = (k mod 2 ^ n + 1) mod 2 ^ n\<close>
    by (simp add: mod_simps)
  also have \<open>\<dots> = k mod 2 ^ n + 1\<close>
    using * by (simp add: zmod_trivial_iff)
  finally have \<open>(k + 1) mod 2 ^ n = k mod 2 ^ n + 1\<close> .
  then show ?thesis
    by (simp add: take_bit_eq_mod)
qed

lemma take_bit_decr_eq:
  \<open>take_bit n (k - 1) = take_bit n k - 1\<close> if \<open>take_bit n k \<noteq> 0\<close>
  for k :: int
proof -
  from that have \<open>k mod 2 ^ n \<noteq> 0\<close>
    by (simp add: take_bit_eq_mod)
  moreover have \<open>k mod 2 ^ n \<ge> 0\<close> \<open>k mod 2 ^ n < 2 ^ n\<close>
    by simp_all
  ultimately have *: \<open>k mod 2 ^ n > 0\<close>
    by linarith
  have \<open>(k - 1) mod 2 ^ n = (k mod 2 ^ n - 1) mod 2 ^ n\<close>
    by (simp add: mod_simps)
  also have \<open>\<dots> = k mod 2 ^ n - 1\<close>
    by (simp add: zmod_trivial_iff)
      (use \<open>k mod 2 ^ n < 2 ^ n\<close> * in linarith)
  finally have \<open>(k - 1) mod 2 ^ n = k mod 2 ^ n - 1\<close> .
  then show ?thesis
    by (simp add: take_bit_eq_mod)
qed 

lemma take_bit_int_greater_eq:
  \<open>k + 2 ^ n \<le> take_bit n k\<close> if \<open>k < 0\<close> for k :: int
proof -
  have \<open>k + 2 ^ n \<le> take_bit n (k + 2 ^ n)\<close>
  proof (cases \<open>k > - (2 ^ n)\<close>)
    case False
    then have \<open>k + 2 ^ n \<le> 0\<close>
      by simp
    also note take_bit_nonnegative
    finally show ?thesis .
  next
    case True
    with that have \<open>0 \<le> k + 2 ^ n\<close> and \<open>k + 2 ^ n < 2 ^ n\<close>
      by simp_all
    then show ?thesis
      by (simp only: take_bit_eq_mod mod_pos_pos_trivial)
  qed
  then show ?thesis
    by (simp add: take_bit_eq_mod)
qed

lemma take_bit_int_less_eq:
  \<open>take_bit n k \<le> k - 2 ^ n\<close> if \<open>2 ^ n \<le> k\<close> and \<open>n > 0\<close> for k :: int
  using that zmod_le_nonneg_dividend [of \<open>k - 2 ^ n\<close> \<open>2 ^ n\<close>]
  by (simp add: take_bit_eq_mod) 

lemma take_bit_int_less_eq_self_iff:
  \<open>take_bit n k \<le> k \<longleftrightarrow> 0 \<le> k\<close> (is \<open>?P \<longleftrightarrow> ?Q\<close>)
  for k :: int
proof
  assume ?P
  show ?Q
  proof (rule ccontr)
    assume \<open>\<not> 0 \<le> k\<close>
    then have \<open>k < 0\<close>
      by simp
    with \<open>?P\<close>
    have \<open>take_bit n k < 0\<close>
      by (rule le_less_trans)
    then show False
      by simp
  qed
next
  assume ?Q
  then show ?P
    by (simp add: take_bit_eq_mod zmod_le_nonneg_dividend)
qed

lemma take_bit_int_less_self_iff:
  \<open>take_bit n k < k \<longleftrightarrow> 2 ^ n \<le> k\<close>
  for k :: int
  by (auto simp add: less_le take_bit_int_less_eq_self_iff take_bit_int_eq_self_iff
    intro: order_trans [of 0 \<open>2 ^ n\<close> k])

lemma take_bit_int_greater_self_iff:
  \<open>k < take_bit n k \<longleftrightarrow> k < 0\<close>
  for k :: int
  using take_bit_int_less_eq_self_iff [of n k] by auto

lemma take_bit_int_greater_eq_self_iff:
  \<open>k \<le> take_bit n k \<longleftrightarrow> k < 2 ^ n\<close>
  for k :: int
  by (auto simp add: le_less take_bit_int_greater_self_iff take_bit_int_eq_self_iff
    dest: sym not_sym intro: less_trans [of k 0 \<open>2 ^ n\<close>])

lemma not_exp_less_eq_0_int [simp]:
  \<open>\<not> 2 ^ n \<le> (0::int)\<close>
  by (simp add: power_le_zero_eq)

lemma half_nonnegative_int_iff [simp]:
  \<open>k div 2 \<ge> 0 \<longleftrightarrow> k \<ge> 0\<close> for k :: int
proof (cases \<open>k \<ge> 0\<close>)
  case True
  then show ?thesis
    by (auto simp add: divide_int_def sgn_1_pos)
next
  case False
  then show ?thesis
    by (auto simp add: divide_int_def not_le elim!: evenE)
qed

lemma half_negative_int_iff [simp]:
  \<open>k div 2 < 0 \<longleftrightarrow> k < 0\<close> for k :: int
  by (subst Not_eq_iff [symmetric]) (simp add: not_less) 

lemma int_bit_bound:
  fixes k :: int
  obtains n where \<open>\<And>m. n \<le> m \<Longrightarrow> bit k m \<longleftrightarrow> bit k n\<close>
    and \<open>n > 0 \<Longrightarrow> bit k (n - 1) \<noteq> bit k n\<close>
proof -
  obtain q where *: \<open>\<And>m. q \<le> m \<Longrightarrow> bit k m \<longleftrightarrow> bit k q\<close>
  proof (cases \<open>k \<ge> 0\<close>)
    case True
    moreover from power_gt_expt [of 2 \<open>nat k\<close>]
    have \<open>nat k < 2 ^ nat k\<close>
      by simp
    then have \<open>int (nat k) < int (2 ^ nat k)\<close>
      by (simp only: of_nat_less_iff)
    ultimately have *: \<open>k div 2 ^ nat k = 0\<close>
      by simp
    show thesis
    proof (rule that [of \<open>nat k\<close>])
      fix m
      assume \<open>nat k \<le> m\<close>
      then show \<open>bit k m \<longleftrightarrow> bit k (nat k)\<close>
        by (auto simp add: * bit_iff_odd power_add zdiv_zmult2_eq dest!: le_Suc_ex)
    qed
  next
    case False
    moreover from power_gt_expt [of 2 \<open>nat (- k)\<close>]
    have \<open>nat (- k) < 2 ^ nat (- k)\<close>
      by simp
    then have \<open>int (nat (- k)) < int (2 ^ nat (- k))\<close>
      by (simp only: of_nat_less_iff)
    ultimately have \<open>- k div - (2 ^ nat (- k)) = - 1\<close>
      by (subst div_pos_neg_trivial) simp_all
    then have *: \<open>k div 2 ^ nat (- k) = - 1\<close>
      by simp
    show thesis
    proof (rule that [of \<open>nat (- k)\<close>])
      fix m
      assume \<open>nat (- k) \<le> m\<close>
      then show \<open>bit k m \<longleftrightarrow> bit k (nat (- k))\<close>
        by (auto simp add: * bit_iff_odd power_add zdiv_zmult2_eq minus_1_div_exp_eq_int dest!: le_Suc_ex)
    qed
  qed
  show thesis
  proof (cases \<open>\<forall>m. bit k m \<longleftrightarrow> bit k q\<close>)
    case True
    then have \<open>bit k 0 \<longleftrightarrow> bit k q\<close>
      by blast
    with True that [of 0] show thesis
      by simp
  next
    case False
    then obtain r where **: \<open>bit k r \<noteq> bit k q\<close>
      by blast
    have \<open>r < q\<close>
      by (rule ccontr) (use * [of r] ** in simp)
    define N where \<open>N = {n. n < q \<and> bit k n \<noteq> bit k q}\<close>
    moreover have \<open>finite N\<close> \<open>r \<in> N\<close>
      using ** N_def \<open>r < q\<close> by auto
    moreover define n where \<open>n = Suc (Max N)\<close>
    ultimately have \<open>\<And>m. n \<le> m \<Longrightarrow> bit k m \<longleftrightarrow> bit k n\<close>
      apply auto
         apply (metis (full_types, lifting) "*" Max_ge_iff Suc_n_not_le_n \<open>finite N\<close> all_not_in_conv mem_Collect_eq not_le)
        apply (metis "*" Max_ge Suc_n_not_le_n \<open>finite N\<close> linorder_not_less mem_Collect_eq)
        apply (metis "*" Max_ge Suc_n_not_le_n \<open>finite N\<close> linorder_not_less mem_Collect_eq)
      apply (metis (full_types, lifting) "*" Max_ge_iff Suc_n_not_le_n \<open>finite N\<close> all_not_in_conv mem_Collect_eq not_le)
      done
    have \<open>bit k (Max N) \<noteq> bit k n\<close>
      by (metis (mono_tags, lifting) "*" Max_in N_def \<open>\<And>m. n \<le> m \<Longrightarrow> bit k m = bit k n\<close> \<open>finite N\<close> \<open>r \<in> N\<close> empty_iff le_cases mem_Collect_eq)
    show thesis apply (rule that [of n])
      using \<open>\<And>m. n \<le> m \<Longrightarrow> bit k m = bit k n\<close> apply blast
      using \<open>bit k (Max N) \<noteq> bit k n\<close> n_def by auto
  qed
qed

lemma take_bit_tightened_less_eq_int:
  \<open>take_bit m k \<le> take_bit n k\<close> if \<open>m \<le> n\<close> for k :: int
proof -
  have \<open>take_bit m (take_bit n k) \<le> take_bit n k\<close>
    by (simp only: take_bit_int_less_eq_self_iff take_bit_nonnegative)
  with that show ?thesis
    by simp
qed

context ring_bit_operations
begin

lemma even_of_int_iff:
  \<open>even (of_int k) \<longleftrightarrow> even k\<close>
  by (induction k rule: int_bit_induct) simp_all

lemma bit_of_int_iff [bit_simps]:
  \<open>bit (of_int k) n \<longleftrightarrow> possible_bit TYPE('a) n \<and> bit k n\<close>
proof (cases \<open>possible_bit TYPE('a) n\<close>)
  case False
  then show ?thesis
    by (simp add: impossible_bit)
next
  case True
  then have \<open>bit (of_int k) n \<longleftrightarrow> bit k n\<close>
  proof (induction k arbitrary: n rule: int_bit_induct)
    case zero
    then show ?case
      by simp
  next
    case minus
    then show ?case
      by simp
  next
    case (even k)
    then show ?case
      using bit_double_iff [of \<open>of_int k\<close> n] Bit_Operations.bit_double_iff [of k n]
      by (cases n) (auto simp add: ac_simps possible_bit_def dest: mult_not_zero)
  next
    case (odd k)
    then show ?case
      using bit_double_iff [of \<open>of_int k\<close> n]
      by (cases n) (auto simp add: ac_simps bit_double_iff even_bit_succ_iff Bit_Operations.bit_Suc possible_bit_def dest: mult_not_zero)
  qed
  with True show ?thesis
    by simp
qed

lemma push_bit_of_int:
  \<open>push_bit n (of_int k) = of_int (push_bit n k)\<close>
  by (simp add: push_bit_eq_mult Bit_Operations.push_bit_eq_mult)

lemma of_int_push_bit:
  \<open>of_int (push_bit n k) = push_bit n (of_int k)\<close>
  by (simp add: push_bit_eq_mult Bit_Operations.push_bit_eq_mult)

lemma take_bit_of_int:
  \<open>take_bit n (of_int k) = of_int (take_bit n k)\<close>
  by (rule bit_eqI) (simp add: bit_take_bit_iff Bit_Operations.bit_take_bit_iff bit_of_int_iff)

lemma of_int_take_bit:
  \<open>of_int (take_bit n k) = take_bit n (of_int k)\<close>
  by (rule bit_eqI) (simp add: bit_take_bit_iff Bit_Operations.bit_take_bit_iff bit_of_int_iff)

lemma of_int_not_eq:
  \<open>of_int (NOT k) = NOT (of_int k)\<close>
  by (rule bit_eqI) (simp add: bit_not_iff Bit_Operations.bit_not_iff bit_of_int_iff)

lemma of_int_not_numeral:
  \<open>of_int (NOT (numeral k)) = NOT (numeral k)\<close>
  by (simp add: local.of_int_not_eq)

lemma of_int_and_eq:
  \<open>of_int (k AND l) = of_int k AND of_int l\<close>
  by (rule bit_eqI) (simp add: bit_of_int_iff bit_and_iff Bit_Operations.bit_and_iff)

lemma of_int_or_eq:
  \<open>of_int (k OR l) = of_int k OR of_int l\<close>
  by (rule bit_eqI) (simp add: bit_of_int_iff bit_or_iff Bit_Operations.bit_or_iff)

lemma of_int_xor_eq:
  \<open>of_int (k XOR l) = of_int k XOR of_int l\<close>
  by (rule bit_eqI) (simp add: bit_of_int_iff bit_xor_iff Bit_Operations.bit_xor_iff)

lemma of_int_mask_eq:
  \<open>of_int (mask n) = mask n\<close>
  by (induction n) (simp_all add: mask_Suc_double Bit_Operations.mask_Suc_double of_int_or_eq)

end 


subsection \<open>Instance \<^typ>\<open>nat\<close>\<close>

instantiation nat :: semiring_bit_operations
begin

definition and_nat :: \<open>nat \<Rightarrow> nat \<Rightarrow> nat\<close>
  where \<open>m AND n = nat (int m AND int n)\<close> for m n :: nat

definition or_nat :: \<open>nat \<Rightarrow> nat \<Rightarrow> nat\<close>
  where \<open>m OR n = nat (int m OR int n)\<close> for m n :: nat

definition xor_nat :: \<open>nat \<Rightarrow> nat \<Rightarrow> nat\<close>
  where \<open>m XOR n = nat (int m XOR int n)\<close> for m n :: nat

definition mask_nat :: \<open>nat \<Rightarrow> nat\<close>
  where \<open>mask n = (2 :: nat) ^ n - 1\<close>

definition push_bit_nat :: \<open>nat \<Rightarrow> nat \<Rightarrow> nat\<close>
  where \<open>push_bit_nat n m = m * 2 ^ n\<close>

definition drop_bit_nat :: \<open>nat \<Rightarrow> nat \<Rightarrow> nat\<close>
  where \<open>drop_bit_nat n m = m div 2 ^ n\<close>

definition take_bit_nat :: \<open>nat \<Rightarrow> nat \<Rightarrow> nat\<close>
  where \<open>take_bit_nat n m = m mod 2 ^ n\<close>

definition set_bit_nat :: \<open>nat \<Rightarrow> nat \<Rightarrow> nat\<close>
  where \<open>set_bit m n = n OR push_bit m 1\<close> for m n :: nat

definition unset_bit_nat :: \<open>nat \<Rightarrow> nat \<Rightarrow> nat\<close>
  where \<open>unset_bit m n = nat (unset_bit m (int n))\<close> for m n :: nat

definition flip_bit_nat :: \<open>nat \<Rightarrow> nat \<Rightarrow> nat\<close>
  where \<open>flip_bit m n = n XOR push_bit m 1\<close> for m n :: nat 

instance proof
  fix m n q :: nat
  show \<open>bit (m AND n) q \<longleftrightarrow> bit m q \<and> bit n q\<close>
    by (simp add: and_nat_def bit_simps)
  show \<open>bit (m OR n) q \<longleftrightarrow> bit m q \<or> bit n q\<close>
    by (simp add: or_nat_def bit_simps)
  show \<open>bit (m XOR n) q \<longleftrightarrow> bit m q \<noteq> bit n q\<close>
    by (simp add: xor_nat_def bit_simps)
  show \<open>bit (unset_bit m n) q \<longleftrightarrow> bit n q \<and> m \<noteq> q\<close>
    by (simp add: unset_bit_nat_def bit_simps)
qed (simp_all add: mask_nat_def set_bit_nat_def flip_bit_nat_def push_bit_nat_def drop_bit_nat_def take_bit_nat_def)

end 

lemma take_bit_nat_less_exp [simp]:
  \<open>take_bit n m < 2 ^ n\<close> for n m ::nat 
  by (simp add: take_bit_eq_mod)

lemma take_bit_nat_eq_self_iff:
  \<open>take_bit n m = m \<longleftrightarrow> m < 2 ^ n\<close> (is \<open>?P \<longleftrightarrow> ?Q\<close>)
  for n m :: nat
proof
  assume ?P
  moreover note take_bit_nat_less_exp [of n m]
  ultimately show ?Q
    by simp
next
  assume ?Q
  then show ?P
    by (simp add: take_bit_eq_mod)
qed

lemma take_bit_nat_eq_self:
  \<open>take_bit n m = m\<close> if \<open>m < 2 ^ n\<close> for m n :: nat
  using that by (simp add: take_bit_nat_eq_self_iff)

lemma take_bit_nat_less_eq_self [simp]:
  \<open>take_bit n m \<le> m\<close> for n m :: nat
  by (simp add: take_bit_eq_mod)

lemma take_bit_nat_less_self_iff:
  \<open>take_bit n m < m \<longleftrightarrow> 2 ^ n \<le> m\<close> (is \<open>?P \<longleftrightarrow> ?Q\<close>)
  for m n :: nat
proof
  assume ?P
  then have \<open>take_bit n m \<noteq> m\<close>
    by simp
  then show \<open>?Q\<close>
    by (simp add: take_bit_nat_eq_self_iff)
next
  have \<open>take_bit n m < 2 ^ n\<close>
    by (fact take_bit_nat_less_exp)
  also assume ?Q
  finally show ?P .
qed 

lemma bit_push_bit_iff_nat:
  \<open>bit (push_bit m q) n \<longleftrightarrow> m \<le> n \<and> bit q (n - m)\<close> for q :: nat
  by (auto simp add: bit_push_bit_iff)

lemma and_nat_rec:
  \<open>m AND n = of_bool (odd m \<and> odd n) + 2 * ((m div 2) AND (n div 2))\<close> for m n :: nat
  by (simp add: and_nat_def and_int_rec [of \<open>int m\<close> \<open>int n\<close>] zdiv_int nat_add_distrib nat_mult_distrib)

lemma or_nat_rec:
  \<open>m OR n = of_bool (odd m \<or> odd n) + 2 * ((m div 2) OR (n div 2))\<close> for m n :: nat
  by (simp add: or_nat_def or_int_rec [of \<open>int m\<close> \<open>int n\<close>] zdiv_int nat_add_distrib nat_mult_distrib)

lemma xor_nat_rec:
  \<open>m XOR n = of_bool (odd m \<noteq> odd n) + 2 * ((m div 2) XOR (n div 2))\<close> for m n :: nat
  by (simp add: xor_nat_def xor_int_rec [of \<open>int m\<close> \<open>int n\<close>] zdiv_int nat_add_distrib nat_mult_distrib)

lemma Suc_0_and_eq [simp]:
  \<open>Suc 0 AND n = n mod 2\<close>
  using one_and_eq [of n] by simp

lemma and_Suc_0_eq [simp]:
  \<open>n AND Suc 0 = n mod 2\<close>
  using and_one_eq [of n] by simp

lemma Suc_0_or_eq:
  \<open>Suc 0 OR n = n + of_bool (even n)\<close>
  using one_or_eq [of n] by simp

lemma or_Suc_0_eq:
  \<open>n OR Suc 0 = n + of_bool (even n)\<close>
  using or_one_eq [of n] by simp

lemma Suc_0_xor_eq:
  \<open>Suc 0 XOR n = n + of_bool (even n) - of_bool (odd n)\<close>
  using one_xor_eq [of n] by simp

lemma xor_Suc_0_eq:
  \<open>n XOR Suc 0 = n + of_bool (even n) - of_bool (odd n)\<close>
  using xor_one_eq [of n] by simp

lemma and_nat_unfold [code]:
  \<open>m AND n = (if m = 0 \<or> n = 0 then 0 else (m mod 2) * (n mod 2) + 2 * ((m div 2) AND (n div 2)))\<close>
    for m n :: nat
  by (auto simp add: and_nat_rec [of m n] elim: oddE)

lemma or_nat_unfold [code]:
  \<open>m OR n = (if m = 0 then n else if n = 0 then m
    else max (m mod 2) (n mod 2) + 2 * ((m div 2) OR (n div 2)))\<close> for m n :: nat
  by (auto simp add: or_nat_rec [of m n] elim: oddE)

lemma xor_nat_unfold [code]:
  \<open>m XOR n = (if m = 0 then n else if n = 0 then m
    else (m mod 2 + n mod 2) mod 2 + 2 * ((m div 2) XOR (n div 2)))\<close> for m n :: nat
  by (auto simp add: xor_nat_rec [of m n] elim!: oddE)

lemma [code]:
  \<open>unset_bit 0 m = 2 * (m div 2)\<close>
  \<open>unset_bit (Suc n) m = m mod 2 + 2 * unset_bit n (m div 2)\<close> for m n :: nat
  by (simp_all add: unset_bit_Suc)

lemma push_bit_of_Suc_0 [simp]:
  \<open>push_bit n (Suc 0) = 2 ^ n\<close>
  using push_bit_of_1 [where ?'a = nat] by simp

lemma take_bit_of_Suc_0 [simp]:
  \<open>take_bit n (Suc 0) = of_bool (0 < n)\<close>
  using take_bit_of_1 [where ?'a = nat] by simp

lemma drop_bit_of_Suc_0 [simp]:
  \<open>drop_bit n (Suc 0) = of_bool (n = 0)\<close>
  using drop_bit_of_1 [where ?'a = nat] by simp 

lemma Suc_mask_eq_exp:
  \<open>Suc (mask n) = 2 ^ n\<close>
  by (simp add: mask_eq_exp_minus_1)

lemma less_eq_mask:
  \<open>n \<le> mask n\<close>
  by (simp add: mask_eq_exp_minus_1 le_diff_conv2)
    (metis Suc_mask_eq_exp diff_Suc_1 diff_le_diff_pow diff_zero le_refl not_less_eq_eq power_0)

lemma less_mask:
  \<open>n < mask n\<close> if \<open>Suc 0 < n\<close>
proof -
  define m where \<open>m = n - 2\<close>
  with that have *: \<open>n = m + 2\<close>
    by simp
  have \<open>Suc (Suc (Suc m)) < 4 * 2 ^ m\<close>
    by (induction m) simp_all
  then have \<open>Suc (m + 2) < Suc (mask (m + 2))\<close>
    by (simp add: Suc_mask_eq_exp)
  then have \<open>m + 2 < mask (m + 2)\<close>
    by (simp add: less_le)
  with * show ?thesis
    by simp
qed

lemma mask_nat_less_exp [simp]:
  \<open>(mask n :: nat) < 2 ^ n\<close>
  by (simp add: mask_eq_exp_minus_1)

lemma mask_nat_positive_iff [simp]:
  \<open>(0::nat) < mask n \<longleftrightarrow> 0 < n\<close>
proof (cases \<open>n = 0\<close>)
  case True
  then show ?thesis
    by simp
next
  case False
  then have \<open>0 < n\<close>
    by simp
  then have \<open>(0::nat) < mask n\<close>
    using less_eq_mask [of n] by (rule order_less_le_trans)
  with \<open>0 < n\<close> show ?thesis
    by simp
qed

lemma take_bit_tightened_less_eq_nat:
  \<open>take_bit m q \<le> take_bit n q\<close> if \<open>m \<le> n\<close> for q :: nat
proof -
  have \<open>take_bit m (take_bit n q) \<le> take_bit n q\<close>
    by (rule take_bit_nat_less_eq_self)
  with that show ?thesis
    by simp
qed 

lemma push_bit_nat_eq:
  \<open>push_bit n (nat k) = nat (push_bit n k)\<close>
  by (cases \<open>k \<ge> 0\<close>) (simp_all add: push_bit_eq_mult nat_mult_distrib not_le mult_nonneg_nonpos2)

lemma drop_bit_nat_eq:
  \<open>drop_bit n (nat k) = nat (drop_bit n k)\<close>
  apply (cases \<open>k \<ge> 0\<close>)
   apply (simp_all add: drop_bit_eq_div nat_div_distrib nat_power_eq not_le)
  apply (simp add: divide_int_def)
  done

lemma take_bit_nat_eq:
  \<open>take_bit n (nat k) = nat (take_bit n k)\<close> if \<open>k \<ge> 0\<close>
  using that by (simp add: take_bit_eq_mod nat_mod_distrib nat_power_eq)

lemma nat_take_bit_eq:
  \<open>nat (take_bit n k) = take_bit n (nat k)\<close>
  if \<open>k \<ge> 0\<close>
  using that by (simp add: take_bit_eq_mod nat_mod_distrib nat_power_eq)

context semiring_bit_operations
begin

lemma push_bit_of_nat:
  \<open>push_bit n (of_nat m) = of_nat (push_bit n m)\<close>
  by (simp add: push_bit_eq_mult Bit_Operations.push_bit_eq_mult)

lemma of_nat_push_bit:
  \<open>of_nat (push_bit m n) = push_bit m (of_nat n)\<close>
  by (simp add: push_bit_eq_mult Bit_Operations.push_bit_eq_mult)

lemma take_bit_of_nat:
  \<open>take_bit n (of_nat m) = of_nat (take_bit n m)\<close>
  by (rule bit_eqI) (simp add: bit_take_bit_iff Bit_Operations.bit_take_bit_iff bit_of_nat_iff)

lemma of_nat_take_bit:
  \<open>of_nat (take_bit n m) = take_bit n (of_nat m)\<close>
  by (rule bit_eqI) (simp add: bit_take_bit_iff Bit_Operations.bit_take_bit_iff bit_of_nat_iff)

end

context semiring_bit_operations
begin

lemma of_nat_and_eq:
  \<open>of_nat (m AND n) = of_nat m AND of_nat n\<close>
  by (rule bit_eqI) (simp add: bit_of_nat_iff bit_and_iff Bit_Operations.bit_and_iff)

lemma of_nat_or_eq:
  \<open>of_nat (m OR n) = of_nat m OR of_nat n\<close>
  by (rule bit_eqI) (simp add: bit_of_nat_iff bit_or_iff Bit_Operations.bit_or_iff)

lemma of_nat_xor_eq:
  \<open>of_nat (m XOR n) = of_nat m XOR of_nat n\<close>
  by (rule bit_eqI) (simp add: bit_of_nat_iff bit_xor_iff Bit_Operations.bit_xor_iff)

lemma of_nat_mask_eq:
  \<open>of_nat (mask n) = mask n\<close>
  by (induction n) (simp_all add: mask_Suc_double Bit_Operations.mask_Suc_double of_nat_or_eq)

end

lemma nat_mask_eq:
  \<open>nat (mask n) = mask n\<close>
  by (simp add: nat_eq_iff of_nat_mask_eq)


subsection \<open>Common algebraic structure\<close>

class unique_euclidean_semiring_with_bit_operations =
  unique_euclidean_semiring_with_nat + semiring_bit_operations
begin

lemma take_bit_of_exp [simp]:
  \<open>take_bit m (2 ^ n) = of_bool (n < m) * 2 ^ n\<close>
  by (simp add: take_bit_eq_mod exp_mod_exp)

lemma take_bit_of_2 [simp]:
  \<open>take_bit n 2 = of_bool (2 \<le> n) * 2\<close>
  using take_bit_of_exp [of n 1] by simp

lemma push_bit_eq_0_iff [simp]:
  "push_bit n a = 0 \<longleftrightarrow> a = 0"
  by (simp add: push_bit_eq_mult)

lemma take_bit_add:
  "take_bit n (take_bit n a + take_bit n b) = take_bit n (a + b)"
  by (simp add: take_bit_eq_mod mod_simps)

lemma take_bit_of_1_eq_0_iff [simp]:
  "take_bit n 1 = 0 \<longleftrightarrow> n = 0"
  by (simp add: take_bit_eq_mod)

lemma drop_bit_Suc_bit0 [simp]:
  \<open>drop_bit (Suc n) (numeral (Num.Bit0 k)) = drop_bit n (numeral k)\<close>
  by (simp add: drop_bit_Suc numeral_Bit0_div_2)

lemma drop_bit_Suc_bit1 [simp]:
  \<open>drop_bit (Suc n) (numeral (Num.Bit1 k)) = drop_bit n (numeral k)\<close>
  by (simp add: drop_bit_Suc numeral_Bit1_div_2)

lemma drop_bit_numeral_bit0 [simp]:
  \<open>drop_bit (numeral l) (numeral (Num.Bit0 k)) = drop_bit (pred_numeral l) (numeral k)\<close>
  by (simp add: drop_bit_rec numeral_Bit0_div_2)

lemma drop_bit_numeral_bit1 [simp]:
  \<open>drop_bit (numeral l) (numeral (Num.Bit1 k)) = drop_bit (pred_numeral l) (numeral k)\<close>
  by (simp add: drop_bit_rec numeral_Bit1_div_2)

lemma take_bit_Suc_1 [simp]:
  \<open>take_bit (Suc n) 1 = 1\<close>
  by (simp add: take_bit_Suc)

lemma take_bit_Suc_bit0:
  \<open>take_bit (Suc n) (numeral (Num.Bit0 k)) = take_bit n (numeral k) * 2\<close>
  by (simp add: take_bit_Suc numeral_Bit0_div_2)

lemma take_bit_Suc_bit1:
  \<open>take_bit (Suc n) (numeral (Num.Bit1 k)) = take_bit n (numeral k) * 2 + 1\<close>
  by (simp add: take_bit_Suc numeral_Bit1_div_2 mod_2_eq_odd)

lemma take_bit_numeral_1 [simp]:
  \<open>take_bit (numeral l) 1 = 1\<close>
  by (simp add: take_bit_rec [of \<open>numeral l\<close> 1])

lemma take_bit_numeral_bit0:
  \<open>take_bit (numeral l) (numeral (Num.Bit0 k)) = take_bit (pred_numeral l) (numeral k) * 2\<close>
  by (simp add: take_bit_rec numeral_Bit0_div_2)

lemma take_bit_numeral_bit1:
  \<open>take_bit (numeral l) (numeral (Num.Bit1 k)) = take_bit (pred_numeral l) (numeral k) * 2 + 1\<close>
  by (simp add: take_bit_rec numeral_Bit1_div_2 mod_2_eq_odd)

lemma bit_of_nat_iff_bit [bit_simps]:
  \<open>bit (of_nat m) n \<longleftrightarrow> bit m n\<close>
proof -
  have \<open>even (m div 2 ^ n) \<longleftrightarrow> even (of_nat (m div 2 ^ n))\<close>
    by simp
  also have \<open>of_nat (m div 2 ^ n) = of_nat m div of_nat (2 ^ n)\<close>
    by (simp add: of_nat_div)
  finally show ?thesis
    by (simp add: bit_iff_odd semiring_bits_class.bit_iff_odd)
qed

lemma drop_bit_of_nat:
  "drop_bit n (of_nat m) = of_nat (drop_bit n m)"
  by (simp add: drop_bit_eq_div Bit_Operations.drop_bit_eq_div of_nat_div [of m "2 ^ n"])

lemma of_nat_drop_bit:
  \<open>of_nat (drop_bit m n) = drop_bit m (of_nat n)\<close>
  by (simp add: drop_bit_eq_div Bit_Operations.drop_bit_eq_div of_nat_div)

lemma take_bit_sum:
  "take_bit n a = (\<Sum>k = 0..<n. push_bit k (of_bool (bit a k)))"
  for n :: nat
proof (induction n arbitrary: a)
  case 0
  then show ?case
    by simp
next
  case (Suc n)
  have "(\<Sum>k = 0..<Suc n. push_bit k (of_bool (bit a k))) = 
    of_bool (odd a) + (\<Sum>k = Suc 0..<Suc n. push_bit k (of_bool (bit a k)))"
    by (simp add: sum.atLeast_Suc_lessThan ac_simps)
  also have "(\<Sum>k = Suc 0..<Suc n. push_bit k (of_bool (bit a k)))
    = (\<Sum>k = 0..<n. push_bit k (of_bool (bit (a div 2) k))) * 2"
    by (simp only: sum.atLeast_Suc_lessThan_Suc_shift) (simp add: sum_distrib_right push_bit_double drop_bit_Suc bit_Suc)
  finally show ?case
    using Suc [of "a div 2"] by (simp add: ac_simps take_bit_Suc mod_2_eq_odd)
qed

end

instance nat :: unique_euclidean_semiring_with_bit_operations ..

instance int :: unique_euclidean_semiring_with_bit_operations ..

lemma drop_bit_Suc_minus_bit0 [simp]:
  \<open>drop_bit (Suc n) (- numeral (Num.Bit0 k)) = drop_bit n (- numeral k :: int)\<close>
  by (simp add: drop_bit_Suc numeral_Bit0_div_2)

lemma drop_bit_Suc_minus_bit1 [simp]:
  \<open>drop_bit (Suc n) (- numeral (Num.Bit1 k)) = drop_bit n (- numeral (Num.inc k) :: int)\<close>
  by (simp add: drop_bit_Suc numeral_Bit1_div_2 add_One)

lemma drop_bit_numeral_minus_bit0 [simp]:
  \<open>drop_bit (numeral l) (- numeral (Num.Bit0 k)) = drop_bit (pred_numeral l) (- numeral k :: int)\<close>
  by (simp add: numeral_eq_Suc numeral_Bit0_div_2)

lemma drop_bit_numeral_minus_bit1 [simp]:
  \<open>drop_bit (numeral l) (- numeral (Num.Bit1 k)) = drop_bit (pred_numeral l) (- numeral (Num.inc k) :: int)\<close>
  by (simp add: numeral_eq_Suc numeral_Bit1_div_2)

lemma take_bit_Suc_minus_bit0:
  \<open>take_bit (Suc n) (- numeral (Num.Bit0 k)) = take_bit n (- numeral k) * (2 :: int)\<close>
  by (simp add: take_bit_Suc numeral_Bit0_div_2)

lemma take_bit_Suc_minus_bit1:
  \<open>take_bit (Suc n) (- numeral (Num.Bit1 k)) = take_bit n (- numeral (Num.inc k)) * 2 + (1 :: int)\<close>
  by (simp add: take_bit_Suc numeral_Bit1_div_2 add_One)

lemma take_bit_numeral_minus_bit0:
  \<open>take_bit (numeral l) (- numeral (Num.Bit0 k)) = take_bit (pred_numeral l) (- numeral k) * (2 :: int)\<close>
  by (simp add: numeral_eq_Suc numeral_Bit0_div_2 take_bit_Suc_minus_bit0)

lemma take_bit_numeral_minus_bit1:
  \<open>take_bit (numeral l) (- numeral (Num.Bit1 k)) = take_bit (pred_numeral l) (- numeral (Num.inc k)) * 2 + (1 :: int)\<close>
  by (simp add: numeral_eq_Suc numeral_Bit1_div_2 take_bit_Suc_minus_bit1)


subsection \<open>Symbolic computations on numeral expressions\<close>

context unique_euclidean_semiring_with_bit_operations
begin

lemma bit_numeral_iff:
  \<open>bit (numeral m) n \<longleftrightarrow> bit (numeral m :: nat) n\<close>
  using bit_of_nat_iff_bit [of \<open>numeral m\<close> n] by simp

lemma bit_numeral_Bit0_Suc_iff [simp]:
  \<open>bit (numeral (Num.Bit0 m)) (Suc n) \<longleftrightarrow> bit (numeral m) n\<close>
  by (simp add: bit_Suc numeral_Bit0_div_2)

lemma bit_numeral_Bit1_Suc_iff [simp]:
  \<open>bit (numeral (Num.Bit1 m)) (Suc n) \<longleftrightarrow> bit (numeral m) n\<close>
  by (simp add: bit_Suc numeral_Bit1_div_2)

lemma bit_numeral_rec:
  \<open>bit (numeral (Num.Bit0 w)) n \<longleftrightarrow> (case n of 0 \<Rightarrow> False | Suc m \<Rightarrow> bit (numeral w) m)\<close>
  \<open>bit (numeral (Num.Bit1 w)) n \<longleftrightarrow> (case n of 0 \<Rightarrow> True | Suc m \<Rightarrow> bit (numeral w) m)\<close>
  by (cases n; simp)+

lemma bit_numeral_simps [simp]:
  \<open>\<not> bit 1 (numeral n)\<close>
  \<open>bit (numeral (Num.Bit0 w)) (numeral n) \<longleftrightarrow> bit (numeral w) (pred_numeral n)\<close>
  \<open>bit (numeral (Num.Bit1 w)) (numeral n) \<longleftrightarrow> bit (numeral w) (pred_numeral n)\<close>
  by (simp_all add: bit_1_iff numeral_eq_Suc)

lemma and_numerals [simp]:
  \<open>1 AND numeral (Num.Bit0 y) = 0\<close>
  \<open>1 AND numeral (Num.Bit1 y) = 1\<close>
  \<open>numeral (Num.Bit0 x) AND numeral (Num.Bit0 y) = 2 * (numeral x AND numeral y)\<close>
  \<open>numeral (Num.Bit0 x) AND numeral (Num.Bit1 y) = 2 * (numeral x AND numeral y)\<close>
  \<open>numeral (Num.Bit0 x) AND 1 = 0\<close>
  \<open>numeral (Num.Bit1 x) AND numeral (Num.Bit0 y) = 2 * (numeral x AND numeral y)\<close>
  \<open>numeral (Num.Bit1 x) AND numeral (Num.Bit1 y) = 1 + 2 * (numeral x AND numeral y)\<close>
  \<open>numeral (Num.Bit1 x) AND 1 = 1\<close>
  by (simp_all add: bit_eq_iff) (simp_all add: bit_simps bit_Suc bit_numeral_rec split: nat.splits)

fun and_num :: \<open>num \<Rightarrow> num \<Rightarrow> num option\<close> \<^marker>\<open>contributor \<open>Andreas Lochbihler\<close>\<close>
where
  \<open>and_num num.One num.One = Some num.One\<close>
| \<open>and_num num.One (num.Bit0 n) = None\<close>
| \<open>and_num num.One (num.Bit1 n) = Some num.One\<close>
| \<open>and_num (num.Bit0 m) num.One = None\<close>
| \<open>and_num (num.Bit0 m) (num.Bit0 n) = map_option num.Bit0 (and_num m n)\<close>
| \<open>and_num (num.Bit0 m) (num.Bit1 n) = map_option num.Bit0 (and_num m n)\<close>
| \<open>and_num (num.Bit1 m) num.One = Some num.One\<close>
| \<open>and_num (num.Bit1 m) (num.Bit0 n) = map_option num.Bit0 (and_num m n)\<close>
| \<open>and_num (num.Bit1 m) (num.Bit1 n) = (case and_num m n of None \<Rightarrow> Some num.One | Some n' \<Rightarrow> Some (num.Bit1 n'))\<close>

lemma numeral_and_num:
  \<open>numeral m AND numeral n = (case and_num m n of None \<Rightarrow> 0 | Some n' \<Rightarrow> numeral n')\<close>
  by (induction m n rule: and_num.induct) (simp_all add: split: option.split)

lemma and_num_eq_None_iff:
  \<open>and_num m n = None \<longleftrightarrow> numeral m AND numeral n = 0\<close>
  by (simp add: numeral_and_num split: option.split)

lemma and_num_eq_Some_iff:
  \<open>and_num m n = Some q \<longleftrightarrow> numeral m AND numeral n = numeral q\<close>
  by (simp add: numeral_and_num split: option.split)

lemma or_numerals [simp]:
  \<open>1 OR numeral (Num.Bit0 y) = numeral (Num.Bit1 y)\<close>
  \<open>1 OR numeral (Num.Bit1 y) = numeral (Num.Bit1 y)\<close>
  \<open>numeral (Num.Bit0 x) OR numeral (Num.Bit0 y) = 2 * (numeral x OR numeral y)\<close>
  \<open>numeral (Num.Bit0 x) OR numeral (Num.Bit1 y) = 1 + 2 * (numeral x OR numeral y)\<close>
  \<open>numeral (Num.Bit0 x) OR 1 = numeral (Num.Bit1 x)\<close>
  \<open>numeral (Num.Bit1 x) OR numeral (Num.Bit0 y) = 1 + 2 * (numeral x OR numeral y)\<close>
  \<open>numeral (Num.Bit1 x) OR numeral (Num.Bit1 y) = 1 + 2 * (numeral x OR numeral y)\<close>
  \<open>numeral (Num.Bit1 x) OR 1 = numeral (Num.Bit1 x)\<close>
  by (simp_all add: bit_eq_iff) (simp_all add: bit_simps bit_Suc bit_numeral_rec split: nat.splits)

fun or_num :: \<open>num \<Rightarrow> num \<Rightarrow> num\<close> \<^marker>\<open>contributor \<open>Andreas Lochbihler\<close>\<close>
where
  \<open>or_num num.One num.One = num.One\<close>
| \<open>or_num num.One (num.Bit0 n) = num.Bit1 n\<close>
| \<open>or_num num.One (num.Bit1 n) = num.Bit1 n\<close>
| \<open>or_num (num.Bit0 m) num.One = num.Bit1 m\<close>
| \<open>or_num (num.Bit0 m) (num.Bit0 n) = num.Bit0 (or_num m n)\<close>
| \<open>or_num (num.Bit0 m) (num.Bit1 n) = num.Bit1 (or_num m n)\<close>
| \<open>or_num (num.Bit1 m) num.One = num.Bit1 m\<close>
| \<open>or_num (num.Bit1 m) (num.Bit0 n) = num.Bit1 (or_num m n)\<close>
| \<open>or_num (num.Bit1 m) (num.Bit1 n) = num.Bit1 (or_num m n)\<close>

lemma numeral_or_num:
  \<open>numeral m OR numeral n = numeral (or_num m n)\<close>
  by (induction m n rule: or_num.induct) simp_all

lemma numeral_or_num_eq:
  \<open>numeral (or_num m n) = numeral m OR numeral n\<close>
  by (simp add: numeral_or_num)

lemma xor_numerals [simp]:
  \<open>1 XOR numeral (Num.Bit0 y) = numeral (Num.Bit1 y)\<close>
  \<open>1 XOR numeral (Num.Bit1 y) = numeral (Num.Bit0 y)\<close>
  \<open>numeral (Num.Bit0 x) XOR numeral (Num.Bit0 y) = 2 * (numeral x XOR numeral y)\<close>
  \<open>numeral (Num.Bit0 x) XOR numeral (Num.Bit1 y) = 1 + 2 * (numeral x XOR numeral y)\<close>
  \<open>numeral (Num.Bit0 x) XOR 1 = numeral (Num.Bit1 x)\<close>
  \<open>numeral (Num.Bit1 x) XOR numeral (Num.Bit0 y) = 1 + 2 * (numeral x XOR numeral y)\<close>
  \<open>numeral (Num.Bit1 x) XOR numeral (Num.Bit1 y) = 2 * (numeral x XOR numeral y)\<close>
  \<open>numeral (Num.Bit1 x) XOR 1 = numeral (Num.Bit0 x)\<close>
  by (simp_all add: bit_eq_iff) (simp_all add: bit_simps bit_Suc bit_numeral_rec split: nat.splits)

fun xor_num :: \<open>num \<Rightarrow> num \<Rightarrow> num option\<close> \<^marker>\<open>contributor \<open>Andreas Lochbihler\<close>\<close>
where
  \<open>xor_num num.One num.One = None\<close>
| \<open>xor_num num.One (num.Bit0 n) = Some (num.Bit1 n)\<close>
| \<open>xor_num num.One (num.Bit1 n) = Some (num.Bit0 n)\<close>
| \<open>xor_num (num.Bit0 m) num.One = Some (num.Bit1 m)\<close>
| \<open>xor_num (num.Bit0 m) (num.Bit0 n) = map_option num.Bit0 (xor_num m n)\<close>
| \<open>xor_num (num.Bit0 m) (num.Bit1 n) = Some (case xor_num m n of None \<Rightarrow> num.One | Some n' \<Rightarrow> num.Bit1 n')\<close>
| \<open>xor_num (num.Bit1 m) num.One = Some (num.Bit0 m)\<close>
| \<open>xor_num (num.Bit1 m) (num.Bit0 n) = Some (case xor_num m n of None \<Rightarrow> num.One | Some n' \<Rightarrow> num.Bit1 n')\<close>
| \<open>xor_num (num.Bit1 m) (num.Bit1 n) = map_option num.Bit0 (xor_num m n)\<close>

lemma numeral_xor_num:
  \<open>numeral m XOR numeral n = (case xor_num m n of None \<Rightarrow> 0 | Some n' \<Rightarrow> numeral n')\<close>
  by (induction m n rule: xor_num.induct) (simp_all split: option.split)

lemma xor_num_eq_None_iff:
  \<open>xor_num m n = None \<longleftrightarrow> numeral m XOR numeral n = 0\<close>
  by (simp add: numeral_xor_num split: option.split)

lemma xor_num_eq_Some_iff:
  \<open>xor_num m n = Some q \<longleftrightarrow> numeral m XOR numeral n = numeral q\<close>
  by (simp add: numeral_xor_num split: option.split)

end

lemma bit_Suc_0_iff [bit_simps]:
  \<open>bit (Suc 0) n \<longleftrightarrow> n = 0\<close>
  using bit_1_iff [of n, where ?'a = nat] by simp

lemma and_nat_numerals [simp]:
  \<open>Suc 0 AND numeral (Num.Bit0 y) = 0\<close>
  \<open>Suc 0 AND numeral (Num.Bit1 y) = 1\<close>
  \<open>numeral (Num.Bit0 x) AND Suc 0 = 0\<close>
  \<open>numeral (Num.Bit1 x) AND Suc 0 = 1\<close>
  by (simp_all only: and_numerals flip: One_nat_def)

lemma or_nat_numerals [simp]:
  \<open>Suc 0 OR numeral (Num.Bit0 y) = numeral (Num.Bit1 y)\<close>
  \<open>Suc 0 OR numeral (Num.Bit1 y) = numeral (Num.Bit1 y)\<close>
  \<open>numeral (Num.Bit0 x) OR Suc 0 = numeral (Num.Bit1 x)\<close>
  \<open>numeral (Num.Bit1 x) OR Suc 0 = numeral (Num.Bit1 x)\<close>
  by (simp_all only: or_numerals flip: One_nat_def)

lemma xor_nat_numerals [simp]:
  \<open>Suc 0 XOR numeral (Num.Bit0 y) = numeral (Num.Bit1 y)\<close>
  \<open>Suc 0 XOR numeral (Num.Bit1 y) = numeral (Num.Bit0 y)\<close>
  \<open>numeral (Num.Bit0 x) XOR Suc 0 = numeral (Num.Bit1 x)\<close>
  \<open>numeral (Num.Bit1 x) XOR Suc 0 = numeral (Num.Bit0 x)\<close>
  by (simp_all only: xor_numerals flip: One_nat_def)

context ring_bit_operations
begin

lemma minus_numeral_inc_eq:
  \<open>- numeral (Num.inc n) = NOT (numeral n)\<close>
  by (simp add: not_eq_complement sub_inc_One_eq add_One)

lemma sub_one_eq_not_neg:
  \<open>Num.sub n num.One = NOT (- numeral n)\<close>
  by (simp add: not_eq_complement)

lemma minus_numeral_eq_not_sub_one:
  \<open>- numeral n = NOT (Num.sub n num.One)\<close>
  by (simp add: not_eq_complement)

lemma not_numeral_eq [simp]:
  \<open>NOT (numeral n) = - numeral (Num.inc n)\<close>
  by (simp add: minus_numeral_inc_eq)

lemma not_minus_numeral_eq [simp]:
  \<open>NOT (- numeral n) = Num.sub n num.One\<close>
  by (simp add: sub_one_eq_not_neg)

lemma minus_not_numeral_eq [simp]:
  \<open>- (NOT (numeral n)) = numeral (Num.inc n)\<close>
  by simp

lemma not_numeral_BitM_eq:
  \<open>NOT (numeral (Num.BitM n)) =  - numeral (num.Bit0 n)\<close>
  by (simp add: inc_BitM_eq) 

lemma not_numeral_Bit0_eq:
  \<open>NOT (numeral (Num.Bit0 n)) =  - numeral (num.Bit1 n)\<close>
  by simp

end

lemma bit_minus_numeral_int [simp]:
  \<open>bit (- numeral (num.Bit0 w) :: int) (numeral n) \<longleftrightarrow> bit (- numeral w :: int) (pred_numeral n)\<close>
  \<open>bit (- numeral (num.Bit1 w) :: int) (numeral n) \<longleftrightarrow> \<not> bit (numeral w :: int) (pred_numeral n)\<close>
  by (simp_all add: bit_minus_iff bit_not_iff numeral_eq_Suc bit_Suc add_One sub_inc_One_eq)

lemma bit_minus_numeral_Bit0_Suc_iff [simp]:
  \<open>bit (- numeral (num.Bit0 w) :: int) (Suc n) \<longleftrightarrow> bit (- numeral w :: int) n\<close>
  by (simp add: bit_Suc)

lemma bit_minus_numeral_Bit1_Suc_iff [simp]:
  \<open>bit (- numeral (num.Bit1 w) :: int) (Suc n) \<longleftrightarrow> \<not> bit (numeral w :: int) n\<close>
  by (simp add: bit_Suc add_One flip: bit_not_int_iff)

lemma and_not_numerals:
  \<open>1 AND NOT 1 = (0 :: int)\<close>
  \<open>1 AND NOT (numeral (Num.Bit0 n)) = (1 :: int)\<close>
  \<open>1 AND NOT (numeral (Num.Bit1 n)) = (0 :: int)\<close>
  \<open>numeral (Num.Bit0 m) AND NOT (1 :: int) = numeral (Num.Bit0 m)\<close>
  \<open>numeral (Num.Bit0 m) AND NOT (numeral (Num.Bit0 n)) = (2 :: int) * (numeral m AND NOT (numeral n))\<close>
  \<open>numeral (Num.Bit0 m) AND NOT (numeral (Num.Bit1 n)) = (2 :: int) * (numeral m AND NOT (numeral n))\<close>
  \<open>numeral (Num.Bit1 m) AND NOT (1 :: int) = numeral (Num.Bit0 m)\<close>
  \<open>numeral (Num.Bit1 m) AND NOT (numeral (Num.Bit0 n)) = 1 + (2 :: int) * (numeral m AND NOT (numeral n))\<close>
  \<open>numeral (Num.Bit1 m) AND NOT (numeral (Num.Bit1 n)) = (2 :: int) * (numeral m AND NOT (numeral n))\<close>
  by (simp_all add: bit_eq_iff) (auto simp add: bit_simps bit_Suc bit_numeral_rec BitM_inc_eq sub_inc_One_eq split: nat.split)

fun and_not_num :: \<open>num \<Rightarrow> num \<Rightarrow> num option\<close> \<^marker>\<open>contributor \<open>Andreas Lochbihler\<close>\<close>
where
  \<open>and_not_num num.One num.One = None\<close>
| \<open>and_not_num num.One (num.Bit0 n) = Some num.One\<close>
| \<open>and_not_num num.One (num.Bit1 n) = None\<close>
| \<open>and_not_num (num.Bit0 m) num.One = Some (num.Bit0 m)\<close>
| \<open>and_not_num (num.Bit0 m) (num.Bit0 n) = map_option num.Bit0 (and_not_num m n)\<close>
| \<open>and_not_num (num.Bit0 m) (num.Bit1 n) = map_option num.Bit0 (and_not_num m n)\<close>
| \<open>and_not_num (num.Bit1 m) num.One = Some (num.Bit0 m)\<close>
| \<open>and_not_num (num.Bit1 m) (num.Bit0 n) = (case and_not_num m n of None \<Rightarrow> Some num.One | Some n' \<Rightarrow> Some (num.Bit1 n'))\<close>
| \<open>and_not_num (num.Bit1 m) (num.Bit1 n) = map_option num.Bit0 (and_not_num m n)\<close>

lemma int_numeral_and_not_num:
  \<open>numeral m AND NOT (numeral n) = (case and_not_num m n of None \<Rightarrow> 0 :: int | Some n' \<Rightarrow> numeral n')\<close>
  by (induction m n rule: and_not_num.induct) (simp_all del: not_numeral_eq not_one_eq add: and_not_numerals split: option.splits)

lemma int_numeral_not_and_num:
  \<open>NOT (numeral m) AND numeral n = (case and_not_num n m of None \<Rightarrow> 0 :: int | Some n' \<Rightarrow> numeral n')\<close>
  using int_numeral_and_not_num [of n m] by (simp add: ac_simps)

lemma and_not_num_eq_None_iff:
  \<open>and_not_num m n = None \<longleftrightarrow> numeral m AND NOT (numeral n) = (0 :: int)\<close>
  by (simp del: not_numeral_eq add: int_numeral_and_not_num split: option.split)

lemma and_not_num_eq_Some_iff:
  \<open>and_not_num m n = Some q \<longleftrightarrow> numeral m AND NOT (numeral n) = (numeral q :: int)\<close>
  by (simp del: not_numeral_eq add: int_numeral_and_not_num split: option.split)

lemma and_minus_numerals [simp]:
  \<open>1 AND - (numeral (num.Bit0 n)) = (0::int)\<close>
  \<open>1 AND - (numeral (num.Bit1 n)) = (1::int)\<close>
  \<open>numeral m AND - (numeral (num.Bit0 n)) = (case and_not_num m (Num.BitM n) of None \<Rightarrow> 0 :: int | Some n' \<Rightarrow> numeral n')\<close>
  \<open>numeral m AND - (numeral (num.Bit1 n)) = (case and_not_num m (Num.Bit0 n) of None \<Rightarrow> 0 :: int | Some n' \<Rightarrow> numeral n')\<close>
  \<open>- (numeral (num.Bit0 n)) AND 1 = (0::int)\<close>
  \<open>- (numeral (num.Bit1 n)) AND 1 = (1::int)\<close>
  \<open>- (numeral (num.Bit0 n)) AND numeral m = (case and_not_num m (Num.BitM n) of None \<Rightarrow> 0 :: int | Some n' \<Rightarrow> numeral n')\<close>
  \<open>- (numeral (num.Bit1 n)) AND numeral m = (case and_not_num m (Num.Bit0 n) of None \<Rightarrow> 0 :: int | Some n' \<Rightarrow> numeral n')\<close>
  by (simp_all del: not_numeral_eq add: ac_simps
    and_not_numerals one_and_eq not_numeral_BitM_eq not_numeral_Bit0_eq and_not_num_eq_None_iff and_not_num_eq_Some_iff split: option.split)

lemma and_minus_minus_numerals [simp]:
  \<open>- (numeral m :: int) AND - (numeral n :: int) = NOT ((numeral m - 1) OR (numeral n - 1))\<close>
  by (simp add: minus_numeral_eq_not_sub_one)

lemma or_not_numerals:
  \<open>1 OR NOT 1 = NOT (0 :: int)\<close>
  \<open>1 OR NOT (numeral (Num.Bit0 n)) = NOT (numeral (Num.Bit0 n) :: int)\<close>
  \<open>1 OR NOT (numeral (Num.Bit1 n)) = NOT (numeral (Num.Bit0 n) :: int)\<close>
  \<open>numeral (Num.Bit0 m) OR NOT (1 :: int) = NOT (1 :: int)\<close>
  \<open>numeral (Num.Bit0 m) OR NOT (numeral (Num.Bit0 n)) = 1 + (2 :: int) * (numeral m OR NOT (numeral n))\<close>
  \<open>numeral (Num.Bit0 m) OR NOT (numeral (Num.Bit1 n)) = (2 :: int) * (numeral m OR NOT (numeral n))\<close>
  \<open>numeral (Num.Bit1 m) OR NOT (1 :: int) = NOT (0 :: int)\<close>
  \<open>numeral (Num.Bit1 m) OR NOT (numeral (Num.Bit0 n)) = 1 + (2 :: int) * (numeral m OR NOT (numeral n))\<close>
  \<open>numeral (Num.Bit1 m) OR NOT (numeral (Num.Bit1 n)) = 1 + (2 :: int) * (numeral m OR NOT (numeral n))\<close>
  by (simp_all add: bit_eq_iff)
    (auto simp add: bit_simps bit_Suc bit_numeral_rec sub_inc_One_eq split: nat.split)

fun or_not_num_neg :: \<open>num \<Rightarrow> num \<Rightarrow> num\<close> \<^marker>\<open>contributor \<open>Andreas Lochbihler\<close>\<close>
where
  \<open>or_not_num_neg num.One num.One = num.One\<close>
| \<open>or_not_num_neg num.One (num.Bit0 m) = num.Bit1 m\<close>
| \<open>or_not_num_neg num.One (num.Bit1 m) = num.Bit1 m\<close>
| \<open>or_not_num_neg (num.Bit0 n) num.One = num.Bit0 num.One\<close>
| \<open>or_not_num_neg (num.Bit0 n) (num.Bit0 m) = Num.BitM (or_not_num_neg n m)\<close>
| \<open>or_not_num_neg (num.Bit0 n) (num.Bit1 m) = num.Bit0 (or_not_num_neg n m)\<close>
| \<open>or_not_num_neg (num.Bit1 n) num.One = num.One\<close>
| \<open>or_not_num_neg (num.Bit1 n) (num.Bit0 m) = Num.BitM (or_not_num_neg n m)\<close>
| \<open>or_not_num_neg (num.Bit1 n) (num.Bit1 m) = Num.BitM (or_not_num_neg n m)\<close>

lemma int_numeral_or_not_num_neg:
  \<open>numeral m OR NOT (numeral n :: int) = - numeral (or_not_num_neg m n)\<close>
  by (induction m n rule: or_not_num_neg.induct) (simp_all del: not_numeral_eq not_one_eq add: or_not_numerals, simp_all)

lemma int_numeral_not_or_num_neg:
  \<open>NOT (numeral m) OR (numeral n :: int) = - numeral (or_not_num_neg n m)\<close>
  using int_numeral_or_not_num_neg [of n m] by (simp add: ac_simps)

lemma numeral_or_not_num_eq:
  \<open>numeral (or_not_num_neg m n) = - (numeral m OR NOT (numeral n :: int))\<close>
  using int_numeral_or_not_num_neg [of m n] by simp

lemma or_minus_numerals [simp]:
  \<open>1 OR - (numeral (num.Bit0 n)) = - (numeral (or_not_num_neg num.One (Num.BitM n)) :: int)\<close>
  \<open>1 OR - (numeral (num.Bit1 n)) = - (numeral (num.Bit1 n) :: int)\<close>
  \<open>numeral m OR - (numeral (num.Bit0 n)) = - (numeral (or_not_num_neg m (Num.BitM n)) :: int)\<close>
  \<open>numeral m OR - (numeral (num.Bit1 n)) = - (numeral (or_not_num_neg m (Num.Bit0 n)) :: int)\<close>
  \<open>- (numeral (num.Bit0 n)) OR 1 = - (numeral (or_not_num_neg num.One (Num.BitM n)) :: int)\<close>
  \<open>- (numeral (num.Bit1 n)) OR 1 = - (numeral (num.Bit1 n) :: int)\<close>
  \<open>- (numeral (num.Bit0 n)) OR numeral m = - (numeral (or_not_num_neg m (Num.BitM n)) :: int)\<close>
  \<open>- (numeral (num.Bit1 n)) OR numeral m = - (numeral (or_not_num_neg m (Num.Bit0 n)) :: int)\<close>
  by (simp_all only: or.commute [of _ 1] or.commute [of _ \<open>numeral m\<close>]
    minus_numeral_eq_not_sub_one or_not_numerals
    numeral_or_not_num_eq arith_simps minus_minus numeral_One)

lemma or_minus_minus_numerals [simp]:
  \<open>- (numeral m :: int) OR - (numeral n :: int) = NOT ((numeral m - 1) AND (numeral n - 1))\<close>
  by (simp add: minus_numeral_eq_not_sub_one)

lemma xor_minus_numerals [simp]:
  \<open>- numeral n XOR k = NOT (neg_numeral_class.sub n num.One XOR k)\<close>
  \<open>k XOR - numeral n = NOT (k XOR (neg_numeral_class.sub n num.One))\<close> for k :: int
  by (simp_all add: minus_numeral_eq_not_sub_one)

definition take_bit_num :: \<open>nat \<Rightarrow> num \<Rightarrow> num option\<close>
  where \<open>take_bit_num n m =
    (if take_bit n (numeral m ::nat) = 0 then None else Some (num_of_nat (take_bit n (numeral m ::nat))))\<close>

lemma take_bit_num_simps:
  \<open>take_bit_num 0 m = None\<close>
  \<open>take_bit_num (Suc n) Num.One =
    Some Num.One\<close>
  \<open>take_bit_num (Suc n) (Num.Bit0 m) =
    (case take_bit_num n m of None \<Rightarrow> None | Some q \<Rightarrow> Some (Num.Bit0 q))\<close>
  \<open>take_bit_num (Suc n) (Num.Bit1 m) =
    Some (case take_bit_num n m of None \<Rightarrow> Num.One | Some q \<Rightarrow> Num.Bit1 q)\<close>
  \<open>take_bit_num (numeral r) Num.One =
    Some Num.One\<close>
  \<open>take_bit_num (numeral r) (Num.Bit0 m) =
    (case take_bit_num (pred_numeral r) m of None \<Rightarrow> None | Some q \<Rightarrow> Some (Num.Bit0 q))\<close>
  \<open>take_bit_num (numeral r) (Num.Bit1 m) =
    Some (case take_bit_num (pred_numeral r) m of None \<Rightarrow> Num.One | Some q \<Rightarrow> Num.Bit1 q)\<close>
  by (auto simp add: take_bit_num_def ac_simps mult_2 num_of_nat_double
    take_bit_Suc_bit0 take_bit_Suc_bit1 take_bit_numeral_bit0 take_bit_numeral_bit1)

lemma take_bit_num_code [code]:
  \<comment> \<open>Ocaml-style pattern matching is more robust wrt. different representations of \<^typ>\<open>nat\<close>\<close>
  \<open>take_bit_num n m = (case (n, m)
   of (0, _) \<Rightarrow> None
    | (Suc n, Num.One) \<Rightarrow> Some Num.One
    | (Suc n, Num.Bit0 m) \<Rightarrow> (case take_bit_num n m of None \<Rightarrow> None | Some q \<Rightarrow> Some (Num.Bit0 q))
    | (Suc n, Num.Bit1 m) \<Rightarrow> Some (case take_bit_num n m of None \<Rightarrow> Num.One | Some q \<Rightarrow> Num.Bit1 q))\<close>
  by (cases n; cases m) (simp_all add: take_bit_num_simps)

context semiring_bit_operations
begin

lemma take_bit_num_eq_None_imp:
  \<open>take_bit m (numeral n) = 0\<close> if \<open>take_bit_num m n = None\<close>
proof -
  from that have \<open>take_bit m (numeral n :: nat) = 0\<close>
    by (simp add: take_bit_num_def split: if_splits)
  then have \<open>of_nat (take_bit m (numeral n)) = of_nat 0\<close>
    by simp
  then show ?thesis
    by (simp add: of_nat_take_bit)
qed
    
lemma take_bit_num_eq_Some_imp:
  \<open>take_bit m (numeral n) = numeral q\<close> if \<open>take_bit_num m n = Some q\<close>
proof -
  from that have \<open>take_bit m (numeral n :: nat) = numeral q\<close>
    by (auto simp add: take_bit_num_def Num.numeral_num_of_nat_unfold split: if_splits)
  then have \<open>of_nat (take_bit m (numeral n)) = of_nat (numeral q)\<close>
    by simp
  then show ?thesis
    by (simp add: of_nat_take_bit)
qed

lemma take_bit_numeral_numeral:
  \<open>take_bit (numeral m) (numeral n) =
    (case take_bit_num (numeral m) n of None \<Rightarrow> 0 | Some q \<Rightarrow> numeral q)\<close>
  by (auto split: option.split dest: take_bit_num_eq_None_imp take_bit_num_eq_Some_imp)

end

lemma take_bit_numeral_minus_numeral_int:
  \<open>take_bit (numeral m) (- numeral n :: int) =
    (case take_bit_num (numeral m) n of None \<Rightarrow> 0 | Some q \<Rightarrow> take_bit (numeral m) (2 ^ numeral m - numeral q))\<close> (is \<open>?lhs = ?rhs\<close>)
proof (cases \<open>take_bit_num (numeral m) n\<close>)
  case None
  then show ?thesis
    by (auto dest: take_bit_num_eq_None_imp [where ?'a = int] simp add: take_bit_eq_0_iff)
next
  case (Some q)
  then have q: \<open>take_bit (numeral m) (numeral n :: int) = numeral q\<close>
    by (auto dest: take_bit_num_eq_Some_imp)
  let ?T = \<open>take_bit (numeral m) :: int \<Rightarrow> int\<close>
  have *: \<open>?T (2 ^ numeral m) = ?T (?T 0)\<close>
    by (simp add: take_bit_eq_0_iff)
  have \<open>?lhs = ?T (0 - numeral n)\<close>
    by simp
  also have \<open>\<dots> = ?T (?T (?T 0) - ?T (?T (numeral n)))\<close>
    by (simp only: take_bit_diff)
  also have \<open>\<dots> = ?T (2 ^ numeral m - ?T (numeral n))\<close>
    by (simp only: take_bit_diff flip: * )
  also have \<open>\<dots> = ?rhs\<close>
    by (simp add: q Some)
  finally show ?thesis .
qed

declare take_bit_num_simps [simp]
  take_bit_numeral_numeral [simp]
  take_bit_numeral_minus_numeral_int [simp]


subsection \<open>More properties\<close>

lemma take_bit_eq_mask_iff:
  \<open>take_bit n k = mask n \<longleftrightarrow> take_bit n (k + 1) = 0\<close> (is \<open>?P \<longleftrightarrow> ?Q\<close>)
  for k :: int
proof
  assume ?P
  then have \<open>take_bit n (take_bit n k + take_bit n 1) = 0\<close>
    by (simp add: mask_eq_exp_minus_1 take_bit_eq_0_iff)
  then show ?Q
    by (simp only: take_bit_add)
next
  assume ?Q
  then have \<open>take_bit n (k + 1) - 1 = - 1\<close>
    by simp
  then have \<open>take_bit n (take_bit n (k + 1) - 1) = take_bit n (- 1)\<close>
    by simp
  moreover have \<open>take_bit n (take_bit n (k + 1) - 1) = take_bit n k\<close>
    by (simp add: take_bit_eq_mod mod_simps)
  ultimately show ?P
    by simp
qed

lemma take_bit_eq_mask_iff_exp_dvd:
  \<open>take_bit n k = mask n \<longleftrightarrow> 2 ^ n dvd k + 1\<close>
  for k :: int
  by (simp add: take_bit_eq_mask_iff flip: take_bit_eq_0_iff)


subsection \<open>Bit concatenation\<close>

definition concat_bit :: \<open>nat \<Rightarrow> int \<Rightarrow> int \<Rightarrow> int\<close>
  where \<open>concat_bit n k l = take_bit n k OR push_bit n l\<close>

lemma bit_concat_bit_iff [bit_simps]:
  \<open>bit (concat_bit m k l) n \<longleftrightarrow> n < m \<and> bit k n \<or> m \<le> n \<and> bit l (n - m)\<close>
  by (simp add: concat_bit_def bit_or_iff bit_and_iff bit_take_bit_iff bit_push_bit_iff ac_simps)

lemma concat_bit_eq:
  \<open>concat_bit n k l = take_bit n k + push_bit n l\<close>
  by (simp add: concat_bit_def take_bit_eq_mask
    bit_and_iff bit_mask_iff bit_push_bit_iff disjunctive_add)

lemma concat_bit_0 [simp]:
  \<open>concat_bit 0 k l = l\<close>
  by (simp add: concat_bit_def)

lemma concat_bit_Suc:
  \<open>concat_bit (Suc n) k l = k mod 2 + 2 * concat_bit n (k div 2) l\<close>
  by (simp add: concat_bit_eq take_bit_Suc push_bit_double)

lemma concat_bit_of_zero_1 [simp]:
  \<open>concat_bit n 0 l = push_bit n l\<close>
  by (simp add: concat_bit_def)

lemma concat_bit_of_zero_2 [simp]:
  \<open>concat_bit n k 0 = take_bit n k\<close>
  by (simp add: concat_bit_def take_bit_eq_mask)

lemma concat_bit_nonnegative_iff [simp]:
  \<open>concat_bit n k l \<ge> 0 \<longleftrightarrow> l \<ge> 0\<close>
  by (simp add: concat_bit_def)

lemma concat_bit_negative_iff [simp]:
  \<open>concat_bit n k l < 0 \<longleftrightarrow> l < 0\<close>
  by (simp add: concat_bit_def)

lemma concat_bit_assoc:
  \<open>concat_bit n k (concat_bit m l r) = concat_bit (m + n) (concat_bit n k l) r\<close>
  by (rule bit_eqI) (auto simp add: bit_concat_bit_iff ac_simps)

lemma concat_bit_assoc_sym:
  \<open>concat_bit m (concat_bit n k l) r = concat_bit (min m n) k (concat_bit (m - n) l r)\<close>
  by (rule bit_eqI) (auto simp add: bit_concat_bit_iff ac_simps min_def)

lemma concat_bit_eq_iff:
  \<open>concat_bit n k l = concat_bit n r s
    \<longleftrightarrow> take_bit n k = take_bit n r \<and> l = s\<close> (is \<open>?P \<longleftrightarrow> ?Q\<close>)
proof
  assume ?Q
  then show ?P
    by (simp add: concat_bit_def)
next
  assume ?P
  then have *: \<open>bit (concat_bit n k l) m = bit (concat_bit n r s) m\<close> for m
    by (simp add: bit_eq_iff)
  have \<open>take_bit n k = take_bit n r\<close>
  proof (rule bit_eqI)
    fix m
    from * [of m]
    show \<open>bit (take_bit n k) m \<longleftrightarrow> bit (take_bit n r) m\<close>
      by (auto simp add: bit_take_bit_iff bit_concat_bit_iff)
  qed
  moreover have \<open>push_bit n l = push_bit n s\<close>
  proof (rule bit_eqI)
    fix m
    from * [of m]
    show \<open>bit (push_bit n l) m \<longleftrightarrow> bit (push_bit n s) m\<close>
      by (auto simp add: bit_push_bit_iff bit_concat_bit_iff)
  qed
  then have \<open>l = s\<close>
    by (simp add: push_bit_eq_mult)
  ultimately show ?Q
    by (simp add: concat_bit_def)
qed

lemma take_bit_concat_bit_eq:
  \<open>take_bit m (concat_bit n k l) = concat_bit (min m n) k (take_bit (m - n) l)\<close>
  by (rule bit_eqI)
    (auto simp add: bit_take_bit_iff bit_concat_bit_iff min_def)  

lemma concat_bit_take_bit_eq:
  \<open>concat_bit n (take_bit n b) = concat_bit n b\<close>
  by (simp add: concat_bit_def [abs_def])


subsection \<open>Taking bits with sign propagation\<close>

context ring_bit_operations
begin

definition signed_take_bit :: \<open>nat \<Rightarrow> 'a \<Rightarrow> 'a\<close>
  where \<open>signed_take_bit n a = take_bit n a OR (of_bool (bit a n) * NOT (mask n))\<close>

lemma signed_take_bit_eq_if_positive:
  \<open>signed_take_bit n a = take_bit n a\<close> if \<open>\<not> bit a n\<close>
  using that by (simp add: signed_take_bit_def)

lemma signed_take_bit_eq_if_negative:
  \<open>signed_take_bit n a = take_bit n a OR NOT (mask n)\<close> if \<open>bit a n\<close>
  using that by (simp add: signed_take_bit_def)

lemma even_signed_take_bit_iff:
  \<open>even (signed_take_bit m a) \<longleftrightarrow> even a\<close>
  by (auto simp add: signed_take_bit_def even_or_iff even_mask_iff bit_double_iff)

lemma bit_signed_take_bit_iff [bit_simps]:
  \<open>bit (signed_take_bit m a) n \<longleftrightarrow> possible_bit TYPE('a) n \<and> bit a (min m n)\<close>
  by (simp add: signed_take_bit_def bit_take_bit_iff bit_or_iff bit_not_iff bit_mask_iff min_def not_le)
    (blast dest: bit_imp_possible_bit)

lemma signed_take_bit_0 [simp]:
  \<open>signed_take_bit 0 a = - (a mod 2)\<close>
  by (simp add: signed_take_bit_def odd_iff_mod_2_eq_one)

lemma signed_take_bit_Suc:
  \<open>signed_take_bit (Suc n) a = a mod 2 + 2 * signed_take_bit n (a div 2)\<close>
  apply (simp add: bit_eq_iff bit_sum_mult_2_cases bit_simps bit_Suc[symmetric])
  apply (simp add: possible_bit_less_imp flip: min_Suc_Suc)
  done

lemma signed_take_bit_of_0 [simp]:
  \<open>signed_take_bit n 0 = 0\<close>
  by (simp add: signed_take_bit_def)

lemma signed_take_bit_of_minus_1 [simp]:
  \<open>signed_take_bit n (- 1) = - 1\<close>
  by (simp add: signed_take_bit_def mask_eq_exp_minus_1 possible_bit_def)

lemma signed_take_bit_Suc_1 [simp]:
  \<open>signed_take_bit (Suc n) 1 = 1\<close>
  by (simp add: signed_take_bit_Suc)

lemma signed_take_bit_numeral_of_1 [simp]:
  \<open>signed_take_bit (numeral k) 1 = 1\<close>
  by (simp add: bit_1_iff signed_take_bit_eq_if_positive)

lemma signed_take_bit_rec:
  \<open>signed_take_bit n a = (if n = 0 then - (a mod 2) else a mod 2 + 2 * signed_take_bit (n - 1) (a div 2))\<close>
  by (cases n) (simp_all add: signed_take_bit_Suc)

lemma signed_take_bit_eq_iff_take_bit_eq:
  \<open>signed_take_bit n a = signed_take_bit n b \<longleftrightarrow> take_bit (Suc n) a = take_bit (Suc n) b\<close>
proof -
  have \<open>bit (signed_take_bit n a) = bit (signed_take_bit n b) \<longleftrightarrow> bit (take_bit (Suc n) a) = bit (take_bit (Suc n) b)\<close>
    by (simp add: fun_eq_iff bit_signed_take_bit_iff bit_take_bit_iff not_le less_Suc_eq_le min_def)
      (use bit_imp_possible_bit in fastforce)
  then show ?thesis
    by (auto simp add: fun_eq_iff intro: bit_eqI)
qed

lemma signed_take_bit_signed_take_bit [simp]:
  \<open>signed_take_bit m (signed_take_bit n a) = signed_take_bit (min m n) a\<close>
  by (auto simp add: bit_eq_iff bit_simps ac_simps)

lemma signed_take_bit_take_bit:
  \<open>signed_take_bit m (take_bit n a) = (if n \<le> m then take_bit n else signed_take_bit m) a\<close>
  by (rule bit_eqI) (auto simp add: bit_signed_take_bit_iff min_def bit_take_bit_iff)

lemma take_bit_signed_take_bit:
  \<open>take_bit m (signed_take_bit n a) = take_bit m a\<close> if \<open>m \<le> Suc n\<close>
  using that by (rule le_SucE; intro bit_eqI)
   (auto simp add: bit_take_bit_iff bit_signed_take_bit_iff min_def less_Suc_eq)

end

text \<open>Modulus centered around 0\<close>

lemma signed_take_bit_eq_concat_bit:
  \<open>signed_take_bit n k = concat_bit n k (- of_bool (bit k n))\<close>
  by (simp add: concat_bit_def signed_take_bit_def)

lemma signed_take_bit_add:
  \<open>signed_take_bit n (signed_take_bit n k + signed_take_bit n l) = signed_take_bit n (k + l)\<close>
  for k l :: int
proof -
  have \<open>take_bit (Suc n)
     (take_bit (Suc n) (signed_take_bit n k) +
      take_bit (Suc n) (signed_take_bit n l)) =
    take_bit (Suc n) (k + l)\<close>
    by (simp add: take_bit_signed_take_bit take_bit_add)
  then show ?thesis
    by (simp only: signed_take_bit_eq_iff_take_bit_eq take_bit_add)
qed

lemma signed_take_bit_diff:
  \<open>signed_take_bit n (signed_take_bit n k - signed_take_bit n l) = signed_take_bit n (k - l)\<close>
  for k l :: int
proof -
  have \<open>take_bit (Suc n)
     (take_bit (Suc n) (signed_take_bit n k) -
      take_bit (Suc n) (signed_take_bit n l)) =
    take_bit (Suc n) (k - l)\<close>
    by (simp add: take_bit_signed_take_bit take_bit_diff)
  then show ?thesis
    by (simp only: signed_take_bit_eq_iff_take_bit_eq take_bit_diff)
qed

lemma signed_take_bit_minus:
  \<open>signed_take_bit n (- signed_take_bit n k) = signed_take_bit n (- k)\<close>
  for k :: int
proof -
  have \<open>take_bit (Suc n)
     (- take_bit (Suc n) (signed_take_bit n k)) =
    take_bit (Suc n) (- k)\<close>
    by (simp add: take_bit_signed_take_bit take_bit_minus)
  then show ?thesis
    by (simp only: signed_take_bit_eq_iff_take_bit_eq take_bit_minus)
qed

lemma signed_take_bit_mult:
  \<open>signed_take_bit n (signed_take_bit n k * signed_take_bit n l) = signed_take_bit n (k * l)\<close>
  for k l :: int
proof -
  have \<open>take_bit (Suc n)
     (take_bit (Suc n) (signed_take_bit n k) *
      take_bit (Suc n) (signed_take_bit n l)) =
    take_bit (Suc n) (k * l)\<close>
    by (simp add: take_bit_signed_take_bit take_bit_mult)
  then show ?thesis
    by (simp only: signed_take_bit_eq_iff_take_bit_eq take_bit_mult)
qed

lemma signed_take_bit_eq_take_bit_minus:
  \<open>signed_take_bit n k = take_bit (Suc n) k - 2 ^ Suc n * of_bool (bit k n)\<close>
  for k :: int
proof (cases \<open>bit k n\<close>)
  case True
  have \<open>signed_take_bit n k = take_bit (Suc n) k OR NOT (mask (Suc n))\<close>
    by (rule bit_eqI) (auto simp add: bit_signed_take_bit_iff min_def bit_take_bit_iff bit_or_iff bit_not_iff bit_mask_iff less_Suc_eq True)
  then have \<open>signed_take_bit n k = take_bit (Suc n) k + NOT (mask (Suc n))\<close>
    by (simp add: disjunctive_add bit_take_bit_iff bit_not_iff bit_mask_iff)
  with True show ?thesis
    by (simp flip: minus_exp_eq_not_mask)
next
  case False
  show ?thesis
    by (rule bit_eqI) (simp add: False bit_signed_take_bit_iff bit_take_bit_iff min_def less_Suc_eq)
qed

lemma signed_take_bit_eq_take_bit_shift:
  \<open>signed_take_bit n k = take_bit (Suc n) (k + 2 ^ n) - 2 ^ n\<close>
  for k :: int
proof -
  have *: \<open>take_bit n k OR 2 ^ n = take_bit n k + 2 ^ n\<close>
    by (simp add: disjunctive_add bit_exp_iff bit_take_bit_iff)
  have \<open>take_bit n k - 2 ^ n = take_bit n k + NOT (mask n)\<close>
    by (simp add: minus_exp_eq_not_mask)
  also have \<open>\<dots> = take_bit n k OR NOT (mask n)\<close>
    by (rule disjunctive_add)
      (simp add: bit_exp_iff bit_take_bit_iff bit_not_iff bit_mask_iff)
  finally have **: \<open>take_bit n k - 2 ^ n = take_bit n k OR NOT (mask n)\<close> .
  have \<open>take_bit (Suc n) (k + 2 ^ n) = take_bit (Suc n) (take_bit (Suc n) k + take_bit (Suc n) (2 ^ n))\<close>
    by (simp only: take_bit_add)
  also have \<open>take_bit (Suc n) k = 2 ^ n * of_bool (bit k n) + take_bit n k\<close>
    by (simp add: take_bit_Suc_from_most)
  finally have \<open>take_bit (Suc n) (k + 2 ^ n) = take_bit (Suc n) (2 ^ (n + of_bool (bit k n)) + take_bit n k)\<close>
    by (simp add: ac_simps)
  also have \<open>2 ^ (n + of_bool (bit k n)) + take_bit n k = 2 ^ (n + of_bool (bit k n)) OR take_bit n k\<close>
    by (rule disjunctive_add)
      (auto simp add: disjunctive_add bit_take_bit_iff bit_double_iff bit_exp_iff)
  finally show ?thesis
    using * ** by (simp add: signed_take_bit_def concat_bit_Suc min_def ac_simps)
qed

lemma signed_take_bit_nonnegative_iff [simp]:
  \<open>0 \<le> signed_take_bit n k \<longleftrightarrow> \<not> bit k n\<close>
  for k :: int
  by (simp add: signed_take_bit_def not_less concat_bit_def)

lemma signed_take_bit_negative_iff [simp]:
  \<open>signed_take_bit n k < 0 \<longleftrightarrow> bit k n\<close>
  for k :: int
  by (simp add: signed_take_bit_def not_less concat_bit_def)

lemma signed_take_bit_int_greater_eq_minus_exp [simp]:
  \<open>- (2 ^ n) \<le> signed_take_bit n k\<close>
  for k :: int
  by (simp add: signed_take_bit_eq_take_bit_shift)

lemma signed_take_bit_int_less_exp [simp]:
  \<open>signed_take_bit n k < 2 ^ n\<close>
  for k :: int
  using take_bit_int_less_exp [of \<open>Suc n\<close>]
  by (simp add: signed_take_bit_eq_take_bit_shift)

lemma signed_take_bit_int_eq_self_iff:
  \<open>signed_take_bit n k = k \<longleftrightarrow> - (2 ^ n) \<le> k \<and> k < 2 ^ n\<close>
  for k :: int
  by (auto simp add: signed_take_bit_eq_take_bit_shift take_bit_int_eq_self_iff algebra_simps)

lemma signed_take_bit_int_eq_self:
  \<open>signed_take_bit n k = k\<close> if \<open>- (2 ^ n) \<le> k\<close> \<open>k < 2 ^ n\<close>
  for k :: int
  using that by (simp add: signed_take_bit_int_eq_self_iff)

lemma signed_take_bit_int_less_eq_self_iff:
  \<open>signed_take_bit n k \<le> k \<longleftrightarrow> - (2 ^ n) \<le> k\<close>
  for k :: int
  by (simp add: signed_take_bit_eq_take_bit_shift take_bit_int_less_eq_self_iff algebra_simps)
    linarith

lemma signed_take_bit_int_less_self_iff:
  \<open>signed_take_bit n k < k \<longleftrightarrow> 2 ^ n \<le> k\<close>
  for k :: int
  by (simp add: signed_take_bit_eq_take_bit_shift take_bit_int_less_self_iff algebra_simps)

lemma signed_take_bit_int_greater_self_iff:
  \<open>k < signed_take_bit n k \<longleftrightarrow> k < - (2 ^ n)\<close>
  for k :: int
  by (simp add: signed_take_bit_eq_take_bit_shift take_bit_int_greater_self_iff algebra_simps)
    linarith

lemma signed_take_bit_int_greater_eq_self_iff:
  \<open>k \<le> signed_take_bit n k \<longleftrightarrow> k < 2 ^ n\<close>
  for k :: int
  by (simp add: signed_take_bit_eq_take_bit_shift take_bit_int_greater_eq_self_iff algebra_simps)

lemma signed_take_bit_int_greater_eq:
  \<open>k + 2 ^ Suc n \<le> signed_take_bit n k\<close> if \<open>k < - (2 ^ n)\<close>
  for k :: int
  using that take_bit_int_greater_eq [of \<open>k + 2 ^ n\<close> \<open>Suc n\<close>]
  by (simp add: signed_take_bit_eq_take_bit_shift)

lemma signed_take_bit_int_less_eq:
  \<open>signed_take_bit n k \<le> k - 2 ^ Suc n\<close> if \<open>k \<ge> 2 ^ n\<close>
  for k :: int
  using that take_bit_int_less_eq [of \<open>Suc n\<close> \<open>k + 2 ^ n\<close>]
  by (simp add: signed_take_bit_eq_take_bit_shift)

lemma signed_take_bit_Suc_bit0 [simp]:
  \<open>signed_take_bit (Suc n) (numeral (Num.Bit0 k)) = signed_take_bit n (numeral k) * (2 :: int)\<close>
  by (simp add: signed_take_bit_Suc)

lemma signed_take_bit_Suc_bit1 [simp]:
  \<open>signed_take_bit (Suc n) (numeral (Num.Bit1 k)) = signed_take_bit n (numeral k) * 2 + (1 :: int)\<close>
  by (simp add: signed_take_bit_Suc)

lemma signed_take_bit_Suc_minus_bit0 [simp]:
  \<open>signed_take_bit (Suc n) (- numeral (Num.Bit0 k)) = signed_take_bit n (- numeral k) * (2 :: int)\<close>
  by (simp add: signed_take_bit_Suc)

lemma signed_take_bit_Suc_minus_bit1 [simp]:
  \<open>signed_take_bit (Suc n) (- numeral (Num.Bit1 k)) = signed_take_bit n (- numeral k - 1) * 2 + (1 :: int)\<close>
  by (simp add: signed_take_bit_Suc)

lemma signed_take_bit_numeral_bit0 [simp]:
  \<open>signed_take_bit (numeral l) (numeral (Num.Bit0 k)) = signed_take_bit (pred_numeral l) (numeral k) * (2 :: int)\<close>
  by (simp add: signed_take_bit_rec)

lemma signed_take_bit_numeral_bit1 [simp]:
  \<open>signed_take_bit (numeral l) (numeral (Num.Bit1 k)) = signed_take_bit (pred_numeral l) (numeral k) * 2 + (1 :: int)\<close>
  by (simp add: signed_take_bit_rec)

lemma signed_take_bit_numeral_minus_bit0 [simp]:
  \<open>signed_take_bit (numeral l) (- numeral (Num.Bit0 k)) = signed_take_bit (pred_numeral l) (- numeral k) * (2 :: int)\<close>
  by (simp add: signed_take_bit_rec)

lemma signed_take_bit_numeral_minus_bit1 [simp]:
  \<open>signed_take_bit (numeral l) (- numeral (Num.Bit1 k)) = signed_take_bit (pred_numeral l) (- numeral k - 1) * 2 + (1 :: int)\<close>
  by (simp add: signed_take_bit_rec)

lemma signed_take_bit_code [code]:
  \<open>signed_take_bit n a =
  (let l = take_bit (Suc n) a
   in if bit l n then l + push_bit (Suc n) (- 1) else l)\<close>
proof -
  have *: \<open>take_bit (Suc n) a + push_bit n (- 2) =
    take_bit (Suc n) a OR NOT (mask (Suc n))\<close>
    by (auto simp add: bit_take_bit_iff bit_push_bit_iff bit_not_iff bit_mask_iff disjunctive_add
       simp flip: push_bit_minus_one_eq_not_mask)
  show ?thesis
    by (rule bit_eqI)
      (auto simp add: Let_def * bit_signed_take_bit_iff bit_take_bit_iff min_def less_Suc_eq bit_not_iff
        bit_mask_iff bit_or_iff simp del: push_bit_minus_one_eq_not_mask)
qed


subsection \<open>Horner sums\<close>

context semiring_bit_operations
begin

lemma horner_sum_bit_eq_take_bit:
  \<open>horner_sum of_bool 2 (map (bit a) [0..<n]) = take_bit n a\<close>
proof (induction a arbitrary: n rule: bits_induct)
  case (stable a)
  moreover have \<open>bit a = (\<lambda>_. odd a)\<close>
    using stable by (simp add: stable_imp_bit_iff_odd fun_eq_iff)
  moreover have \<open>{q. q < n} = {0..<n}\<close>
    by auto
  ultimately show ?case
    by (simp add: stable_imp_take_bit_eq horner_sum_eq_sum mask_eq_sum_exp)
next
  case (rec a b)
  show ?case
  proof (cases n)
    case 0
    then show ?thesis
      by simp
  next
    case (Suc m)
    have \<open>map (bit (of_bool b + 2 * a)) [0..<Suc m] = b # map (bit (of_bool b + 2 * a)) [Suc 0..<Suc m]\<close>
      by (simp only: upt_conv_Cons) simp
    also have \<open>\<dots> = b # map (bit a) [0..<m]\<close>
      by (simp only: flip: map_Suc_upt) (simp add: bit_Suc rec.hyps)
    finally show ?thesis
      using Suc rec.IH [of m] by (simp add: take_bit_Suc rec.hyps)
        (simp_all add: ac_simps mod_2_eq_odd)
  qed
qed

end

context unique_euclidean_semiring_with_bit_operations
begin

lemma bit_horner_sum_bit_iff [bit_simps]:
  \<open>bit (horner_sum of_bool 2 bs) n \<longleftrightarrow> n < length bs \<and> bs ! n\<close>
proof (induction bs arbitrary: n)
  case Nil
  then show ?case
    by simp
next
  case (Cons b bs)
  show ?case
  proof (cases n)
    case 0
    then show ?thesis
      by simp
  next
    case (Suc m)
    with bit_rec [of _ n] Cons.prems Cons.IH [of m]
    show ?thesis by simp
  qed
qed

lemma take_bit_horner_sum_bit_eq:
  \<open>take_bit n (horner_sum of_bool 2 bs) = horner_sum of_bool 2 (take n bs)\<close>
  by (auto simp add: bit_eq_iff bit_take_bit_iff bit_horner_sum_bit_iff)

end

lemma horner_sum_of_bool_2_less:
  \<open>(horner_sum of_bool 2 bs :: int) < 2 ^ length bs\<close>
proof -
  have \<open>(\<Sum>n = 0..<length bs. of_bool (bs ! n) * (2::int) ^ n) \<le> (\<Sum>n = 0..<length bs. 2 ^ n)\<close>
    by (rule sum_mono) simp
  also have \<open>\<dots> = 2 ^ length bs - 1\<close>
    by (induction bs) simp_all
  finally show ?thesis
    by (simp add: horner_sum_eq_sum)
qed


subsection \<open>Key ideas of bit operations\<close>

text \<open>
  When formalizing bit operations, it is tempting to represent
  bit values as explicit lists over a binary type. This however
  is a bad idea, mainly due to the inherent ambiguities in
  representation concerning repeating leading bits.

  Hence this approach avoids such explicit lists altogether
  following an algebraic path:

  \<^item> Bit values are represented by numeric types: idealized
    unbounded bit values can be represented by type \<^typ>\<open>int\<close>,
    bounded bit values by quotient types over \<^typ>\<open>int\<close>.

  \<^item> (A special case are idealized unbounded bit values ending
    in @{term [source] 0} which can be represented by type \<^typ>\<open>nat\<close> but
    only support a restricted set of operations).

  \<^item> From this idea follows that

      \<^item> multiplication by \<^term>\<open>2 :: int\<close> is a bit shift to the left and

      \<^item> division by \<^term>\<open>2 :: int\<close> is a bit shift to the right.

  \<^item> Concerning bounded bit values, iterated shifts to the left
    may result in eliminating all bits by shifting them all
    beyond the boundary.  The property \<^prop>\<open>(2 :: int) ^ n \<noteq> 0\<close>
    represents that \<^term>\<open>n\<close> is \<^emph>\<open>not\<close> beyond that boundary.

  \<^item> The projection on a single bit is then @{thm bit_iff_odd [where ?'a = int, no_vars]}.

  \<^item> This leads to the most fundamental properties of bit values:

      \<^item> Equality rule: @{thm bit_eqI [where ?'a = int, no_vars]}

      \<^item> Induction rule: @{thm bits_induct [where ?'a = int, no_vars]}

  \<^item> Typical operations are characterized as follows:

      \<^item> Singleton \<^term>\<open>n\<close>th bit: \<^term>\<open>(2 :: int) ^ n\<close>

      \<^item> Bit mask upto bit \<^term>\<open>n\<close>: @{thm mask_eq_exp_minus_1 [where ?'a = int, no_vars]}

      \<^item> Left shift: @{thm push_bit_eq_mult [where ?'a = int, no_vars]}

      \<^item> Right shift: @{thm drop_bit_eq_div [where ?'a = int, no_vars]}

      \<^item> Truncation: @{thm take_bit_eq_mod [where ?'a = int, no_vars]}

      \<^item> Negation: @{thm bit_not_iff [where ?'a = int, no_vars]}

      \<^item> And: @{thm bit_and_iff [where ?'a = int, no_vars]}

      \<^item> Or: @{thm bit_or_iff [where ?'a = int, no_vars]}

      \<^item> Xor: @{thm bit_xor_iff [where ?'a = int, no_vars]}

      \<^item> Set a single bit: @{thm set_bit_def [where ?'a = int, no_vars]}

      \<^item> Unset a single bit: @{thm unset_bit_def [where ?'a = int, no_vars]}

      \<^item> Flip a single bit: @{thm flip_bit_def [where ?'a = int, no_vars]}

      \<^item> Signed truncation, or modulus centered around \<^term>\<open>0::int\<close>: @{thm signed_take_bit_def [no_vars]}

      \<^item> Bit concatenation: @{thm concat_bit_def [no_vars]}

      \<^item> (Bounded) conversion from and to a list of bits: @{thm horner_sum_bit_eq_take_bit [where ?'a = int, no_vars]}
\<close>

no_notation
  not  (\<open>NOT\<close>)
    and "and"  (infixr \<open>AND\<close> 64)
    and or  (infixr \<open>OR\<close>  59)
    and xor  (infixr \<open>XOR\<close> 59)

bundle bit_operations_syntax
begin

notation
  not  (\<open>NOT\<close>)
    and "and"  (infixr \<open>AND\<close> 64)
    and or  (infixr \<open>OR\<close>  59)
    and xor  (infixr \<open>XOR\<close> 59)

end

end
