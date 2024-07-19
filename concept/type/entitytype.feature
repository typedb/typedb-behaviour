# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Concept Entity Type

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection reset database: typedb
    Given connection open schema transaction for database: typedb

########################
# entity type common
########################

  Scenario: Root entity type cannot be deleted
    Then delete entity type: entity; fails

  Scenario: Root entity type cannot be renamed
    Then entity(entity) set label: superentity; fails

  Scenario: Cyclic entity type hierarchies are disallowed
    When create entity type: ent0
    When create entity type: ent1
    When entity(ent1) set supertype: ent0
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(ent1) set supertype: ent1; fails
    Then entity(ent0) set supertype: ent1; fails

  Scenario: Entity types can be created
    When create entity type: person
    Then entity(person) exists
    Then entity(person) get supertype: entity
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) exists
    Then entity(person) get supertype: entity

  Scenario: Entity types cannot be redeclared
    When create entity type: person
    Then entity(person) exists
    Then create entity type: person; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) exists
    Then create entity type: person; fails

  Scenario: Entity types can be deleted
    When create entity type: person
    Then entity(person) exists
    When create entity type: company
    Then entity(company) exists
    When delete entity type: company
    Then entity(company) does not exist
    Then entity(entity) get subtypes do not contain:
      | company |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) exists
    Then entity(company) does not exist
    Then entity(entity) get subtypes do not contain:
      | company |
    When delete entity type: person
    Then entity(person) does not exist
    Then entity(entity) get subtypes do not contain:
      | person  |
      | company |
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) does not exist
    Then entity(company) does not exist
    Then entity(entity) get subtypes do not contain:
      | person  |
      | company |

    # TODO: Move all "create new instance" into validation?
#  Scenario: Entity types that have instances cannot be deleted
#    When create entity type: person
#    When transaction commits
#    When connection open write transaction for database: typedb
#    When $x = entity(person) create new instance
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then delete entity type: person; fails

  Scenario: Entity types can change labels
    When create entity type: person
    Then entity(person) get name: person
    When entity(person) set label: horse
    Then entity(person) does not exist
    Then entity(horse) exists
    Then entity(horse) get name: horse
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(horse) get name: horse
    When entity(horse) set label: animal
    Then entity(horse) does not exist
    Then entity(animal) exists
    Then entity(animal) get name: animal
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(animal) exists
    Then entity(animal) get name: animal

  Scenario: Entity types can be subtypes of other entity types
    When create entity type: man
    When create entity type: woman
    When create entity type: person
    When create entity type: cat
    When create entity type: animal
    When entity(man) set supertype: person
    When entity(woman) set supertype: person
    When entity(person) set supertype: animal
    When entity(cat) set supertype: animal
    Then entity(man) get supertype: person
    Then entity(woman) get supertype: person
    Then entity(person) get supertype: animal
    Then entity(cat) get supertype: animal
    Then entity(man) get supertypes contain:
      | entity |
      | person |
      | animal |
    Then entity(woman) get supertypes contain:
      | entity |
      | person |
      | animal |
    Then entity(person) get supertypes contain:
      | entity |
      | animal |
    Then entity(cat) get supertypes contain:
      | entity |
      | animal |
    Then entity(man) get subtypes is empty
    Then entity(woman) get subtypes is empty
    Then entity(person) get subtypes contain:
      | man   |
      | woman |
    Then entity(cat) get subtypes is empty
    Then entity(animal) get subtypes contain:
      | cat    |
      | person |
      | man    |
      | woman  |
    Then entity(entity) get subtypes contain:
      | animal |
      | cat    |
      | person |
      | man    |
      | woman  |
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(man) get supertype: person
    Then entity(woman) get supertype: person
    Then entity(person) get supertype: animal
    Then entity(cat) get supertype: animal
    Then entity(man) get supertypes contain:
      | entity |
      | person |
      | animal |
    Then entity(woman) get supertypes contain:
      | entity |
      | person |
      | animal |
    Then entity(person) get supertypes contain:
      | entity |
      | animal |
    Then entity(cat) get supertypes contain:
      | entity |
      | animal |
    Then entity(man) get subtypes is empty
    Then entity(woman) get subtypes is empty
    Then entity(person) get subtypes contain:
      | man   |
      | woman |
    Then entity(cat) get subtypes is empty
    Then entity(animal) get subtypes contain:
      | cat    |
      | person |
      | man    |
      | woman  |
    Then entity(entity) get subtypes contain:
      | animal |
      | cat    |
      | person |
      | man    |
      | woman  |

  Scenario: Entity types cannot subtype itself
    When create entity type: person
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) set supertype: person; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    Then entity(person) set supertype: person; fails

  Scenario: Entity types cannot change root's supertype
    When create entity type: person
    Then entity(entity) set supertype: person; fails
    Then entity(entity) set supertype: entity; fails
    Then entity(entity) get supertypes is empty

