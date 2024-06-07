# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Concept Plays

  # TODO: Refactor "DEPRECATED"!
  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb

    Given put entity type: person
    Given put entity type: customer
    Given put entity type: subscriber
    # Notice: supertypes are the same, but can be overridden for the second subtype inside the tests
    Given entity(customer) set supertype: person
    Given entity(subscriber) set supertype: person
    Given put relation type: description
    Given relation(description) create role: object
    Given put relation type: registration
    Given put relation type: profile
    # Notice: supertypes are the same, but can be overridden for the second subtype inside the tests
    Given relation(registration) set supertype: description
    Given relation(profile) set supertype: description

    Given transaction commits
    Given connection open schema transaction for database: typedb

########################
# plays common
########################

  Scenario: Entity types can play role types
    When put relation type: marriage
    When relation(marriage) create role: husband
    When entity(person) set plays role: marriage:husband
    Then entity(person) get plays roles contain:
      | marriage:husband |
    Then relation(marriage) get role(husband) get players contain:
      | person |
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(marriage) create role: wife
    When entity(person) set plays role: marriage:wife
    Then entity(person) get plays roles contain:
      | marriage:husband |
      | marriage:wife    |
    Then relation(marriage) get role(husband) get players contain:
      | person |
    Then relation(marriage) get role(wife) get players contain:
      | person |
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get plays roles contain:
      | marriage:husband |
      | marriage:wife    |
    Then relation(marriage) get role(husband) get players contain:
      | person |
    Then relation(marriage) get role(wife) get players contain:
      | person |

  Scenario: Entity types cannot play entities, relations, attributes, structs, structs fields, and non-existing things
    When put entity type: car
    When put relation type: credit
    When put attribute type: id
    When attribute(id) set value-type: long
    When relation(credit) create role: creditor
    # TODO: Create structs in concept api
    When put struct type: passport
    When struct(passport) create field: birthday
    When struct(passport) get field(birthday); set value-type: datetime
    Then entity(person) set plays role: car; fails
    Then entity(person) set plays role: credit; fails
    Then entity(person) set plays role: id; fails
    Then entity(person) set plays role: passport; fails
    Then entity(person) set plays role: passport:birthday; fails
    Then entity(person) set plays role: does-not-exist; fails
    Then entity(person) get plays roles is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get plays roles is empty

  Scenario: Entity types can unset playing role types
    When put relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    When entity(person) set plays role: marriage:husband
    When entity(person) set plays role: marriage:wife
    Then entity(person) unset plays role: marriage:husband
    Then entity(person) get plays roles do not contain:
      | marriage:husband |
    Then relation(marriage) get role(husband) get players do not contain:
      | person |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) unset plays role: marriage:wife
    Then entity(person) get plays roles do not contain:
      | marriage:husband |
      | marriage:wife    |
    Then relation(marriage) get role(husband) get players do not contain:
      | person |
    Then relation(marriage) get role(wife) get players do not contain:
      | person |
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get plays roles do not contain:
      | marriage:husband |
      | marriage:wife    |
    Then relation(marriage) get role(husband) get players do not contain:
      | person |
    Then relation(marriage) get role(wife) get players do not contain:
      | person |

  Scenario: Entity types can inherit playing role types
    When put relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When put relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    When put entity type: animal
    When entity(animal) set plays role: parentship:parent
    When entity(animal) set plays role: parentship:child
    When entity(person) set supertype: animal
    When entity(person) set plays role: marriage:husband
    When entity(person) set plays role: marriage:wife
    Then entity(person) get plays roles contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    Then entity(person) get plays roles explicit contain:
      | marriage:husband |
      | marriage:wife    |
    Then entity(person) get plays roles explicit do not contain:
      | parentship:parent |
      | parentship:child  |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get plays roles contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    Then entity(person) get plays roles explicit contain:
      | marriage:husband |
      | marriage:wife    |
    Then entity(person) get plays roles explicit do not contain:
      | parentship:parent |
      | parentship:child  |
    When put relation type: sales
    When relation(sales) create role: buyer
    When put entity type: customer
    When entity(customer) set supertype: person
    When entity(customer) set plays role: sales:buyer
    Then entity(customer) get plays roles contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
      | sales:buyer       |
    Then entity(customer) get plays roles explicit contain:
      | sales:buyer |
    Then entity(customer) get plays roles explicit do not contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(animal) get plays roles contain:
      | parentship:parent |
      | parentship:child  |
    Then entity(person) get plays roles contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    Then entity(customer) get plays roles contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
      | sales:buyer       |

  Scenario: Entity types can inherit playing role types that are subtypes of each other
    When put relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When put relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father); set override: parent
    When entity(person) set plays role: parentship:parent
    When entity(person) set plays role: parentship:child
    When put entity type: man
    When entity(man) set supertype: person
    When entity(man) set plays role: fathership:father
    Then entity(man) get plays roles contain:
      | parentship:parent |
      | fathership:father |
      | parentship:child  |
    Then entity(man) get plays roles explicit contain:
      | fathership:father |
    Then entity(man) get plays roles explicit do not contain:
      | parentship:parent |
      | parentship:child  |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(man) get plays roles contain:
      | parentship:parent |
      | fathership:father |
      | parentship:child  |
    Then entity(man) get plays roles explicit contain:
      | fathership:father |
    Then entity(man) get plays roles explicit do not contain:
      | parentship:parent |
      | parentship:child  |
    When put relation type: mothership
    When relation(mothership) set supertype: parentship
    When relation(mothership) create role: mother
    When relation(mothership) get role(mother); set override: parent
    When put entity type: woman
    When entity(woman) set supertype: person
    When entity(woman) set plays role: mothership:mother
    Then entity(woman) get plays roles contain:
      | parentship:parent |
      | mothership:mother |
      | parentship:child  |
    Then entity(woman) get plays roles explicit contain:
      | mothership:mother |
    Then entity(woman) get plays roles explicit do not contain:
      | parentship:parent |
      | parentship:child  |
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get plays roles contain:
      | parentship:parent |
      | parentship:child  |
    Then entity(man) get plays roles contain:
      | parentship:parent |
      | fathership:father |
      | parentship:child  |
    Then entity(man) get plays roles explicit contain:
      | fathership:father |
    Then entity(man) get plays roles explicit do not contain:
      | parentship:parent |
      | parentship:child  |
    Then entity(woman) get plays roles contain:
      | parentship:parent |
      | mothership:mother |
      | parentship:child  |
    Then entity(woman) get plays roles explicit contain:
      | mothership:mother |
    Then entity(woman) get plays roles explicit do not contain:
      | parentship:parent |
      | parentship:child  |

  Scenario: Entity types can override inherited playing role types
    When put relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When put relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father); set override: parent
    When entity(person) set plays role: parentship:parent
    When entity(person) set plays role: parentship:child
    When put entity type: man
    When entity(man) set supertype: person
    When entity(man) set plays role: fathership:father
    When entity(man) get plays role: fathership:father; set override: parentship:parent
    Then entity(man) get plays roles contain:
      | fathership:father |
      | parentship:child  |
    Then entity(man) get plays roles do not contain:
      | parentship:parent |
    Then entity(man) get plays roles explicit contain:
      | fathership:father |
    Then entity(man) get plays roles explicit do not contain:
      | parentship:child  |
      | parentship:parent |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(man) get plays roles contain:
      | fathership:father |
      | parentship:child  |
    Then entity(man) get plays roles do not contain:
      | parentship:parent |
    Then entity(man) get plays roles explicit contain:
      | fathership:father |
    Then entity(man) get plays roles explicit do not contain:
      | parentship:child  |
      | parentship:parent |
    When put relation type: mothership
    When relation(mothership) set supertype: parentship
    When relation(mothership) create role: mother
    When relation(mothership) get role(mother); set override: parent
    When put entity type: woman
    When entity(woman) set supertype: person
    When entity(woman) set plays role: mothership:mother
    When entity(woman) get plays role: mothership:mother; set override: parentship:parent
    Then entity(woman) get plays roles contain:
      | mothership:mother |
      | parentship:child  |
    Then entity(woman) get plays roles do not contain:
      | parentship:parent |
    Then entity(woman) get plays roles explicit contain:
      | mothership:mother |
    Then entity(woman) get plays roles explicit do not contain:
      | parentship:child  |
      | parentship:parent |
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get plays roles contain:
      | parentship:parent |
      | parentship:child  |
    Then entity(man) get plays roles contain:
      | fathership:father |
      | parentship:child  |
    Then entity(man) get plays roles do not contain:
      | parentship:parent |
    Then entity(man) get plays roles explicit contain:
      | fathership:father |
    Then entity(man) get plays roles explicit do not contain:
      | parentship:child  |
      | parentship:parent |
    Then entity(woman) get plays roles contain:
      | mothership:mother |
      | parentship:child  |
    Then entity(woman) get plays roles do not contain:
      | parentship:parent |
    Then entity(woman) get plays roles explicit contain:
      | mothership:mother |
    Then entity(woman) get plays roles explicit do not contain:
      | parentship:child  |
      | parentship:parent |

  Scenario: Entity types cannot redeclare inherited/overridden playing role types
    When put relation type: parentship
    When relation(parentship) create role: parent
    When put relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father); set override: parent
    When entity(person) set plays role: parentship:parent
    When put entity type: man
    When entity(man) set supertype: person
    When entity(man) set plays role: fathership:father
    When entity(man) get plays role: fathership:father; set override: parentship:parent
    When put entity type: boy
    When entity(boy) set supertype: man
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(boy) set plays role: parentship:parent; fails
    When connection open schema transaction for database: typedb
    Then entity(boy) set plays role: fathership:father
    Then transaction commits; fails

  Scenario: Entity types cannot override declared playing role types
    When put relation type: parentship
    When relation(parentship) create role: parent
    When put relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father); set override: parent
    When entity(person) set plays role: parentship:parent
    Then entity(person) set plays role: fathership:father
    Then entity(person) get plays role: fathership:father; set override: fathership:father; fails
    Then entity(person) get plays role: fathership:father; set override: parentship:parent; fails

  Scenario: Entity types cannot override inherited playing role types other than with their subtypes
    When put relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When put relation type: fathership
    When relation(fathership) create role: father
    When entity(person) set plays role: parentship:parent
    When entity(person) set plays role: parentship:child
    When put entity type: man
    When entity(man) set supertype: person
    Then entity(man) set plays role: fathership:father
    Then entity(man) get plays role: fathership:father; set override: fathership:father; fails
    Then entity(man) get plays role: fathership:father; set override: parentship:parent; fails

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
    When connection open schema transaction for database: typedb
    When put relation type: organises
    When relation(organises) create role: organiser
    When relation(organises) create role: organised
    When relation(marriage) set plays role: organises:organised
    Then relation(marriage) get plays roles contain:
      | locates:located     |
      | organises:organised |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(marriage) get plays roles contain:
      | locates:located     |
      | organises:organised |

  Scenario: Relation types cannot play entities, relations, attributes, structs, structs fields, and non-existing things
    When put entity type: car
    When put relation type: credit
    When put attribute type: id
    When attribute(id) set value-type: long
    When relation(credit) create role: creditor
    When put relation type: marriage
    When relation(marriage) create role: spouse
    # TODO: Create structs in concept api
    When put struct type: passport
    When struct(passport) create field: birthday
    When struct(passport) get field(birthday); set value-type: datetime
    Then relation(marriage) set plays role: car; fails
    Then relation(marriage) set plays role: credit; fails
    Then relation(marriage) set plays role: id; fails
    Then relation(marriage) set plays role: passport; fails
    Then relation(marriage) set plays role: passport:birthday; fails
    Then relation(marriage) set plays role: marriage:spouse; fails
    Then relation(marriage) set plays role: does-not-exist; fails
    Then relation(marriage) get plays roles is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(marriage) get plays roles is empty

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
    When connection open schema transaction for database: typedb
    When relation(marriage) unset plays role: organises:organised
    Then relation(marriage) get plays roles do not contain:
      | locates:located     |
      | organises:organised |
    When transaction commits
    When connection open read transaction for database: typedb
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
    When connection open schema transaction for database: typedb
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
    When connection open read transaction for database: typedb
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
    When connection open schema transaction for database: typedb
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
    When connection open read transaction for database: typedb
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
    When connection open schema transaction for database: typedb
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
    When connection open read transaction for database: typedb
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
    When connection open schema transaction for database: typedb
    Then relation(parttime-employment) set plays role: locates:located; fails
    When connection open schema transaction for database: typedb
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
    Then relation(contractor-employment) get plays role: contractor-locates:contractor-located; set override: contractor-locates:contractor-located; fails
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
    Then relation(contractor-employment) get plays role: contractor-locates:contractor-located; set override: contractor-locates:contractor-located; fails
    Then relation(contractor-employment) get plays role: contractor-locates:contractor-located; set override: locates:located; fails

  Scenario: Attribute types cannot play entities, attributes, relations, roles, structs, structs fields, and non-existing things
    When put attribute type: surname
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When attribute(surname) set value-type: string
    # TODO: Create structs in concept api
    When put struct type: passport
    When struct(passport) create field: first-name
    When struct(passport) get field(first-name); set value-type: string
    When struct(passport) create field: surname
    When struct(passport) get field(surname); set value-type: string
    When struct(passport) create field: birthday
    When struct(passport) get field(birthday); set value-type: datetime
    When put attribute type: name
    When attribute(name) set value-type: string
    Then attribute(name) set plays role: person; fails
    Then attribute(name) set plays role: surname; fails
    Then attribute(name) set plays role: marriage; fails
    Then attribute(name) set plays role: marriage:spouse; fails
    Then attribute(name) set plays role: passport; fails
    Then attribute(name) set plays role: passport:birthday; fails
    Then attribute(name) set plays role: does-not-exist; fails
    Then attribute(name) get plays roles is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get plays roles is empty

  Scenario: Struct types cannot play entities, attributes, relations, roles, structs, structs fields, and non-existing things
    When put attribute type: name
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When attribute(surname) set value-type: string
    # TODO: Create structs in concept api
    When put struct type: passport
    When struct(passport) create field: birthday
    When struct(passport) get field(birthday); set value-type: datetime
    # TODO: Create structs in concept api
    When put struct type: wallet
    When struct(wallet) create field: currency
    When struct(wallet) get field(currency); set value-type: string
    When struct(wallet) create field: value
    When struct(wallet) get field(value); set value-type: double
    Then struct(wallet) set plays role: person; fails
    Then struct(wallet) set plays role: name; fails
    Then struct(wallet) set plays role: marriage; fails
    Then struct(wallet) set plays role: marriage:spouse; fails
    Then struct(wallet) set plays role: passport; fails
    Then struct(wallet) set plays role: passport:birthday; fails
    Then struct(wallet) set plays role: wallet:currency; fails
    Then struct(wallet) set plays role: does-not-exist; fails
    Then struct(wallet) get plays roles is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then struct(wallet) get plays roles is empty

  Scenario Outline: <root-type> types can redeclare playing role types
    When put relation type: parentship
    When relation(parentship) create role: parent
    When <root-type>(<type-name>) set plays role: parentship:parent
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<type-name>) set plays role: parentship:parent
    Examples:
      | root-type | type-name   |
      | entity    | person      |
      | relation  | description |

  Scenario Outline: <root-type> types cannot unset not played role
    When put relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    When <root-type>(<type-name>) set plays role: marriage:wife
    Then <root-type>(<type-name>) get plays roles do not contain:
      | marriage:husband |
    Then <root-type>(<type-name>) unset plays role: marriage:husband; fails
    Examples:
      | root-type | type-name   |
      | entity    | person      |
      | relation  | description |

  Scenario Outline: <root-type> types cannot unset playing role types that are currently played by existing instances
    When put relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    When <root-type>(<type-name>) set plays role: marriage:wife
    Then transaction commits
    When connection open write transaction for database: typedb
    When $i = <root-type>(<type-name>) create new instance
    When $m = relation(marriage) create new instance
    When relation $m add player for role(wife): $i
    Then transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) unset plays role: marriage:wife; fails
    Examples:
      | root-type | type-name   |
      | entity    | person      |
      | relation  | description |

  Scenario Outline: <root-type> types can re-override inherited playing role types
    When put relation type: parentship
    When relation(parentship) create role: parent
    When put relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father); set override: parent
    When <root-type>(<supertype-name>) set plays role: parentship:parent
    When <root-type>(<subtype-name>) set plays role: fathership:father
    When <root-type>(<subtype-name>) get plays role: fathership:father; set override: parentship:parent
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) set plays role: fathership:father
    When <root-type>(<subtype-name>) get plays role: fathership:father; set override: parentship:parent
    Examples:
      | root-type | supertype-name | subtype-name |
      | entity    | person         | customer     |
      | relation  | description    | registration |

