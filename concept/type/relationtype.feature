# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Concept Relation Type and Role Type

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb

########################
# relation type common
########################

  Scenario: Root relation type cannot be deleted
    Then delete relation type: relation; fails

  Scenario: Relation and role types can be created
    When create relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    Then relation(marriage) exists
    Then relation(marriage) get supertype: relation
    Then relation(marriage) get role(husband) exists
    Then relation(marriage) get role(wife) exists
    Then relation(marriage) get role(husband) get supertype: relation:role
    Then relation(marriage) get role(wife) get supertype: relation:role
    Then relation(marriage) get roles contain:
      | marriage:husband |
      | marriage:wife    |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(marriage) exists
    Then relation(marriage) get supertype: relation
    Then relation(marriage) get role(husband) exists
    Then relation(marriage) get role(wife) exists
    Then relation(marriage) get role(husband) get supertype: relation:role
    Then relation(marriage) get role(wife) get supertype: relation:role
    Then relation(marriage) get roles contain:
      | marriage:husband |
      | marriage:wife    |

  Scenario: Relation types cannot be redeclared
    When create relation type: parentship
    When relation(parentship) create role: husband
    Then relation(parentship) exists
    Then create relation type: parentship; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) exists
    Then create relation type: parentship; fails

  Scenario: Relation type cannot redeclare role types
    When create relation type: parentship
    When relation(parentship) create role: parent
    Then relation(parentship) get roles contain: parent
    Then relation(parentship) create role: parent; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) create role: parent; fails

  Scenario: Relation and role types can be deleted
    When create relation type: marriage
    When relation(marriage) create role: spouse
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When relation(parentship) delete role: parent
    Then relation(parentship) get roles do not contain:
      | parent |
    Then relation(relation) get role(role) get subtypes do not contain:
      | parentship:parent |
    When transaction commits
    When connection open schema transaction for database: typedb
    When delete relation type: parentship
    Then relation(parentship) does not exist
    Then relation(relation) get role(role) get subtypes do not contain:
      | parentship:parent |
      | parentship:child  |
    When relation(marriage) delete role: spouse
    Then relation(marriage) get roles do not contain:
      | spouse |
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    When transaction commits
    When connection open schema transaction for database: typedb
    When delete relation type: marriage
    Then relation(marriage) does not exist
    Then relation(relation) get role(role) get subtypes do not contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) does not exist
    Then relation(marriage) does not exist
    Then relation(relation) get role(role) get subtypes do not contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |

  Scenario: Relation types that have instances cannot be deleted
    When create relation type: marriage
    When relation(marriage) create role: wife
    When create entity type: person
    When entity(person) set plays: marriage:wife
    When transaction commits
    When connection open write transaction for database: typedb
    When $m = relation(marriage) create new instance
    When $a = entity(person) create new instance
    When relation $m add player for role(wife): $a
    When transaction commits
    When connection open schema transaction for database: typedb
    Then delete relation type: marriage; fails

  Scenario: Role types that have instances cannot be deleted
    When create relation type: marriage
    When relation(marriage) create role: wife
    When relation(marriage) create role: husband
    When create entity type: person
    When entity(person) set plays: marriage:wife
    When transaction commits
    When connection open write transaction for database: typedb
    When $m = relation(marriage) create new instance
    When $a = entity(person) create new instance
    When relation $m add player for role(wife): $a
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(marriage) delete role: wife; fails
    When connection open schema transaction for database: typedb
    Then relation(marriage) delete role: husband
    Then transaction commits

  Scenario: Relation and role types can change names
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    Then relation(parentship) get name: parentship
    Then relation(parentship) get role(parent) get name: parent
    Then relation(parentship) get role(child) get name: child
    When relation(parentship) set name: marriage
    Then relation(parentship) does not exist
    Then relation(marriage) exists
    When relation(marriage) get role(parent) set name: husband
    When relation(marriage) get role(child) set name: wife
    Then relation(marriage) get role(parent) does not exist
    Then relation(marriage) get role(child) does not exist
    Then relation(marriage) get name: marriage
    Then relation(marriage) get role(husband) get name: husband
    Then relation(marriage) get role(wife) get name: wife
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(marriage) get name: marriage
    Then relation(marriage) get role(husband) get name: husband
    Then relation(marriage) get role(wife) get name: wife
    When relation(marriage) set name: employment
    Then relation(marriage) does not exist
    Then relation(employment) exists
    When relation(employment) get role(husband) set name: employee
    When relation(employment) get role(wife) set name: employer
    Then relation(employment) get role(husband) does not exist
    Then relation(employment) get role(wife) does not exist
    Then relation(employment) get name: employment
    Then relation(employment) get role(employee) get name: employee
    Then relation(employment) get role(employer) get name: employer
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(employment) exists
    Then relation(employment) get name: employment
    Then relation(employment) get role(employee) get name: employee
    Then relation(employment) get role(employer) get name: employer

  Scenario: Relation and role types can be subtypes of other relation and role types
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set override: parent
    Then relation(fathership) get supertype: parentship
    Then relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(fathership) get role(child) get supertype: relation:role
    Then relation(fathership) get supertypes contain:
      | relation   |
      | parentship |
    Then relation(fathership) get role(father) get supertypes contain:
      | relation:role     |
      | parentship:parent |
    Then relation(fathership) get role(child) get supertypes contain:
      | relation:role |
    Then relation(parentship) get subtypes contain:
      | fathership |
    Then relation(parentship) get role(parent) get subtypes contain:
      | fathership:father |
    Then relation(parentship) get role(child) get subtypes is empty
    Then relation(relation) get subtypes contain:
      | parentship |
      | fathership |
    Then relation(relation) get role(role) get subtypes contain:
      | parentship:parent |
      | parentship:child  |
      | fathership:father |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(fathership) get supertype: parentship
    Then relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(fathership) get role(child) get supertype: relation:role
    Then relation(fathership) get supertypes contain:
      | relation   |
      | parentship |
    Then relation(fathership) get role(father) get supertypes contain:
      | relation:role     |
      | parentship:parent |
    Then relation(fathership) get role(child) get supertypes contain:
      | relation:role |
    Then relation(parentship) get subtypes contain:
      | fathership |
    Then relation(parentship) get role(parent) get subtypes contain:
      | fathership:father |
    Then relation(parentship) get role(child) get subtypes is empty
    Then relation(relation) get subtypes contain:
      | parentship |
      | fathership |
    Then relation(relation) get role(role) get subtypes contain:
      | parentship:parent |
      | parentship:child  |
      | fathership:father |
    When create relation type: father-son
    When relation(father-son) set supertype: fathership
    When relation(father-son) create role: son
    When relation(father-son) get role(son) set override: child
    Then relation(father-son) get supertype: fathership
    Then relation(father-son) get role(father) get supertype: parentship:parent
    Then relation(father-son) get role(son) get supertype: parentship:child
    Then relation(father-son) get supertypes contain:
      | relation   |
      | parentship |
      | fathership |
    Then relation(father-son) get role(father) get supertypes contain:
      | relation:role     |
      | parentship:parent |
    Then relation(father-son) get role(son) get supertypes contain:
      | relation:role    |
      | parentship:child |
    Then relation(fathership) get subtypes contain:
      | father-son |
    Then relation(fathership) get role(father) get subtypes is empty
    Then relation(fathership) get role(child) get subtypes contain:
      | father-son:son |
    Then relation(parentship) get role(parent) get subtypes contain:
      | fathership:father |
    Then relation(parentship) get role(child) get subtypes contain:
      | father-son:son |
    Then relation(relation) get subtypes contain:
      | parentship |
      | fathership |
    Then relation(relation) get role(role) get subtypes contain:
      | parentship:parent |
      | parentship:child  |
      | fathership:father |
      | father-son:son    |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(father-son) get supertype: fathership
    Then relation(father-son) get role(father) get supertype: parentship:parent
    Then relation(father-son) get role(son) get supertype: parentship:child
    Then relation(father-son) get supertypes contain:
      | relation   |
      | parentship |
      | fathership |
    Then relation(father-son) get role(father) get supertypes contain:
      | relation:role     |
      | parentship:parent |
    Then relation(father-son) get role(son) get supertypes contain:
      | relation:role    |
      | parentship:child |
    Then relation(fathership) get supertype: parentship
    Then relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(fathership) get role(child) get supertype: relation:role
    Then relation(fathership) get supertypes contain:
      | relation   |
      | parentship |
    Then relation(fathership) get role(father) get supertypes contain:
      | relation:role     |
      | parentship:parent |
    Then relation(fathership) get role(child) get supertypes contain:
      | relation:role |
    Then relation(fathership) get subtypes contain:
      | father-son |
    Then relation(fathership) get role(father) get subtypes is empty
    Then relation(fathership) get role(child) get subtypes contain:
      | father-son:son |
    Then relation(parentship) get role(parent) get subtypes contain:
      | fathership:father |
    Then relation(parentship) get role(child) get subtypes contain:
      | father-son:son |
    Then relation(relation) get subtypes contain:
      | parentship |
      | fathership |
    Then relation(relation) get role(role) get subtypes contain:
      | parentship:parent |
      | parentship:child  |
      | fathership:father |
      | father-son:son    |

  Scenario: Relation types cannot subtype itself
    When create relation type: marriage
    When relation(marriage) create role: wife
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(marriage) set supertype: marriage; fails

  Scenario: Relation types can inherit related role types
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set override: parent
    Then relation(fathership) get roles contain:
      | fathership:father |
      | parentship:child  |
    Then relation(fathership) get declared roles contain:
      | fathership:father |
    Then relation(fathership) get declared roles do not contain:
      | parentship:child |
    When transaction commits
    When connection open schema transaction for database: typedb
    When create relation type: mothership
    When relation(mothership) set supertype: parentship
    When relation(mothership) create role: mother
    When relation(mothership) get role(mother) set override: parent
    Then relation(mothership) get roles contain:
      | mothership:mother |
      | parentship:child  |
    Then relation(mothership) get declared roles contain:
      | mothership:mother |
    Then relation(mothership) get declared roles do not contain:
      | parentship:child |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get roles contain:
      | fathership:father |
      | parentship:child  |
    Then relation(fathership) get declared roles contain:
      | fathership:father |
    Then relation(fathership) get declared roles do not contain:
      | parentship:child |
    Then relation(mothership) get roles contain:
      | mothership:mother |
      | parentship:child  |
    Then relation(mothership) get declared roles contain:
      | mothership:mother |
    Then relation(mothership) get declared roles do not contain:
      | parentship:child |

  Scenario: Relation types can override inherited related role types
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set override: parent
    Then relation(fathership) get overridden role(father) exists
    Then relation(fathership) get overridden role(father) get name: parent
    Then relation(fathership) get roles do not contain:
      | parentship:parent |
    When transaction commits
    When connection open schema transaction for database: typedb
    When create relation type: mothership
    When relation(mothership) set supertype: parentship
    When relation(mothership) create role: mother
    When relation(mothership) get role(mother) set override: parent
    Then relation(mothership) get roles do not contain:
      | parentship:parent |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get roles do not contain:
      | parentship:parent |
    Then relation(mothership) get roles do not contain:
      | parentship:parent |

  Scenario: Relation types cannot redeclare inherited related role types
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    Then relation(fathership) create role: parent; fails

  Scenario: Relation types cannot override declared related role types
    When create relation type: parentship
    When relation(parentship) create role: parent
    Then relation(parentship) create role: father
    Then relation(parentship) get role(father) set override: parent; fails

  Scenario: Relation types can update existing roles override a newly defined role it inherits
    When create relation type: parentship
    When relation(parentship) create role: other-role
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(parentship) create role: parent
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set override: parent
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get overridden role(father) get name: parent