########################
# @annotations common
########################

  Scenario Outline: Root entity type cannot set or unset @<annotation>
    Then entity(entity) set annotation: @<annotation>; fails
    Then entity(entity) unset annotation: @<annotation-category>; fails
    Examples:
      | annotation | annotation-category |
      | abstract   | abstract            |

  Scenario Outline: Entity type can set and unset @<annotation>
    When create entity type: person
    When entity(person) set annotation: @<annotation>
    Then entity(person) get annotations contain: @<annotation>
    Then entity(person) get annotation categories contain: @<annotation-category>
    Then entity(person) get declared annotations contain: @<annotation>
    When entity(person) unset annotation: @<annotation-category>
    Then entity(person) get annotations do not contain: @<annotation>
    Then entity(person) get annotation categories do not contain: @<annotation-category>
    Then entity(person) get declared annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get annotations do not contain: @<annotation>
    Then entity(person) get annotation categories do not contain: @<annotation-category>
    Then entity(person) get declared annotations do not contain: @<annotation>
    When entity(person) set annotation: @<annotation>
    Then entity(person) get annotations contain: @<annotation>
    Then entity(person) get annotation categories contain: @<annotation-category>
    Then entity(person) get declared annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get annotations contain: @<annotation>
    Then entity(person) get annotation categories contain: @<annotation-category>
    Then entity(person) get declared annotations contain: @<annotation>
    Examples:
      | annotation | annotation-category |
      | abstract   | abstract            |

  Scenario Outline: Entity type can unset not set @<annotation>
    When create entity type: person
    Then entity(person) get annotations do not contain: @<annotation>
    Then entity(person) get declared annotations do not contain: @<annotation>
    When entity(person) unset annotation: @<annotation-category>
    Then entity(person) get annotations do not contain: @<annotation>
    Then entity(person) get declared annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get annotations do not contain: @<annotation>
    Then entity(person) get declared annotations do not contain: @<annotation>
    When entity(person) unset annotation: @<annotation-category>
    Then entity(person) get annotations do not contain: @<annotation>
    Then entity(person) get declared annotations do not contain: @<annotation>
    Examples:
      | annotation | annotation-category |
      | abstract   | abstract            |

    # TODO: Uncomment this test and when there appear inherited annotations (abstract is not inherited)
#  Scenario Outline: Entity type cannot set or unset inherited @<annotation>
#    When create entity type: person
#    When entity(person) set annotation: @<annotation>
#    When create entity type: player
#    When entity(player) set supertype: person
#    Then entity(person) get annotations contain: @<annotation>
#    Then entity(person) get declared annotations contain: @<annotation>
#    Then entity(player) get annotations contain: @<annotation>
#    Then entity(player) get declared annotations do not contain: @<annotation>
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then entity(person) get annotations contain: @<annotation>
#    Then entity(person) get declared annotations contain: @<annotation>
#    Then entity(player) get annotations contain: @<annotation>
#    Then entity(player) get declared annotations do not contain: @<annotation>
#    When entity(player) set annotation: @<annotation>
#    Then transaction commits; fails
#    When connection open schema transaction for database: typedb
#    Then entity(person) get annotations contain: @<annotation>
#    Then entity(person) get declared annotations contain: @<annotation>
#    Then entity(player) get annotations contain: @<annotation>
#    Then entity(player) get declared annotations do not contain: @<annotation>
#    Then entity(player) unset annotation: @<annotation-category>; fails
#    When connection open schema transaction for database: typedb
#    Then entity(person) get annotations contain: @<annotation>
#    Then entity(person) get declared annotations contain: @<annotation>
#    Then entity(player) get annotations contain: @<annotation>
#    Then entity(player) get declared annotations do not contain: @<annotation>
#    Examples:
#      | annotation | annotation-category |
#      |            |                     |

    # TODO: Uncomment this test and when there appear inherited annotations (abstract is not inherited)
