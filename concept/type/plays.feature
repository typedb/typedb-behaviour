# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Concept Plays

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb

    Given create entity type: person
    Given create entity type: customer
    Given create entity type: subscriber
    # Notice: supertypes are the same, but can be overridden for the second subtype inside the tests
    Given entity(customer) set supertype: person
    Given entity(subscriber) set supertype: person
    Given create relation type: description
    Given relation(description) create role: object
    Given create relation type: registration
    Given create relation type: profile
    # Notice: supertypes are the same, but can be overridden for the second subtype inside the tests
    Given relation(registration) set supertype: description
    Given relation(profile) set supertype: description

    Given transaction commits
    Given connection open schema transaction for database: typedb

########################
# plays common
########################

  Scenario: Entity types can play role types
    When create relation type: marriage
    When relation(marriage) create role: husband
    When entity(person) set plays: marriage:husband
    Then entity(person) get plays contain:
      | marriage:husband |
    Then relation(marriage) get role(husband) get players contain:
      | person |
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(marriage) create role: wife
    When entity(person) set plays: marriage:wife
    Then entity(person) get plays contain:
      | marriage:husband |
      | marriage:wife    |
    Then relation(marriage) get role(husband) get players contain:
      | person |
    Then relation(marriage) get role(wife) get players contain:
      | person |
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get plays contain:
      | marriage:husband |
      | marriage:wife    |
    Then relation(marriage) get role(husband) get players contain:
      | person |
    Then relation(marriage) get role(wife) get players contain:
      | person |

#  Scenario: Entity types cannot play entities, relations, attributes, structs, structs fields, and non-existing things
#    When create entity type: car
#    When create relation type: credit
#    When create attribute type: id
#    When attribute(id) set value type: long
#    When relation(credit) create role: creditor
#    When create struct type: passport
#    When struct(passport) create field: birthday, with value type: datetime
#    Then entity(person) set plays: car; fails
#    Then entity(person) set plays: credit; fails
#    Then entity(person) set plays: id; fails
#    Then entity(person) set plays: passport; fails
#    Then entity(person) set plays: passport:birthday; fails
#    Then entity(person) set plays: does-not-exist; fails
#    Then entity(person) get plays is empty
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then entity(person) get plays is empty

  Scenario: Entity types can unset playing role types
    When create relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    When entity(person) set plays: marriage:husband
    When entity(person) set plays: marriage:wife
    Then entity(person) unset plays: marriage:husband
    Then entity(person) get plays do not contain:
      | marriage:husband |
    Then relation(marriage) get role(husband) get players do not contain:
      | person |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) unset plays: marriage:wife
    Then entity(person) get plays do not contain:
      | marriage:husband |
      | marriage:wife    |
    Then relation(marriage) get role(husband) get players do not contain:
      | person |
    Then relation(marriage) get role(wife) get players do not contain:
      | person |
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get plays do not contain:
      | marriage:husband |
      | marriage:wife    |
    Then relation(marriage) get role(husband) get players do not contain:
      | person |
    Then relation(marriage) get role(wife) get players do not contain:
      | person |

  Scenario: Entity types can inherit playing role types
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When create relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    When create entity type: animal
    When entity(animal) set plays: parentship:parent
    When entity(animal) set plays: parentship:child
    When entity(person) set supertype: animal
    When entity(person) set plays: marriage:husband
    When entity(person) set plays: marriage:wife
    Then entity(person) get plays contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    Then entity(person) get plays explicit contain:
      | marriage:husband |
      | marriage:wife    |
    Then entity(person) get plays explicit do not contain:
      | parentship:parent |
      | parentship:child  |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get plays contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    Then entity(person) get plays explicit contain:
      | marriage:husband |
      | marriage:wife    |
    Then entity(person) get plays explicit do not contain:
      | parentship:parent |
      | parentship:child  |
    When create relation type: sales
    When relation(sales) create role: buyer
    When create entity type: customer
    When entity(customer) set supertype: person
    When entity(customer) set plays: sales:buyer
    Then entity(customer) get plays contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
      | sales:buyer       |
    Then entity(customer) get plays explicit contain:
      | sales:buyer |
    Then entity(customer) get plays explicit do not contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(animal) get plays contain:
      | parentship:parent |
      | parentship:child  |
    Then entity(person) get plays contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    Then entity(customer) get plays contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
      | sales:buyer       |

  Scenario: Entity types can inherit playing role types that are subtypes of each other
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set override: parent
    When entity(person) set plays: parentship:parent
    When entity(person) set plays: parentship:child
    When create entity type: man
    When entity(man) set supertype: person
    When entity(man) set plays: fathership:father
    Then entity(man) get plays contain:
      | parentship:parent |
      | fathership:father |
      | parentship:child  |
    Then entity(man) get plays explicit contain:
      | fathership:father |
    Then entity(man) get plays explicit do not contain:
      | parentship:parent |
      | parentship:child  |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(man) get plays contain:
      | parentship:parent |
      | fathership:father |
      | parentship:child  |
    Then entity(man) get plays explicit contain:
      | fathership:father |
    Then entity(man) get plays explicit do not contain:
      | parentship:parent |
      | parentship:child  |
    When create relation type: mothership
    When relation(mothership) set supertype: parentship
    When relation(mothership) create role: mother
    When relation(mothership) get role(mother) set override: parent
    When create entity type: woman
    When entity(woman) set supertype: person
    When entity(woman) set plays: mothership:mother
    Then entity(woman) get plays contain:
      | parentship:parent |
      | mothership:mother |
      | parentship:child  |
    Then entity(woman) get plays explicit contain:
      | mothership:mother |
    Then entity(woman) get plays explicit do not contain:
      | parentship:parent |
      | parentship:child  |
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get plays contain:
      | parentship:parent |
      | parentship:child  |
    Then entity(man) get plays contain:
      | parentship:parent |
      | fathership:father |
      | parentship:child  |
    Then entity(man) get plays explicit contain:
      | fathership:father |
    Then entity(man) get plays explicit do not contain:
      | parentship:parent |
      | parentship:child  |
    Then entity(woman) get plays contain:
      | parentship:parent |
      | mothership:mother |
      | parentship:child  |
    Then entity(woman) get plays explicit contain:
      | mothership:mother |
    Then entity(woman) get plays explicit do not contain:
      | parentship:parent |
      | parentship:child  |

  Scenario: Entity types can override inherited playing role types
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set override: parent
    When entity(person) set plays: parentship:parent
    When entity(person) set plays: parentship:child
    When create entity type: man
    When entity(man) set supertype: person
    When entity(man) set plays: fathership:father
    When entity(man) get plays(fathership:father) set override: parentship:parent
    Then entity(man) get plays contain:
      | fathership:father |
      | parentship:child  |
    Then entity(man) get plays do not contain:
      | parentship:parent |
    Then entity(man) get plays explicit contain:
      | fathership:father |
    Then entity(man) get plays explicit do not contain:
      | parentship:child  |
      | parentship:parent |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(man) get plays contain:
      | fathership:father |
      | parentship:child  |
    Then entity(man) get plays do not contain:
      | parentship:parent |
    Then entity(man) get plays explicit contain:
      | fathership:father |
    Then entity(man) get plays explicit do not contain:
      | parentship:child  |
      | parentship:parent |
    When create relation type: mothership
    When relation(mothership) set supertype: parentship
    When relation(mothership) create role: mother
    When relation(mothership) get role(mother) set override: parent
    When create entity type: woman
    When entity(woman) set supertype: person
    When entity(woman) set plays: mothership:mother
    When entity(woman) get plays(mothership:mother) set override: parentship:parent
    Then entity(woman) get plays contain:
      | mothership:mother |
      | parentship:child  |
    Then entity(woman) get plays do not contain:
      | parentship:parent |
    Then entity(woman) get plays explicit contain:
      | mothership:mother |
    Then entity(woman) get plays explicit do not contain:
      | parentship:child  |
      | parentship:parent |
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get plays contain:
      | parentship:parent |
      | parentship:child  |
    Then entity(man) get plays contain:
      | fathership:father |
      | parentship:child  |
    Then entity(man) get plays do not contain:
      | parentship:parent |
    Then entity(man) get plays explicit contain:
      | fathership:father |
    Then entity(man) get plays explicit do not contain:
      | parentship:child  |
      | parentship:parent |
    Then entity(woman) get plays contain:
      | mothership:mother |
      | parentship:child  |
    Then entity(woman) get plays do not contain:
      | parentship:parent |
    Then entity(woman) get plays explicit contain:
      | mothership:mother |
    Then entity(woman) get plays explicit do not contain:
      | parentship:child  |
      | parentship:parent |

  Scenario: Entity types cannot redeclare inherited/overridden playing role types
    When create relation type: parentship
    When relation(parentship) create role: parent
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set override: parent
    When entity(person) set plays: parentship:parent
    When create entity type: man
    When entity(man) set supertype: person
    When entity(man) set plays: fathership:father
    When entity(man) get plays(fathership:father) set override: parentship:parent
    When create entity type: boy
    When entity(boy) set supertype: man
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(boy) set plays: parentship:parent; fails
    When connection open schema transaction for database: typedb
    Then entity(boy) set plays: fathership:father
    Then transaction commits; fails

  Scenario: Entity types cannot override declared playing role types
    When create relation type: parentship
    When relation(parentship) create role: parent
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set override: parent
    When entity(person) set plays: parentship:parent
    Then entity(person) set plays: fathership:father
    Then entity(person) get plays(fathership:father) set override: fathership:father; fails
    Then entity(person) get plays(fathership:father) set override: parentship:parent; fails

  Scenario: Entity types cannot override inherited playing role types other than with their subtypes
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When create relation type: fathership
    When relation(fathership) create role: father
    When entity(person) set plays: parentship:parent
    When entity(person) set plays: parentship:child
    When create entity type: man
    When entity(man) set supertype: person
    Then entity(man) set plays: fathership:father
    Then entity(man) get plays(fathership:father) set override: fathership:father; fails
    Then entity(man) get plays(fathership:father) set override: parentship:parent; fails

  Scenario: Relation types can play role types
    When create relation type: locates
    When relation(locates) create role: location
    When relation(locates) create role: located
    When create relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    When relation(marriage) set plays: locates:located
    Then relation(marriage) get plays contain:
      | locates:located |
    When transaction commits
    When connection open schema transaction for database: typedb
    When create relation type: organises
    When relation(organises) create role: organiser
    When relation(organises) create role: organised
    When relation(marriage) set plays: organises:organised
    Then relation(marriage) get plays contain:
      | locates:located     |
      | organises:organised |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(marriage) get plays contain:
      | locates:located     |
      | organises:organised |