########################
# @annotations common
########################

  Scenario Outline: Relation type cannot unset @<annotation> that has not been set
    When create relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    Then relation(marriage) unset annotation: @<annotation>; fails
    Examples:
      | annotation |
      | abstract   |
      | cascade    |

  Scenario Outline: Relation type can set and unset @<annotation>
    When create relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    When relation(marriage) set annotation: @<annotation>
    Then relation(marriage) get annotations contain: @<annotation>
    When relation(marriage) unset annotation: @<annotation>
    Then relation(marriage) get annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(marriage) get annotations do not contain: @<annotation>
    When relation(marriage) set annotation: @<annotation>
    Then relation(marriage) get annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(marriage) get annotations contain: @<annotation>
    Examples:
      | annotation |
      | abstract   |
      | cascade    |

########################
# @abstract
########################

  Scenario: Relation type can be set to abstract while role types remain concrete
    When create relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    When relation(marriage) set annotation: @abstract
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    Then relation(marriage) get annotations contain: @abstract
    Then relation(marriage) get role(husband) get annotations do not contain: @abstract
    Then relation(marriage) get role(wife) get annotations do not contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get annotations do not contain: @abstract
    Then relation(parentship) get role(parent) get annotations do not contain: @abstract
    Then relation(parentship) get role(child) get annotations do not contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(marriage) get annotations contain: @abstract
    Then relation(marriage) get role(husband) get annotations do not contain: @abstract
    Then relation(marriage) get role(wife) get annotations do not contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get annotations do not contain: @abstract
    Then relation(parentship) get role(parent) get annotations do not contain: @abstract
    Then relation(parentship) get role(child) get annotations do not contain: @abstract
    Then relation(parentship) set annotation: @abstract
    Then relation(parentship) get annotations contain: @abstract
    Then relation(parentship) get role(parent) get annotations do not contain: @abstract
    Then relation(parentship) get role(child) get annotations do not contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get annotations contain: @abstract
    Then relation(parentship) get role(parent) get annotations do not contain: @abstract
    Then relation(parentship) get role(child) get annotations do not contain: @abstract

  Scenario: Relation types can be set to abstract when a subtype has instances
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set override: parent
    When relation(fathership) create role: father-child
    When relation(fathership) get role(father-child) set override: child
    When create entity type: person
    When entity(person) set plays: fathership:father
    Then transaction commits
    When connection open write transaction for database: typedb
    Then $m = relation(fathership) create new instance
    When $a = entity(person) create new instance
    When relation $m add player for role(father): $a
    Then transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) set annotation: @abstract
    Then transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get annotations contain: @abstract
# TODO: Make it only for typeql
#  Scenario: Relation type cannot set @abstract annotation with arguments
#    When create relation type: parentship
#    Then relation(parentship) set annotation: @abstract(); fails
#    Then relation(parentship) set annotation: @abstract(1); fails
#    Then relation(parentship) set annotation: @abstract(1, 2); fails
#    Then relation(parentship) get annotations is empty
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then relation(parentship) get annotations is empty

  Scenario: Relation types must have at least one role in order to commit, unless they are abstract
    When create relation type: connection
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When create relation type: connection
    When relation(connection) set annotation: @abstract
    Then transaction commits

  Scenario: Relation type can reset @abstract annotation
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) set annotation: @abstract
    Then relation(parentship) get annotations contain: @abstract
    When relation(parentship) set annotation: @abstract
    Then relation(parentship) get annotations contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get annotations contain: @abstract

  Scenario: Roles can be inherited from abstract relation types
    When create relation type: parentship
    Then relation(parentship) set annotation: @abstract
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get roles contain:
      | parentship:parent |
      | parentship:child  |
    Then relation(fathership) get declared roles do not contain:
      | fathership:parent |
      | fathership:child  |
    Then relation(fathership) get role(parent) get annotations do not contain: @abstract
    Then relation(fathership) get role(child) get annotations do not contain: @abstract

  Scenario: Relation types can subtype non abstract relation types
    When create relation type: parentship
    When relation(parentship) create role: parent
    When create relation type: fathership
    When relation(fathership) create role: father
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get annotations do not contain: @abstract
    When relation(fathership) set supertype: parentship
    Then relation(fathership) get supertypes contain:
      | parentship |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(fathership) get supertypes contain:
      | parentship |

  Scenario: Relation type cannot inherit @abstract annotation, but can set it being a subtype
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) set annotation: @abstract
    Then relation(parentship) get annotations contain: @abstract
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    Then relation(parentship) get annotations contain: @abstract
    Then relation(fathership) get annotations do not contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get annotations contain: @abstract
    Then relation(fathership) get annotations do not contain: @abstract
    When relation(fathership) set annotation: @abstract
    Then relation(fathership) get annotations contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get annotations contain: @abstract

