#
# GRAKN.AI - THE KNOWLEDGE GRAPH
# Copyright (C) 2019 Grakn Labs Ltd
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
Feature: Graql Define Query

  Background: Create a simple schema that is extensible for each scenario
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | test_define_keyspace |
    Given the schema
      | define                                                        |
      | person sub entity, plays employee, has name, key email;       |
      | employment sub relation, relates employee;                    |
      | name sub attribute, datatype string;                          |
      | email sub attribute, datatype string;                         |
    Given the KB is valid


  Scenario: define a subtype creates a type
    Given the schema
      | define dog sub entity; |
    Given the KB is valid
    When executing
      | match $x type dog; get; |
    # do we want to also check the number of answers
    Then answers have concepts labeled
      | x   |
      | dog |


  Scenario: define subtype creates child of supertype
    Given the schema
      | define child sub person;  |
    Given the KB is valid

    When executing
      | match $x sub person; get; |
    Then answers have concepts labeled
      | x      |
      | person |
      | child  |

  Scenario: define entity subtype inherits 'plays' from supertypes
    Given the schema
      | define child sub person; |
    Given the KB is valid

    When executing
      | match $x plays employee; get; |

    Then answers have concepts labeled
      | x      |
      | person |
      | child  |


  Scenario: define entity subtype inherits 'has' from supertypes
    Given the schema
      | define child sub person; |
    Given the KB is valid

    When executing
      | match $x has name; get; |

    Then answers have concepts labeled
      | x      |
      | person |
      | child  |


  Scenario: define entity inherits 'key' from supertypes
    Given the schema
      | define child sub person; |
    Given the KB is valid

    When executing
      | match $x key email; get; |

    Then answers have concepts labeled
      | x      |
      | person |
      | child  |


  @ignore
  # re-enable when 'relates' is inherited
  Scenario: define relation subtype inherits 'relates' from supertypes without role subtyping
    Given the schema
      | define part-time-employment sub employment; |
    Given the KB is valid

    When executing
      | match $x relates employee; get; |

    Then answers have concepts labeled
      | x                    |
      | employment           |
      | part-time-employment |


  @ignore
  # re-enable when 'relates' is bound to a relation and blockable
  Scenario: define relation subtype with role subtyping blocks parent role
    Given the schema
      | define part-time-employment sub employment, relates part-timer as employee; |
    Given the KB is valid

    When executing
      | match $x relates employee; get; |
    Then answers have concepts labeled
      | x                    |
      | employment           |
      | part-time-employment |

    # TODO - should employee role be retrieving part-timer as well?

    # Then query 1 has 2 answers
    # And answers of query 1 satisfy: match $x sub employment; get;


  Scenario: define relation subtype inherits 'plays' from supertypes
  Scenario: define relation subtype inherits 'has' from supertypes
  Scenario: define relation subtype inherits 'key' from supertypes


  Scenario: define attribute subtype has same datatype as supertype
    Given the schema
      | define first-name sub name;   |
    Given the KB is valid

    When executing
      | match $x datatype string; get; |
    Then answers have concepts labeled
      | x          |
      | name       |
      | first-name |
      | email      |


  Scenario: define attribute subtype inherits 'plays' from supertypes
  Scenario: define attribute subtype inherits 'has' from supertypes
  Scenario: define attribute subtype inherits 'key' from supertypes


  Scenario: define additional 'plays' is visible from all children
    Given the schema
      | define employment sub relation, relates employer; |
    Given the KB is valid

    Given the schema
      | define                             |
      | child sub person;                  |
      | person sub entity, plays employer; |
    Given the KB is valid

    When executing
      | match $x type child, plays $r; get; |

    Then answers have concepts labeled
      | x      | r                |
      | child  | employee         |
      | child  | employer         |
      | child  | @has-name-owner  |
      | child  | @key-email-owner  |

  @ignore
  # re-enable when we can query schema 'has' and 'key' with variables eg: 'match $x type ___, has key $a; get;'
  Scenario: define additional 'has' is visible from all children
    Given the schema
      | define                                     |
      | child sub person;                          |
      | phone-number sub attribute, datatype long; |
      | person sub entity, has phone-number;       |
    Given the KB is valid

    When executing
      | match $x type child, has $y; get; |

    Then answers have concepts labeled
      | x      | y            |
      | child  | name         |
      | child  | phone-number |


  @ignore
  # re-enable when we can query schema 'has' and 'key' with variables eg: 'match $x type ___, has key $a; get;'
  Scenario: define additional 'key' is visible from all children
    Given the schema
      | define                                     |
      | child sub person;                          |
      | phone-number sub attribute, datatype long; |
      | person sub entity, key phone-number;       |
    Given the KB is valid

    When executing
      | match $x type child, key $y; get; |

    Then answers have concepts labeled
      | x      | y      |
      | child  | email  |
      | child  | email  |

  @ignore
  # re-enable when we can inherit 'relates
  Scenario: define additional 'relates' is visible from all children
    Given the schema
      | define                                       |
      | part-time-employment sub employment;         |
      | employment sub relation, relates employer; |
    Given the KB is valid

    When executing
      | match $x type part-time-employment, relates $r; get; |

    Then answers have concepts labeled
      | x                     | r          |
      | part-time-employment  | employee   |
      | part-time-employment  | employer   |



  Scenario: define a type as abstract errors if has non-abstract parent types (?)

  Scenario: define a type as abstract creates an abstract type

  Scenario: define a regex on an attribute type, attribute type queryable by regex value

  Scenario: define a rule creates a rule (?)

  Scenario: define a sub-role using as is visible from children (?)


  Scenario: defining an attribute key- and owner-ship creates the implicit attribute key/ownership relation types
    When executing
      | match $x sub relation; get;  |
    Then answers have concepts labeled
      | x              |
      | relation       |
      | employment     |
      | @has-attribute |
      | @has-name      |
      | @key-attribute |
      | @key-email     |

  Scenario: implicit attribute ownerships exist in a hierarchy matching attribute hierarchy
    Given the schema
      | define first-name sub name; person sub entity, has first-name; |
    Given the data
      | $x isa person, has name $a, has first-name $b, has email $e; $a "John Hopkins"; $b "John"; $e "abc@xyz.com"; |
    Given the KB is valid

    When executing
      | match $child sub $super; $super sub @has-attribute; get;  |
    Then answers have concepts labeled
      | child           | super            |
      | @has-attribute  | @has-attribute   |
      | @has-name       | @has-attribute   |
      | @has-first-name | @has-attribute   |
      | @has-name       | @has-name        |
      | @has-first-name | @has-name        |
      | @has-first-name | @has-first-name  |