########################
# plays role from a list
########################

  Scenario: Entity types can play role from a list
    When put relation type: marriage
    When relation(marriage) create role: husband[]
    When entity(person) set plays role: marriage:husband
    Then entity(person) get plays roles contain:
      | marriage:husband |
    Then relation(marriage) get role(husband) get players contain:
      | person |
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(marriage) create role: wife[]
    When entity(person) set plays role: marriage:wife
    Then entity(person) get plays roles contain:
      | marriage:husband |
      | marriage:wife    |
    Then relation(marriage) get role(husband) get players contain:
      | person |
    Then relation(marriage) get role(wife) get players contain:
      | person |
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get plays roles contain:
      | marriage:husband |
      | marriage:wife    |
    Then relation(marriage) get role(husband) get players contain:
      | person |
    Then relation(marriage) get role(wife) get players contain:
      | person |

  Scenario: Entity types can unset playing role from a list
    When put relation type: marriage
    When relation(marriage) create role: husband[]
    When relation(marriage) create role: wife[]
    When entity(person) set plays role: marriage:husband
    When entity(person) set plays role: marriage:wife
    Then entity(person) unset plays role: marriage:husband
    Then entity(person) get plays roles do not contain:
      | marriage:husband |
    Then relation(marriage) get role(husband) get players do not contain:
      | person |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) unset plays role: marriage:wife
    Then entity(person) get plays roles do not contain:
      | marriage:husband |
      | marriage:wife    |
    Then relation(marriage) get role(husband) get players do not contain:
      | person |
    Then relation(marriage) get role(wife) get players do not contain:
      | person |
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get plays roles do not contain:
      | marriage:husband |
      | marriage:wife    |
    Then relation(marriage) get role(husband) get players do not contain:
      | person |
    Then relation(marriage) get role(wife) get players do not contain:
      | person |

  Scenario: Entity types can inherit playing role from a list
    When put relation type: parentship
    When relation(parentship) create role: parent[]
    When relation(parentship) create role: child[]
    When put relation type: marriage
    When relation(marriage) create role: husband[]
    When relation(marriage) create role: wife[]
    When put entity type: animal
    When entity(animal) set plays role: parentship:parent
    When entity(animal) set plays role: parentship:child
    When entity(person) set supertype: animal
    When entity(person) set plays role: marriage:husband
    When entity(person) set plays role: marriage:wife
    Then entity(person) get plays roles contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    Then entity(person) get plays roles explicit contain:
      | marriage:husband |
      | marriage:wife    |
    Then entity(person) get plays roles explicit do not contain:
      | parentship:parent |
      | parentship:child  |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get plays roles contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    Then entity(person) get plays roles explicit contain:
      | marriage:husband |
      | marriage:wife    |
    Then entity(person) get plays roles explicit do not contain:
      | parentship:parent |
      | parentship:child  |
    When put relation type: sales
    When relation(sales) create role: buyer[]
    When put entity type: customer
    When entity(customer) set supertype: person
    When entity(customer) set plays role: sales:buyer
    Then entity(customer) get plays roles contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
      | sales:buyer       |
    Then entity(customer) get plays roles explicit contain:
      | sales:buyer |
    Then entity(customer) get plays roles explicit do not contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(animal) get plays roles contain:
      | parentship:parent |
      | parentship:child  |
    Then entity(person) get plays roles contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    Then entity(customer) get plays roles contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
      | sales:buyer       |

  Scenario: Relation types can play role from a list
    When put relation type: locates
    When relation(locates) create role: location[]
    When relation(locates) create role: located[]
    When put relation type: marriage
    When relation(marriage) create role: husband[]
    When relation(marriage) create role: wife[]
    When relation(marriage) set plays role: locates:located
    Then relation(marriage) get plays roles contain:
      | locates:located |
    When transaction commits
    When connection open schema transaction for database: typedb
    When put relation type: organises
    When relation(organises) create role: organiser[]
    When relation(organises) create role: organised[]
    When relation(marriage) set plays role: organises:organised
    Then relation(marriage) get plays roles contain:
      | locates:located     |
      | organises:organised |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(marriage) get plays roles contain:
      | locates:located     |
      | organises:organised |

  Scenario: Relation types can unset playing role from a list
    When put relation type: locates
    When relation(locates) create role: location[]
    When relation(locates) create role: located[]
    When put relation type: organises
    When relation(organises) create role: organiser[]
    When relation(organises) create role: organised[]
    When put relation type: marriage
    When relation(marriage) create role: husband[]
    When relation(marriage) create role: wife[]
    When relation(marriage) set plays role: locates:located
    When relation(marriage) set plays role: organises:organised
    When relation(marriage) unset plays role: locates:located
    Then relation(marriage) get plays roles do not contain:
      | locates:located |
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(marriage) unset plays role: organises:organised
    Then relation(marriage) get plays roles do not contain:
      | locates:located     |
      | organises:organised |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(marriage) get plays roles do not contain:
      | locates:located     |
      | organises:organised |

  Scenario: Relation types can inherit playing role from a list
    When put relation type: locates
    When relation(locates) create role: locating[]
    When relation(locates) create role: located[]
    When put relation type: contractor-locates
    When relation(contractor-locates) create role: contractor-locating[]
    When relation(contractor-locates) create role: contractor-located[]
    When put relation type: employment
    When relation(employment) create role: employer[]
    When relation(employment) create role: employee[]
    When relation(employment) set plays role: locates:located
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) set plays role: contractor-locates:contractor-located
    Then relation(contractor-employment) get plays roles contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
    When transaction commits
    When connection open schema transaction for database: typedb
    When put relation type: parttime-locates
    When relation(parttime-locates) create role: parttime-locating[]
    When relation(parttime-locates) create role: parttime-located[]
    When put relation type: parttime-employment
    When relation(parttime-employment) set supertype: contractor-employment
    When relation(parttime-employment) create role: parttime-employer[]
    When relation(parttime-employment) create role: parttime-employee[]
    When relation(parttime-employment) set plays role: parttime-locates:parttime-located
    Then relation(parttime-employment) get plays roles contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
      | parttime-locates:parttime-located     |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(contractor-employment) get plays roles contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
    Then relation(parttime-employment) get plays roles contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
      | parttime-locates:parttime-located     |

  Scenario Outline: <root-type> types can redeclare playing role from a list
    When put relation type: parentship
    When relation(parentship) create role: parent[]
    When <root-type>(<type-name>) set plays role: parentship:parent
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<type-name>) set plays role: parentship:parent
    Examples:
      | root-type | type-name   |
      | entity    | person      |
      | relation  | description |

  Scenario Outline: <root-type> types cannot unset not played role from a list
    When put relation type: marriage
    When relation(marriage) create role: husband[]
    When relation(marriage) create role: wife[]
    When <root-type>(<type-name>) set plays role: marriage:wife
    Then <root-type>(<type-name>) get plays roles do not contain:
      | marriage:husband |
    Then <root-type>(<type-name>) unset plays role: marriage:husband; fails
    Examples:
      | root-type | type-name   |
      | entity    | person      |
      | relation  | description |

  Scenario Outline: <root-type> types cannot unset playing role from a list that is currently played by existing instances
    When put relation type: marriage
    When relation(marriage) create role: husband[]
    When relation(marriage) create role: wife[]
    When <root-type>(<type-name>) set plays role: marriage:wife
    Then transaction commits
    When connection open write transaction for database: typedb
    When $i = <root-type>(<type-name>) create new instance
    When $m = relation(marriage) create new instance
    When relation $m add player for role(wife): $i
    Then transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) unset plays role: marriage:wife; fails
    Examples:
      | root-type | type-name   |
      | entity    | person      |
      | relation  | description |

  Scenario Outline: <root-type> types can re-override inherited playing role from a list
    When put relation type: parentship
    When relation(parentship) create role: parent[]
    When put relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father[]
    When relation(fathership) get role(father); set override: parent
    When <root-type>(<supertype-name>) set plays role: parentship:parent
    When <root-type>(<subtype-name>) set plays role: fathership:father
    When <root-type>(<subtype-name>) get plays role: fathership:father; set override: parentship:parent
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) set plays role: fathership:father
    When <root-type>(<subtype-name>) get plays role: fathership:father; set override: parentship:parent
    Examples:
      | root-type | supertype-name | subtype-name |
      | entity    | person         | customer     |
      | relation  | description    | registration |