########################
# @cascade
########################

  Scenario: Relation type can set and unset @cascade annotation
    When create relation type: parentship
    Then relation(parentship) set annotation: @cascade
    Then relation(parentship) get annotations contain: @cascade
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get annotations contain: @cascade
    When relation(parentship) unset annotation: @cascade
    Then relation(parentship) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get annotations is empty

  Scenario: Relation type can reset @cascade annotation
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) set annotation: @cascade
    Then relation(parentship) get annotations contain: @cascade
    When relation(parentship) set annotation: @cascade
    Then relation(parentship) get annotations contain: @cascade
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get annotations contain: @cascade

  Scenario: Relation types' @cascade annotation can be inherited
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) set annotation: @cascade
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    Then relation(fathership) get annotations contain: @cascade
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get annotations contain: @cascade

  Scenario: Relation type can reset inherited @cascade annotation
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) set annotation: @cascade
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    Then relation(fathership) get annotations contain: @cascade
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(fathership) set annotation: @cascade
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When create relation type: mothership
    When relation(mothership) set supertype: parentship
    Then relation(mothership) get annotations contain: @cascade
    When relation(mothership) set annotation: @cascade
    Then transaction commits; fails

  Scenario: Relation type cannot unset inherited @cascade annotation
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) set annotation: @cascade
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    Then relation(fathership) get annotations contain: @cascade
    Then relation(fathership) unset annotation: @cascade; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(fathership) get annotations contain: @cascade
    Then relation(fathership) unset annotation: @cascade; fails
    When relation(fathership) unset supertype: parentship
    Then relation(fathership) get annotations do not contain: @cascade
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get annotations do not contain: @cascade

  Scenario: Relation type cannot set @cascade annotation with arguments
    When create relation type: parentship
    Then relation(parentship) set annotation: @cascade(); fails
    Then relation(parentship) set annotation: @cascade(1); fails
    Then relation(parentship) set annotation: @cascade(1, 2); fails
    Then relation(parentship) get annotations is empty

########################
# not compatible @annotations: @distinct, @key, @unique, @subkey, @values, @range, @card, @independent, @replace, @regex
########################

  Scenario: Relation type cannot have @distinct, @key, @unique, @subkey, @values, @range, @card, @independent, @replace, and @regex annotations
    When create relation type: parentship
    When relation(parentship) create role: parent
    Then relation(parentship) set annotation: @distinct; fails
    Then relation(parentship) set annotation: @key; fails
    Then relation(parentship) set annotation: @unique; fails
    Then relation(parentship) set annotation: @subkey(LABEL); fails
    Then relation(parentship) set annotation: @values(1, 2); fails
    Then relation(parentship) set annotation: @range(1, 2); fails
    Then relation(parentship) set annotation: @card(1, 2); fails
    Then relation(parentship) set annotation: @independent; fails
    Then relation(parentship) set annotation: @replace; fails
    Then relation(parentship) set annotation: @regex("val"); fails
    Then relation(parentship) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get annotations is empty

########################
# @annotations combinations:
# @abstract, @cascade
########################

  Scenario Outline: Relation types can set @<annotation-1> and @<annotation-2> together and unset it
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) set annotation: @<annotation-1>
    When relation(parentship) set annotation: @<annotation-2>
    Then relation(parentship) get annotations contain:
      | @<annotation-1> |
      | @<annotation-2> |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get annotations contain:
      | @<annotation-1> |
      | @<annotation-2> |
    When relation(parentship) unset annotation: @<annotation-1>
    Then relation(parentship) get annotations do not contain: @<annotation-1>
    Then relation(parentship) get annotations contain: @<annotation-2>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get annotations do not contain: @<annotation-1>
    Then relation(parentship) get annotations contain: @<annotation-2>
    When relation(parentship) set annotation: @<annotation-1>
    When relation(parentship) unset annotation: @<annotation-2>
    Then relation(parentship) get annotations do not contain: @<annotation-2>
    Then relation(parentship) get annotations contain: @<annotation-1>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get annotations do not contain: @<annotation-2>
    Then relation(parentship) get annotations contain: @<annotation-1>
    When relation(parentship) unset annotation: @<annotation-1>
    Then relation(parentship) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get annotations is empty
    Examples:
      | annotation-1 | annotation-2 |
      | abstract     | cascade      |

    # Uncomment and add Examples when they appear!
#  Scenario Outline: Relation types cannot set @<annotation-1> and @<annotation-2> together for
#    When create relation type: parentship
#    When relation(parentship) create role: parent
#    When relation(parentship) set annotation: @<annotation-1>
#    When relation(parentship) set annotation: @<annotation-2>; fails
#    When connection open schema transaction for database: typedb
#    When create relation type: parentship
#    When relation(parentship) create role: parent
#    When relation(parentship) set annotation: @<annotation-2>
#    When relation(parentship) set annotation: @<annotation-1>; fails
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then relation(parentship) get annotation contain: @<annotation-2>
#    Then relation(parentship) get annotation do not contain: @<annotation-1>
#    Examples:
#      | annotation-1 | annotation-2 |