#  Scenario Outline: Entity type cannot set supertype with the same @<annotation> until it is explicitly unset from type
#    When create entity type: person
#    When entity(person) set annotation: @<annotation>
#    Then entity(person) get annotations contain: @<annotation>
#    Then entity(person) get declared annotations contain: @<annotation>
#    When create entity type: player
#    When entity(player) set annotation: @<annotation>
#    Then entity(player) get annotations contain: @<annotation>
#    Then entity(player) get declared annotations contain: @<annotation>
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then entity(person) get annotations contain: @<annotation>
#    Then entity(person) get declared annotations contain: @<annotation>
#    Then entity(player) get annotations contain: @<annotation>
#    Then entity(player) get declared annotations contain: @<annotation>
#    When entity(player) set supertype: person
#    Then entity(person) get annotations contain: @<annotation>
#    Then entity(person) get declared annotations contain: @<annotation>
#    Then entity(player) get annotations contain: @<annotation>
#    Then entity(player) get declared annotations contain: @<annotation>
#    Then transaction commits; fails
#    When connection open schema transaction for database: typedb
#    Then entity(person) get annotations contain: @<annotation>
#    Then entity(person) get declared annotations contain: @<annotation>
#    Then entity(player) get annotations contain: @<annotation>
#    Then entity(player) get declared annotations contain: @<annotation>
#    When entity(player) set supertype: person
#    When entity(player) unset annotation: @<annotation-category>
#    Then entity(player) get annotations contain: @<annotation>
#    Then entity(player) get declared annotations do not contain: @<annotation>
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then entity(person) get annotations contain: @<annotation>
#    Then entity(person) get declared annotations contain: @<annotation>
#    Then entity(player) get annotations contain: @<annotation>
#    Then entity(player) get declared annotations do not contain: @<annotation>
#    Examples:
#      | annotation | annotation-category |
#      |            |                     |

    # TODO: Uncomment this test and when there appear inherited annotations (abstract is not inherited)
#  Scenario Outline: Entity type loses inherited @<annotation> if supertype is unset
#    When create entity type: person
#    When entity(person) set annotation: @<annotation>
#    When create entity type: player
#    When entity(player) set supertype: person
#    Then entity(person) get annotations contain: @<annotation>
#    Then entity(player) get annotations contain: @<annotation>
#    When entity(player) set supertype: entity
#    Then entity(person) get annotations contain: @<annotation>
#    Then entity(player) get annotations do not contain: @<annotation>
#    When entity(player) set supertype: person
#    Then entity(person) get annotations contain: @<annotation>
#    Then entity(player) get annotations contain: @<annotation>
#    Then entity(player) get declared annotations do not contain: @<annotation>
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then entity(person) get annotations contain: @<annotation>
#    Then entity(player) get annotations contain: @<annotation>
#    Then entity(player) get declared annotations do not contain: @<annotation>
#    When entity(player) set supertype: entity
#    Then entity(person) get annotations contain: @<annotation>
#    Then entity(player) get annotations do not contain: @<annotation>
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then entity(person) get annotations contain: @<annotation>
#    Then entity(player) get annotations do not contain: @<annotation>
#    Examples:
#      | annotation |
#      |     |

  # TODO: Uncomment this test and when there appear inherited annotations (abstract is not inherited)
#  Scenario Outline: Entity type cannot set redundant duplicated @<annotation> while inheriting it
#    When create entity type: person
#    When entity(person) set annotation: @<annotation>
#    When create entity type: player
#    When entity(player) set supertype: person
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When entity(player) set annotation: @<annotation>
#    Then transaction commits; fails
#    When connection open schema transaction for database: typedb
#    When entity(player) set annotation: @<annotation>
#    When entity(person) unset annotation: @<annotation>
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then entity(person) get annotations do not contain: @<annotation>
#    Then entity(player) get annotations contain: @<annotation>
#    When entity(person) set annotation: @<annotation>
#    Then transaction commits; fails
#    Examples:
#      | annotation |

########################
# @abstract
########################

  # TODO: This test with new instances should be in entity.feature!
