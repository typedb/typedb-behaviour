# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Negation Resolution

  Background: Set up database
    Given typedb starts
    Given connection opens with default authentication
    Given reasoning schema
      """
      define

      person sub entity,
        owns name,
        owns age,
        plays friendship:friend,
        plays employment:employee;

      company sub entity,
        owns name,
        plays employment:employer;

      place sub entity,
        owns name,
        plays location-hierarchy:subordinate,
        plays location-hierarchy:superior;

      friendship sub relation,
        relates friend;

      employment sub relation,
        relates employee,
        relates employer;

      location-hierarchy sub relation,
        relates subordinate,
        relates superior;

      name sub attribute, value string;
      age sub attribute, value long;
      """
    # each scenario specialises the schema further

  #####################
  # NEGATION IN MATCH #
  #####################

  # Negation is currently handled by Reasoner, even inside a match clause.

  Scenario: negation can check that an entity does not play a specified role in any relation
    Given reasoning data
    """
      insert
      $x1 isa person;
      $x2 isa person;
      $x3 isa person;
      $x4 isa person;
      $x5 isa person;
      $c isa company, has name "Amazon";
      $e1 (employee: $x1, employer: $c) isa employment;
      $e2 (employee: $x2, employer: $c) isa employment;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x isa person;
      """
    Then verify answer size is: 5
    Given reasoning query
      """
      match
        $x isa person;
        not {
          $e (employee: $x) isa employment;
        };

      """
    Then verify answer size is: 3


  Scenario: negation can check that an entity does not play any role in any relation
    Given reasoning data
      """
      insert
      $x1 isa person;
      $x2 isa person;
      $x3 isa person;
      $x4 isa person;
      $x5 isa person;
      $c isa company, has name "Amazon";
      $e1 (employee: $x1, employer: $c) isa employment;
      $e2 (employee: $x2, employer: $c) isa employment;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x isa person;
      """
    Then verify answer size is: 5
    Given reasoning query
      """
      match
        $x isa person;
        not {
          ($x) isa relation;
        };

      """
    Then verify answer size is: 3


  Scenario: negation can check that an entity does not own any instance of a specific attribute type
    Given reasoning data
      """
      insert
      $x1 isa person, has name "asdf";
      $x2 isa person, has name "cgt";
      $x3 isa person;
      $x4 isa person, has name "bleh";
      $x5 isa person;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x isa person;
      """
    Then verify answer size is: 5
    Given reasoning query
      """
      match
        $x isa person;
        not {
          $x has name $val;
        };

      """
    Then verify answer size is: 2


  Scenario: negation can check that an entity does not own a particular attribute
    Given reasoning data
      """
      insert
      $x1 isa person, has name "Bob";
      $x2 isa person, has name "cgt";
      $x3 isa person;
      $x4 isa person, has name "bleh";
      $x5 isa person;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x isa person;
      """
    Then verify answer size is: 5
    Given reasoning query
      """
      match
        $x isa person;
        not {
          $x has name "Bob";
        };

      """
    Then verify answer size is: 4


  Scenario: negation can check that an entity owns an attribute which is not equal to a specific value
    Given reasoning data
    """
      insert
      $x isa person, has age 10;
      $y isa person, has age 20;
      $z isa person;
      """
    Given verifier is initialised
    Given reasoning query
    """
      match
        $x has age $y;
        not {$y 20;};

      """
    Then verify answer size is: 1
    Then verify answer set is equivalent for query
      """
      match
        $x has age $y;
        $y 10;

      """


  Scenario: negation can check that an entity owns an attribute that is not of a specified type
    Given reasoning data
    """
      insert
      $x isa person, has age 10, has name "Bob";
      $y isa person, has age 20;
      $z isa person;
      $w isa person, has name "Charlie";
      """
    Given verifier is initialised
    Given reasoning query
    """
      match
        $x has attribute $y;
        not {$y isa name;};

      """
    Then verify answer size is: 2
    Then verify answer set is equivalent for query
      """
      match $x has age $y;
      """


  Scenario: negation can filter out an unwanted entity type from part of a chain of matched relations
    Given reasoning schema
      """
      define
      dog sub entity, plays friendship:friend;
      """
    Given reasoning data
      """
      insert
      $a isa person;
      $b isa person;
      $c isa person;
      $d isa person;
      $z isa dog;

      (friend: $a, friend: $b) isa friendship;
      (friend: $b, friend: $c) isa friendship;
      (friend: $c, friend: $d) isa friendship;
      (friend: $d, friend: $z) isa friendship;
      """
    Given verifier is initialised
    Given reasoning query
    """
      match
        (friend: $a, friend: $b) isa friendship;
        (friend: $b, friend: $c) isa friendship;
        (friend: $c, friend: $d) isa friendship;

      """
    # abab, abcb, abcd,
    # baba, babc, bcba, bcbc, bcdc, bcdz,
    # cbab, cbcb, cbcd, cdcb, cdcd, cdzd,
    # dcba, dcbc, dcdc, dcdz, dzdc, dzdz,
    # zdcb, zdcd, zdzd
    Then verify answer size is: 24
    Given reasoning query
      """
      match
        (friend: $a, friend: $b) isa friendship;
        (friend: $b, friend: $c) isa friendship;
        (friend: $c, friend: $d) isa friendship;
        not {$c isa dog;};

      """
    # Eliminates (cdzd, zdzd)
    Then verify answer size is: 22
    Then verify answer set is equivalent for query
      """
      match
        (friend: $a, friend: $b) isa friendship;
        (friend: $b, friend: $c) isa friendship;
        (friend: $c, friend: $d) isa friendship;
        $c isa person;

      """


  Scenario: negation can filter out an unwanted connection between two concepts from a chain of matched relations
    Given reasoning schema
      """
      define
      dog sub entity, owns name, plays friendship:friend;
      """
    Given reasoning data
      """
      insert
      $a isa person, has name "a";
      $b isa person, has name "b";
      $c isa person, has name "c";
      $d isa person, has name "d";
      $z isa dog, has name "z";

      (friend: $a, friend: $b) isa friendship;
      (friend: $b, friend: $c) isa friendship;
      (friend: $c, friend: $d) isa friendship;
      (friend: $d, friend: $z) isa friendship;
      """
    Given verifier is initialised
    Given reasoning query
    """
      match
        (friend: $a, friend: $b) isa friendship;
        (friend: $b, friend: $c) isa friendship;

      """
    # aba, abc
    # bab, bcb, bcd
    # cba, cbc, cdc, cdz
    # dcb, dcd, dzd
    # zdc, zdz
    Then verify answer size is: 14
    Given reasoning query
      """
      match
        (friend: $a, friend: $b) isa friendship;
        not {(friend: $b, friend: $z) isa friendship;};
        (friend: $b, friend: $c) isa friendship;
        $z isa dog;

      """
    # (d,z) is a friendship so we eliminate results where $b is 'd': these are (cdc, cdz, zdc, zdz)
    Then verify answer size is: 10
    Then verify answer set is equivalent for query
      """
      match
        (friend: $a, friend: $b) isa friendship;
        (friend: $b, friend: $c) isa friendship;
        $z isa dog;
        not {$b has name "d";};

      """


  Scenario: negation can filter out an unwanted role from a variable role query
    Given reasoning data
    """
      insert

      $x isa person;
      $c isa company;
      (employee: $x, employer: $c) isa employment;
      """
    Given verifier is initialised
    Given reasoning query
    """
      match ($r1: $x) isa employment;
      """
    # r1       | x   |
    # role     | PER |
    # employee | PER |
    # role     | COM |
    # employer | COM |
    Then verify answer size is: 4
    Given reasoning query
      """
      match
        ($r1: $x) isa employment;
        not {$r1 type relation:role;};

      """
    Then verify answer size is: 2


  Scenario: a negated statement with multiple properties can be re-written as a negation of multiple statements
    Given reasoning data
    """
      insert

      $x isa person, has name "Tim", has age 45;
      $y isa person, has name "Tim", has age 55;
      $z isa person, has name "Jim", has age 55;
      $w isa person, has name "Winnie";
      $c isa company, has name "Pizza Express";
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x has attribute $r;
      """
    Then verify answer size is: 8
    Given reasoning query
      """
      match
        $x has attribute $r;
        not {
          $x isa person, has name "Tim", has age 55;
        };

      """
    Then verify answer size is: 6
    Then verify answer set is equivalent for query
      """
      match
        $x has attribute $r;
        not {
          $x isa person;
          $x has name "Tim";
          $x has age 55;
        };

      """


  Scenario: a query can contain multiple negations
    Given reasoning data
      """
      insert

      $x isa person, has name "Tim", has age 45;
      $y isa person, has name "Tim", has age 55;
      $z isa person, has name "Jim", has age 55;
      $w isa person, has name "Winnie";
      $c isa company, has name "Pizza Express";
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x has attribute $r;
      """
    Then verify answer size is: 8
    Given reasoning query
      """
      match
        $x has attribute $r;
        not { $x isa company; };

      """
    Then verify answer size is: 7
    Given reasoning query
      """
      match
        $x has attribute $r;
        not { $x isa company; };
        not { $x has name "Tim"; };

      """
    Then verify answer size is: 3
    Given reasoning query
      """
      match
        $x has attribute $r;
        not { $x isa company; };
        not { $x has name "Tim"; };
        not { $r 55; };

      """
    Then verify answer size is: 2


  Scenario: negation can exclude entities of specific types that play roles in a specific relation
    Given reasoning schema
      """
      define
      pizza-company sub company;
      """
    Given reasoning data
      """
      insert

      $x isa person, has name "Tim", has age 45;
      $y isa person, has name "Tim", has age 55;
      $z isa person, has name "Jim", has age 55;
      $w isa person, has name "Winnie";
      $c isa pizza-company, has name "Pizza Express";
      $d isa company, has name "Heathrow Express";

      (employee: $x, employer: $c) isa employment;
      (employee: $y, employer: $d) isa employment;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x isa person;
      """
    Then verify answer size is: 4
    Given reasoning query
      """
      match
        $x isa person;
        not {
          (employee: $x, employer: $y) isa employment;
          $y isa pizza-company;
        };

      """
    Then verify answer size is: 3


  Scenario: when using negation to exclude entities of specific types, their subtypes are also excluded
    Given reasoning schema
      """
      define
      pizza-company sub company;
      """
    Given reasoning data
      """
      insert

      $x isa person, has name "Tim", has age 45;
      $y isa person, has name "Tim", has age 55;
      $z isa person, has name "Jim", has age 55;
      $w isa person, has name "Winnie";
      $c isa pizza-company, has name "Pizza Express";
      $d isa company, has name "Heathrow Express";

      (employee: $x, employer: $c) isa employment;
      (employee: $y, employer: $d) isa employment;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match
        $x isa person;
        not {
          (employee: $x, employer: $y) isa employment;
          $y isa company;
        };

      """
    Then verify answer size is: 2


  Scenario: answers can be returned even if a statement in a conjunction in a negation is identical to a non-negated one
    Given reasoning schema
      """
      define
      pizza-company sub company;
      """
    Given reasoning data
    """
      insert

      $x isa person, has name "Tim", has age 45;
      $y isa person, has name "Tim", has age 55;
      $z isa person, has name "Jim", has age 55;
      $w isa person, has name "Winnie";
      $c isa pizza-company, has name "Pizza Express";
      $d isa company, has name "Heathrow Express";

      (employee: $x, employer: $c) isa employment;
      (employee: $y, employer: $d) isa employment;
      """
    # We match $x isa person and not {$x isa person; ...}; answers can still be returned because of the conjunction
    Given reasoning query
    """
      match
        $x isa person;
        not {
          $x isa person;
          (employee: $x, employer: $y) isa employment;
          $y isa pizza-company;
        };

      """
    Then verify answer size is: 3


  ##############################
  # MATCHING INFERRED CONCEPTS #
  ##############################

  Scenario: negation of a transitive relation is resolvable
    Given reasoning schema
      """
      define

      area sub place;
      city sub place;
      country sub place;
      continent sub place;

      rule location-hierarchy-transitivity: when {
          (superior: $a, subordinate: $b) isa location-hierarchy;
          (superior: $b, subordinate: $c) isa location-hierarchy;
      } then {
          (superior: $a, subordinate: $c) isa location-hierarchy;
      };
      """
    Given reasoning data
    """
      insert
      $ar isa area, has name "King's Cross";
      $cit isa city, has name "London";
      $cntry isa country, has name "UK";
      $cont isa continent, has name "Europe";
      (superior: $cont, subordinate: $cntry) isa location-hierarchy;
      (superior: $cntry, subordinate: $cit) isa location-hierarchy;
      (superior: $cit, subordinate: $ar) isa location-hierarchy;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match
        $continent isa continent;
        $area isa area;

      """
    Then verify answer size is: 1
    Given reasoning query
      """
      match
        $continent isa continent;
        $area isa area;
        not {(superior: $continent, subordinate: $area) isa location-hierarchy;};

      """
    Then verify answer size is: 0
    Then verify answers are sound
    Then verify answers are complete


  Scenario: negation can exclude a particular entity from a matched transitive relation
    Given reasoning schema
      """
      define

      indexable sub entity,
          owns index;

      traversable sub indexable,
          plays link:from,
          plays link:to,
          plays indirect-link:from,
          plays indirect-link:to,
          plays reachable:from,
          plays reachable:to;

      vertex sub traversable;
      node sub traversable;

      link sub relation, relates from, relates to;
      indirect-link sub relation, relates from, relates to;
      reachable sub relation, relates from, relates to;

      index sub attribute, value string;

      rule reachability-transitivityA: when {
          (from: $x, to: $y) isa link;
      } then {
          (from: $x, to: $y) isa reachable;
      };

      rule reachability-transitivityB: when {
          (from: $x, to: $z) isa link;
          (from: $z, to: $y) isa reachable;
      } then {
          (from: $x, to: $y) isa reachable;
      };

      rule indirect-link-rule: when {
          (from: $x, to: $y) isa reachable;
          not {(from: $x, to: $y) isa link;};
      } then {
          (from: $x, to: $y) isa indirect-link;
      };
      """
    Given reasoning data
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
    Given verifier is initialised
    Given reasoning query
    """
      match
        (from: $x, to: $y) isa indirect-link;
        $x has index "aa";

      """
    Then verify answer size is: 2
    Then verify answer set is equivalent for query
      """
      match
        (from: $x, to: $y) isa reachable;
        $x has index "aa";
        not {$y has index "bb";};

      """


  #####################
  # NEGATION IN RULES #
  #####################

  # TODO: re-enable all steps when fixed (#75)
  Scenario: a rule can be triggered based on not having a particular attribute
    Given reasoning schema
      """
      define
      person owns age;
      age sub attribute, value long;
      rule not-ten: when {
        $x isa person;
        not { $x has age 10; };
      } then {
        $x has name "Not Ten";
      };
      """
    Given reasoning data
    """
      insert
      $x isa person, has age 10;
      $y isa person, has age 20;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x has name "Not Ten", has age 20;
      """
    Then verify answer size is: 1
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match $x has name "Not Ten", has age 10;
      """
    Then verify answer size is: 0
    Then verify answers are sound
    Then verify answers are complete


  Scenario: a rule can be triggered based on not having any instances of a specified attribute type
    Given reasoning schema
      """
      define
      person owns age;
      age sub attribute, value long;
      rule not-ten: when {
        $x isa person;
        not { $x has age $val; };
      } then {
        $x has name "No Age";
      };
      """
    Given reasoning data
    """
      insert
      $x isa person, has age 10;
      $y isa person, has age 20;
      $z isa person;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x isa person;
      """
    Then verify answer size is: 3
    Then verify answers are sound
    Then verify answers are complete
    Given reasoning query
      """
      match $x isa person, has name "No Age";
      """
    Then verify answer size is: 1
    Then verify answers are sound
    Then verify answers are complete


  Scenario: when negating a conjunction, all the conjuction statements must be met for the negation to be met
    Given reasoning schema
      """
      define
      country sub entity, owns name, plays company-country:country;
      company plays company-country:company, plays non-uk:not-in-uk;
      company-country sub relation,
        relates company,
        relates country;
      non-uk sub relation,
        relates not-in-uk;
      rule non-uk-rule: when {
        $x isa company;
        not {
          (country: $y, company: $x) isa company-country;
          $y has name 'UK';
        };
      } then {
        (not-in-uk: $x) isa non-uk;
      };
      """
    Given reasoning data
    """
      insert
      $a isa company, has name "a";
      $b isa company, has name "b";
      $c isa company, has name "c";
      $d isa company, has name "d";

      $e isa country, has name 'UK';
      $f isa country, has name 'France';

      (country: $e, company: $a) isa company-country;
      (country: $e, company: $b) isa company-country;
      (country: $f, company: $c) isa company-country;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x isa company;
      """
    Then verify answer size is: 4
    Given reasoning query
      """
      match
        $x isa company;
        not { (not-in-uk: $x) isa non-uk; };

      """
    # Should exclude both the company in France and the company with no country
    Then verify answer size is: 2
    Then verify answers are sound
    Then verify answers are complete
    Then verify answer set is equivalent for query
      """
      match
        $x isa company;
        (country: $y, company: $x) isa company-country;
        $y has name "UK";
      get $x;
      """
    Then verify answer set is equivalent for query
      """
      match
        $x isa company;
        { $x has name "a"; } or { $x has name "b"; };

      """


  Scenario: when nesting multiple negations and conjunctions, they are correctly resolved
    Given reasoning schema
      """
      define
      country sub entity, owns name, plays company-country:country;
      company plays company-country:company, plays non-uk:not-in-uk;
      company-country sub relation,
        relates company,
        relates country;
      non-uk sub relation,
        relates not-in-uk;
      rule non-uk-rule: when {
        $x isa company;
        not {
          (country: $y, company: $x) isa company-country;
          $y has name 'UK';
        };
      } then {
        (not-in-uk: $x) isa non-uk;
      };
      """
    Given reasoning data
      """
      insert
      $a isa company, has name "a";
      $b isa company, has name "b";
      $c isa company, has name "c";
      $d isa company, has name "d";

      $e isa country, has name 'UK';
      $f isa country, has name 'France';

      (country: $e, company: $a) isa company-country;
      (country: $e, company: $b) isa company-country;
      (country: $f, company: $c) isa company-country;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match
        $x isa company;
        not {
          (not-in-uk: $x) isa non-uk;
          not {
            $x has name "c";
          };
        };

      """
    Then verify answer size is: 3
    Then verify answer set is equivalent for query
      """
      match
        $x isa company;
        not { $x has name "d"; };

      """


  Scenario: when evaluating negation blocks, global subgoals are not updated

  The test highlights a potential issue with eagerly updating global subgoals when branching out to determine whether
  negation conditions are met. When checking negation satisfiability, we are interested in a first answer that can
  prove us wrong - we are not exhaustively exploring all answer options.

  Consequently, if we use the same subgoals as for the main loop, we can end up with a query which answers weren't
  fully consumed but that was marked as visited.

  As a result, if it happens that a negated query has multiple answers and is visited more than a single time
  - because of the admissibility check, answers might be missed.

    Given reasoning schema
      """
      define

      session sub entity,
          plays reported-fault:parent-session,
          plays unanswered-question:parent-session,
          plays logged-question:parent-session,
          plays diagnosis:parent-session;

      fault sub entity,
          plays reported-fault:relevant-fault,
          plays fault-identification:identified-fault,
          plays diagnosis:diagnosed-fault;

      question sub entity,
          owns response,
          plays fault-identification:identifying-question,
          plays logged-question:question-logged,
          plays unanswered-question:question-not-answered;

      response sub attribute, value string;

      reported-fault sub relation,
          relates relevant-fault,
          relates parent-session;

      logged-question sub relation,
          relates question-logged,
          relates parent-session;

      unanswered-question sub relation,
          relates question-not-answered,
          relates parent-session;

      fault-identification sub relation,
          relates identifying-question,
          relates identified-fault;

      diagnosis sub relation,
          relates diagnosed-fault,
          relates parent-session;

      rule no-response-means-unanswered-question: when {
          $ques isa question;
          (question-logged: $ques, parent-session: $ts) isa logged-question;
          not {
              $ques has response $r;
          };
      } then {
          (question-not-answered: $ques, parent-session: $ts) isa unanswered-question;
      };

      rule determined-fault: when {
          (relevant-fault: $flt, parent-session: $ts) isa reported-fault;
          not {
              (question-not-answered: $ques, parent-session: $ts) isa unanswered-question;
              ($flt, $ques) isa fault-identification;
          };
      } then {
          (diagnosed-fault: $flt, parent-session: $ts) isa diagnosis;
      };
      """
    Given reasoning data
    """
      insert
      $sesh isa session;
      $q1 isa question;
      $q2 isa question;
      $f1 isa fault;
      $f2 isa fault;
      (relevant-fault: $f1, parent-session: $sesh) isa reported-fault;
      (relevant-fault: $f2, parent-session: $sesh) isa reported-fault;

      (question-logged: $q1, parent-session: $sesh) isa logged-question;
      (question-logged: $q2, parent-session: $sesh) isa logged-question;

      (identified-fault: $f1, identifying-question: $q1) isa fault-identification;
      (identified-fault: $f2, identifying-question: $q2) isa fault-identification;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match (diagnosed-fault: $flt, parent-session: $ts) isa diagnosis;
      """
    Then verify answer size is: 0
    Then verify answers are consistent across 5 executions
    Then verify answers are sound
    Then verify answers are complete


  Scenario: when evaluating negation blocks, completion of incomplete queries is not acknowledged
    Given reasoning schema
      """
      define
      resource sub attribute, value string;

      entity-1 sub entity, owns resource, plays relation-2:role-2, plays relation-3:role-4;
      entity-2 sub entity, owns resource, plays relation-2:role-1, plays relation-3:role-3, plays relation-3:role-4;
      entity-3 sub entity, owns resource, plays relation-2:role-1, plays relation-3:role-3, plays relation-3:role-4, plays symmetric-relation:symmetric-role;

      relation-2 sub relation, relates role-1, relates role-2;
      relation-3 sub relation, relates role-3, relates role-4;
      relation-4 sub relation-3;
      relation-5 sub relation-3;
      symmetric-relation sub relation, relates symmetric-role;


      rule rule-1: when {
          (role-3: $x, role-4: $y) isa relation-5;
      } then {
          (role-3: $x, role-4: $y) isa relation-4;
      };

      rule rule-2: when {
          (role-1: $x, role-2: $y) isa relation-2;
          not { (role-3: $x, role-4: $z) isa relation-5;};
      } then {
          (role-3: $x, role-4: $y) isa relation-4;
      };

      rule trans-rule: when {
          (role-3: $y, role-4: $z) isa relation-4;
          (role-3: $x, role-4: $y) isa relation-4;
      } then {
          (role-3: $x, role-4: $z) isa relation-4;
      };

      rule rule-3: when {
          (symmetric-role: $x, symmetric-role: $y) isa symmetric-relation;
      } then {
          (role-3: $y, role-4: $x) isa relation-5;
      };
      """
    Given reasoning data
    """
      insert
      $d isa entity-1, has resource "d";
      $e isa entity-2, has resource "e";

      $a isa entity-3, has resource "a";
      $b isa entity-3, has resource "b";
      $c isa entity-3, has resource "c";

      (role-1: $e, role-2: $d)  isa relation-2;
      (role-1: $a, role-2: $d) isa relation-2;
      (role-1: $b, role-2: $d)  isa relation-2;
      (role-1: $c, role-2: $d) isa relation-2;

      (role-3: $a, role-4: $e)  isa relation-5;
      (role-3: $b, role-4: $e)  isa relation-5;
      (role-3: $c, role-4: $e) isa relation-5;

      (symmetric-role: $c, symmetric-role: $b ) isa symmetric-relation;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match (role-3: $x, role-4: $y) isa relation-4;
      """
    Then verify answer size is: 11
    Then verify answers are consistent across 5 executions
    Then verify answers are sound
    Then verify answers are complete


  # TODO: Re-enable once fixed (Completeness found missing answer)
  @ignore
  Scenario: a rule can use negation to exclude things that have any transitive relations to a specific concept
    Given reasoning schema
      """
      define

      indexable sub entity,
          owns index;

      traversable sub indexable,
          plays link:from,
          plays link:to,
          plays reachable:from,
          plays reachable:to,
          plays unreachable:from,
          plays unreachable:to;

      node sub traversable;

      link sub relation, relates from, relates to;
      reachable sub relation, relates from, relates to;
      unreachable sub relation, relates from, relates to;

      index sub attribute, value string;

      rule reachability-transitivityA: when {
          (from: $x, to: $y) isa link;
      } then {
          (from: $x, to: $y) isa reachable;
      };

      rule reachability-transitivityB: when {
          (from: $x, to: $z) isa link;
          (from: $z, to: $y) isa reachable;
      } then {
          (from: $x, to: $y) isa reachable;
      };

      rule unreachability-rule: when {
          $x isa node;
          $y isa node;
          not {(from: $x, to: $y) isa reachable;};
      } then {
          (from: $x, to: $y) isa unreachable;
      };
      """
    Given reasoning data
    """
      insert

      $aa isa node, has index "aa";
      $bb isa node, has index "bb";
      $cc isa node, has index "cc";
      $dd isa node, has index "dd";
      $ee isa node, has index "ee";
      $ff isa node, has index "ff";
      $gg isa node, has index "gg";
      $hh isa node, has index "hh";

      (from: $aa, to: $bb) isa link;
      (from: $bb, to: $cc) isa link;
      (from: $cc, to: $cc) isa link;
      (from: $cc, to: $dd) isa link;
      (from: $ee, to: $ff) isa link;
      (from: $ff, to: $gg) isa link;
      """
    Given verifier is initialised
    Given reasoning query
    """
      match
        (from: $x, to: $y) isa unreachable;
        $x has index "aa";

      """
    # aa is not linked to itself. ee, ff, gg are linked to each other, but not to aa. hh is not linked to anything
    Then verify answer size is: 5
    Then verify answers are sound
    Then verify answers are complete
    Then verify answer set is equivalent for query
      """
      match
        $x has index "aa"; $y isa node;
        { $y has index "aa"; } or { $y has index "ee"; } or { $y has index "ff"; } or
        { $y has index "gg"; } or { $y has index "hh"; };

      """

  Scenario: negated and non-negated clauses can use the same rule
    Given reasoning schema
      """
      define
      name sub attribute, value string;
      retailer sub attribute, value string;
      soft-drink sub entity,
        owns name,
        owns retailer;

      rule ocado-sells-all-soft-drinks: when {
        $y isa soft-drink;
      } then {
        $y has retailer 'Ocado';
      };
      """
    Given reasoning data
      """
      insert
      $x isa soft-drink, has name "Fanta";
      $r "Ocado" isa retailer;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match
        $x has retailer $r;
        not { $r == "Ocado"; };

      """
    Then verify answer size is: 0
    Then verify answers are sound
    Then verify answers are complete

  Scenario: double nested negations are resolved correctly
    Given reasoning schema
      """
      define
      enemies sub relation,
        relates enemy;
      person plays enemies:enemy;

      rule non-friends-are-enemies:
      when {
        $p1 isa person;
        $p2 isa person;
        not { ($p1, $p2) isa friendship; };
      } then {
        (enemy: $p1, enemy: $p2) isa enemies;
      };
      """
    Given reasoning data
      """
      insert
      $p1 isa person, has name "a";
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $p isa person; not { ($p, $f) isa enemies; };
      """
    Then verify answer size is: 0
#    TODO: Add a case with non-zero answers


  Scenario: Negated concept considers all rules & retrievables
    Derived from issue #6500
    Given reasoning schema
      """
      define

      place plays passage:from,
            plays passage:to,
            plays reachable:from,
            plays reachable:to;

      passage sub relation,
          relates from,
          relates to;

      reachable sub relation,
          relates from,
          relates to;

      rule location-hierarchy-transitivity: when {
          (superior: $a, subordinate: $b) isa location-hierarchy;
          (superior: $b, subordinate: $c) isa location-hierarchy;
      } then {
          (superior: $a, subordinate: $c) isa location-hierarchy;
      };

      rule reachable-rule:
          when {
              $from isa place;
              $to isa place;
              $common-superior isa place;
              (superior: $common-superior, subordinate: $from) isa location-hierarchy;
              (from: $common-superior, to: $to) isa passage;
              not {$common-superior is $to;};
              not {(superior: $to, subordinate: $from) isa location-hierarchy;};
          } then {
              (from: $from, to: $to) isa reachable;
          };
      """
    Given reasoning data
      """
      insert
      $forest isa place, has name "forest";
      $cabin isa place, has name "cabin";
      $common-room isa place, has name "common room";
      $fridge isa place, has name "fridge";

      (superior: $forest, subordinate: $cabin) isa location-hierarchy;
      (superior: $cabin, subordinate: $common-room) isa location-hierarchy;
      (superior: $common-room, subordinate: $fridge) isa location-hierarchy;
      (from: $forest, to: $common-room) isa passage;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match
      $from isa place, has name $from-name;
      $to isa place, has name $to-name;
      (from: $from, to: $to) isa reachable;
      get $from-name, $to-name;
      """
    Then verify answer size is: 2
    Then verify answers are sound
    Then verify answers are complete