########################
# relates (roles) lists
########################

  Scenario: Relation and ordered roles can be created
    When create relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    Then relation(marriage) exists
    Then relation(marriage) get supertype: relation
    Then relation(marriage) get role(husband) exists
    Then relation(marriage) get role(husband) get ordering: unordered
    When relation(marriage) get role(husband) set ordering: ordered
    Then relation(marriage) get role(husband) get ordering: ordered
    Then relation(marriage) get role(wife) exists
    Then relation(marriage) get role(wife) get ordering: unordered
    When relation(marriage) get role(wife) set ordering: ordered
    Then relation(marriage) get role(wife) get ordering: ordered
    Then relation(marriage) get role(husband) get supertype: relation:role
    Then relation(marriage) get role(wife) get supertype: relation:role
    Then relation(marriage) get roles contain:
      | marriage:husband |
      | marriage:wife    |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(marriage) exists
    Then relation(marriage) get supertype: relation
    Then relation(marriage) get role(husband) exists
    Then relation(marriage) get role(wife) exists
    Then relation(marriage) get role(husband) get supertype: relation:role
    Then relation(marriage) get role(wife) get supertype: relation:role
    Then relation(marriage) get roles contain:
      | marriage:husband |
      | marriage:wife    |
    Then relation(marriage) get role(husband) get ordering: ordered
    Then relation(marriage) get role(wife) get ordering: ordered

  Scenario: Role can change ordering
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When relation(parentship) get role(child) set ordering: ordered
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(parentship) get role(child) get ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(parentship) get role(child) get ordering: ordered
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) get role(child) set ordering: unordered
    Then relation(parentship) get role(parent) get ordering: ordered
    Then relation(parentship) get role(child) get ordering: unordered
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get ordering: ordered
    Then relation(parentship) get role(child) get ordering: unordered

  Scenario: Role can set ordering after setting an override or an annotation
    When create relation type: parentship
    When relation(parentship) create role: parent
    When create realtion type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: fathership
    When relation(fathership) get role(father) set override: parent
    When relation(fathership) get role(father) set annotation: @card(0, 1)
    When relation(fathership) get role(father) set ordering: ordered
    Then relation(fathership) get role(father) get ordering: ordered
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get role(father) get ordering: ordered

  Scenario: Relation type cannot redeclare ordered role types
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    Then relation(parentship) get roles contain: parent
    Then relation(parentship) create role: parent; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) create role: parent; fails

  Scenario: Ordered roles can redeclare ordering
    When create relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) get role(spouse) set ordering: ordered
    Then relation(marriage) get role(spouse) get ordering: ordered
    When relation(marriage) get role(spouse) set ordering: ordered
    Then relation(marriage) get role(spouse) get ordering: ordered
    When connection open schema transaction for database: typedb
    Then relation(parentship) create role: parent; fails
    When relation(marriage) get role(spouse) set ordering: ordered
    Then relation(marriage) get role(spouse) get ordering: ordered

  Scenario: Relation and ordered roles can be deleted
    When create relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) get role(spouse) set ordering: ordered
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) create role: child
    When relation(parentship) get role(child) set ordering: ordered
    When relation(parentship) delete role: parent
    Then relation(parentship) get roles do not contain:
      | parent |
    Then relation(relation) get role(role) get subtypes do not contain:
      | parentship:parent |
    When transaction commits
    When connection open schema transaction for database: typedb
    When delete relation type: parentship
    Then relation(parentship) does not exist
    Then relation(relation) get role(role) get subtypes do not contain:
      | parentship:parent |
      | parentship:child  |
    When relation(marriage) delete role: spouse
    Then relation(marriage) get roles do not contain:
      | spouse |
    When relation(marriage) create role: husband
    When relation(marriage) get role(husband) set ordering: ordered
    When relation(marriage) create role: wife
    When relation(marriage) get role(wife) set ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    When delete relation type: marriage
    Then relation(marriage) does not exist
    Then relation(relation) get role(role) get subtypes do not contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) does not exist
    Then relation(marriage) does not exist
    Then relation(relation) get role(role) get subtypes do not contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |

  Scenario: Role can change ordering if it does not have role instances even if its relation has instances
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When create entity type: person
    When entity(person) set plays: parentship:parent
    When transaction commits
    When connection open write transaction for database: typedb
    When $m = relation(parentship) create new instance
    When $a = entity(person) create new instance
    When relation $m add player for role(parent): $a
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(parentship) get role(child) set ordering: ordered
    Then relation(parentship) get role(child) get ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(child) get ordering: ordered
    When relation(parentship) get role(child) set ordering: unordered
    Then relation(parentship) get role(child) get ordering: unordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(child) get ordering: unordered

  Scenario: Role cannot change ordering if it has role instances
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When relation(parentship) get role(child) set ordering: ordered
    When create attribute type: id
    When attribute(id) set value type: long
    When relation(parentship) set owns: id
    When relation(parentship) get owns(id) set annotation: @key
    When create entity type: person
    When entity(person) set plays: parentship:parent
    When entity(person) set plays: parentship:child
    When entity(person) set owns: id
    When entity(person) get owns(id) set annotation: @key
    When transaction commits
    When connection open write transaction for database: typedb
    When $m = relation(parentship) create new instance with key(id): 1
    When $a = entity(person) create new instance with key(id): 1
    When relation $m add player for role(parent): $a
    When relation $m add player for role(child): $a
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) set ordering: unordered; fails
    Then relation(parentship) get role(parent) set ordering: ordered; fails
    Then relation(parentship) get role(child) set ordering: unordered; fails
    Then relation(parentship) get role(child) set ordering: ordered; fails
    When connection open write transaction for database: typedb
    When $m = relation(parentship) get instance with key(id): 1
    When $a = entity(person) get instance with key(id): 1
    When delete entity: $a
    When delete relation: $m
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(parentship) get role(parent) set ordering: ordered
    Then relation(parentship) get role(parent) get ordering: ordered
    When relation(parentship) get role(child) set ordering: unordered
    Then relation(parentship) get role(child) get ordering: unordered
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get ordering: ordered
    Then relation(parentship) get role(child) get ordering: unordered

  Scenario: Relation and role lists can change labels
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) create role: child
    When relation(parentship) get role(child) set ordering: ordered
    Then relation(parentship) get name: parentship
    Then relation(parentship) get role(parent) get name: parent
    Then relation(parentship) get role(child) get name: child
    When relation(parentship) set name: marriage
    Then relation(parentship) does not exist
    Then relation(marriage) exists
    When relation(marriage) get role(parent) set name: husband
    When relation(marriage) get role(child) set name: wife
    Then relation(marriage) get role(parent) does not exist
    Then relation(marriage) get role(child) does not exist
    Then relation(marriage) get name: marriage
    Then relation(marriage) get role(husband) get name: husband
    Then relation(marriage) get role(wife) get name: wife
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(marriage) get name: marriage
    Then relation(marriage) get role(husband) get name: husband
    Then relation(marriage) get role(wife) get name: wife
    When relation(marriage) set name: employment
    Then relation(marriage) does not exist
    Then relation(employment) exists
    When relation(employment) get role(husband) set name: employee
    When relation(employment) get role(wife) set name: employer
    Then relation(employment) get role(husband) does not exist
    Then relation(employment) get role(wife) does not exist
    Then relation(employment) get name: employment
    Then relation(employment) get role(employee) get name: employee
    Then relation(employment) get role(employer) get name: employer
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(employment) exists
    Then relation(employment) get name: employment
    Then relation(employment) get role(employee) get name: employee
    Then relation(employment) get role(employer) get name: employer

  Scenario: Relation and role lists can be subtypes of other relation and role lists
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) create role: child
    When relation(parentship) get role(child) set ordering: ordered
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set ordering: ordered
    When relation(fathership) get role(father) set override: parent
    Then relation(fathership) get supertype: parentship
    Then relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(fathership) get role(child) get supertype: relation:role
    Then relation(fathership) get supertypes contain:
      | relation   |
      | parentship |
    Then relation(fathership) get role(father) get supertypes contain:
      | relation:role     |
      | parentship:parent |
    Then relation(fathership) get role(child) get supertypes contain:
      | relation:role |
    Then relation(parentship) get subtypes contain:
      | fathership |
    Then relation(parentship) get role(parent) get subtypes contain:
      | fathership:father |
    Then relation(parentship) get role(child) get subtypes is empty
    Then relation(relation) get subtypes contain:
      | parentship |
      | fathership |
    Then relation(relation) get role(role) get subtypes contain:
      | parentship:parent |
      | parentship:child  |
      | fathership:father |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(fathership) get supertype: parentship
    Then relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(fathership) get role(child) get supertype: relation:role
    Then relation(fathership) get supertypes contain:
      | relation   |
      | parentship |
    Then relation(fathership) get role(father) get supertypes contain:
      | relation:role     |
      | parentship:parent |
    Then relation(fathership) get role(child) get supertypes contain:
      | relation:role |
    Then relation(parentship) get subtypes contain:
      | fathership |
    Then relation(parentship) get role(parent) get subtypes contain:
      | fathership:father |
    Then relation(parentship) get role(child) get subtypes is empty
    Then relation(relation) get subtypes contain:
      | parentship |
      | fathership |
    Then relation(relation) get role(role) get subtypes contain:
      | parentship:parent |
      | parentship:child  |
      | fathership:father |
    When create relation type: father-son
    When relation(father-son) set supertype: fathership
    When relation(father-son) create role: son
    When relation(father-son) get role(son) set ordering: ordered
    When relation(father-son) get role(son) set override: child
    Then relation(father-son) get supertype: fathership
    Then relation(father-son) get role(father) get supertype: parentship:parent
    Then relation(father-son) get role(son) get supertype: parentship:child
    Then relation(father-son) get supertypes contain:
      | relation   |
      | parentship |
      | fathership |
    Then relation(father-son) get role(father) get supertypes contain:
      | relation:role     |
      | parentship:parent |
    Then relation(father-son) get role(son) get supertypes contain:
      | relation:role    |
      | parentship:child |
    Then relation(fathership) get subtypes contain:
      | father-son |
    Then relation(fathership) get role(father) get subtypes is empty
    Then relation(fathership) get role(child) get subtypes contain:
      | father-son:son |
    Then relation(parentship) get role(parent) get subtypes contain:
      | fathership:father |
    Then relation(parentship) get role(child) get subtypes contain:
      | father-son:son |
    Then relation(relation) get subtypes contain:
      | parentship |
      | fathership |
    Then relation(relation) get role(role) get subtypes contain:
      | parentship:parent |
      | parentship:child  |
      | fathership:father |
      | father-son:son    |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(father-son) get supertype: fathership
    Then relation(father-son) get role(father) get supertype: parentship:parent
    Then relation(father-son) get role(son) get supertype: parentship:child
    Then relation(father-son) get supertypes contain:
      | relation   |
      | parentship |
      | fathership |
    Then relation(father-son) get role(father) get supertypes contain:
      | relation:role     |
      | parentship:parent |
    Then relation(father-son) get role(son) get supertypes contain:
      | relation:role    |
      | parentship:child |
    Then relation(fathership) get supertype: parentship
    Then relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(fathership) get role(child) get supertype: relation:role
    Then relation(fathership) get supertypes contain:
      | relation   |
      | parentship |
    Then relation(fathership) get role(father) get supertypes contain:
      | relation:role     |
      | parentship:parent |
    Then relation(fathership) get role(child) get supertypes contain:
      | relation:role |
    Then relation(fathership) get subtypes contain:
      | father-son |
    Then relation(fathership) get role(father) get subtypes is empty
    Then relation(fathership) get role(child) get subtypes contain:
      | father-son:son |
    Then relation(parentship) get role(parent) get subtypes contain:
      | fathership:father |
    Then relation(parentship) get role(child) get subtypes contain:
      | father-son:son |
    Then relation(relation) get subtypes contain:
      | parentship |
      | fathership |
    Then relation(relation) get role(role) get subtypes contain:
      | parentship:parent |
      | parentship:child  |
      | fathership:father |
      | father-son:son    |

  Scenario: Relation types can inherit ordered related role
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) create role: child
    When relation(parentship) get role(child) set ordering: ordered
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set ordering: ordered
    When relation(fathership) get role(father) set override: parent
    Then relation(fathership) get roles contain:
      | fathership:father |
      | parentship:child  |
    Then relation(fathership) get declared roles contain:
      | fathership:father |
    Then relation(fathership) get declared roles do not contain:
      | parentship:child |
    When transaction commits
    When connection open schema transaction for database: typedb
    When create relation type: mothership
    When relation(mothership) set supertype: parentship
    When relation(mothership) create role: mother
    When relation(mothership) get role(mother) set ordering: ordered
    When relation(mothership) get role(mother) set override: parent
    Then relation(mothership) get roles contain:
      | mothership:mother |
      | parentship:child  |
    Then relation(mothership) get declared roles contain:
      | mothership:mother |
    Then relation(mothership) get declared roles do not contain:
      | parentship:child |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get roles contain:
      | fathership:father |
      | parentship:child  |
    Then relation(fathership) get declared roles contain:
      | fathership:father |
    Then relation(fathership) get declared roles do not contain:
      | parentship:child |
    Then relation(mothership) get roles contain:
      | mothership:mother |
      | parentship:child  |
    Then relation(mothership) get declared roles contain:
      | mothership:mother |
    Then relation(mothership) get declared roles do not contain:
      | parentship:child |

  Scenario: Relation types can override inherited related role lists
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) create role: child
    When relation(parentship) get role(child) set ordering: ordered
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set ordering: ordered
    When relation(fathership) get role(father) set override: parent
    Then relation(fathership) get overridden role(father) exists
    Then relation(fathership) get overridden role(father) get name: parent
    Then relation(fathership) get roles do not contain:
      | parentship:parent |
    When transaction commits
    When connection open schema transaction for database: typedb
    When create relation type: mothership
    When relation(mothership) set supertype: parentship
    When relation(mothership) create role: mother
    When relation(mothership) get role(mother) set ordering: ordered
    When relation(mothership) get role(mother) set override: parent
    Then relation(mothership) get roles do not contain:
      | parentship:parent |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get roles do not contain:
      | parentship:parent |
    Then relation(mothership) get roles do not contain:
      | parentship:parent |

  Scenario: Relation types cannot redeclare inherited related role types
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) create role: child
    When relation(parentship) get role(child) set ordering: ordered
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    Then relation(fathership) create role: parent; fails

  Scenario: Relation types cannot override declared related role types
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    Then relation(parentship) create role: father
    When relation(parentship) get role(father) set ordering: ordered
    Then relation(parentship) get role(father) set override: parent; fails

  Scenario: Relation types can update existing roles override a newly defined role it inherits
    When create relation type: parentship
    When relation(parentship) create role: other-role
    When relation(parentship) get role(other-role) set ordering: ordered
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set ordering: ordered
    When relation(fathership) get role(father) set override: parent
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get overridden role(father) get name: parent

  Scenario: Relation type can set ordered for inherited unordered roles
    When create relation type: parentship
    When relation(parentship) set annotation: @abstract
    When relation(parentship) create role: parent
    When create relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    When create relation type: mothership
    When relation(mothership) create role: mother
    When relation(mothership) set supertype: parentship
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(fathership) get role(father) get ordering: unordered
    Then relation(mothership) get role(mother) get ordering: unordered
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(fathership) get role(father) set ordering: ordered
    When relation(fathership) get role(father) set override: parent
    When relation(mothership) get role(mother) set override: parent
    Then relation(fathership) get role(father) get supertype: parent
    Then relation(mothership) get role(mother) get supertype: parent
    When relation(mothership) get role(mother) set ordering: ordered
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(fathership) get role(father) get ordering: ordered
    Then relation(mothership) get role(mother) get ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(fathership) get role(father) get ordering: ordered
    Then relation(mothership) get role(mother) get ordering: ordered
    When relation(fathership) get role(father) set ordering: unordered
    When relation(mothership) get role(mother) set ordering: unordered
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(fathership) get role(father) get ordering: unordered
    Then relation(mothership) get role(mother) get ordering: unordered
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(fathership) get role(father) get ordering: unordered
    Then relation(mothership) get role(mother) get ordering: unordered

  Scenario: Unordered and ordered are propagated to subtypes of roles unless overridden
    When create relation type: parentship
    When relation(parentship) set annotation: @abstract
    When relation(parentship) create role: parent
    Then relation(parentship) get role(parent) get ordering: unordered
    When relation(parentship) create role: child
    When relation(parentship) get role(child) set ordering: ordered
    Then relation(parentship) get role(child) get ordering: ordered
    When create relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) create role: father-child
    When relation(fathership) set supertype: parentship
    When create relation type: mothership
    When relation(mothership) create role: mother
    When relation(mothership) create role: mother-child
    When relation(mothership) set supertype: parentship
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(fathership) get role(father) get ordering: unordered
    Then relation(mothership) get role(mother) get ordering: unordered
    Then relation(fathership) get role(father-child) get ordering: unordered
    Then relation(mothership) get role(mother-child) get ordering: unordered
    When relation(fathership) get role(father) set override: parent
    Then relation(fathership) get role(father) get ordering: unordered
    When relation(mothership) get role(mother) set override: parent
    Then relation(mothership) get role(mother) get ordering: unordered
    When relation(fathership) get role(father-child) set override: child
    Then relation(fathership) get role(father-child) get ordering: ordered
    When relation(mothership) get role(mother-child) set override: child
    Then relation(mothership) get role(mother-child) get ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(fathership) get role(father) get ordering: unordered
    Then relation(mothership) get role(mother) get ordering: unordered
    Then relation(fathership) get role(father-child) get ordering: ordered
    Then relation(mothership) get role(mother-child) get ordering: ordered
    When <root-type>(mothership) get role(mother) set ordering: ordered
    Then <root-type>(mothership) get role(mother) get ordering: ordered
    When <root-type>(mothership) get role(mother-child) set ordering: ordered
    Then <root-type>(mothership) get role(mother-child) get ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(fathership) get role(father) get ordering: unordered
    Then relation(mothership) get role(mother) get ordering: unordered
    Then relation(fathership) get role(father-child) get ordering: ordered
    Then relation(mothership) get role(mother-child) get ordering: ordered
    When relation(parenship) get owns(name) set ordering: ordered
    Then relation(fathership) get role(father) get ordering: ordered
    Then relation(mothership) get role(mother) get ordering: ordered
    When relation(parenship) get owns(email) set ordering: unordered
    Then relation(fathership) get role(father) get ordering: unordered
    Then relation(mothership) get role(mother) get ordering: ordered
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get role(father) get ordering: ordered
    Then relation(mothership) get role(mother) get ordering: ordered
    Then relation(fathership) get role(father) get ordering: unordered
    Then relation(mothership) get role(mother) get ordering: ordered

  Scenario: Relation can set and unset ordering if it inherits unordered roles
    When create relation type: parentship
    When relation(parentship) create role: parent
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(fathership) get role(parent) get ordering: unordered
    When relation(fathership) get role(parent) set ordering: ordered
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(fathership) get role(parent) get ordering: ordered
    When transaction commit
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(fathership) get role(parent) get ordering: ordered
    When relation(fathership) get role(parent) set ordering: unordered
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(fathership) get role(parent) get ordering: unordered
    When transaction commit
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(fathership) get role(parent) get ordering: unordered

  Scenario: Relation cannot set or unset ordering if it inherits ordered roles
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    Then relation(parentship) get role(parent) get ordering: ordered
    When transaction commit
    When connection open schema transaction for database: typedb
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    Then relation(parentship) get role(parent) get ordering: ordered
    Then relation(fathership) get role(parent) get ordering: ordered
    When relation(fathership) get role(parent) set ordering: ordered
    Then transaction commit; fails
    When connection open schema transaction for database: typedb
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    Then relation(parentship) get role(parent) get ordering: ordered
    Then relation(fathership) get role(parent) get ordering: ordered
    Then relation(fathership) get role(parent) set ordering: unordered; fails
    Then relation(parentship) get role(parent) get ordering: ordered
    Then relation(fathership) get role(parent) get ordering: ordered
    Then transaction commit
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get ordering: ordered
    Then relation(fathership) get role(parent) get ordering: ordered

  Scenario: Relation can set and unset ordering if it overrides unordered roles
    When create relation type: parentship
    When relation(parentship) create role: parent
    Then relation(parentship) get role(parent) get ordering: unordered
    When transaction commit
    When connection open schema transaction for database: typedb
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set override: parent
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(fathership) get role(father) get ordering: unordered
    When relation(fathership) get role(father) set ordering: ordered
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(fathership) get role(father) get ordering: ordered
    Then relation(fathership) get role(father) get supertype: parent
    When transaction commit
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(fathership) get role(father) get ordering: ordered
    When relation(fathership) get role(father) set ordering: unordered
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(fathership) get role(father) get ordering: unordered
    When transaction commit
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(fathership) get role(father) get ordering: unordered
    When connection open schema transaction for database: typedb
    When create relation type: mothership
    When relation(mothership) set supertype: parentship
    When relation(mothership) create role: mother
    When relation(mothership) get role(mother) set ordering: ordered
    When relation(mothership) get role(mother) set override: parent
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(mothership) get role(mother) get ordering: ordered
    Then relation(mothership) get role(mother) get supertype: parent
    When transaction commit
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(mothership) get role(mother) get ordering: ordered
    When relation(mothership) get role(mother) set ordering: unordered
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(mothership) get role(mother) get ordering: unordered
    When transaction commit
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(mothership) get role(mother) get ordering: unordered

  Scenario: Relation cannot set or unset ordering if it overrides ordered roles
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    Then relation(parentship) get role(parent) get ordering: ordered
    When transaction commit
    When connection open schema transaction for database: typedb
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set override: parent
    Then relation(parentship) get role(parent) get ordering: ordered
    Then relation(fathership) get role(father) get ordering: ordered
    When transaction commit
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get ordering: ordered
    Then relation(fathership) get role(father) get ordering: ordered
    When relation(fathership) get role(father) set ordering: ordered
    Then transaction commit; fails
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get ordering: ordered
    Then relation(fathership) get role(father) get ordering: ordered
    Then relation(fathership) get role(father) set ordering: unordered; fails
    When connection open schema transaction for database: typedb
    When create relation type: mothership
    When relation(mothership) set supertype: parentship
    When relation(mothership) create role: mother
    When relation(mothership) get role(mother) set ordering: ordered
    When relation(mothership) get role(mother) set override: parent
    Then relation(parentship) get role(parent) get ordering: ordered
    Then relation(mothership) get role(mother) get ordering: ordered
    Then relation(mothership) get role(mother) get supertype: parent
    When transaction commit
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get ordering: ordered
    Then relation(mothership) get role(mother) get ordering: ordered
    When relation(mothership) get role(mother) set ordering: ordered
    Then transaction commit; fails
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get ordering: ordered
    Then relation(mothership) get role(mother) get ordering: ordered
    Then relation(mothership) get role(mother) set ordering: unordered; fails

