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
    Given connection opens schema transaction for database: typedb

  Scenario: Root relation type cannot be deleted
    Then delete relation type: relation; fails

  Scenario: Relation and role types can be created
    When put relation type: marriage
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
    When connection opens read transaction for database: typedb
    Then relation(marriage) exists
    Then relation(marriage) get supertype: relation
    Then relation(marriage) get role(husband) exists
    Then relation(marriage) get role(wife) exists
    Then relation(marriage) get role(husband) get supertype: relation:role
    Then relation(marriage) get role(wife) get supertype: relation:role
    Then relation(marriage) get roles contain:
      | marriage:husband |
      | marriage:wife    |

  Scenario: Relation and role types can be deleted
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When put relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When relation(parentship) delete role: parent
    Then relation(parentship) get roles do not contain:
      | parent |
    Then relation(relation) get role(role) get subtypes do not contain:
      | parentship:parent |
    When transaction commits
    When connection opens schema transaction for database: typedb
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
    When connection opens schema transaction for database: typedb
    When delete relation type: marriage
    Then relation(marriage) does not exist
    Then relation(relation) get role(role) get subtypes do not contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(parentship) does not exist
    Then relation(marriage) does not exist
    Then relation(relation) get role(role) get subtypes do not contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |

  Scenario: Relation types that have instances cannot be deleted
    When put relation type: marriage
    When relation(marriage) create role: wife
    When put entity type: person
    When entity(person) set plays role: marriage:wife
    When transaction commits
    When connection opens write transaction for database: typedb
    When $m = relation(marriage) create new instance
    When $a = entity(person) create new instance
    When relation $m add player for role(wife): $a
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then delete relation type: marriage; fails

  Scenario: Role types that have instances cannot be deleted
    When put relation type: marriage
    When relation(marriage) create role: wife
    When relation(marriage) create role: husband
    When put entity type: person
    When entity(person) set plays role: marriage:wife
    When transaction commits
    When connection opens write transaction for database: typedb
    When $m = relation(marriage) create new instance
    When $a = entity(person) create new instance
    When relation $m add player for role(wife): $a
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then relation(marriage) delete role: wife; fails
    When connection opens schema transaction for database: typedb
    Then relation(marriage) delete role: husband
    Then transaction commits

  Scenario: Relation and role types can change labels
    When put relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    Then relation(parentship) get label: parentship
    Then relation(parentship) get role(parent) get label: parent
    Then relation(parentship) get role(child) get label: child
    When relation(parentship) set label: marriage
    Then relation(parentship) does not exist
    Then relation(marriage) exists
    When relation(marriage) get role(parent) set name: husband
    When relation(marriage) get role(child) set name: wife
    Then relation(marriage) get role(parent) does not exist
    Then relation(marriage) get role(child) does not exist
    Then relation(marriage) get label: marriage
    Then relation(marriage) get role(husband) get label: husband
    Then relation(marriage) get role(wife) get label: wife
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then relation(marriage) get label: marriage
    Then relation(marriage) get role(husband) get label: husband
    Then relation(marriage) get role(wife) get label: wife
    When relation(marriage) set label: employment
    Then relation(marriage) does not exist
    Then relation(employment) exists
    When relation(employment) get role(husband) set name: employee
    When relation(employment) get role(wife) set name: employer
    Then relation(employment) get role(husband) does not exist
    Then relation(employment) get role(wife) does not exist
    Then relation(employment) get label: employment
    Then relation(employment) get role(employee) get label: employee
    Then relation(employment) get role(employer) get label: employer
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(employment) exists
    Then relation(employment) get label: employment
    Then relation(employment) get role(employee) get label: employee
    Then relation(employment) get role(employer) get label: employer

  Scenario: Relation type can be set to abstract while role types remain concrete
    When put relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    When relation(marriage) set annotation: @abstract
    When put relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    Then relation(marriage) get annotations contain: @abstract
    Then relation(marriage) get role(husband) get annotations do not contain: @abstract
    Then relation(marriage) get role(wife) get annotations do not contain: @abstract
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then relation(parentship) get annotations do not contain: @abstract
    Then relation(parentship) get role(parent) get annotations do not contain: @abstract
    Then relation(parentship) get role(child) get annotations do not contain: @abstract
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then relation(marriage) get annotations contain: @abstract
    Then relation(marriage) get role(husband) get annotations do not contain: @abstract
    Then relation(marriage) get role(wife) get annotations do not contain: @abstract
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then relation(parentship) get annotations do not contain: @abstract
    Then relation(parentship) get role(parent) get annotations do not contain: @abstract
    Then relation(parentship) get role(child) get annotations do not contain: @abstract
    Then relation(parentship) set annotation: @abstract
    Then relation(parentship) get annotations contain: @abstract
    Then relation(parentship) get role(parent) get annotations do not contain: @abstract
    Then relation(parentship) get role(child) get annotations do not contain: @abstract
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(parentship) get annotations contain: @abstract
    Then relation(parentship) get role(parent) get annotations do not contain: @abstract
    Then relation(parentship) get role(child) get annotations do not contain: @abstract

  Scenario: relation types can be set to abstract when a subtype has instances
    When put relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When put relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father); set override: parent
    When relation(fathership) create role: father-child
    When relation(fathership) get role(father-child); set override: child
    When put entity type: person
    When entity(person) set plays role: fathership:father
    Then transaction commits
    When connection opens write transaction for database: typedb
    Then $m = relation(fathership) create new instance
    When $a = entity(person) create new instance
    When relation $m add player for role(father): $a
    Then transaction commits
    When connection opens schema transaction for database: typedb
    Then relation(parentship) set annotation: @abstract
    Then transaction commits
    When connection opens read transaction for database: typedb
    Then relation(parentship) get annotations contain: @abstract

  Scenario: Relation types must have at least one role in order to commit, unless they are abstract
    When put relation type: connection
    Then transaction commits; fails
    When connection opens schema transaction for database: typedb
    When put relation type: connection
    When relation(connection) set annotation: @abstract
    Then transaction commits

  Scenario: Relation and role types can be subtypes of other relation and role types
    When put relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When put relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father); set override: parent
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
      | relation:role    |
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
    When connection opens schema transaction for database: typedb
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
      | relation:role    |
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
    When put relation type: father-son
    When relation(father-son) set supertype: fathership
    When relation(father-son) create role: son
    When relation(father-son) get role(son); set override: child
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
      | father-son:son   |
    Then relation(parentship) get role(parent) get subtypes contain:
      | fathership:father |
    Then relation(parentship) get role(child) get subtypes contain:
      | father-son:son   |
    Then relation(relation) get subtypes contain:
      | parentship |
      | fathership |
    Then relation(relation) get role(role) get subtypes contain:
      | parentship:parent |
      | parentship:child  |
      | fathership:father |
      | father-son:son    |
    When transaction commits
    When connection opens read transaction for database: typedb
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
      | relation:role    |
    Then relation(fathership) get subtypes contain:
      | father-son |
    Then relation(fathership) get role(father) get subtypes is empty
    Then relation(fathership) get role(child) get subtypes contain:
      | father-son:son   |
    Then relation(parentship) get role(parent) get subtypes contain:
      | fathership:father |
    Then relation(parentship) get role(child) get subtypes contain:
      | father-son:son   |
    Then relation(relation) get subtypes contain:
      | parentship |
      | fathership |
    Then relation(relation) get role(role) get subtypes contain:
      | parentship:parent |
      | parentship:child  |
      | fathership:father |
      | father-son:son    |

  Scenario: Relation types cannot subtype itself
    When put relation type: marriage
    When relation(marriage) create role: wife
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then relation(marriage) set supertype: marriage; fails

  Scenario: Relation types can inherit related role types
    When put relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When put relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father); set override: parent
    Then relation(fathership) get roles contain:
      | fathership:father |
      | parentship:child  |
    Then relation(fathership) get declared roles contain:
      | fathership:father |
    Then relation(fathership) get declared roles do not contain:
      | parentship:child  |
    When transaction commits
    When connection opens schema transaction for database: typedb
    When put relation type: mothership
    When relation(mothership) set supertype: parentship
    When relation(mothership) create role: mother
    When relation(mothership) get role(mother); set override: parent
    Then relation(mothership) get roles contain:
      | mothership:mother |
      | parentship:child  |
    Then relation(mothership) get declared roles contain:
      | mothership:mother |
    Then relation(mothership) get declared roles do not contain:
      | parentship:child  |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(fathership) get roles contain:
      | fathership:father |
      | parentship:child  |
    Then relation(fathership) get declared roles contain:
      | fathership:father |
    Then relation(fathership) get declared roles do not contain:
      | parentship:child  |
    Then relation(mothership) get roles contain:
      | mothership:mother |
      | parentship:child  |
    Then relation(mothership) get declared roles contain:
      | mothership:mother |
    Then relation(mothership) get declared roles do not contain:
      | parentship:child  |

  Scenario: Roles can be inherited from abstract relation types
    When put relation type: parentship
    Then relation(parentship) set annotation: @abstract
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When put relation type: fathership
    When relation(fathership) set supertype: parentship
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(fathership) get roles contain:
      | parentship:parent |
      | parentship:child  |
    Then relation(fathership) get declared roles do not contain:
      | fathership:parent |
      | fathership:child  |
    Then relation(fathership) get role(parent) get annotations do not contain: @abstract
    Then relation(fathership) get role(child) get annotations do not contain: @abstract

  Scenario: Relation types can override inherited related role types
    When put relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When put relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father); set override: parent
    Then relation(fathership) get overridden role(father) exists
    Then relation(fathership) get overridden role(father) get label: parent
    Then relation(fathership) get roles do not contain:
      | parentship:parent |
    When transaction commits
    When connection opens schema transaction for database: typedb
    When put relation type: mothership
    When relation(mothership) set supertype: parentship
    When relation(mothership) create role: mother
    When relation(mothership) get role(mother); set override: parent
    Then relation(mothership) get roles do not contain:
      | parentship:parent |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(fathership) get roles do not contain:
      | parentship:parent |
    Then relation(mothership) get roles do not contain:
      | parentship:parent |

  Scenario: Relation types cannot redeclare inherited related role types
    When put relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When put relation type: fathership
    When relation(fathership) set supertype: parentship
    Then relation(fathership) create role: parent; fails

  Scenario: Relation types cannot override declared related role types
    When put relation type: parentship
    When relation(parentship) create role: parent
    Then relation(parentship) create role: father
    Then relation(parentship) get role(father); set override: parent; fails

  Scenario: Relation types can update existing roles override a newly defined role it inherits
    When put relation type: parentship
    When relation(parentship) create role: other-role
    When put relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When transaction commits
    When connection opens schema transaction for database: typedb
    When relation(parentship) create role: parent
    When relation(fathership) create role: father
    When relation(fathership) get role(father); set override: parent
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(fathership) get overridden role(father) get label: parent

  Scenario: Relation types can play role types
    When put relation type: locates
    When relation(locates) create role: location
    When relation(locates) create role: located
    When put relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    When relation(marriage) set plays role: locates:located
    Then relation(marriage) get plays roles contain:
      | locates:located |
    When transaction commits
    When connection opens schema transaction for database: typedb
    When put relation type: organises
    When relation(organises) create role: organiser
    When relation(organises) create role: organised
    When relation(marriage) set plays role: organises:organised
    Then relation(marriage) get plays roles contain:
      | locates:located     |
      | organises:organised |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(marriage) get plays roles contain:
      | locates:located     |
      | organises:organised |

  Scenario: Relation types can unset playing role types
    When put relation type: locates
    When relation(locates) create role: location
    When relation(locates) create role: located
    When put relation type: organises
    When relation(organises) create role: organiser
    When relation(organises) create role: organised
    When put relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    When relation(marriage) set plays role: locates:located
    When relation(marriage) set plays role: organises:organised
    When relation(marriage) unset plays role: locates:located
    Then relation(marriage) get plays roles do not contain:
      | locates:located |
    When transaction commits
    When connection opens schema transaction for database: typedb
    When relation(marriage) unset plays role: organises:organised
    Then relation(marriage) get plays roles do not contain:
      | locates:located     |
      | organises:organised |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(marriage) get plays roles do not contain:
      | locates:located     |
      | organises:organised |

  Scenario: Relation types can inherit playing role types
    When put relation type: locates
    When relation(locates) create role: locating
    When relation(locates) create role: located
    When put relation type: contractor-locates
    When relation(contractor-locates) create role: contractor-locating
    When relation(contractor-locates) create role: contractor-located
    When put relation type: employment
    When relation(employment) create role: employer
    When relation(employment) create role: employee
    When relation(employment) set plays role: locates:located
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) set plays role: contractor-locates:contractor-located
    Then relation(contractor-employment) get plays roles contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
    When transaction commits
    When connection opens schema transaction for database: typedb
    When put relation type: parttime-locates
    When relation(parttime-locates) create role: parttime-locating
    When relation(parttime-locates) create role: parttime-located
    When put relation type: parttime-employment
    When relation(parttime-employment) set supertype: contractor-employment
    When relation(parttime-employment) create role: parttime-employer
    When relation(parttime-employment) create role: parttime-employee
    When relation(parttime-employment) set plays role: parttime-locates:parttime-located
    Then relation(parttime-employment) get plays roles contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
      | parttime-locates:parttime-located     |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(contractor-employment) get plays roles contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
    Then relation(parttime-employment) get plays roles contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
      | parttime-locates:parttime-located     |

  Scenario: Relation types can inherit playing role types that are subtypes of each other
    When put relation type: locates
    When relation(locates) create role: locating
    When relation(locates) create role: located
    When put relation type: contractor-locates
    When relation(contractor-locates) set supertype: locates
    When relation(contractor-locates) create role: contractor-locating
    When relation(contractor-locates) get role(contractor-locating); set override: locating
    When relation(contractor-locates) create role: contractor-located
    When relation(contractor-locates) get role(contractor-located); set override: located
    When put relation type: employment
    When relation(employment) create role: employer
    When relation(employment) create role: employee
    When relation(employment) set plays role: locates:located
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) set plays role: contractor-locates:contractor-located
    Then relation(contractor-employment) get plays roles contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
    When transaction commits
    When connection opens schema transaction for database: typedb
    When put relation type: parttime-locates
    When relation(parttime-locates) set supertype: contractor-locates
    When relation(parttime-locates) create role: parttime-locating
    When relation(parttime-locates) get role(parttime-locating); set override: contractor-locating
    When relation(parttime-locates) create role: parttime-located
    When relation(parttime-locates) get role(parttime-located); set override: contractor-located
    When put relation type: parttime-employment
    When relation(parttime-employment) set supertype: contractor-employment
    When relation(parttime-employment) create role: parttime-employer
    When relation(parttime-employment) create role: parttime-employee
    When relation(parttime-employment) set plays role: parttime-locates:parttime-located
    Then relation(parttime-employment) get plays roles contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
      | parttime-locates:parttime-located     |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(contractor-employment) get plays roles contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
    Then relation(parttime-employment) get plays roles contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
      | parttime-locates:parttime-located     |

  Scenario: Relation types can override inherited playing role types
    When put relation type: locates
    When relation(locates) create role: locating
    When relation(locates) create role: located
    When put relation type: contractor-locates
    When relation(contractor-locates) set supertype: locates
    When relation(contractor-locates) create role: contractor-locating
    When relation(contractor-locates) get role(contractor-locating); set override: locating
    When relation(contractor-locates) create role: contractor-located
    When relation(contractor-locates) get role(contractor-located); set override: located
    When put relation type: employment
    When relation(employment) create role: employer
    When relation(employment) create role: employee
    When relation(employment) set plays role: locates:located
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) set plays role: contractor-locates:contractor-located
    When relation(contractor-employment) get plays role: contractor-locates:contractor-located; set override: locates:located
    Then relation(contractor-employment) get plays roles do not contain:
      | locates:located |
    When transaction commits
    When connection opens schema transaction for database: typedb
    When put relation type: parttime-locates
    When relation(parttime-locates) set supertype: contractor-locates
    When relation(parttime-locates) create role: parttime-locating
    When relation(parttime-locates) get role(parttime-locating); set override: contractor-locating
    When relation(parttime-locates) create role: parttime-located
    When relation(parttime-locates) get role(parttime-located); set override: contractor-located
    When put relation type: parttime-employment
    When relation(parttime-employment) set supertype: contractor-employment
    When relation(parttime-employment) create role: parttime-employer
    When relation(parttime-employment) create role: parttime-employee
    When relation(parttime-employment) set plays role: parttime-locates:parttime-located
    When relation(parttime-employment) get plays role: parttime-locates:parttime-located; set override: contractor-locates:contractor-located
    Then relation(parttime-employment) get plays roles do not contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(contractor-employment) get plays roles do not contain:
      | locates:located |
    Then relation(parttime-employment) get plays roles do not contain:
      | locates:located                       |
      | contractor-locates:contractor-located |

  Scenario: Relation types cannot redeclare inherited/overridden playing role types
    When put relation type: locates
    When relation(locates) create role: located
    When put relation type: contractor-locates
    When relation(contractor-locates) set supertype: locates
    When relation(contractor-locates) create role: contractor-located
    When relation(contractor-locates) get role(contractor-located); set override: located
    When put relation type: employment
    When relation(employment) create role: employee
    When relation(employment) set plays role: locates:located
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) set plays role: contractor-locates:contractor-located
    When relation(contractor-employment) get plays role: contractor-locates:contractor-located; set override: locates:located
    When put relation type: parttime-employment
    When relation(parttime-employment) set supertype: contractor-employment
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then relation(parttime-employment) set plays role: locates:located; fails
    When connection opens schema transaction for database: typedb
    Then relation(parttime-employment) set plays role: contractor-locates:contractor-located
    Then transaction commits; fails

  Scenario: Relation types cannot override declared playing role types
    When put relation type: locates
    When relation(locates) create role: locating
    When relation(locates) create role: located
    When put relation type: employment-locates
    When relation(employment-locates) set supertype: locates
    When relation(employment-locates) create role: employment-locating
    When relation(employment-locates) get role(employment-locating); set override: locating
    When relation(employment-locates) create role: employment-located
    When relation(employment-locates) get role(employment-located); set override: located
    When put relation type: employment
    When relation(employment) create role: employer
    When relation(employment) create role: employee
    When relation(employment) set plays role: locates:located
    Then relation(employment) set plays role: employment-locates:employment-located
    Then relation(employment) get plays role: employment-locates:employment-located; set override: locates:located; fails

  Scenario: Relation types cannot override inherited playing role types other than with their subtypes
    When put relation type: locates
    When relation(locates) create role: locating
    When relation(locates) create role: located
    When put relation type: contractor-locates
    When relation(contractor-locates) create role: contractor-locating
    When relation(contractor-locates) create role: contractor-located
    When put relation type: employment
    When relation(employment) create role: employer
    When relation(employment) create role: employee
    When relation(employment) set plays role: locates:located
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    Then relation(contractor-employment) set plays role: contractor-locates:contractor-located
    Then relation(contractor-employment) get plays role: contractor-locates:contractor-located; set override: locates:located; fails