########################
# plays lists
########################
# TODO: Add tests here if we allow `set plays role: T:ROL[]`

########################
# @annotations common: contain common tests for annotations suitable for **scalar** plays:
# @card (the only compatible annotation for now, but these tests will be helpful for compactness in the future)
########################

  Scenario Outline: <root-type> types can set plays with @<annotation> and unset it
    When put relation type: parentship
    When relation(parentship) create role: parent
    When <root-type>(<type-name>) set plays role: parentship:parent
    When <root-type>(<type-name>) get plays role: parentship:parent, set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays role: parentship:parent, get annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get plays role: parentship:parent, get annotations contain: @<annotation>
    When <root-type>(<type-name>) get plays role: parentship:parent, unset annotation: @<annotation>
    Then <root-type>(<type-name>) get plays role: parentship:parent, get annotations is empty
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get plays role: parentship:parent, get annotations is empty
    When <root-type>(<type-name>) get plays role: parentship:parent, set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays role: parentship:parent, get annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get plays role: parentship:parent, get annotations contain: @<annotation>
    When <root-type>(<type-name>) unset plays role: parentship:parent
    Then <root-type>(<type-name>) get plays role is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get plays role is empty
    Examples:
      | root-type | type-name   | annotation |
      | entity    | person      | card(0, 1) |
      | relation  | description | card(0, 1) |

  Scenario Outline: <root-type> types can have plays with @<annotation> alongside pure plays
    When put relation type: parentship
    When relation(parentship) create role: parent
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When put relation type: contract
    When relation(contract) create role: contractor
    When put relation type: employment
    When relation(employment) create role: employee
    When <root-type>(<type-name>) set plays role: parentship:parent
    When <root-type>(<type-name>) get plays role: parentship:parent, set annotation: @<annotation>
    When <root-type>(<type-name>) set plays role: marriage:spouse
    When <root-type>(<type-name>) get plays role: marriage:spouse, set annotation: @<annotation>
    When <root-type>(<type-name>) set plays role: contract:contractor
    When <root-type>(<type-name>) set plays role: employment:employee
    Then <root-type>(<type-name>) get plays role: parentship:parent, get annotations contain: @<annotation>
    Then <root-type>(<type-name>) get plays role: marriage:spouse, get annotations contain: @<annotation>
    Then <root-type>(<type-name>) get plays role contain:
      | parentship:parent   |
      | marriage:spouse     |
      | contract:contractor |
      | employment:employee |
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get plays role: parentship:parent, get annotations contain: @<annotation>
    Then <root-type>(<type-name>) get plays role: marriage:spouse, get annotations contain: @<annotation>
    Then <root-type>(<type-name>) get plays role contain:
      | parentship:parent   |
      | marriage:spouse     |
      | contract:contractor |
      | employment:employee |
    Examples:
      | root-type | type-name   | annotation |
      | entity    | person      | card(0, 1) |
      | relation  | description | card(0, 1) |

  Scenario Outline: <root-type> types cannot unset not set @<annotation> of plays
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When put relation type: parentship
    When relation(parentship) create role: parent
    When <root-type>(<type-name>) set plays role: marriage:spouse
    When <root-type>(<type-name>) get plays role: marriage:spouse, set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays role: marriage:spouse, get annotation contain: @<annotation>
    When <root-type>(<type-name>) set plays role: parentship:parent
    Then <root-type>(<type-name>) get plays role: parentship:parent, unset annotation: @<annotation>; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get plays role: marriage:spouse, get annotation contain: @<annotation>
    Then <root-type>(<type-name>) get plays role: parentship:parent, unset annotation: @<annotation>; fails
    Then <root-type>(<type-name>) get plays role: marriage:spouse, unset annotation: @<annotation>
    Then <root-type>(<type-name>) get plays role: marriage:spouse, unset annotation: @<annotation>; fails
    Then <root-type>(<type-name>) get plays role: marriage:spouse, get annotations is empty
    Then <root-type>(<type-name>) get plays role: parentship:parent, get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get plays role: marriage:spouse, get annotations is empty
    Then <root-type>(<type-name>) get plays role: parentship:parent, get annotations is empty
    Examples:
      | root-type | type-name   | annotation |
      | entity    | person      | card(0, 1) |
      | relation  | description | card(0, 1) |

  Scenario Outline: <root-type> types cannot unset @<annotation> of inherited plays
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When <root-type>(<supertype-name>) set plays role: marriage:spouse
    When <root-type>(<supertype-name>) get plays role: marriage:spouse, set annotation: @<annotation>
    Then <root-type>(<supertype-name>) get plays role: marriage:spouse, get annotation contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays role: marriage:spouse, get annotation contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays role: marriage:spouse, unset annotation: @<annotation>; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get plays role: marriage:spouse, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays role: marriage:spouse, unset annotation: @<annotation>; fails
    Examples:
      | root-type | supertype-name | subtype-name | annotation |
      | entity    | person         | customer     | card(1, 2) |
      | relation  | description    | registration | card(1, 2) |

  Scenario Outline: <root-type> types can inherit plays with @<annotation>s alongside pure plays
    When put relation type: parentship
    When relation(parentship) create role: parent
    When put relation type: contract
    When relation(contract) create role: contractor
    When put relation type: employment
    When relation(employment) create role: employee
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When <root-type>(<supertype-name>) set plays role: parentship:parent
    When <root-type>(<supertype-name>) get plays role: parentship:parent, set annotation: @<annotation>
    When <root-type>(<supertype-name>) set plays role: contract:contractor
    When <root-type>(<subtype-name>) set plays role: employment:employee
    When <root-type>(<subtype-name>) get plays role: employment:employee, set annotation: @<annotation>
    When <root-type>(<subtype-name>) set plays role: marriage:spouse
    Then <root-type>(<subtype-name>) get plays role contain:
      | parentship:parent   |
      | employment:employee |
      | contract:contractor |
      | marriage:spouse     |
    Then <root-type>(<subtype-name>) get declared plays role contain:
      | employment:employee |
      | marriage:spouse     |
    Then <root-type>(<subtype-name>) get declared plays role do not contain:
      | parentship:parent   |
      | contract:contractor |
    Then <root-type>(<subtype-name>) get plays role: parentship:parent, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays role: employment:employee, get annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get plays role contain:
      | parentship:parent   |
      | employment:employee |
      | contract:contractor |
      | marriage:spouse     |
    Then <root-type>(<subtype-name>) get declared plays role contain:
      | employment:employee |
      | marriage:spouse     |
    Then <root-type>(<subtype-name>) get declared plays role do not contain:
      | parentship:parent   |
      | contract:contractor |
    Then <root-type>(<subtype-name>) get plays role: parentship:parent, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays role: employment:employee, get annotations contain: @<annotation>
    When put relation type: license
    When relation(license) create role: object
    When put relation type: report
    When relation(object) create role: object
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    When <root-type>(<subtype-name-2>) set plays role: license:object
    When <root-type>(<subtype-name-2>) get plays role: license:object, set annotation: @<annotation>
    When <root-type>(<subtype-name-2>) set plays role: report:object
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<subtype-name>) get plays role contain:
      | parentship:parent   |
      | employment:employee |
      | contract:contractor |
      | marriage:spouse     |
    Then <root-type>(<subtype-name>) get declared plays role contain:
      | employment:employee |
      | marriage:spouse     |
    Then <root-type>(<subtype-name>) get declared plays role do not contain:
      | parentship:parent   |
      | contract:contractor |
    Then <root-type>(<subtype-name>) get plays role: parentship:parent, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays role: employment:employee, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays role: parentship:parent, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays role: employment:employee, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays role: license:object, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays role contain:
      | parentship:parent   |
      | employment:employee |
      | license:object      |
      | contract:contractor |
      | marriage:spouse     |
      | report:object       |
    Then <root-type>(<subtype-name-2>) get declared plays role contain:
      | license:object |
      | report:object  |
    Then <root-type>(<subtype-name-2>) get declared plays role do not contain:
      | parentship:parent   |
      | employment:employee |
      | contract:contractor |
      | marriage:spouse     |
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | annotation |
      | entity    | person         | customer     | subscriber     | card(1, 2) |
      | relation  | description    | registration | profile        | card(1, 2) |

  Scenario Outline: <root-type> types can redeclare plays with @<annotation>s as plays with @<annotation>s
    When put relation type: contract
    When relation(contract) create role: contractor
    When put relation type: parentship
    When relation(parentship) create role: parent
    When <root-type>(<type-name>) set plays role: contract:contractor
    When <root-type>(<type-name>) get plays role: contract:contractor, set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays role: contract:contractor, get annotation contain: @<annotation>
    When <root-type>(<type-name>) set plays role: parentship:parent
    When <root-type>(<type-name>) get plays role: parentship:parent, set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays role: parentship:parent, get annotation contain: @<annotation>
    Then <root-type>(<type-name>) set plays role: contract:contractor
    Then <root-type>(<type-name>) get plays role: contract:contractor, set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays role: contract:contractor, get annotation contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get plays role: contract:contractor, get annotation contain: @<annotation>
    Then <root-type>(<type-name>) set plays role: parentship:parent
    Then <root-type>(<type-name>) get plays role: parentship:parent, set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays role: parentship:parent, get annotation contain: @<annotation>
    Examples:
      | root-type | type-name   | annotation |
      | entity    | person      | card(1, 2) |
      | relation  | description | card(1, 2) |

  Scenario Outline: <root-type> types can redeclare plays as plays with @<annotation>
    When put relation type: contract
    When relation(contract) create role: contractor
    When put relation type: parentship
    When relation(parentship) create role: parent
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When <root-type>(<type-name>) set plays role: contract:contractor
    When <root-type>(<type-name>) set plays role: parentship:parent
    When <root-type>(<type-name>) set plays role: marriage:spouse
    Then <root-type>(<type-name>) set plays role: contract:contractor
    Then <root-type>(<type-name>) get plays role: contract:contractor, set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays role: contract:contractor, get annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) set plays role: parentship:parent
    Then <root-type>(<type-name>) get plays role: parentship:parent, get annotations is empty
    When <root-type>(<type-name>) get plays role: parentship:parent, set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays role: parentship:parent, get annotations contain: @<annotation>
    Then <root-type>(<type-name>) get plays role: marriage:spouse, get annotations is empty
    When <root-type>(<type-name>) get plays role: marriage:spouse, set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays role: marriage:spouse, get annotations contain: @<annotation>
    Examples:
      | root-type | type-name   | annotation |
      | entity    | person      | card(1, 2) |
      | relation  | description | card(1, 2) |

    # TODO: We set annotations independently now. Is the Scenario still relevant? I think so.
  Scenario Outline: <root-type> types can redeclare plays with @<annotation> as pure plays
    When put relation type: contract
    When relation(contract) create role: contractor
    When put relation type: parentship
    When relation(parentship) create role: parent
    When <root-type>(<type-name>) set plays role: contract:contractor
    When <root-type>(<type-name>) get plays role: contract:contractor, set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays role: contract:contractor, get annotations contain: @<annotation>
    When <root-type>(<type-name>) set plays role: parentship:parent
    When <root-type>(<type-name>) get plays role: parentship:parent, set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays role: parentship:parent, get annotations contain: @<annotation>
    Then <root-type>(<type-name>) set plays role: contract:contractor
    Then <root-type>(<type-name>) get plays role: contract:contractor, get annotations is empty
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get plays role: parentship:parent, get annotations contain: @<annotation>
    When <root-type>(<type-name>) set plays role: parentship:parent
    Then <root-type>(<type-name>) get plays role: parentship:parent, get annotations is empty
    Examples:
      | root-type | type-name   | annotation |
      | entity    | person      | card(1, 2) |
      | relation  | description | card(1, 2) |

  Scenario Outline: <root-type> types can override inherited pure plays as plays with @<annotation>s
    When put relation type: contract
    When relation(contract) create role: contractor
    When relation(contract) set annotation: @abstract
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) set supertype: contract
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set plays role: contract:contractor
    When <root-type>(<subtype-name>) set plays role: marriage:spouse
    When <root-type>(<subtype-name>) get plays role: marriage:spouse; set override: contract:contractor
    When <root-type>(<subtype-name>) get plays role: marriage:spouse, set annotation: @<annotation>
    Then <root-type>(<subtype-name>) get plays role overridden(marriage:spouse) get label: contract:contractor
    Then <root-type>(<subtype-name>) get plays role, with annotations (DEPRECATED): <annotation>; contain:
      | marriage:spouse |
    Then <root-type>(<subtype-name>) get plays role, with annotations (DEPRECATED): <annotation>; do not contain:
      | contract:contractor |
    Then <root-type>(<subtype-name>) get plays role contain:
      | marriage:spouse |
    Then <root-type>(<subtype-name>) get plays role do not contain:
      | contract:contractor |
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<subtype-name>) get plays role overridden(marriage:spouse) get label: contract:contractor
    Then <root-type>(<subtype-name>) get plays role, with annotations (DEPRECATED): <annotation>; contain:
      | marriage:spouse |
    Then <root-type>(<subtype-name>) get plays role, with annotations (DEPRECATED): <annotation>; do not contain:
      | contract:contractor |
    Then <root-type>(<subtype-name>) get plays role contain:
      | marriage:spouse |
    Then <root-type>(<subtype-name>) get plays role do not contain:
      | contract:contractor |
    Examples:
      | root-type | supertype-name | subtype-name | annotation |
      | entity    | person         | customer     | card(1, 2) |
      | relation  | description    | registration | card(1, 2) |

    # TODO: Maybe it should be rejected?
  Scenario Outline: <root-type> types can re-override plays with <annotation>s
    When put relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) set annotation: @abstract
    When put relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set plays role: parentship:parent
    When <root-type>(<supertype-name>) get plays role: parentship:parent, set annotation: @<annotation>
    When <root-type>(<subtype-name>) set annotation: @abstract
    Then <root-type>(<subtype-name>) get plays role contain: parentship:parent
    Then <root-type>(<subtype-name>) get plays role: parentship:parent, get annotations contain: @<annotation>
    When <root-type>(<subtype-name>) set plays role: fathership:father
    When <root-type>(<subtype-name>) get plays role: fathership:father; set override: parentship:parent
    # TODO: These commas, semicolons, and colons are a mess and are different for different subcases. Need to refactor it!
    Then <root-type>(<subtype-name>) get plays role overridden(fathership:father) get label: email
    Then <root-type>(<subtype-name>) get plays role overridden(fathership:father), get annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) set plays role: fathership:father
    When <root-type>(<subtype-name>) get plays role: fathership:father; set override: parentship:parent
    Then <root-type>(<subtype-name>) get plays role overridden(fathership:father) get label: parentship:parent
    Then <root-type>(<subtype-name>) get plays role overridden(fathership:father), get annotations contain: @<annotation>
    Examples:
      | root-type | supertype-name | subtype-name | annotation |
      | entity    | person         | customer     | card(1, 2) |
      | relation  | description    | registration | card(1, 2) |

  Scenario Outline: <root-type> types can redeclare inherited plays as plays with @<annotation> (which will override)
    When put relation type: parentship
    When relation(parentship) create role: parent
    When <root-type>(<supertype-name>) set plays role: parentship:parent
    Then <root-type>(<supertype-name>) get plays role overridden(parentship:parent) does not exist
    Then <root-type>(<subtype-name>) set plays role: parentship:parent
    Then <root-type>(<subtype-name>) get plays role: parentship:parent, set annotation: @<annotation>
    Then <root-type>(<subtype-name>) get plays role overridden(parentship:parent) exists
    Then <root-type>(<subtype-name>) get plays role overridden(parentship:parent) get label: parentship:parent
    Then <root-type>(<subtype-name>) get plays role, with annotations (DEPRECATED): <annotation>; contain: parentship:parent
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get plays role, with annotations (DEPRECATED): <annotation>; contain: parentship:parent
    Then <root-type>(<subtype-name-2>) set plays role: parentship:parent
    Then <root-type>(<subtype-name-2>) get plays role: parentship:parent, set annotation: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays role, with annotations (DEPRECATED): <annotation>; contain: parentship:parent
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | annotation |
      | entity    | person         | customer     | subscriber     | card(1, 2) |
      | relation  | description    | registration | profile        | card(1, 2) |

  Scenario Outline: <root-type> types cannot redeclare inherited plays with @<annotation> as pure plays or plays with @<annotation>
    When put relation type: parentship
    When relation(parentship) create role: parent
    When put relation type: contract
    When relation(contract) create role: contractor
    When <root-type>(<supertype-name>) set plays role: parentship:parent
    When <root-type>(<supertype-name>) get plays role: parentship:parent, set annotation: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) set plays role: parentship:parent
    Then transaction commits; fails
    Then transaction closes
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) set plays role: parentship:parent
    Then <root-type>(<subtype-name>) get plays role: parentship:parent, set annotation: @<annotation>
    Then transaction commits; fails
    Examples:
      | root-type | supertype-name | subtype-name | annotation |
      | entity    | person         | customer     | card(1, 2) |
      | relation  | description    | registration | card(1, 2) |

  Scenario Outline: <root-type> types cannot redeclare inherited plays with @<annotation>
    When put relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) set annotation: @abstract
    When put relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set plays role: parentship:parent
    When <root-type>(<supertype-name>) get plays role: parentship:parent, set annotation: @<annotation>
    When <root-type>(<subtype-name>) set plays role: fathership:father
    When <root-type>(<subtype-name>) get plays role: fathership:father, set annotation: @<annotation>
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    Then <root-type>(<subtype-name-2>) set plays role: parentship:parent
    Then <root-type>(<subtype-name-2>) get plays role: parentship:parent, set annotation: @<annotation>
    Then transaction commits; fails
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | annotation |
      | entity    | person         | customer     | subscriber     | card(1, 2) |
      | relation  | description    | registration | profile        | card(1, 2) |

  Scenario Outline: <root-type> types cannot redeclare overridden plays with @<annotation>s
    When put relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) set annotation: @abstract
    When put relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set plays role: parentship:parent
    When <root-type>(<supertype-name>) get plays role: parentship:parent, set annotation: @<annotation>
    When <root-type>(<subtype-name>) set plays role: fathership:father
    # TODO: Do we have overrides? Revalidate "override"-mentioning tests if we do need it and place it everywhere!
