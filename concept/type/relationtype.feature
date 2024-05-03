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
    Given connection open schema session for database: typedb
    Given connection opens schema transaction for database: typedb

  Scenario: Root relation type cannot be deleted
    Then delete relation type: relation; fails

  Scenario: Relation and role types can be created
    When put relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    Then relation(marriage) exists: true
    Then relation(marriage) get supertype: relation
    Then relation(marriage) get role(husband) exists: true
    Then relation(marriage) get role(wife) exists: true
    Then relation(marriage) get role(husband) get supertype: relation:role
    Then relation(marriage) get role(wife) get supertype: relation:role
    Then relation(marriage) get roles contain:
      | marriage:husband |
      | marriage:wife    |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(marriage) exists: true
    Then relation(marriage) get supertype: relation
    Then relation(marriage) get role(husband) exists: true
    Then relation(marriage) get role(wife) exists: true
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
    Then relation(parentship) exists: false
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
    Then relation(marriage) exists: false
    Then relation(relation) get role(role) get subtypes do not contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(parentship) exists: false
    Then relation(marriage) exists: false
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
    When connection close all sessions
    When connection open data session for database: typedb
    When connection opens write transaction for database: typedb
    When $m = relation(marriage) create new instance
    When $a = entity(person) create new instance
    When relation $m add player for role(wife): $a
    When transaction commits
    When connection close all sessions
    When connection open schema session for database: typedb
    When connection opens schema transaction for database: typedb
    Then delete relation type: marriage; fails

  Scenario: Role types that have instances cannot be deleted
    When put relation type: marriage
    When relation(marriage) create role: wife
    When relation(marriage) create role: husband
    When put entity type: person
    When entity(person) set plays role: marriage:wife
    When transaction commits
    When connection close all sessions
    When connection open data session for database: typedb
    When connection opens write transaction for database: typedb
    When $m = relation(marriage) create new instance
    When $a = entity(person) create new instance
    When relation $m add player for role(wife): $a
    When transaction commits
    When connection close all sessions
    When connection open schema session for database: typedb
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
    Then relation(parentship) exists: false
    Then relation(marriage) exists: true
    When relation(marriage) get role(parent) set name: husband
    When relation(marriage) get role(child) set name: wife
    Then relation(marriage) get role(parent) exists: false
    Then relation(marriage) get role(child) exists: false
    Then relation(marriage) get label: marriage
    Then relation(marriage) get role(husband) get label: husband
    Then relation(marriage) get role(wife) get label: wife
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then relation(marriage) get label: marriage
    Then relation(marriage) get role(husband) get label: husband
    Then relation(marriage) get role(wife) get label: wife
    When relation(marriage) set label: employment
    Then relation(marriage) exists: false
    Then relation(employment) exists: true
    When relation(employment) get role(husband) set name: employee
    When relation(employment) get role(wife) set name: employer
    Then relation(employment) get role(husband) exists: false
    Then relation(employment) get role(wife) exists: false
    Then relation(employment) get label: employment
    Then relation(employment) get role(employee) get label: employee
    Then relation(employment) get role(employer) get label: employer
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(employment) exists: true
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
    When relation(fathership) create role: father as (DEPRECATED) parent
    When relation(fathership) create role: father-child as (DEPRECATED) child
    When put entity type: person
    When entity(person) set plays role: fathership:father
    Then transaction commits
    When connection close all sessions
    When connection open data session for database: typedb
    When connection opens write transaction for database: typedb
    Then $m = relation(fathership) create new instance
    When $a = entity(person) create new instance
    When relation $m add player for role(father): $a
    Then transaction commits
    When connection close all sessions
    When connection open schema session for database: typedb
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
    When relation(fathership) create role: father as (DEPRECATED) parent
    Then relation(fathership) get supertype: parentship
    Then relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(fathership) get role(child) get supertype: relation:role
    Then relation(fathership) get supertypes contain:
      | relation   |
      | parentship |
      | fathership |
    Then relation(fathership) get role(father) get supertypes contain:
      | relation:role     |
      | parentship:parent |
      | fathership:father |
    Then relation(fathership) get role(child) get supertypes contain:
      | relation:role    |
      | parentship:child |
    Then relation(parentship) get subtypes contain:
      | parentship |
      | fathership |
    Then relation(parentship) get role(parent) get subtypes contain:
      | parentship:parent |
      | fathership:father |
    Then relation(parentship) get role(child) get subtypes contain:
      | parentship:child |
    Then relation(relation) get subtypes contain:
      | relation   |
      | parentship |
      | fathership |
    Then relation(relation) get role(role) get subtypes contain:
      | relation:role     |
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
      | fathership |
    Then relation(fathership) get role(father) get supertypes contain:
      | relation:role     |
      | parentship:parent |
      | fathership:father |
    Then relation(fathership) get role(child) get supertypes contain:
      | relation:role    |
      | parentship:child |
    Then relation(parentship) get subtypes contain:
      | parentship |
      | fathership |
    Then relation(parentship) get role(parent) get subtypes contain:
      | parentship:parent |
      | fathership:father |
    Then relation(parentship) get role(child) get subtypes contain:
      | parentship:child |
    Then relation(relation) get subtypes contain:
      | relation   |
      | parentship |
      | fathership |
    Then relation(relation) get role(role) get subtypes contain:
      | relation:role     |
      | parentship:parent |
      | parentship:child  |
      | fathership:father |
    When put relation type: father-son
    When relation(father-son) set supertype: fathership
    When relation(father-son) create role: son as (DEPRECATED) child
    Then relation(father-son) get supertype: fathership
    Then relation(father-son) get role(father) get supertype: parentship:parent
    Then relation(father-son) get role(son) get supertype: parentship:child
    Then relation(father-son) get supertypes contain:
      | relation   |
      | parentship |
      | fathership |
      | father-son |
    Then relation(father-son) get role(father) get supertypes contain:
      | relation:role     |
      | parentship:parent |
      | fathership:father |
    Then relation(father-son) get role(son) get supertypes contain:
      | relation:role    |
      | parentship:child |
      | father-son:son   |
    Then relation(fathership) get subtypes contain:
      | fathership |
      | father-son |
    Then relation(fathership) get role(father) get subtypes contain:
      | fathership:father |
    Then relation(fathership) get role(child) get subtypes contain:
      | parentship:child |
      | father-son:son   |
    Then relation(parentship) get role(parent) get subtypes contain:
      | parentship:parent |
      | fathership:father |
    Then relation(parentship) get role(child) get subtypes contain:
      | parentship:child |
      | father-son:son   |
    Then relation(relation) get subtypes contain:
      | relation   |
      | parentship |
      | fathership |
    Then relation(relation) get role(role) get subtypes contain:
      | relation:role     |
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
      | father-son |
    Then relation(father-son) get role(father) get supertypes contain:
      | relation:role     |
      | parentship:parent |
      | fathership:father |
    Then relation(father-son) get role(son) get supertypes contain:
      | relation:role    |
      | parentship:child |
      | father-son:son   |
    Then relation(fathership) get supertype: parentship
    Then relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(fathership) get role(child) get supertype: relation:role
    Then relation(fathership) get supertypes contain:
      | relation   |
      | parentship |
      | fathership |
    Then relation(fathership) get role(father) get supertypes contain:
      | relation:role     |
      | parentship:parent |
      | fathership:father |
    Then relation(fathership) get role(child) get supertypes contain:
      | relation:role    |
      | parentship:child |
    Then relation(fathership) get subtypes contain:
      | fathership |
      | father-son |
    Then relation(fathership) get role(father) get subtypes contain:
      | fathership:father |
    Then relation(fathership) get role(child) get subtypes contain:
      | parentship:child |
    Then relation(parentship) get role(parent) get subtypes contain:
      | parentship:parent |
      | fathership:father |
    Then relation(parentship) get role(child) get subtypes contain:
      | parentship:child |
      | father-son:son   |
    Then relation(relation) get subtypes contain:
      | relation   |
      | parentship |
      | fathership |
    Then relation(relation) get role(role) get subtypes contain:
      | relation:role     |
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
    When relation(fathership) create role: father as (DEPRECATED) parent
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
    When relation(mothership) create role: mother as (DEPRECATED) parent
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
    When relation(fathership) create role: father as (DEPRECATED) parent
    Then relation(fathership) get overridden role(father) exists: true
    Then relation(fathership) get overridden role(father) get label: parent
    Then relation(fathership) get roles do not contain:
      | parentship:parent |
    When transaction commits
    When connection opens schema transaction for database: typedb
    When put relation type: mothership
    When relation(mothership) set supertype: parentship
    When relation(mothership) create role: mother as (DEPRECATED) parent
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
    Then relation(parentship) create role: father as (DEPRECATED) parent; fails

  Scenario: Relation types can update existing roles override a newly defined role it inherits
    When put relation type: parentship
    When relation(parentship) create role: other-role
    When put relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When transaction commits
    When connection opens schema transaction for database: typedb
    When relation(parentship) create role: parent
    When relation(fathership) create role: father as (DEPRECATED) parent
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(fathership) get overridden role(father) get label: parent

  Scenario: Relation types can have keys
    When put attribute type: license
    When attribute(license) set value-type: string
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) set owns: license
    When relation(marriage) get owns: license; set annotation: @key
    Then relation(marriage) get owns: license; get annotations contain: @key
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(marriage) get owns: license; get annotations contain: @key