#  Scenario: Relation types cannot play entities, relations, attributes, structs, structs fields, and non-existing things
#    When create entity type: car
#    When create relation type: credit
#    When create attribute type: id
#    When attribute(id) set value type: long
#    When relation(credit) create role: creditor
#    When create relation type: marriage
#    When relation(marriage) create role: spouse
#    When create struct type: passport
#    When struct(passport) create field: birthday, with value type: datetime
#    Then relation(marriage) set plays: car; fails
#    Then relation(marriage) set plays: credit; fails
#    Then relation(marriage) set plays: id; fails
#    Then relation(marriage) set plays: passport; fails
#    Then relation(marriage) set plays: passport:birthday; fails
#    Then relation(marriage) set plays: marriage:spouse; fails
#    Then relation(marriage) set plays: does-not-exist; fails
#    Then relation(marriage) get plays is empty
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then relation(marriage) get plays is empty

  Scenario: Relation types can unset playing role types
    When create relation type: locates
    When relation(locates) create role: location
    When relation(locates) create role: located
    When create relation type: organises
    When relation(organises) create role: organiser
    When relation(organises) create role: organised
    When create relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    When relation(marriage) set plays: locates:located
    When relation(marriage) set plays: organises:organised
    When relation(marriage) unset plays: locates:located
    Then relation(marriage) get plays do not contain:
      | locates:located |
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(marriage) unset plays: organises:organised
    Then relation(marriage) get plays do not contain:
      | locates:located     |
      | organises:organised |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(marriage) get plays do not contain:
      | locates:located     |
      | organises:organised |

  Scenario: Relation types can inherit playing role types
    When create relation type: locates
    When relation(locates) create role: locating
    When relation(locates) create role: located
    When create relation type: contractor-locates
    When relation(contractor-locates) create role: contractor-locating
    When relation(contractor-locates) create role: contractor-located
    When create relation type: employment
    When relation(employment) create role: employer
    When relation(employment) create role: employee
    When relation(employment) set plays: locates:located
    When create relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) set plays: contractor-locates:contractor-located
    Then relation(contractor-employment) get plays contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
    When transaction commits
    When connection open schema transaction for database: typedb
    When create relation type: parttime-locates
    When relation(parttime-locates) create role: parttime-locating
    When relation(parttime-locates) create role: parttime-located
    When create relation type: parttime-employment
    When relation(parttime-employment) set supertype: contractor-employment
    When relation(parttime-employment) create role: parttime-employer
    When relation(parttime-employment) create role: parttime-employee
    When relation(parttime-employment) set plays: parttime-locates:parttime-located
    Then relation(parttime-employment) get plays contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
      | parttime-locates:parttime-located     |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(contractor-employment) get plays contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
    Then relation(parttime-employment) get plays contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
      | parttime-locates:parttime-located     |

  Scenario: Relation types can inherit playing role types that are subtypes of each other
    When create relation type: locates
    When relation(locates) create role: locating
    When relation(locates) create role: located
    When create relation type: contractor-locates
    When relation(contractor-locates) set supertype: locates
    When relation(contractor-locates) create role: contractor-locating
    When relation(contractor-locates) get role(contractor-locating) set override: locating
    When relation(contractor-locates) create role: contractor-located
    When relation(contractor-locates) get role(contractor-located) set override: located
    When create relation type: employment
    When relation(employment) create role: employer
    When relation(employment) create role: employee
    When relation(employment) set plays: locates:located
    When create relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) set plays: contractor-locates:contractor-located
    Then relation(contractor-employment) get plays contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
    When transaction commits
    When connection open schema transaction for database: typedb
    When create relation type: parttime-locates
    When relation(parttime-locates) set supertype: contractor-locates
    When relation(parttime-locates) create role: parttime-locating
    When relation(parttime-locates) get role(parttime-locating) set override: contractor-locating
    When relation(parttime-locates) create role: parttime-located
    When relation(parttime-locates) get role(parttime-located) set override: contractor-located
    When create relation type: parttime-employment
    When relation(parttime-employment) set supertype: contractor-employment
    When relation(parttime-employment) create role: parttime-employer
    When relation(parttime-employment) create role: parttime-employee
    When relation(parttime-employment) set plays: parttime-locates:parttime-located
    Then relation(parttime-employment) get plays contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
      | parttime-locates:parttime-located     |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(contractor-employment) get plays contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
    Then relation(parttime-employment) get plays contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
      | parttime-locates:parttime-located     |

  Scenario: Relation types can override inherited playing role types
    When create relation type: locates
    When relation(locates) create role: locating
    When relation(locates) create role: located
    When create relation type: contractor-locates
    When relation(contractor-locates) set supertype: locates
    When relation(contractor-locates) create role: contractor-locating
    When relation(contractor-locates) get role(contractor-locating) set override: locating
    When relation(contractor-locates) create role: contractor-located
    When relation(contractor-locates) get role(contractor-located) set override: located
    When create relation type: employment
    When relation(employment) create role: employer
    When relation(employment) create role: employee
    When relation(employment) set plays: locates:located
    When create relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) set plays: contractor-locates:contractor-located
    When relation(contractor-employment) get plays(contractor-locates:contractor-located) set override: locates:located
    Then relation(contractor-employment) get plays do not contain:
      | locates:located |
    When transaction commits
    When connection open schema transaction for database: typedb
    When create relation type: parttime-locates
    When relation(parttime-locates) set supertype: contractor-locates
    When relation(parttime-locates) create role: parttime-locating
    When relation(parttime-locates) get role(parttime-locating) set override: contractor-locating
    When relation(parttime-locates) create role: parttime-located
    When relation(parttime-locates) get role(parttime-located) set override: contractor-located
    When create relation type: parttime-employment
    When relation(parttime-employment) set supertype: contractor-employment
    When relation(parttime-employment) create role: parttime-employer
    When relation(parttime-employment) create role: parttime-employee
    When relation(parttime-employment) set plays: parttime-locates:parttime-located
    When relation(parttime-employment) get plays(parttime-locates:parttime-located) set override: contractor-locates:contractor-located
    Then relation(parttime-employment) get plays do not contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(contractor-employment) get plays do not contain:
      | locates:located |
    Then relation(parttime-employment) get plays do not contain:
      | locates:located                       |
      | contractor-locates:contractor-located |

  Scenario: Relation types cannot redeclare inherited/overridden playing role types
    When create relation type: locates
    When relation(locates) create role: located
    When create relation type: contractor-locates
    When relation(contractor-locates) set supertype: locates
    When relation(contractor-locates) create role: contractor-located
    When relation(contractor-locates) get role(contractor-located) set override: located
    When create relation type: employment
    When relation(employment) create role: employee
    When relation(employment) set plays: locates:located
    When create relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) set plays: contractor-locates:contractor-located
    When relation(contractor-employment) get plays(contractor-locates:contractor-located) set override: locates:located
    When create relation type: parttime-employment
    When relation(parttime-employment) set supertype: contractor-employment
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parttime-employment) set plays: locates:located; fails
    When connection open schema transaction for database: typedb
    Then relation(parttime-employment) set plays: contractor-locates:contractor-located
    Then transaction commits; fails

  Scenario: Relation types cannot override declared playing role types
    When create relation type: locates
    When relation(locates) create role: locating
    When relation(locates) create role: located
    When create relation type: employment-locates
    When relation(employment-locates) set supertype: locates
    When relation(employment-locates) create role: employment-locating
    When relation(employment-locates) get role(employment-locating) set override: locating
    When relation(employment-locates) create role: employment-located
    When relation(employment-locates) get role(employment-located) set override: located
    When create relation type: employment
    When relation(employment) create role: employer
    When relation(employment) create role: employee
    When relation(employment) set plays: locates:located
    Then relation(employment) set plays: employment-locates:employment-located
    Then relation(contractor-employment) get plays(contractor-locates:contractor-located) set override: contractor-locates:contractor-located; fails
    Then relation(employment) get plays(employment-locates:employment-located) set override: locates:located; fails

  Scenario: Relation types cannot override inherited playing role types other than with their subtypes
    When create relation type: locates
    When relation(locates) create role: locating
    When relation(locates) create role: located
    When create relation type: contractor-locates
    When relation(contractor-locates) create role: contractor-locating
    When relation(contractor-locates) create role: contractor-located
    When create relation type: employment
    When relation(employment) create role: employer
    When relation(employment) create role: employee
    When relation(employment) set plays: locates:located
    When create relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    Then relation(contractor-employment) set plays: contractor-locates:contractor-located
    Then relation(contractor-employment) get plays(contractor-locates:contractor-located) set override: contractor-locates:contractor-located; fails
    Then relation(contractor-employment) get plays(contractor-locates:contractor-located) set override: locates:located; fails

#  Scenario: Attribute types cannot play entities, attributes, relations, roles, structs, structs fields, and non-existing things
#    When create attribute type: surname
#    When create relation type: marriage
#    When relation(marriage) create role: spouse
#    When attribute(surname) set value type: string
#    When create struct type: passport
#    When struct(passport) create field: first-name, with value type: string
#    When struct(passport) create field: surname, with value type: string
#    When struct(passport) create field: birthday, with value type: datetime
#    When create attribute type: name
#    When attribute(name) set value type: string
#    Then attribute(name) set plays: person; fails
#    Then attribute(name) set plays: surname; fails
#    Then attribute(name) set plays: marriage; fails
#    Then attribute(name) set plays: marriage:spouse; fails
#    Then attribute(name) set plays: passport; fails
#    Then attribute(name) set plays: passport:birthday; fails
#    Then attribute(name) set plays: does-not-exist; fails
#    Then attribute(name) get plays is empty
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then attribute(name) get plays is empty

