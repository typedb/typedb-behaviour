# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# TODO: All tests with directed can be changed to a "Verify answer set is equivalent for" test.

#noinspection CucumberUndefinedStep
Feature: Recursive Function Execution

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
        location-hierarchy (subordinate: $x, superior: $y);
        location-hierarchy (subordinate: $y, superior: $z);
      return {$x, $z};

      fun big_location_hierarchy_pairs() -> { place, place }:
      match
        let $x, $y in transitive_location_hierarchy_pairs();
        $x isa big-place;
        $y isa big-place;
      return {$x, $y};


      fun transitive_location_hierarchy_directed($x: place) -> { place }:
      match
        location-hierarchy (subordinate: $x, superior: $y);
        location-hierarchy (subordinate: $y, superior: $z);
      return {$z};

      fun big_location_hierarchy_directed($x: big-place) -> { big-place }:
      match
        let $y in transitive_location_hierarchy_directed($x);
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

      location-hierarchy (subordinate: $x, superior: $y);
      location-hierarchy (subordinate: $y, superior: $z);
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match let $x, $y in big_location_hierarchy_pairs();
      """
    Then answer size is: 1

    Given get answers of typeql read query
      """
      match $x isa big-place; let $y in big_location_hierarchy_directed($x);
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
         { parentship (parent: $x, child: $y); } or
         {
            parentship (parent: $x, child: $z);
            let $z, $y1 in ancestor_pairs();
            $y is $y1;
          };
        return { $x, $y };

      fun ancestors_directed($x: person) -> { person } :
        match
         $y isa person;
         { parentship (parent: $x, child: $y); } or
         {
            parentship (parent: $x, child: $z);
            let $y1 in ancestors_directed($z);
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

      parentship (parent: $a, child: $aa);
      parentship (parent: $a, child: $ab);
      parentship (parent: $aa, child: $aaa);
      parentship (parent: $aa, child: $aab);
      parentship (parent: $aaa, child: $aaaa);
      parentship (parent: $c, child: $ca);
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match
        let $X, $Y in ancestor_pairs();
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
        let $Y in ancestors_directed($X);
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
      match let $X, $Y in ancestor_pairs();
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
         friendship (friend: $x, friend: $y);
         not { $x is $y; }; # TODO: 3.0 does not de-duplicate links yet
          } or
        {
          parentship (parent: $x1, child: $z);
          let $z, $y1 in ancestor_friendship_pairs();
          $y is $y1; $x is $x1;
        };
        return { $x, $y };

      fun ancestor_friendship_directed($y: person) -> { person }:
      match
        $x isa person; $y isa person;
        {
         friendship (friend: $x, friend: $y);
         $x has name $xn; $y has name $yn; $xn != $yn; # TODO: 3.0 does not de-duplicate symmetric links yet
          } or
        {
          parentship (parent: $x, child: $z);
          let $z in ancestor_friendship_directed($y);
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

      parentship (parent: $a, child: $b);
      parentship (parent: $b, child: $c);
      friendship (friend: $a, friend: $g);
      friendship (friend: $c, friend: $d);
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match
        let $X, $Y in ancestor_friendship_pairs();
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
        let $X, $Y in ancestor_friendship_pairs();
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
        let $X in ancestor_friendship_directed($Y);
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
        parentship (parent: $x1, child: $u);
        parentship (parent: $y1, child: $v);
        let $u, $v in same_gen_pairs();
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
        parentship (parent: $x, child: $u);
        parentship (parent: $y1, child: $v);
        let $u in same_gen_directed($v);
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

      parentship (parent: $a, child: $b);
      parentship (parent: $a, child: $c);
      parentship (parent: $b, child: $d);
      parentship (parent: $c, child: $d);
      parentship (parent: $e, child: $d);
      parentship (parent: $f, child: $e);

      #Extra data
      parentship (parent: $g, child: $f);
      parentship (parent: $h, child: $g);
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match
        let $x, $y in same_gen_pairs();
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
        let $y in same_gen_directed($x);
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
        let $x, $y in tc_pairs();
      return { $x, $y };

      fun tc_pairs() -> { entity2, entity2 } :
      match
        $x isa entity2; $y isa entity2;
        { P (roleA: $x, roleB: $y); } or
        {
          P (roleA: $x, roleB: $z);
          let $z, $y1 in tc_pairs();
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

      P (roleA: $a1, roleB: $a);
      P (roleA: $a2, roleB: $a1);
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
    """
      match
        let $x, $y in ntc_pairs();
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
          plays pair:start,
          plays pair:end_;

      entity vertex sub traversable;
      entity node sub traversable;

      relation pair, relates start, relates end_;
      relation link sub pair;
      relation indirect-link sub pair;
      relation reachable sub pair;
      relation unreachable sub pair;

      attribute index, value string;

    # --- pairs ---

      fun reachable_pairs() -> {traversable, traversable}:
      match
        $x isa traversable; $y isa traversable;
        { link (start: $x, end: $y); } or
        {
          link (start: $x, end: $z);
          let $z, $y1 in reachable_pairs();
          $y1 is $y;
        };
      return {$x, $y};

      fun indirect_link_pairs() -> { traversable, traversable }:
        match
          let $x, $y in reachable_pairs();
          not { link (start: $x, end: $y);};
        return { $x, $y };

      fun unreachable_pairs() -> {traversable, traversable}:
        match
          $x isa vertex;
          $y isa vertex;
          not {
            let $x1, $y1 in reachable_pairs();
             $x is $x1; $y is $y1;
          };
        return { $x, $y };

      # --- directed ---
      fun reachable_from($x: traversable) -> {traversable}:
      match
        $x isa traversable; $y isa traversable;
        { link (start: $x, end: $y); } or
        {
          link (start: $x, end: $z);
          let $y1 in reachable_from($z);
          $y1 is $y;
        };
      return { $y };

      fun indirect_link_from($x: traversable) -> { traversable }:
        match
          let $y in reachable_from($x);
          not {link (start: $x, end: $y); };
        return { $y };

      fun unreachable_from($x: traversable) -> {traversable}:
        match
          $x isa vertex;
          $y isa vertex;
          not {
            let $y1 in reachable_from($x);
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

      link (start: $aa, end: $bb);
      link (start: $bb, end: $cc);
      link (start: $cc, end: $cc);
      link (start: $cc, end: $dd);
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match let $x, $y in reachable_pairs();
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
        let $y in reachable_from($x);
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
        { link ($x, $y); } or
        {
          link ($x, $z);
          let $z, $y1 in reachable_pairs();
          $y is $y1;
        };
      return { $x, $y };

      # --- from ---
      fun reachable_from($x: vertex) -> { vertex }:
      match
        $x isa vertex; $y isa vertex;
        { link ($x, $y); } or
        {
          link ($x, $z);
          let $y1 in reachable_from($z);
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

      link (coordinate: $a, coordinate: $b);
      link (coordinate: $b, coordinate: $c);
      link (coordinate: $c, coordinate: $c);
      link (coordinate: $c, coordinate: $d);
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match
        let $x, $y in reachable_pairs();
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
        let $y in reachable_from($x);
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
        { let $x1, $y1 in sibling_pairs(); $x1 is $x; $y1 is $y; } or
        {
          parentship (parent: $x, child: $u);
          let $u, $v in same_gen_pairs();
          parentship (parent: $y, child: $v);
        };
      return { $x, $y };

      fun sibling_pairs() -> { person, person }:
      match
        $x isa person; $y isa person;
        { Sibling (A: $x, B: $y); } or
        {
          parentship (parent: $z, child: $x);
          parentship (parent: $z, child: $y);
        };
      return {$x, $y};

      # --- directed ---
      fun same_gen_directed($x: person) -> { person }:
      match
        $x isa person; $y isa person;
        { let $y1 in sibling_directed($x); $y is $y1; } or
        {
          parentship (parent: $x, child: $u);
          let $v in same_gen_directed($u);
          parentship (parent: $y, child: $v);
        };
      return { $y };

      fun sibling_directed($x: person) -> { person }:
      match
        $x isa person; $y isa person;
        { Sibling (A: $x, B: $y); } or
        {
          parentship (parent: $z, child: $x);
          parentship (parent: $z, child: $y);
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

      parentship (parent: $john, child: $ann);
      parentship (parent: $john, child: $peter);
      parentship (parent: $john, child: $bill);
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match
        $x has name 'ann'; $y isa person;
        let $x, $y in same_gen_pairs();
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
        let $y in same_gen_directed($x);
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
        plays up:start,
        plays up:end_,
        plays down:start,
        plays down:end_,
        plays flat:start,
        plays flat:end_;

      relation parentship, relates parent, relates child;

      relation up, relates start, relates end_;

      relation down, relates start, relates end_;

      relation flat, relates end_, relates start;

      attribute name, value string;

      fun rev_sg_pairs() -> { person, person }:
      match
      $x isa person; $y isa person;
      { flat (start: $x, end: $y); } or
      {
        up (start: $x, end: $x1);
        let $y1, $x1 in rev_sg_pairs();
        down (start: $y1, end: $y);
      };
      return {$x, $y};


      fun rev_sg_directed_from_bound($x: person) -> { person }:
      match
      $x isa person; $y isa person;
      { flat (start: $x, end: $y); } or
      {
        up (start: $x, end: $x1);
        let $y1 in rev_sg_directed_to_bound($x1);
        down (start: $y1, end: $y);
      };
      return {$y};


      fun rev_sg_directed_to_bound($y: person) -> { person }:
      match
      $x isa person; $y isa person;
      { flat (start: $x, end: $y); } or
      {
        up (start: $x, end: $x1);
        let $x1 in rev_sg_directed_from_bound($y1);
        down (start: $y1, end: $y);
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

      up (start: $a, end: $e);
      up (start: $a, end: $f);
      up (start: $f, end: $m);
      up (start: $g, end: $n);
      up (start: $h, end: $n);
      up (start: $i, end: $o);
      up (start: $j, end: $o);

      flat (start: $g, end: $f);
      flat (start: $m, end: $n);
      flat (start: $m, end: $o);
      flat (start: $p, end: $m);

      down (start: $l, end: $f);
      down (start: $m, end: $f);
      down (start: $g, end: $b);
      down (start: $h, end: $c);
      down (start: $i, end: $d);
      down (start: $p, end: $k);
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match
        let $x, $y in rev_sg_pairs();
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
      match let $x, $y in rev_sg_pairs();
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
        let $y in rev_sg_directed_from_bound($x);
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
      let $y in rev_sg_directed_from_bound($x);
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
      let $x in rev_sg_directed_to_bound($y);
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
        plays P:start, plays P:end_,
        plays R1:start, plays R1:end_,
        plays R2:start, plays R2:end_;

      entity start sub entity2;
      entity end_ sub entity2;
      entity a-entity sub entity2;
      entity b-entity sub entity2;

      relation R1, relates start, relates end_;
      relation R2, relates start, relates end_;
      relation P, relates start, relates end_;
      attribute index, value string;

      # --- pairs ---

      fun q1_pairs() -> { entity2, entity2 }:
        match
         $x isa entity2; $y isa entity2;
         { R1 (start: $x, end: $y); } or
         {
            R1 (start: $x, end: $z);
            let $z, $y1 in q1_pairs();
            $y is $y1;
         };
        return { $x, $y };

      fun q2_pairs() -> { entity2, entity2 }:
      match
        $x isa entity2; $y isa entity2;
        { R2 (start: $x, end: $y); }
        or {
            R2 (start: $x, end: $z);
            let $z, $y1 in q2_pairs();
            $y is $y1;
        };
        return { $x, $y };

      fun p_pairs() -> { entity2, entity2 }:
      match
        let $x, $y in q1_pairs();
      return { $x, $y };

      # --- directed ---

      fun q1_directed($x: entity2) -> { entity2 }:
        match
         $x isa entity2; $y isa entity2;
         { R1 (start: $x, end: $y); } or
         {
            R1 (start: $x, end: $z);
            let $y1 in q1_directed($z);
            $y is $y1;
         };
        return { $y };

      fun q2_directed($x: entity2) -> { entity2 }:
      match
        $x isa entity2; $y isa entity2;
        { R2 (start: $x, end: $y); }
        or {
            R2 (start: $x, end: $z);
            let $y1 in q2_directed($z);
            $y is $y1;
        };
        return { $y };

      fun p_directed($x: entity2) -> { entity2 }:
      match
        let $y in q1_directed($x);
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


      # (start: $a{i}, end: $a{i+1} isa R1; for 0 <= i < m
      R1 (start: $a0, end: $a1);
      R1 (start: $a1, end: $a2);
      R1 (start: $a2, end: $a3);
      R1 (start: $a3, end: $a4);
      R1 (start: $a4, end: $a5);


      # (start: $a0, end: $b1{j}) isa R2; for 1 <= j <= n
      # (start: $b{m-1}{j}, end: $a{m}) isa R2; for 1 <= j <= n
      # (start: $b{i}{j}, end: $b{i+1}{j}) isa R2; for 1 <= j <= n; for 1 <= i < m - 1
      R2 (start: $a0, end: $b11);
      R2 (start: $b41, end: $a5);
      R2 (start: $b11, end: $b21);
      R2 (start: $b21, end: $b31);
      R2 (start: $b31, end: $b41);

      R2 (start: $a0, end: $b12);
      R2 (start: $b42, end: $a5);
      R2 (start: $b12, end: $b22);
      R2 (start: $b22, end: $b32);
      R2 (start: $b32, end: $b42);

      R2 (start: $a0, end: $b13);
      R2 (start: $b43, end: $a5);
      R2 (start: $b13, end: $b23);
      R2 (start: $b23, end: $b33);
      R2 (start: $b33, end: $b43);

      R2 (start: $a0, end: $b14);
      R2 (start: $b44, end: $a5);
      R2 (start: $b14, end: $b24);
      R2 (start: $b24, end: $b34);
      R2 (start: $b34, end: $b44);

      R2 (start: $a0, end: $b15);
      R2 (start: $b45, end: $a5);
      R2 (start: $b15, end: $b25);
      R2 (start: $b25, end: $b35);
      R2 (start: $b35, end: $b45);
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match
        let $x, $y in q1_pairs();
        $x has index 'a0';
      select $y;
      """
    Then answer size is: 5

    Then verify answer set is equivalent for query
      """
      match $y isa $t; { $t label a-entity; } or { $t label end_; }; select $y;
      """
    Given get answers of typeql read query
      """
      match
        let $y in q1_directed($x);
        $x has index 'a0';
      select $y;
      """
    Then answer size is: 5

    Then verify answer set is equivalent for query
      """
      match $y isa $t; { $t label a-entity; } or { $t label end_; }; select $y;
      """

  Scenario: tail recursion test

  test 6.3 from Cao - Methods for evaluating queries to Horn knowledge bases in first-order logic, p 75
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define

      entity entity2,
        owns index @key,
        plays Q:start,
        plays Q:end_;

      entity a-entity sub entity2;
      entity b-entity sub entity2;

      relation Q, relates start, relates end_;

      attribute index, value string;

     fun identity($x: entity2) -> { entity2 }:
      match $x isa entity2; # no-op purely for binding
      return { $x };

      fun p_pairs() -> {entity2, entity2}:
      match
        let $x in identity($x1);
        let $y in identity($y1);
        { Q (start: $x1, end: $y1); } or
        {
          Q (start: $x1, end: $z1);
          let $z1, $y1 in p_pairs();
        };
      return { $x, $y };

      fun p_directed($x: entity2) -> {entity2}:
      match
        let $y in identity($y1);
        { Q (start: $x, end: $y1); } or
        {
          Q (start: $x, end: $z);
          let $y1 in p_directed($z);
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


      # (start: $a0, end: $b1_{j}) isa Q; for 1 <= j <= n
      Q (start: $a0, end: $b1_1);
      Q (start: $a0, end: $b1_2);
      Q (start: $a0, end: $b1_3);
      Q (start: $a0, end: $b1_4);
      Q (start: $a0, end: $b1_5);
      Q (start: $a0, end: $b1_6);
      Q (start: $a0, end: $b1_7);
      Q (start: $a0, end: $b1_8);
      Q (start: $a0, end: $b1_9);
      Q (start: $a0, end: $b1_10);


      # (start: $b{i}_{j}, end: $b{i+1}_{j}) isa Q; for 1 <= j <= n; for 1 <= i <= m
      Q (start: $b1_1, end: $b2_1);
      Q (start: $b2_1, end: $b3_1);
      Q (start: $b3_1, end: $b4_1);
      Q (start: $b4_1, end: $b5_1);
      Q (start: $b5_1, end: $b6_1);

      Q (start: $b1_2, end: $b2_2);
      Q (start: $b2_2, end: $b3_2);
      Q (start: $b3_2, end: $b4_2);
      Q (start: $b4_2, end: $b5_2);
      Q (start: $b5_2, end: $b6_2);

      Q (start: $b1_3, end: $b2_3);
      Q (start: $b2_3, end: $b3_3);
      Q (start: $b3_3, end: $b4_3);
      Q (start: $b4_3, end: $b5_3);
      Q (start: $b5_3, end: $b6_3);

      Q (start: $b1_4, end: $b2_4);
      Q (start: $b2_4, end: $b3_4);
      Q (start: $b3_4, end: $b4_4);
      Q (start: $b4_4, end: $b5_4);
      Q (start: $b5_4, end: $b6_4);

      Q (start: $b1_5, end: $b2_5);
      Q (start: $b2_5, end: $b3_5);
      Q (start: $b3_5, end: $b4_5);
      Q (start: $b4_5, end: $b5_5);
      Q (start: $b5_5, end: $b6_5);

      Q (start: $b1_6, end: $b2_6);
      Q (start: $b2_6, end: $b3_6);
      Q (start: $b3_6, end: $b4_6);
      Q (start: $b4_6, end: $b5_6);
      Q (start: $b5_6, end: $b6_6);

      Q (start: $b1_7, end: $b2_7);
      Q (start: $b2_7, end: $b3_7);
      Q (start: $b3_7, end: $b4_7);
      Q (start: $b4_7, end: $b5_7);
      Q (start: $b5_7, end: $b6_7);

      Q (start: $b1_8, end: $b2_8);
      Q (start: $b2_8, end: $b3_8);
      Q (start: $b3_8, end: $b4_8);
      Q (start: $b4_8, end: $b5_8);
      Q (start: $b5_8, end: $b6_8);

      Q (start: $b1_9, end: $b2_9);
      Q (start: $b2_9, end: $b3_9);
      Q (start: $b3_9, end: $b4_9);
      Q (start: $b4_9, end: $b5_9);
      Q (start: $b5_9, end: $b6_9);

      Q (start: $b1_10, end: $b2_10);
      Q (start: $b2_10, end: $b3_10);
      Q (start: $b3_10, end: $b4_10);
      Q (start: $b4_10, end: $b5_10);
      Q (start: $b5_10, end: $b6_10);
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match
        let $x, $y in p_pairs();
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
        let $y in p_directed($x);
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

      relation Q, relates start, relates end_;
      entity2 plays Q:start, plays Q:end_;

      attribute index, value string;

      # --- pairs ---
      fun p_pairs() -> { entity2, entity2 }:
      match
      $x isa entity2; $y isa entity2;
      { Q (start: $x, end: $y); } or
      {
        Q (start: $x, end: $z);
        let $z, $y1 in p_pairs();
        $y is $y1;
      };
      return { $x, $y };

      fun s_pairs() -> { entity2, entity2 }:
      match
        let $x, $y in p_pairs();
      return { $x, $y };

      # --- directed ---
      fun p_directed($x: entity2) -> {entity2 }:
      match
      $x isa entity2; $y isa entity2;
      { Q (start: $x, end: $y); } or
      {
        Q (start: $x, end: $z);
        let $y1 in p_directed($z);
        $y is $y1;
      };
      return { $y };

      fun s_directed($x: entity2) -> { entity2 }:
      match
        let $y in p_directed($x);
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

      Q (start: $a, end: $a1_1);

      # (start: $a{i}_{j}, end: $a{i+1}_{j}) isa Q; for 1 <= i < n; for 1 <= j <= m
      Q (start: $a1_1, end: $a2_1);
      Q (start: $a1_2, end: $a2_2);
      Q (start: $a1_3, end: $a2_3);
      Q (start: $a1_4, end: $a2_4);
      Q (start: $a1_5, end: $a2_5);

      Q (start: $a2_1, end: $a3_1);
      Q (start: $a2_2, end: $a3_2);
      Q (start: $a2_3, end: $a3_3);
      Q (start: $a2_4, end: $a3_4);
      Q (start: $a2_5, end: $a3_5);

      Q (start: $a3_1, end: $a4_1);
      Q (start: $a3_2, end: $a4_2);
      Q (start: $a3_3, end: $a4_3);
      Q (start: $a3_4, end: $a4_4);
      Q (start: $a3_5, end: $a4_5);

      Q (start: $a4_1, end: $a5_1);
      Q (start: $a4_2, end: $a5_2);
      Q (start: $a4_3, end: $a5_3);
      Q (start: $a4_4, end: $a5_4);
      Q (start: $a4_5, end: $a5_5);

      # (start: $a{i}_{j}, end: $a{i}_{j+1}) isa Q; for 1 <= i <= n; for 1 <= j < m
      Q (start: $a1_1, end: $a1_2);
      Q (start: $a1_2, end: $a1_3);
      Q (start: $a1_3, end: $a1_4);
      Q (start: $a1_4, end: $a1_5);

      Q (start: $a2_1, end: $a2_2);
      Q (start: $a2_2, end: $a2_3);
      Q (start: $a2_3, end: $a2_4);
      Q (start: $a2_4, end: $a2_5);

      Q (start: $a3_1, end: $a3_2);
      Q (start: $a3_2, end: $a3_3);
      Q (start: $a3_3, end: $a3_4);
      Q (start: $a3_4, end: $a3_5);

      Q (start: $a4_1, end: $a4_2);
      Q (start: $a4_2, end: $a4_3);
      Q (start: $a4_3, end: $a4_4);
      Q (start: $a4_4, end: $a4_5);

      Q (start: $a5_1, end: $a5_2);
      Q (start: $a5_2, end: $a5_3);
      Q (start: $a5_3, end: $a5_4);
      Q (start: $a5_4, end: $a5_5);
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match
        let $x, $y in p_pairs();
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
        let $y in p_directed($x);
        $x has index 'a';
      select $y;
      """
    Then answer size is: 25
    Then verify answer set is equivalent for query
      """
      match $y isa a-entity;
      """
