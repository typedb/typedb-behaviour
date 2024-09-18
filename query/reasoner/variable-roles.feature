# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# TODO: re-enable all steps in file when TypeDB is faster
#noinspection CucumberUndefinedStep
Feature: Variable Role Resolution

  Background: Set up database
    Given typedb starts
    Given connection opens with default authentication
    Given reasoning schema
      """
      define

      entity1 sub entity,
          owns name,
          plays binary-base:role1,
          plays binary-base:role2,
          plays ternary-base:ternary-role1,
          plays ternary-base:ternary-role2,
          plays ternary-base:ternary-role3,
          plays quaternary-base:quat-role1,
          plays quaternary-base:quat-role2,
          plays quaternary-base:quat-role3,
          plays quaternary-base:quat-role4;

      binary-base sub relation,
          relates role1,
          relates role2;

      binary sub binary-base;

      ternary-base sub relation,
          relates ternary-role1,
          relates ternary-role2,
          relates ternary-role3;

      ternary sub ternary-base;

      quaternary-base sub relation,
          relates quat-role1,
          relates quat-role2,
          relates quat-role3,
          relates quat-role4;

      quaternary sub quaternary-base;

      name sub attribute, value string;

      rule binary-base-transitive: when {
          (role1:$x, role2:$z) isa binary-base;
          (role1:$z, role2:$y) isa binary-base;
      } then {
          (role1:$x, role2:$y) isa binary-base;
      };

      rule binary-base-to-ternary-base: when {
          (role1:$x, role2:$z) isa binary-base;
          (role1:$z, role2:$y) isa binary-base;
      } then {
          (ternary-role1:$x, ternary-role2:$y, ternary-role3: $z) isa ternary-base;
      };

      rule binary-base-to-quaternary-base: when {
          (role1:$x, role2:$z1) isa binary-base;
          (role1:$z1, role2:$z2) isa binary-base;
          (role1:$z2, role2:$y) isa binary-base;
      } then {
          (quat-role1:$x, quat-role2:$z1, quat-role3: $z2, quat-role4: $y) isa quaternary-base;
      };

      rule binary-transitive: when {
          (role1:$x, role2:$z) isa binary;
          (role1:$z, role2:$y) isa binary;
      } then {
          (role1:$x, role2:$y) isa binary;
      };

      rule binary-to-ternary: when {
          (role1:$x, role2:$z) isa binary;
          (role1:$z, role2:$y) isa binary;
      } then {
          (ternary-role1:$x, ternary-role2:$y, ternary-role3: $z) isa ternary;
      };

      rule binary-to-quaternary: when {
          (role1:$x, role2:$z1) isa binary;
          (role1:$z1, role2:$z2) isa binary;
          (role1:$z2, role2:$y) isa binary;
      } then {
          (quat-role1:$x, quat-role2:$z1, quat-role3: $z2, quat-role4: $y) isa quaternary;
      };
      """
    Given reasoning data
      """
      insert

      $a isa entity1, has name 'a';
      $b isa entity1, has name 'b';
      $c isa entity1, has name 'c';

      (role1: $a, role2: $b) isa binary-base;
      (role1: $b, role2: $c) isa binary-base;
      (role1: $c, role2: $b) isa binary-base;

      (role1: $a, role2: $b) isa binary;
      (role1: $b, role2: $a) isa binary;
      """
  # Materialised binary-base: [ab, bc, cb]
  # Inferred binary-base: [aa, ac, bb, ca, cc]
  # Materialised binary: [ab, ba]
  # Inferred binary: [aa, bb]
  # Total binary-base relations: 9 (3^2)
  # Total binary relations: 4 (2^2)
  # Inferred ternary-base: [aaa, aab, aac, aba, abb, abc, aca, acb, acc, baa, bab, bac,
  # bba, bbb, bbc, bca, bcb, bcc, caa, cab, cac, cba, cbb, cbc, cca, ccb, ccc]
  # Inferred ternary: [aaa, aab, aba, abb, baa, bab, bba, bbb]
  # Total ternary-base relations: 27 (3^3)
  # Total ternary relations: 8 (2^3)
  # Total quaternary-base relations: 81 (3^4)
  # Total quaternary relations: 16 (2^4)


  Scenario: when querying a binary relation, introducing a variable role doubles the answer size
    Given verifier is initialised
    Given reasoning query
      """
      match (role1: $a, role2: $b) isa binary-base;
      """
    Then verify answer size is: 9
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match (role1: $a, $r1: $b) isa binary-base;
      """
    # $r1 in {role, role2} (2 options => double answer size)
    Then verify answer size is: 18
    Then verify answers are sound
    Then verify answers are complete


  Scenario: converting a fixed role to a variable role bound with 'type' does not modify the answer size
    Given verifier is initialised
    Given reasoning query
      """
      match (role1: $a, $r1: $b) isa binary-base;
      """
    Then verify answer size is: 18
    Then verify answers are sound
    Then verify answers are complete
    # This query should be equivalent to the one above
    Given reasoning query
      """
      match
        ($r1: $a, $r2: $b) isa binary-base;
        $r1 type binary-base:role1;
      get $a, $b, $r2;
      """
    Then verify answer size is: 18
    Then verify answers are sound
    Then verify answers are complete


  Scenario: when querying a binary relation, introducing a meta 'role' and a variable role triples the answer size
    Given verifier is initialised
    Given reasoning query
      """
      match (role1: $a, role2: $b) isa binary-base;
      """
    Then verify answer size is: 9
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match (role: $a, $r1: $b) isa binary-base;
      """
    # $r1 in {role, role1, role2} (3 options => triple answer size)
    Then verify answer size is: 27
    Then verify answers are sound
    Then verify answers are complete

  @ignore
  Scenario: converting a fixed role to a variable bound with 'type role' (?)
    Given verifier is initialised
    Given reasoning query
      """
      match (role: $a, $r1: $b) isa binary-base;
      """
    Then verify answer size is: 27
    Then verify answers are sound
    Then verify answers are complete
    # This query should be equivalent to the one above
    Given reasoning query
      """
      match
        ($r1: $a, $r2: $b) isa binary-base;
        $r1 type relation:role;
      get $a, $b, $r2;
      """
    Then verify answer size is: 27
    Then verify answers are sound
    Then verify answers are complete


  Scenario: converting a fixed role to a variable bound with 'sub role' (?)
    Given verifier is initialised
    Given reasoning query
      """
      match (role: $a, $r1: $b) isa binary-base;
      """
    Then verify answer size is: 27
    Then verify answers are sound
    Then verify answers are complete
    # This query should be equivalent to the one above
    Given reasoning query
      """
      match
        ($r1: $a, $r2: $b) isa binary-base;
        $r1 sub relation:role;
      get $a, $b, $r2;
      """
    Then verify answer size is: 27
    Then verify answers are sound
    Then verify answers are complete


  Scenario: when all other role variables are bound, introducing a meta 'role' doesn't affect the answer size
    Given verifier is initialised
    Given reasoning query
      """
      match
        ($r1: $a, $r2: $b) isa binary-base;
        $r1 type relation:role;
        $r2 type binary-base:role2;

      """
    # $r1 must be 'role' and $r2 must be 'role2'
    Then verify answer size is: 9
    Then verify answers are sound
    Then verify answers are complete
    # This query is equivalent to the one above
    Given reasoning query
      """
      match
        (role: $a, $r2: $b) isa binary-base;
        $r2 type binary-base:role2;

      """
    Then verify answer size is: 9
    Then verify answers are sound
    Then verify answers are complete


  Scenario: when querying a binary relation, introducing two variable roles multiplies the answer size by 7
    Given verifier is initialised
    Given reasoning query
      """
      match (role1: $a, role2: $b) isa binary-base;
      """
    Then verify answer size is: 9
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match ($r1: $a, $r2: $b) isa binary-base;
      """
    # r1    | r2    |
    # role  | role  |
    # role  | role1 |
    # role  | role2 |
    # role1 | role  |
    # role1 | role2 |
    # role2 | role  |
    # role2 | role1 |
    Then verify answer size is: 63
    Then verify answers are sound
    Then verify answers are complete


  # General formula for the answer size with K degrees of freedom [*] on an N-ary relation
  #
  # Each role player variable can be mapped to either of the conceptDOF concepts and these can repeat.
  # Each role variable can be mapped to either of RPs roles and only meta roles can repeat.
  #
  # For the case of conceptDOF = 3, roleDOF = 3.
  # We start by considering the number of meta roles we allow.
  # If we consider only non-meta roles, considering each relation player we get:
  # C^3_0 x 3.3 x 3.2 x 3 = 162 combinations
  #
  # If we consider single metarole - C^3_1 = 3 possibilities of assigning them:
  # C^3_1 x 3.3 x 3.2 x 3 = 486 combinations
  #
  # Two metaroles - again C^3_2 = 3 possibilities of assigning them:
  # C^3_2 x 3.3 x 3   x 3 = 243 combinations
  #
  # Three metaroles, C^3_3 = 1 possiblity of assignment:
  # C^3_3 x 3   x 3   x 3 = 81 combinations
  #
  # -> Total = 918 different answers
  # In general, for i allowed meta roles we have:
  # C^{RP}_i PRODUCT_{j = RP-i}{ (conceptDOF)x(roleDOF-j) } x PRODUCT_i{ conceptDOF} } answers.
  #
  # So total number of answers is:
  # SUM_i{ C^{RP}_i PRODUCT_{j = RP-i}{ (conceptDOF)x(roleDOF-j) } x PRODUCT_i{ conceptDOF} }
  #
  # [*] Here "degrees of freedom" is based on the number of concepts to choose from when matching 'isa [type]'.
  # For our test dataset, the conceptDOF is 2 when matching 'isa binary'/'isa quaternary', and 3 for their supertypes.
  # This is because the test data doesn't have 'c' as a roleplayer in any 'binary', 'ternary' or 'quaternary' relations.
  # So for the parent relations we have {a,b,c} to choose from; for the children we have only 'a' and 'b'.
  #
  # The following Java method returns the number of answer combinations for given # of role vars and concept DOF:
  #  private int answerCombinations(int RPS, int conceptDOF) {
  #    int answers = 0;
  #    //i is the number of meta roles
  #    for (int i = 0; i <= RPS; i++) {
  #      int RPProduct = 1;
  #      //rps with non-meta roles
  #      for (int j = 0; j < RPS - i; j++) RPProduct *= conceptDOF * (RPS - j);
  #      //rps with meta roles
  #      for (int k = 0; k < i; k++) RPProduct *= conceptDOF;
  #      answers += CombinatoricsUtils.binomialCoefficient(RPS, i) * RPProduct;
  #    }
  #    return answers;
  #  }

  Scenario: variable roles are correctly mapped to answers for a ternary relation with 3 possible roleplayers
    Given reasoning query
      """
      match
        (ternary-role1: $a1, $r2: $a2, $r3: $a3) isa ternary-base;
        $a1 has name 'a';

      """
    # This query is equivalent to matching ($r2: $a2, $r3: $a3) isa binary-base, as role1 and $a1 each have only 1 value
    Then verify answer size is: 63
    Given reasoning query
      """
      match (ternary-role1: $a1, $r2: $a2, $r3: $a3) isa ternary-base;
      """
    # Now the bound role 'role1' is in {a, b, c}, tripling the answer size
    Then verify answer size is: 189
    Given reasoning query
      """
      match ($r1: $a1, $r2: $a2, $r3: $a3) isa ternary-base;
      """
    # r1    | r2    | r3    |
    # role  | role  | role  | 1 pattern
    # roleX | role  | role  | 3 patterns: X in {1,2,3}
    # role  | roleX | role  | 3 patterns: X in {1,2,3}
    # role  | role  | roleX | 3 patterns: X in {1,2,3}
    # roleX | roleY | role  | 6 patterns: [X,Y] in {[1,2],[1,3],[2,3],[2,1],[3,1],[3,2]}
    # roleX | role  | roleY | 6 patterns: [X,Y] in {[1,2],[1,3],[2,3],[2,1],[3,1],[3,2]}
    # role  | roleX | roleY | 6 patterns: [X,Y] in {[1,2],[1,3],[2,3],[2,1],[3,1],[3,2]}
    # roleX | roleY | roleZ | 6 patterns (# of permutations of {1,2,3} = 3! = 6)
    # TOTAL                 | 34 patterns
    #
    # For each pattern, we have one possible match per ternary-base relation
    # and there are 27 ternary-base relations in the knowledge graph (including both material and inferred)
    # giving an answer size of 34 * 27 = 918
    Then verify answer size is: 918


  Scenario: variable roles are correctly mapped to answers for a quaternary relation with 3 possible roleplayers
    Given reasoning query
      """
      match
        (quat-role1: $a1, $r2: $a2, $r3: $a3, $r4: $a4) isa quaternary-base;
        $a1 has name 'a';

      """
    # This query is equivalent to matching ($r2: $a2, $r3: $a3, $r4: $a4) isa ternary-base
    Then verify answer size is: 918
    Given reasoning query
      """
      match (quat-role1: $a1, $r2: $a2, $r3: $a3, $r4: $a4) isa quaternary-base;
      """
    # Now the bound role 'role1' is in {a, b, c}, tripling the answer size
    Then verify answer size is: 2754
    Given reasoning query
      """
      match ($r1: $a1, $r2: $a2, $r3: $a3, $r4: $a4) isa quaternary-base;
      """
    # {r1,r2,r3,r4}
    # 4 occurrences of 'role' | 1 pattern
    # 3 occurrences of 'role' | 16 patterns (4 combinations of 1 role var x (4) distinct roles)
    # 2 occurrences of 'role' | 72 patterns (6 combinations of 2 role vars x (4x3 = 12) distinct pairs of roles)
    # 1 occurrence of 'role'  | 96 patterns (4 combinations of 3 role vars x (4x3x2 = 24) distinct triplets of roles)
    # 0 occurrences of 'role' | 24 patterns (4! = 24 distinct quartets of roles)
    # TOTAL                   | 209 patterns
    #
    # For each pattern, we have one possible match per quaternary-base relation
    # and there are 81 quaternary-base relations in the knowledge graph (including both material and inferred)
    # giving an answer size of 209 * 81 = 16929
    Then verify answer size is: 16929


  # Note: This test uses the sub-relation 'quaternary' while the others use the super-relations '{n}-ary-base'.
  # If this test passes while others fail, there may be an inheritance-related issue.
  Scenario: variable roles are correctly mapped to answers for a quaternary relation with 2 possible roleplayers
    Given reasoning query
      """
      match
        (quat-role1: $a1, $r2: $a2, $r3: $a3, $r4: $a4) isa quaternary;
        $a1 has name 'a';

      """
    # This query is equivalent to matching ($r2: $a2, $r3: $a3, $r4: $a4) isa ternary
    Then verify answer size is: 272
    Given reasoning query
      """
      match (quat-role1: $a1, $r2: $a2, $r3: $a3, $r4: $a4) isa quaternary;
      """
    # Now the bound role 'role1' is in {a, b}, doubling the answer size
    Then verify answer size is: 544
    Given reasoning query
      """
      match ($r1: $a1, $r2: $a2, $r3: $a3, $r4: $a4) isa quaternary;
      """
    # {r1,r2,r3,r4} | 209 patterns (see 'quaternary-base' scenario for details)
    # For each pattern, we have one possible match per quaternary relation
    # and there are 16 quaternary relations in the knowledge graph (including both material and inferred)
    # giving an answer size of 209 * 16 = 3344
    Then verify answer size is: 3344