#    When <root-type>(<subtype-name>) get plays role: fathership:father, set override: parentship:parent
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    Then <root-type>(<subtype-name-2>) set plays role: fathership:father
    Then <root-type>(<subtype-name-2>) get plays role: fathership:father, set annotation: @<annotation>
    Then transaction commits; fails
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | annotation |
      | entity    | person         | customer     | subscriber     | card(1, 2) |
      | relation  | description    | registration | profile        | card(1, 2) |

  Scenario Outline: <root-type> types cannot redeclare overridden plays with @<annotation>s on multiple layers
    When put relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) set annotation: @abstract
    When put relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set plays role: parentship:parent
    When <root-type>(<supertype-name>) get plays role: parentship:parent, set annotation: @<annotation>
    When <root-type>(<subtype-name>) set plays role: fathership:father
    When <root-type>(<subtype-name>) get plays role: fathership:father, set annotation: @<annotation>
        # TODO: Do we have overrides?
#    When <root-type>(<subtype-name>) get plays role: fathership:father, set override: parentship:parent
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    Then <root-type>(<subtype-name-2>) set plays role: fathership:father
    Then <root-type>(<subtype-name-2>) get plays role: fathership:father, set annotation: @<annotation>
    Then transaction commits; fails
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | annotation |
      | entity    | person         | customer     | subscriber     | card(1, 2) |
      | relation  | description    | registration | profile        | card(1, 2) |

  Scenario Outline: <root-type> subtypes can redeclare plays with @<annotation>s after it is unset from supertype
    When put relation type: contract
    When relation(contract) create role: contractor
    When put relation type: marriage
    When relation(marriage) set supertype: contract
    When <root-type>(<type-name>) set plays role: contract:contractor
    When <root-type>(<type-name>) get plays role: contract:contractor, set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays role: contract:contractor, get annotation contain: @<annotation>
    When <root-type>(<type-name>) set plays role: marriage:contractor
    Then <root-type>(<type-name>) get plays role: marriage:contractor, get annotation contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get plays role: contract:contractor, get annotation contain: @<annotation>
    Then <root-type>(<type-name>) get plays role: marriage:contractor, get annotation contain: @<annotation>
    Then <root-type>(<type-name>) get plays role: marriage:contractor, set annotation: @<annotation>; fails
    When <root-type>(<type-name>) get plays role: contract:contractor, unset annotation: @<annotation>
    Then <root-type>(<type-name>) get plays role: contract:contractor, get annotation is empty
    Then <root-type>(<type-name>) get plays role: marriage:contractor, get annotation is empty
    Then <root-type>(<type-name>) get plays role: marriage:contractor, set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays role: contract:contractor, get annotation is empty
    Then <root-type>(<type-name>) get plays role: marriage:contractor, get annotation contain: @<annotation>
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get plays role: contract:contractor, get annotation is empty
    Then <root-type>(<type-name>) get plays role: marriage:contractor, get annotation contain: @<annotation>
    Examples:
      | root-type | type-name   | annotation |
      | entity    | person      | card(1, 2) |
      | relation  | description | card(1, 2) |

  Scenario Outline: <root-type> types can inherit plays with @<annotation>s and pure plays that are subtypes of each other
    When put relation type: contract
    When relation(contract) create role: contractor
    When relation(contract) set annotation: @abstract
    When put relation type: family
    When relation(family) create role: member
    When relation(family) set annotation: @abstract
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) set annotation: @abstract
    When relation(marriage) set supertype: contract
    When put relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) set annotation: @abstract
    When relation(parentship) set supertype: family
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set plays role: contract:contractor
    When <root-type>(<supertype-name>) get plays role: contract:contractor, set annotation: @<annotation>
    When <root-type>(<supertype-name>) set plays role: family:member
    When <root-type>(<subtype-name>) set annotation: @abstract
    When <root-type>(<subtype-name>) set plays role: marriage:spouse
    When <root-type>(<subtype-name>) get plays role: marriage:spouse, set annotation: @<annotation>
    When <root-type>(<subtype-name>) set plays role: parentship:parent
    Then <root-type>(<subtype-name>) get plays role contain:
      | contract:contractor |
      | marriage:spouse     |
      | family:member       |
      | parentship:parent   |
    Then <root-type>(<subtype-name>) get declared plays role contain:
      | marriage:spouse   |
      | parentship:parent |
    Then <root-type>(<subtype-name>) get declared plays role do not contain:
      | contract:contractor |
      | family:member       |
    Then <root-type>(<subtype-name>) get plays role: contract:contractor, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays role: marriage:spouse, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays role: family:member, get annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays role: parentship:parent, get annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get plays role contain:
      | contract:contractor |
      | marriage:spouse     |
      | family:member       |
      | parentship:parent   |
    Then <root-type>(<subtype-name>) get declared plays role contain:
      | marriage:spouse   |
      | parentship:parent |
    Then <root-type>(<subtype-name>) get declared plays role do not contain:
      | contract:contractor |
      | family:member       |
    Then <root-type>(<subtype-name>) get plays role: contract:contractor, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays role: marriage:spouse, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays role: family:member, get annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays role: parentship:parent, get annotations do not contain: @<annotation>
    When put relation type: civil-marriage
    When relation(civil-marriage) set supertype: marriage
    When relation(fathership) create role: father
    When relation(fathership) set annotation: @abstract
    When relation(fathership) set supertype: parentship
    When <root-type>(<subtype-name-2>) set annotation: @abstract
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    When <root-type>(<subtype-name-2>) set plays role: civil-marriage:spouse
    When <root-type>(<subtype-name-2>) get plays role: civil-marriage:spouse, set annotation: @<annotation>
    When <root-type>(<subtype-name-2>) set plays role: fathership:father
    Then <root-type>(<subtype-name-2>) get plays role contain:
      | contract:contractor   |
      | marriage:spouse       |
      | civil-marriage:spouse |
      | family:member         |
      | parentship:parent     |
      | fathership:father     |
    Then <root-type>(<subtype-name-2>) get declared plays role contain:
      | civil-marriage:spouse |
      | fathership:father     |
    Then <root-type>(<subtype-name-2>) get declared plays role do not contain:
      | contract:contractor |
      | marriage:spouse     |
      | family:member       |
      | parentship:parent   |
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<subtype-name>) get plays role contain:
      | contract:contractor |
      | marriage:spouse     |
      | family:member       |
      | parentship:parent   |
    Then <root-type>(<subtype-name>) get declared plays role contain:
      | marriage:spouse   |
      | parentship:parent |
    Then <root-type>(<subtype-name>) get declared plays role do not contain:
      | contract:contractor |
      | family:member       |
    Then <root-type>(<subtype-name>) get plays role: contract:contractor, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays role: marriage:spouse, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays role: family:member, get annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays role: parentship:parent, get annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays role contain:
      | contract:contractor   |
      | marriage:spouse       |
      | civil-marriage:spouse |
      | family:member         |
      | parentship:parent     |
      | fathership:father     |
    Then <root-type>(<subtype-name-2>) get declared plays role contain:
      | civil-marriage:spouse |
      | fathership:father     |
    Then <root-type>(<subtype-name-2>) get declared plays role do not contain:
      | contract:contractor |
      | marriage:spouse     |
      | family:member       |
      | parentship:parent   |
    Then <root-type>(<subtype-name-2>) get plays role: contract:contractor, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays role: marriage:spouse, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays role: civil-marriage:spouse, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays role: family:member, get annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays role: parentship:parent, get annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays role: fathership:father, get annotations do not contain: @<annotation>
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | annotation |
      | entity    | person         | customer     | subscriber     | card(1, 2) |
      | relation  | description    | registration | profile        | card(1, 2) |

  Scenario Outline: <root-type> types can override inherited plays with @<annotation>s and pure plays
    When put relation type: dispatch
    When relation(dispatch) create role: recipient
    When put relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) set annotation: @abstract
    When put relation type: contract
    When relation(contract) create role: contractor
    When relation(contract) set annotation: @abstract
    When put relation type: employment
    When relation(employment) create role: employee
    When put relation type: reference
    When relation(reference) create role: target
    When relation(reference) set annotation: @abstract
    When put relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) set supertype: contract
    When put relation type: celebration
    When relation(celebration) create role: cause
    When relation(celebration) set annotation: @abstract
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set plays role: dispatch:recipient
    When <root-type>(<supertype-name>) get plays role: dispatch:recipient, set annotation: @<annotation>
    When <root-type>(<supertype-name>) set plays role: parentship:parent
    When <root-type>(<supertype-name>) get plays role: parentship:parent, set annotation: @<annotation>
    When <root-type>(<supertype-name>) set plays role: contract:contractor
    When <root-type>(<supertype-name>) set plays role: employment:employee
    When <root-type>(<subtype-name>) set annotation: @abstract
    When <root-type>(<subtype-name>) set plays role: reference:target
    When <root-type>(<subtype-name>) get plays role: reference:target, set annotation: @<annotation>
    When <root-type>(<subtype-name>) set plays role: fathership:father
    When <root-type>(<subtype-name>) get plays role: fathership:father; set override: parentship:parent
    When <root-type>(<subtype-name>) set plays role: celebration:cause
    When <root-type>(<subtype-name>) set plays role: marriage:spouse
    When <root-type>(<subtype-name>) get plays role: marriage:spouse; set override: contract:contractor
    Then <root-type>(<subtype-name>) get plays role overridden(fathership:father) get label: parentship:parent
    Then <root-type>(<subtype-name>) get plays role overridden(marriage:spouse) get label: contract:contractor
    Then <root-type>(<subtype-name>) get plays role contain:
      | dispatch:recipient  |
      | reference:target    |
      | fathership:father   |
      | employment:employee |
      | celebration:cause   |
      | marriage:spouse     |
    Then <root-type>(<subtype-name>) get plays role do not contain:
      | parentship:parent   |
      | contract:contractor |
    Then <root-type>(<subtype-name>) get declared plays role contain:
      | reference:target  |
      | fathership:father |
      | celebration:cause |
      | marriage:spouse   |
    Then <root-type>(<subtype-name>) get declared plays role do not contain:
      | dispatch:recipient  |
      | employment:employee |
      | parentship:parent   |
      | contract:contractor |
    Then <root-type>(<subtype-name>) get plays role: dispatch:recipient, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays role: reference:target, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays role: fathership:father, get annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get plays role overridden(fathership:father) get label: parentship:parent
    Then <root-type>(<subtype-name>) get plays role overridden(marriage:spouse) get label: contract:contractor
    Then <root-type>(<subtype-name>) get plays role contain:
      | dispatch:recipient  |
      | reference:target    |
      | fathership:father   |
      | employment:employee |
      | celebration:cause   |
      | marriage:spouse     |
    Then <root-type>(<subtype-name>) get plays role do not contain:
      | parentship:parent   |
      | contract:contractor |
    Then <root-type>(<subtype-name>) get declared plays role contain:
      | reference:target  |
      | fathership:father |
      | celebration:cause |
      | marriage:spouse   |
    Then <root-type>(<subtype-name>) get declared plays role do not contain:
      | dispatch:recipient  |
      | employment:employee |
      | parentship:parent   |
      | contract:contractor |
    Then <root-type>(<subtype-name>) get plays role: dispatch:recipient, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays role: reference:target, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays role: fathership:father, get annotations contain: @<annotation>
    When put relation type: publication-reference
    When relation(publication-reference) create role: publication
    When relation(publication-reference) set supertype: reference
    When put relation type: birthday
    When relation(birthday) create role: celebrant
    When relation(birthday) set supertype: celebration
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    When <root-type>(<subtype-name-2>) set plays role: publication-reference:publication
    When <root-type>(<subtype-name-2>) get plays role: publication-reference:publication; set override: reference:target
    When <root-type>(<subtype-name-2>) set plays role: birthday:celebrant
    When <root-type>(<subtype-name-2>) get plays role: birthday:celebrant; set override: celebration
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<subtype-name>) get plays role contain:
      | dispatch:recipient  |
      | reference:target    |
      | fathership:father   |
      | employment:employee |
      | celebration:cause   |
      | marriage:spouse     |
    Then <root-type>(<subtype-name>) get plays role do not contain:
      | parentship:parent   |
      | contract:contractor |
    Then <root-type>(<subtype-name>) get declared plays role contain:
      | reference:target  |
      | fathership:father |
      | celebration:cause |
      | marriage:spouse   |
    Then <root-type>(<subtype-name>) get declared plays role do not contain:
      | dispatch:recipient  |
      | employment:employee |
      | parentship:parent   |
      | contract:contractor |
    Then <root-type>(<subtype-name>) get plays role: dispatch:recipient, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays role: reference:target, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays role: fathership:father, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays role overridden(publication-reference:publication) get label: reference:target
    Then <root-type>(<subtype-name-2>) get plays role overridden(birthday:celebrant) get label: celebration:cause
    Then <root-type>(<subtype-name-2>) get plays role contain:
      | dispatch:recipient                |
      | publication-reference:publication |
      | fathership:father                 |
      | employment:employee               |
      | birthday:celebrant                |
      | marriage:spouse                   |
    Then <root-type>(<subtype-name-2>) get plays role do not contain:
      | parentship:parent   |
      | reference:target    |
      | contract:contractor |
      | celebration:cause   |
    Then <root-type>(<subtype-name-2>) get declared plays role contain:
      | publication-reference:publication |
      | birthday:celebrant                |
    Then <root-type>(<subtype-name-2>) get declared plays role do not contain:
      | dispatch:recipient  |
      | fathership:father   |
      | employment:employee |
      | marriage:spouse     |
      | parentship:parent   |
      | reference:target    |
      | contract:contractor |
      | celebration:cause   |
    Then <root-type>(<subtype-name-2>) get plays role: dispatch:recipient, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays role: publication-reference:publication, get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays role: fathership:father, get annotations contain: @<annotation>
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | annotation |
      | entity    | person         | customer     | subscriber     | card(1, 2) |
      | relation  | description    | registration | profile        | card(1, 2) |