########################
# relates @annotations common
########################

  Scenario Outline: Roles cannot unset @<annotation> that has not been set
    When create relation type: marriage
    When relation(marriage) create role: spouse
    Then relation(marriage) get role(spouse) unset annotation: @<annotation>; fails
    Examples:
      | annotation |
      | card(1, 2) |

  Scenario Outline: Role can set and unset @<annotation>
    When create relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) get role(spouse) set annotation: @<annotation>
    Then relation(marriage) get role(spouse) get annotations contain: @<annotation>
    When relation(marriage) get role(spouse) unset annotation: @<annotation>
    Then relation(marriage) get role(spouse) get annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(marriage) get role(spouse) get annotations do not contain: @<annotation>
    When relation(marriage) get role(spouse) set annotation: @<annotation>
    Then relation(marriage) get role(spouse) get annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(marriage) get role(spouse) get annotations contain: @<annotation>
    Examples:
      | annotation |
      | card(1, 2) |

  Scenario Outline: Ordered roles cannot unset @<annotation> that has not been set
    When create relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) get role(spouse) set ordering: ordered
    Then relation(marriage) get role(spouse) unset annotation: @<annotation>; fails
    Examples:
      | annotation |
      | distinct   |
      | card(1, 2) |

  Scenario Outline: Ordered roles can set and unset @<annotation>
    When create relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) get role(spouse) set ordering: ordered
    When relation(marriage) get role(spouse) set annotation: @<annotation>
    Then relation(marriage) get role(spouse) get annotations contain: @<annotation>
    When relation(marriage) get role(spouse) unset annotation: @<annotation>
    Then relation(marriage) get role(spouse) get annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(marriage) get role(spouse) get annotations do not contain: @<annotation>
    When relation(marriage) get role(spouse) set annotation: @<annotation>
    Then relation(marriage) get role(spouse) get annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(marriage) get role(spouse) get annotations contain: @<annotation>
    Examples:
      | annotation |
      | distinct   |
      | card(1, 2) |

