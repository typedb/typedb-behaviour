# Constraints
#  Only scenarios where there is only one possible resolution path can be tested in this way

Feature: Graql Reasoning Explanation

  Background: Initialise a session and transaction for each scenario
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | test_explanation |
    Given transaction is initialised

  @ignore
  Scenario: an attribute's existence and ownership can be inferred
    Given graql define
      """
      define

      name sub attribute, value string;
      company-id sub attribute, value long;

      company sub entity,
        has name,
        key company-id;

      company-has-name sub rule,
      when {
         $c isa company;
      }, then {
         $c has name "the-company";
      };
      """

    When graql insert
      """
      insert
      $x isa company, has company-id 0;
      """

    Then get answers of graql query
      """
      match $co has name $n; get;
      """

    Then concept identifiers are
      |     | check | value            |
      | CO  | key   | company-id:0     |
      | CON | value | name:the-company |

    Then uniquely identify answer concepts
      | co | n   |
      | CO | CON |

    Then rules are
      |                  | when                 | then                            |
      | company-has-name | { $c isa company; }; | { $c has name "the-company"; }; |

    Then answers contain explanation tree
      |   | children | vars  | identifiers | rule             | pattern                                                      |
      | 0 | 1        | co, n | CO, CON     | company-has-name | $co id <answer.co.id>; $co has name $n; $n id <answer.n.id>; |
      | 1 | -        | c     | CO          | lookup           | $c isa company; $c id <answer.c.id>;                         |


  @ignore
  Scenario: an attribute's existence, and ownership can be inferred recursively
    Given graql define
      """
      define

      name sub attribute,
          value string;

      is-liable sub attribute,
          value boolean;

      company-id sub attribute,
          value long;

      company sub entity,
          key company-id,
          has name,
          has is-liable;

      company-has-name sub rule,
      when {
          $c1 isa company;
      }, then {
          $c1 has name "the-company";
      };

      company-is-liable sub rule,
      when {
          $c2 isa company, has name $name; $name "the-company";
      }, then {
          $c2 has is-liable true;
      };
      """

    When graql insert
      """
      insert
      $co isa company, has company-id 0;
      """

    Then get answers of graql query
      """
      match $co has is-liable $l; get;
      """

    Then concept identifiers are
      |     | check | value            |
      | CO  | key   | company-id:0     |
      | CON | value | name:the-company |
      | LIA | value | is-liable:true   |

    Then uniquely identify answer concepts
      | co | l   |
      | CO | LIA |

    Then rules are
      |                   | when                                                       | then                             |
      | company-has-name  | { $c1 isa company; };                                      | { $c1 has name "the-company"; }; |
      | company-is-liable | { $c2 isa company, has name $name; $name "the-company"; }; | { $c2 has is-liable true; };     |

    Then answers contain explanation tree
      |   | children | vars     | identifiers | rule              | pattern                                                                                                         |
      | 0 | 1        | co, l    | CO, LIA     | company-is-liable | $co id <answer.co.id>; $co has is-liable $l; $l id <answer.l.id>;                                               |
      | 1 | 2        | c2, name | CO, CON     | company-has-name  | $c2 isa company; $c2 has name $name; $name == "the-company"; $c2 id <answer.c2.id>; $name id <answer.name.id>;  |
      | 2 | -        | c1       | CO          | lookup            | $c1 isa company; $c1 id <answer.c1.id>;                                                                         |


  Scenario: relation is explained as expected when there is no inference
    Given graql define
      """
      define
      name sub attribute,
          value string;

      location sub entity,
          abstract,
          key name,
          plays superior,
          plays subordinate;

      area sub location;
      city sub location;
      country sub location;

      location-hierarchy sub relation,
          relates superior,
          relates subordinate;
      """

    When graql insert
      """
      insert
      $ar isa area, has name "King's Cross";
      $cit isa city, has name "London";
      (superior: $cit, subordinate: $ar) isa location-hierarchy;
      """

    Then get answers of graql query
      """
      match
      $k isa area, has name $n;
      (superior: $l, subordinate: $k) isa location-hierarchy;
      get;
      """

    Then concept identifiers are
      |     | check | value             |
      | KC  | key   | name:King's Cross |
      | LDN | key   | name:London       |
      | KCn | value | name:King's Cross |

    Then uniquely identify answer concepts
      | k  | l   | n   |
      | KC | LDN | KCn |

    Then answers contain explanation tree
      |   | children | vars    | identifiers  | rule   | pattern                                                                                                                                             |
      | 0 | -        | k, l, n | KC, LDN, KCn | lookup | $k isa area; $k has name $n; (superior: $l, subordinate: $k) isa location-hierarchy; $k id <answer.k.id>; $n id <answer.n.id>; $l id <answer.l.id>; |


  @ignore
  Scenario: transitive relation is explained as expected for one hop
    Given graql define
      """
      define
      name sub attribute,
          value string;

      location sub entity,
          abstract,
          key name,
          plays superior,
          plays subordinate;

      area sub location;
      city sub location;
      country sub location;

      location-hierarchy sub relation,
          relates superior,
          relates subordinate;

      location-hierarchy-transitivity sub rule,
      when {
          (superior: $a, subordinate: $b) isa location-hierarchy;
          (superior: $b, subordinate: $c) isa location-hierarchy;
      }, then {
          (superior: $a, subordinate: $c) isa location-hierarchy;
      };
      """

    When graql insert
      """
      insert
      $ar isa area, has name "King's Cross";
      $cit isa city, has name "London";
      $cntry isa country, has name "UK";
      (superior: $cntry, subordinate: $cit) isa location-hierarchy;
      (superior: $cit, subordinate: $ar) isa location-hierarchy;
      """

    Then get answers of graql query
      """
      match
      $k isa area, has name $n;
      (superior: $l, subordinate: $k) isa location-hierarchy;
      get;
      """

    Then concept identifiers are
      |     | check | value             |
      | KC  | key   | name:King's Cross |
      | UK  | key   | name:UK           |
      | LDN | key   | name:London       |
      | KCN | value | name:King's Cross |

    Then uniquely identify answer concepts
      | k  | l   | n   |
      | KC | UK  | KCN |
      | KC | LDN | KCN |

    Then rules are
      |                                 | when                                                                                                                 | then                                                         |
      | location-hierarchy-transitivity | { (superior: $a, subordinate: $b) isa location-hierarchy; (superior: $b, subordinate: $c) isa location-hierarchy; }; | { (superior: $a, subordinate: $c) isa location-hierarchy; }; |

    Then answers contain explanation tree
      |   | children | vars    | identifiers | rule                            | pattern                                                                                                                                                                                      |
      | 0 | 1, 2     | k, l, n | KC, UK, KCN | join                            | $k isa area; $k has name $n; (superior: $l, subordinate: $k) isa location-hierarchy; $k id <answer.k.id>; $n id <answer.n.id>; $l id <answer.l.id>;                                          |
      | 1 | -        | k, n    | KC, KCN     | lookup                          | $k isa area; $k has name $n; $n id <answer.n.id>; $k id <answer.k.id>;                                                                                                                       |
      | 2 | 3        | k, l    | KC, UK      | location-hierarchy-transitivity | (superior: $l, subordinate: $k) isa location-hierarchy; $k isa area; $k id <answer.k.id>; $l id <answer.l.id>;                                                                               |
      | 3 | 4, 5     | a, b, c | UK, LDN, KC | join                            | (superior: $a, subordinate: $b) isa location-hierarchy; (superior: $b, subordinate: $c) isa location-hierarchy; $c isa area; $a id <answer.a.id>; $b id <answer.b.id>; $c id <answer.c.id>;  |
      | 4 | -        | b, c    | LDN, KC     | lookup                          | (superior: $b, subordinate: $c) isa location-hierarchy; $c isa area; $b id <answer.b.id>; $c id <answer.c.id>;                                                                               |
      | 5 | -        | a, b    | UK, LDN     | lookup                          | (superior: $a, subordinate: $b) isa location-hierarchy; $b id <answer.b.id>; $a id <answer.a.id>;                                                                                            |

