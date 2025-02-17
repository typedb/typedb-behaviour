# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL Update Query

  Background: Open connection and create a simple extensible schema
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
        plays friendship:friend,
        plays parentship:parent,
        plays parentship:child,
        owns name,
        owns ref @key;
      relation friendship,
        relates friend,
        owns ref @key;
      relation parentship,
        relates parent,
        relates child;
      attribute name value string;
      attribute ref @independent, value integer;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb


#  Scenario: Update owned attribute without side effects on other owners
#    Given get answers of typeql write query
#      """
#      insert
#        $x isa person, has name "Alex", has ref 0;
#        $y isa person, has name "Alex", has ref 1;
#      """
#    Given uniquely identify answer concepts
#      | x         | y         |
#      | key:ref:0 | key:ref:1 |
#    Given transaction commits
#    Given connection open write transaction for database: typedb
#    When typeql write query
#      """
#      match
#      $x isa person, has ref 1, has $n;
#      $n isa name;
#      delete has $n of $x;
#      insert $x has name "Bob";
#      """
#    Then transaction commits
#    Given connection open write transaction for database: typedb
#    When get answers of typeql read query
#      """
#      match $x isa person, has name $n;
#      """
#    Then uniquely identify answer concepts
#      | x         | n               |
#      | key:ref:0 | attr:name:Alex  |
#      | key:ref:1 | attr:name:Bob   |
#
#
#  Scenario: Roleplayer exchange
#    Given get answers of typeql write query
#      """
#      insert
#      $x isa person, has name "Alex", has ref 0;
#      $y isa person, has name "Bob", has ref 1;
#      $r isa parentship (parent: $x, child:$y);
#      """
#    Given transaction commits
#    Given connection open write transaction for database: typedb
#    When typeql write query
#      """
#      match $r isa parentship (parent: $x, child: $y);
#      delete $r;
#      insert $q isa parentship (parent: $y, child: $x);
#      """
#
#
#  Scenario: Complex migration
#    Given get answers of typeql write query
#      """
#      insert
#      $u isa person, has name "Alex", has ref 0;
#      $v isa person, has name "Bob", has ref 1;
#      $w isa person, has name "Charlie", has ref 2;
#      $x isa person, has name "Darius", has ref 3;
#      $y isa person, has name "Alex", has ref 4;
#      $z isa person, has name "Bob", has ref 5;
#      """
#    Given transaction commits
#    Given connection open schema transaction for database: typedb
#    Given typeql schema query
#      """
#      define
#      entity nameclass,
#        owns name @key,
#        plays naming:name;
#      relation naming,
#        relates named,
#        relates name;
#      person plays naming:named;
#      """
#    Given transaction commits
#    Given connection open write transaction for database: typedb
#    When typeql write query
#      """
#      match $att isa name;
#      insert $x isa nameclass, has $att;
#      """
#    When typeql write query
#      """
#      match
#      $p isa person, has name $n;
#      $nc isa nameclass, has name $n;
#      delete has $n of $p;
#      insert (named: $p, name: $nc) isa naming;
#      """
#    Then transaction commits
#    Given connection open read transaction for database: typedb
#    When get answers of typeql read query
#      """
#      match
#      $r isa naming (named: $p, name: $nc);
#      $nc has name $n;
#
#      """
#    Then uniquely identify answer concepts
#      | p         | n                  |
#      | key:ref:0 | attr:name:Alex     |
#      | key:ref:1 | attr:name:Bob      |
#      | key:ref:2 | attr:name:Charlie  |
#      | key:ref:3 | attr:name:Darius   |
#      | key:ref:4 | attr:name:Alex     |
#      | key:ref:5 | attr:name:Bob      |
#
#    When get answers of typeql read query
#      """
#      match
#      $p isa person;
#      $p has name $n;
#
#      """
#    Then answer size is: 0


  #######################
  # UNSUPPORTED UPDATES #
  #######################

  Scenario: Update queries cannot define or update schema
    Given transaction closes

    Given connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      match
        $p label person;
      update
        $p label superperson;
      """

    When connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      match
        $p label person;
      update
        entity superperson;
      """

    When connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      match
        $p label person;
      update
        $p owns name;
      """

    When connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      match
        $p label person;
      update
        $p @abstract;
      """

    When connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      match
        $p label person;
      update
        $p owns name @card(5..);
      """

    When connection open schema transaction for database: typedb
    Then typeql schema query; parsing fails
      """
      match
        $n label name;
      update
        $n value datetime;
      """

    When connection open schema transaction for database: typedb
    Then typeql write query; parsing fails
      """
      update
        entity superperson;
      """


  Scenario: Update queries cannot declare new instances through isa
    Given typeql write query
      """
      insert
        $p isa person, has ref 0, has name "Bob";
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "variable 'a' referenced in the update stage is unavailable"
      """
      update
        $a isa name "John";
      """
    When transaction closes

    When connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "variable 'a' referenced in the update stage is unavailable"
      """
      match
        $p isa person;
      update
        $a isa name "John";
      """
    When transaction closes

    When connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "Illegal statement provided for an update stage"
      """
      match
        $p isa person, has name $a;
      update
        $a isa name "Bob";
      """
    When transaction closes

    When connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "Illegal statement provided for an update stage"
      """
      match
        $p isa person, has name $a;
      update
        $a isa name "John";
      """
    When transaction closes

    When connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "variable 'p' referenced in the update stage is unavailable"
      """
      update
        $p isa person;
      """
    When transaction closes

    When connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "variable 'p' referenced in the update stage is unavailable"
      """
      update
        $p isa parentship;
      """
    When transaction closes

    When connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "Illegal statement provided for an update stage"
      """
      match $p isa person;
      update
        (parent: $p) isa parentship;
      """


  Scenario: Update queries cannot match instances and types or illegally update them
    Given typeql write query
      """
      insert
        $p isa person, has ref 0, has name "Bob";
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "variable 'p' referenced in the update stage is unavailable"
      """
      update
        $p iid 0x1e00000000001234567890;
      """
    When transaction closes

    When connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "variable 'p' referenced in the update stage is unavailable"
      """
      update
        $p isa person;
      """
    When transaction closes

    When connection open write transaction for database: typedb
    Then typeql write query; parsing fails
      """
      update > 5;
      """

    When connection open write transaction for database: typedb
    Then typeql write query; parsing fails
      """
      update = 5;
      """

    When connection open write transaction for database: typedb
    Then typeql write query; parsing fails
      """
      update 6 > 5;
      """

    When connection open write transaction for database: typedb
    Then typeql write query; parsing fails
      """
      update $p is $f;
      """

    When connection open write transaction for database: typedb
    Then typeql write query; parsing fails
      """
      update person owns name;
      """

  #############################
  # HAS (ATTRIBUTE OWNERSHIP) #
  #############################

  Scenario: Has can be updated by a new attribute without a variable
    Given typeql write query
      """
      insert $p isa person, has ref 0;
      """

    When get answers of typeql write query
      """
      match
        $p isa person;
      update
        $p has name "Alice";
      """
    Then uniquely identify answer concepts
      | p              |
      | key:name:Alice |
    When get answers of typeql read query
      """
      match $p isa person, has name $n;
      """
    Then uniquely identify answer concepts
      | p         | n               |
      | key:ref:0 | attr:name:Alice |

    When get answers of typeql write query
      """
      match
        $p isa person;
      update
        $p has name "Bob";
      """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |
    When get answers of typeql read query
      """
      match $p isa person, has name $n;
      """
    Then uniquely identify answer concepts
      | p         | n             |
      | key:ref:0 | attr:name:Bob |

    When get answers of typeql write query
      """
      match
        $p isa person, has name "Bob";
      update
        $p has name "Charlie";
      """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |
    When get answers of typeql read query
      """
      match $p isa person, has name $n;
      """
    Then uniquely identify answer concepts
      | p         | n                 |
      | key:ref:0 | attr:name:Charlie |

    When get answers of typeql write query
      """
      match
        $p isa person, has name $_;
      update
        $p has name "Donald";
      """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |
    When get answers of typeql read query
      """
      match $p isa person, has name $n;
      """
    Then uniquely identify answer concepts
      | p         | n                |
      | key:ref:0 | attr:name:Donald |


  Scenario: Has can be updated with an attribute variable
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define name @independent;
      """
    Given typeql write query
      """
      insert
        $p isa person, has ref 0;
        $n isa name "Charlie";
      """
    Given transaction commits
    Given connection open write transaction for database: typedb

    When get answers of typeql write query
      """
      insert
        $n isa name "Alice";
      match
        $p isa person;
      update
        $p has $n;
      """
    Then uniquely identify answer concepts
      | p              |
      | key:name:Alice |
    When get answers of typeql read query
      """
      match $p isa person, has name $n;
      """
    Then uniquely identify answer concepts
      | p         | n               |
      | key:ref:0 | attr:name:Alice |

    When get answers of typeql write query
      """
      match
        $p isa person;
        let $n = "Bob";
      update
        $p has name == $n;
      """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |
    When get answers of typeql read query
      """
      match $p isa person, has name $n;
      """
    Then uniquely identify answer concepts
      | p         | n             |
      | key:ref:0 | attr:name:Bob |

    When get answers of typeql write query
      """
      match
        $p isa person;
        $n isa name "Charlie";
      update
        $p has $n;
      """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |
    When get answers of typeql read query
      """
      match $p isa person, has name $n;
      """
    Then uniquely identify answer concepts
      | p         | n                 |
      | key:ref:0 | attr:name:Charlie |

    Then typeql write query; fails with a message containing: "Illegal 'isa' provided for variable 'n' that is input from a previous stage"
      """
      match
        $p isa person;
        $n isa name "Alice";
      update
        $p has name $n;
      """
    When transaction closes

    When connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "The variable 'n' referenced in the update stage is unavailable"
      """
      match
        $p isa person;
      update
        $n isa name "Charlie";
        $p has $n;
      """
    When transaction closes

    When connection open write transaction for database: typedb
    Then typeql write query; parsing fails
      """
      match
        $p isa person;
      update
        let $n = "Charlie";
        $p has name == $n;
      """


  Scenario: Has can be updated by an arithmetic operation, but not a comparison
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define person owns balance; attribute balance value decimal;
      """
    Given typeql write query
      """
      insert
        $p0 isa person, has ref 0, has balance 20.0dec;
        $p1 isa person, has ref 1, has balance 0.0dec;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb

    # TODO: Uncomment when inserts can do this. Now it returns errors! Write tests for inserts + cover it here