########################
# relates @distinct
########################

  Scenario: Relation type can set @distinct annotation for ordered roles and unset it
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    Then relation(parentship) get role(parent) get ordering: ordered
    When relation(parentship) get role(parent) set annotation: @distinct
    Then relation(parentship) get role(parent) get annotations contain: @distinct
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get annotations contain: @distinct
    When relation(parentship) get role(parent) unset annotation: @distinct
    Then relation(parentship) get role(parent) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get annotations is empty

  Scenario: Relation type cannot set @distinct annotation for unordered roles
    When create relation type: parentship
    When relation(parentship) create role: parent
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(parentship) get role(parent) set annotation: @distinct; fails
    Then relation(parentship) get role(parent) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get annotations is empty

  Scenario: Relation type cannot unset ordering if @distinct annotation is set
    When create relation type: parentship
    When relation(parentship) create role: parent
    Then relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) get role(parent) set annotation: @distinct
    Then relation(parentship) get role(parent) get annotations contain: @distinct
    Then relation(parentship) get role(parent) get ordering: ordered
    Then relation(parentship) get role(parent) set ordering: unordered; fails
    Then relation(parentship) get role(parent) get ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get ordering: ordered
    Then relation(parentship) get role(parent) get annotations contain: @distinct
    Then relation(parentship) get role(parent) set ordering: unordered; fails
    When relation(parentship) get role(parent) unset annotation: @distinct
    Then relation(parentship) get role(parent) get annotations is empty
    Then relation(parentship) get role(parent) get ordering: ordered
    When relation(parentship) get role(parent) set ordering: unordered
    Then relation(parentship) get role(parent) get ordering: unordered
    When transaction commits
    When connection open Read transaction for database: typedb
    Then relation(parentship) get role(parent) get annotations is empty
    Then relation(parentship) get role(parent) get ordering: unordered

  Scenario: Ordered roles can reset @distinct annotation
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) get role(parent) set annotation: @distinct
    Then relation(parentship) get role(parent) get annotations contain: @distinct
    When relation(parentship) get role(parent) set annotation: @distinct
    Then relation(parentship) get role(parent) get annotations contain: @distinct
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get annotations contain: @distinct

  Scenario: Ordered roles can set @distinct annotation with arguments
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    Then relation(parentship) get role(parent) set annotation: @distinct(); fails
    Then relation(parentship) get role(parent) set annotation: @distinct(1); fails
    Then relation(parentship) get role(parent) set annotation: @distinct(1, 2); fails
    Then relation(parentship) get role(parent) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get annotations is empty

  Scenario: Ordered roles cannot unset not set @distinct
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    Then relation(parentship) get role(parent) unset annotation: @distinct; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get annotations is empty
    Then relation(parentship) get role(parent) unset annotation: @distinct; fails

  Scenario: Ordered roles' @distinct annotation can be inherited
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) get role(parent) set annotation: @distinct
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    Then relation(fathership) get role(parent) get annotations contain: @distinct
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get role(parent) get annotations contain: @distinct

  Scenario: Ordered roles can reset inherited @distinct annotation
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) get role(parent) set annotation: @distinct
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    Then relation(fathership) get role(parent) get annotations contain: @distinct
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(fathership) get role(parent) set annotation: @distinct
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When create relation type: mothership
    When relation(mothership) set supertype: parentship
    Then relation(mothership) get role(parent) get annotations contain: @distinct
    When relation(mothership) get role(parent) set annotation: @distinct
    Then transaction commits; fails

  Scenario: Ordered roles cannot unset inherited @distinct annotation
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    Then relation(parentship) get role(parent) set annotation: @distinct
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    Then relation(parentship) get role(parent) get annotations contain: @distinct
    Then relation(fathership) get role(parent) get annotations contain: @distinct
    Then relation(fathership) get role(parent) unset annotation: @distinct; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get annotations contain: @distinct
    Then relation(fathership) get role(parent) get annotations contain: @distinct
    Then relation(fathership) get role(parent) unset annotation: @distinct; fails

  Scenario: Ordered roles can reset inherited @distinct annotation on an overridden role
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) get role(parent) set annotation: @distinct
    When create relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    When relation(fathership) get role(father) set override: parent
    Then relation(fathership) get role(father) get annotations contain: @distinct
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(fathership) get role(father) get ordering: ordered
    When relation(fathership) get role(father) set annotation: @distinct
    Then transaction commits; fails

  Scenario: Ordered roles cannot unset inherited @distinct annotation
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) get role(parent) set annotation: @distinct
    When create relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    When relation(parentship) get role(father) get ordering: unordered
    When relation(fathership) get role(father) set override: parent
    When relation(parentship) get role(father) get ordering: ordered
    Then relation(fathership) get role(father) get annotations contain: @distinct
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(fathership) get role(father) unset annotation: @distinct; fails
    Then relation(fathership) get role(father) get annotations contain: @distinct
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get role(father) get annotations contain: @distinct