#  Scenario: Struct types cannot play entities, attributes, relations, roles, structs, structs fields, and non-existing things
#    When create attribute type: name
#    When create relation type: marriage
#    When relation(marriage) create role: spouse
#    When attribute(surname) set value type: string
#    When create struct type: passport
#    When struct(passport) create field: birthday, with value type: datetime
#    When create struct type: wallet
#    When struct(wallet) create field: currency, with value type: string
#    When struct(wallet) create field: value, with value type: double
#    Then struct(wallet) set plays: person; fails
#    Then struct(wallet) set plays: name; fails
#    Then struct(wallet) set plays: marriage; fails
#    Then struct(wallet) set plays: marriage:spouse; fails
#    Then struct(wallet) set plays: passport; fails
#    Then struct(wallet) set plays: passport:birthday; fails
#    Then struct(wallet) set plays: wallet:currency; fails
#    Then struct(wallet) set plays: does-not-exist; fails
#    Then struct(wallet) get plays is empty
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then struct(wallet) get plays is empty

  Scenario Outline: <root-type> types can redeclare playing role types
    When create relation type: parentship
    When relation(parentship) create role: parent
    When <root-type>(<type-name>) set plays: parentship:parent
    When <root-type>(<type-name>) set plays: parentship:parent
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<type-name>) set plays: parentship:parent
    Examples:
      | root-type | type-name   |
      | entity    | person      |
      | relation  | description |

  Scenario Outline: <root-type> types cannot unset not played role
    When create relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    When <root-type>(<type-name>) set plays: marriage:wife
    Then <root-type>(<type-name>) get plays do not contain:
      | marriage:husband |
    Then <root-type>(<type-name>) unset plays: marriage:husband; fails
    Examples:
      | root-type | type-name   |
      | entity    | person      |
      | relation  | description |

     # TODO: Move to thing-feature or schema/data-validation?
#  Scenario Outline: <root-type> types cannot unset playing role types that are currently played by existing instances
#    When create relation type: marriage
#    When relation(marriage) create role: husband
#    When relation(marriage) create role: wife
#    When <root-type>(<type-name>) set plays: marriage:wife
#    Then transaction commits
#    When connection open write transaction for database: typedb
#    When $i = <root-type>(<type-name>) create new instance
#    When $m = relation(marriage) create new instance
#    When relation $m add player for role(wife): $i
#    Then transaction commits
#    When connection open schema transaction for database: typedb
#    Then <root-type>(<type-name>) unset plays: marriage:wife; fails
#    Examples:
#      | root-type | type-name   |
#      | entity    | person      |
#      | relation  | description |

  Scenario Outline: <root-type> types can re-override inherited playing role types
    When create relation type: parentship
    When relation(parentship) create role: parent
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set override: parent
    When <root-type>(<supertype-name>) set plays: parentship:parent
    When <root-type>(<subtype-name>) set plays: fathership:father
    When <root-type>(<subtype-name>) get plays(fathership:father) set override: parentship:parent
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) set plays: fathership:father
    When <root-type>(<subtype-name>) get plays(fathership:father) set override: parentship:parent
    Examples:
      | root-type | supertype-name | subtype-name |
      | entity    | person         | customer     |
      | relation  | description    | registration |

########################
# plays from a list
########################

  Scenario: Entity types can play ordered role
    When create relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) get role(husband) set ordering: ordered
    When entity(person) set plays: marriage:husband
    Then entity(person) get plays contain:
      | marriage:husband |
    Then relation(marriage) get role(husband) get players contain:
      | person |
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(marriage) create role: wife
    When relation(marriage) get role(wife) set ordering: ordered
    When entity(person) set plays: marriage:wife
    Then entity(person) get plays contain:
      | marriage:husband |
      | marriage:wife    |
    Then relation(marriage) get role(husband) get players contain:
      | person |
    Then relation(marriage) get role(wife) get players contain:
      | person |
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get plays contain:
      | marriage:husband |
      | marriage:wife    |
    Then relation(marriage) get role(husband) get players contain:
      | person |
    Then relation(marriage) get role(wife) get players contain:
      | person |

  Scenario: Entity types can unset playing ordered role
    When create relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) get role(husband) set ordering: ordered
    When relation(marriage) create role: wife
    When relation(marriage) get role(wife) set ordering: ordered
    When entity(person) set plays: marriage:husband
    When entity(person) set plays: marriage:wife
    Then entity(person) unset plays: marriage:husband
    Then entity(person) get plays do not contain:
      | marriage:husband |
    Then relation(marriage) get role(husband) get players do not contain:
      | person |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) unset plays: marriage:wife
    Then entity(person) get plays do not contain:
      | marriage:husband |
      | marriage:wife    |
    Then relation(marriage) get role(husband) get players do not contain:
      | person |
    Then relation(marriage) get role(wife) get players do not contain:
      | person |
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get plays do not contain:
      | marriage:husband |
      | marriage:wife    |
    Then relation(marriage) get role(husband) get players do not contain:
      | person |
    Then relation(marriage) get role(wife) get players do not contain:
      | person |

  Scenario: Entity types can inherit playing ordered role
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) create role: child
    When relation(parentship) get role(child) set ordering: ordered
    When create relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) get role(husband) set ordering: ordered
    When relation(marriage) create role: wife
    When relation(marriage) get role(wife) set ordering: ordered
    When create entity type: animal
    When entity(animal) set plays: parentship:parent
    When entity(animal) set plays: parentship:child
    When entity(person) set supertype: animal
    When entity(person) set plays: marriage:husband
    When entity(person) set plays: marriage:wife
    Then entity(person) get plays contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    Then entity(person) get plays explicit contain:
      | marriage:husband |
      | marriage:wife    |
    Then entity(person) get plays explicit do not contain:
      | parentship:parent |
      | parentship:child  |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get plays contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    Then entity(person) get plays explicit contain:
      | marriage:husband |
      | marriage:wife    |
    Then entity(person) get plays explicit do not contain:
      | parentship:parent |
      | parentship:child  |
    When create relation type: sales
    When relation(sales) create role: buyer
    When relation(sales) get role(buyer) set ordering: ordered
    When create entity type: customer
    When entity(customer) set supertype: person
    When entity(customer) set plays: sales:buyer
    Then entity(customer) get plays contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
      | sales:buyer       |
    Then entity(customer) get plays explicit contain:
      | sales:buyer |
    Then entity(customer) get plays explicit do not contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(animal) get plays contain:
      | parentship:parent |
      | parentship:child  |
    Then entity(person) get plays contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    Then entity(customer) get plays contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
      | sales:buyer       |

  Scenario: Relation types can play ordered role
    When create relation type: locates
    When relation(locates) create role: location
    When relation(locates) get role(location) set ordering: ordered
    When relation(locates) create role: located
    When relation(locates) get role(located) set ordering: ordered
    When create relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) get role(husband) set ordering: ordered
    When relation(marriage) create role: wife
    When relation(marriage) get role(wife) set ordering: ordered
    When relation(marriage) set plays: locates:located
    Then relation(marriage) get plays contain:
      | locates:located |
    When transaction commits
    When connection open schema transaction for database: typedb
    When create relation type: organises
    When relation(organises) create role: organiser
    When relation(organises) get role(organiser) set ordering: ordered
    When relation(organises) create role: organised
    When relation(organises) get role(organised) set ordering: ordered
    When relation(marriage) set plays: organises:organised
    Then relation(marriage) get plays contain:
      | locates:located     |
      | organises:organised |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(marriage) get plays contain:
      | locates:located     |
      | organises:organised |

  Scenario: Relation types can unset playing ordered role
    When create relation type: locates
    When relation(locates) create role: location
    When relation(locates) get role(location) set ordering: ordered
    When relation(locates) create role: located
    When relation(locates) get role(located) set ordering: ordered
    When create relation type: organises
    When relation(organises) create role: organiser
    When relation(organises) get role(organiser) set ordering: ordered
    When relation(organises) create role: organised
    When relation(organises) get role(organised) set ordering: ordered
    When create relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) get role(husband) set ordering: ordered
    When relation(marriage) create role: wife
    When relation(marriage) get role(wife) set ordering: ordered
    When relation(marriage) set plays: locates:located
    When relation(marriage) set plays: organises:organised
    When relation(marriage) unset plays: locates:located
    Then relation(marriage) get plays do not contain:
      | locates:located |
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(marriage) unset plays: organises:organised
    Then relation(marriage) get plays do not contain:
      | locates:located     |
      | organises:organised |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(marriage) get plays do not contain:
      | locates:located     |
      | organises:organised |

  Scenario: Relation types can inherit playing ordered role
    When create relation type: locates
    When relation(locates) create role: locating
    When relation(locates) get role(locating) set ordering: ordered
    When relation(locates) create role: located
    When relation(locates) get role(located) set ordering: ordered
    When create relation type: contractor-locates
    When relation(contractor-locates) create role: contractor-locating
    When relation(contractor-locates) get role(contractor-locating) set ordering: ordered
    When relation(contractor-locates) create role: contractor-located
    When relation(contractor-locates) get role(contractor-located) set ordering: ordered
    When create relation type: employment
    When relation(employment) create role: employer
    When relation(employment) get role(employer) set ordering: ordered
    When relation(employment) create role: employee
    When relation(employment) get role(employer) set ordering: ordered
    When relation(employment) set plays: locates:located
    When create relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) set plays: contractor-locates:contractor-located
    Then relation(contractor-employment) get plays contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
    When transaction commits
    When connection open schema transaction for database: typedb
    When create relation type: parttime-locates
    When relation(parttime-locates) create role: parttime-locating
    When relation(parttime-locates) get role(parttime-locating) set ordering: ordered
    When relation(parttime-locates) create role: parttime-located
    When relation(parttime-locates) get role(parttime-located) set ordering: ordered
    When create relation type: parttime-employment
    When relation(parttime-employment) set supertype: contractor-employment
    When relation(parttime-employment) create role: parttime-employer
    When relation(parttime-employment) get role(parttime-employer) set ordering: ordered
    When relation(parttime-employment) create role: parttime-employee
    When relation(parttime-employment) get role(parttime-employee) set ordering: ordered
    When relation(parttime-employment) set plays: parttime-locates:parttime-located
    Then relation(parttime-employment) get plays contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
      | parttime-locates:parttime-located     |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(contractor-employment) get plays contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
    Then relation(parttime-employment) get plays contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
      | parttime-locates:parttime-located     |

  Scenario Outline: <root-type> types can redeclare playing ordered role
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When <root-type>(<type-name>) set plays: parentship:parent
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<type-name>) set plays: parentship:parent
    Examples:
      | root-type | type-name   |
      | entity    | person      |
      | relation  | description |

  Scenario Outline: <root-type> types cannot unset not played ordered role
    When create relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) get role(husband) set ordering: ordered
    When relation(marriage) create role: wife
    When relation(marriage) get role(wife) set ordering: ordered
    When <root-type>(<type-name>) set plays: marriage:wife
    Then <root-type>(<type-name>) get plays do not contain:
      | marriage:husband |
    Then <root-type>(<type-name>) unset plays: marriage:husband; fails
    Examples:
      | root-type | type-name   |
      | entity    | person      |
      | relation  | description |

     # TODO: Move to thing-feature or schema/data-validation?
