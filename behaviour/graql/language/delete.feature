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

  Background: Open connection
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | test_delete |
    Given transaction is initialised
    Given the integrity is validated

  Scenario: delete an instance using 'thing' meta label succeeds
    Given graql define
      """
      define
      person sub entity,
        plays friend,
        has name,
        key ref;
      friendship sub relation,
        relates friend,
        key ref;
      name sub attribute, datatype string;
      ref sub attribute, value long;
      """
    Given the integrity is validated

    When graql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa person, has ref 1;
      $r (friend: $x, friend: $y) isa friendship,
         has ref 2;
      $n "john" isa name;
      """
    When the integrity is validated

    Then concept identifiers are
      |      | check | value     |
      | P1   | key   | ref:0     |
      | P2   | key   | ref:1     |
      | FR   | key   | ref:2     |
      | JOHN | value | name:john |

    Then graql delete
      """
      match
        $x isa person, has ref 0;
        $r isa friendship, has ref 2;
        $n "john" isa name;
      delete
        $x isa thing; $r isa thing; $n isa thing;
      """

    Then get answers of graql query
      """
      match $x isa person; get;
      """
    Then unique identify answer concepts
      | x  |
      | P2 |

    Then get answers of graql query
      """
      match $x isa friendship; get;
      """
    Then answer size is: 0

    Then get answers of graql query
      """
      match $x isa name; get;
      """
    Then answer size is: 0


  Scenario: delete an entity instance using 'entity' meta label succeeds
    Given graql define
      """
      define
      person sub entity,
        plays friend,
        has name,
        key ref;
      friendship sub relation,
        relates friend,
        key ref;
      name sub attribute, datatype string;
      ref sub attribute, value long;
      """
    Given the integrity is validated

    When graql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa person, has ref 1;
      $r (friend: $x, friend: $y) isa friendship,
         has ref 2;
      $n "john" isa name;
      """
    When the integrity is validated

    Then concept identifiers are
      |      | check | value     |
      | P1   | key   | ref:0     |
      | P2   | key   | ref:1     |
      | FR   | key   | ref:2     |
      | JOHN | value | name:john |

    Then graql delete
      """
      match
        $r isa person, has ref 0;
      delete
        $r isa entity;
      """

    Then get answers of graql query
      """
      match $x isa person; get;
      """
    Then unique identify answer concepts
      | x  |
      | P2 |

  Scenario: delete an relation instance using 'relation' meta label succeeds
    Given graql define
      """
      define
      person sub entity,
        plays friend,
        has name,
        key ref;
      friendship sub relation,
        relates friend,
        key ref;
      name sub attribute, datatype string;
      ref sub attribute, value long;
      """
    Given the integrity is validated

    When graql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa person, has ref 1;
      $r (friend: $x, friend: $y) isa friendship,
         has ref 2;
      $n "john" isa name;
      """
    When the integrity is validated

    Then concept identifiers are
      |      | check | value     |
      | P1   | key   | ref:0     |
      | P2   | key   | ref:1     |
      | FR   | key   | ref:2     |
      | JOHN | value | name:john |

    Then graql delete
      """
      match
        $r isa friendship, has ref 2;
      delete
        $r isa relation;
      """

    Then get answers of graql query
      """
      match $x isa friendship; get;
      """
    Then answer size is: 0


  Scenario: delete an attribute instance using 'attribute' meta label succeeds
    Given graql define
      """
      define
      person sub entity,
        plays friend,
        has name,
        key ref;
      friendship sub relation,
        relates friend,
        key ref;
      name sub attribute, datatype string;
      ref sub attribute, value long;
      """
    Given the integrity is validated

    When graql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa person, has ref 1;
      $r (friend: $x, friend: $y) isa employment,
         has ref 2;
      $n "john" isa name;
      """
    When the integrity is validated

    Then concept identifiers are
      |      | check | value     |
      | P1   | key   | ref:0     |
      | P2   | key   | ref:1     |
      | FR   | key   | ref:2     |
      | JOHN | value | name:john |

    Then graql delete
      """
      match
        $r isa name; $r "john";
      delete
        $r isa attribute;
      """

    Then get answers of graql query
      """
      match $x isa name; get;
      """
    Then answer size is: 0


  Scenario: delete a role player from a relation removes the player from the relation
    Given graql define
      """
      define
      person sub entity,
        plays friend,
        has name,
        key ref;
      friendship sub relation,
        relates friend,
        key ref;
      name sub attribute, datatype string;
      ref sub attribute, value long;
      """
    Given the integrity is validated

    When graql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa person, has ref 1;
      $z isa person, has ref 2;
      $r (friend: $x, friend: $y, friend: $z) isa friendship,
         has ref 3;
      """
    When the integrity is validated

    Then concept identifiers are
      |      | check | value     |
      | P1   | key   | ref:0     |
      | P2   | key   | ref:1     |
      | P3   | key   | ref:2     |
      | FR   | key   | ref:3     |

    Then graql delete
      """
      match
        $r (friend: $x, friend: $y, friend: $z) isa friendship;
        $x isa person, has ref 0;
        $y isa person, has ref 1;
        $z isa person, has ref 2;
      delete
        $r (friend: $x);
      """

    Then get answers of graql query
      """
      match (friend: $x, friend: $y) isa friendship;
      """
    Then uniquely identify answer concepts
      | x    | y    |
      | P1   | P2   |
      | P2   | P1   |

    
  Scenario: delete a role player from a relation using meta role removes the player from the relation
    Given graql define
      """
      define
      person sub entity,
        plays friend,
        has name,
        key ref;
      friendship sub relation,
        relates friend,
        key ref;
      name sub attribute, datatype string;
      ref sub attribute, value long;
      """
    Given the integrity is validated

    When graql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa person, has ref 1;
      $z isa person, has ref 2;
      $r (friend: $x, friend: $y, friend: $z) isa friendship,
         has ref 3;
      """
    When the integrity is validated

    Then concept identifiers are
      |      | check | value     |
      | P1   | key   | ref:0     |
      | P2   | key   | ref:1     |
      | P3   | key   | ref:2     |
      | FR   | key   | ref:3     |

    Then graql delete
      """
      match
        $r (friend: $x, friend: $y, friend: $z) isa friendship;
        $x isa person, has ref 0;
        $y isa person, has ref 1;
        $z isa person, has ref 2;
      delete
        $r (role: $x);
      """

    Then get answers of graql query
      """
      match (friend: $x, friend: $y) isa friendship;
      """
    Then uniquely identify answer concepts
      | x    | y    |
      | P1   | P2   |
      | P2   | P1   |


  Scenario: delete an instance removes it from all relations
    Given graql define
      """
      define
      person sub entity,
        plays friend,
        has name,
        key ref;
      friendship sub relation,
        relates friend,
        key ref;
      ref sub attribute, value long;
      """
    Given the integrity is validated

    When graql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa person, has ref 1;
      $z isa person, has ref 2;
      $r (friend: $x, friend: $y) isa friendship, has ref 3;
      $r (friend: $x, friend: $z) isa friendship, has ref 4;
      """
    When the integrity is validated

    Then concept identifiers are
      |      | check | value     |
      | P1   | key   | ref:0     |
      | P2   | key   | ref:1     |
      | P3   | key   | ref:2     |
      | FR1  | key   | ref:3     |
      | FR2  | key   | ref:4     |

    Then graql delete
      """
      match
        $x isa person, has ref 0;
      delete
        $x isa person;
      """

    Then get answers of graql query
      """
      match $r (friend: $x) isa friendship;
      """
    Then uniquely identify answer concepts
      | r     | x    |
      | FR1   | P2   |
      | FR2   | P3   |


  Scenario: delete duplicate role players from a relation removes duplicate player from relation
    Given graql define
      """
      define
      person sub entity,
        plays friend,
        has name,
        key ref;
      friendship sub relation,
        relates friend,
        key ref;
      ref sub attribute, value long;
      """
    Given the integrity is validated

    When graql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa person, has ref 1;
      $r (friend: $x, friend: $x, friend: $y) isa friendship, has ref 2;
      """
    When the integrity is validated

    Then concept identifiers are
      |      | check | value     |
      | P1   | key   | ref:0     |
      | P2   | key   | ref:1     |
      | FR   | key   | ref:2     |

    Then graql delete
      """
      match
        $r (friend: $x, friend: $x) isa friendship;
      delete
        $r (friend: $x, friend: $x);
      """

    Then get answers of graql query
      """
      match $r (friend: $x) isa friendship;
      """
    Then uniquely identify answer concepts
      | r     | x    |
      | FR1   | P2   |


  Scenario: delete role players in multiple statements are all deleted
    Given graql define
      """
      define
      person sub entity,
        plays friend,
        has name,
        key ref;
      friendship sub relation,
        relates friend,
        key ref;
      ref sub attribute, value long;
      """
    Given the integrity is validated

    When graql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa person, has ref 1;
      $z isa person, has ref 2;
      $r (friend: $x, friend: $y, friend: $z) isa friendship, has ref 3;
      """
    When the integrity is validated

    Then concept identifiers are
      |      | check | value     |
      | P1   | key   | ref:0     |
      | P2   | key   | ref:1     |
      | P3   | key   | ref:2     |
      | FR   | key   | ref:3     |

    Then graql delete
      """
      match
        $r (friend: $x, friend: $y, friend: $z) isa friendship;
      delete
        $r (friend: $x);
        $r (friend: $y);
      """

    Then get answers of graql query
      """
      match $r (friend: $x) isa friendship;
      """
    Then uniquely identify answer concepts
      | r     | x    |
      | FR1   | P3   |


  Scenario: delete more role players than exist throws
    Given graql define
      """
      define
      person sub entity,
        plays friend,
        has name,
        key ref;
      friendship sub relation,
        relates friend,
        key ref;
      ref sub attribute, value long;
      """
    Given the integrity is validated

    When graql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa person, has ref 1;
      $r (friend: $x, friend: $y) isa friendship, has ref 2;
      """
    When the integrity is validated

    Then concept identifiers are
      |      | check | value     |
      | P1   | key   | ref:0     |
      | P2   | key   | ref:1     |
      | FR   | key   | ref:2     |

    Then graql delete throws
      """
      match
        $x isa person, has ref 0;
        $y isa person, has ref 1;
        $r (friend: $x, friend: $y) isa friendship;
      delete
        $r (friend: $x, friend: $x);
      """


  Scenario: delete all role players of relation cleans up relation instance
    Given graql define
      """
      define
      person sub entity,
        plays friend,
        has name,
        key ref;
      friendship sub relation,
        relates friend,
        key ref;
      ref sub attribute, value long;
      """
    Given the integrity is validated

    When graql insert
      """
      insert
      $x isa person, has ref 0;
      $y isa person, has ref 1;
      $r (friend: $x, friend: $y) isa friendship, has ref 2;
      """
    When the integrity is validated

    Then concept identifiers are
      |      | check | value     |
      | P1   | key   | ref:0     |
      | P2   | key   | ref:1     |
      | FR   | key   | ref:2     |

    Then graql delete
      """
      match
        $x isa person, has ref 0;
        $y isa person, has ref 1;
      delete
        $x isa person;
        $y isa person;
      """

    Then get answers of graql query
      """
      match $r isa friendship;
      """
    Then answer size is: 0


  Scenario: delete attribute ownership makes attribute invisible to owner
  Scenario: delete a role player with too-specific (downcasting) role label throws
  Scenario: delete an instance using wrong type throws
  Scenario: delete an instance using too-specific (downcasting) type throws
  Scenario: using unmatched variable in delete throws