#   TODO Non-deterministically getting this error:
#   Expected :{ (superior: $b, subordinate: $c) isa location-hierarchy; $c isa area; $b id V8240; $c id V20656; };
#   Actual   :{ $c id V20656; $b id V8240; (superior: $b, subordinate: $c) isa location-hierarchy; };

    Then answers contain explanation tree
      |   | children | vars    | identifiers  | rule   | pattern                                                                                                                                             |
      | 0 | 1, 2     | k, l, n | KC, LDN, KCN | join   | $k isa area; $k has name $n; (superior: $l, subordinate: $k) isa location-hierarchy; $k id <answer.k.id>; $n id <answer.n.id>; $l id <answer.l.id>; |
      | 1 | -        | k, n    | KC, KCN      | lookup | $k isa area; $k has name $n; $n id <answer.n.id>; $k id <answer.k.id>;                                                                              |
      | 2 | -        | k, l    | KC, LDN      | lookup | (superior: $l, subordinate: $k) isa location-hierarchy; $k isa area; $k id <answer.k.id>; $l id <answer.l.id>;                                      |


  @ignore
  Scenario: an attribute's existence and ownership can be inferred and used to infer a relation
    Given graql define
      """
      define

      name sub attribute, value string;

      person-id sub attribute, value long;

      person sub entity,
          key person-id,
          has name,
          plays sibling;

      man sub person;
      woman sub person;

      siblingship sub relation,
          relates sibling;

      a-man-is-called-bob sub rule,
      when {
          $man isa man;
      }, then {
          $man has name "Bob";
      };

      bobs-sister-is-alice sub rule,
      when {
          $p isa man, has name $nb; $nb "Bob";
          $p1 isa woman, has name $na; $na "Alice";
      }, then {
          (sibling: $p, sibling: $p1) isa siblingship;
      };
      """

    When graql insert
      """
      insert
      $a isa woman, has person-id 0, has name "Alice";
      $b isa man, has person-id 1;
      """

    Then get answers of graql query
      """
      match (sibling: $w, sibling: $m) isa siblingship; $w isa woman; get;
      """

    Then concept identifiers are
      |      | check | value       |
      | ALI  | key   | person-id:0 |
      | ALIN | value | name:Alice  |
      | BOB  | key   | person-id:1 |
      | BOBN | value | name:Bob    |

    Then uniquely identify answer concepts
      | w   | m   |
      | ALI | BOB |

    Then rules are
      |                      | when                                                                                | then                                              |
      | a-man-is-called-bob  | { $man isa man; };                                                                  | { $man has name "Bob"; };                         |