########################
# relates @card
########################

  Scenario: Relation type can set @card annotation on roles and unset it
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When relation(parentship) get role(child) set ordering: ordered
    When relation(parentship) get role(parent) set annotation: @card(1, 2)
    Then relation(parentship) get role(parent) get annotations contain: @card(1, 2)
    When relation(parentship) get role(child) set annotation: @card(0, *)
    Then relation(parentship) get role(child) get annotations contain: @card(0, *)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get annotations contain: @card(1, 2)
    Then relation(parentship) get role(child) get annotations contain: @card(0, *)
    When relation(parentship) get role(parent) unset annotation: @card(1, 2)
    Then relation(parentship) get role(parent) get annotations is empty
    When relation(parentship) get role(child) unset annotation: @card(0, *)
    Then relation(parentship) get role(child) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get annotations is empty
    Then relation(parentship) get role(child) get annotations is empty

  Scenario Outline: Relation type can set @card annotation on roles with duplicate args (exactly N ownerships)
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When relation(parentship) get role(child) set ordering: ordered
    When relation(parentship) get role(parent) set annotation: @card(<arg>, <arg>)
    Then relation(parentship) get role(parent) get annotations contain: @card(<arg>, <arg>)
    When relation(parentship) get role(child) set annotation: @card(<arg>, <arg>)
    Then relation(parentship) get role(child) get annotations contain: @card(<arg>, <arg>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get annotations contain: @card(<arg>, <arg>)
    Then relation(parentship) get role(child) get annotations contain: @card(<arg>, <arg>)
    Examples:
      | arg  |
      | 1    |
      | 9999 |

  Scenario: Relation type cannot have @card annotation for with invalid arguments
    When create relation type: parentship
    When relation(parentship) create role: parent
    Then relation(parentship) get role(parent) set annotation: @card(); fails
    Then relation(parentship) get role(parent) set annotation: @card(0); fails
    Then relation(parentship) get role(parent) set annotation: @card(1); fails
    Then relation(parentship) get role(parent) set annotation: @card(*); fails
    Then relation(parentship) get role(parent) set annotation: @card(-1, 1); fails
    Then relation(parentship) get role(parent) set annotation: @card(0, 0.1); fails
    Then relation(parentship) get role(parent) set annotation: @card(0, 1.5); fails
    Then relation(parentship) get role(parent) set annotation: @card(*, *); fails
    Then relation(parentship) get role(parent) set annotation: @card(0, **); fails
    Then relation(parentship) get role(parent) set annotation: @card(1, 2, 3); fails
    Then relation(parentship) get role(parent) set annotation: @card(1, "2"); fails
    Then relation(parentship) get role(parent) set annotation: @card("1", 2); fails
    Then relation(parentship) get role(parent) set annotation: @card(2, 1); fails
    Then relation(parentship) get role(parent) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get annotations is empty

  Scenario Outline: Relation type can reset @card annotations
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set annotation: @card(<init-args>)
    Then relation(parentship) get role(parent) get annotations contain: @card(<init-args>)
    Then relation(parentship) get role(parent) get annotations do not contain: @card(<reset-args>)
    When relation(parentship) get role(parent) set annotation: @card(<init-args>)
    Then relation(parentship) get role(parent) get annotations contain: @card(<init-args>)
    Then relation(parentship) get role(parent) get annotations do not contain: @card(<reset-args>)
    When relation(parentship) get role(parent) set annotation: @card(<reset-args>)
    Then relation(parentship) get role(parent) get annotations contain: @card(<reset-args>)
    Then relation(parentship) get role(parent) get annotations do not contain: @card(<init-args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get annotations contain: @card(<reset-args>)
    Then relation(parentship) get role(parent) get annotations do not contain: @card(<init-args>)
    When relation(parentship) get role(parent) set annotation: @card(<init-args>)
    Then relation(parentship) get role(parent) get annotations contain: @card(<init-args>)
    Then relation(parentship) get role(parent) get annotations do not contain: @card(<reset-args>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get annotations do not contain: @card(<reset-args>)
    Examples:
      | init-args | reset-args |
      | 0, *      | 0, 1       |
      | 0, 5      | 0, 1       |
      | 2, 5      | 0, 1       |
      | 2, 5      | 0, 2       |
      | 2, 5      | 0, 3       |
      | 2, 5      | 0, 5       |
      | 2, 5      | 0, *       |
      | 2, 5      | 2, 3       |
      | 2, 5      | 2, 5       |
      | 2, 5      | 2, *       |
      | 2, 5      | 3, 4       |
      | 2, 5      | 3, 5       |
      | 2, 5      | 3, *       |
      | 2, 5      | 5, *       |
      | 2, 5      | 6, *       |

  Scenario: Role can reset inherited @range annotation
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set annotation: @range("value", "value+1")
    When create attribute type: fathership
    When relation(fathership) set supertype: parentship
    Then relation(fathership) get role(parent) get annotations contain: @range("value", "value+1")
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(fathership) get role(parent) set annotation: @range("value", "value+1")
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When create attribute type: mothership
    When relation(mothership) set supertype: parentship
    Then relation(mothership) get role(parent) get annotations contain: @range("value", "value+1")
    When relation(mothership) get role(parent) set annotation: @range("value", "value+1")
    Then transaction commits; fails

  Scenario: Role cannot unset inherited @range annotation
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set annotation: @range("value", "value+1")
    When create attribute type: fathership
    When relation(fathership) set supertype: parentship
    Then relation(fathership) get role(parent) get annotations contain: @range("value", "value+1")
    Then relation(fathership) get role(parent) unset annotation: @range("value", "value+1"); fail
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(fathership) get role(parent) get annotations contain: @range("value", "value+1")
    Then relation(fathership) get role(parent) unset annotation: @range("value", "value+1"); fail
    Then relation(fathership) unset supertype: name
    Then relation(fathership) get role(parent) get annotations do not contain: @range("value", "value+1")
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get role(parent) get annotations do not contain: @range("value", "value+1")

  Scenario Outline: Role's @card annotation can be inherited and overridden by a subset of arguments
    When create relation type: parentship
    When relation(parentship) create role: custom-role
    When relation(parentship) create role: second-custom-role
    When relation(parentship) get role(custom-role) set annotation: @card(<args>)
    Then relation(parentship) get role(custom-role) get annotations contain: @card(<args>)
    When relation(parentship) get role(second-custom-role) set annotation: @card(<args>)
    Then relation(parentship) get role(second-custom-role) get annotations contain: @card(<args>)
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: overridden-custom-role
    # TODO: Overrides? Remove second-custom-role from test if we remove overrides!
    When relation(fathership) get role(overridden-custom-role) set override: second-custom-role
    Then relation(fathership) get roles contain: custom-role
    Then relation(fathership) get role(custom-role) get annotations contain: @card(<args>)
    Then relation(fathership) get roles do not contain: second-custom-role
    Then relation(fathership) get roles contain: overridden-custom-role
    Then relation(fathership) get role(overridden-custom-role) get annotations contain: @card(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(fathership) get role(custom-role) get annotations contain: @card(<args>)
    Then relation(fathership) get role(overridden-custom-role) get annotations contain: @card(<args>)
    When relation(fathership) get role(custom-role) set annotation: @card(<args-override>)
    Then relation(fathership) get role(custom-role) get annotations contain: @card(<args-override>)
    When relation(fathership) get role(overridden-custom-role) set annotation: @card(<args-override>)
    Then relation(fathership) get role(overridden-custom-role) get annotations contain: @card(<args-override>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get role(custom-role) get annotations contain: @card(<args-override>)
    Then relation(fathership) get role(overridden-custom-role) get annotations contain: @card(<args-override>)
    Examples:
      | args       | args-override |
      | 0, *       | 0, 10000      |
      | 0, 10      | 0, 1          |
      | 0, 2       | 1, 2          |
      | 1, *       | 1, 1          |
      | 1, 5       | 3, 4          |
      | 38, 111    | 39, 111       |
      | 1000, 1100 | 1000, 1099    |

  Scenario Outline: Inherited @card annotation of roles cannot be reset or overridden by the @card of not a subset of arguments
    When create relation type: parentship
    When relation(parentship) create role: custom-role
    When relation(parentship) create role: second-custom-role
    When relation(parentship) get role(custom-role) set annotation: @card(<args>)
    Then relation(parentship) get role(custom-role) get annotations contain: @card(<args>)
    When relation(parentship) get role(second-custom-role) set annotation: @card(<args>)
    Then relation(parentship) get role(second-custom-role) get annotations contain: @card(<args>)
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: overridden-custom-role
    # TODO: Overrides? Remove second-custom-role from test if we remove overrides!
    When relation(fathership) get role(overridden-custom-role) set override: second-custom-role
    Then relation(fathership) get role(custom-role) get annotations contain: @card(<args>)
    Then relation(fathership) get role(overridden-custom-role) get annotations contain: @card(<args>)
    Then relation(fathership) get role(custom-role) set annotation: @card(<args-override>); fails
    Then relation(fathership) get role(overridden-custom-role) set annotation: @card(<args-override>); fails
    Then relation(fathership) get role(custom-role) get annotations contain: @card(<args>)
    Then relation(fathership) get role(overridden-custom-role) get annotations contain: @card(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(fathership) get role(custom-role) get annotations contain: @card(<args>)
    Then relation(fathership) get role(overridden-custom-role) get annotations contain: @card(<args>)
    When relation(fathership) get role(custom-role) set annotation: @card(<args>)
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When relation(fathership) get role(overridden-custom-role) set annotation: @card(<args>)
    Then transaction commits; fails
    Examples:
      | args       | args-override |
      | 0, 10000   | 0, 10001      |
      | 0, 10      | 1, 11         |
      | 0, 2       | 0, 0          |
      | 1, *       | 0, 2          |
      | 1, 5       | 6, 10         |
      | 38, 111    | 37, 111       |
      | 1000, 1100 | 1000, 1199    |

########################
# relates not compatible @annotations: @key, @unique, @subkey, @values, @range, @abstract, @cascade, @independent, @replace, @regex
########################

  Scenario: Relation's role cannot have @key, @unique, @subkey, @values, @range, @abstract, @cascade, @independent, @replace, and @regex annotations
    When create relation type: parentship
    When relation(parentship) create role: parent
    Then relation(parentship) get role(parent) set annotation: @key; fails
    Then relation(parentship) get role(parent) set annotation: @unique; fails
    Then relation(parentship) get role(parent) set annotation: @subkey; fails
    Then relation(parentship) get role(parent) set annotation: @subkey(LABEL); fails
    Then relation(parentship) get role(parent) set annotation: @values; fails
    Then relation(parentship) get role(parent) set annotation: @values(1, 2); fails
    Then relation(parentship) get role(parent) set annotation: @range; fails
    Then relation(parentship) get role(parent) set annotation: @range(1, 2); fails
    Then relation(parentship) get role(parent) set annotation: @abstract; fails
    # TODO: @cascade on relates?
    Then relation(parentship) get role(parent) set annotation: @cascade; fails
    Then relation(parentship) get role(parent) set annotation: @independent; fails
    Then relation(parentship) get role(parent) set annotation: @replace; fails
    Then relation(parentship) get role(parent) set annotation: @regex; fails
    Then relation(parentship) get role(parent) set annotation: @regex("val"); fails
    Then relation(parentship) get role(parent) set annotation: @does-not-exist; fails
    Then relation(parentship) get role(parent) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get annotations is empty

########################
# relates @annotations combinations:
# @distinct, @card
# Right now only for lists as there are no combinations for scalar roles!
########################

  Scenario Outline: Ordered roles can set @<annotation-1> and @<annotation-2> together and unset it
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) get role(parent) set annotation: @<annotation-1>
    When relation(parentship) get role(parent) set annotation: @<annotation-2>
    Then relation(parentship) get role(parent) get annotations contain:
      | @<annotation-1> |
      | @<annotation-2> |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get annotations contain:
      | @<annotation-1> |
      | @<annotation-2> |
    When relation(parentship) get role(parent) unset annotation: @<annotation-1>
    Then relation(parentship) get role(parent) get annotations do not contain: @<annotation-1>
    Then relation(parentship) get role(parent) get annotations contain: @<annotation-2>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get annotations do not contain: @<annotation-1>
    Then relation(parentship) get role(parent) get annotations contain: @<annotation-2>
    When relation(parentship) get role(parent) set annotation: @<annotation-1>
    When relation(parentship) get role(parent) unset annotation: @<annotation-2>
    Then relation(parentship) get role(parent) get annotations do not contain: @<annotation-2>
    Then relation(parentship) get role(parent) get annotations contain: @<annotation-1>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get annotations do not contain: @<annotation-2>
    Then relation(parentship) get role(parent) get annotations contain: @<annotation-1>
    When relation(parentship) get role(parent) unset annotation: @<annotation-1>
    Then relation(parentship) get role(parent) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get annotations is empty
    Examples:
      | annotation-1 | annotation-2 |
      | distinct     | card(0, 1)   |

      # Uncomment and add Examples when they appear!
#  Scenario Outline: Roles lists cannot set @<annotation-1> and @<annotation-2> together and unset it
#    When create relation type: parentship
#    When relation(parentship) create role: parent
#    When relation(parentship) get role(parent) set ordering: ordered
#    When relation(parentship) get role(parent) set annotation: @<annotation-1>
#    Then relation(parentship) get role(parent) set annotation: @<annotation-2>; fails
#    When connection open schema transaction for database: typedb
#    When create relation type: parentship
#    When relation(parentship) create role: parent
#    When relation(parentship) get role(parent) set ordering: ordered
#    Then relation(parentship) get role(parent) set annotation: @<annotation-2>
#    When relation(parentship) get role(parent) set annotation: @<annotation-1>; fails
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(parentship) get role(parent) get annotation contain: @<annotation-2>
#    Then relation(parentship) get role(parent) get annotation do not contain: @<annotation-1>
#    Examples:
#      | annotation-1 | annotation-2 |