#  Scenario Outline: <root-type> types cannot unset playing ordered role that is currently played by existing instances
#    When create relation type: marriage
#    When relation(marriage) create role: husband
#    When relation(marriage) get role(husband) set ordering: ordered
#    When relation(marriage) create role: wife
#    When relation(marriage) get role(wife) set ordering: ordered
#    When <root-type>(<type-name>) set plays: marriage:wife
#    Then transaction commits
#    When connection open write transaction for database: typedb
#    When $i = <root-type>(<type-name>) create new instance
#    When $m = relation(marriage) create new instance
#    When relation $m add player for role(wife): $i
#    Then transaction commits
#    When connection open schema transaction for database: typedb
#    Then <root-type>(<type-name>) unset plays: marriage:wife; fails
#    Examples:
#      | root-type | type-name   |
#      | entity    | person      |
#      | relation  | description |

  Scenario Outline: <root-type> types can re-override inherited playing ordered role
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set ordering: ordered
    When relation(fathership) get role(father) set override: parent
    When <root-type>(<supertype-name>) set plays: parentship:parent
    When <root-type>(<subtype-name>) set plays: fathership:father
    When <root-type>(<subtype-name>) get plays(fathership:father) set override: parentship:parent
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) set plays: fathership:father
    When <root-type>(<subtype-name>) get plays(fathership:father) set override: parentship:parent
    Examples:
      | root-type | supertype-name | subtype-name |
      | entity    | person         | customer     |
      | relation  | description    | registration |

########################
# plays lists
########################
# Add tests here if we allow `set plays: T:ROL[]`