#  Scenario: Entity types can be set to abstract
#    When create entity type: person
#    When entity(person) set annotation: @abstract
#    When create entity type: company
#    Then entity(person) get annotations contain: @abstract
#    Then entity(person) get declared annotations contain: @abstract
#    When transaction commits
#    When connection open write transaction for database: typedb
#    Then entity(person) create new instance; fails
#    When connection open write transaction for database: typedb
#    Then entity(company) get annotations do not contain: @abstract
#    Then entity(company) get declared annotations do not contain: @abstract
#    Then entity(person) get annotations contain: @abstract
#    Then entity(person) get declared annotations contain: @abstract
#    Then entity(person) create new instance; fails
#    When transaction closes
#    When connection open schema transaction for database: typedb
#    Then entity(company) get annotations do not contain: @abstract
#    Then entity(company) get declared annotations do not contain: @abstract
#    When entity(company) set annotation: @abstract
#    Then entity(company) get annotations contain: @abstract
#    Then entity(company) get declared annotations contain: @abstract
#    When transaction commits
#    When connection open write transaction for database: typedb
#    Then entity(company) create new instance; fails
#    When connection open write transaction for database: typedb
#    Then entity(company) get annotations contain: @abstract
#    Then entity(company) create new instance; fails

  Scenario: Entity types can be set to abstract
    When create entity type: person
    When entity(person) set annotation: @abstract
    When create entity type: company
    Then entity(person) get annotations contain: @abstract
    Then entity(person) get declared annotations contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(company) get annotations do not contain: @abstract
    Then entity(person) get annotations contain: @abstract
    Then entity(company) get declared annotations do not contain: @abstract
    Then entity(person) get declared annotations contain: @abstract
    When entity(company) set annotation: @abstract
    Then entity(company) get annotations contain: @abstract
    Then entity(company) get declared annotations contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(company) get annotations contain: @abstract
    Then entity(company) get declared annotations contain: @abstract

    # TODO: Move to entity.feature or schema/data-validation?
#  Scenario: Entity types can be set to abstract when a subtype has instances
#    When create entity type: person
#    When create entity type: player
#    When entity(player) set supertype: person
#    Then transaction commits
#    When connection open write transaction for database: typedb
#    When $m = entity(player) create new instance
#    Then transaction commits
#    When connection open schema transaction for database: typedb
#    Then entity(person) set annotation: @abstract
#    Then transaction commits
#    When connection open read transaction for database: typedb
#    Then entity(person) get annotations contain: @abstract
#    Then entity(person) get declared annotations contain: @abstract
#    Then entity(player) get annotations do not contain: @abstract
#    Then entity(player) get declared annotations do not contain: @abstract