########################
# @card
########################

  Scenario Outline: Plays can set @card annotation with args in correct order and unset it
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When entity(person) set plays role: marriage:spouse
    Then entity(player) get plays role: marriage:spouse, set annotation: @card(<arg1>, <arg0>); fails
    Then entity(person) get plays role: marriage:spouse, get annotations is empty
    When entity(person) get plays role: marriage:spouse, set annotation: @card(<arg0>, <arg1>)
    Then entity(person) get plays role: marriage:spouse, get annotations contain: @card(<arg0>, <arg1>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get plays role: marriage:spouse, get annotations contain: @card(<arg0>, <arg1>)
    Then entity(person) get plays role: marriage:spouse, unset annotation: @card(<arg0>, <arg1>)
    Then entity(person) get plays role: marriage:spouse, get annotations is empty
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get plays role: marriage:spouse, get annotations is empty
    When entity(person) get plays role: marriage:spouse, set annotation: @card(<arg0>, <arg1>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get plays role: marriage:spouse, get annotations contain: @card(<arg0>, <arg1>)
    When entity(person) unset plays role: marriage:spouse
    Then entity(person) get plays role is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get plays role is empty
    Examples:
      | arg0 | arg1                |
      | 0    | 1                   |
      | 0    | 10                  |
      | 0    | 9223372036854775807 |
      | 1    | 10                  |
      | 0    | *                   |
      | 1    | *                   |
      | *    | 10                  |

  Scenario Outline: Plays can set @card annotation with duplicate args (exactly N plays)
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When entity(person) set plays role: marriage:spouse
    Then entity(person) get plays role: marriage:spouse, get annotations is empty
    When entity(person) get plays role: marriage:spouse, set annotation: @card(<arg>, <arg>)
    Then entity(person) get plays role: marriage:spouse, get annotations contain: @card(<arg>, <arg>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get plays role: marriage:spouse, get annotations contain: @card(<arg>, <arg>)
    Examples:
      | arg                 |
      | 1                   |
      | 2                   |
      | 9999                |
      | 9223372036854775807 |

  Scenario: Plays cannot have @card annotation with less than two args
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When entity(person) set plays role: marriage:spouse
    Then entity(person) get plays role: marriage:spouse, set annotation: @card; fails
    Then entity(person) get plays role: marriage:spouse, set annotation: @card(); fails
    Then entity(person) get plays role: marriage:spouse, set annotation: @card(1); fails
    Then entity(person) get plays role: marriage:spouse, set annotation: @card(*); fails
    Then entity(person) get plays role: marriage:spouse, get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get plays role: marriage:spouse, get annotations is empty

  Scenario: Plays cannot have @card annotation with invalid args or args number
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When entity(player) set plays role: marriage:spouse
    Then entity(player) get plays role: marriage:spouse, set annotation: @card(-1, 1); fails
    Then entity(player) get plays role: marriage:spouse, set annotation: @card(0, 0.1); fails
    Then entity(player) get plays role: marriage:spouse, set annotation: @card(0, 1.5); fails
    Then entity(player) get plays role: marriage:spouse, set annotation: @card(*, *); fails
    Then entity(player) get plays role: marriage:spouse, set annotation: @card(0, **); fails
    Then entity(player) get plays role: marriage:spouse, set annotation: @card(1, 2, 3); fails
    Then entity(player) get plays role: marriage:spouse, set annotation: @card(1, "2"); fails
    Then entity(player) get plays role: marriage:spouse, set annotation: @card("1", 2); fails
    Then entity(player) get plays role: marriage:spouse, get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(player) get plays role: marriage:spouse, get annotations is empty

  Scenario Outline: Plays cannot set multiple @card annotations with different arguments
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When entity(person) set plays role: marriage:spouse
    When entity(person) get plays role: marriage:spouse, set annotation: @card(2, 5)
    Then entity(person) get plays role: marriage:spouse, set annotation: @card(<fail-args>); fails
    Then entity(person) get plays role: marriage:spouse, set annotation: @card(<fail-args>); fails
    Then entity(person) get plays role: marriage:spouse, get annotations contain: @card(2, 5)
    Then entity(person) get plays role: marriage:spouse, get annotations do not contain: @card(<fail-args>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get plays role: marriage:spouse, get annotations contain: @card(2, 5)
    Then entity(person) get plays role: marriage:spouse, get annotations do not contain: @card(<fail-args>)
    Examples:
      | fail-args |
      | 0, 1      |
      | 0, 2      |
      | 0, 3      |
      | 0, 5      |
      | 0, *      |
      | 2, 3      |
      | 2, 5      |
      | 2, *      |
      | 3, 4      |
      | 3, 5      |
      | 3, *      |
      | 5, *      |
      | 6, *      |

    # TODO: Maybe we allow it, then change the test considering the expected behavior
  Scenario Outline: Plays cannot redeclare @card annotation with different arguments
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When entity(person) set plays role: marriage:spouse
    Then entity(person) get plays role: marriage:spouse, set annotation: @card(<args>)
    Then entity(person) get plays role: marriage:spouse, set annotation: @card(<args-redeclared>); fails
    Then entity(person) get plays role: marriage:spouse, get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get plays role: marriage:spouse, get annotations is empty
    Examples:
      | args | args-redeclared |
      | 0, * | 0, 1            |
      | 0, 5 | 0, 1            |
      | 1, 5 | 0, 1            |
      | 2, 5 | 0, 1            |
      | 2, 5 | 0, 2            |
      | 2, 5 | 2, *            |
      | 2, 5 | 2, 6            |
      | 2, 5 | 7, 11            |

  Scenario Outline: Plays-related @card annotation can be inherited and overridden by a subset of args
    When put relation type: custom-relation
    When relation(custom-relation) create role: r1
    When put relation type: second-custom-relation
    When relation(second-custom-relation) create role: r2
    When put relation type: overridden-custom-relation
    When relation(overridden-custom-relation) create role: overridden-r2
    When relation(overridden-custom-relation) set supertype: second-custom-relation
    When entity(person) set plays role: custom-relation:r1
    When relation(description) set plays role: custom-relation:r1
    When entity(person) set plays role: second-custom-relation:r2
    When relation(description) set plays role: second-custom-relation:r2
    When entity(person) get plays role: custom-relation:r1, set annotation: @card(<args>)
    When relation(description) get plays role: custom-relation:r1, set annotation: @card(<args>)
    Then entity(person) get plays role: custom-relation:r1, get annotations contain: @card(<args>)
    Then relation(description) get plays role: custom-relation:r1, get annotations contain: @card(<args>)
    When entity(person) get plays role: second-custom-relation:r1-2, set annotation: @card(<args>)
    When relation(description) get plays role: second-custom-relation:r2, set annotation: @card(<args>)
    Then entity(person) get plays role: second-custom-relation:r2, get annotations contain: @card(<args>)
    Then relation(description) get plays role: second-custom-relation:r2, get annotations contain: @card(<args>)
    When put entity type: player
    When put relation type: marriage
    When entity(player) set supertype: person
    When relation(marriage) set supertype: description
    When entity(player) set plays role: overridden-custom-relation:overridden-r2
    When relation(marriage) set plays role: overridden-custom-relation:overridden-r2
    # TODO: Overrides? Remove second-custom-relation:r2 from test if we remove overrides!
    When entity(player) get plays role: overridden-custom-relation:overridden-r2; set override: second-custom-relation:r2
    When relation(marriage) get plays role: overridden-custom-relation:overridden-r2; set override: second-custom-relation:r2
    Then entity(player) get plays role contain: custom-relation:r1
    Then relation(marriage) get plays role contain: custom-relation:r1
    Then entity(player) get plays role: custom-relation:r1, get annotations contain: @card(<args>)
    Then relation(marriage) get plays role: custom-relation:r1, get annotations contain: @card(<args>)
    Then entity(player) get plays role do not contain: second-custom-relation:r2
    Then relation(marriage) get plays role do not contain: second-custom-relation:r2
    Then entity(player) get plays role contain: overridden-custom-relation:overridden-r2
    Then relation(marriage) get plays role contain: overridden-custom-relation:overridden-r2
    Then entity(player) get plays role: overridden-custom-relation:overridden-r2, get annotations contain: @card(<args>)
    Then relation(marriage) get plays role: overridden-custom-relation:overridden-r2, get annotations contain: @card(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(player) get plays role: custom-relation:r1, get annotations contain: @card(<args>)
    Then relation(marriage) get plays role: custom-relation:r1, get annotations contain: @card(<args>)
    Then entity(player) get plays role: overridden-custom-relation:overridden-r2, get annotations contain: @card(<args>)
    Then relation(marriage) get plays role: overridden-custom-relation:overridden-r2, get annotations contain: @card(<args>)
    When entity(player) get plays role: custom-relation:r1, set annotation: @card(<args-override>)
    When relation(marriage) get plays role: custom-relation:r1, set annotation: @card(<args-override>)
    Then entity(player) get plays role: custom-relation:r1, get annotations contain: @card(<args-override>)
    Then relation(marriage) get plays role: custom-relation:r1, get annotations contain: @card(<args-override>)
    When entity(player) get plays role: overridden-custom-relation:overridden-r2, set annotation: @card(<args-override>)
    When relation(marriage) get plays role: overridden-custom-relation:overridden-r2, set annotation: @card(<args-override>)
    Then entity(player) get plays role: overridden-custom-relation:overridden-r2, get annotations contain: @card(<args-override>)
    Then relation(marriage) get plays role: overridden-custom-relation:overridden-r2, get annotations contain: @card(<args-override>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(player) get plays role: custom-relation:r1, get annotations contain: @card(<args-override>)
    Then relation(marriage) get plays role: custom-relation:r1, get annotations contain: @card(<args-override>)
    Then entity(player) get plays role: overridden-custom-relation:overridden-r2, get annotations contain: @card(<args-override>)
    Then relation(marriage) get plays role: overridden-custom-relation:overridden-r2, get annotations contain: @card(<args-override>)
    Examples:
      | args       | args-override |
      | 0, *       | 0, 10000      |
      | 0, 10      | 0, 1          |
      | 0, 2       | 1, 2          |
      | 1, *       | 1, 1          |
      | 1, 5       | 3, 4          |
      | 38, 111    | 39, 111       |
      | 1000, 1100 | 1000, 1099    |

  Scenario Outline: Inherited @card annotation on plays role cannot be overridden by the @card of same args or not a subset of args
    When put relation type: custom-relation
    When relation(custom-relation) create role: r1
    When put relation type: second-custom-relation
    When relation(second-custom-relation) create role: r2
    When put relation type: overridden-custom-relation
    When relation(overridden-custom-relation) create role: overridden-r2
    When relation(overridden-custom-relation) set supertype: second-custom-relation
    When entity(person) set plays role: custom-relation:r1
    When relation(description) set plays role: custom-relation:r1
    When entity(person) set plays role: second-custom-relation:r2
    When relation(description) set plays role: second-custom-relation:r2
    When entity(person) get plays role: custom-relation:r1, set annotation: @card(<args>)
    When relation(description) get plays role: custom-relation:r1, set annotation: @card(<args>)
    Then entity(person) get plays role: custom-relation:r1, get annotations contain: @card(<args>)
    Then relation(description) get plays role: custom-relation:r1, get annotations contain: @card(<args>)
    When entity(person) get plays role: second-custom-relation:r2, set annotation: @card(<args>)
    When relation(description) get plays role: second-custom-relation:r2, set annotation: @card(<args>)
    Then entity(person) get plays role: second-custom-relation:r2, get annotations contain: @card(<args>)
    Then relation(description) get plays role: second-custom-relation:r2, get annotations contain: @card(<args>)
    When put entity type: player
    When put relation type: marriage
    When entity(player) set supertype: person
    When relation(marriage) set supertype: description
    When entity(player) set plays role: overridden-custom-relation:overridden-r2
    When relation(marriage) set plays role: overridden-custom-relation:overridden-r2
    # TODO: Overrides? Remove second-custom-relation:r2 from test if we remove overrides!
    When entity(player) get plays role: overridden-custom-relation:overridden-r2; set override: second-custom-relation:r2
    When relation(marriage) get plays role: overridden-custom-relation:overridden-r2; set override: second-custom-relation:r2
    Then entity(player) get plays role: custom-relation:r1, get annotations contain: @card(<args>)
    Then relation(marriage) get plays role: custom-relation:r1, get annotations contain: @card(<args>)
    Then entity(player) get plays role: overridden-custom-relation:overridden-r2, get annotations contain: @card(<args>)
    Then relation(marriage) get plays role: overridden-custom-relation:overridden-r2, get annotations contain: @card(<args>)
    Then entity(player) get plays role: custom-relation:r1, set annotation: @card(<args>); fails
    Then relation(marriage) get plays role: custom-relation:r1, set annotation: @card(<args>); fails
    Then entity(player) get plays role: overridden-custom-relation:overridden-r2, set annotation: @card(<args>); fails
    Then relation(marriage) get plays role: overridden-custom-relation:overridden-r2, set annotation: @card(<args>); fails
    Then entity(player) get plays role: custom-relation:r1, set annotation: @card(<args-override>); fails
    Then relation(marriage) get plays role: custom-relation:r1, set annotation: @card(<args-override>); fails
    Then entity(player) get plays role: overridden-custom-relation:overridden-r2, set annotation: @card(<args-override>); fails
    Then relation(marriage) get plays role: overridden-custom-relation:overridden-r2, set annotation: @card(<args-override>); fails
    Then entity(player) get plays role: custom-relation:r1, get annotations contain: @card(<args>)
    Then relation(marriage) get plays role: custom-relation:r1, get annotations contain: @card(<args>)
    Then entity(player) get plays role: overridden-custom-relation:overridden-r2, get annotations contain: @card(<args>)
    Then relation(marriage) get plays role: overridden-custom-relation:overridden-r2, get annotations contain: @card(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(player) get plays role: custom-relation:r1, get annotations contain: @card(<args>)
    Then relation(marriage) get plays role: custom-relation:r1, get annotations contain: @card(<args>)
    Then entity(player) get plays role: overridden-custom-relation:overridden-r2, get annotations contain: @card(<args>)
    Then relation(marriage) get plays role: overridden-custom-relation:overridden-r2, get annotations contain: @card(<args>)
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
# not compatible @annotations: @distinct, @key, @unique, @subkey, @values, @range, @regex, @abstract, @cascade, @independent, @replace
########################

  Scenario Outline: <root-type> cannot play a role with @distinct, @key, @unique, @subkey, @values, @range, @regex, @abstract, @cascade, @independent, and @replace annotations
    When put relation type: marriage
    When relation(marriage) create role: husband
    When <root-type>(<type-name>) set plays role: marriage:husband
    Then <root-type>(<type-name>) get play roles: marriage:husband, set annotation: @distinct; fails
    Then <root-type>(<type-name>) get play roles: marriage:husband, set annotation: @key; fails
    Then <root-type>(<type-name>) get play roles: marriage:husband, set annotation: @unique; fails
    Then <root-type>(<type-name>) get play roles: marriage:husband, set annotation: @subkey; fails
    Then <root-type>(<type-name>) get play roles: marriage:husband, set annotation: @values; fails
    Then <root-type>(<type-name>) get play roles: marriage:husband, set annotation: @range; fails
    Then <root-type>(<type-name>) get play roles: marriage:husband, set annotation: @regex; fails
    Then <root-type>(<type-name>) get play roles: marriage:husband, set annotation: @abstract; fails
    Then <root-type>(<type-name>) get play roles: marriage:husband, set annotation: @cascade; fails
    Then <root-type>(<type-name>) get play roles: marriage:husband, set annotation: @independent; fails
    Then <root-type>(<type-name>) get play roles: marriage:husband, set annotation: @replace; fails
    Then <root-type>(<type-name>) get play roles: marriage:husband, set annotation: @does-not-exist; fails
    Then <root-type>(<type-name>) get play roles: marriage:husband, get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get play roles: marriage:husband, get annotations is empty
    Examples:
      | root-type | type-name   |
      | entity    | person      |
      | relation  | description |

########################
# @annotations combinations:
# @card - the only compatible annotation, nothing to combine yet
########################