########################
# @annotations common: contain common tests for annotations suitable for **scalar** plays:
# @card
########################

  Scenario Outline: <root-type> types can set plays with @<annotation> and unset it
    When create relation type: parentship
    When relation(parentship) create role: parent
    When <root-type>(<type-name>) set plays: parentship:parent
    When <root-type>(<type-name>) get plays(parentship:parent) set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays(parentship:parent) get annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get plays(parentship:parent) get annotations contain: @<annotation>
    When <root-type>(<type-name>) get plays(parentship:parent) unset annotation: @<annotation>
    Then <root-type>(<type-name>) get plays(parentship:parent) get annotations is empty
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get plays(parentship:parent) get annotations is empty
    When <root-type>(<type-name>) get plays(parentship:parent) set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays(parentship:parent) get annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get plays(parentship:parent) get annotations contain: @<annotation>
    When <root-type>(<type-name>) unset plays: parentship:parent
    Then <root-type>(<type-name>) get plays is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get plays is empty
    Examples:
      | root-type | type-name   | annotation |
      | entity    | person      | card(0, 1) |
      | relation  | description | card(0, 1) |

  Scenario Outline: <root-type> types can have plays with @<annotation> alongside pure plays
    When create relation type: parentship
    When relation(parentship) create role: parent
    When create relation type: marriage
    When relation(marriage) create role: spouse
    When create relation type: contract
    When relation(contract) create role: contractor
    When create relation type: employment
    When relation(employment) create role: employee
    When <root-type>(<type-name>) set plays: parentship:parent
    When <root-type>(<type-name>) get plays(parentship:parent) set annotation: @<annotation>
    When <root-type>(<type-name>) set plays: marriage:spouse
    When <root-type>(<type-name>) get plays(marriage:spouse) set annotation: @<annotation>
    When <root-type>(<type-name>) set plays: contract:contractor
    When <root-type>(<type-name>) set plays: employment:employee
    Then <root-type>(<type-name>) get plays(parentship:parent) get annotations contain: @<annotation>
    Then <root-type>(<type-name>) get plays(marriage:spouse) get annotations contain: @<annotation>
    Then <root-type>(<type-name>) get plays contain:
      | parentship:parent   |
      | marriage:spouse     |
      | contract:contractor |
      | employment:employee |
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get plays(parentship:parent) get annotations contain: @<annotation>
    Then <root-type>(<type-name>) get plays(marriage:spouse) get annotations contain: @<annotation>
    Then <root-type>(<type-name>) get plays contain:
      | parentship:parent   |
      | marriage:spouse     |
      | contract:contractor |
      | employment:employee |
    Examples:
      | root-type | type-name   | annotation |
      | entity    | person      | card(0, 1) |
      | relation  | description | card(0, 1) |

  Scenario Outline: <root-type> types can unset not set @<annotation> of plays
    When create relation type: marriage
    When relation(marriage) create role: spouse
    When create relation type: parentship
    When relation(parentship) create role: parent
    When <root-type>(<type-name>) set plays: marriage:spouse
    When <root-type>(<type-name>) get plays(marriage:spouse) set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays(marriage:spouse) get annotation contain: @<annotation>
    When <root-type>(<type-name>) set plays: parentship:parent
    Then <root-type>(<type-name>) get plays(parentship:parent) get annotations do not contain: @<annotation>
    When <root-type>(<type-name>) get plays(parentship:parent) unset annotation: @<annotation>
    Then <root-type>(<type-name>) get plays(parentship:parent) get annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get plays(marriage:spouse) get annotation contain: @<annotation>
    Then <root-type>(<type-name>) get plays(parentship:parent) get annotations do not contain: @<annotation>
    When <root-type>(<type-name>) get plays(parentship:parent) unset annotation: @<annotation>
    Then <root-type>(<type-name>) get plays(parentship:parent) get annotations do not contain: @<annotation>
    Then <root-type>(<type-name>) get plays(marriage:spouse) get annotations contain: @<annotation>
    When <root-type>(<type-name>) get plays(marriage:spouse) unset annotation: @<annotation>
    Then <root-type>(<type-name>) get plays(marriage:spouse) get annotations do not contain: @<annotation>
    When <root-type>(<type-name>) get plays(marriage:spouse) unset annotation: @<annotation>
    Then <root-type>(<type-name>) get plays(marriage:spouse) get annotations do not contain: @<annotation>
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get plays(marriage:spouse) get annotations is empty
    Then <root-type>(<type-name>) get plays(parentship:parent) get annotations is empty
    Examples:
      | root-type | type-name   | annotation |
      | entity    | person      | card(0, 1) |
      | relation  | description | card(0, 1) |

  Scenario Outline: <root-type> types cannot unset @<annotation> of inherited plays
    When create relation type: marriage
    When relation(marriage) create role: spouse
    When <root-type>(<supertype-name>) set plays: marriage:spouse
    When <root-type>(<supertype-name>) get plays(marriage:spouse) set annotation: @<annotation>
    Then <root-type>(<supertype-name>) get plays(marriage:spouse) get annotation contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays(marriage:spouse) get annotation contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays(marriage:spouse) unset annotation: @<annotation>; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get plays(marriage:spouse) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays(marriage:spouse) unset annotation: @<annotation>; fails
    Examples:
      | root-type | supertype-name | subtype-name | annotation |
      | entity    | person         | customer     | card(1, 2) |
      | relation  | description    | registration | card(1, 2) |

  Scenario Outline: <root-type> types can inherit plays with @<annotation>s alongside pure plays
    When create relation type: parentship
    When relation(parentship) create role: parent
    When create relation type: contract
    When relation(contract) create role: contractor
    When create relation type: employment
    When relation(employment) create role: employee
    When create relation type: marriage
    When relation(marriage) create role: spouse
    When <root-type>(<supertype-name>) set plays: parentship:parent
    When <root-type>(<supertype-name>) get plays(parentship:parent) set annotation: @<annotation>
    When <root-type>(<supertype-name>) set plays: contract:contractor
    When <root-type>(<subtype-name>) set plays: employment:employee
    When <root-type>(<subtype-name>) get plays(employment:employee) set annotation: @<annotation>
    When <root-type>(<subtype-name>) set plays: marriage:spouse
    Then <root-type>(<subtype-name>) get plays contain:
      | parentship:parent   |
      | employment:employee |
      | contract:contractor |
      | marriage:spouse     |
    Then <root-type>(<subtype-name>) get declared plays contain:
      | employment:employee |
      | marriage:spouse     |
    Then <root-type>(<subtype-name>) get declared plays do not contain:
      | parentship:parent   |
      | contract:contractor |
    Then <root-type>(<subtype-name>) get plays(parentship:parent) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays(employment:employee) get annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get plays contain:
      | parentship:parent   |
      | employment:employee |
      | contract:contractor |
      | marriage:spouse     |
    Then <root-type>(<subtype-name>) get declared plays contain:
      | employment:employee |
      | marriage:spouse     |
    Then <root-type>(<subtype-name>) get declared plays do not contain:
      | parentship:parent   |
      | contract:contractor |
    Then <root-type>(<subtype-name>) get plays(parentship:parent) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays(employment:employee) get annotations contain: @<annotation>
    When create relation type: license
    When relation(license) create role: object
    When create relation type: report
    When relation(object) create role: object
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    When <root-type>(<subtype-name-2>) set plays: license:object
    When <root-type>(<subtype-name-2>) get plays(license:object) set annotation: @<annotation>
    When <root-type>(<subtype-name-2>) set plays: report:object
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<subtype-name>) get plays contain:
      | parentship:parent   |
      | employment:employee |
      | contract:contractor |
      | marriage:spouse     |
    Then <root-type>(<subtype-name>) get declared plays contain:
      | employment:employee |
      | marriage:spouse     |
    Then <root-type>(<subtype-name>) get declared plays do not contain:
      | parentship:parent   |
      | contract:contractor |
    Then <root-type>(<subtype-name>) get plays(parentship:parent) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays(employment:employee) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays(parentship:parent) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays(employment:employee) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays(license:object) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays contain:
      | parentship:parent   |
      | employment:employee |
      | license:object      |
      | contract:contractor |
      | marriage:spouse     |
      | report:object       |
    Then <root-type>(<subtype-name-2>) get declared plays contain:
      | license:object |
      | report:object  |
    Then <root-type>(<subtype-name-2>) get declared plays do not contain:
      | parentship:parent   |
      | employment:employee |
      | contract:contractor |
      | marriage:spouse     |
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | annotation |
      | entity    | person         | customer     | subscriber     | card(1, 2) |
      | relation  | description    | registration | profile        | card(1, 2) |

  Scenario Outline: <root-type> types can redeclare plays with @<annotation>s as plays with @<annotation>s
    When create relation type: contract
    When relation(contract) create role: contractor
    When create relation type: parentship
    When relation(parentship) create role: parent
    When <root-type>(<type-name>) set plays: contract:contractor
    When <root-type>(<type-name>) get plays(contract:contractor) set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays(contract:contractor) get annotation contain: @<annotation>
    When <root-type>(<type-name>) set plays: parentship:parent
    When <root-type>(<type-name>) get plays(parentship:parent) set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays(parentship:parent) get annotation contain: @<annotation>
    Then <root-type>(<type-name>) set plays: contract:contractor
    Then <root-type>(<type-name>) get plays(contract:contractor) set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays(contract:contractor) get annotation contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get plays(contract:contractor) get annotation contain: @<annotation>
    Then <root-type>(<type-name>) set plays: parentship:parent
    Then <root-type>(<type-name>) get plays(parentship:parent) set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays(parentship:parent) get annotation contain: @<annotation>
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get plays(parentship:parent) get annotation contain: @<annotation>
    Examples:
      | root-type | type-name   | annotation |
      | entity    | person      | card(1, 2) |
      | relation  | description | card(1, 2) |

  Scenario Outline: <root-type> types can redeclare plays as plays with @<annotation>
    When create relation type: contract
    When relation(contract) create role: contractor
    When create relation type: parentship
    When relation(parentship) create role: parent
    When create relation type: marriage
    When relation(marriage) create role: spouse
    When <root-type>(<type-name>) set plays: contract:contractor
    When <root-type>(<type-name>) set plays: parentship:parent
    When <root-type>(<type-name>) set plays: marriage:spouse
    Then <root-type>(<type-name>) set plays: contract:contractor
    Then <root-type>(<type-name>) get plays(contract:contractor) set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays(contract:contractor) get annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) set plays: parentship:parent
    Then <root-type>(<type-name>) get plays(parentship:parent) get annotations is empty
    When <root-type>(<type-name>) get plays(parentship:parent) set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays(parentship:parent) get annotations contain: @<annotation>
    Then <root-type>(<type-name>) get plays(marriage:spouse) get annotations is empty
    When <root-type>(<type-name>) get plays(marriage:spouse) set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays(marriage:spouse) get annotations contain: @<annotation>
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get plays(marriage:spouse) get annotations contain: @<annotation>
    Examples:
      | root-type | type-name   | annotation |
      | entity    | person      | card(1, 2) |
      | relation  | description | card(1, 2) |

  Scenario Outline: <root-type> types can redeclare plays with @<annotation> as pure plays
    When create relation type: contract
    When relation(contract) create role: contractor
    When create relation type: parentship
    When relation(parentship) create role: parent
    When <root-type>(<type-name>) set plays: contract:contractor
    When <root-type>(<type-name>) get plays(contract:contractor) set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays(contract:contractor) get annotations contain: @<annotation>
    When <root-type>(<type-name>) set plays: parentship:parent
    When <root-type>(<type-name>) get plays(parentship:parent) set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays(parentship:parent) get annotations contain: @<annotation>
    Then <root-type>(<type-name>) set plays: contract:contractor
    Then <root-type>(<type-name>) get plays(contract:contractor) get annotations is empty
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get plays(parentship:parent) get annotations contain: @<annotation>
    When <root-type>(<type-name>) set plays: parentship:parent
    Then <root-type>(<type-name>) get plays(parentship:parent) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get plays(parentship:parent) get annotations is empty
    Examples:
      | root-type | type-name   | annotation |
      | entity    | person      | card(1, 2) |
      | relation  | description | card(1, 2) |

  Scenario Outline: <root-type> types can override inherited pure plays as plays with @<annotation>s
    When create relation type: contract
    When relation(contract) create role: contractor
    When relation(contract) set annotation: @abstract
    When create relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) set supertype: contract
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set plays: contract:contractor
    When <root-type>(<subtype-name>) set plays: marriage:spouse
    When <root-type>(<subtype-name>) get plays(marriage:spouse) set override: contract:contractor
    When <root-type>(<subtype-name>) get plays(marriage:spouse) set annotation: @<annotation>
    Then <root-type>(<subtype-name>) get plays overridden(marriage:spouse) get label: contract:contractor
    Then <root-type>(<subtype-name>) get plays(marriage:spouse) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays(contract:contractor) get annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays contain:
      | marriage:spouse |
    Then <root-type>(<subtype-name>) get plays do not contain:
      | contract:contractor |
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<subtype-name>) get plays overridden(marriage:spouse) get label: contract:contractor
    Then <root-type>(<subtype-name>) get plays(marriage:spouse) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays(contract:contractor) get annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays contain:
      | marriage:spouse |
    Then <root-type>(<subtype-name>) get plays do not contain:
      | contract:contractor |
    Examples:
      | root-type | supertype-name | subtype-name | annotation |
      | entity    | person         | customer     | card(1, 2) |
      | relation  | description    | registration | card(1, 2) |

  Scenario Outline: <root-type> types can re-override plays with <annotation>s
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) set annotation: @abstract
    When create relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set plays: parentship:parent
    When <root-type>(<supertype-name>) get plays(parentship:parent) set annotation: @<annotation>
    When <root-type>(<subtype-name>) set annotation: @abstract
    Then <root-type>(<subtype-name>) get plays contain: parentship:parent
    Then <root-type>(<subtype-name>) get plays(parentship:parent) get annotations contain: @<annotation>
    When <root-type>(<subtype-name>) set plays: fathership:father
    When <root-type>(<subtype-name>) get plays(fathership:father) set override: parentship:parent
    Then <root-type>(<subtype-name>) get plays overridden(fathership:father) get name: email
    Then <root-type>(<subtype-name>) get plays overridden(fathership:father)) get annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    When <root-type>(<subtype-name>) set plays: fathership:father
    When <root-type>(<subtype-name>) get plays(fathership:father) set override: parentship:parent
    Then <root-type>(<subtype-name>) get plays overridden(fathership:father) get label: parentship:parent
    Then <root-type>(<subtype-name>) get plays overridden(fathership:father)) get annotations contain: @<annotation>
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<subtype-name>) get plays overridden(fathership:father) get label: parentship:parent
    Then <root-type>(<subtype-name>) get plays overridden(fathership:father)) get annotations contain: @<annotation>
    Examples:
      | root-type | supertype-name | subtype-name | annotation |
      | entity    | person         | customer     | card(1, 2) |
      | relation  | description    | registration | card(1, 2) |

  Scenario Outline: <root-type> types can redeclare inherited plays as plays with @<annotation> (which will override)
    When create relation type: parentship
    When relation(parentship) create role: parent
    When <root-type>(<supertype-name>) set plays: parentship:parent
    Then <root-type>(<supertype-name>) get plays overridden(parentship:parent) does not exist
    Then <root-type>(<subtype-name>) set plays: parentship:parent
    Then <root-type>(<subtype-name>) get plays(parentship:parent) set annotation: @<annotation>
    Then <root-type>(<subtype-name>) get plays overridden(parentship:parent) exists
    Then <root-type>(<subtype-name>) get plays overridden(parentship:parent) get label: parentship:parent
    Then <root-type>(<subtype-name>) get plays(parentship:parent) get annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get plays(parentship:parent) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) set plays: parentship:parent
    Then <root-type>(<subtype-name-2>) get plays(parentship:parent) set annotation: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays(parentship:parent) get annotations contain: @<annotation>
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<subtype-name-2>) get plays(parentship:parent) get annotations contain: @<annotation>
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | annotation |
      | entity    | person         | customer     | subscriber     | card(1, 2) |
      | relation  | description    | registration | profile        | card(1, 2) |

  Scenario Outline: <root-type> types cannot redeclare inherited plays with @<annotation> as pure plays or plays with @<annotation>
    When create relation type: parentship
    When relation(parentship) create role: parent
    When create relation type: contract
    When relation(contract) create role: contractor
    When <root-type>(<supertype-name>) set plays: parentship:parent
    When <root-type>(<supertype-name>) get plays(parentship:parent) set annotation: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) set plays: parentship:parent
    Then transaction commits; fails
    Then transaction closes
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) set plays: parentship:parent
    Then <root-type>(<subtype-name>) get plays(parentship:parent) set annotation: @<annotation>
    Then transaction commits; fails
    Examples:
      | root-type | supertype-name | subtype-name | annotation |
      | entity    | person         | customer     | card(1, 2) |
      | relation  | description    | registration | card(1, 2) |

  Scenario Outline: <root-type> types cannot redeclare inherited plays with @<annotation>
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) set annotation: @abstract
    When create relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set plays: parentship:parent
    When <root-type>(<supertype-name>) get plays(parentship:parent) set annotation: @<annotation>
    When <root-type>(<subtype-name>) set plays: fathership:father
    When <root-type>(<subtype-name>) get plays(fathership:father) set annotation: @<annotation>
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    Then <root-type>(<subtype-name-2>) set plays: parentship:parent
    Then <root-type>(<subtype-name-2>) get plays(parentship:parent) set annotation: @<annotation>
    Then transaction commits; fails
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | annotation |
      | entity    | person         | customer     | subscriber     | card(1, 2) |
      | relation  | description    | registration | profile        | card(1, 2) |

  Scenario Outline: <root-type> types cannot redeclare overridden plays with @<annotation>s
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) set annotation: @abstract
    When create relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set plays: parentship:parent
    When <root-type>(<supertype-name>) get plays(parentship:parent) set annotation: @<annotation>
    When <root-type>(<subtype-name>) set plays: fathership:father
    # TODO: Do we have overrides? Revalidate "override"-mentioning tests if we do need it and place it everywhere!