#  TODO: Make it only for typeql
#  Scenario: Entity cannot set @abstract annotation with arguments
#    When create entity type: person
#    Then entity(person) set annotation: @abstract(); fails
#    Then entity(person) set annotation: @abstract(1); fails
#    Then entity(person) set annotation: @abstract(1, 2); fails
#    Then entity(person) get annotations is empty
#    Then entity(person) get declared annotations is empty
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then entity(person) get annotations is empty
#    Then entity(person) get declared annotations is empty

  Scenario: Entity type can reset @abstract annotation
    When create entity type: person
    When entity(person) set annotation: @abstract
    Then entity(person) get annotations contain: @abstract
    Then entity(person) get declared annotations contain: @abstract
    When entity(person) set annotation: @abstract
    Then entity(person) get annotations contain: @abstract
    Then entity(person) get declared annotations contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get annotations contain: @abstract
    Then entity(person) get declared annotations contain: @abstract

  Scenario: Entity types can subtype non abstract entity types
    When create entity type: person
    When create entity type: player
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get annotations do not contain: @abstract
    Then entity(person) get declared annotations do not contain: @abstract
    When entity(player) set supertype: person
    Then entity(player) get supertypes contain:
      | person |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(player) get supertypes contain:
      | person |

  Scenario: Entity type cannot inherit @abstract annotation, but can set it being a subtype
    When create entity type: person
    When entity(person) set annotation: @abstract
    Then entity(person) get annotations contain: @abstract
    Then entity(person) get declared annotations contain: @abstract
    When create entity type: player
    When entity(player) set supertype: person
    Then entity(person) get annotations contain: @abstract
    Then entity(person) get declared annotations contain: @abstract
    Then entity(player) get annotations do not contain: @abstract
    Then entity(player) get declared annotations do not contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get annotations contain: @abstract
    Then entity(person) get declared annotations contain: @abstract
    Then entity(player) get annotations do not contain: @abstract
    Then entity(player) get declared annotations do not contain: @abstract
    When entity(player) set annotation: @abstract
    Then entity(player) get annotations contain: @abstract
    Then entity(player) get declared annotations contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(player) get annotations contain: @abstract
    Then entity(player) get declared annotations contain: @abstract

  Scenario: Entity type can set @abstract annotation and then set abstract supertype
    When create entity type: person
    When entity(person) set annotation: @abstract
    Then entity(person) get annotations contain: @abstract
    Then entity(person) get declared annotations contain: @abstract
    When create entity type: player
    When entity(player) set annotation: @abstract
    Then entity(player) get annotations contain: @abstract
    Then entity(player) get declared annotations contain: @abstract
    When entity(player) set supertype: person
    Then entity(person) get annotations contain: @abstract
    Then entity(person) get declared annotations contain: @abstract
    Then entity(player) get annotations contain: @abstract
    Then entity(player) get declared annotations contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get annotations contain: @abstract
    Then entity(person) get declared annotations contain: @abstract
    Then entity(player) get annotations contain: @abstract
    Then entity(player) get declared annotations contain: @abstract
    Then entity(player) get supertype: person

  Scenario: Abstract entity type cannot set non-abstract supertype
    When create entity type: person
    Then entity(person) get annotations do not contain: @abstract
    When create entity type: player
    When entity(player) set annotation: @abstract
    Then entity(player) get annotations contain: @abstract
    Then entity(player) set supertype: person; fails
    Then entity(person) get annotations do not contain: @abstract
    Then entity(player) get annotations contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get annotations do not contain: @abstract
    Then entity(player) get annotations contain: @abstract
    Then entity(player) get supertypes do not contain:
      | person |
    Then entity(player) set supertype: person; fails
    When entity(person) set annotation: @abstract
    When entity(player) set supertype: person
    Then entity(person) get annotations contain: @abstract
    Then entity(player) get annotations contain: @abstract
    Then entity(player) get supertype: person
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get annotations contain: @abstract
    Then entity(player) get annotations contain: @abstract
    Then entity(player) get supertype: person

  Scenario: Entity type cannot set @abstract annotation while having non-abstract supertype
    When create entity type: person
    Then entity(person) get annotations do not contain: @abstract
    When create entity type: player
    When entity(player) set supertype: person
    Then entity(player) set annotation: @abstract; fails
    Then entity(person) get annotations do not contain: @abstract
    Then entity(player) get annotations do not contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get annotations do not contain: @abstract
    Then entity(player) get annotations do not contain: @abstract
    Then entity(player) set annotation: @abstract; fails
    When entity(person) set annotation: @abstract
    When entity(player) set annotation: @abstract
    Then entity(person) get annotations contain: @abstract
    Then entity(player) get annotations contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get annotations contain: @abstract
    Then entity(player) get annotations contain: @abstract
    When entity(person) unset annotation: @abstract
    Then entity(person) get annotations do not contain: @abstract
    Then entity(player) get annotations contain: @abstract
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    Then entity(person) get annotations contain: @abstract
    Then entity(player) get annotations contain: @abstract
    When entity(person) unset annotation: @abstract
    When entity(player) unset annotation: @abstract
    Then entity(person) get annotations do not contain: @abstract
    Then entity(player) get annotations do not contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get annotations do not contain: @abstract
    Then entity(player) get annotations do not contain: @abstract

########################
# not compatible @annotations: @distinct, @key, @unique, @subkey, @values, @range, @card, @cascade, @independent, @replace, @regex
########################
#  TODO: Make it only for typeql
#  Scenario: Entity type cannot have @distinct, @key, @unique, @subkey, @values, @range, @card, @cascade, @independent, @replace, and @regex annotations
#    When create entity type: person
#    Then entity(person) set annotation: @distinct; fails
#    Then entity(person) set annotation: @key; fails
#    Then entity(person) set annotation: @unique; fails
#    Then entity(person) set annotation: @subkey(LABEL); fails
#    Then entity(person) set annotation: @values(1, 2); fails
#    Then entity(person) set annotation: @range(1, 2); fails
#    Then entity(person) set annotation: @card(1..2); fails
#    Then entity(person) set annotation: @cascade; fails
#    Then entity(person) set annotation: @independent; fails
#    Then entity(person) set annotation: @replace; fails
#    Then entity(person) set annotation: @regex("val"); fails
#    Then entity(person) get annotations is empty
#    Then entity(person) get declared annotations is empty
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then entity(person) get annotations is empty
#    Then entity(person) get declared annotations is empty