#      | bobs-sister-is-alice  | { $p isa man, has name "Bob"; $p1 isa woman, has name "Alice"; };                   | { (sibling: $p, sibling: $p1) isa siblingship; }; |
#      TODO Expected the above as the response, but the rule body was customised to the pattern of the explanation's answer(s), as below
      | bobs-sister-is-alice | { $p isa man, has name $nb; $nb "Bob"; $p1 isa woman, has name $na; $na "Alice"; }; | { (sibling: $p, sibling: $p1) isa siblingship; }; |

    Then answers contain explanation tree
      |   | children  | vars          | identifiers           | rule                 | pattern                                                                                                                                                                                |
      | 0 | 1         | w, m          | ALI, BOB              | bobs-sister-is-alice | (sibling: $m, sibling: $w) isa siblingship; $w isa woman; $w id <answer.w.id>; $m id <answer.m.id>;                                                                                    |
      | 1 | 2, 3      | p, nb, p1, na | BOB, BOBN, ALI, ALIN  | join                 | $p isa man; $p has name $nb; $nb == "Bob"; $p id <answer.p.id>; $nb id <answer.nb.id>; $p1 isa woman; $p1 has name $na; $na == "Alice"; $p1 id <answer.p1.id>; $na id <answer.na.id>;  |
      | 2 | 4         | p, nb         | BOB, BOBN             | a-man-is-called-bob  | $p isa man; $p has name $nb; $nb == "Bob"; $p id <answer.p.id>; $nb id <answer.nb.id>;                                                                                                 |
      | 3 | -         | p1, na        | ALI, ALIN             | lookup               | $p1 isa woman; $p1 has name $na; $na == "Alice"; $p1 id <answer.p1.id>; $na id <answer.na.id>;                                                                                         |
      | 4 | -         | man           | BOB                   | lookup               | $man isa man; $man id <answer.man.id>;                                                                                                                                                 |