#    When <root-type>(<subtype-name>) get plays(fathership:father) set override: parentship:parent
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    Then <root-type>(<subtype-name-2>) set plays: fathership:father
    Then <root-type>(<subtype-name-2>) get plays(fathership:father) set annotation: @<annotation>
    Then transaction commits; fails
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | annotation |
      | entity    | person         | customer     | subscriber     | card(1, 2) |
      | relation  | description    | registration | profile        | card(1, 2) |

  Scenario Outline: <root-type> types cannot redeclare overridden plays with @<annotation>s on multiple layers
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) set annotation: @abstract
    When create relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set plays: parentship:parent
    When <root-type>(<supertype-name>) get plays(parentship:parent) set annotation: @<annotation>
    When <root-type>(<subtype-name>) set plays: fathership:father
    When <root-type>(<subtype-name>) get plays(fathership:father) set annotation: @<annotation>
        # TODO: Do we have overrides?
#    When <root-type>(<subtype-name>) get plays(fathership:father) set override: parentship:parent
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    Then <root-type>(<subtype-name-2>) set plays: fathership:father
    Then <root-type>(<subtype-name-2>) get plays(fathership:father) set annotation: @<annotation>
    Then transaction commits; fails
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | annotation |
      | entity    | person         | customer     | subscriber     | card(1, 2) |
      | relation  | description    | registration | profile        | card(1, 2) |

  Scenario Outline: <root-type> subtypes can redeclare plays with @<annotation>s after it is unset from supertype
    When create relation type: contract
    When relation(contract) create role: contractor
    When create relation type: marriage
    When relation(marriage) set supertype: contract
    When <root-type>(<type-name>) set plays: contract:contractor
    When <root-type>(<type-name>) get plays(contract:contractor) set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays(contract:contractor) get annotation contain: @<annotation>
    When <root-type>(<type-name>) set plays: marriage:contractor
    Then <root-type>(<type-name>) get plays(marriage:contractor) get annotation contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<type-name>) get plays(contract:contractor) get annotation contain: @<annotation>
    Then <root-type>(<type-name>) get plays(marriage:contractor) get annotation contain: @<annotation>
    Then <root-type>(<type-name>) get plays(marriage:contractor) set annotation: @<annotation>; fails
    When <root-type>(<type-name>) get plays(contract:contractor) unset annotation: @<annotation>
    Then <root-type>(<type-name>) get plays(contract:contractor) get annotation is empty
    Then <root-type>(<type-name>) get plays(marriage:contractor) get annotation is empty
    Then <root-type>(<type-name>) get plays(marriage:contractor) set annotation: @<annotation>
    Then <root-type>(<type-name>) get plays(contract:contractor) get annotation is empty
    Then <root-type>(<type-name>) get plays(marriage:contractor) get annotation contain: @<annotation>
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get plays(contract:contractor) get annotation is empty
    Then <root-type>(<type-name>) get plays(marriage:contractor) get annotation contain: @<annotation>
    Examples:
      | root-type | type-name   | annotation |
      | entity    | person      | card(1, 2) |
      | relation  | description | card(1, 2) |

  Scenario Outline: <root-type> types can inherit plays with @<annotation>s and pure plays that are subtypes of each other
    When create relation type: contract
    When relation(contract) create role: contractor
    When relation(contract) set annotation: @abstract
    When create relation type: family
    When relation(family) create role: member
    When relation(family) set annotation: @abstract
    When create relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) set annotation: @abstract
    When relation(marriage) set supertype: contract
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) set annotation: @abstract
    When relation(parentship) set supertype: family
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set plays: contract:contractor
    When <root-type>(<supertype-name>) get plays(contract:contractor) set annotation: @<annotation>
    When <root-type>(<supertype-name>) set plays: family:member
    When <root-type>(<subtype-name>) set annotation: @abstract
    When <root-type>(<subtype-name>) set plays: marriage:spouse
    When <root-type>(<subtype-name>) get plays(marriage:spouse) set annotation: @<annotation>
    When <root-type>(<subtype-name>) set plays: parentship:parent
    Then <root-type>(<subtype-name>) get plays contain:
      | contract:contractor |
      | marriage:spouse     |
      | family:member       |
      | parentship:parent   |
    Then <root-type>(<subtype-name>) get declared plays contain:
      | marriage:spouse   |
      | parentship:parent |
    Then <root-type>(<subtype-name>) get declared plays do not contain:
      | contract:contractor |
      | family:member       |
    Then <root-type>(<subtype-name>) get plays(contract:contractor) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays(marriage:spouse) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays(family:member) get annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays(parentship:parent) get annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get plays contain:
      | contract:contractor |
      | marriage:spouse     |
      | family:member       |
      | parentship:parent   |
    Then <root-type>(<subtype-name>) get declared plays contain:
      | marriage:spouse   |
      | parentship:parent |
    Then <root-type>(<subtype-name>) get declared plays do not contain:
      | contract:contractor |
      | family:member       |
    Then <root-type>(<subtype-name>) get plays(contract:contractor) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays(marriage:spouse) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays(family:member) get annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays(parentship:parent) get annotations do not contain: @<annotation>
    When create relation type: civil-marriage
    When relation(civil-marriage) set supertype: marriage
    When relation(fathership) create role: father
    When relation(fathership) set annotation: @abstract
    When relation(fathership) set supertype: parentship
    When <root-type>(<subtype-name-2>) set annotation: @abstract
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    When <root-type>(<subtype-name-2>) set plays: civil-marriage:spouse
    When <root-type>(<subtype-name-2>) get plays(civil-marriage:spouse) set annotation: @<annotation>
    When <root-type>(<subtype-name-2>) set plays: fathership:father
    Then <root-type>(<subtype-name-2>) get plays contain:
      | contract:contractor   |
      | marriage:spouse       |
      | civil-marriage:spouse |
      | family:member         |
      | parentship:parent     |
      | fathership:father     |
    Then <root-type>(<subtype-name-2>) get declared plays contain:
      | civil-marriage:spouse |
      | fathership:father     |
    Then <root-type>(<subtype-name-2>) get declared plays do not contain:
      | contract:contractor |
      | marriage:spouse     |
      | family:member       |
      | parentship:parent   |
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<subtype-name>) get plays contain:
      | contract:contractor |
      | marriage:spouse     |
      | family:member       |
      | parentship:parent   |
    Then <root-type>(<subtype-name>) get declared plays contain:
      | marriage:spouse   |
      | parentship:parent |
    Then <root-type>(<subtype-name>) get declared plays do not contain:
      | contract:contractor |
      | family:member       |
    Then <root-type>(<subtype-name>) get plays(contract:contractor) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays(marriage:spouse) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays(family:member) get annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays(parentship:parent) get annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays contain:
      | contract:contractor   |
      | marriage:spouse       |
      | civil-marriage:spouse |
      | family:member         |
      | parentship:parent     |
      | fathership:father     |
    Then <root-type>(<subtype-name-2>) get declared plays contain:
      | civil-marriage:spouse |
      | fathership:father     |
    Then <root-type>(<subtype-name-2>) get declared plays do not contain:
      | contract:contractor |
      | marriage:spouse     |
      | family:member       |
      | parentship:parent   |
    Then <root-type>(<subtype-name-2>) get plays(contract:contractor) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays(marriage:spouse) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays(civil-marriage:spouse) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays(family:member) get annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays(parentship:parent) get annotations do not contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays(fathership:father) get annotations do not contain: @<annotation>
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | annotation |
      | entity    | person         | customer     | subscriber     | card(1, 2) |
      | relation  | description    | registration | profile        | card(1, 2) |

  Scenario Outline: <root-type> types can override inherited plays with @<annotation>s and pure plays
    When create relation type: dispatch
    When relation(dispatch) create role: recipient
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) set annotation: @abstract
    When create relation type: contract
    When relation(contract) create role: contractor
    When relation(contract) set annotation: @abstract
    When create relation type: employment
    When relation(employment) create role: employee
    When create relation type: reference
    When relation(reference) create role: target
    When relation(reference) set annotation: @abstract
    When create relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    When create relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) set supertype: contract
    When create relation type: celebration
    When relation(celebration) create role: cause
    When relation(celebration) set annotation: @abstract
    When <root-type>(<supertype-name>) set annotation: @abstract
    When <root-type>(<supertype-name>) set plays: dispatch:recipient
    When <root-type>(<supertype-name>) get plays(dispatch:recipient) set annotation: @<annotation>
    When <root-type>(<supertype-name>) set plays: parentship:parent
    When <root-type>(<supertype-name>) get plays(parentship:parent) set annotation: @<annotation>
    When <root-type>(<supertype-name>) set plays: contract:contractor
    When <root-type>(<supertype-name>) set plays: employment:employee
    When <root-type>(<subtype-name>) set annotation: @abstract
    When <root-type>(<subtype-name>) set plays: reference:target
    When <root-type>(<subtype-name>) get plays(reference:target) set annotation: @<annotation>
    When <root-type>(<subtype-name>) set plays: fathership:father
    When <root-type>(<subtype-name>) get plays(fathership:father) set override: parentship:parent
    When <root-type>(<subtype-name>) set plays: celebration:cause
    When <root-type>(<subtype-name>) set plays: marriage:spouse
    When <root-type>(<subtype-name>) get plays(marriage:spouse) set override: contract:contractor
    Then <root-type>(<subtype-name>) get plays overridden(fathership:father) get label: parentship:parent
    Then <root-type>(<subtype-name>) get plays overridden(marriage:spouse) get label: contract:contractor
    Then <root-type>(<subtype-name>) get plays contain:
      | dispatch:recipient  |
      | reference:target    |
      | fathership:father   |
      | employment:employee |
      | celebration:cause   |
      | marriage:spouse     |
    Then <root-type>(<subtype-name>) get plays do not contain:
      | parentship:parent   |
      | contract:contractor |
    Then <root-type>(<subtype-name>) get declared plays contain:
      | reference:target  |
      | fathership:father |
      | celebration:cause |
      | marriage:spouse   |
    Then <root-type>(<subtype-name>) get declared plays do not contain:
      | dispatch:recipient  |
      | employment:employee |
      | parentship:parent   |
      | contract:contractor |
    Then <root-type>(<subtype-name>) get plays(dispatch:recipient) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays(reference:target) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays(fathership:father) get annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then <root-type>(<subtype-name>) get plays overridden(fathership:father) get label: parentship:parent
    Then <root-type>(<subtype-name>) get plays overridden(marriage:spouse) get label: contract:contractor
    Then <root-type>(<subtype-name>) get plays contain:
      | dispatch:recipient  |
      | reference:target    |
      | fathership:father   |
      | employment:employee |
      | celebration:cause   |
      | marriage:spouse     |
    Then <root-type>(<subtype-name>) get plays do not contain:
      | parentship:parent   |
      | contract:contractor |
    Then <root-type>(<subtype-name>) get declared plays contain:
      | reference:target  |
      | fathership:father |
      | celebration:cause |
      | marriage:spouse   |
    Then <root-type>(<subtype-name>) get declared plays do not contain:
      | dispatch:recipient  |
      | employment:employee |
      | parentship:parent   |
      | contract:contractor |
    Then <root-type>(<subtype-name>) get plays(dispatch:recipient) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays(reference:target) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays(fathership:father) get annotations contain: @<annotation>
    When create relation type: publication-reference
    When relation(publication-reference) create role: publication
    When relation(publication-reference) set supertype: reference
    When create relation type: birthday
    When relation(birthday) create role: celebrant
    When relation(birthday) set supertype: celebration
    When <root-type>(<subtype-name-2>) set supertype: <subtype-name>
    When <root-type>(<subtype-name-2>) set plays: publication-reference:publication
    When <root-type>(<subtype-name-2>) get plays(publication-reference:publication) set override: reference:target
    When <root-type>(<subtype-name-2>) set plays: birthday:celebrant
    When <root-type>(<subtype-name-2>) get plays(birthday:celebrant) set override: celebration
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<subtype-name>) get plays contain:
      | dispatch:recipient  |
      | reference:target    |
      | fathership:father   |
      | employment:employee |
      | celebration:cause   |
      | marriage:spouse     |
    Then <root-type>(<subtype-name>) get plays do not contain:
      | parentship:parent   |
      | contract:contractor |
    Then <root-type>(<subtype-name>) get declared plays contain:
      | reference:target  |
      | fathership:father |
      | celebration:cause |
      | marriage:spouse   |
    Then <root-type>(<subtype-name>) get declared plays do not contain:
      | dispatch:recipient  |
      | employment:employee |
      | parentship:parent   |
      | contract:contractor |
    Then <root-type>(<subtype-name>) get plays(dispatch:recipient) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays(reference:target) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name>) get plays(fathership:father) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays overridden(publication-reference:publication) get label: reference:target
    Then <root-type>(<subtype-name-2>) get plays overridden(birthday:celebrant) get label: celebration:cause
    Then <root-type>(<subtype-name-2>) get plays contain:
      | dispatch:recipient                |
      | publication-reference:publication |
      | fathership:father                 |
      | employment:employee               |
      | birthday:celebrant                |
      | marriage:spouse                   |
    Then <root-type>(<subtype-name-2>) get plays do not contain:
      | parentship:parent   |
      | reference:target    |
      | contract:contractor |
      | celebration:cause   |
    Then <root-type>(<subtype-name-2>) get declared plays contain:
      | publication-reference:publication |
      | birthday:celebrant                |
    Then <root-type>(<subtype-name-2>) get declared plays do not contain:
      | dispatch:recipient  |
      | fathership:father   |
      | employment:employee |
      | marriage:spouse     |
      | parentship:parent   |
      | reference:target    |
      | contract:contractor |
      | celebration:cause   |
    Then <root-type>(<subtype-name-2>) get plays(dispatch:recipient) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays(publication-reference:publication) get annotations contain: @<annotation>
    Then <root-type>(<subtype-name-2>) get plays(fathership:father) get annotations contain: @<annotation>
    Examples:
      | root-type | supertype-name | subtype-name | subtype-name-2 | annotation |
      | entity    | person         | customer     | subscriber     | card(1, 2) |
      | relation  | description    | registration | profile        | card(1, 2) |