#    When get answers of typeql write query
#      """
#      match
#        $p isa person, has balance $b;
#      update
#        $p has balance $b + 15;
#      """
#    Then uniquely identify answer concepts
#      | p         | b                    |
#      | key:ref:0 | attr:balance:20.0dec |
#      | key:ref:1 | attr:balance:0.0dec  |
#    When get answers of typeql read query
#      """
#      match $p isa person, has balance $b;
#      """
#    Then uniquely identify answer concepts
#      | p         | b                    |
#      | key:ref:0 | attr:balance:35.0dec |
#      | key:ref:1 | attr:balance:15.0dec |
#
#    When get answers of typeql write query
#      """
#      match
#        $p isa person, has balance $_;
#        let $v = 15.5dec;
#      update
#        $p has $v + 15;
#      """
#    Then uniquely identify answer concepts
#      | p         | v                     |
#      | key:ref:0 | value:decimal:15.5dec |
#      | key:ref:1 | value:decimal:15.5dec |
#    When get answers of typeql read query
#      """
#      match $p isa person, has balance $b;
#      """
#    Then uniquely identify answer concepts
#      | p         | b                    |
#      | key:ref:0 | attr:balance:30.5dec |
#      | key:ref:1 | attr:balance:30.5dec |

    When typeql write query; fails with a message containing: "'b' cannot be declared as both a 'ThingType' and as a 'Attribute'"
      """
      match
        $p isa person, has balance $b;
      update
        $p has $b + 15;
      """
    When transaction closes
    When connection open write transaction for database: typedb

    Then typeql write query; fails with a message containing: "'b' cannot be declared as both a 'ThingType' and as a 'Attribute'"
      """
      match
        $p isa person, has balance $b;
      update
        $p has $b < 15;
      """
    When transaction closes
    When connection open write transaction for database: typedb

    Then typeql write query; parsing fails
      """
      match
        $p isa person, has balance $b;
      update
        $p has balance $b < 15;
      """


  Scenario: Can update from any other write stage, even right after creating a new instance
    When get answers of typeql write query
      """
      insert
        $p isa person, has ref 0, has name "Alice";
      update
        $p has name "Bob";
      update
        $p has name "Charlie";
      update
        $p has name "David";
      """
    When get answers of typeql read query
      """
      match $p isa person, has name $n;
      """
    Then uniquely identify answer concepts
      | p         | n               |
      | key:ref:0 | attr:name:David |


  Scenario: Cannot declare new attribute and value variables in an update stage
    Then typeql write query; parsing fails
      """
      insert
        $p isa person, has ref 0, has name "Alice";
      update
        let $n = "Bob";
        $p has name $n;
      """
    When connection open write transaction for database: typedb
    Then typeql write query; parsing fails
      """
      insert
        $p isa person, has ref 0, has name "Alice";
      update
        let $n = "Bob";
        $p has name == $n;
      """
    When connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "variable 'n' referenced in the update stage is unavailable"
      """
      insert
        $p isa person, has ref 0, has name "Alice";
      update
        $n isa name "Bob";
        $p has $n;
      """


  Scenario: Has can be updated by a function call
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
        person owns balance; attribute balance value decimal;
        fun increased_balance($b: balance) -> decimal:
          match
            let $ib = $b + 15.0dec;
          return first $ib;
        fun get_balance($p: person) -> balance:
          match
            $p has balance $b;
          return first $b;
      """
    Given typeql write query
      """
      insert
        $p0 isa person, has ref 0, has balance 20.0dec;
        $p1 isa person, has ref 1, has balance 0.0dec;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb

    When get answers of typeql write query
      """
      match
        $p isa person, has balance $b;
      update
        $p has balance increased_balance($b);
      """
    Then uniquely identify answer concepts
      | p         | b                    |
      | key:ref:0 | attr:balance:20.0dec |
      | key:ref:1 | attr:balance:0.0dec  |
    When get answers of typeql read query
      """
      match $p isa person, has balance $b;
      """
    Then uniquely identify answer concepts
      | p         | b                    |
      | key:ref:0 | attr:balance:30.5dec |
      | key:ref:1 | attr:balance:30.5dec |

    When transaction commits
    When connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $p isa person, has balance $b;
      """
    Then uniquely identify answer concepts
      | p         | b                    |
      | key:ref:0 | attr:balance:30.5dec |
      | key:ref:1 | attr:balance:30.5dec |

    Then typeql write query; fails with a message containing: "afkawnlfla"
      """
      match
        $p isa person, has balance $b;
      update
        $p has increased_balance($b);
      """
    When transaction closes

    When connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "afkawnlfla"
      """
      match
        $p isa person, has balance $b;
      update
        let $ib = increased_balance($b);
        $p has balance $ib;
      """

    When connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      match
        $p isa person, has ref 0, has balance $b;
        let $nb = increased_balance($b);
      update
        $p has balance $nb;
      """
    Then uniquely identify answer concepts
      | p         | b                    | nb                    |
      | key:ref:0 | attr:balance:30.5dec | value:decimal:46.0dec |
    When get answers of typeql read query
      """
      match $p isa person, has balance $b;
      """
    Then uniquely identify answer concepts
      | p         | b                    |
      | key:ref:0 | attr:balance:46.0dec |
      | key:ref:1 | attr:balance:30.5dec |
    When transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      match
        $p0 isa person, has ref 0, has balance $b0;
        $p1 isa person, has ref 1, has balance $b1;
      update
        $p1 has get_balance($p0);
      """
    Then uniquely identify answer concepts
      | p0        | p1        | b0                   | b1                    |
      | key:ref:0 | key:ref:1 | attr:balance:46.0dec | value:decimal:30.5dec |
    When get answers of typeql read query
      """
      match $p isa person, has balance $b;
      """
    Then uniquely identify answer concepts
      | p         | b                    |
      | key:ref:0 | attr:balance:46.0dec |
      | key:ref:1 | attr:balance:46.0dec |

    Then typeql write query; fails with a message containing: "afkgalwfl"
      """
      match
        $p0 isa person, has ref 0, has balance $b0;
        $p1 isa person, has ref 1, has balance $b1;
      update
        $p1 has balance get_balance($p0);
      """


  Scenario Outline: Cannot update has with cardinality higher than 1: @card(<card>)
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define person owns name @card(<card>);
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $p isa person, has ref 0<has-name>;
      """
    Examples:
      | card  | has-name                              |
      | 0..   | , has name "Alice"                    |
      | 0..10 | , has name "Alice"                    |
      | 0..2  | , has name "Alice"                    |
      | 1..   | , has name "Alice"                    |
      | 1..2  | , has name "Alice"                    |
      | 2..2  | , has name "Alice", has name "Morgan" |
      | 2     | , has name "Alice", has name "Morgan" |


  Scenario: Has for keys can be updated
    Given typeql write query
      """
      insert $p isa person, has ref 0;
      """

    When get answers of typeql write query
      """
      match
        $p isa person;
      update
        $p has ref 1;
      """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:1 |
    When get answers of typeql read query
      """
      match $p isa person, has ref $r;
      """
    Then uniquely identify answer concepts
      | p         | r          |
      | key:ref:1 | attr:ref:1 |

    When get answers of typeql write query
      """
      match
        $p isa person, has ref 1;
      update
        $p has ref 0;
      """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |
    When get answers of typeql read query
      """
      match $p isa person, has ref $r;
      """
    Then uniquely identify answer concepts
      | p         | r          |
      | key:ref:0 | attr:ref:0 |

    When get answers of typeql write query
      """
      match
        $p isa person, has ref $_;
      update
        $p has ref 5;
      """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:5 |
    When get answers of typeql read query
      """
      match $p isa person, has ref $r;
      """
    Then uniquely identify answer concepts
      | p         | r          |
      | key:ref:5 | attr:ref:5 |


  Scenario: Update cannot result in keys conflict
    Given typeql write query
      """
      insert $p0 isa person, has ref 0;
      insert $p1 isa person, has ref 1;
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "Constraint '@unique' has been violated"
      """
      match
        $p isa person;
      update
        $p has ref 2;
      """
    When transaction closes

    When connection open write transaction for database: typedb
    Then get answers of typeql write query
      """
      match
        $p isa person, has ref 0;
      update
        $p has ref 2;
      """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:2 |
    When get answers of typeql read query
      """
      match $p isa person, has ref $r;
      """
    Then uniquely identify answer concepts
      | p         | r          |
      | key:ref:2 | attr:ref:2 |
      | key:ref:1 | attr:ref:1 |


  Scenario: Has update can result in 0 changes if it updates existing data by the same value
    Given typeql write query
      """
      insert $p isa person, has ref 0, has name "Alice";
      """
    Given get answers of typeql read query
      """
      match $p isa person, has name $n;
      """
    Given uniquely identify answer concepts
      | p         | n               |
      | key:ref:0 | attr:name:Alice |

    When get answers of typeql write query
      """
      match
        $p isa person;
      update
        $p has name "Alice";
      """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |
    When get answers of typeql read query
      """
      match $p isa person, has name $n;
      """
    Then uniquely identify answer concepts
      | p         | n               |
      | key:ref:0 | attr:name:Alice |


  Scenario: Has for attribute subtypes can be updated without affecting sub and supertypes
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
        person owns first-name @card(0..), owns surname @card(0..), owns old-surname;
        attribute first-name sub name;
        attribute surname sub name;
        attribute old-surname sub surname;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $p isa person, has ref 0,
        has name "Alice Morgan",
        has first-name "Alice",
        has surname "Morgan",
        has old-surname "Cooper";
      """
    Given get answers of typeql read query
      """
      match $p isa person, has name $n;
      """
    Given uniquely identify answer concepts
      | p         | n                         |
      | key:ref:0 | attr:name:"Alice Morgan"  |
      | key:ref:0 | attr:first-name:"Alice"   |
      | key:ref:0 | attr:surname:"Morgan"     |
      | key:ref:0 | attr:old-surname:"Cooper" |

    When get answers of typeql write query
      """
      match
        $p isa person;
      update
        $p has name "Bob Marley";
      """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |
    When get answers of typeql read query
      """
      match $p isa person, has name $n;
      """
    Then uniquely identify answer concepts
      | p         | n                         |
      | key:ref:0 | attr:name:"Bob Marley"    |
      | key:ref:0 | attr:first-name:"Alice"   |
      | key:ref:0 | attr:surname:"Morgan"     |
      | key:ref:0 | attr:old-surname:"Cooper" |

    When get answers of typeql write query
      """
      match
        $p isa person;
      update
        $p has first-name "Bob";
      """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |
    When get answers of typeql read query
      """
      match $p isa person, has name $n;
      """
    Then uniquely identify answer concepts
      | p         | n                         |
      | key:ref:0 | attr:name:"Bob Marley"    |
      | key:ref:0 | attr:first-name:"Bob"     |
      | key:ref:0 | attr:surname:"Morgan"     |
      | key:ref:0 | attr:old-surname:"Cooper" |

    When get answers of typeql write query
      """
      match
        $p isa person;
      update
        $p has surname "Marley";
      """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |
    When get answers of typeql read query
      """
      match $p isa person, has name $n;
      """
    Then uniquely identify answer concepts
      | p         | n                         |
      | key:ref:0 | attr:name:"Bob Marley"    |
      | key:ref:0 | attr:first-name:"Bob"     |
      | key:ref:0 | attr:surname:"Marley"     |
      | key:ref:0 | attr:old-surname:"Cooper" |

    When get answers of typeql write query
      """
      match
        $p isa person;
      update
        $p has old-surname "Morgan";
      """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |
    When get answers of typeql read query
      """
      match $p isa person, has name $n;
      """
    Then uniquely identify answer concepts
      | p         | n                         |
      | key:ref:0 | attr:name:"Bob Marley"    |
      | key:ref:0 | attr:first-name:"Bob"     |
      | key:ref:0 | attr:surname:"Marley"     |
      | key:ref:0 | attr:old-surname:"Morgan" |

    When get answers of typeql write query
      """
      insert
        $n isa surname "Cruise";
      match
        $p isa person;
      update
        $p has $n;
      """
    Then uniquely identify answer concepts
      | p         | n                     |
      | key:ref:0 | attr:surname:"Cruise" |
    When get answers of typeql read query
      """
      match $p isa person, has name $n;
      """
    Then uniquely identify answer concepts
      | p         | n                         |
      | key:ref:0 | attr:name:"Bob Marley"    |
      | key:ref:0 | attr:first-name:"Bob"     |
      | key:ref:0 | attr:surname:"Cruise"     |
      | key:ref:0 | attr:old-surname:"Morgan" |


  Scenario: Update queries can only use bound variables with 'has'
    Then typeql write query; fails with a message containing: "variable 'p' referenced in the update stage is unavailable"
      """
      update
        $p has name "Bob";
      """
    When transaction closes

    When connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      insert
        $p isa person, has ref 0, has name "Alice";
      update
        $p has name "Bob";
      """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |
    When get answers of typeql read query
      """
      match $p isa person, has name $n;
      """
    Then uniquely identify answer concepts
      | p         | n             |
      | key:ref:0 | attr:name:Bob |


  Scenario: Update queries are validated similarly to insert queries and do not allow creating abstract has instances
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
        name @abstract;
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "empty-set for some variable"
      """
      insert
        $p isa person, has ref 0;
      update
        $p has name "Bob";
      """
    When transaction closes

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
        person owns first-name;
        attribute first-name sub name;
      """
    When transaction commits

    When connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "empty-set for some variable"
      """
      insert
        $p isa person, has ref 0;
      update
        $p has name "Bob";
      """
    When transaction closes

    When connection open write transaction for database: typedb
    When typeql write query
      """
      insert
        $p isa person, has ref 0;
      update
        $p has first-name "Bob";
      """
    When get answers of typeql read query
      """
      match $p isa person, has name $n;
      """
    Then uniquely identify answer concepts
      | p         | n                   |
      | key:ref:0 | attr:first-name:Bob |


  Scenario: Dependent attributes are not preserved if they are no longer owned after updates
    When typeql write query
      """
      insert
        $r0 isa ref 0;
        $n0 isa name "Alice";
        $r1 isa ref 1;
        $n1 isa name "Bob";
        $p isa person, has $r0, has $n0;
      update
        $p has $r1, has $n1;
      """
    When get answers of typeql read query
      """
      match $p isa person, has name $n;
      """
    Then uniquely identify answer concepts
      | p         | n             |
      | key:ref:1 | attr:name:Bob |
    When get answers of typeql read query
      """
      match
        attribute $t;
        $a isa $t;
      """
    Then uniquely identify answer concepts
      | t          | a             |
      | label:ref  | attr:ref:0    |
      | label:ref  | attr:ref:1    |
      | label:name | attr:name:Bob |

    When typeql write query
      """
      match
        $p1 isa person, has ref 1, has name $n1;
      insert
        $r2 isa ref 2;
        $n2 isa name "Charlie";
        $p3 isa person, has ref 3, has $n1;
      update
        $p1 has $r2, has $n2;
      """
    When get answers of typeql read query
      """
      match $p isa person, has name $n;
      """
    Then uniquely identify answer concepts
      | p         | n                 |
      | key:ref:3 | attr:name:Bob     |
      | key:ref:2 | attr:name:Charlie |
    When get answers of typeql read query
      """
      match
        attribute $t;
        $a isa $t;
      """
    Then uniquely identify answer concepts
      | t          | a                 |
      | label:ref  | attr:ref:0        |
      | label:ref  | attr:ref:1        |
      | label:ref  | attr:ref:2        |
      | label:ref  | attr:ref:3        |
      | label:name | attr:name:Bob     |
      | label:name | attr:name:Charlie |
    When transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        attribute $t;
        $a isa $t;
      """
    Then uniquely identify answer concepts
      | t          | a                 |
      | label:ref  | attr:ref:0        |
      | label:ref  | attr:ref:1        |
      | label:ref  | attr:ref:2        |
      | label:ref  | attr:ref:3        |
      | label:name | attr:name:Bob     |
      | label:name | attr:name:Charlie |

  #######################
  # LINKS (ROLEPLAYING) #
  #######################

  Scenario: Update queries cannot update non-existing roles
    Then typeql write query; fails with a message containing: "Role label not found 'father'"
      """
      insert
        $f isa person, has ref 0;
        $p isa parentship;
      update
        $p links (father: $f);
      """



  # TODO



  Scenario: Update queries can only use bound variables with 'links'
    Then typeql write query; fails with a message containing: "referenced in the update stage is unavailable"
      """
      update
        $p links (parent: $f);
      """
    When transaction closes

    When connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "variable 'p' referenced in the update stage is unavailable"
      """
      insert
        $f isa person, has ref 0;
      update
        $p links (parent: $f);
      """
    When transaction closes

    When connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "variable 'p' referenced in the update stage is unavailable"
      """
      insert
        $f isa person, has ref 0;
      update
        $p isa parentship, links (parent: $f);
      """
    When transaction closes

    When connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "variable 'f' referenced in the update stage is unavailable"
      """
      insert
        $p isa parentship, has ref 15;
      update
        $p links (parent: $f);
      """
    When transaction closes

    When connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      insert
        $f isa person, has ref 0;
        $p isa parentship;
      update
        $p links (parent: $f);
      select $f;
      """
    Then uniquely identify answer concepts
      | f         |
      | key:ref:0 |


  Scenario: Update queries are validated similarly to insert queries and do not allow creating abstract links instances
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
        friendship relates friend @abstract;
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "Constraint '@abstract' has been violated"
      """
      insert
        $p isa person, has ref 0;
        $f isa friendship, has ref 0;
      update
        $f links (friend: $p);
      """
    When transaction closes

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
        person plays best-friendship:best-friend;
        relation best-friendship relates best-friend as friend, sub friendship;
      """
    When transaction commits

    When connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "Constraint '@abstract' has been violated"
      """
      insert
        $p isa person, has ref 0;
        $f isa friendship, has ref 0;
      update
        $f links (friend: $p);
      """
    When transaction closes

    When connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "Constraint '@abstract' has been violated"
      """
      insert
        $p isa person, has ref 0;
        $f isa best-friendship, has ref 0;
      update
        $f links (friend: $p);
      """
    When transaction closes

    When connection open write transaction for database: typedb
    When typeql write query
      """
      insert
        $p isa person, has ref 0;
        $f isa best-friendship, has ref 0;
      update
        $f links (best-friend: $p);
      """
    When get answers of typeql read query
      """
      match $f isa friendship, links (friend: $p);
      """
    Then uniquely identify answer concepts
      | p         | f         |
      | key:ref:0 | key:ref:0 |
    When transaction commits

    When connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
        person plays eternal-friendship:eternal-friend;
        relation eternal-friendship relates eternal-friend as best-friend, sub best-friendship;
      """
    When transaction commits

    When connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "Constraint '@abstract' has been violated"
      """
      insert
        $p isa person, has ref 1;
        $f isa eternal-friendship, has ref 1;
      update
        $f links (best-friend: $p);
      """
    When transaction closes

    When connection open write transaction for database: typedb
    When typeql write query
      """
      insert
        $p isa person, has ref 1;
        $f isa eternal-friendship, has ref 1;
      update
        $f links (eternal-friend: $p);
      """
    When get answers of typeql read query
      """
      match $f isa friendship, links (friend: $p);
      """
    Then uniquely identify answer concepts
      | p         | f         |
      | key:ref:0 | key:ref:0 |
      | key:ref:1 | key:ref:1 |
    When transaction commits

  ###############################
  # COMBINATIONS AND EDGE CASES #
  ###############################

  Scenario: Update on an empty match does nothing
    When get answers of typeql write query
      """
      match
        $p isa person;
      update
        $p has name "Bob";
      """
    Then answer size is: 0


  Scenario: updating an anonymous variable errors
    Then typeql write query; fails with a message containing: "anonymous"
      """
      update
        $_ has $_;
      """
    When transaction closes

    When connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "anonymous"
      """
      insert
        $p isa person, has ref 0, has name "John";
      update
        $p has $_;
      """
    When transaction closes

    When connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "anonymous"
      """
      insert
        $n isa name "John";
      update
        $_ has $n;
      """
    When transaction closes

    When connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "anonymous"
      """
      update
        $_ links (parent: $_);
      """
    When transaction closes

    When connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "anonymous"
      """
      insert
        $p isa parentship;
      update
        $p links (parent: $_);
      """
    When transaction closes

    When connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "anonymous"
      """
      insert
        $p isa person, has ref 0;
      update
        $_ links (parent: $p);
      """


  Scenario: Update queries can update multiple 'has'es in a single query
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
        person owns first-name, owns surname;
        attribute first-name sub name;
        attribute surname sub name;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
        $p0 isa person, has ref 0,
          has name "Alice Morgan",
          has first-name "Alice",
          has surname "Morgan";
        $p1 isa person, has ref 1,
          has name "Bob Marley",
          has first-name "Bob",
          has surname "Marley";
      """
    Given get answers of typeql read query
      """
      match $p isa person, has name $n;
      """
    Given uniquely identify answer concepts
      | p         | n                        |
      | key:ref:0 | attr:name:"Alice Morgan" |
      | key:ref:0 | attr:first-name:"Alice"  |
      | key:ref:0 | attr:surname:"Morgan"    |
      | key:ref:1 | attr:name:"Bob Marley"   |
      | key:ref:1 | attr:first-name:"Bob"    |
      | key:ref:1 | attr:surname:"Marley"    |


    When get answers of typeql write query
      """
      match
        $p isa person, has first-name "Alice";
      update
        $p has surname "Cooper", has ref 20;
      """
    Then uniquely identify answer concepts
      | p          |
      | key:ref:20 |
    When get answers of typeql read query
      """
      match $p isa person, has name $n;
      """
    Then uniquely identify answer concepts
      | p          | n                        |
      | key:ref:20 | attr:name:"Alice Morgan" |
      | key:ref:20 | attr:first-name:"Alice"  |
      | key:ref:20 | attr:surname:"Cooper"    |
      | key:ref:1  | attr:name:"Bob Marley"   |
      | key:ref:1  | attr:first-name:"Bob"    |
      | key:ref:1  | attr:surname:"Marley"    |

    When get answers of typeql write query
      """
      match
        $p isa person;
      update
        $p has first-name "Charlie", has name "404";
      """
    Then uniquely identify answer concepts
      | p          |
      | key:ref:20 |
      | key:ref:1  |
    When get answers of typeql read query
      """
      match $p isa person, has name $n;
      """
    Then uniquely identify answer concepts
      | p          | n                         |
      | key:ref:20 | attr:name:"404"           |
      | key:ref:20 | attr:first-name:"Charlie" |
      | key:ref:20 | attr:surname:"Cooper"     |
      | key:ref:1  | attr:name:"404"           |
      | key:ref:1  | attr:first-name:"Charlie" |
      | key:ref:1  | attr:surname:"Marley"     |

    When get answers of typeql write query
      """
      match
        $p isa person, has name "404";
      update
        $p has first-name "David";
        $p has name "Unknown";
      """
    Then uniquely identify answer concepts
      | p          |
      | key:ref:20 |
      | key:ref:1  |
    When get answers of typeql read query
      """
      match $p isa person, has name $n;
      """
    Then uniquely identify answer concepts
      | p          | n                       |
      | key:ref:20 | attr:name:"Unknown"     |
      | key:ref:20 | attr:first-name:"David" |
      | key:ref:20 | attr:surname:"Cooper"   |
      | key:ref:1  | attr:name:"Unknown"     |
      | key:ref:1  | attr:first-name:"David" |
      | key:ref:1  | attr:surname:"Marley"   |

    Then typeql write query; fails with a message containing: "Constraint '@unique' has been violated"
      """
      match
        $p isa person;
      update
        $p has first-name "Elon";
        $p has ref 0;
      """


    # TODO: multiple links edges

    # TODO: has + links edges in one query

