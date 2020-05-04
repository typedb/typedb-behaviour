#
# Copyright (C) 2020 Grakn Labs
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
Feature: Graql Delete Query

  Background: Open connection and create a simple extensible schema
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | test_delete |
    Given transaction is initialised
    Given graql define
      """
      define
      person sub entity,
        plays friend,
        key name;
      friendship sub relation,
        relates friend,
        key ref;
      name sub attribute, value string;
      ref sub attribute, value long;
      """
    Given the integrity is validated

  Scenario: delete an instance using 'thing' meta label succeeds
    When graql insert
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $r (friend: $x, friend: $y) isa friendship,
         has ref 0;
      $n "John" isa name;
      """
    When the integrity is validated

    Then concept identifiers are
      |      | check | value     |
      | ALEX | key   | name:Alex |
      | BOB  | key   | name:Bob  |
      | FR   | key   | ref:0     |
      | JOHN | value | name:John |
      | nALX | value | name:Alex |
      | nBOB | value | name:Bob  |

    Then graql delete
      """
      match
        $x isa person, has name "Alex";
        $r isa friendship, has ref 0;
        $n "John" isa name;
      delete
        $x isa thing; $r isa thing; $n isa thing;
      """

    Then get answers of graql query
      """
      match $x isa person; get;
      """
    Then uniquely identify answer concept
      | x   |
      | BOB |

    Then get answers of graql query
      """
      match $x isa friendship; get;
      """
    Then answer size is: 0

    Then get answers of graql query
      """
      match $x isa name; get;
      """
    Then uniquely identify answer concepts
      | x    |
      | nALX |
      | nBOB |

  Scenario: delete an entity instance using 'entity' meta label succeeds
    When graql insert
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $r (friend: $x, friend: $y) isa friendship,
         has ref 0;
      $n "John" isa name;
      """
    When the integrity is validated

    Then concept identifiers are
      |      | check | value     |
      | ALEX | key   | name:Alex |
      | BOB  | key   | name:Bob  |
      | FR   | key   | ref:0     |
      | JOHN | value | name:John |

    Then graql delete
      """
      match
        $r isa person, has name "Alex";
      delete
        $r isa entity;
      """

    Then get answers of graql query
      """
      match $x isa person; get;
      """
    Then uniquely identify answer concepts
      | x   |
      | BOB |


  Scenario: delete a relation instance using 'relation' meta label succeeds
    When graql insert
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $r (friend: $x, friend: $y) isa friendship,
         has ref 0;
      $n "John" isa name;
      """
    When the integrity is validated

    Then concept identifiers are
      |      | check | value     |
      | ALEX | key   | name:Alex |
      | BOB  | key   | name:Bob  |
      | FR   | key   | ref:0     |
      | JOHN | value | name:John |

    Then graql delete
      """
      match
        $r isa friendship, has ref 0;
      delete
        $r isa relation;
      """

    Then get answers of graql query
      """
      match $x isa friendship; get;
      """
    Then answer size is: 0


  Scenario: delete an attribute instance using 'attribute' meta label succeeds
    When graql insert
      """
      insert
      $n "John" isa name;
      """
    When the integrity is validated

    Then concept identifiers are
      |      | check | value     |
      | JOHN | value | name:John |

    Then graql delete
      """
      match
        $r "John" isa name;
      delete
        $r isa attribute;
      """

    Then get answers of graql query
      """
      match $x isa name; get;
      """
    Then answer size is: 0


  Scenario: delete an instance using wrong type throws
    When graql insert
      """
      insert
      $x isa person, has name "Alex";
      $n "John" isa name;
      """
    When the integrity is validated

    Then graql delete throws
      """
      match
        $x isa person;
        $r isa name; $r "John";
      delete
        $r isa person;
      """


  Scenario: delete an instance using too-specific (downcasting) type throws
    When graql define
      """
      define
      special-friendship sub friendship,
        relates friend;
      """
    When graql insert
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $r (friend: $x, friend: $y) isa friendship, has ref 0;
      """
    When the integrity is validated

    Then graql delete throws
      """
      match
        $r ($x, $y) isa friendship;
      delete
        $r isa special-friendship;
      """


  Scenario: delete a role player from a relation removes the player from the relation
    When graql insert
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $z isa person, has name "Carrie";
      $r (friend: $x, friend: $y, friend: $z) isa friendship,
         has ref 0;
      """
    When the integrity is validated

    Then concept identifiers are
      |      | check | value       |
      | ALEX | key   | name:Alex   |
      | BOB  | key   | name:Bob    |
      | CAR  | key   | name:Carrie |
      | FR   | key   | ref:0       |

    Then graql delete
      """
      match
        $r (friend: $x, friend: $y, friend: $z) isa friendship;
        $x isa person, has name "Alex";
        $y isa person, has name "Bob";
        $z isa person, has name "Carrie";
      delete
        $r (friend: $x);
      """

    Then get answers of graql query
      """
      match (friend: $x, friend: $y) isa friendship; get;
      """
    Then uniquely identify answer concepts
      | x    | y    |
      | BOB  | CAR   |
      | CAR  | BOB   |


  Scenario: delete a role player from a relation using meta role removes the player from the relation
    When graql insert
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $z isa person, has name "Carrie";
      $r (friend: $x, friend: $y, friend: $z) isa friendship,
         has ref 0;
      """
    When the integrity is validated

    Then concept identifiers are
      |      | check | value       |
      | ALEX | key   | name:Alex   |
      | BOB  | key   | name:Bob    |
      | CAR  | key   | name:Carrie |
      | FR   | key   | ref:0       |

    Then graql delete
      """
      match
        $r (friend: $x, friend: $y, friend: $z) isa friendship;
        $x isa person, has name "Alex";
        $y isa person, has name "Bob";
        $z isa person, has name "Carrie";
      delete
        $r (role: $x);
      """

    Then get answers of graql query
      """
      match (friend: $x, friend: $y) isa friendship; get;
      """
    Then uniquely identify answer concepts
      | x     | y     |
      | BOB   | CAR   |
      | CAR   | BOB   |


  Scenario: delete an instance removes it from all relations
    When graql insert
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $z isa person, has name "Carrie";
      $r (friend: $x, friend: $y) isa friendship, has ref 1;
      $r2 (friend: $x, friend: $z) isa friendship, has ref 2;
      """
    When the integrity is validated

    Then concept identifiers are
      |      | check | value       |
      | ALEX | key   | name:Alex   |
      | BOB  | key   | name:Bob    |
      | CAR  | key   | name:Carrie |
      | FR1  | key   | ref:1       |
      | FR2  | key   | ref:2       |

    Then graql delete
      """
      match
        $x isa person, has name "Alex";
      delete
        $x isa person;
      """

    Then get answers of graql query
      """
      match $x isa person; get;
      """
    Then uniquely identify answer concepts
      | x    |
      | BOB  |
      | CAR  |

    Then get answers of graql query
      """
      match $r (friend: $x) isa friendship; get;
      """
    Then uniquely identify answer concepts
      | r    | x    |
      | FR1  | BOB  |
      | FR2  | CAR  |


  Scenario: delete duplicate role players from a relation removes duplicate player from relation
    When graql insert
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $r (friend: $x, friend: $x, friend: $y) isa friendship, has ref 0;
      """
    When the integrity is validated

    Then concept identifiers are
      |      | check | value     |
      | ALEX | key   | name:Alex |
      | BOB  | key   | name:Bob  |
      | FR   | key   | ref:0     |

    Then graql delete
      """
      match
        $r (friend: $x, friend: $x) isa friendship;
      delete
        $r (friend: $x, friend: $x);
      """

    Then get answers of graql query
      """
      match $r (friend: $x) isa friendship; get;
      """
    Then uniquely identify answer concepts
      | r     | x    |
      | FR    | BOB  |


  Scenario: delete one of matched duplicate role players from a relation removes only one playing
    When graql insert
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $r (friend: $x, friend: $x, friend: $y) isa friendship, has ref 0;
      """
    When the integrity is validated

    Then concept identifiers are
      |      | check | value     |
      | ALEX | key   | name:Alex |
      | BOB  | key   | name:Bob  |
      | FR   | key   | ref:0     |

    Then graql delete
      """
      match
        $r (friend: $x, friend: $x) isa friendship;
      delete
        $r (friend: $x);
      """

    Then get answers of graql query
      """
      match $r (friend: $x, friend: $y) isa friendship; get;
      """
    Then uniquely identify answer concepts
      | r     | x    | y    |
      | FR    | BOB  | ALEX |
      | FR    | ALEX | BOB  |


  # this scenario should be identical in behaviour to the above, only the match differs
  Scenario: delete one of role players from a relation removes only one duplicate
    When graql insert
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $r (friend: $x, friend: $x, friend: $y) isa friendship, has ref 0;
      """
    When the integrity is validated

    Then concept identifiers are
      |      | check | value     |
      | ALEX | key   | name:Alex |
      | BOB  | key   | name:Bob  |
      | FR   | key   | ref:0     |

    Then graql delete
      """
      match
        $r (friend: $x) isa friendship;
        $x isa person, has name "Alex";
      delete
        $r (friend: $x);
      """

    Then get answers of graql query
      """
      match $r (friend: $x, friend: $y) isa friendship; get;
      """
    Then uniquely identify answer concepts
      | r     | x    | y    |
      | FR    | BOB  | ALEX |
      | FR    | ALEX | BOB  |


  Scenario: delete role players in multiple statements are all deleted
    When graql insert
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $z isa person, has name "Carrie";
      $r (friend: $x, friend: $y, friend: $z) isa friendship, has ref 0;
      """
    When the integrity is validated

    Then concept identifiers are
      |      | check | value       |
      | ALEX | key   | name:Alex   |
      | BOB  | key   | name:Bob    |
      | CAR  | key   | name:Carrie |
      | FR   | key   | ref:0       |

    Then graql delete
      """
      match
        $r (friend: $x, friend: $y, friend: $z) isa friendship;
        $x isa person, has name "Alex";
        $y isa person, has name "Bob";
        $z isa person, has name "Carrie";
      delete
        $r (friend: $x);
        $r (friend: $y);
      """

    Then get answers of graql query
      """
      match $r (friend: $x) isa friendship; get;
      """
    Then uniquely identify answer concepts
      | r     | x    |
      | FR    | CAR  |


  Scenario: delete more role players than exist throws
    When graql insert
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $r (friend: $x, friend: $y) isa friendship, has ref 0;
      """
    When the integrity is validated

    Then graql delete throws
      """
      match
        $x isa person, has name "Alex";
        $y isa person, has name "Bob";
        $r (friend: $x, friend: $y) isa friendship;
      delete
        $r (friend: $x, friend: $x);
      """


  Scenario: delete all role players of relation cleans up relation instance
    When graql insert
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $r (friend: $x, friend: $y) isa friendship, has ref 0;
      """
    When the integrity is validated

    Then concept identifiers are
      |      | check | value     |
      | ALEX | key   | name:Alex |
      | BOB  | key   | name:Bob  |
      | FR   | key   | ref:0     |

    Then graql delete
      """
      match
        $x isa person, has name "Alex";
        $y isa person, has name "Bob";
      delete
        $x isa person;
        $y isa person;
      """

    Then get answers of graql query
      """
      match $r isa friendship; get;
      """
    Then answer size is: 0


  Scenario: delete a role player with too-specific (downcasting) role throws
    Given graql define
      """
      define
      special-friendship sub friendship,
        relates special-friend as friend;
      """
    Given the integrity is validated

    When graql insert
      """
      insert
      $x isa person, has name "Alex";
      $y isa person, has name "Bob";
      $r (friend: $x, friend: $y) isa friendship, has ref 0;
      """
    When the integrity is validated

    Then graql delete throws
      """
      match
        $x isa person, has name "Alex";
        $y isa person, has name "Bob";
        $r (friend: $x, friend: $y) isa friendship;
      delete
        $r (special-friend: $x);
      """


  Scenario: delete attribute ownership makes attribute invisible to owner
    When graql define
      """
      define
      lastname sub attribute, value string;
      person sub entity, has lastname;
      """
    When graql insert
      """
      insert
      $x isa person,
        has lastname "Smith",
        has name "Alex";
      $y isa person,
        has lastname "Smith",
        has name "John";
      """
    When the integrity is validated

    Then concept identifiers are
      |      | check | value          |
      | ALEX | key   | name:Alex      |
      | JOHN | key   | name:John      |
      | lnST | value | lastname:Smith |
      | nALX | value | name:Alex      |
      | nJHN | value | name:John      |

    Then graql delete
      """
      match
        $x isa person, has lastname $n, has name "Alex";
        $n "Smith";
      delete
        $x has lastname $n;
      """

    Then get answers of graql query
      """
      match $x isa person; get;
      """
    Then uniquely identify answer concepts
      | x     |
      | ALEX  |
      | JOHN  |

    Then get answers of graql query
      """
      match $n isa lastname; get;
      """
    Then uniquely identify answer concepts
      | n     |
      | lnST  |

    Then get answers of graql query
      """
      match $x isa person, has lastname $n; get;
      """
    Then uniquely identify answer concepts
      | x     | n      |
      | JOHN  | lnST   |


  Scenario: using unmatched variable in delete throws even without data
    Then graql delete throws
      """
      match $x isa person; delete $n isa name;
      """

  Scenario: delete complex pattern
    When graql define
      """
      define
      lastname sub attribute, value string;
      person sub entity, has lastname;
      """
    When graql insert
      """
      insert
      $x isa person,
        has lastname "Smith",
        has name "Alex";
      $y isa person,
        has lastname "Smith",
        has name "John";
      $r (friend: $x, friend: $y) isa friendship, has ref 1;
      $r1 (friend: $x, friend: $y) isa friendship, has ref 2;
      $reflexive (friend: $x, friend: $x) isa friendship, has ref 3;
      """
    When the integrity is validated

    Then concept identifiers are
      |      | check | value          |
      | ALEX | key   | name:Alex      |
      | JOHN | key   | name:John      |
      | SMTH | value | lastname:Smith |
      | nALX | value | name:Alex      |
      | nJHN | value | name:John      |
      | F1   | key   | ref:1          |
      | F2   | key   | ref:2          |
      | REFL | key   | ref:3          |

    Then graql delete
      """
      match
        $x isa person, has name "Alex", has lastname $n;
        $y isa person, has name "John", has lastname $n;
        $refl (friend: $x, friend: $x) isa friendship, has ref 3;
        $f1 (friend: $x, friend: $y) isa friendship, has ref 1;
      delete
        $x has lastname $n;
        $refl (friend: $x);
        $f1 isa friendship;
      """

    Then get answers of graql query
      """
      match $f (friend: $x) isa friendship; get;
      """
    Then uniquely identify answer concepts
      | f     | x     |
      | F2    | ALEX  |
      | F2    | JOHN  |
      | REFL  | ALEX  |

    Then get answers of graql query
      """
      match $n isa name; get;
      """
    Then uniquely identify answer concepts
      | n     |
      | nJHN  |
      | nALX  |

    Then get answers of graql query
      """
      match $x isa person, has lastname $n; get;
      """
    Then uniquely identify answer concepts
      | x     | n     |
      | JOHN  | SMTH |


  Scenario: delete key ownership throws exception
    When graql insert
      """
      insert
      $x isa person, has name "Alex";
      """
    When the integrity is validated

    Then graql delete throws
      """
      match
        $x isa person, has name $n;
        $n "Alex";
      delete
        $x has name $n;
      """