########################
# @card
########################

  Scenario Outline: Plays can set @card annotation with arguments in correct order and unset it
    When create relation type: marriage
    When relation(marriage) create role: spouse
    When entity(person) set plays: marriage:spouse
    Then entity(player) get plays(marriage:spouse) set annotation: @card(<arg1>, <arg0>); fails
    Then entity(person) get plays(marriage:spouse) get annotations is empty
    When entity(person) get plays(marriage:spouse) set annotation: @card(<arg0>, <arg1>)
    Then entity(person) get plays(marriage:spouse) get annotations contain: @card(<arg0>, <arg1>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get plays(marriage:spouse) get annotations contain: @card(<arg0>, <arg1>)
    Then entity(person) get plays(marriage:spouse) unset annotation: @card(<arg0>, <arg1>)
    Then entity(person) get plays(marriage:spouse) get annotations is empty
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get plays(marriage:spouse) get annotations is empty
    When entity(person) get plays(marriage:spouse) set annotation: @card(<arg0>, <arg1>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get plays(marriage:spouse) get annotations contain: @card(<arg0>, <arg1>)
    When entity(person) unset plays: marriage:spouse
    Then entity(person) get plays is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get plays is empty
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
    When create relation type: marriage
    When relation(marriage) create role: spouse
    When entity(person) set plays: marriage:spouse
    Then entity(person) get plays(marriage:spouse) get annotations is empty
    When entity(person) get plays(marriage:spouse) set annotation: @card(<arg>, <arg>)
    Then entity(person) get plays(marriage:spouse) get annotations contain: @card(<arg>, <arg>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get plays(marriage:spouse) get annotations contain: @card(<arg>, <arg>)
    Examples:
      | arg                 |
      | 1                   |
      | 2                   |
      | 9999                |
      | 9223372036854775807 |

  Scenario: Plays cannot have @card annotation with invalid arguments
    When create relation type: marriage
    When relation(marriage) create role: spouse
    When entity(person) set plays: marriage:spouse
    #  TODO: Make it only for typeql
#    Then entity(person) get plays(marriage:spouse) set annotation: @card; fails
#    Then entity(person) get plays(marriage:spouse) set annotation: @card(); fails
#    Then entity(person) get plays(marriage:spouse) set annotation: @card(1); fails
#    Then entity(person) get plays(marriage:spouse) set annotation: @card(*); fails
#    Then entity(person) get plays(marriage:spouse) set annotation: @card(1, 2, 3); fails
    Then entity(person) get plays(marriage:spouse) set annotation: @card(-1, 1); fails
    Then entity(person) get plays(marriage:spouse) set annotation: @card(0, 0.1); fails
    Then entity(person) get plays(marriage:spouse) set annotation: @card(0, 1.5); fails
    Then entity(person) get plays(marriage:spouse) set annotation: @card(*, *); fails
    Then entity(person) get plays(marriage:spouse) set annotation: @card(0, **); fails
    Then entity(person) get plays(marriage:spouse) set annotation: @card(1, "2"); fails
    Then entity(person) get plays(marriage:spouse) set annotation: @card("1", 2); fails
    Then entity(person) get plays(marriage:spouse) set annotation: @card(2, 1); fails
    Then entity(person) get plays(marriage:spouse) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get plays(marriage:spouse) get annotations is empty

  Scenario Outline: Plays can reset @card annotations
    When create relation type: marriage
    When relation(marriage) create role: spouse
    When entity(person) set plays: marriage:spouse
    When entity(person) get plays(marriage:spouse) set annotation: @card(<init-args>)
    Then entity(person) get plays(marriage:spouse) get annotations contain: @card(<init-args>)
    Then entity(person) get plays(marriage:spouse) get annotations do not contain: @card(<reset-args>)
    When entity(person) get plays(marriage:spouse) set annotation: @card(<init-args>)
    Then entity(person) get plays(marriage:spouse) get annotations contain: @card(<init-args>)
    Then entity(person) get plays(marriage:spouse) get annotations do not contain: @card(<reset-args>)
    When entity(person) get plays(marriage:spouse) set annotation: @card(<reset-args>)
    Then entity(person) get plays(marriage:spouse) get annotations contain: @card(<reset-args>)
    Then entity(person) get plays(marriage:spouse) get annotations do not contain: @card(<init-args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(person) get plays(marriage:spouse) get annotations contain: @card(<reset-args>)
    Then entity(person) get plays(marriage:spouse) get annotations do not contain: @card(<init-args>)
    When entity(person) get plays(marriage:spouse) set annotation: @card(<init-args>)
    Then entity(person) get plays(marriage:spouse) get annotations contain: @card(<init-args>)
    Then entity(person) get plays(marriage:spouse) get annotations do not contain: @card(<reset-args>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get plays(marriage:spouse) get annotations do not contain: @card(<reset-args>)
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

  Scenario Outline: Plays-related @card annotation can be inherited and overridden by a subset of arguments
    When create relation type: custom-relation
    When relation(custom-relation) create role: r1
    When create relation type: second-custom-relation
    When relation(second-custom-relation) create role: r2
    When create relation type: overridden-custom-relation
    When relation(overridden-custom-relation) create role: overridden-r2
    When relation(overridden-custom-relation) set supertype: second-custom-relation
    When entity(person) set plays: custom-relation:r1
    When relation(description) set plays: custom-relation:r1
    When entity(person) set plays: second-custom-relation:r2
    When relation(description) set plays: second-custom-relation:r2
    When entity(person) get plays(custom-relation:r1) set annotation: @card(<args>)
    When relation(description) get plays(custom-relation:r1) set annotation: @card(<args>)
    Then entity(person) get plays(custom-relation:r1) get annotations contain: @card(<args>)
    Then relation(description) get plays(custom-relation:r1) get annotations contain: @card(<args>)
    When entity(person) get plays(second-custom-relation:r1-2) set annotation: @card(<args>)
    When relation(description) get plays(second-custom-relation:r2) set annotation: @card(<args>)
    Then entity(person) get plays(second-custom-relation:r2) get annotations contain: @card(<args>)
    Then relation(description) get plays(second-custom-relation:r2) get annotations contain: @card(<args>)
    When create entity type: player
    When create relation type: marriage
    When entity(player) set supertype: person
    When relation(marriage) set supertype: description
    When entity(player) set plays: overridden-custom-relation:overridden-r2
    When relation(marriage) set plays: overridden-custom-relation:overridden-r2
    # TODO: Overrides? Remove second-custom-relation:r2 from test if we remove overrides!
    When entity(player) get plays(overridden-custom-relation:overridden-r2) set override: second-custom-relation:r2
    When relation(marriage) get plays(overridden-custom-relation:overridden-r2) set override: second-custom-relation:r2
    Then entity(player) get plays contain: custom-relation:r1
    Then relation(marriage) get plays contain: custom-relation:r1
    Then entity(player) get plays(custom-relation:r1) get annotations contain: @card(<args>)
    Then relation(marriage) get plays(custom-relation:r1) get annotations contain: @card(<args>)
    Then entity(player) get plays do not contain: second-custom-relation:r2
    Then relation(marriage) get plays do not contain: second-custom-relation:r2
    Then entity(player) get plays contain: overridden-custom-relation:overridden-r2
    Then relation(marriage) get plays contain: overridden-custom-relation:overridden-r2
    Then entity(player) get plays(overridden-custom-relation:overridden-r2) get annotations contain: @card(<args>)
    Then relation(marriage) get plays(overridden-custom-relation:overridden-r2) get annotations contain: @card(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(player) get plays(custom-relation:r1) get annotations contain: @card(<args>)
    Then relation(marriage) get plays(custom-relation:r1) get annotations contain: @card(<args>)
    Then entity(player) get plays(overridden-custom-relation:overridden-r2) get annotations contain: @card(<args>)
    Then relation(marriage) get plays(overridden-custom-relation:overridden-r2) get annotations contain: @card(<args>)
    When entity(player) get plays(custom-relation:r1) set annotation: @card(<args-override>)
    When relation(marriage) get plays(custom-relation:r1) set annotation: @card(<args-override>)
    Then entity(player) get plays(custom-relation:r1) get annotations contain: @card(<args-override>)
    Then relation(marriage) get plays(custom-relation:r1) get annotations contain: @card(<args-override>)
    When entity(player) get plays(overridden-custom-relation:overridden-r2) set annotation: @card(<args-override>)
    When relation(marriage) get plays(overridden-custom-relation:overridden-r2) set annotation: @card(<args-override>)
    Then entity(player) get plays(overridden-custom-relation:overridden-r2) get annotations contain: @card(<args-override>)
    Then relation(marriage) get plays(overridden-custom-relation:overridden-r2) get annotations contain: @card(<args-override>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(player) get plays(custom-relation:r1) get annotations contain: @card(<args-override>)
    Then relation(marriage) get plays(custom-relation:r1) get annotations contain: @card(<args-override>)
    Then entity(player) get plays(overridden-custom-relation:overridden-r2) get annotations contain: @card(<args-override>)
    Then relation(marriage) get plays(overridden-custom-relation:overridden-r2) get annotations contain: @card(<args-override>)
    Examples:
      | args       | args-override |
      | 0, *       | 0, 10000      |
      | 0, 10      | 0, 1          |
      | 0, 2       | 1, 2          |
      | 1, *       | 1, 1          |
      | 1, 5       | 3, 4          |
      | 38, 111    | 39, 111       |
      | 1000, 1100 | 1000, 1099    |

  Scenario Outline: Inherited @card annotation on plays cannot be reset or overridden by the @card of not a subset of arguments
    When create relation type: custom-relation
    When relation(custom-relation) create role: r1
    When create relation type: second-custom-relation
    When relation(second-custom-relation) create role: r2
    When create relation type: overridden-custom-relation
    When relation(overridden-custom-relation) create role: overridden-r2
    When relation(overridden-custom-relation) set supertype: second-custom-relation
    When entity(person) set plays: custom-relation:r1
    When relation(description) set plays: custom-relation:r1
    When entity(person) set plays: second-custom-relation:r2
    When relation(description) set plays: second-custom-relation:r2
    When entity(person) get plays(custom-relation:r1) set annotation: @card(<args>)
    When relation(description) get plays(custom-relation:r1) set annotation: @card(<args>)
    Then entity(person) get plays(custom-relation:r1) get annotations contain: @card(<args>)
    Then relation(description) get plays(custom-relation:r1) get annotations contain: @card(<args>)
    When entity(person) get plays(second-custom-relation:r2) set annotation: @card(<args>)
    When relation(description) get plays(second-custom-relation:r2) set annotation: @card(<args>)
    Then entity(person) get plays(second-custom-relation:r2) get annotations contain: @card(<args>)
    Then relation(description) get plays(second-custom-relation:r2) get annotations contain: @card(<args>)
    When create entity type: player
    When create relation type: marriage
    When entity(player) set supertype: person
    When relation(marriage) set supertype: description
    When entity(player) set plays: overridden-custom-relation:overridden-r2
    When relation(marriage) set plays: overridden-custom-relation:overridden-r2
    # TODO: Overrides? Remove second-custom-relation:r2 from test if we remove overrides!
    When entity(player) get plays(overridden-custom-relation:overridden-r2) set override: second-custom-relation:r2
    When relation(marriage) get plays(overridden-custom-relation:overridden-r2) set override: second-custom-relation:r2
    Then entity(player) get plays(custom-relation:r1) get annotations contain: @card(<args>)
    Then relation(marriage) get plays(custom-relation:r1) get annotations contain: @card(<args>)
    Then entity(player) get plays(overridden-custom-relation:overridden-r2) get annotations contain: @card(<args>)
    Then relation(marriage) get plays(overridden-custom-relation:overridden-r2) get annotations contain: @card(<args>)
    Then entity(player) get plays(custom-relation:r1) set annotation: @card(<args-override>); fails
    Then relation(marriage) get plays(custom-relation:r1) set annotation: @card(<args-override>); fails
    Then entity(player) get plays(overridden-custom-relation:overridden-r2) set annotation: @card(<args-override>); fails
    Then relation(marriage) get plays(overridden-custom-relation:overridden-r2) set annotation: @card(<args-override>); fails
    Then entity(player) get plays(custom-relation:r1) get annotations contain: @card(<args>)
    Then relation(marriage) get plays(custom-relation:r1) get annotations contain: @card(<args>)
    Then entity(player) get plays(overridden-custom-relation:overridden-r2) get annotations contain: @card(<args>)
    Then relation(marriage) get plays(overridden-custom-relation:overridden-r2) get annotations contain: @card(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(player) get plays(custom-relation:r1) get annotations contain: @card(<args>)
    Then relation(marriage) get plays(custom-relation:r1) get annotations contain: @card(<args>)
    Then entity(player) get plays(overridden-custom-relation:overridden-r2) get annotations contain: @card(<args>)
    Then relation(marriage) get plays(overridden-custom-relation:overridden-r2) get annotations contain: @card(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then entity(player) get plays(custom-relation:r1) get annotations contain: @card(<args>)
    Then relation(marriage) get plays(custom-relation:r1) get annotations contain: @card(<args>)
    Then entity(player) get plays(overridden-custom-relation:overridden-r2) get annotations contain: @card(<args>)
    Then relation(marriage) get plays(overridden-custom-relation:overridden-r2) get annotations contain: @card(<args>)
    When entity(player) get plays(custom-relation:r1) set annotation: @card(<args>)
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When relation(marriage) get plays(custom-relation:r1) set annotation: @card(<args>)
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When entity(player) get plays(overridden-custom-relation:overridden-r2) set annotation: @card(<args>)
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When relation(marriage) get plays(overridden-custom-relation:overridden-r2) set annotation: @card(<args>)
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
# not compatible @annotations: @distinct, @key, @unique, @subkey, @values, @range, @regex, @abstract, @cascade, @independent, @replace
########################

  Scenario Outline: <root-type> cannot play a role with @distinct, @key, @unique, @subkey, @values, @range, @regex, @abstract, @cascade, @independent, and @replace annotations
    When create relation type: marriage
    When relation(marriage) create role: husband
    When <root-type>(<type-name>) set plays: marriage:husband
    Then <root-type>(<type-name>) get plays(marriage:husband) set annotation: @distinct; fails
    Then <root-type>(<type-name>) get plays(marriage:husband) set annotation: @key; fails
    Then <root-type>(<type-name>) get plays(marriage:husband) set annotation: @unique; fails
    Then <root-type>(<type-name>) get plays(marriage:husband) set annotation: @subkey; fails
    Then <root-type>(<type-name>) get plays(marriage:husband) set annotation: @subkey(LABEL); fails
    Then <root-type>(<type-name>) get plays(marriage:husband) set annotation: @values; fails
    Then <root-type>(<type-name>) get plays(marriage:husband) set annotation: @values(1); fails
    Then <root-type>(<type-name>) get plays(marriage:husband) set annotation: @range; fails
    Then <root-type>(<type-name>) get plays(marriage:husband) set annotation: @range(1, 2); fails
    Then <root-type>(<type-name>) get plays(marriage:husband) set annotation: @regex; fails
    Then <root-type>(<type-name>) get plays(marriage:husband) set annotation: @regex("value"); fails
    Then <root-type>(<type-name>) get plays(marriage:husband) set annotation: @abstract; fails
    Then <root-type>(<type-name>) get plays(marriage:husband) set annotation: @cascade; fails
    Then <root-type>(<type-name>) get plays(marriage:husband) set annotation: @independent; fails
    Then <root-type>(<type-name>) get plays(marriage:husband) set annotation: @replace; fails
    Then <root-type>(<type-name>) get plays(marriage:husband) set annotation: @does-not-exist; fails
    Then <root-type>(<type-name>) get plays(marriage:husband) get annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then <root-type>(<type-name>) get plays(marriage:husband)) get annotations is empty
    Examples:
      | root-type | type-name   |
      | entity    | person      |
      | relation  | description |

########################
# @annotations combinations:
# @card - the only compatible annotation, nothing to combine yet
########################
