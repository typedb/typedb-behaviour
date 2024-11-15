# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# TODO: All tests with directed can be changed to a "Verify answer set is equivalent for" test.

#noinspection CucumberUndefinedStep
Feature: Recursion Resolution

  In some cases, the inferences made by a rule are used to trigger further inferences by the same rule.
  This test feature verifies that so-called recursive inference works as intended.

  Background: Set up database
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define

      entity person,
        owns name,
        plays friendship:friend,
        plays employment:employee;

      entity company,
        owns name,
        plays employment:employer;

      entity place,
        owns name,
        plays location-hierarchy:subordinate,
        plays location-hierarchy:superior;

      relation friendship,
        relates friend @card(2);

      relation employment,
        relates employee,
        relates employer;

      relation location-hierarchy,
        relates subordinate,
        relates superior;

      attribute name value string;
      """
    Given transaction commits


  Scenario: when resolution produces an infinite stream of answers, limiting the answer size allows it to terminate
    # TODO: We need to use arithmetic for this. I can probably just count upwards, one at a time.

  Scenario: when a query using transitivity has a limit exceeding the result size, answers are consistent between runs
    # TODO: Taken from relation-inference

  # TODO: Remove? this doesn't seem to add much
  Scenario: the types of entities in inferred relations can be used to make further inferences
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define

      entity big-place sub place;

      fun transitive_location_hierarchy_pairs() -> { place, place }:
      match
        (subordinate: $x, superior: $y) isa location-hierarchy;
        (subordinate: $y, superior: $z) isa location-hierarchy;
      return {$x, $z};

      fun big_location_hierarchy_pairs() -> { place, place }:
      match
        $x, $y in transitive_location_hierarchy_pairs();
        $x isa big-place;
        $y isa big-place;
      return {$x, $y};


      fun transitive_location_hierarchy_directed($x: place) -> { place }:
      match
        (subordinate: $x, superior: $y) isa location-hierarchy;
        (subordinate: $y, superior: $z) isa location-hierarchy;
      return {$z};

      fun big_location_hierarchy_directed($x: big-place) -> { big-place }:
      match
        $y in transitive_location_hierarchy_directed($x);
        $y isa big-place;
      return {$y};
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa big-place, has name "Mount Kilimanjaro";
      $y isa place, has name "Tanzania";
      $z isa big-place, has name "Africa";

      (subordinate: $x, superior: $y) isa location-hierarchy;
      (subordinate: $y, superior: $z) isa location-hierarchy;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match $x, $y in big_location_hierarchy_pairs();
      """
    Then answer size is: 1

    Given get answers of typeql read query
      """
      match $x isa big-place; $y in big_location_hierarchy_directed($x);
      """
    Then answer size is: 1


  Scenario: ancestor test
  from Bancilhon - An Amateur's Introduction to Recursive Query Processing Strategies p. 25

    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define

      attribute name, value string;
      entity person, owns name;
      relation parentship, relates parent, relates child;
      person plays parentship:parent, plays parentship:child;


      fun ancestor_pairs() -> { person, person } :
        match
         $x isa person; $y isa person;
         { (parent: $x, child: $y) isa parentship; } or
         {
            (parent: $x, child: $z) isa parentship;
            $z, $y1 in ancestor_pairs();
            $y is $y1;
          };
        return { $x, $y };

      fun ancestors_directed($x: person) -> { person } :
        match
         $y isa person;
         { (parent: $x, child: $y) isa parentship; } or
         {
            (parent: $x, child: $z) isa parentship;
            $y1 in ancestors_directed($z);
            $y is $y1;
          };
        return { $y };

      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
    """
      insert

      $a isa person, has name 'a';
      $aa isa person, has name 'aa';
      $aaa isa person, has name 'aaa';
      $aab isa person, has name 'aab';
      $aaaa isa person, has name 'aaaa';
      $ab isa person, has name 'ab';
      $c isa person, has name 'c';
      $ca isa person, has name 'ca';

      (parent: $a, child: $aa) isa parentship;
      (parent: $a, child: $ab) isa parentship;
      (parent: $aa, child: $aaa) isa parentship;
      (parent: $aa, child: $aab) isa parentship;
      (parent: $aaa, child: $aaaa) isa parentship;
      (parent: $c, child: $ca) isa parentship;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match
        $X, $Y in ancestor_pairs();
        $X has name 'aa';
        $Y has name $name;
      select $Y, $name;
      """
    Then answer size is: 3
    Then verify answer set is equivalent for query
      """
      match
        $Y isa person, has name $name;
        {$name == 'aaa';} or {$name == 'aab';} or {$name == 'aaaa';};
      select $Y, $name;
      """
    Given get answers of typeql read query
      """
      match
        $X isa person, has name 'aa';
        $Y in ancestors_directed($X);
        $Y has name $name;
      select $Y, $name;
      """
    Then answer size is: 3
    Then verify answer set is equivalent for query
      """
      match
        $Y isa person, has name $name;
        {$name == 'aaa';} or {$name == 'aab';} or {$name == 'aaaa';};
      select $Y, $name;
      """

    Given get answers of typeql read query
      """
      match $X, $Y in ancestor_pairs();
      """
    Then answer size is: 10
    Then verify answer set is equivalent for query
      """
      match
        $Y isa person, has name $nameY;
        $X isa person, has name $nameX;
        {$nameX == 'a';$nameY == 'aa';} or {$nameX == 'a';$nameY == 'ab';} or
        {$nameX == 'a';$nameY == 'aaa';} or {$nameX == 'a';$nameY == 'aab';} or
        {$nameX == 'a';$nameY == 'aaaa';} or {$nameX == 'aa';$nameY == 'aaa';} or
        {$nameX == 'aa';$nameY == 'aab';} or {$nameX == 'aa';$nameY == 'aaaa';} or
        {$nameX == 'aaa';$nameY == 'aaaa';} or {$nameX == 'c';$nameY == 'ca';};
      select $X, $Y;
      """
    Given transaction closes


  Scenario: ancestor-friend test

  from Vieille - Recursive Axioms in Deductive Databases (QSQ approach) p. 186

    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define

       entity person,
          owns name,
          plays parentship:parent,
          plays parentship:child;

      relation parentship, relates parent, relates child;

      attribute name, value string;

      fun ancestor_friendship_pairs() -> { person, person }:
      match
        $x isa person; $y isa person;
        {
         (friend: $x, friend: $y) isa friendship;
         not { $x is $y; }; # TODO: 3.0 does not de-duplicate links yet
          } or
        {
          (parent: $x1, child: $z) isa parentship;
          $z, $y1 in ancestor_friendship_pairs();
          $y is $y1; $x is $x1;
        };
        return { $x, $y };

      fun ancestor_friendship_directed($y: person) -> { person }:
      match
        $x isa person; $y isa person;
        {
         (friend: $x, friend: $y) isa friendship;
         $x has name $xn; $y has name $yn; $xn != $yn; # TODO: 3.0 does not de-duplicate symmetric links yet
          } or
        {
          (parent: $x, child: $z) isa parentship;
          $z in ancestor_friendship_directed($y);
        };
        return { $x };
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
    """
      insert

      $a isa person, has name "a";
      $b isa person, has name "b";
      $c isa person, has name "c";
      $d isa person, has name "d";
      $g isa person, has name "g";

      (parent: $a, child: $b) isa parentship;
      (parent: $b, child: $c) isa parentship;
      (friend: $a, friend: $g) isa friendship;
      (friend: $c, friend: $d) isa friendship;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match
        $X, $Y in ancestor_friendship_pairs();
        $X has name 'a';
        $Y has name $name;
      select $Y;
      """
    Then answer size is: 2
    Then verify answer set is equivalent for query
      """
      match
        $Y has name $name;
        {$name == 'd';} or {$name == 'g';};
      select $Y;
      """

    Given get answers of typeql read query
      """
      match
        $X, $Y in ancestor_friendship_pairs();
        $Y has name 'd';
      select $X;
      """
    Then answer size is: 3
    Then verify answer set is equivalent for query
      """
      match
        $X has name $name;
        {$name == 'a';} or {$name == 'b';} or {$name == 'c';};
      select $X;
      """
    Given get answers of typeql read query
      """
      match
        $X in ancestor_friendship_directed($Y);
        $Y has name 'd';
      select $X;
      """
    Then answer size is: 3
    Then verify answer set is equivalent for query
      """
      match
        $X has name $name;
        {$name == 'a';} or {$name == 'b';} or {$name == 'c';};
      select $X;
      """


  Scenario: same-generation test

  from Vieille - Recursive Query Processing: The power of logic p. 25
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define

      entity entity2, owns name;
      entity Human sub entity2;

      relation parentship, relates parent, relates child;
      entity2 plays parentship:parent, plays parentship:child;

      attribute name, value string;

      fun same_gen_pairs() -> { entity2, entity2 }:
      match
      $x isa entity2; $y isa entity2;
      {
        $x isa Human; $y is $x;
      } or {
        (parent: $x1, child: $u) isa parentship;
        (parent: $y1, child: $v) isa parentship;
        $u, $v in same_gen_pairs();
        $x is $x1; $y is $y1;
      };
      return { $x, $y };

     fun same_gen_directed($x: entity2) -> { entity2 }:
      match
      $x isa entity2; $y isa entity2;
      {
        # $x is $y; # is unimplemented when $x is input. So we workaround with names
        $x has name $name; $y has name $name;
      } or {
        (parent: $x, child: $u) isa parentship;
        (parent: $y1, child: $v) isa parentship;
        $u in same_gen_directed($v);
        $y is $y1;
      };
      return { $y };
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
    """
      insert

      $a isa entity2, has name "a";
      $b isa entity2, has name "b";
      $c isa entity2, has name "c";
      $d isa Human, has name "d";
      $e isa entity2, has name "e";
      $f isa entity2, has name "f";
      $g isa entity2, has name "g";
      $h isa entity2, has name "h";

      (parent: $a, child: $b) isa parentship;
      (parent: $a, child: $c) isa parentship;
      (parent: $b, child: $d) isa parentship;
      (parent: $c, child: $d) isa parentship;
      (parent: $e, child: $d) isa parentship;
      (parent: $f, child: $e) isa parentship;

      #Extra data
      (parent: $g, child: $f) isa parentship;
      (parent: $h, child: $g) isa parentship;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match
        $x, $y in same_gen_pairs();
        $x has name 'a';
      select $y;
      """
    Then answer size is: 2
    Then verify answer set is equivalent for query
      """
      match
        $y has name $name;
        {$name == 'f';} or {$name == 'a';};
      select $y;
      """
    Given get answers of typeql read query
      """
      match
        $x has name 'a';
        $y in same_gen_directed($x);
      select $y;
      """
    Then answer size is: 2
    Then verify answer set is equivalent for query
      """
      match
        $y has name $name;
        {$name == 'f';} or {$name == 'a';};
      select $y;
      """

  Scenario: TC test

  from Vieille - Recursive Query Processing: The power of logic p. 18
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define

       entity entity2,
          owns index,
          plays P:roleA,
          plays P:roleB;
      entity q sub entity2;

      relation P, relates roleA, relates roleB;

      attribute index, value string;

      fun ntc_pairs() -> { entity2, entity2 } :
      match
        $x isa q;
        $x, $y in tc_pairs();
      return { $x, $y };

      fun tc_pairs() -> { entity2, entity2 } :
      match
        $x isa entity2; $y isa entity2;
        { (roleA: $x, roleB: $y) isa P; } or
        {
          (roleA: $x, roleB: $z) isa P;
          $z, $y1 in tc_pairs();
          $y is $y1;
        };
      return { $x, $y };

      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
    """
      insert

      $a isa entity2, has index "a";
      $a1 isa entity2, has index "a1";
      $a2 isa q, has index "a2";

      (roleA: $a1, roleB: $a) isa P;
      (roleA: $a2, roleB: $a1) isa P;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
    """
      match
        $x, $y in ntc_pairs();
        $y has index 'a';
      select $x;
      """
    Then answer size is: 1
    Then verify answer set is equivalent for query
      """
      match $x has index 'a2';
      """


  Scenario: given a directed graph, all pairs of vertices (x,y) such that y is reachable from x can be found

  test 5.2 from Green - Datalog and Recursive Query Processing

  It defines a node configuration:

  /^\
  aa -> bb -> cc -> dd

  and finds all pairs (from, to) such that 'to' is reachable from 'from'.
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define

       entity indexable, owns index;

      entity traversable sub indexable,
          plays pair:from,
          plays pair:to;

      entity vertex sub traversable;
      entity node sub traversable;

      relation pair, relates from, relates to;
      relation link sub pair;
      relation indirect-link sub pair;
      relation reachable sub pair;
      relation unreachable sub pair;

      attribute index, value string;

    # --- pairs ---

      fun reachable_pairs() -> {traversable, traversable}:
      match
        $x isa traversable; $y isa traversable;
        { (from: $x, to: $y) isa link; } or
        {
          (from: $x, to: $z) isa link;
          $z, $y1 in reachable_pairs();
          $y1 is $y;
        };
      return {$x, $y};

      fun indirect_link_pairs() -> { traversable, traversable }:
        match
          $x, $y in reachable_pairs();
          not {(from: $x, to: $y) isa link;};
        return { $x, $y };

      fun unreachable_pairs() -> {traversable, traversable}:
        match
          $x isa vertex;
          $y isa vertex;
          not {
            $x1, $y1 in reachable_pairs();
             $x is $x1; $y is $y1;
          };
        return { $x, $y };

      # --- directed ---
      fun reachable_from($x: traversable) -> {traversable}:
      match
        $x isa traversable; $y isa traversable;
        { (from: $x, to: $y) isa link; } or
        {
          (from: $x, to: $z) isa link;
          $y1 in reachable_from($z);
          $y1 is $y;
        };
      return { $y };

      fun indirect_link_from($x: traversable) -> { traversable }:
        match
          $y in reachable_from($x);
          not {(from: $x, to: $y) isa link;};
        return { $y };

      fun unreachable_from($x: traversable) -> {traversable}:
        match
          $x isa vertex;
          $y isa vertex;
          not {
            $y1 in reachable_from($x);
            $y is $y1;
          };
        return { $y };
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
    """
      insert

      $aa isa node, has index "aa";
      $bb isa node, has index "bb";
      $cc isa node, has index "cc";
      $dd isa node, has index "dd";

      (from: $aa, to: $bb) isa link;
      (from: $bb, to: $cc) isa link;
      (from: $cc, to: $cc) isa link;
      (from: $cc, to: $dd) isa link;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match $x, $y in reachable_pairs();
      """
    Then answer size is: 7
    Then verify answer set is equivalent for query
      """
      match
        $x has index $indX;
        $y has index $indY;
        {$indX == 'aa';$indY == 'bb';} or
        {$indX == 'bb';$indY == 'cc';} or
        {$indX == 'cc';$indY == 'cc';} or
        {$indX == 'cc';$indY == 'dd';} or
        {$indX == 'aa';$indY == 'cc';} or
        {$indX == 'bb';$indY == 'dd';} or
        {$indX == 'aa';$indY == 'dd';};
      select $x, $y;
      """
    Given get answers of typeql read query
        """
        match
        $x isa traversable;
        $y in reachable_from($x);
        """
    Then answer size is: 7
    Then verify answer set is equivalent for query
      """
      match
        $x has index $indX;
        $y has index $indY;
        {$indX == 'aa';$indY == 'bb';} or
        {$indX == 'bb';$indY == 'cc';} or
        {$indX == 'cc';$indY == 'cc';} or
        {$indX == 'cc';$indY == 'dd';} or
        {$indX == 'aa';$indY == 'cc';} or
        {$indX == 'bb';$indY == 'dd';} or
        {$indX == 'aa';$indY == 'dd';};
      select $x, $y;
      """

  Scenario: given an undirected graph, all vertices connected to a given vertex can be found

  For this test, the graph looks like the following:

  /^\
  a -- b -- c -- d

  We find the set of vertices connected to 'a', which is in fact all of the vertices, including 'a' itself.
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define

      entity vertex,
        owns index @key,
        plays link:coordinate;

      relation link, relates coordinate @card(1..2);
      attribute index, value string;

      # --- pairs ---
      fun reachable_pairs() -> { vertex, vertex }:
      match
        $x isa vertex; $y isa vertex;
        { ($x, $y) isa link; } or
        {
          ($x, $z) isa link;
          $z, $y1 in reachable_pairs();
          $y is $y1;
        };
      return { $x, $y };

      # --- from ---
      fun reachable_from($x: vertex) -> { vertex }:
      match
        $x isa vertex; $y isa vertex;
        { ($x, $y) isa link; } or
        {
          ($x, $z) isa link;
          $y1 in reachable_from($z);
          $y is $y1;
        };
      return { $y };


      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
    """
      insert

      $a isa vertex, has index "a";
      $b isa vertex, has index "b";
      $c isa vertex, has index "c";
      $d isa vertex, has index "d";

      (coordinate: $a, coordinate: $b) isa link;
      (coordinate: $b, coordinate: $c) isa link;
      (coordinate: $c, coordinate: $c) isa link;
      (coordinate: $c, coordinate: $d) isa link;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match
        $x, $y in reachable_pairs();
        $x has index 'a';
      select $y;
      """
    Then answer size is: 4
    Then verify answer set is equivalent for query
      """
      match
        $y has index $indY;
        {$indY == 'a';} or {$indY == 'b';} or {$indY == 'c';} or {$indY == 'd';};
      select $y;
      """

    Given get answers of typeql read query
      """
      match
        $y in reachable_from($x);
        $x has index 'a';
      select $y;
      """
    Then answer size is: 4
    Then verify answer set is equivalent for query
      """
      match
        $y has index $indY;
        {$indY == 'a';} or {$indY == 'b';} or {$indY == 'c';} or {$indY == 'd';};
      select $y;
      """


  # TODO: re-enable all steps when resolvable (currently takes too long) (#75)
  Scenario: same-generation - Cao test

  test 6.6 from Cao p.76

    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define

      entity person,owns name;

      relation parentship, relates parent, relates child;
      person plays parentship:parent, plays parentship:child;

      relation Sibling, relates A, relates B;
      person plays Sibling:A, plays Sibling:B;

      relation SameGen, relates A, relates B;
      person plays SameGen:A, plays SameGen:B;

      attribute name, value string;

      # --- pairs ---
      fun same_gen_pairs() -> { person, person }:
      match
        $x isa person; $y isa person;
        { $x1, $y1 in sibling_pairs(); $x1 is $x; $y1 is $y; } or
        {
          (parent: $x, child: $u) isa parentship;
          $u, $v in same_gen_pairs();
          (parent: $y, child: $v) isa parentship;
        };
      return { $x, $y };

      fun sibling_pairs() -> { person, person }:
      match
        $x isa person; $y isa person;
        { (A: $x, B: $y) isa Sibling; } or
        {
          (parent: $z, child: $x) isa parentship;
          (parent: $z, child: $y) isa parentship;
        };
      return {$x, $y};

      # --- directed ---
      fun same_gen_directed($x: person) -> { person }:
      match
        $x isa person; $y isa person;
        { $y1 in sibling_directed($x); $y is $y1; } or
        {
          (parent: $x, child: $u) isa parentship;
          $v in same_gen_directed($u);
          (parent: $y, child: $v) isa parentship;
        };
      return { $y };

      fun sibling_directed($x: person) -> { person }:
      match
        $x isa person; $y isa person;
        { (A: $x, B: $y) isa Sibling; } or
        {
          (parent: $z, child: $x) isa parentship;
          (parent: $z, child: $y) isa parentship;
        };
      return { $y };
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given get answers of typeql write query
    """
      insert

      $ann isa person, has name "ann";
      $bill isa person, has name "bill";
      $john isa person, has name "john";
      $peter isa person, has name "peter";

      (parent: $john, child: $ann) isa parentship;
      (parent: $john, child: $peter) isa parentship;
      (parent: $john, child: $bill) isa parentship;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match
        $x has name 'ann'; $y isa person;
        $x, $y in same_gen_pairs();
      select $y;
      """
    Then answer size is: 3
    Then verify answer set is equivalent for query
      """
      match
        $y has name $name;
        {$name == 'ann';} or {$name == 'bill';} or {$name == 'peter';};
      select $y;
      """
    Given get answers of typeql read query
      """
      match
        $x has name 'ann'; $y isa person;
        $y in same_gen_directed($x);
      select $y;
      """
    Then answer size is: 3
    Then verify answer set is equivalent for query
      """
      match
        $y has name $name;
        {$name == 'ann';} or {$name == 'bill';} or {$name == 'peter';};
      select $y;
      """


  Scenario: reverse same-generation test

  from Abiteboul - Foundations of databases p. 312/Cao test 6.14 p. 89

    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define

      entity person,
        owns name,
        plays parentship:parent,
        plays parentship:child,
        plays up:from,
        plays up:to,
        plays down:from,
        plays down:to,
        plays flat:from,
        plays flat:to;

      relation parentship, relates parent, relates child;

      relation up, relates from, relates to;

      relation down, relates from, relates to;

      relation flat, relates to, relates from;

      attribute name, value string;

      fun rev_sg_pairs() -> { person, person }:
      match
      $x isa person; $y isa person;
      { (from: $x, to: $y) isa flat; } or
      {
        (from: $x, to: $x1) isa up;
        $y1, $x1 in rev_sg_pairs();
        (from: $y1, to: $y) isa down;
      };
      return {$x, $y};


      fun rev_sg_directed_from_bound($x: person) -> { person }:
      match
      $x isa person; $y isa person;
      { (from: $x, to: $y) isa flat; } or
      {
        (from: $x, to: $x1) isa up;
        $y1 in rev_sg_directed_to_bound($x1);
        (from: $y1, to: $y) isa down;
      };
      return {$y};


      fun rev_sg_directed_to_bound($y: person) -> { person }:
      match
      $x isa person; $y isa person;
      { (from: $x, to: $y) isa flat; } or
      {
        (from: $x, to: $x1) isa up;
        $x1 in rev_sg_directed_from_bound($y1);
        (from: $y1, to: $y) isa down;
      };
      return {$x};
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
    """
      insert

      $a isa person, has name "a";
      $b isa person, has name "b";
      $c isa person, has name "c";
      $d isa person, has name "d";
      $e isa person, has name "e";
      $f isa person, has name "f";
      $g isa person, has name "g";
      $h isa person, has name "h";
      $i isa person, has name "i";
      $j isa person, has name "j";
      $k isa person, has name "k";
      $l isa person, has name "l";
      $m isa person, has name "m";
      $n isa person, has name "n";
      $o isa person, has name "o";
      $p isa person, has name "p";

      (from: $a, to: $e) isa up;
      (from: $a, to: $f) isa up;
      (from: $f, to: $m) isa up;
      (from: $g, to: $n) isa up;
      (from: $h, to: $n) isa up;
      (from: $i, to: $o) isa up;
      (from: $j, to: $o) isa up;

      (from: $g, to: $f) isa flat;
      (from: $m, to: $n) isa flat;
      (from: $m, to: $o) isa flat;
      (from: $p, to: $m) isa flat;

      (from: $l, to: $f) isa down;
      (from: $m, to: $f) isa down;
      (from: $g, to: $b) isa down;
      (from: $h, to: $c) isa down;
      (from: $i, to: $d) isa down;
      (from: $p, to: $k) isa down;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match
        $x, $y in rev_sg_pairs();
        $x has name 'a';
      select $y;
      """
    Then answer size is: 3
    Then verify answer set is equivalent for query
      """
      match
        $y isa person, has name $name;
        {$name == 'b';} or {$name == 'c';} or {$name == 'd';};
      select $y;
      """
    Given get answers of typeql read query
      """
      match $x, $y in rev_sg_pairs();
      """
    Then answer size is: 11
    Then verify answer set is equivalent for query
      """
      match
        $x has name $nameX;
        $y has name $nameY;
        {$nameX == 'a';$nameY == 'b';} or {$nameX == 'a';$nameY == 'c';} or
        {$nameX == 'a';$nameY == 'd';} or {$nameX == 'm';$nameY == 'n';} or
        {$nameX == 'm';$nameY == 'o';} or {$nameX == 'p';$nameY == 'm';} or
        {$nameX == 'g';$nameY == 'f';} or {$nameX == 'h';$nameY == 'f';} or
        {$nameX == 'i';$nameY == 'f';} or {$nameX == 'j';$nameY == 'f';} or
        {$nameX == 'f';$nameY == 'k';};
      select $x, $y;
      """

    Given get answers of typeql read query
      """
      match
        $y in rev_sg_directed_from_bound($x);
        $x has name 'a';
      select $y;
      """
    Then answer size is: 3
    Then verify answer set is equivalent for query
      """
      match
        $y isa person, has name $name;
        {$name == 'b';} or {$name == 'c';} or {$name == 'd';};
      select $y;
      """
    Given get answers of typeql read query
      """
      match
      $x isa person;
      $y in rev_sg_directed_from_bound($x);
      """
    Then answer size is: 11
    Then verify answer set is equivalent for query
      """
      match
        $x has name $nameX;
        $y has name $nameY;
        {$nameX == 'a';$nameY == 'b';} or {$nameX == 'a';$nameY == 'c';} or
        {$nameX == 'a';$nameY == 'd';} or {$nameX == 'm';$nameY == 'n';} or
        {$nameX == 'm';$nameY == 'o';} or {$nameX == 'p';$nameY == 'm';} or
        {$nameX == 'g';$nameY == 'f';} or {$nameX == 'h';$nameY == 'f';} or
        {$nameX == 'i';$nameY == 'f';} or {$nameX == 'j';$nameY == 'f';} or
        {$nameX == 'f';$nameY == 'k';};
      select $x, $y;
      """
    Given get answers of typeql read query
      """
      match
      $y isa person;
      $x in rev_sg_directed_to_bound($y);
      """
    Then answer size is: 11
    Then verify answer set is equivalent for query
      """
      match
        $x has name $nameX;
        $y has name $nameY;
        {$nameX == 'a';$nameY == 'b';} or {$nameX == 'a';$nameY == 'c';} or
        {$nameX == 'a';$nameY == 'd';} or {$nameX == 'm';$nameY == 'n';} or
        {$nameX == 'm';$nameY == 'o';} or {$nameX == 'p';$nameY == 'm';} or
        {$nameX == 'g';$nameY == 'f';} or {$nameX == 'h';$nameY == 'f';} or
        {$nameX == 'i';$nameY == 'f';} or {$nameX == 'j';$nameY == 'f';} or
        {$nameX == 'f';$nameY == 'k';};
      select $x, $y;
      """


  Scenario: dual linear transitivity matrix test

  test 6.1 from Cao - Methods for evaluating queries to Horn knowledge bases in first-order logic, p. 71

  Tests an 'n' x 'm' linear transitivity matrix (in this scenario, n = m = 5)

    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define

      entity entity2,
        owns index @key,
        plays P:from, plays P:to,
        plays R1:from, plays R1:to,
        plays R2:from, plays R2:to;

      entity start sub entity2;
      entity end sub entity2;
      entity a-entity sub entity2;
      entity b-entity sub entity2;

      relation R1, relates from, relates to;
      relation R2, relates from, relates to;
      relation P, relates from, relates to;
      attribute index, value string;

      # --- pairs ---

      fun q1_pairs() -> { entity2, entity2 }:
        match
         $x isa entity2; $y isa entity2;
         { (from: $x, to: $y) isa R1; } or
         {
            (from: $x, to: $z) isa R1;
            $z, $y1 in q1_pairs();
            $y is $y1;
         };
        return { $x, $y };

      fun q2_pairs() -> { entity2, entity2 }:
      match
        $x isa entity2; $y isa entity2;
        { (from: $x, to: $y) isa R2; }
        or {
            (from: $x, to: $z) isa R2;
            $z, $y1 in q2_pairs();
            $y is $y1;
        };
        return { $x, $y };

      fun p_pairs() -> { entity2, entity2 }:
      match
        $x, $y in q1_pairs();
      return { $x, $y };

      # --- directed ---

      fun q1_directed($x: entity2) -> { entity2 }:
        match
         $x isa entity2; $y isa entity2;
         { (from: $x, to: $y) isa R1; } or
         {
            (from: $x, to: $z) isa R1;
            $y1 in q1_directed($z);
            $y is $y1;
         };
        return { $y };

      fun q2_directed($x: entity2) -> { entity2 }:
      match
        $x isa entity2; $y isa entity2;
        { (from: $x, to: $y) isa R2; }
        or {
            (from: $x, to: $z) isa R2;
            $y1 in q2_directed($z);
            $y is $y1;
        };
        return { $y };

      fun p_directed($x: entity2) -> { entity2 }:
      match
        $y in q1_directed($x);
      return { $y };
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given get answers of typeql write query
    # These insert statements can be procedurally generated based on 'm' and 'n', the width and height of the matrix
    """
      insert


      $c isa entity2, has index "c";
      $d isa entity2, has index "d";
      $e isa entity2, has index "e";


      $a0 isa start, has index "a0"; # a{0}
      $a5 isa end, has index "a5"; # a{m}


      # $a{i} isa a-entity, has index "a{i}"; for 1 <= i < m
      $a1 isa a-entity, has index "a1";
      $a2 isa a-entity, has index "a2";
      $a3 isa a-entity, has index "a3";
      $a4 isa a-entity, has index "a4";


      # b{ij} isa b-entity, has index "b{ij}"; for 1 <= i < m; for 1 <= j <= n
      $b11 isa b-entity, has index "b11";
      $b12 isa b-entity, has index "b12";
      $b13 isa b-entity, has index "b13";
      $b14 isa b-entity, has index "b14";
      $b15 isa b-entity, has index "b15";

      $b21 isa b-entity, has index "b21";
      $b22 isa b-entity, has index "b22";
      $b23 isa b-entity, has index "b23";
      $b24 isa b-entity, has index "b24";
      $b25 isa b-entity, has index "b25";

      $b31 isa b-entity, has index "b31";
      $b32 isa b-entity, has index "b32";
      $b33 isa b-entity, has index "b33";
      $b34 isa b-entity, has index "b34";
      $b35 isa b-entity, has index "b35";

      $b41 isa b-entity, has index "b41";
      $b42 isa b-entity, has index "b42";
      $b43 isa b-entity, has index "b43";
      $b44 isa b-entity, has index "b44";
      $b45 isa b-entity, has index "b45";


      # (from: $a{i}, to: $a{i+1} isa R1; for 0 <= i < m
      (from: $a0, to: $a1) isa R1;
      (from: $a1, to: $a2) isa R1;
      (from: $a2, to: $a3) isa R1;
      (from: $a3, to: $a4) isa R1;
      (from: $a4, to: $a5) isa R1;


      # (from: $a0, to: $b1{j}) isa R2; for 1 <= j <= n
      # (from: $b{m-1}{j}, to: $a{m}) isa R2; for 1 <= j <= n
      # (from: $b{i}{j}, to: $b{i+1}{j}) isa R2; for 1 <= j <= n; for 1 <= i < m - 1
      (from: $a0, to: $b11) isa R2;
      (from: $b41, to: $a5) isa R2;
      (from: $b11, to: $b21) isa R2;
      (from: $b21, to: $b31) isa R2;
      (from: $b31, to: $b41) isa R2;

      (from: $a0, to: $b12) isa R2;
      (from: $b42, to: $a5) isa R2;
      (from: $b12, to: $b22) isa R2;
      (from: $b22, to: $b32) isa R2;
      (from: $b32, to: $b42) isa R2;

      (from: $a0, to: $b13) isa R2;
      (from: $b43, to: $a5) isa R2;
      (from: $b13, to: $b23) isa R2;
      (from: $b23, to: $b33) isa R2;
      (from: $b33, to: $b43) isa R2;

      (from: $a0, to: $b14) isa R2;
      (from: $b44, to: $a5) isa R2;
      (from: $b14, to: $b24) isa R2;
      (from: $b24, to: $b34) isa R2;
      (from: $b34, to: $b44) isa R2;

      (from: $a0, to: $b15) isa R2;
      (from: $b45, to: $a5) isa R2;
      (from: $b15, to: $b25) isa R2;
      (from: $b25, to: $b35) isa R2;
      (from: $b35, to: $b45) isa R2;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match
        $x, $y in q1_pairs();
        $x has index 'a0';
      select $y;
      """
    Then answer size is: 5

    Then verify answer set is equivalent for query
      """
      match $y isa $t; { $t type a-entity; } or { $t type end; }; select $y;
      """
    Given get answers of typeql read query
      """
      match
        $y in q1_directed($x);
        $x has index 'a0';
      select $y;
      """
    Then answer size is: 5

    Then verify answer set is equivalent for query
      """
      match $y isa $t; { $t type a-entity; } or { $t type end; }; select $y;
      """

  Scenario: tail recursion test

  test 6.3 from Cao - Methods for evaluating queries to Horn knowledge bases in first-order logic, p 75
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define

      entity entity2,
        owns index @key,
        plays Q:from,
        plays Q:to;

      entity a-entity sub entity2;
      entity b-entity sub entity2;

      relation Q, relates from, relates to;

      attribute index, value string;

     fun identity($x: entity2) -> { entity2 }:
      match $x isa entity2; # no-op purely for binding
      return { $x };

      fun p_pairs() -> {entity2, entity2}:
      match
        $x in identity($x1);
        $y in identity($y1);
        { (from: $x1, to: $y1) isa Q; } or
        {
          (from: $x1, to: $z1) isa Q;
          $z1, $y1 in p_pairs();
        };
      return { $x, $y };

      fun p_directed($x: entity2) -> {entity2}:
      match
        $y in identity($y1);
        { (from: $x, to: $y1) isa Q; } or
        {
          (from: $x, to: $z) isa Q;
          $y1 in p_directed($z);
        };
      return { $y };
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
    """
      insert


      $a0 isa a-entity, has index "a0";


      # $b{i}_{j} isa b-entity, has index "b{i}_{j}"; for 1 <= i <= m + 1; for 1 <= j <= n
      $b1_1 isa b-entity, has index "b1_1";
      $b1_2 isa b-entity, has index "b1_2";
      $b1_3 isa b-entity, has index "b1_3";
      $b1_4 isa b-entity, has index "b1_4";
      $b1_5 isa b-entity, has index "b1_5";
      $b1_6 isa b-entity, has index "b1_6";
      $b1_7 isa b-entity, has index "b1_7";
      $b1_8 isa b-entity, has index "b1_8";
      $b1_9 isa b-entity, has index "b1_9";
      $b1_10 isa b-entity, has index "b1_10";

      $b2_1 isa b-entity, has index "b2_1";
      $b2_2 isa b-entity, has index "b2_2";
      $b2_3 isa b-entity, has index "b2_3";
      $b2_4 isa b-entity, has index "b2_4";
      $b2_5 isa b-entity, has index "b2_5";
      $b2_6 isa b-entity, has index "b2_6";
      $b2_7 isa b-entity, has index "b2_7";
      $b2_8 isa b-entity, has index "b2_8";
      $b2_9 isa b-entity, has index "b2_9";
      $b2_10 isa b-entity, has index "b2_10";

      $b3_1 isa b-entity, has index "b3_1";
      $b3_2 isa b-entity, has index "b3_2";
      $b3_3 isa b-entity, has index "b3_3";
      $b3_4 isa b-entity, has index "b3_4";
      $b3_5 isa b-entity, has index "b3_5";
      $b3_6 isa b-entity, has index "b3_6";
      $b3_7 isa b-entity, has index "b3_7";
      $b3_8 isa b-entity, has index "b3_8";
      $b3_9 isa b-entity, has index "b3_9";
      $b3_10 isa b-entity, has index "b3_10";

      $b4_1 isa b-entity, has index "b4_1";
      $b4_2 isa b-entity, has index "b4_2";
      $b4_3 isa b-entity, has index "b4_3";
      $b4_4 isa b-entity, has index "b4_4";
      $b4_5 isa b-entity, has index "b4_5";
      $b4_6 isa b-entity, has index "b4_6";
      $b4_7 isa b-entity, has index "b4_7";
      $b4_8 isa b-entity, has index "b4_8";
      $b4_9 isa b-entity, has index "b4_9";
      $b4_10 isa b-entity, has index "b4_10";

      $b5_1 isa b-entity, has index "b5_1";
      $b5_2 isa b-entity, has index "b5_2";
      $b5_3 isa b-entity, has index "b5_3";
      $b5_4 isa b-entity, has index "b5_4";
      $b5_5 isa b-entity, has index "b5_5";
      $b5_6 isa b-entity, has index "b5_6";
      $b5_7 isa b-entity, has index "b5_7";
      $b5_8 isa b-entity, has index "b5_8";
      $b5_9 isa b-entity, has index "b5_9";
      $b5_10 isa b-entity, has index "b5_10";

      $b6_1 isa b-entity, has index "b6_1";
      $b6_2 isa b-entity, has index "b6_2";
      $b6_3 isa b-entity, has index "b6_3";
      $b6_4 isa b-entity, has index "b6_4";
      $b6_5 isa b-entity, has index "b6_5";
      $b6_6 isa b-entity, has index "b6_6";
      $b6_7 isa b-entity, has index "b6_7";
      $b6_8 isa b-entity, has index "b6_8";
      $b6_9 isa b-entity, has index "b6_9";
      $b6_10 isa b-entity, has index "b6_10";


      # (from: $a0, to: $b1_{j}) isa Q; for 1 <= j <= n
      (from: $a0, to: $b1_1) isa Q;
      (from: $a0, to: $b1_2) isa Q;
      (from: $a0, to: $b1_3) isa Q;
      (from: $a0, to: $b1_4) isa Q;
      (from: $a0, to: $b1_5) isa Q;
      (from: $a0, to: $b1_6) isa Q;
      (from: $a0, to: $b1_7) isa Q;
      (from: $a0, to: $b1_8) isa Q;
      (from: $a0, to: $b1_9) isa Q;
      (from: $a0, to: $b1_10) isa Q;


      # (from: $b{i}_{j}, to: $b{i+1}_{j}) isa Q; for 1 <= j <= n; for 1 <= i <= m
      (from: $b1_1, to: $b2_1) isa Q;
      (from: $b2_1, to: $b3_1) isa Q;
      (from: $b3_1, to: $b4_1) isa Q;
      (from: $b4_1, to: $b5_1) isa Q;
      (from: $b5_1, to: $b6_1) isa Q;

      (from: $b1_2, to: $b2_2) isa Q;
      (from: $b2_2, to: $b3_2) isa Q;
      (from: $b3_2, to: $b4_2) isa Q;
      (from: $b4_2, to: $b5_2) isa Q;
      (from: $b5_2, to: $b6_2) isa Q;

      (from: $b1_3, to: $b2_3) isa Q;
      (from: $b2_3, to: $b3_3) isa Q;
      (from: $b3_3, to: $b4_3) isa Q;
      (from: $b4_3, to: $b5_3) isa Q;
      (from: $b5_3, to: $b6_3) isa Q;

      (from: $b1_4, to: $b2_4) isa Q;
      (from: $b2_4, to: $b3_4) isa Q;
      (from: $b3_4, to: $b4_4) isa Q;
      (from: $b4_4, to: $b5_4) isa Q;
      (from: $b5_4, to: $b6_4) isa Q;

      (from: $b1_5, to: $b2_5) isa Q;
      (from: $b2_5, to: $b3_5) isa Q;
      (from: $b3_5, to: $b4_5) isa Q;
      (from: $b4_5, to: $b5_5) isa Q;
      (from: $b5_5, to: $b6_5) isa Q;

      (from: $b1_6, to: $b2_6) isa Q;
      (from: $b2_6, to: $b3_6) isa Q;
      (from: $b3_6, to: $b4_6) isa Q;
      (from: $b4_6, to: $b5_6) isa Q;
      (from: $b5_6, to: $b6_6) isa Q;

      (from: $b1_7, to: $b2_7) isa Q;
      (from: $b2_7, to: $b3_7) isa Q;
      (from: $b3_7, to: $b4_7) isa Q;
      (from: $b4_7, to: $b5_7) isa Q;
      (from: $b5_7, to: $b6_7) isa Q;

      (from: $b1_8, to: $b2_8) isa Q;
      (from: $b2_8, to: $b3_8) isa Q;
      (from: $b3_8, to: $b4_8) isa Q;
      (from: $b4_8, to: $b5_8) isa Q;
      (from: $b5_8, to: $b6_8) isa Q;

      (from: $b1_9, to: $b2_9) isa Q;
      (from: $b2_9, to: $b3_9) isa Q;
      (from: $b3_9, to: $b4_9) isa Q;
      (from: $b4_9, to: $b5_9) isa Q;
      (from: $b5_9, to: $b6_9) isa Q;

      (from: $b1_10, to: $b2_10) isa Q;
      (from: $b2_10, to: $b3_10) isa Q;
      (from: $b3_10, to: $b4_10) isa Q;
      (from: $b4_10, to: $b5_10) isa Q;
      (from: $b5_10, to: $b6_10) isa Q;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match
        $x, $y in p_pairs();
        $x has index 'a0';
      select $y;
      """
    Then answer size is: 60
    Then verify answer set is equivalent for query
      """
      match $y isa b-entity;
      """

    Given get answers of typeql read query
      """
      match
        $y in p_directed($x);
        $x has index 'a0';
      select $y;
      """
    Then answer size is: 60
    Then verify answer set is equivalent for query
      """
      match $y isa b-entity;
      """


  Scenario: linear transitivity matrix test

  test 6.9 from Cao - Methods for evaluating queries to Horn knowledge bases in first-order logic p.82

    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define

      entity entity2, owns index @key;
      entity a-entity sub entity2;

      relation Q, relates from, relates to;
      entity2 plays Q:from, plays Q:to;

      attribute index, value string;

      # --- pairs ---
      fun p_pairs() -> { entity2, entity2 }:
      match
      $x isa entity2; $y isa entity2;
      { (from: $x, to: $y) isa Q; } or
      {
        (from: $x, to: $z) isa Q;
        $z, $y1 in p_pairs();
        $y is $y1;
      };
      return { $x, $y };

      fun s_pairs() -> { entity2, entity2 }:
      match
        $x, $y in p_pairs();
      return { $x, $y };

      # --- directed ---
      fun p_directed($x: entity2) -> {entity2 }:
      match
      $x isa entity2; $y isa entity2;
      { (from: $x, to: $y) isa Q; } or
      {
        (from: $x, to: $z) isa Q;
        $y1 in p_directed($z);
        $y is $y1;
      };
      return { $y };

      fun s_directed($x: entity2) -> { entity2 }:
      match
        $y in p_directed($x);
      return { $y };
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert

      $a isa entity2, has index "a";

      # $a{i}_{j} isa a-entity, has index "a{i}_{j}"; for 1 <= i <= n; for 1 <= j <= m
      $a1_1 isa a-entity, has index "a1_1";
      $a1_2 isa a-entity, has index "a1_2";
      $a1_3 isa a-entity, has index "a1_3";
      $a1_4 isa a-entity, has index "a1_4";
      $a1_5 isa a-entity, has index "a1_5";

      $a2_1 isa a-entity, has index "a2_1";
      $a2_2 isa a-entity, has index "a2_2";
      $a2_3 isa a-entity, has index "a2_3";
      $a2_4 isa a-entity, has index "a2_4";
      $a2_5 isa a-entity, has index "a2_5";

      $a3_1 isa a-entity, has index "a3_1";
      $a3_2 isa a-entity, has index "a3_2";
      $a3_3 isa a-entity, has index "a3_3";
      $a3_4 isa a-entity, has index "a3_4";
      $a3_5 isa a-entity, has index "a3_5";

      $a4_1 isa a-entity, has index "a4_1";
      $a4_2 isa a-entity, has index "a4_2";
      $a4_3 isa a-entity, has index "a4_3";
      $a4_4 isa a-entity, has index "a4_4";
      $a4_5 isa a-entity, has index "a4_5";

      $a5_1 isa a-entity, has index "a5_1";
      $a5_2 isa a-entity, has index "a5_2";
      $a5_3 isa a-entity, has index "a5_3";
      $a5_4 isa a-entity, has index "a5_4";
      $a5_5 isa a-entity, has index "a5_5";

      (from: $a, to: $a1_1) isa Q;

      # (from: $a{i}_{j}, to: $a{i+1}_{j}) isa Q; for 1 <= i < n; for 1 <= j <= m
      (from: $a1_1, to: $a2_1) isa Q;
      (from: $a1_2, to: $a2_2) isa Q;
      (from: $a1_3, to: $a2_3) isa Q;
      (from: $a1_4, to: $a2_4) isa Q;
      (from: $a1_5, to: $a2_5) isa Q;

      (from: $a2_1, to: $a3_1) isa Q;
      (from: $a2_2, to: $a3_2) isa Q;
      (from: $a2_3, to: $a3_3) isa Q;
      (from: $a2_4, to: $a3_4) isa Q;
      (from: $a2_5, to: $a3_5) isa Q;

      (from: $a3_1, to: $a4_1) isa Q;
      (from: $a3_2, to: $a4_2) isa Q;
      (from: $a3_3, to: $a4_3) isa Q;
      (from: $a3_4, to: $a4_4) isa Q;
      (from: $a3_5, to: $a4_5) isa Q;

      (from: $a4_1, to: $a5_1) isa Q;
      (from: $a4_2, to: $a5_2) isa Q;
      (from: $a4_3, to: $a5_3) isa Q;
      (from: $a4_4, to: $a5_4) isa Q;
      (from: $a4_5, to: $a5_5) isa Q;

      # (from: $a{i}_{j}, to: $a{i}_{j+1}) isa Q; for 1 <= i <= n; for 1 <= j < m
      (from: $a1_1, to: $a1_2) isa Q;
      (from: $a1_2, to: $a1_3) isa Q;
      (from: $a1_3, to: $a1_4) isa Q;
      (from: $a1_4, to: $a1_5) isa Q;

      (from: $a2_1, to: $a2_2) isa Q;
      (from: $a2_2, to: $a2_3) isa Q;
      (from: $a2_3, to: $a2_4) isa Q;
      (from: $a2_4, to: $a2_5) isa Q;

      (from: $a3_1, to: $a3_2) isa Q;
      (from: $a3_2, to: $a3_3) isa Q;
      (from: $a3_3, to: $a3_4) isa Q;
      (from: $a3_4, to: $a3_5) isa Q;

      (from: $a4_1, to: $a4_2) isa Q;
      (from: $a4_2, to: $a4_3) isa Q;
      (from: $a4_3, to: $a4_4) isa Q;
      (from: $a4_4, to: $a4_5) isa Q;

      (from: $a5_1, to: $a5_2) isa Q;
      (from: $a5_2, to: $a5_3) isa Q;
      (from: $a5_3, to: $a5_4) isa Q;
      (from: $a5_4, to: $a5_5) isa Q;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match
        $x, $y in p_pairs();
        $x has index 'a';
      select $y;
      """
    Then answer size is: 25
    Then verify answer set is equivalent for query
      """
      match $y isa a-entity;
      """
    Given get answers of typeql read query
      """
      match
        $y in p_directed($x);
        $x has index 'a';
      select $y;
      """
    Then answer size is: 25
    Then verify answer set is equivalent for query
      """
      match $y isa a-entity;
      """