--- STARTED SKIPPING ---

  Scenario: Relation types can unset keys
    When put attribute type: license
    When attribute(license) set value type: string
    When put attribute type: certificate
    When attribute(certificate) set value type: string
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) set owns: license
    When relation(marriage) get owns: license, set annotation: key
    When relation(marriage) set owns: certificate
    When relation(marriage) get owns: certificate, set annotation: key
    When relation(marriage) unset owns: license
    Then relation(marriage) get owns, with annotations (DEPRECATED): key; do not contain:
      | license |
    When transaction commits
    When connection opens schema transaction for database: typedb
    When relation(marriage) unset owns: certificate
    Then relation(marriage) get owns, with annotations (DEPRECATED): key; do not contain:
      | license     |
      | certificate |

  Scenario: Relation types can have keys of all keyable attributes
    When put attribute type: is-permanent
    When attribute(is-permanent) set value-type: boolean
    When put attribute type: contract-years
    When attribute(contract-years) set value-type: long
    When put attribute type: salary
    When attribute(salary) set value-type: double
    When put attribute type: reference
    When attribute(reference) set value-type: string
    When put attribute type: start-date
    When attribute(start-date) set value-type: datetime
    When put relation type: employment
    When relation(employment) set owns: contract-years
    When relation(employment) get owns: contract-years, set annotation: key
    When relation(employment) set owns: reference
    When relation(employment) get owns: reference, set annotation: key
    When relation(employment) set owns: start-date
    When relation(employment) get owns: start-date, set annotation: key

  Scenario: Relation types cannot have keys of attributes that are not keyable
    When put attribute type: is-permanent
    When attribute(is-permanent) set value-type: boolean
    When put relation type: employment
    Then relation(employment) set owns: is-permanent, with annotations: key
    When put attribute type: salary
    When attribute(salary) set value-type: double
    When put relation type: employment
    Then relation(employment) set owns: salary, with annotations: key; fails

  Scenario: Relation types can have attributes
    When put attribute type: date
    When attribute(date) set value-type: datetime
    When put attribute type: religion
    When attribute(religion) set value-type: string
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) set owns: date
    When relation(marriage) set owns: religion
    Then relation(marriage) get owns contain:
      | date     |
      | religion |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(marriage) get owns contain:
      | date     |
      | religion |

  Scenario: Relation types can unset attributes
    When put attribute type: date
    When attribute(date) set value-type: datetime
    When put attribute type: religion
    When attribute(religion) set value-type: string
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) set owns: date
    When relation(marriage) set owns: religion
    When relation(marriage) unset owns: religion
    Then relation(marriage) get owns do not contain:
      | religion |
    When transaction commits
    When connection opens schema transaction for database: typedb
    When relation(marriage) unset owns: date
    Then relation(marriage) get owns do not contain:
      | date     |
      | religion |

  Scenario: Relation types can have keys and attributes
    When put attribute type: license
    When attribute(license) set value-type: string
    When put attribute type: certificate
    When attribute(certificate) set value-type: string
    When put attribute type: date
    When attribute(date) set value-type: datetime
    When put attribute type: religion
    When attribute(religion) set value-type: string
    When put relation type: marriage
    When relation(marriage) create role: wife
    When relation(marriage) set owns: license
    When relation(marriage) get owns: license, set annotation: key
    When relation(marriage) set owns: certificate
    When relation(marriage) get owns: certificate, set annotation: key
    When relation(marriage) set owns: date
    When relation(marriage) set owns: religion
    Then relation(marriage) get owns, with annotations (DEPRECATED): key; contain:
      | license     |
      | certificate |
    Then relation(marriage) get owns contain:
      | license     |
      | certificate |
      | date        |
      | religion    |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(marriage) get owns, with annotations (DEPRECATED): key; contain:
      | license     |
      | certificate |
    Then relation(marriage) get owns contain:
      | license     |
      | certificate |
      | date        |
      | religion    |

  Scenario: Relation types can inherit keys and attributes
    When put attribute type: employment-reference
    When attribute(employment-reference) set value-type: string
    When put attribute type: employment-hours
    When attribute(employment-hours) set value-type: long
    When put attribute type: contractor-reference
    When attribute(contractor-reference) set value-type: string
    When put attribute type: contractor-hours
    When attribute(contractor-hours) set value-type: long
    When put relation type: employment
    When relation(employment) create role: employee
    When relation(employment) create role: employer
    When relation(employment) set owns: employment-reference
    When relation(employment) get owns: employment-reference, set annotation: key
    When relation(employment) set owns: employment-hours
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) set owns: contractor-reference
    When relation(contractor-employment) get owns: contractor-reference, set annotation: key
    When relation(contractor-employment) set owns: contractor-hours
    Then relation(contractor-employment) get owns, with annotations (DEPRECATED): key; contain:
      | employment-reference |
      | contractor-reference |
    Then relation(contractor-employment) get owns contain:
      | employment-reference |
      | contractor-reference |
      | employment-hours     |
      | contractor-hours     |
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then relation(contractor-employment) get owns, with annotations (DEPRECATED): key; contain:
      | employment-reference |
      | contractor-reference |
    Then relation(contractor-employment) get owns contain:
      | employment-reference |
      | contractor-reference |
      | employment-hours     |
      | contractor-hours     |
    When put attribute type: parttime-reference
    When attribute(parttime-reference) set value-type: string
    When put attribute type: parttime-hours
    When attribute(parttime-hours) set value-type: long
    When put relation type: parttime-employment
    When relation(parttime-employment) set supertype: contractor-employment
    When relation(parttime-employment) set owns: parttime-reference
    When relation(parttime-employment) get owns: parttime-reference, set annotation: key
    When relation(parttime-employment) set owns: parttime-hours
    Then relation(parttime-employment) get owns, with annotations (DEPRECATED): key; contain:
      | employment-reference |
      | contractor-reference |
      | parttime-reference   |
    Then relation(parttime-employment) get owns contain:
      | employment-reference |
      | contractor-reference |
      | parttime-reference   |
      | employment-hours     |
      | contractor-hours     |
      | parttime-hours       |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(contractor-employment) get owns, with annotations (DEPRECATED): key; contain:
      | employment-reference |
      | contractor-reference |
    Then relation(contractor-employment) get owns contain:
      | employment-reference |
      | contractor-reference |
      | employment-hours     |
      | contractor-hours     |
    Then relation(parttime-employment) get owns, with annotations (DEPRECATED): key; contain:
      | employment-reference |
      | contractor-reference |
      | parttime-reference   |
    Then relation(parttime-employment) get owns contain:
      | employment-reference |
      | contractor-reference |
      | parttime-reference   |
      | employment-hours     |
      | contractor-hours     |
      | parttime-hours       |

  Scenario: Relation types can inherit keys and attributes that are subtypes of each other
    When put attribute type: employment-reference
    When attribute(employment-reference) set value-type: string
    When attribute(employment-reference) set annotation: @abstract
    When put attribute type: employment-hours
    When attribute(employment-hours) set value-type: long
    When attribute(employment-hours) set annotation: @abstract
    When put attribute type: contractor-reference
    When attribute(contractor-reference) set value-type: string
    When attribute(contractor-reference) set annotation: @abstract
    When attribute(contractor-reference) set supertype: employment-reference
    When put attribute type: contractor-hours
    When attribute(contractor-hours) set value-type: long
    When attribute(contractor-hours) set annotation: @abstract
    When attribute(contractor-hours) set supertype: employment-hours
    When put relation type: employment
    When relation(employment) set annotation: @abstract
    When relation(employment) create role: employee
    When relation(employment) create role: employer
    When relation(employment) set owns: employment-reference
    When relation(employment) get owns: employment-reference, set annotation: key
    When relation(employment) set owns: employment-hours
    When put relation type: contractor-employment
    When relation(contractor-employment) set annotation: @abstract
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) set owns: contractor-reference
    When relation(contractor-employment) get owns: contractor-reference, set annotation: key
    When relation(contractor-employment) set owns: contractor-hours
    Then relation(contractor-employment) get owns, with annotations (DEPRECATED): key; contain:
      | employment-reference |
      | contractor-reference |
    Then relation(contractor-employment) get owns contain:
      | employment-reference |
      | contractor-reference |
      | employment-hours     |
      | contractor-hours     |
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then relation(contractor-employment) get owns, with annotations (DEPRECATED): key; contain:
      | employment-reference |
      | contractor-reference |
    Then relation(contractor-employment) get owns contain:
      | employment-reference |
      | contractor-reference |
      | employment-hours     |
      | contractor-hours     |
    When put attribute type: parttime-reference
    When attribute(parttime-reference) set value-type: string
    When attribute(parttime-reference) set supertype: contractor-reference
    When put attribute type: parttime-hours
    When attribute(parttime-hours) set value-type: long
    When attribute(parttime-hours) set supertype: contractor-hours
    When put relation type: parttime-employment
    When relation(parttime-employment) set annotation: @abstract
    When relation(parttime-employment) set supertype: contractor-employment
    When relation(parttime-employment) set owns: parttime-reference
    When relation(parttime-employment) get owns: parttime-reference, set annotation: key
    When relation(parttime-employment) set owns: parttime-hours
    Then relation(parttime-employment) get owns, with annotations (DEPRECATED): key; contain:
      | employment-reference |
      | contractor-reference |
      | parttime-reference   |
    Then relation(parttime-employment) get owns contain:
      | employment-reference |
      | contractor-reference |
      | parttime-reference   |
      | employment-hours     |
      | contractor-hours     |
      | parttime-hours       |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(contractor-employment) get owns, with annotations (DEPRECATED): key; contain:
      | employment-reference |
      | contractor-reference |
    Then relation(contractor-employment) get owns contain:
      | employment-reference |
      | contractor-reference |
      | employment-hours     |
      | contractor-hours     |
    Then relation(parttime-employment) get owns, with annotations (DEPRECATED): key; contain:
      | employment-reference |
      | contractor-reference |
      | parttime-reference   |
    Then relation(parttime-employment) get owns contain:
      | employment-reference |
      | contractor-reference |
      | parttime-reference   |
      | employment-hours     |
      | contractor-hours     |
      | parttime-hours       |

  Scenario: Relation types can override inherited keys and attributes
    When put attribute type: employment-reference
    When attribute(employment-reference) set value-type: string
    When attribute(employment-reference) set annotation: @abstract
    When put attribute type: employment-hours
    When attribute(employment-hours) set value-type: long
    When attribute(employment-hours) set annotation: @abstract
    When put attribute type: contractor-reference
    When attribute(contractor-reference) set value-type: string
    When attribute(contractor-reference) set annotation: @abstract
    When attribute(contractor-reference) set supertype: employment-reference
    When put attribute type: contractor-hours
    When attribute(contractor-hours) set value-type: long
    When attribute(contractor-hours) set annotation: @abstract
    When attribute(contractor-hours) set supertype: employment-hours
    When put relation type: employment
    When relation(employment) set annotation: @abstract
    When relation(employment) create role: employee
    When relation(employment) create role: employer
    When relation(employment) set owns: employment-reference
    When relation(employment) get owns: employment-reference, set annotation: key
    When relation(employment) set owns: employment-hours
    When put relation type: contractor-employment
    When relation(contractor-employment) set annotation: @abstract
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) set owns: contractor-reference
    When relation(contractor-employment) get owns: contractor-reference; set override: employment-reference
    When relation(contractor-employment) set owns: contractor-hours as (DEPRECATED) employment-hours
    Then relation(contractor-employment) get owns, with annotations (DEPRECATED): key; contain:
      | contractor-reference |
    Then relation(contractor-employment) get owns, with annotations (DEPRECATED): key; do not contain:
      | employment-reference |
    Then relation(contractor-employment) get owns contain:
      | contractor-reference |
      | contractor-hours     |
    Then relation(contractor-employment) get owns do not contain:
      | employment-reference |
      | employment-hours     |
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then relation(contractor-employment) get owns, with annotations (DEPRECATED): key; contain:
      | contractor-reference |
    Then relation(contractor-employment) get owns, with annotations (DEPRECATED): key; do not contain:
      | employment-reference |
    Then relation(contractor-employment) get owns contain:
      | contractor-reference |
      | contractor-hours     |
    Then relation(contractor-employment) get owns do not contain:
      | employment-reference |
      | employment-hours     |
    When put attribute type: parttime-reference
    When attribute(parttime-reference) set value-type: string
    When attribute(parttime-reference) set supertype: contractor-reference
    When put attribute type: parttime-hours
    When attribute(parttime-hours) set value-type: long
    When attribute(parttime-hours) set supertype: contractor-hours
    When put relation type: parttime-employment
    When relation(parttime-employment) set supertype: contractor-employment
    When relation(parttime-employment) create role: parttime-employer as (DEPRECATED) employer
    When relation(parttime-employment) create role: parttime-employee as (DEPRECATED) employee
    When relation(parttime-employment) set owns: parttime-reference as (DEPRECATED) contractor-reference
    When relation(parttime-employment) set owns: parttime-hours as (DEPRECATED) contractor-hours
    Then relation(parttime-employment) get owns, with annotations (DEPRECATED): key; contain:
      | parttime-reference |
    Then relation(parttime-employment) get owns contain:
      | parttime-reference |
      | parttime-hours     |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(contractor-employment) get owns, with annotations (DEPRECATED): key; contain:
      | contractor-reference |
    Then relation(contractor-employment) get owns, with annotations (DEPRECATED): key; do not contain:
      | employment-reference |
    Then relation(contractor-employment) get owns contain:
      | contractor-reference |
      | contractor-hours     |
    Then relation(contractor-employment) get owns do not contain:
      | employment-reference |
      | employment-hours     |
    Then relation(parttime-employment) get owns, with annotations (DEPRECATED): key; contain:
      | parttime-reference |
    Then relation(parttime-employment) get owns, with annotations (DEPRECATED): key; do not contain:
      | employment-reference |
      | contractor-reference |
    Then relation(parttime-employment) get owns contain:
      | parttime-reference |
      | parttime-hours     |
    Then relation(parttime-employment) get owns, with annotations (DEPRECATED): key; do not contain:
      | employment-reference |
      | contractor-reference |
      | employment-hours     |
      | contractor-hours     |

  Scenario: Relation types can override inherited attributes as (DEPRECATED) keys
    When put attribute type: employment-reference
    When attribute(employment-reference) set value-type: string
    When attribute(employment-reference) set annotation: @abstract
    When put attribute type: contractor-reference
    When attribute(contractor-reference) set value-type: string
    When attribute(contractor-reference) set supertype: employment-reference
    When put relation type: employment
    When relation(employment) set annotation: @abstract
    When relation(employment) create role: employer
    When relation(employment) create role: employee
    When relation(employment) set owns: employment-reference
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) create role: contractor-employer as (DEPRECATED) employer
    When relation(contractor-employment) create role: contractor-employee as (DEPRECATED) employee
    When relation(contractor-employment) set owns: contractor-reference as (DEPRECATED) employment-reference
    When relation(contractor-employment) get owns: contractor-reference as (DEPRECATED) employment-reference, set annotation: key
    Then relation(contractor-employment) get owns, with annotations (DEPRECATED): key; contain:
      | contractor-reference |
    Then relation(contractor-employment) get owns, with annotations (DEPRECATED): key; do not contain:
      | employment-reference |
    Then relation(contractor-employment) get owns contain:
      | contractor-reference |
    Then relation(contractor-employment) get owns do not contain:
      | employment-reference |
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(contractor-employment) get owns, with annotations (DEPRECATED): key; contain:
      | contractor-reference |
    Then relation(contractor-employment) get owns, with annotations (DEPRECATED): key; do not contain:
      | employment-reference |
    Then relation(contractor-employment) get owns contain:
      | contractor-reference |
    Then relation(contractor-employment) get owns do not contain:
      | employment-reference |

   # TODO: Invalid scenario because we set annotations independently. Check if Unset annotation scenario exists
  Scenario: Relation types can redeclare keys as (DEPRECATED) attributes
    When put attribute type: date
    When attribute(date) set value-type: datetime
    When put attribute type: license
    When attribute(license) set value-type: string
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) set owns: date
    When relation(marriage) get owns: date, set annotation: key
    When relation(marriage) set owns: license
    When relation(marriage) get owns: license, set annotation: key
    When relation(marriage) set owns: date
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then relation(marriage) set owns: license

  Scenario: Relation types can redeclare attributes as (DEPRECATED) keys
    When put attribute type: date
    When attribute(date) set value-type: datetime
    When put attribute type: license
    When attribute(license) set value-type: string
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) set owns: date
    When relation(marriage) set owns: license
    Then relation(marriage) set owns: date, with annotations: key
    When transaction commits
    When connection opens schema transaction for database: typedb
    When relation(marriage) set owns: license
    When relation(marriage) get owns: license, set annotation: key

  Scenario: Relation types cannot redeclare inherited keys and attributes
    When put attribute type: employment-reference
    When attribute(employment-reference) set value-type: string
    When put attribute type: employment-hours
    When attribute(employment-hours) set value-type: long
    When put relation type: employment
    When relation(employment) create role: employee
    When relation(employment) create role: employer
    When relation(employment) set owns: employment-reference
    When relation(employment) get owns: employment-reference, set annotation: key
    When relation(employment) set owns: employment-hours
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then relation(contractor-employment) set owns: employment-reference, with annotations: key
    Then transaction commits; fails
    When connection opens schema transaction for database: typedb
    Then relation(contractor-employment) set owns: employment-hours
    Then transaction commits; fails

  Scenario: Relation types cannot redeclare inherited key attribute types
    When put attribute type: employment-reference
    When attribute(employment-reference) set value-type: string
    When attribute(employment-reference) set annotation: @abstract
    When put relation type: employment
    When relation(employment) set annotation: @abstract
    When relation(employment) create role: employee
    When relation(employment) set owns: employment-reference
    When relation(employment) get owns: employment-reference, set annotation: key
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When put relation type: parttime-employment
    When relation(parttime-employment) set supertype: contractor-employment
    Then relation(parttime-employment) set owns: employment-reference, with annotations: key
    Then transaction commits; fails

  Scenario: Relation types cannot redeclare overridden key attribute types
    When put attribute type: employment-reference
    When attribute(employment-reference) set value-type: string
    When attribute(employment-reference) set annotation: @abstract
    When put attribute type: contractor-reference
    When attribute(contractor-reference) set value-type: string
    When attribute(contractor-reference) set supertype: employment-reference
    When put relation type: employment
    When relation(employment) set annotation: @abstract
    When relation(employment) create role: employee
    When relation(employment) set owns: employment-reference
    When relation(employment) get owns: employment-reference, set annotation: key
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) set owns: contractor-reference as (DEPRECATED) employment-reference
    When put relation type: parttime-employment
    When relation(parttime-employment) set supertype: contractor-employment
    Then relation(parttime-employment) set owns: contractor-reference, with annotations: key
    Then transaction commits; fails

  Scenario: Relation types cannot redeclare inherited owns
    When put attribute type: employment-hours
    When attribute(employment-hours) set value-type: long
    When attribute(employment-hours) set annotation: @abstract
    When put relation type: employment
    When relation(employment) set annotation: @abstract
    When relation(employment) create role: employee
    When relation(employment) set owns: employment-hours
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When put relation type: parttime-employment
    When relation(parttime-employment) set supertype: contractor-employment
    Then relation(parttime-employment) set owns: employment-hours
    Then transaction commits; fails

  Scenario: Relation types cannot redeclare overridden owns
    When put attribute type: employment-hours
    When attribute(employment-hours) set value-type: long
    When attribute(employment-hours) set annotation: @abstract
    When put attribute type: contractor-hours
    When attribute(contractor-hours) set value-type: long
    When attribute(contractor-hours) set supertype: employment-hours
    When put relation type: employment
    When relation(employment) set annotation: @abstract
    When relation(employment) create role: employee
    When relation(employment) set owns: employment-hours
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) set owns: contractor-hours as (DEPRECATED) employment-hours
    When put relation type: parttime-employment
    When relation(parttime-employment) set supertype: contractor-employment
    Then relation(parttime-employment) set owns: contractor-hours
    Then transaction commits; fails

  Scenario: Relation types cannot override declared keys and attributes
    When put attribute type: reference
    When attribute(reference) set value-type: string
    When attribute(reference) set annotation: @abstract
    When put attribute type: social-security-number
    When attribute(social-security-number) set value-type: string
    When attribute(social-security-number) set supertype: reference
    When put attribute type: hours
    When attribute(hours) set value-type: long
    When attribute(hours) set annotation: @abstract
    When put attribute type: max-hours
    When attribute(max-hours) set value-type: long
    When attribute(max-hours) set supertype: hours
    When put relation type: employment
    When relation(employment) set annotation: @abstract
    When relation(employment) create role: employee
    When relation(employment) create role: employer
    When relation(employment) set owns: reference
    When relation(employment) get owns: reference, set annotation: key
    When relation(employment) set owns: hours
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then relation(employment) set owns: social-security-number as (DEPRECATED) reference, with annotations: key; fails
    When connection opens schema transaction for database: typedb
    Then relation(employment) set owns: max-hours as (DEPRECATED) hours; fails

  Scenario: Relation types cannot override inherited keys and attributes other than with their subtypes
    When put attribute type: employment-reference
    When attribute(employment-reference) set value-type: string
    When put attribute type: employment-hours
    When attribute(employment-hours) set value-type: long
    When put attribute type: contractor-reference
    When attribute(contractor-reference) set value-type: string
    When put attribute type: contractor-hours
    When attribute(contractor-hours) set value-type: long
    When put relation type: employment
    When relation(employment) create role: employee
    When relation(employment) create role: employer
    When relation(employment) set owns: employment-reference
    When relation(employment) get owns: employment-reference, set annotation: key
    When relation(employment) set owns: employment-hours
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then relation(contractor-employment) set owns: contractor-reference as (DEPRECATED) employment-reference, with annotations: key; fails
    When connection opens schema transaction for database: typedb
    Then relation(contractor-employment) set owns: contractor-hours as (DEPRECATED) employment-hours; fails

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
    When relation(contractor-locates) create role: contractor-locating as (DEPRECATED) locating
    When relation(contractor-locates) create role: contractor-located as (DEPRECATED) located
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
    When relation(parttime-locates) create role: parttime-locating as (DEPRECATED) contractor-locating
    When relation(parttime-locates) create role: parttime-located as (DEPRECATED) contractor-located
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
    When relation(contractor-locates) create role: contractor-locating as (DEPRECATED) locating
    When relation(contractor-locates) create role: contractor-located as (DEPRECATED) located
    When put relation type: employment
    When relation(employment) create role: employer
    When relation(employment) create role: employee
    When relation(employment) set plays role: locates:located
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) set plays role: contractor-locates:contractor-located as (DEPRECATED) locates:located
    Then relation(contractor-employment) get plays roles do not contain:
      | locates:located |
    When transaction commits
    When connection opens schema transaction for database: typedb
    When put relation type: parttime-locates
    When relation(parttime-locates) set supertype: contractor-locates
    When relation(parttime-locates) create role: parttime-locating as (DEPRECATED) contractor-locating
    When relation(parttime-locates) create role: parttime-located as (DEPRECATED) contractor-located
    When put relation type: parttime-employment
    When relation(parttime-employment) set supertype: contractor-employment
    When relation(parttime-employment) create role: parttime-employer
    When relation(parttime-employment) create role: parttime-employee
    When relation(parttime-employment) set plays role: parttime-locates:parttime-located as (DEPRECATED) contractor-locates:contractor-located
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
    When relation(contractor-locates) create role: contractor-located as (DEPRECATED) located
    When put relation type: employment
    When relation(employment) create role: employee
    When relation(employment) set plays role: locates:located
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) set plays role: contractor-locates:contractor-located as (DEPRECATED) locates:located
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
    When relation(employment-locates) create role: employment-locating as (DEPRECATED) locating
    When relation(employment-locates) create role: employment-located as (DEPRECATED) located
    When put relation type: employment
    When relation(employment) create role: employer
    When relation(employment) create role: employee
    When relation(employment) set plays role: locates:located
    Then relation(employment) set plays role: employment-locates:employment-located as (DEPRECATED) locates:located; fails

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
    Then relation(contractor-employment) set plays role: contractor-locates:contractor-located as (DEPRECATED) locates:located; fails
