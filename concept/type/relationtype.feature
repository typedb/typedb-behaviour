# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Concept Relation Type and Role Type

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection reset database: typedb
    Given connection open schema transaction for database: typedb

########################
# relation type common
########################

  Scenario: Non-abstract relation and cannot be created without roles
    When create relation type: marriage
    Then transaction commits; fails

  Scenario: Cyclic relation type hierarchies are disallowed
    When create relation type: rel0
    When relation(rel0) create role: role0
    When create relation type: rel1
    When relation(rel1) create role: role1
    When relation(rel1) set supertype: rel0
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(rel1) set supertype: rel1; fails
    Then relation(rel0) set supertype: rel1; fails

  Scenario: Relation and role types can be created
    When create relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    Then relation(marriage) exists
    Then relation(marriage) get supertype does not exist
    Then relation(marriage) get role(husband) exists
    Then relation(marriage) get role(wife) exists
    Then relation(marriage) get role(husband) get supertype does not exist
    Then relation(marriage) get role(wife) get supertype does not exist
    Then relation(marriage) get relates contain:
      | marriage:husband |
      | marriage:wife    |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(marriage) exists
    Then relation(marriage) get supertype does not exist
    Then relation(marriage) get role(husband) exists
    Then relation(marriage) get role(wife) exists
    Then relation(marriage) get role(husband) get supertype does not exist
    Then relation(marriage) get role(wife) get supertype does not exist
    Then relation(marriage) get relates contain:
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
    Then relation(parentship) get relates contain:
      | parentship:parent |
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
    Then relation(parentship) get relates do not contain:
      | parent |
    Then get role types do not contain:
      | parentship:parent |
    When transaction commits
    When connection open schema transaction for database: typedb
    When delete relation type: parentship
    Then relation(parentship) does not exist
    Then get role types do not contain:
      | parentship:parent |
      | parentship:child  |
    When relation(marriage) delete role: spouse
    Then relation(marriage) get relates do not contain:
      | spouse |
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    When transaction commits
    When connection open schema transaction for database: typedb
    When delete relation type: marriage
    Then relation(marriage) does not exist
    Then get role types do not contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) does not exist
    Then relation(marriage) does not exist
    Then get role types do not contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |

  Scenario: Relation and role types can change names
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    Then relation(parentship) get name: parentship
    Then relation(parentship) get role(parent) get name: parent
    Then relation(parentship) get role(child) get name: child
    When relation(parentship) set label: marriage
    Then relation(parentship) does not exist
    Then relation(marriage) exists
    When relation(marriage) get role(parent) set name: husband
    When relation(marriage) get role(child) set name: wife
    Then relation(marriage) get role(parent) does not exist
    Then relation(marriage) get role(child) does not exist
    Then relation(marriage) get role(husband) exists
    Then relation(marriage) get role(wife) exists
    Then relation(marriage) get name: marriage
    Then relation(marriage) get role(husband) get name: husband
    Then relation(marriage) get role(wife) get name: wife
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(marriage) get name: marriage
    Then relation(marriage) get role(husband) get name: husband
    Then relation(marriage) get role(wife) get name: wife
    When relation(marriage) set label: employment
    Then relation(marriage) does not exist
    Then relation(employment) exists
    When relation(employment) get role(husband) set name: employee
    When relation(employment) get role(wife) set name: employer
    Then relation(employment) get role(husband) does not exist
    Then relation(employment) get role(wife) does not exist
    Then relation(employment) get role(employee) exists
    Then relation(employment) get role(employer) exists
    Then relation(employment) get name: employment
    Then relation(employment) get role(employee) get name: employee
    Then relation(employment) get role(employer) get name: employer
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(employment) exists
    Then relation(employment) get name: employment
    Then relation(employment) get role(employee) get name: employee
    Then relation(employment) get role(employer) get name: employer

  Scenario: Relation types may not declare a role with the same name as one declared in its inheritance line
    When create relation type: rel00
    When relation(rel00) set annotation: @abstract
    When relation(rel00) create role: role00
    When create relation type: rel01
    When relation(rel01) set annotation: @abstract
    When relation(rel01) create role: role01
    When relation(rel01) create role: role02
    When create relation type: rel1
    When relation(rel1) set annotation: @abstract
    When relation(rel1) set supertype: rel00
    When relation(rel1) create role: role01
    Then transaction commits
    When connection open schema transaction for database: typedb
    When relation(rel1) create role: role00; fails
    When relation(rel00) create role: role01; fails
    When relation(rel1) set supertype: rel01; fails
    When create relation type: rel2
    When relation(rel2) set annotation: @abstract
    When relation(rel2) create role: role2
    When relation(rel2) get role(role2) set annotation: @abstract
    When create relation type: rel02
    When relation(rel02) set annotation: @abstract
    When relation(rel02) create role: role02
    When relation(rel02) set supertype: rel2
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(rel2) set supertype: rel01; fails
    When create relation type: rel3
    When relation(rel3) set annotation: @abstract
    When create relation type: rel4
    When relation(rel4) set annotation: @abstract
    When relation(rel4) create role: role02
    When relation(rel4) set supertype: rel3
    Then relation(rel4) set supertype: rel02; fails
    Then relation(rel3) set supertype: rel02; fails
    When relation(rel4) unset supertype
    When relation(rel3) set supertype: rel02
    Then relation(rel4) set supertype: rel3; fails

  Scenario: Relation and role types can be subtypes of other relation and role types
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set specialise: parent
    Then relation(fathership) get supertype: parentship
    Then relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(parentship) get role(parent) get supertype does not exist
    Then relation(parentship) get role(child) get supertype does not exist
    Then relation(parentship) get relates(parentship:parent) is specialising: false
    Then relation(fathership) get relates(parentship:parent) is specialising: true
    Then relation(fathership) get supertypes contain:
      | parentship |
    Then relation(fathership) get role(father) get supertypes contain:
      | parentship:parent |
    Then relation(parentship) get role(child) get supertypes is empty
    Then relation(parentship) get subtypes contain:
      | fathership |
    Then relation(parentship) get role(parent) get subtypes contain:
      | fathership:father |
    Then relation(parentship) get role(child) get subtypes is empty
    Then get relation types contain:
      | parentship |
      | fathership |
    Then get role types contain:
      | parentship:parent |
      | parentship:child  |
      | fathership:father |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(fathership) get supertype: parentship
    Then relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(parentship) get role(child) get supertype does not exist
    Then relation(fathership) get supertypes contain:
      | parentship |
    Then relation(fathership) get role(father) get supertypes contain:
      | parentship:parent |
    Then relation(parentship) get role(child) get supertypes is empty
    Then relation(parentship) get subtypes contain:
      | fathership |
    Then relation(parentship) get role(parent) get subtypes contain:
      | fathership:father |
    Then relation(parentship) get role(child) get subtypes is empty
    Then get relation types contain:
      | parentship |
      | fathership |
    Then get role types contain:
      | parentship:parent |
      | parentship:child  |
      | fathership:father |
    When create relation type: father-son
    When relation(father-son) set supertype: fathership
    When relation(father-son) create role: son
    When relation(father-son) get role(son) set specialise: child
    Then relation(father-son) get supertype: fathership
    Then relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(father-son) get role(son) get supertype: parentship:child
    Then relation(father-son) get supertypes contain:
      | parentship |
      | fathership |
    Then relation(fathership) get role(father) get supertypes contain:
      | parentship:parent |
    Then relation(father-son) get role(son) get supertypes contain:
      | parentship:child |
    Then relation(fathership) get subtypes contain:
      | father-son |
    Then relation(fathership) get role(father) get subtypes is empty
    Then relation(parentship) get role(child) get subtypes contain:
      | father-son:son |
    Then relation(parentship) get role(parent) get subtypes contain:
      | fathership:father |
    Then relation(parentship) get role(child) get subtypes contain:
      | father-son:son |
    Then get relation types contain:
      | parentship |
      | fathership |
    Then get role types contain:
      | parentship:parent |
      | parentship:child  |
      | fathership:father |
      | father-son:son    |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(father-son) get supertype: fathership
    Then relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(father-son) get role(son) get supertype: parentship:child
    Then relation(father-son) get supertypes contain:
      | parentship |
      | fathership |
    Then relation(fathership) get role(father) get supertypes contain:
      | parentship:parent |
    Then relation(father-son) get role(son) get supertypes contain:
      | parentship:child |
    Then relation(fathership) get supertype: parentship
    Then relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(parentship) get role(child) get supertype does not exist
    Then relation(fathership) get supertypes contain:
      | parentship |
    Then relation(fathership) get role(father) get supertypes contain:
      | parentship:parent |
    Then relation(parentship) get role(child) get supertypes is empty
    Then relation(fathership) get subtypes contain:
      | father-son |
    Then relation(fathership) get role(father) get subtypes is empty
    Then relation(parentship) get role(child) get subtypes contain:
      | father-son:son |
    Then relation(parentship) get role(parent) get subtypes contain:
      | fathership:father |
    Then relation(parentship) get role(child) get subtypes contain:
      | father-son:son |
    Then get relation types contain:
      | parentship |
      | fathership |
    Then get role types contain:
      | parentship:parent |
      | parentship:child  |
      | fathership:father |
      | father-son:son    |

  Scenario: Relation types must relate at least one role
    When create relation type: rel0a
    Then relation(rel0a) get relates is empty
    Then relation(rel0a) get declared relates is empty
    Then relation(rel0a) get role(role) does not exist
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    When create relation type: rel0b
    When relation(rel0b) create role: role0b
    Then relation(rel0b) get relates contain:
      | rel0b:role0b |
    Then relation(rel0b) get declared relates contain:
      | rel0b:role0b |
    When transaction commits

    When connection open schema transaction for database: typedb
    Then relation(rel0b) get relates contain:
      | rel0b:role0b |
    Then relation(rel0b) get declared relates contain:
      | rel0b:role0b |
    When relation(rel0b) delete role: role0b
    Then relation(rel0b) get relates is empty
    Then relation(rel0b) get relates do not contain:
      | rel0b:role0b |
    Then relation(rel0b) get declared relates is empty
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    When create relation type: rel0c
    When relation(rel0c) set annotation: @abstract
    Then relation(rel0c) get relates is empty
    Then relation(rel0c) get declared relates is empty
    Then transaction commits; fails

    When connection open schema transaction for database: typedb
    When create relation type: rel0c
    When relation(rel0c) set annotation: @abstract
    When relation(rel0c) create role: role0c
    When relation(rel0c) get role(role0c) set annotation: @abstract
    Then relation(rel0c) get relates contain:
      | rel0c:role0c |
    Then relation(rel0c) get declared relates contain:
      | rel0c:role0c |
    When transaction commits

    When connection open schema transaction for database: typedb
    Then relation(rel0c) get relates contain:
      | rel0c:role0c |
    Then relation(rel0c) get declared relates contain:
      | rel0c:role0c |
    When relation(rel0c) unset annotation: @abstract
    Then transaction commits

  Scenario: Relation types cannot subtype itself
    When create relation type: marriage
    When relation(marriage) create role: wife
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(marriage) set supertype: marriage; fails

  Scenario: Roles cannot subtype itself
    When create relation type: marriage
    When relation(marriage) create role: wife
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(marriage) get role(wife) set specialise: wife; fails

  Scenario: Relation types can inherit related role types
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set specialise: parent
    Then relation(fathership) get relates contain:
      | fathership:father |
      | parentship:child  |
      | parentship:parent |
    Then relation(fathership) get declared relates contain:
      | fathership:father |
      | parentship:parent |
    Then relation(fathership) get declared relates do not contain:
      | parentship:child |
    Then relation(parentship) get relates(parentship:parent) is specialising: false
    Then relation(fathership) get relates(parentship:parent) is specialising: true
    Then relation(parentship) get role(parent) get declared annotations do not contain: @abstract
    Then relation(parentship) get role(parent) get constraints do not contain: @abstract
    Then relation(parentship) get constraints for related role(parentship:parent) do not contain: @abstract
    Then relation(fathership) get constraints for related role(parentship:parent) contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get constraints for related role(parentship:parent) do not contain: @abstract
    Then relation(fathership) get constraints for related role(parentship:parent) contain: @abstract
    When create relation type: mothership
    When relation(mothership) set supertype: parentship
    When relation(mothership) create role: mother
    When relation(mothership) get role(mother) set specialise: parent
    Then relation(mothership) get relates contain:
      | mothership:mother |
      | parentship:child  |
    Then relation(mothership) get declared relates contain:
      | mothership:mother |
    Then relation(mothership) get declared relates do not contain:
      | parentship:child |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get relates contain:
      | fathership:father |
      | parentship:child  |
    Then relation(fathership) get declared relates contain:
      | fathership:father |
    Then relation(fathership) get declared relates do not contain:
      | parentship:child |
    Then relation(mothership) get relates contain:
      | mothership:mother |
      | parentship:child  |
    Then relation(mothership) get declared relates contain:
      | mothership:mother |
    Then relation(mothership) get declared relates do not contain:
      | parentship:child |

  Scenario: Relation types can unset specialise of inherited role types
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set specialise: parent
    Then relation(fathership) get relates contain:
      | fathership:father |
      | parentship:child  |
      | parentship:parent |
    Then relation(fathership) get relates(fathership:father) is specialising: false
    Then relation(fathership) get relates(parentship:child) is specialising: false
    Then relation(fathership) get relates(parentship:parent) is specialising: true
    Then relation(fathership) get declared relates contain:
      | fathership:father |
      | parentship:parent |
    Then relation(fathership) get declared relates do not contain:
      | parentship:child |
    When relation(fathership) get role(father) unset specialise
    Then relation(fathership) get relates contain:
      | fathership:father |
      | parentship:parent |
      | parentship:child  |
      | parentship:parent |
    Then relation(fathership) get relates(fathership:father) is specialising: false
    Then relation(fathership) get relates(parentship:child) is specialising: false
    Then relation(fathership) get relates(parentship:parent) is specialising: false
    Then relation(fathership) get declared relates contain:
      | fathership:father |
    Then relation(fathership) get declared relates do not contain:
      | parentship:parent |
      | parentship:child  |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get relates contain:
      | fathership:father |
      | parentship:parent |
      | parentship:child  |
      | parentship:parent |
    Then relation(fathership) get relates(fathership:father) is specialising: false
    Then relation(fathership) get relates(parentship:child) is specialising: false
    Then relation(fathership) get relates(parentship:parent) is specialising: false
    Then relation(fathership) get declared relates contain:
      | fathership:father |
    Then relation(fathership) get declared relates do not contain:
      | parentship:parent |
      | parentship:child  |

  Scenario: Relation types can specialise inherited related role types
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set specialise: parent
    Then relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(fathership) get relates contain:
      | parentship:parent |
    Then relation(fathership) get relates(parentship:parent) is specialising: true
    When transaction commits
    When connection open schema transaction for database: typedb
    When create relation type: mothership
    When relation(mothership) set supertype: parentship
    When relation(mothership) create role: mother
    When relation(mothership) get role(mother) set specialise: parent
    Then relation(mothership) get relates contain:
      | parentship:parent |
    Then relation(mothership) get relates(parentship:parent) is specialising: true
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get relates contain:
      | parentship:parent |
    Then relation(fathership) get relates(parentship:parent) is specialising: true
    Then relation(mothership) get relates contain:
      | parentship:parent |
    Then relation(mothership) get relates(parentship:parent) is specialising: true
    Then relation(parentship) get relates(parentship:parent) is specialising: false

  Scenario: Relation types cannot redeclare inherited related role types
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    Then relation(fathership) create role: parent; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(fathership) get relates do not contain:
      | fathership:parent |
    Then relation(fathership) create role: parent; fails
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set specialise: parent
    When relation(fathership) create role: spouse
    Then relation(fathership) get relates contain:
      | fathership:father |
      | fathership:spouse |
      | parentship:child  |
      | parentship:parent |
    Then relation(fathership) get relates do not contain:
      | fathership:parent |
    Then relation(fathership) get relates(parentship:parent) is specialising: true
    When transaction commits
    When connection open schema transaction for database: typedb
    When create relation type: biological-fathership
    When relation(biological-fathership) create role: father
    When relation(biological-fathership) create role: parent
    When relation(biological-fathership) create role: child
    When relation(biological-fathership) create role: spouse
    Then relation(biological-fathership) get relates contain:
      | biological-fathership:father |
      | biological-fathership:parent |
      | biological-fathership:child  |
      | biological-fathership:spouse |
    When transaction closes
    When connection open schema transaction for database: typedb
    When create relation type: biological-fathership
    When relation(biological-fathership) set supertype: fathership
    Then relation(biological-fathership) create role: father; fails
    Then relation(biological-fathership) create role: parent; fails
    Then relation(biological-fathership) create role: child; fails
    Then relation(biological-fathership) create role: spouse; fails
    Then relation(biological-fathership) get relates do not contain:
      | biological-fathership:father |
      | biological-fathership:parent |
      | fathership:parent            |
      | biological-fathership:child  |
      | biological-fathership:spouse |
    Then relation(biological-fathership) get relates contain:
      | fathership:father |
      | parentship:child  |
      | fathership:spouse |
      | parentship:parent |
    Then relation(biological-fathership) get relates(parentship:parent) is specialising: true
    Then relation(biological-fathership) get relates(fathership:father) is specialising: false
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(biological-fathership) get relates do not contain:
      | biological-fathership:father |
      | biological-fathership:parent |
      | fathership:parent            |
      | biological-fathership:child  |
      | biological-fathership:spouse |
    Then relation(biological-fathership) get relates contain:
      | fathership:father |
      | parentship:child  |
      | fathership:spouse |
      | parentship:parent |
    Then relation(biological-fathership) get relates(parentship:parent) is specialising: true
    Then relation(biological-fathership) get relates(fathership:father) is specialising: false

  Scenario: Relation types cannot redeclare inherited role without changes
    When create relation type: parentship
    When relation(parentship) create role: parent
    When create relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(fathership) create role: parent; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    Then relation(fathership) create role: father; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    When relation(fathership) get role(father) set specialise: parent
    Then relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(fathership) create role: parent; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    When relation(fathership) get role(father) set specialise: parent
    Then relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(fathership) create role: father; fails

  Scenario: Relation types can update existing roles specialise a newly defined role it inherits
    When create relation type: parentship
    When relation(parentship) create role: other-role
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(parentship) create role: parent
    When relation(fathership) get role(father) set specialise: parent
    Then relation(fathership) get role(father) get supertype: parentship:parent
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get role(father) get supertype: parentship:parent

  Scenario: Role can be named as relation, entity, attribute, or role from another relation
    When create entity type: person
    When create attribute type: name
    When attribute(name) set value type: string
    When create relation type: parentship
    When relation(parentship) create role: parent
    When create relation type: marriage
    When relation(marriage) create role: marriage
    When relation(marriage) create role: parent
    When relation(marriage) create role: parentship
    When relation(marriage) create role: person
    When relation(marriage) create role: name
    Then relation(marriage) get relates contain:
      | marriage:marriage   |
      | marriage:parent     |
      | marriage:parentship |
      | marriage:person     |
      | marriage:name       |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(marriage) get relates contain:
      | marriage:marriage   |
      | marriage:parent     |
      | marriage:parentship |
      | marriage:person     |
      | marriage:name       |

  Scenario: Relation types can specialise inherited roles multiple times
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set annotation: @card(0..2)
    When create relation type: split-parentship
    Then relation(split-parentship) set supertype: split-parentship; fails
    When relation(split-parentship) set supertype: parentship
    When relation(split-parentship) create role: father
    When relation(split-parentship) get role(father) set specialise: parent
    When relation(split-parentship) create role: mother
    When relation(split-parentship) get role(mother) set specialise: parent
    Then relation(split-parentship) get relates contain:
      | split-parentship:father |
      | split-parentship:mother |
      | parentship:parent       |
    Then relation(split-parentship) get relates(parentship:parent) is specialising: true
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(split-parentship) get relates contain:
      | split-parentship:father |
      | split-parentship:mother |
      | parentship:parent       |
    Then relation(split-parentship) get relates(parentship:parent) is specialising: true

  Scenario: Relation types cannot unset supertype while having relates specialise
    When create relation type: parentship
    When relation(parentship) create role: parent
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set specialise: parent
    Then relation(fathership) unset supertype; fails
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(fathership) unset supertype; fails
    When relation(fathership) get role(father) unset specialise
    When relation(fathership) unset supertype
    Then relation(fathership) get supertype does not exist
    Then relation(fathership) get role(father) get supertype does not exist
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(fathership) get supertype does not exist
    Then relation(fathership) get role(father) get supertype does not exist
    When relation(fathership) set supertype: parentship
    When create relation type: subfathership
    When relation(subfathership) create role: subfather
    When relation(subfathership) set supertype: fathership
    When relation(subfathership) get role(subfather) set specialise: parent
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(subfathership) unset supertype; fails
    Then relation(fathership) unset supertype; fails
    When relation(subfathership) get role(subfather) unset specialise
    When relation(fathership) unset supertype
    Then relation(fathership) get supertype does not exist
    Then relation(subfathership) get role(subfather) get supertype does not exist
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get supertype does not exist
    Then relation(subfathership) get role(subfather) get supertype does not exist

  Scenario: Relation types cannot specialise already specialised inherited role types
    When create relation type: parentship
    When relation(parentship) create role: parent
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set specialise: parent
    When create relation type: subfathership
    When relation(subfathership) set supertype: fathership
    Then relation(fathership) get relates(parentship:parent) is specialising: true
    Then relation(subfathership) get relates(parentship:parent) is specialising: true
    When relation(subfathership) create role: subfather
    Then relation(subfathership) get role(subfather) set specialise: parent; fails
    When relation(fathership) get role(father) unset specialise
    Then relation(fathership) get relates(parentship:parent) is specialising: false
    Then relation(subfathership) get relates(parentship:parent) is specialising: false
    Then relation(subfathership) get role(subfather) set specialise: parent
    Then relation(fathership) get relates(parentship:parent) is specialising: false
    Then relation(subfathership) get relates(parentship:parent) is specialising: true
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(fathership) get relates(parentship:parent) is specialising: false
    Then relation(subfathership) get relates(parentship:parent) is specialising: true
    Then relation(fathership) get role(father) get supertype does not exist
    Then relation(subfathership) get role(subfather) get supertype: parentship:parent

  Scenario: Relation types can specialise already specialised role types on the same relation type
    When create relation type: parentship
    When relation(parentship) create role: parent
    When create relation type: family
    When relation(family) set supertype: parentship
    When relation(family) create role: father
    When relation(family) create role: mother
    When relation(family) get role(father) set specialise: parent
    When relation(family) get role(mother) set specialise: parent
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(family) get role(father) get supertype: parentship:parent
    Then relation(family) get role(mother) get supertype: parentship:parent
    Then relation(family) get relates(parentship:parent) is specialising: true
    Then relation(family) get constraints for related role(parentship:parent) contain: @abstract
    When relation(family) get role(mother) unset specialise
    Then relation(family) get role(father) get supertype: parentship:parent
    Then relation(family) get role(mother) get supertype does not exist
    Then relation(family) get relates(parentship:parent) is specialising: true
    Then relation(family) get constraints for related role(parentship:parent) contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(family) get role(father) get supertype: parentship:parent
    Then relation(family) get role(mother) get supertype does not exist
    Then relation(family) get relates(parentship:parent) is specialising: true
    Then relation(family) get constraints for related role(parentship:parent) contain: @abstract
    When relation(family) get role(father) unset specialise
    Then relation(family) get role(father) get supertype does not exist
    Then relation(family) get role(mother) get supertype does not exist
    Then relation(family) get relates(parentship:parent) is specialising: false
    Then relation(family) get constraints for related role(parentship:parent) do not contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(family) get role(father) get supertype does not exist
    Then relation(family) get role(mother) get supertype does not exist
    Then relation(family) get relates(parentship:parent) is specialising: false
    Then relation(family) get constraints for related role(parentship:parent) do not contain: @abstract

########################
# @annotations common
########################

  Scenario Outline: Relation type can set and unset @<annotation>
    When create relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    When relation(marriage) set annotation: @<annotation>
    Then relation(marriage) get constraints contain: @<annotation>
    Then relation(marriage) get constraint categories contain: @<annotation-category>
    Then relation(marriage) get declared annotations contain: @<annotation>
    When relation(marriage) unset annotation: @<annotation-category>
    Then relation(marriage) get constraints do not contain: @<annotation>
    Then relation(marriage) get constraint categories do not contain: @<annotation-category>
    Then relation(marriage) get declared annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(marriage) get constraints do not contain: @<annotation>
    Then relation(marriage) get constraint categories do not contain: @<annotation-category>
    Then relation(marriage) get declared annotations do not contain: @<annotation>
    When relation(marriage) set annotation: @<annotation>
    Then relation(marriage) get constraints contain: @<annotation>
    Then relation(marriage) get constraint categories contain: @<annotation-category>
    Then relation(marriage) get declared annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(marriage) get constraints contain: @<annotation>
    Then relation(marriage) get constraint categories contain: @<annotation-category>
    Then relation(marriage) get declared annotations contain: @<annotation>
    Examples:
      | annotation | annotation-category |
      | abstract   | abstract            |
    # TODO: Cascade is turned off
#      | cascade    | cascade             |

  Scenario Outline: Relation type can unset not set @<annotation>
    When create relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    Then relation(marriage) get constraints do not contain: @<annotation>
    Then relation(marriage) get declared annotations do not contain: @<annotation>
    When relation(marriage) unset annotation: @<annotation-category>
    Then relation(marriage) get constraints do not contain: @<annotation>
    Then relation(marriage) get declared annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(marriage) get constraints do not contain: @<annotation>
    Then relation(marriage) get declared annotations do not contain: @<annotation>
    When relation(marriage) unset annotation: @<annotation-category>
    Then relation(marriage) get constraints do not contain: @<annotation>
    Then relation(marriage) get declared annotations do not contain: @<annotation>
    Examples:
      | annotation | annotation-category |
      | abstract   | abstract            |
    # TODO: Cascade is turned off
#      | cascade    | cascade             |

  Scenario Outline: Relation type cannot set or unset inherited @<annotation>
    When create relation type: parentship
    When relation(parentship) create role: parent
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(parentship) set annotation: @<annotation>
    Then relation(parentship) get constraints contain: @<annotation>
    Then relation(parentship) get declared annotations contain: @<annotation>
    Then relation(fathership) get constraints contain: @<annotation>
    Then relation(fathership) get declared annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get constraints contain: @<annotation>
    Then relation(parentship) get declared annotations contain: @<annotation>
    Then relation(fathership) get constraints contain: @<annotation>
    Then relation(fathership) get declared annotations do not contain: @<annotation>
    When relation(fathership) set annotation: @<annotation>
    Then relation(fathership) get constraints contain: @<annotation>
    Then relation(fathership) get declared annotations contain: @<annotation>
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    Then relation(parentship) get constraints contain: @<annotation>
    Then relation(parentship) get declared annotations contain: @<annotation>
    Then relation(fathership) get constraints contain: @<annotation>
    Then relation(fathership) get declared annotations do not contain: @<annotation>
    Then relation(fathership) unset annotation: @<annotation-category>; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    Then relation(parentship) get constraints contain: @<annotation>
    Then relation(parentship) get declared annotations contain: @<annotation>
    Then relation(fathership) get constraints contain: @<annotation>
    Then relation(fathership) get declared annotations do not contain: @<annotation>
    Examples:
      | annotation | annotation-category |
      # abstract is not inherited
      # TODO: Cascade is turned off
#      | cascade    | cascade             |

  Scenario Outline: Relation type cannot set supertype with the same @<annotation> until it is explicitly unset from type
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) set annotation: @abstract
    When relation(parentship) set annotation: @<annotation>
    Then relation(parentship) get constraints contain: @<annotation>
    Then relation(parentship) get declared annotations contain: @<annotation>
    When create relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set annotation: @<annotation>
    Then relation(fathership) get constraints contain: @<annotation>
    Then relation(fathership) get declared annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get constraints contain: @<annotation>
    Then relation(parentship) get declared annotations contain: @<annotation>
    Then relation(fathership) get constraints contain: @<annotation>
    Then relation(fathership) get declared annotations contain: @<annotation>
    When relation(fathership) set supertype: parentship
    Then relation(parentship) get constraints contain: @<annotation>
    Then relation(parentship) get declared annotations contain: @<annotation>
    Then relation(fathership) get constraints contain: @<annotation>
    Then relation(fathership) get declared annotations contain: @<annotation>
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    Then relation(parentship) get constraints contain: @<annotation>
    Then relation(parentship) get declared annotations contain: @<annotation>
    Then relation(fathership) get constraints contain: @<annotation>
    Then relation(fathership) get declared annotations contain: @<annotation>
    When relation(fathership) set supertype: parentship
    When relation(fathership) unset annotation: @<annotation-category>
    Then relation(fathership) get constraints contain: @<annotation>
    Then relation(fathership) get declared annotations do not contain: @<annotation>
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get constraints contain: @<annotation>
    Then relation(parentship) get declared annotations contain: @<annotation>
    Then relation(fathership) get constraints contain: @<annotation>
    Then relation(fathership) get declared annotations do not contain: @<annotation>
    Examples:
      | annotation | annotation-category |
      # abstract is not inherited
  # TODO: Cascade is turned off
#      | cascade    | cascade             |

  Scenario Outline: Relation type loses inherited @<annotation> if supertype is unset
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) set annotation: @abstract
    When create relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    When relation(parentship) set annotation: @<annotation>
    Then relation(parentship) get constraints contain: @<annotation>
    Then relation(fathership) get constraints contain: @<annotation>
    When relation(fathership) unset supertype
    Then relation(parentship) get constraints contain: @<annotation>
    Then relation(fathership) get constraints do not contain: @<annotation>
    When relation(fathership) set annotation: @<annotation>
    When relation(fathership) set supertype: parentship
    Then relation(parentship) get constraints contain: @<annotation>
    Then relation(fathership) get constraints contain: @<annotation>
    Then relation(fathership) get declared annotations contain: @<annotation>
    When relation(fathership) unset annotation: @<annotation-category>
    Then relation(fathership) get declared annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get constraints contain: @<annotation>
    Then relation(fathership) get constraints contain: @<annotation>
    Then relation(fathership) get declared annotations do not contain: @<annotation>
    When relation(fathership) unset supertype
    Then relation(parentship) get constraints contain: @<annotation>
    Then relation(fathership) get constraints do not contain: @<annotation>
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get constraints contain: @<annotation>
    Then relation(fathership) get constraints do not contain: @<annotation>
    Examples:
      | annotation | annotation-category |
      # abstract is not inherited
  # TODO: Cascade is turned off
#      | cascade    | cascade             |

  Scenario Outline: Relation type cannot set redundant duplicated @<annotation> while inheriting it
    When create relation type: parentship
    When relation(parentship) create role: parent
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(parentship) set annotation: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(fathership) set annotation: @<annotation>
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When relation(fathership) set annotation: @<annotation>
    When relation(parentship) unset annotation: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get constraints do not contain: @<annotation>
    Then relation(fathership) get constraints contain: @<annotation>
    When relation(parentship) set annotation: @<annotation>
    Then transaction commits; fails
    Examples:
      | annotation |
      # abstract is not inherited
      # Cascade is turned off
#      | cascade    |

########################
# @abstract
########################

  Scenario: Abstract relation cannot be created without roles
    When create relation type: marriage
    When relation(marriage) set annotation: @abstract
    When transaction commits; fails
    When connection open read transaction for database: typedb
    Then relation(marriage) does not exist

  Scenario: Relation type can be set to abstract while role types remain concrete
    When create relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    When relation(marriage) set annotation: @abstract
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    Then relation(marriage) get constraints contain: @abstract
    Then relation(marriage) get declared annotations contain: @abstract
    Then relation(marriage) get role(husband) get constraints do not contain: @abstract
    Then relation(marriage) get role(husband) get declared annotations do not contain: @abstract
    Then relation(marriage) get role(wife) get constraints do not contain: @abstract
    Then relation(marriage) get role(wife) get declared annotations do not contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get constraints do not contain: @abstract
    Then relation(parentship) get declared annotations do not contain: @abstract
    Then relation(parentship) get role(parent) get constraints do not contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations do not contain: @abstract
    Then relation(parentship) get role(child) get constraints do not contain: @abstract
    Then relation(parentship) get role(child) get declared annotations do not contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(marriage) get constraints contain: @abstract
    Then relation(marriage) get declared annotations contain: @abstract
    Then relation(marriage) get role(husband) get constraints do not contain: @abstract
    Then relation(marriage) get role(husband) get declared annotations do not contain: @abstract
    Then relation(marriage) get role(wife) get constraints do not contain: @abstract
    Then relation(marriage) get role(wife) get declared annotations do not contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get constraints do not contain: @abstract
    Then relation(parentship) get declared annotations do not contain: @abstract
    Then relation(parentship) get role(parent) get constraints do not contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations do not contain: @abstract
    Then relation(parentship) get role(child) get constraints do not contain: @abstract
    Then relation(parentship) get role(child) get declared annotations do not contain: @abstract
    Then relation(parentship) set annotation: @abstract
    Then relation(parentship) get constraints contain: @abstract
    Then relation(parentship) get declared annotations contain: @abstract
    Then relation(parentship) get role(parent) get constraints do not contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations do not contain: @abstract
    Then relation(parentship) get role(child) get constraints do not contain: @abstract
    Then relation(parentship) get role(child) get declared annotations do not contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get constraints contain: @abstract
    Then relation(parentship) get declared annotations contain: @abstract
    Then relation(parentship) get role(parent) get constraints do not contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations do not contain: @abstract
    Then relation(parentship) get role(child) get constraints do not contain: @abstract
    Then relation(parentship) get role(child) get declared annotations do not contain: @abstract

  Scenario: Relation types must have at least one role even if it's abstract
    When create relation type: connection
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When create relation type: connection
    When relation(connection) set annotation: @abstract
    When transaction commits; fails
    When connection open schema transaction for database: typedb
    When create relation type: rel00
    When relation(rel00) set annotation: @abstract
    When relation(rel00) create role: role00
    When create relation type: rel01
    When relation(rel01) create role: role01
    When transaction commits
    When connection open schema transaction for database: typedb
    When create relation type: rel1
    When relation(rel1) set supertype: rel01
    Then relation(rel1) get relates contain:
      | rel01:role01 |
    Then relation(rel1) get declared relates is empty
    When relation(rel1) set supertype: rel00
    Then relation(rel1) get relates contain:
      | rel00:role00 |
    Then relation(rel1) get declared relates is empty
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(rel00) delete role: role00
    Then relation(rel00) get relates is empty
    Then relation(rel1) get relates is empty
    Then relation(rel00) get relates do not contain:
      | rel00:role00 |
    Then relation(rel1) get relates do not contain:
      | rel00:role00 |
    Then transaction commits; fails
    When connection open schema transaction for database: typedb
    When relation(rel1) unset supertype
    Then relation(rel1) get relates is empty
    Then transaction commits; fails

  Scenario: Relation type can reset @abstract annotation
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) set annotation: @abstract
    Then relation(parentship) get constraints contain: @abstract
    Then relation(parentship) get declared annotations contain: @abstract
    When relation(parentship) set annotation: @abstract
    Then relation(parentship) get constraints contain: @abstract
    Then relation(parentship) get declared annotations contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get constraints contain: @abstract
    Then relation(parentship) get declared annotations contain: @abstract

  Scenario: Roles can be inherited from abstract relation types
    When create relation type: parentship
    Then relation(parentship) set annotation: @abstract
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get relates contain:
      | parentship:parent |
      | parentship:child  |
    Then relation(fathership) get declared relates do not contain:
      | fathership:parent |
      | fathership:child  |
    Then relation(parentship) get role(parent) get constraints do not contain: @abstract
    Then relation(parentship) get role(child) get constraints do not contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations do not contain: @abstract
    Then relation(parentship) get role(child) get declared annotations do not contain: @abstract
    Then relation(parentship) get constraints for related role(parentship:parent) do not contain: @abstract
    Then relation(parentship) get constraints for related role(parentship:child) do not contain: @abstract
    Then relation(fathership) get constraints for related role(parentship:parent) do not contain: @abstract
    Then relation(fathership) get constraints for related role(parentship:child) do not contain: @abstract

  Scenario: Relation types can subtype non abstract relation types
    When create relation type: parentship
    When relation(parentship) create role: parent
    When create relation type: fathership
    When relation(fathership) create role: father
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get constraints do not contain: @abstract
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
    Then relation(parentship) get constraints contain: @abstract
    Then relation(parentship) get declared annotations contain: @abstract
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    Then relation(parentship) get constraints contain: @abstract
    Then relation(parentship) get declared annotations contain: @abstract
    Then relation(fathership) get constraints do not contain: @abstract
    Then relation(fathership) get declared annotations do not contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get constraints contain: @abstract
    Then relation(parentship) get declared annotations contain: @abstract
    Then relation(fathership) get constraints do not contain: @abstract
    Then relation(fathership) get declared annotations do not contain: @abstract
    When relation(fathership) set annotation: @abstract
    Then relation(fathership) get constraints contain: @abstract
    Then relation(fathership) get declared annotations contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get constraints contain: @abstract
    Then relation(fathership) get declared annotations contain: @abstract

  Scenario: Relation type can set @abstract annotation and then set abstract supertype
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) set annotation: @abstract
    Then relation(parentship) get constraints contain: @abstract
    Then relation(parentship) get declared annotations contain: @abstract
    When create relation type: fathership
    When relation(fathership) set annotation: @abstract
    Then relation(fathership) get constraints contain: @abstract
    Then relation(fathership) get declared annotations contain: @abstract
    When relation(fathership) set supertype: parentship
    Then relation(parentship) get constraints contain: @abstract
    Then relation(parentship) get declared annotations contain: @abstract
    Then relation(fathership) get constraints contain: @abstract
    Then relation(fathership) get declared annotations contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get constraints contain: @abstract
    Then relation(parentship) get declared annotations contain: @abstract
    Then relation(fathership) get constraints contain: @abstract
    Then relation(fathership) get declared annotations contain: @abstract
    Then relation(fathership) get supertype: parentship

  Scenario: Abstract relation type cannot set non-abstract supertype
    When create relation type: parentship
    When relation(parentship) create role: parent
    Then relation(parentship) get constraints do not contain: @abstract
    When create relation type: fathership
    When relation(fathership) set annotation: @abstract
    When relation(fathership) create role: father
    Then relation(fathership) get constraints contain: @abstract
    Then relation(fathership) set supertype: parentship; fails
    Then relation(parentship) get constraints do not contain: @abstract
    Then relation(fathership) get constraints contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get constraints do not contain: @abstract
    Then relation(fathership) get constraints contain: @abstract
    Then relation(fathership) get supertypes do not contain:
      | parentship |
    Then relation(fathership) set supertype: parentship; fails
    When relation(parentship) set annotation: @abstract
    When relation(fathership) set supertype: parentship
    Then relation(parentship) get constraints contain: @abstract
    Then relation(fathership) get constraints contain: @abstract
    Then relation(fathership) get supertype: parentship
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get constraints contain: @abstract
    Then relation(fathership) get constraints contain: @abstract
    Then relation(fathership) get supertype: parentship

  Scenario: Relation type cannot set @abstract annotation while having non-abstract supertype and cannot unset @abstract while having abstract subtype
    When create relation type: parentship
    When relation(parentship) create role: parent
    Then relation(parentship) get constraints do not contain: @abstract
    When create relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    Then relation(fathership) set annotation: @abstract; fails
    Then relation(parentship) get constraints do not contain: @abstract
    Then relation(fathership) get constraints do not contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get constraints do not contain: @abstract
    Then relation(fathership) get constraints do not contain: @abstract
    Then relation(fathership) set annotation: @abstract; fails
    When relation(parentship) set annotation: @abstract
    When relation(fathership) set annotation: @abstract
    Then relation(parentship) get constraints contain: @abstract
    Then relation(fathership) get constraints contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get constraints contain: @abstract
    Then relation(fathership) get constraints contain: @abstract
    Then relation(parentship) unset annotation: @abstract; fails
    When relation(fathership) unset annotation: @abstract
    When relation(parentship) unset annotation: @abstract
    Then relation(parentship) get constraints do not contain: @abstract
    Then relation(fathership) get constraints do not contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get constraints do not contain: @abstract
    Then relation(fathership) get constraints do not contain: @abstract

#########################
## @cascade # TODO: Cascade is turned off
#########################
#  Scenario: Relation type can reset @cascade annotation
#    When create relation type: parentship
#    When relation(parentship) create role: parent
#    When relation(parentship) set annotation: @cascade
#    Then relation(parentship) get constraints contain: @cascade
#    Then relation(parentship) get declared annotations contain: @cascade
#    When relation(parentship) set annotation: @cascade
#    Then relation(parentship) get constraints contain: @cascade
#    Then relation(parentship) get declared annotations contain: @cascade
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then relation(parentship) get constraints contain: @cascade
#    Then relation(parentship) get declared annotations contain: @cascade
#
#  Scenario: Relation types' @cascade annotation can be inherited
#    When create relation type: parentship
#    When relation(parentship) create role: parent
#    When create relation type: fathership
#    When relation(fathership) set supertype: parentship
#    When relation(parentship) set annotation: @cascade
#    Then relation(fathership) get constraints contain: @cascade
#    Then relation(fathership) get declared annotations do not contain: @cascade
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then relation(fathership) get constraints contain: @cascade
#    Then relation(fathership) get declared annotations do not contain: @cascade
#
#  Scenario: Relation type cannot reset inherited @cascade annotation
#    When create relation type: parentship
#    When relation(parentship) create role: parent
#    When create relation type: fathership
#    When relation(fathership) set supertype: parentship
#    When relation(parentship) set annotation: @cascade
#    Then relation(fathership) get constraints contain: @cascade
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When relation(fathership) set annotation: @cascade
#    Then transaction commits; fails
#    When connection open schema transaction for database: typedb
#    When create relation type: mothership
#    When relation(mothership) set annotation: @cascade
#    When relation(mothership) set supertype: parentship
#    Then relation(mothership) get constraints contain: @cascade
#    Then relation(mothership) get declared annotations contain: @cascade
#    Then transaction commits; fails
#    When connection open schema transaction for database: typedb
#    When create relation type: mothership
#    When relation(mothership) set annotation: @cascade
#    When relation(mothership) set supertype: parentship
#    Then relation(mothership) get constraints contain: @cascade
#    Then relation(mothership) get declared annotations contain: @cascade
#    When relation(mothership) unset annotation: @cascade
#    Then relation(mothership) get declared annotations do not contain: @cascade
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then relation(mothership) get constraints contain: @cascade
#    Then relation(mothership) get declared annotations do not contain: @cascade
#
#  Scenario: Relation type can change supertype while implicitly acquiring @cascade annotation if it doesn't have data
#    When create relation type: parentship
#    When create relation type: connection
#    When create relation type: fathership
#    When relation(parentship) create role: parent
#    When relation(connection) create role: player
#    When relation(connection) set annotation: @cascade
#    When relation(fathership) create role: father
#    When relation(fathership) set supertype: connection
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(fathership) get supertype: connection
#    Then relation(fathership) get constraints contain: @cascade
#    Then relation(fathership) get declared annotations do not contain: @cascade
#    When relation(fathership) set supertype: parentship
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(fathership) get supertype: parentship
#    Then relation(fathership) get constraints do not contain: @cascade
#    When relation(fathership) set supertype: connection
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then relation(fathership) get supertype: connection
#    Then relation(fathership) get constraints contain: @cascade
#    Then relation(fathership) get declared annotations do not contain: @cascade


########################
# @annotations combinations:
# @abstract, @cascade
########################

  # TODO: Cascade is turned off, there are not combinations
#  Scenario Outline: Relation types can set @<annotation-1> and @<annotation-2> together and unset it
#    When create relation type: parentship
#    When relation(parentship) create role: parent
#    When relation(parentship) set annotation: @<annotation-1>
#    When relation(parentship) set annotation: @<annotation-2>
#    Then relation(parentship) get constraints contain: @<annotation-1>
#    Then relation(parentship) get constraints contain: @<annotation-2>
#    Then relation(parentship) get declared annotations contain: @<annotation-1>
#    Then relation(parentship) get declared annotations contain: @<annotation-2>
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(parentship) get constraints contain: @<annotation-1>
#    Then relation(parentship) get constraints contain: @<annotation-2>
#    Then relation(parentship) get declared annotations contain: @<annotation-1>
#    Then relation(parentship) get declared annotations contain: @<annotation-2>
#    When relation(parentship) unset annotation: @<annotation-category-1>
#    Then relation(parentship) get constraints do not contain: @<annotation-1>
#    Then relation(parentship) get constraints contain: @<annotation-2>
#    Then relation(parentship) get declared annotations do not contain: @<annotation-1>
#    Then relation(parentship) get declared annotations contain: @<annotation-2>
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(parentship) get constraints do not contain: @<annotation-1>
#    Then relation(parentship) get constraints contain: @<annotation-2>
#    Then relation(parentship) get declared annotations do not contain: @<annotation-1>
#    Then relation(parentship) get declared annotations contain: @<annotation-2>
#    When relation(parentship) set annotation: @<annotation-1>
#    When relation(parentship) unset annotation: @<annotation-category-2>
#    Then relation(parentship) get constraints do not contain: @<annotation-2>
#    Then relation(parentship) get constraints contain: @<annotation-1>
#    Then relation(parentship) get declared annotations do not contain: @<annotation-2>
#    Then relation(parentship) get declared annotations contain: @<annotation-1>
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(parentship) get constraints do not contain: @<annotation-2>
#    Then relation(parentship) get constraints contain: @<annotation-1>
#    Then relation(parentship) get declared annotations do not contain: @<annotation-2>
#    Then relation(parentship) get declared annotations contain: @<annotation-1>
#    When relation(parentship) unset annotation: @<annotation-category-1>
#    Then relation(parentship) get constraints is empty
#    Then relation(parentship) get declared annotations is empty
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then relation(parentship) get constraints is empty
#    Then relation(parentship) get declared annotations is empty
#    Examples:
#      | annotation-1 | annotation-category-1 | annotation-2 | annotation-category-2 |
#      | abstract     | abstract              | cascade      | cascade               |

    # Uncomment and add Examples when they appear!
#  Scenario Outline: Relation types cannot set @<annotation-1> and @<annotation-2> together for
#    When create relation type: parentship
#    When relation(parentship) create role: parent
#    When relation(parentship) set annotation: @<annotation-1>
#    When relation(parentship) set annotation: @<annotation-2>; fails
#    When transaction closes
#    When connection open schema transaction for database: typedb
#    When create relation type: parentship
#    When relation(parentship) create role: parent
#    When relation(parentship) set annotation: @<annotation-2>
#    When relation(parentship) set annotation: @<annotation-1>; fails
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then relation(parentship) get constraints contain: @<annotation-2>
#    Then relation(parentship) get constraints do not contain: @<annotation-1>
#    Examples:
#      | annotation-1 | annotation-2 |

  Scenario: Modifying a relation or role does not leave invalid specialises
    When create relation type: rel00
    When relation(rel00) create role: role00
    When relation(rel00) create role: extra_role
    When create relation type: rel01
    When relation(rel01) create role: role01
    When create relation type: rel1
    When relation(rel1) set supertype: rel00
    When create relation type: rel2
    When relation(rel2) set supertype: rel1
    When relation(rel2) create role: role2
    When relation(rel2) get role(role2) set specialise: role00
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(rel00) delete role: role00; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    Then relation(rel2) set supertype: rel01; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    When relation(rel1) create role: role1
    # role00 is specialised by a role of rel1's subtype, but it can also be specialised by rel1 itself
    Then relation(rel1) get role(role1) set specialise: role00
    Then relation(rel00) get relates(rel00:role00) is specialising: false
    Then relation(rel1) get relates(rel00:role00) is specialising: true
    Then relation(rel2) get relates(rel00:role00) is specialising: true
    When transaction closes
    When connection open schema transaction for database: typedb
    When create relation type: rel3
    When relation(rel3) set supertype: rel1
    When relation(rel3) create role: role3
    When create relation type: rel4
    When relation(rel4) set supertype: rel1
    When relation(rel2) set supertype: rel3
    Then relation(rel2) get role(role2) get supertype: rel00:role00
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(rel2) get role(role2) get supertype: rel00:role00
    When relation(rel2) set supertype: rel4
    Then relation(rel2) get role(role2) get supertype: rel00:role00
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(rel3) get role(role3) set specialise: role00
    Then relation(rel2) set supertype: rel3; fails
    Then relation(rel3) create role: role00; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    When create relation type: rel5
    When relation(rel5) create role: role00
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(rel2) get role(role2) get supertype: rel00:role00
    Then relation(rel2) set supertype: rel5; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    Then relation(rel2) get supertype: rel4
    Then relation(rel2) get role(role2) get supertype: rel00:role00
    Then relation(rel4) set supertype: rel5; fails
    Then relation(rel2) get supertype: rel4
    Then relation(rel2) get role(role2) get supertype: rel00:role00
    When relation(rel4) set supertype: rel01; fails

  Scenario: A relation-type may only specialise role-types it inherits
    When create relation type: rel00
    When relation(rel00) create role: role00
    When create relation type: rel01
    When relation(rel01) create role: role01
    When transaction commits
    When connection open schema transaction for database: typedb
    When create relation type: rel1
    When relation(rel1) create role: role1
    Then relation(rel1) get role(role1) set specialise: role00; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    When create relation type: rel1
    When relation(rel1) set supertype: rel00
    When relation(rel1) create role: role1
    When relation(rel1) get role(role1) set specialise: role00
    Then relation(rel1) get relates contain:
      | rel1:role1 |
    Then relation(rel1) get relates do not contain:
      | rel0:role0 |
    Then transaction commits
    When connection open schema transaction for database: typedb
    Then relation(rel1) set supertype: rel01; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    Then relation(rel00) delete role: role00; fails

########################
# relates (roles) lists
########################

  Scenario: Relation and ordered roles can be created
    When create relation type: marriage
    When relation(marriage) create role: husband
    When relation(marriage) create role: wife
    Then relation(marriage) exists
    Then relation(marriage) get supertype does not exist
    Then relation(marriage) get role(husband) exists
    Then relation(marriage) get role(husband) get ordering: unordered
    When relation(marriage) get role(husband) set ordering: ordered
    Then relation(marriage) get role(husband) get ordering: ordered
    Then relation(marriage) get role(wife) exists
    Then relation(marriage) get role(wife) get ordering: unordered
    When relation(marriage) get role(wife) set ordering: ordered
    Then relation(marriage) get role(wife) get ordering: ordered
    Then relation(marriage) get role(husband) get supertype does not exist
    Then relation(marriage) get role(wife) get supertype does not exist
    Then relation(marriage) get relates contain:
      | marriage:husband |
      | marriage:wife    |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(marriage) exists
    Then relation(marriage) get supertype does not exist
    Then relation(marriage) get role(husband) exists
    Then relation(marriage) get role(wife) exists
    Then relation(marriage) get role(husband) get supertype does not exist
    Then relation(marriage) get role(wife) get supertype does not exist
    Then relation(marriage) get relates contain:
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

  Scenario: Role can change ordering only if does not conflict with subtypes or supertypes
    When create relation type: parentship
    When relation(parentship) create role: parent
    When create relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    When relation(fathership) get role(father) set specialise: parent
    When relation(fathership) get role(father) set annotation: @card(1..1)
    When relation(parentship) get role(parent) set ordering: unordered
    Then relation(parentship) get role(parent) get ordering: unordered
    When relation(fathership) get role(father) set ordering: unordered
    Then relation(fathership) get role(father) get ordering: unordered
    Then relation(parentship) get role(parent) set ordering: ordered; fails
    Then relation(fathership) get role(father) set ordering: ordered; fails
    When relation(fathership) get role(father) unset specialise
    When relation(parentship) get role(parent) set ordering: ordered
    Then relation(fathership) get role(father) set specialise: parent; fails
    When relation(fathership) get role(father) set ordering: ordered
    When relation(parentship) get role(parent) set ordering: unordered
    Then relation(fathership) get role(father) set specialise: parent; fails
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(fathership) get role(father) set specialise: parent
    Then relation(fathership) get role(father) get ordering: ordered
    Then relation(parentship) get role(parent) get ordering: ordered
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get ordering: ordered
    Then relation(fathership) get role(father) get ordering: ordered
    Then relation(fathership) get role(father) get supertype: parentship:parent

  Scenario: Relation type cannot redeclare ordered role types
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    Then relation(parentship) get relates contain:
      | parentship:parent |
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
    When transaction commits
    When connection open schema transaction for database: typedb
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
    Then relation(parentship) get relates do not contain:
      | parent |
    Then get role types do not contain:
      | parentship:parent |
    When transaction commits
    When connection open schema transaction for database: typedb
    When delete relation type: parentship
    Then relation(parentship) does not exist
    Then get role types do not contain:
      | parentship:parent |
      | parentship:child  |
    When relation(marriage) delete role: spouse
    Then relation(marriage) get relates do not contain:
      | spouse |
    When relation(marriage) create role: husband
    When relation(marriage) get role(husband) set ordering: ordered
    When relation(marriage) create role: wife
    When relation(marriage) get role(wife) set ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    When delete relation type: marriage
    Then relation(marriage) does not exist
    Then get role types do not contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) does not exist
    Then relation(marriage) does not exist
    Then get role types do not contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |

  Scenario: Relation and role lists can change labels
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) create role: child
    When relation(parentship) get role(child) set ordering: ordered
    Then relation(parentship) get name: parentship
    Then relation(parentship) get role(parent) get name: parent
    Then relation(parentship) get role(child) get name: child
    When relation(parentship) set label: marriage
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
    When relation(marriage) set label: employment
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
    When relation(fathership) get role(father) set specialise: parent
    Then relation(fathership) get supertype: parentship
    Then relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(parentship) get role(child) get supertype does not exist
    Then relation(fathership) get supertypes contain:
      | parentship |
    Then relation(fathership) get role(father) get supertypes contain:
      | parentship:parent |
    Then relation(parentship) get role(child) get supertypes is empty
    Then relation(parentship) get subtypes contain:
      | fathership |
    Then relation(parentship) get role(parent) get subtypes contain:
      | fathership:father |
    Then relation(parentship) get role(child) get subtypes is empty
    Then get relation types contain:
      | parentship |
      | fathership |
    Then get role types contain:
      | parentship:parent |
      | parentship:child  |
      | fathership:father |
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(fathership) get supertype: parentship
    Then relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(parentship) get role(child) get supertype does not exist
    Then relation(fathership) get supertypes contain:
      | parentship |
    Then relation(fathership) get role(father) get supertypes contain:
      | parentship:parent |
    Then relation(parentship) get role(child) get supertypes is empty
    Then relation(parentship) get subtypes contain:
      | fathership |
    Then relation(parentship) get role(parent) get subtypes contain:
      | fathership:father |
    Then relation(parentship) get role(child) get subtypes is empty
    Then get relation types contain:
      | parentship |
      | fathership |
    Then get role types contain:
      | parentship:parent |
      | parentship:child  |
      | fathership:father |
    When create relation type: father-son
    When relation(father-son) set supertype: fathership
    When relation(father-son) create role: son
    When relation(father-son) get role(son) set ordering: ordered
    When relation(father-son) get role(son) set specialise: child
    Then relation(father-son) get supertype: fathership
    Then relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(father-son) get role(son) get supertype: parentship:child
    Then relation(father-son) get supertypes contain:
      | parentship |
      | fathership |
    Then relation(fathership) get role(father) get supertypes contain:
      | parentship:parent |
    Then relation(father-son) get role(son) get supertypes contain:
      | parentship:child |
    Then relation(fathership) get subtypes contain:
      | father-son |
    Then relation(fathership) get role(father) get subtypes is empty
    Then relation(parentship) get role(child) get subtypes contain:
      | father-son:son |
    Then relation(parentship) get role(parent) get subtypes contain:
      | fathership:father |
    Then relation(parentship) get role(child) get subtypes contain:
      | father-son:son |
    Then get relation types contain:
      | parentship |
      | fathership |
    Then get role types contain:
      | parentship:parent |
      | parentship:child  |
      | fathership:father |
      | father-son:son    |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(father-son) get supertype: fathership
    Then relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(father-son) get role(son) get supertype: parentship:child
    Then relation(father-son) get supertypes contain:
      | parentship |
      | fathership |
    Then relation(fathership) get role(father) get supertypes contain:
      | parentship:parent |
    Then relation(father-son) get role(son) get supertypes contain:
      | parentship:child |
    Then relation(fathership) get supertype: parentship
    Then relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(parentship) get role(child) get supertype does not exist
    Then relation(fathership) get supertypes contain:
      | parentship |
    Then relation(fathership) get role(father) get supertypes contain:
      | parentship:parent |
    Then relation(parentship) get role(child) get supertypes is empty
    Then relation(fathership) get subtypes contain:
      | father-son |
    Then relation(fathership) get role(father) get subtypes is empty
    Then relation(parentship) get role(child) get subtypes contain:
      | father-son:son |
    Then relation(parentship) get role(parent) get subtypes contain:
      | fathership:father |
    Then relation(parentship) get role(child) get subtypes contain:
      | father-son:son |
    Then get relation types contain:
      | parentship |
      | fathership |
    Then get role types contain:
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
    When relation(fathership) get role(father) set specialise: parent
    Then relation(fathership) get relates contain:
      | fathership:father |
      | parentship:child  |
    Then relation(fathership) get declared relates contain:
      | fathership:father |
    Then relation(fathership) get declared relates do not contain:
      | parentship:child |
    When transaction commits
    When connection open schema transaction for database: typedb
    When create relation type: mothership
    When relation(mothership) set supertype: parentship
    When relation(mothership) create role: mother
    When relation(mothership) get role(mother) set ordering: ordered
    When relation(mothership) get role(mother) set specialise: parent
    Then relation(mothership) get relates contain:
      | mothership:mother |
      | parentship:child  |
    Then relation(mothership) get declared relates contain:
      | mothership:mother |
    Then relation(mothership) get declared relates do not contain:
      | parentship:child |
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get relates contain:
      | fathership:father |
      | parentship:child  |
    Then relation(fathership) get declared relates contain:
      | fathership:father |
    Then relation(fathership) get declared relates do not contain:
      | parentship:child |
    Then relation(mothership) get relates contain:
      | mothership:mother |
      | parentship:child  |
    Then relation(mothership) get declared relates contain:
      | mothership:mother |
    Then relation(mothership) get declared relates do not contain:
      | parentship:child |

  Scenario: Relation types can specialise inherited ordered role
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) create role: child
    When relation(parentship) get role(child) set ordering: ordered
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set ordering: ordered
    When relation(fathership) get role(father) set specialise: parent
    Then relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(fathership) get relates(parentship:parent) is specialising: true
    Then relation(fathership) get constraints for related role(parentship:parent) contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    When create relation type: mothership
    When relation(mothership) set supertype: parentship
    When relation(mothership) create role: mother
    When relation(mothership) get role(mother) set ordering: ordered
    When relation(mothership) get role(mother) set specialise: parent
    Then relation(mothership) get relates(parentship:parent) is specialising: true
    Then relation(mothership) get constraints for related role(parentship:parent) contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get relates(parentship:parent) is specialising: true
    Then relation(fathership) get constraints for related role(parentship:parent) contain: @abstract
    Then relation(mothership) get relates(parentship:parent) is specialising: true
    Then relation(mothership) get constraints for related role(parentship:parent) contain: @abstract

  Scenario: Relation types cannot redeclare inherited ordered role types
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    Then relation(fathership) create role: parent; fails

  Scenario: Roles can set supertype only if ordering matches
    When create relation type: parentship
    When relation(parentship) create role: other-role
    When relation(parentship) get role(other-role) set ordering: ordered
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set ordering: ordered
    When relation(fathership) get role(father) set specialise: other-role
    Then relation(fathership) get role(father) get supertype: parentship:other-role
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(parentship) create role: parent
    Then relation(fathership) get role(father) get supertype: parentship:other-role
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(fathership) get role(father) set specialise: parent
    Then relation(fathership) get role(father) get supertype: parentship:parent
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(fathership) get role(father) get supertype: parentship:parent
    When relation(fathership) get role(father) set specialise: other-role
    Then relation(fathership) get role(father) get supertype: parentship:other-role
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(fathership) get role(father) get supertype: parentship:other-role
    When relation(parentship) get role(parent) set ordering: unordered
    Then relation(fathership) get role(father) set specialise: parent; fails
    Then relation(fathership) get role(father) get supertype: parentship:other-role
    Then relation(fathership) get role(father) unset specialise
    When relation(fathership) get role(father) set ordering: unordered
    When relation(fathership) get role(father) set specialise: parent
    Then relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(fathership) get role(father) get ordering: unordered
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(parentship) get role(other-role) get ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(fathership) get role(father) get ordering: unordered
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(parentship) get role(other-role) get ordering: ordered
    Then relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(fathership) get role(father) set specialise: other-role; fails
    When relation(parentship) get role(other-role) set ordering: unordered
    When relation(fathership) get role(father) set specialise: other-role
    Then relation(fathership) get role(father) get ordering: unordered
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(parentship) get role(other-role) get ordering: unordered
    Then relation(fathership) get role(father) get supertype: parentship:other-role
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(fathership) get role(father) get ordering: unordered
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(parentship) get role(other-role) get ordering: unordered
    Then relation(fathership) get role(father) get supertype: parentship:other-role

  Scenario: Roles with subtypes and supertypes can change ordering only together
    When create relation type: connection
    When relation(connection) create role: part
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) set supertype: connection
    When relation(parentship) get role(parent) set specialise: part
    When create relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    When relation(fathership) get role(father) set specialise: parent
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(connection) get role(part) set ordering: ordered; fails
    Then relation(parentship) get role(parent) set ordering: ordered; fails
    Then relation(fathership) get role(father) set ordering: ordered; fails
    When relation(parentship) get role(parent) unset specialise
    Then relation(connection) get role(part) set ordering: ordered
    Then relation(parentship) get role(parent) set specialise: part; fails
    Then relation(parentship) get role(parent) set ordering: ordered; fails
    Then relation(fathership) get role(father) set ordering: ordered; fails
    When relation(fathership) delete role: father
    Then relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) get role(parent) set specialise: part
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(fathership) create role: father
    Then relation(fathership) get role(father) set specialise: parent; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    When relation(fathership) create role: father[]
    When relation(fathership) get role(father) set specialise: parent
    Then relation(connection) get role(part) get ordering: ordered
    Then relation(parentship) get role(parent) get ordering: ordered
    Then relation(fathership) get role(father) get ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(connection) get role(part) set ordering: unordered; fails
    Then relation(parentship) get role(parent) set ordering: unordered; fails
    Then relation(fathership) get role(father) set ordering: unordered; fails
    When relation(fathership) get role(father) unset specialise
    Then relation(connection) get role(part) set ordering: unordered; fails
    Then relation(parentship) get role(parent) set ordering: unordered; fails
    Then relation(fathership) get role(father) set ordering: unordered
    When relation(parentship) get role(parent) unset specialise
    Then relation(connection) get role(part) set ordering: unordered
    Then relation(parentship) get role(parent) set ordering: unordered
    When relation(parentship) get role(parent) set specialise: part
    When relation(fathership) get role(father) set specialise: parent
    Then relation(connection) get role(part) get ordering: unordered
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(fathership) get role(father) get ordering: unordered
    Then transaction commits
    When connection open read transaction for database: typedb
    Then relation(connection) get role(part) get ordering: unordered
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(fathership) get role(father) get ordering: unordered

########################
# relates @annotations common
########################

  Scenario Outline: Role can unset not set @<annotation>
    When create relation type: marriage
    When relation(marriage) create role: spouse
    Then relation(marriage) get role(spouse) get declared annotations do not contain: @<annotation>
    When relation(marriage) get role(spouse) unset annotation: @<annotation-category>
    Then relation(marriage) get role(spouse) get declared annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(marriage) get role(spouse) get declared annotations do not contain: @<annotation>
    When relation(marriage) get role(spouse) unset annotation: @<annotation-category>
    Then relation(marriage) get role(spouse) get declared annotations do not contain: @<annotation>
    Examples:
      | annotation | annotation-category |
      | abstract   | abstract            |
      | distinct   | distinct            |
      | card(1..2) | card                |

  Scenario Outline: Role can set and unset @<annotation>
    When create relation type: marriage
    When relation(marriage) set annotation: @abstract
    When relation(marriage) create role: spouse
    When relation(marriage) get role(spouse) set annotation: @<annotation>
    Then relation(marriage) get role(spouse) get declared annotation categories contain: @<annotation-category>
    Then relation(marriage) get role(spouse) get declared annotations contain: @<annotation>
    When relation(marriage) get role(spouse) unset annotation: @<annotation-category>
    Then relation(marriage) get role(spouse) get declared annotation categories do not contain: @<annotation-category>
    Then relation(marriage) get role(spouse) get declared annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(marriage) get role(spouse) get declared annotation categories do not contain: @<annotation-category>
    Then relation(marriage) get role(spouse) get declared annotations do not contain: @<annotation>
    When relation(marriage) get role(spouse) set annotation: @<annotation>
    Then relation(marriage) get role(spouse) get declared annotation categories contain: @<annotation-category>
    Then relation(marriage) get role(spouse) get declared annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(marriage) get role(spouse) get declared annotation categories contain: @<annotation-category>
    Then relation(marriage) get role(spouse) get declared annotations contain: @<annotation>
    Examples:
      | annotation | annotation-category |
      | abstract   | abstract            |
      | card(1..2) | card                |

  Scenario Outline: Ordered role can unset not set @<annotation>
    When create relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) get role(spouse) set ordering: ordered
    Then relation(marriage) get role(spouse) get declared annotations do not contain: @<annotation>
    When relation(marriage) get role(spouse) unset annotation: @<annotation-category>
    Then relation(marriage) get role(spouse) get declared annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(marriage) get role(spouse) get declared annotations do not contain: @<annotation>
    When relation(marriage) get role(spouse) unset annotation: @<annotation-category>
    Then relation(marriage) get role(spouse) get declared annotations do not contain: @<annotation>
    Examples:
      | annotation | annotation-category |
      | abstract   | abstract            |
      | distinct   | distinct            |
      | card(1..2) | card                |

  Scenario Outline: Ordered roles can set and unset @<annotation>
    When create relation type: marriage
    When relation(marriage) set annotation: @abstract
    When relation(marriage) create role: spouse
    When relation(marriage) get role(spouse) set ordering: ordered
    When relation(marriage) get role(spouse) set annotation: @<annotation>
    Then relation(marriage) get role(spouse) get declared annotations contain: @<annotation>
    When relation(marriage) get role(spouse) unset annotation: @<annotation-category>
    Then relation(marriage) get role(spouse) get declared annotation categories do not contain: @<annotation-category>
    Then relation(marriage) get role(spouse) get declared annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(marriage) get role(spouse) get declared annotation categories do not contain: @<annotation-category>
    Then relation(marriage) get role(spouse) get declared annotations do not contain: @<annotation>
    When relation(marriage) get role(spouse) set annotation: @<annotation>
    Then relation(marriage) get role(spouse) get declared annotation categories contain: @<annotation-category>
    Then relation(marriage) get role(spouse) get declared annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(marriage) get role(spouse) get declared annotation categories contain: @<annotation-category>
    Then relation(marriage) get role(spouse) get declared annotations contain: @<annotation>
    Examples:
      | annotation | annotation-category |
      | abstract   | abstract            |
      | distinct   | distinct            |
      | card(1..2) | card                |

  Scenario Outline: Role can set or unset inherited @<annotation> of inherited role
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) get role(parent) set annotation: @<annotation>
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) get role(parent) get ordering: ordered
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(parentship) get role(parent) get ordering: ordered
    Then relation(parentship) get role(parent) get constraints contain: @<annotation>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation>
    Then relation(parentship) get role(parent) get constraints contain: @<annotation>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @<annotation>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation>
    Then relation(parentship) get role(parent) get constraints contain: @<annotation>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation>
    When relation(parentship) get role(parent) set annotation: @<annotation>
    Then relation(parentship) get role(parent) get constraints contain: @<annotation>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation>
    Then relation(parentship) get role(parent) get constraints contain: @<annotation>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @<annotation>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation>
    Then relation(parentship) get role(parent) get constraints contain: @<annotation>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation>
    Then relation(parentship) get role(parent) unset annotation: @<annotation-category>
    Then relation(parentship) get role(parent) get constraints do not contain: @<annotation>
    Then relation(parentship) get role(parent) get declared annotations do not contain: @<annotation>
    Then relation(parentship) get role(parent) get constraints do not contain: @<annotation>
    Then relation(parentship) get role(parent) get declared annotations do not contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints do not contain: @<annotation>
    Then relation(parentship) get role(parent) get declared annotations do not contain: @<annotation>
    Then relation(parentship) get role(parent) get constraints do not contain: @<annotation>
    Then relation(parentship) get role(parent) get declared annotations do not contain: @<annotation>
    Examples:
      | annotation | annotation-category |
      | distinct   | distinct            |
      | card(1..2) | card                |

  Scenario Outline: Role types relates can have "redundant" @<annotation> annotations already declared on specialised relates
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) get role(parent) set annotation: @<annotation>
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set ordering: ordered
    When relation(fathership) get role(father) set specialise: parent
    Then relation(fathership) get role(father) get constraints do not contain: @<annotation>
    Then relation(fathership) get role(father) get declared annotations do not contain: @<annotation>
    Then relation(fathership) get constraints for related role(fathership:father) contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(fathership) get role(father) set annotation: @<annotation>
    Then transaction commits
    Examples:
      | annotation |
      | distinct   |
      | card(1..2) |

  Scenario Outline: Role cannot set or unset inherited @<annotation> of specialised role
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) get role(parent) set annotation: @<annotation>
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set ordering: ordered
    When relation(fathership) get role(father) set specialise: parent
    Then relation(parentship) get role(parent) get constraints contain: @<annotation>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation>
    Then relation(fathership) get role(father) get constraints do not contain: @<annotation>
    Then relation(fathership) get role(father) get declared annotations do not contain: @<annotation>
    Then relation(fathership) get constraints for related role(fathership:father) contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @<annotation>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation>
    Then relation(fathership) get role(father) get constraints do not contain: @<annotation>
    Then relation(fathership) get role(father) get declared annotations do not contain: @<annotation>
    Then relation(fathership) get constraints for related role(fathership:father) contain: @<annotation>
    When relation(fathership) get role(father) set annotation: @<annotation>
    Then transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @<annotation>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation>
    Then relation(fathership) get role(father) get constraints contain: @<annotation>
    Then relation(fathership) get role(father) get declared annotations contain: @<annotation>
    Then relation(fathership) get constraints for related role(fathership:father) contain: @<annotation>
    Examples:
      | annotation | annotation-category |
      | distinct   | distinct            |
      | card(1..2) | card                |

  Scenario Outline: Role can set supertype with relates with the same @<annotation>
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) get role(parent) set annotation: @<annotation>
    Then relation(parentship) get role(parent) get constraints contain: @<annotation>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation>
    When create relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set ordering: ordered
    When relation(fathership) get role(father) set annotation: @<annotation>
    Then relation(fathership) get role(father) get constraints contain: @<annotation>
    Then relation(fathership) get role(father) get declared annotations contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @<annotation>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation>
    Then relation(fathership) get role(father) get constraints contain: @<annotation>
    Then relation(fathership) get role(father) get declared annotations contain: @<annotation>
    When relation(fathership) set supertype: parentship
    When relation(fathership) get role(father) set specialise: parent
    Then relation(parentship) get role(parent) get constraints contain: @<annotation>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation>
    Then relation(fathership) get role(father) get constraints contain: @<annotation>
    Then relation(fathership) get role(father) get declared annotations contain: @<annotation>
    Then transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @<annotation>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation>
    Then relation(fathership) get role(father) get constraints contain: @<annotation>
    Then relation(fathership) get role(father) get declared annotations contain: @<annotation>
    When relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(parentship) get constraints for related role(parentship:parent) contain: @<annotation>
    Then relation(fathership) get constraints for related role(fathership:father) contain: @<annotation>
    Then relation(fathership) get role(father) unset annotation: @<annotation-category>
    Then relation(parentship) get role(parent) get constraints contain: @<annotation>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation>
    Then relation(fathership) get role(father) get constraints do not contain: @<annotation>
    Then relation(fathership) get role(father) get declared annotations do not contain: @<annotation>
    When relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(parentship) get constraints for related role(parentship:parent) contain: @<annotation>
    Then relation(fathership) get constraints for related role(fathership:father) contain: @<annotation>
    Then transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @<annotation>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation>
    Then relation(fathership) get role(father) get constraints do not contain: @<annotation>
    Then relation(fathership) get role(father) get declared annotations do not contain: @<annotation>
    When relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(parentship) get constraints for related role(parentship:parent) contain: @<annotation>
    Then relation(fathership) get constraints for related role(fathership:father) contain: @<annotation>
    Examples:
      | annotation | annotation-category |
      | distinct   | distinct            |
      | card(1..2) | card                |

  Scenario Outline: Role type loses inherited @<annotation> if supertype is unset
    When create relation type: parentship
    When relation(parentship) set annotation: @abstract
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) get role(parent) set annotation: @<annotation>
    When create relation type: fathership
    When relation(fathership) set annotation: @abstract
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    When relation(fathership) get role(father) set ordering: ordered
    When relation(fathership) get role(father) set specialise: parent
    Then relation(parentship) get role(parent) get constraints contain: @<annotation>
    Then relation(fathership) get role(father) get constraints do not contain: @<annotation>
    Then relation(parentship) get constraints for related role(parentship:parent) contain: @<annotation>
    Then relation(fathership) get constraints for related role(fathership:father) contain: @<annotation>
    When relation(fathership) get role(father) unset specialise
    When relation(fathership) get role(father) get supertype does not exist
    Then relation(parentship) get role(parent) get constraints contain: @<annotation>
    Then relation(fathership) get role(father) get constraints do not contain: @<annotation>
    Then relation(parentship) get constraints for related role(parentship:parent) contain: @<annotation>
    Then relation(fathership) get constraints for related role(fathership:father) do not contain: @<annotation>
    When relation(fathership) get role(father) set specialise: parent
    When relation(fathership) get role(father) get supertype: parentship:parent
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation>
    Then relation(parentship) get role(parent) get constraints contain: @<annotation>
    Then relation(parentship) get constraints for related role(parentship:parent) contain: @<annotation>
    Then relation(fathership) get role(father) get declared annotations do not contain: @<annotation>
    Then relation(fathership) get role(father) get constraints do not contain: @<annotation>
    Then relation(fathership) get constraints for related role(fathership:father) contain: @<annotation>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @<annotation>
    Then relation(fathership) get role(father) get constraints do not contain: @<annotation>
    Then relation(parentship) get constraints for related role(parentship:parent) contain: @<annotation>
    Then relation(fathership) get constraints for related role(fathership:father) contain: @<annotation>
    Then relation(fathership) get role(father) get declared annotations do not contain: @<annotation>
    When relation(fathership) get role(father) unset specialise
    When relation(fathership) get role(father) get supertype does not exist
    Then relation(parentship) get role(parent) get constraints contain: @<annotation>
    Then relation(fathership) get role(father) get constraints do not contain: @<annotation>
    Then relation(parentship) get constraints for related role(parentship:parent) contain: @<annotation>
    Then relation(fathership) get constraints for related role(fathership:father) do not contain: @<annotation>
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @<annotation>
    Then relation(fathership) get role(father) get constraints do not contain: @<annotation>
    Then relation(parentship) get constraints for related role(parentship:parent) contain: @<annotation>
    Then relation(fathership) get constraints for related role(fathership:father) do not contain: @<annotation>
    Examples:
      | annotation |
      | distinct   |
      | card(1..2) |

  Scenario Outline: Relates can set annotation @<annotation> if it already has its constraint because of the sibling subtype
    When create relation type: parentship
    When relation(parentship) create role: parent[]
    When relation(parentship) get role(parent) set annotation: @<annotation>
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father[]
    When relation(fathership) get role(father) set specialise: parent
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(parentship) get role(parent) get declared annotations contain: @<annotation>
    When relation(fathership) get role(father) get declared annotations do not contain: @<annotation>
    Then relation(fathership) get constraints for related role(fathership:father) contain: @<annotation>
    When relation(fathership) get role(father) set annotation: @<annotation>
    Then transaction commits
    When connection open read transaction for database: typedb
    When relation(parentship) get role(parent) get declared annotations contain: @<annotation>
    When relation(fathership) get role(father) get declared annotations contain: @<annotation>
    When relation(fathership) get constraints for related role(fathership:father) contain: @<annotation>
    Examples:
      | annotation |
      | distinct   |
      | card(1..2) |

########################
# relates @abstract
########################

  Scenario: Relation type can set @abstract annotation for roles and unset it
    When create relation type: parentship
    When relation(parentship) set annotation: @abstract
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set annotation: @abstract
    Then relation(parentship) get role(parent) get constraints contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations contain: @abstract
    When relation(parentship) get role(parent) unset annotation: @abstract
    Then relation(parentship) get role(parent) get constraints do not contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints do not contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations is empty

  Scenario: Relation type can set @abstract annotation for ordered roles and unset it
    When create relation type: parentship
    When relation(parentship) set annotation: @abstract
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    Then relation(parentship) get role(parent) get ordering: ordered
    When relation(parentship) get role(parent) set annotation: @abstract
    Then relation(parentship) get role(parent) get constraints contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations contain: @abstract
    When relation(parentship) get role(parent) unset annotation: @abstract
    Then relation(parentship) get role(parent) get constraints do not contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints do not contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations is empty

  Scenario: Role can have @abstract annotation even if relation type is not abstract
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set annotation: @abstract
    Then relation(parentship) get role(parent) get constraints contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations contain: @abstract
    Then relation(parentship) get constraints for related role(parentship:parent) contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations contain: @abstract
    Then relation(parentship) get constraints for related role(parentship:parent) contain: @abstract

  Scenario: Roles can reset @abstract annotation
    When create relation type: parentship
    When relation(parentship) set annotation: @abstract
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set annotation: @abstract
    Then relation(parentship) get role(parent) get constraints contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations contain: @abstract
    When relation(parentship) get role(parent) set annotation: @abstract
    Then relation(parentship) get role(parent) get constraints contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations contain: @abstract

  Scenario: Inherited Roles' @abstract annotation is persistent
    When create relation type: parentship
    When relation(parentship) set annotation: @abstract
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set annotation: @abstract
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) set annotation: @abstract
    Then relation(parentship) get role(parent) get constraints contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations contain: @abstract

  Scenario: Roles' @abstract annotation cannot be inherited
    When create relation type: parentship
    When relation(parentship) set annotation: @abstract
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set annotation: @abstract
    When create relation type: fathership
    When relation(fathership) set annotation: @abstract
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    When relation(fathership) get role(father) set specialise: parent
    Then relation(fathership) get role(father) get constraints do not contain: @abstract
    Then relation(fathership) get role(father) get declared annotations do not contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations contain: @abstract
    Then relation(fathership) get role(father) get constraints do not contain: @abstract
    Then relation(fathership) get role(father) get declared annotations do not contain: @abstract
    When relation(fathership) get role(father) set annotation: @abstract
    Then relation(fathership) get role(father) get constraints contain: @abstract
    Then relation(fathership) get role(father) get declared annotations contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations contain: @abstract
    Then relation(fathership) get role(father) get constraints contain: @abstract
    Then relation(fathership) get role(father) get declared annotations contain: @abstract

  Scenario: Inherited role can set and unset @abstract annotation
    When create relation type: parentship
    When relation(parentship) set annotation: @abstract
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set annotation: @abstract
    When create relation type: fathership
    When relation(fathership) set annotation: @abstract
    When relation(fathership) set supertype: parentship
    Then relation(parentship) get role(parent) get constraints contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(parentship) get role(parent) set annotation: @abstract
    Then transaction commits
    When connection open schema transaction for database: typedb
    When create relation type: mothership
    When relation(mothership) set annotation: @abstract
    When relation(mothership) set supertype: parentship
    Then relation(parentship) get role(parent) get constraints contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations contain: @abstract
    When relation(parentship) get role(parent) set annotation: @abstract
    Then transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations contain: @abstract
    Then relation(parentship) get role(parent) unset annotation: @abstract
    Then relation(parentship) get role(parent) get constraints do not contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations do not contain: @abstract
    Then transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints do not contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations do not contain: @abstract

  Scenario: Roles can set @abstract annotation after specialising another abstract role
    When create relation type: parentship
    When relation(parentship) set annotation: @abstract
    When relation(parentship) create role: parent
    Then relation(parentship) get role(parent) set annotation: @abstract
    When create relation type: fathership
    When relation(fathership) set annotation: @abstract
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    Then relation(parentship) get role(parent) get constraints contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations contain: @abstract
    Then relation(parentship) get role(parent) get constraints contain: @abstract
    Then relation(parentship) get role(parent) get declared annotations contain: @abstract
    Then relation(fathership) get role(father) get constraints do not contain: @abstract
    Then relation(fathership) get role(father) get declared annotations do not contain: @abstract
    When relation(fathership) get role(father) set specialise: parent
    Then relation(fathership) get role(father) get constraints do not contain: @abstract
    Then relation(fathership) get role(father) get declared annotations do not contain: @abstract
    Then relation(fathership) get role(father) set annotation: @abstract
    Then relation(fathership) get role(father) get constraints contain: @abstract
    Then relation(fathership) get role(father) get declared annotations contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get role(father) get constraints contain: @abstract
    Then relation(fathership) get role(father) get declared annotations contain: @abstract

  Scenario: Abstract role type cannot set non-abstract specialise
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) set annotation: @abstract
    Then relation(parentship) get role(parent) get constraints do not contain: @abstract
    When create relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    When relation(fathership) set annotation: @abstract
    When relation(fathership) get role(father) set annotation: @abstract
    Then relation(fathership) get role(father) get constraints contain: @abstract
    Then relation(fathership) get role(father) set specialise: parent; fails
    Then relation(parentship) get role(parent) get constraints do not contain: @abstract
    Then relation(fathership) get role(father) get constraints contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints do not contain: @abstract
    Then relation(fathership) get role(father) get constraints contain: @abstract
    Then relation(fathership) get role(father) get supertypes do not contain:
      | parentship:parent |
    Then relation(fathership) get role(father) set specialise: parent; fails
    When relation(parentship) get role(parent) set annotation: @abstract
    When relation(fathership) get role(father) set specialise: parent
    Then relation(parentship) get role(parent) get constraints contain: @abstract
    Then relation(fathership) get role(father) get constraints contain: @abstract
    Then relation(fathership) get role(father) get supertype: parentship:parent
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @abstract
    Then relation(fathership) get role(father) get constraints contain: @abstract
    Then relation(fathership) get role(father) get supertype: parentship:parent

  Scenario: Role type cannot set @abstract annotation while having non-abstract supertype and cannot unset @abstract while having abstract subtype
    When create relation type: parentship
    When relation(parentship) create role: parent
    Then relation(parentship) set annotation: @abstract
    Then relation(parentship) get role(parent) get constraints do not contain: @abstract
    When create relation type: fathership
    When relation(fathership) create role: father
    Then relation(fathership) set annotation: @abstract
    When relation(fathership) set supertype: parentship
    When relation(fathership) get role(father) set specialise: parent
    Then relation(fathership) get role(father) set annotation: @abstract; fails
    Then relation(parentship) get role(parent) get constraints do not contain: @abstract
    Then relation(fathership) get role(father) get constraints do not contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints do not contain: @abstract
    Then relation(fathership) get role(father) get constraints do not contain: @abstract
    Then relation(fathership) get role(father) set annotation: @abstract; fails
    When relation(parentship) get role(parent) set annotation: @abstract
    When relation(fathership) get role(father) set annotation: @abstract
    Then relation(parentship) get role(parent) get constraints contain: @abstract
    Then relation(fathership) get role(father) get constraints contain: @abstract
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @abstract
    Then relation(fathership) get role(father) get constraints contain: @abstract
    Then relation(parentship) get role(parent) unset annotation: @abstract; fails
    When relation(fathership) get role(father) unset annotation: @abstract
    When relation(parentship) get role(parent) unset annotation: @abstract
    Then relation(parentship) get role(parent) get constraints do not contain: @abstract
    Then relation(fathership) get role(father) get constraints do not contain: @abstract
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints do not contain: @abstract
    Then relation(fathership) get role(father) get constraints do not contain: @abstract

########################
# relates @distinct
########################

  Scenario: Relation type can set @distinct annotation for ordered roles and unset it
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    Then relation(parentship) get role(parent) get ordering: ordered
    When relation(parentship) get role(parent) set annotation: @distinct
    Then relation(parentship) get role(parent) get constraints contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations contain: @distinct
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations contain: @distinct
    When relation(parentship) get role(parent) unset annotation: @distinct
    Then relation(parentship) get role(parent) get constraints do not contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints do not contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations is empty

  Scenario: Relation type cannot set @distinct annotation for unordered roles
    When create relation type: parentship
    When relation(parentship) create role: parent
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(parentship) get role(parent) set annotation: @distinct; fails
    Then relation(parentship) get role(parent) get constraints contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations is empty

  Scenario: Relation type cannot unset ordering if @distinct annotation is set
    When create relation type: parentship
    When relation(parentship) create role: parent
    Then relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) get role(parent) set annotation: @distinct
    Then relation(parentship) get role(parent) get constraints contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations contain: @distinct
    Then relation(parentship) get role(parent) get ordering: ordered
    Then relation(parentship) get role(parent) set ordering: unordered; fails
    Then relation(parentship) get role(parent) get ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get ordering: ordered
    Then relation(parentship) get role(parent) get constraints contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations contain: @distinct
    Then relation(parentship) get role(parent) set ordering: unordered; fails
    When relation(parentship) get role(parent) unset annotation: @distinct
    Then relation(parentship) get role(parent) get constraints do not contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations is empty
    Then relation(parentship) get role(parent) get ordering: ordered
    When relation(parentship) get role(parent) set ordering: unordered
    Then relation(parentship) get role(parent) get ordering: unordered
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations is empty
    Then relation(parentship) get role(parent) get ordering: unordered

  Scenario: Relation type cannot unset ordering if @distinct annotation is set
    When create relation type: parentship
    When relation(parentship) create role: parent
    Then relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) get role(parent) set annotation: @distinct
    Then relation(parentship) get role(parent) get constraints contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations contain: @distinct
    Then relation(parentship) get role(parent) get ordering: ordered
    Then relation(parentship) get role(parent) set ordering: unordered; fails
    Then relation(parentship) get role(parent) get ordering: ordered
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get ordering: ordered
    Then relation(parentship) get role(parent) get constraints contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations contain: @distinct
    Then relation(parentship) get role(parent) set ordering: unordered; fails
    When relation(parentship) get role(parent) unset annotation: @distinct
    Then relation(parentship) get role(parent) get declared annotations is empty
    Then relation(parentship) get role(parent) get constraints do not contain: @distinct
    Then relation(parentship) get role(parent) get ordering: ordered
    When relation(parentship) get role(parent) set ordering: unordered
    Then relation(parentship) get role(parent) get ordering: unordered
    Then relation(parentship) get role(parent) get constraints contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations do not contain: @distinct
    Then relation(parentship) get role(parent) get ordering: unordered
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations do not contain: @distinct
    Then relation(parentship) get role(parent) get ordering: unordered

  Scenario: Ordered roles can reset @distinct annotation
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) get role(parent) set annotation: @distinct
    Then relation(parentship) get role(parent) get constraints contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations contain: @distinct
    When relation(parentship) get role(parent) set annotation: @distinct
    Then relation(parentship) get role(parent) get constraints contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations contain: @distinct
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations contain: @distinct

  Scenario: Inherited ordered roles' @distinct annotation is persistent
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) get role(parent) set annotation: @distinct
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    Then relation(parentship) get role(parent) get constraints contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations contain: @distinct
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations contain: @distinct

  Scenario: Ordered roles' @distinct constraint is inherited by sibling subtypes
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) get role(parent) set annotation: @distinct
    When create relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    When relation(fathership) get role(father) set ordering: ordered
    When relation(fathership) get role(father) set specialise: parent
    Then relation(fathership) get role(father) get declared annotations do not contain: @distinct
    Then relation(fathership) get role(father) get constraints do not contain: @distinct
    Then relation(fathership) get constraints for related role(fathership:father) contain: @distinct
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get declared annotations contain: @distinct
    Then relation(parentship) get role(parent) get constraints contain: @distinct
    Then relation(fathership) get role(father) get declared annotations do not contain: @distinct
    Then relation(fathership) get role(father) get constraints do not contain: @distinct
    Then relation(parentship) get constraints for related role(parentship:parent) contain: @distinct
    Then relation(fathership) get constraints for related role(parentship:parent) contain: @distinct
    Then relation(fathership) get constraints for related role(fathership:father) contain: @distinct

  Scenario: Ordered roles can reset inherited @distinct annotation
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) get role(parent) set annotation: @distinct
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    Then relation(parentship) get role(parent) get constraints contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations contain: @distinct
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(parentship) get role(parent) set annotation: @distinct
    When transaction commits
    When connection open schema transaction for database: typedb
    When create relation type: mothership
    When relation(mothership) set supertype: parentship
    Then relation(parentship) get role(parent) get constraints contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations contain: @distinct
    When relation(parentship) get role(parent) set annotation: @distinct
    Then relation(parentship) get role(parent) get declared annotations contain: @distinct
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get declared annotations contain: @distinct

  Scenario: Ordered roles can unset @distinct annotation of inherited role
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    Then relation(parentship) get role(parent) set annotation: @distinct
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    Then relation(parentship) get role(parent) get constraints contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations contain: @distinct
    Then relation(parentship) get role(parent) get constraints contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations contain: @distinct
    When relation(parentship) get role(parent) unset annotation: @distinct
    Then relation(parentship) get role(parent) get constraints do not contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations do not contain: @distinct
    Then relation(parentship) get role(parent) get constraints do not contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations do not contain: @distinct
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints do not contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations do not contain: @distinct
    Then relation(parentship) get role(parent) get constraints do not contain: @distinct
    Then relation(parentship) get role(parent) get declared annotations do not contain: @distinct

  Scenario: Ordered roles can reset inherited @distinct annotation from a specialised role
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) get role(parent) set annotation: @distinct
    When create relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    When relation(fathership) get role(father) set ordering: ordered
    When relation(fathership) get role(father) set specialise: parent
    Then relation(fathership) get role(father) get declared annotations do not contain: @distinct
    Then relation(fathership) get role(father) get constraints do not contain: @distinct
    Then relation(fathership) get constraints for related role(fathership:father) contain: @distinct
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(fathership) get role(father) set annotation: @distinct
    Then relation(fathership) get role(father) get declared annotations contain: @distinct
    Then relation(fathership) get role(father) get constraints contain: @distinct
    Then relation(fathership) get constraints for related role(fathership:father) contain: @distinct
    Then transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get role(father) get declared annotations contain: @distinct
    Then relation(fathership) get role(father) get constraints contain: @distinct
    Then relation(fathership) get constraints for related role(fathership:father) contain: @distinct

  Scenario: Ordered roles cannot unset inherited @distinct annotation from a specialised role
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) get role(parent) set annotation: @distinct
    When create relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    When relation(fathership) get role(father) set ordering: ordered
    When relation(fathership) get role(father) set specialise: parent
    Then relation(fathership) get role(father) get constraints do not contain: @distinct
    Then relation(fathership) get constraints for related role(fathership:father) contain: @distinct
    Then relation(fathership) get role(father) get declared annotations do not contain: @distinct
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(fathership) get role(father) get constraints do not contain: @distinct
    Then relation(fathership) get constraints for related role(fathership:father) contain: @distinct
    Then relation(fathership) get role(father) get declared annotations do not contain: @distinct
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get role(father) get constraints do not contain: @distinct
    Then relation(fathership) get constraints for related role(fathership:father) contain: @distinct
    Then relation(fathership) get role(father) get declared annotations do not contain: @distinct

########################
# relates @card
########################

  Scenario: Relates have default cardinality without annotation
    When create relation type: parentship
    When relation(parentship) create role: parent
    Then relation(parentship) get role(parent) get declared annotations is empty
    Then relation(parentship) get role(parent) get cardinality: @card(0..1)
    Then relation(parentship) get role(parent) get constraints contain: @card(0..1)
    When relation(parentship) create role: child
    Then relation(parentship) get role(child) get declared annotations is empty
    Then relation(parentship) get role(child) get cardinality: @card(0..1)
    Then relation(parentship) get role(child) get constraints contain: @card(0..1)
    When relation(parentship) get role(child) set ordering: ordered
    Then relation(parentship) get role(child) get declared annotations is empty
    Then relation(parentship) get role(child) get cardinality: @card(0..)
    Then relation(parentship) get role(child) get constraints contain: @card(0..)
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get declared annotations is empty
    Then relation(parentship) get role(parent) get cardinality: @card(0..1)
    Then relation(parentship) get role(parent) get constraints contain: @card(0..1)
    Then relation(parentship) get role(child) get declared annotations is empty
    Then relation(parentship) get role(child) get cardinality: @card(0..)
    Then relation(parentship) get role(child) get constraints contain: @card(0..)

  Scenario Outline: Relation type can set @card annotation on roles and unset it
    When create relation type: parentship
    When relation(parentship) create role: parent
    Then relation(parentship) get role(parent) get cardinality: @card(0..1)
    When relation(parentship) create role: child
    When relation(parentship) get role(child) set ordering: ordered
    Then relation(parentship) get role(child) get cardinality: @card(0..)
    When relation(parentship) get role(parent) set annotation: @card(<arg0>..<arg1>)
    Then relation(parentship) get role(parent) get cardinality: @card(<arg0>..<arg1>)
    Then relation(parentship) get role(parent) get constraints contain: @card(<arg0>..<arg1>)
    Then relation(parentship) get role(parent) get declared annotations contain: @card(<arg0>..<arg1>)
    Then relation(parentship) get role(parent) get constraint categories contain: @card
    When relation(parentship) get role(child) set annotation: @card(<arg0>..<arg1>)
    Then relation(parentship) get role(child) get cardinality: @card(<arg0>..<arg1>)
    Then relation(parentship) get role(child) get constraints contain: @card(<arg0>..<arg1>)
    Then relation(parentship) get role(child) get declared annotations contain: @card(<arg0>..<arg1>)
    Then relation(parentship) get role(child) get constraint categories contain: @card
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get cardinality: @card(<arg0>..<arg1>)
    Then relation(parentship) get role(parent) get constraints contain: @card(<arg0>..<arg1>)
    Then relation(parentship) get role(parent) get declared annotations contain: @card(<arg0>..<arg1>)
    Then relation(parentship) get role(parent) get constraint categories contain: @card
    Then relation(parentship) get role(child) get cardinality: @card(<arg0>..<arg1>)
    Then relation(parentship) get role(child) get constraints contain: @card(<arg0>..<arg1>)
    Then relation(parentship) get role(child) get declared annotations contain: @card(<arg0>..<arg1>)
    Then relation(parentship) get role(child) get constraint categories contain: @card
    When relation(parentship) get role(parent) unset annotation: @card
    Then relation(parentship) get role(parent) get declared annotations is empty
    Then relation(parentship) get role(parent) get constraints contain: @card(0..1)
    Then relation(parentship) get constraints for related role(parentship:parent) contain: @card(0..1)
    Then relation(parentship) get role(parent) get cardinality: @card(0..1)
    When relation(parentship) get role(child) unset annotation: @card
    Then relation(parentship) get role(child) get declared annotations is empty
    Then relation(parentship) get role(child) get constraints do not contain: @card(0..1)
    Then relation(parentship) get role(child) get constraints contain: @card(0..)
    Then relation(parentship) get constraints for related role(parentship:child) contain: @card(0..)
    Then relation(parentship) get role(child) get cardinality: @card(0..)
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get declared annotations is empty
    Then relation(parentship) get role(parent) get constraints do not contain: @card(0..)
    Then relation(parentship) get role(parent) get constraints contain: @card(0..1)
    Then relation(parentship) get constraints for related role(parentship:parent) contain: @card(0..1)
    Then relation(parentship) get constraints for related role(parentship:parent) do not contain: @card(0..)
    Then relation(parentship) get role(parent) get cardinality: @card(0..1)
    Then relation(parentship) get role(child) get declared annotations is empty
    Then relation(parentship) get role(child) get constraints do not contain: @card(0..1)
    Then relation(parentship) get role(child) get constraints contain: @card(0..)
    Then relation(parentship) get constraints for related role(parentship:child) do not contain: @card(0..1)
    Then relation(parentship) get constraints for related role(parentship:child) contain: @card(0..)
    Then relation(parentship) get role(child) get cardinality: @card(0..)
    Examples:
      | arg0 | arg1                |
      | 0    | 1                   |
      | 0    | 10                  |
      | 0    | 9223372036854775807 |
      | 1    | 10                  |
      | 0    |                     |
      | 1    |                     |

  Scenario Outline: Relation type can set @card annotation on roles with duplicate args (exactly N ownerships)
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) create role: child
    When relation(parentship) get role(child) set ordering: ordered
    When relation(parentship) get role(parent) set annotation: @card(<arg>..<arg>)
    Then relation(parentship) get role(parent) get constraints contain: @card(<arg>..<arg>)
    Then relation(parentship) get role(parent) get declared annotations contain: @card(<arg>..<arg>)
    When relation(parentship) get role(child) set annotation: @card(<arg>..<arg>)
    Then relation(parentship) get role(child) get constraints contain: @card(<arg>..<arg>)
    Then relation(parentship) get role(child) get declared annotations contain: @card(<arg>..<arg>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @card(<arg>..<arg>)
    Then relation(parentship) get role(parent) get declared annotations contain: @card(<arg>..<arg>)
    Then relation(parentship) get role(child) get constraints contain: @card(<arg>..<arg>)
    Then relation(parentship) get role(child) get declared annotations contain: @card(<arg>..<arg>)
    Examples:
      | arg  |
      | 1    |
      | 9999 |

  Scenario: Relation type cannot have @card annotation for with invalid arguments
    When create relation type: parentship
    When relation(parentship) create role: parent
    Then relation(parentship) get role(parent) set annotation: @card(2..1); fails
    Then relation(parentship) get role(parent) set annotation: @card(0..0); fails
    Then relation(parentship) get role(parent) get constraints do not contain: @card(2..1)
    Then relation(parentship) get role(parent) get constraints do not contain: @card(0..0)
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints do not contain: @card(2..1)
    Then relation(parentship) get role(parent) get constraints do not contain: @card(0..0)

  Scenario Outline: Relation type can reset @card annotations
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set annotation: @card(<init-args>)
    Then relation(parentship) get role(parent) get constraints contain: @card(<init-args>)
    Then relation(parentship) get role(parent) get constraints do not contain: @card(<reset-args>)
    When relation(parentship) get role(parent) set annotation: @card(<init-args>)
    Then relation(parentship) get role(parent) get constraints contain: @card(<init-args>)
    Then relation(parentship) get role(parent) get constraints do not contain: @card(<reset-args>)
    When relation(parentship) get role(parent) set annotation: @card(<reset-args>)
    Then relation(parentship) get role(parent) get constraints contain: @card(<reset-args>)
    Then relation(parentship) get role(parent) get constraints do not contain: @card(<init-args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @card(<reset-args>)
    Then relation(parentship) get role(parent) get constraints do not contain: @card(<init-args>)
    When relation(parentship) get role(parent) set annotation: @card(<init-args>)
    Then relation(parentship) get role(parent) get constraints contain: @card(<init-args>)
    Then relation(parentship) get role(parent) get constraints do not contain: @card(<reset-args>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints do not contain: @card(<reset-args>)
    Examples:
      | init-args | reset-args |
      | 0..       | 1..1       |
      | 0..5      | 1..1       |
      | 2..5      | 1..1       |
      | 2..5      | 0..2       |
      | 2..5      | 0..3       |
      | 2..5      | 0..5       |
      | 2..5      | 0..        |
      | 2..5      | 2..3       |
      | 2..5      | 2..        |
      | 2..5      | 3..4       |
      | 2..5      | 3..5       |
      | 2..5      | 3..        |
      | 2..5      | 5..        |
      | 2..5      | 6..        |

  Scenario: Relation type's inherited role can unset @card annotation
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set annotation: @card(0..1)
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    Then relation(parentship) get role(parent) get constraints contain: @card(0..1)
    Then relation(parentship) get role(parent) get declared annotations contain: @card(0..1)
    When relation(parentship) get role(parent) unset annotation: @card
    Then relation(parentship) get role(parent) get declared annotation categories do not contain: @card
    Then relation(parentship) get role(parent) get declared annotation categories do not contain: @card
    Then relation(parentship) get role(parent) get declared annotations do not contain: @card(0..1)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get declared annotation categories do not contain: @card
    Then relation(parentship) get role(parent) get declared annotation categories do not contain: @card
    Then relation(parentship) get role(parent) get declared annotations do not contain: @card(0..1)
    When relation(parentship) get role(parent) set annotation: @card(0..1)
    Then relation(parentship) get role(parent) get constraint categories contain: @card
    Then relation(parentship) get role(parent) get constraint categories contain: @card
    Then relation(parentship) get role(parent) get constraints contain: @card(0..1)
    Then relation(parentship) get role(parent) get declared annotations contain: @card(0..1)
    Then relation(parentship) get role(parent) get constraints contain: @card(0..1)
    Then relation(parentship) get role(parent) get declared annotations contain: @card(0..1)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get constraint categories contain: @card
    Then relation(parentship) get role(parent) get constraint categories contain: @card
    Then relation(parentship) get role(parent) get constraints contain: @card(0..1)
    Then relation(parentship) get role(parent) get declared annotations contain: @card(0..1)
    Then relation(parentship) get role(parent) get constraints contain: @card(0..1)
    Then relation(parentship) get role(parent) get declared annotations contain: @card(0..1)
    When relation(parentship) get role(parent) unset annotation: @card
    Then relation(parentship) get role(parent) get declared annotation categories do not contain: @card
    Then relation(parentship) get role(parent) get declared annotation categories do not contain: @card
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get declared annotation categories do not contain: @card
    Then relation(parentship) get role(parent) get declared annotation categories do not contain: @card

  Scenario: Role cannot unset inherited @card annotation from a specialised role
    When create relation type: parentship
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set annotation: @card(1..1)
    When create relation type: fathership
    When relation(fathership) create role: father
    When relation(fathership) set supertype: parentship
    Then relation(fathership) get role(father) set specialise: parent
    Then relation(fathership) get role(father) get declared annotations do not contain: @card(1..1)
    Then relation(fathership) get role(father) get constraints do not contain: @card(1..1)
    Then relation(fathership) get constraints for related role(fathership:father) contain: @card(1..1)
    When relation(fathership) get role(father) unset annotation: @card
    Then relation(fathership) get constraints for related role(fathership:father) contain: @card(1..1)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(fathership) get role(father) get declared annotations do not contain: @card(1..1)
    Then relation(fathership) get role(father) get constraints do not contain: @card(1..1)
    Then relation(fathership) get constraints for related role(fathership:father) contain: @card(1..1)
    When relation(fathership) get role(father) unset annotation: @card
    Then relation(fathership) get constraints for related role(fathership:father) contain: @card(1..1)
    When relation(fathership) get role(father) unset specialise
    Then relation(fathership) get role(father) get declared annotations do not contain: @card(1..1)
    Then relation(fathership) get role(father) get constraints do not contain: @card(1..1)
    Then relation(fathership) get constraints for related role(fathership:father) do not contain: @card(1..1)
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(fathership) get role(father) get declared annotations do not contain: @card(1..1)
    Then relation(fathership) get role(father) get constraints do not contain: @card(1..1)
    Then relation(fathership) get constraints for related role(fathership:father) do not contain: @card(1..1)

  Scenario Outline: Role's @card annotation can be inherited and specialised by a subset of arguments
    When create relation type: parentship
    When relation(parentship) create role: custom-role
    When relation(parentship) create role: second-custom-role
    When relation(parentship) get role(custom-role) set annotation: @card(<args>)
    Then relation(parentship) get role(custom-role) get constraints contain: @card(<args>)
    When relation(parentship) get role(second-custom-role) set annotation: @card(<args>)
    Then relation(parentship) get role(second-custom-role) get constraints contain: @card(<args>)
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: specialised-custom-role
    When relation(fathership) get role(specialised-custom-role) set specialise: second-custom-role
    Then relation(fathership) get relates contain:
      | parentship:custom-role             |
      | parentship:second-custom-role      |
      | fathership:specialised-custom-role |
    Then relation(fathership) get relates(custom-role) is specialising: false
    Then relation(fathership) get relates(second-custom-role) is specialising: true
    Then relation(fathership) get relates(specialised-custom-role) is specialising: false
    Then relation(parentship) get relates(custom-role) is specialising: false
    Then relation(parentship) get relates(second-custom-role) is specialising: false
    Then relation(parentship) get role(custom-role) get constraints contain: @card(<args>)
    Then relation(fathership) get role(specialised-custom-role) get constraints do not contain: @card(<args>)
    Then relation(fathership) get role(specialised-custom-role) get declared annotations do not contain: @card(<args>)
    Then relation(fathership) get constraints for related role(fathership:specialised-custom-role) contain: @card(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(custom-role) get constraints contain: @card(<args>)
    Then relation(fathership) get role(specialised-custom-role) get constraints do not contain: @card(<args>)
    Then relation(fathership) get role(specialised-custom-role) get declared annotations do not contain: @card(<args>)
    Then relation(fathership) get constraints for related role(fathership:specialised-custom-role) contain: @card(<args>)
    When relation(parentship) get role(custom-role) set annotation: @card(<args-specialise>)
    Then relation(parentship) get role(custom-role) get constraints contain: @card(<args-specialise>)
    Then relation(parentship) get role(custom-role) get declared annotations contain: @card(<args-specialise>)
    Then relation(parentship) get role(custom-role) get declared annotations do not contain: @card(<args>)
    When relation(fathership) get role(specialised-custom-role) set annotation: @card(<args-specialise>)
    Then relation(fathership) get role(specialised-custom-role) get constraints contain: @card(<args-specialise>)
    Then relation(fathership) get role(specialised-custom-role) get declared annotations contain: @card(<args-specialise>)
    Then relation(fathership) get role(specialised-custom-role) get declared annotations do not contain: @card(<args>)
    Then relation(fathership) get role(specialised-custom-role) get constraints do not contain: @card(<args>)
    Then relation(fathership) get constraints for related role(fathership:specialised-custom-role) contain: @card(<args>)
    Then relation(fathership) get constraints for related role(fathership:specialised-custom-role) contain: @card(<args-specialise>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(custom-role) get constraints contain: @card(<args-specialise>)
    Then relation(parentship) get role(custom-role) get declared annotations contain: @card(<args-specialise>)
    Then relation(parentship) get role(custom-role) get declared annotations do not contain: @card(<args>)
    Then relation(fathership) get role(specialised-custom-role) get constraints contain: @card(<args-specialise>)
    Then relation(fathership) get role(specialised-custom-role) get declared annotations contain: @card(<args-specialise>)
    Then relation(fathership) get role(specialised-custom-role) get declared annotations do not contain: @card(<args>)
    Then relation(fathership) get constraints for related role(fathership:specialised-custom-role) contain: @card(<args>)
    Then relation(fathership) get constraints for related role(fathership:specialised-custom-role) contain: @card(<args-specialise>)
    Examples:
      | args       | args-specialise |
      | 0..        | 0..10000        |
      | 0..10      | 0..2            |
      | 0..2       | 1..2            |
      | 1..        | 1..1            |
      | 1..5       | 3..4            |
      | 38..111    | 39..111         |
      | 1000..1100 | 1000..1099      |

  # TODO: This may change if we reintroduce narrowing checks for card
  Scenario Outline: Role's @card annotation can be inherited and specialised by NOT a subset of arguments
    When create relation type: parentship
    When relation(parentship) create role: custom-role
    When relation(parentship) create role: second-custom-role
    When relation(parentship) get role(custom-role) set annotation: @card(<args>)
    Then relation(parentship) get role(custom-role) get constraints contain: @card(<args>)
    When relation(parentship) get role(second-custom-role) set annotation: @card(<args>)
    Then relation(parentship) get role(second-custom-role) get constraints contain: @card(<args>)
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: specialised-custom-role
    When relation(fathership) get role(specialised-custom-role) set specialise: second-custom-role
    Then relation(fathership) get relates contain:
      | parentship:custom-role             |
      | fathership:specialised-custom-role |
    Then relation(fathership) get relates do not contain:
      | second-custom-role |
    Then relation(parentship) get role(custom-role) get constraints contain: @card(<args>)
    Then relation(fathership) get role(specialised-custom-role) get constraints do not contain: @card(<args>)
    Then relation(fathership) get constraints for related role(fathership:specialised-custom-role) contain: @card(<args>)
    Then relation(fathership) get role(specialised-custom-role) get declared annotations do not contain: @card(<args>)
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(custom-role) get constraints contain: @card(<args>)
    Then relation(parentship) get constraints for related role(parentship:custom-role) contain: @card(<args>)
    Then relation(fathership) get role(specialised-custom-role) get constraints do not contain: @card(<args>)
    Then relation(fathership) get constraints for related role(fathership:specialised-custom-role) contain: @card(<args>)
    Then relation(fathership) get role(specialised-custom-role) get declared annotations do not contain: @card(<args>)
    When relation(parentship) get role(custom-role) set annotation: @card(<args-specialise>)
    Then relation(parentship) get role(custom-role) get constraints contain: @card(<args-specialise>)
    Then relation(parentship) get role(custom-role) get declared annotations contain: @card(<args-specialise>)
    Then relation(parentship) get role(custom-role) get declared annotations do not contain: @card(<args>)
    When relation(fathership) get role(specialised-custom-role) set annotation: @card(<args-specialise>)
    Then relation(fathership) get role(specialised-custom-role) get constraints contain: @card(<args-specialise>)
    Then relation(fathership) get role(specialised-custom-role) get constraints do not contain: @card(<args>)
    Then relation(fathership) get constraints for related role(fathership:specialised-custom-role) contain: @card(<args>)
    Then relation(fathership) get constraints for related role(fathership:specialised-custom-role) contain: @card(<args-specialise>)
    Then relation(fathership) get role(specialised-custom-role) get declared annotations contain: @card(<args-specialise>)
    Then relation(fathership) get role(specialised-custom-role) get declared annotations do not contain: @card(<args>)
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(custom-role) get constraints contain: @card(<args-specialise>)
    Then relation(parentship) get role(custom-role) get declared annotations contain: @card(<args-specialise>)
    Then relation(parentship) get role(custom-role) get declared annotations do not contain: @card(<args>)
    Then relation(parentship) get constraints for related role(parentship:custom-role) contain: @card(<args-specialise>)
    Then relation(parentship) get constraints for related role(parentship:custom-role) do not contain: @card(<args>)
    Then relation(fathership) get role(specialised-custom-role) get constraints contain: @card(<args-specialise>)
    Then relation(fathership) get role(specialised-custom-role) get declared annotations contain: @card(<args-specialise>)
    Then relation(fathership) get role(specialised-custom-role) get declared annotations do not contain: @card(<args>)
    Then relation(fathership) get constraints for related role(fathership:specialised-custom-role) contain: @card(<args>)
    Then relation(fathership) get constraints for related role(fathership:specialised-custom-role) contain: @card(<args-specialise>)
    Examples:
      | args  | args-specialise |
      | 0..3  | 0..             |
      | 0..10 | 0..15           |
      | 0..2  | 1..             |

    # TODO: We (temporarily) don't revalidate cardinality narrowing in schema!
#  Scenario Outline: Inherited @card annotation of roles cannot be reset or specialised by the @card of not a subset of arguments
#    When create relation type: parentship
#    When relation(parentship) create role: custom-role
#    When relation(parentship) create role: second-custom-role
#    When relation(parentship) get role(custom-role) set annotation: @card(<args>)
#    Then relation(parentship) get role(custom-role) get constraints contain: @card(<args>)
#    When relation(parentship) get role(second-custom-role) set annotation: @card(<args>)
#    Then relation(parentship) get role(second-custom-role) get constraints contain: @card(<args>)
#    When create relation type: fathership
#    When relation(fathership) set supertype: parentship
#    When relation(fathership) create role: specialised-custom-role
#    When relation(fathership) get role(specialised-custom-role) set specialise: second-custom-role
#    Then relation(fathership) get role(custom-role) get constraints contain: @card(<args>)
#    Then relation(fathership) get role(specialised-custom-role) get constraints contain: @card(<args>)
#    When relation(fathership) get role(custom-role) set annotation: @card(<args-specialise>)
#    Then relation(fathership) get role(specialised-custom-role) set annotation: @card(<args-specialise>); fails
#    Then relation(fathership) get role(custom-role) get constraints contain: @card(<args-specialise>)
#    Then relation(parentship) get role(custom-role) get constraints contain: @card(<args-specialise>)
#    Then relation(parentship) get role(second-custom-role) get constraints contain: @card(<args>)
#    Then relation(fathership) get role(specialised-custom-role) get constraints contain: @card(<args>)
#    Then relation(fathership) get role(specialised-custom-role) get declared annotations do not contain: @card(<args>)
#    Then relation(fathership) get role(specialised-custom-role) get declared annotations do not contain: @card(<args-specialise>)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(fathership) get role(custom-role) get constraints contain: @card(<args-specialise>)
#    Then relation(parentship) get role(custom-role) get constraints contain: @card(<args-specialise>)
#    Then relation(parentship) get role(second-custom-role) get constraints contain: @card(<args>)
#    Then relation(fathership) get role(specialised-custom-role) get constraints contain: @card(<args>)
#    Then relation(fathership) get role(specialised-custom-role) get declared annotations do not contain: @card(<args>)
#    Then relation(fathership) get role(specialised-custom-role) get declared annotations do not contain: @card(<args-specialise>)
#    When relation(fathership) get role(specialised-custom-role) set annotation: @card(<args>)
#    Then transaction commits; fails
#    Examples:
#      | args       | args-specialise |
#      | 0..10000   | 0..10001      |
#      | 0..10      | 1..11         |
#      | 1..        | 0..2          |
#      | 1..5       | 6..10         |
#      | 2..2       | 1..1          |
#      | 38..111    | 37..111       |
#      | 1000..1100 | 1000..1199    |

    # TODO: We (temporarily) don't revalidate cardinality narrowing in schema!
#  Scenario: Cardinality can be narrowed for different roles
#    When create relation type: parentship
#    When relation(parentship) create role: parent
#    When relation(parentship) get role(parent) set annotation: @card(0..)
#    When create relation type: single-parentship
#    When relation(single-parentship) set supertype: parentship
#    When create relation type: divorced-parentship
#    When relation(divorced-parentship) set supertype: single-parentship
#    When relation(single-parentship) create role: single-parent
#    When relation(single-parentship) get role(single-parent) set specialise: parent
#    When relation(divorced-parentship) create role: divorced-parent
#    When relation(divorced-parentship) get role(divorced-parent) set specialise: single-parent
#    Then relation(parentship) get role(parent) get constraints contain: @card(0..)
#    Then relation(single-parentship) get role(single-parent) get constraints contain: @card(0..)
#    Then relation(divorced-parentship) get role(divorced-parent) get constraints contain: @card(0..)
#    Then relation(parentship) get role(parent) get declared annotations contain: @card(0..)
#    Then relation(single-parentship) get role(single-parent) get declared annotations do not contain: @card(0..)
#    Then relation(divorced-parentship) get role(divorced-parent) get declared annotations do not contain: @card(0..)
#    When relation(single-parentship) get role(single-parent) set annotation: @card(3..)
#    Then relation(parentship) get role(parent) get constraints contain: @card(0..)
#    Then relation(single-parentship) get role(single-parent) get constraints do not contain: @card(0..)
#    Then relation(divorced-parentship) get role(divorced-parent) get constraints do not contain: @card(0..)
#    Then relation(parentship) get role(parent) get declared annotations contain: @card(0..)
#    Then relation(single-parentship) get role(single-parent) get declared annotations do not contain: @card(0..)
#    Then relation(divorced-parentship) get role(divorced-parent) get declared annotations do not contain: @card(0..)
#    Then relation(parentship) get role(parent) get constraints do not contain: @card(3..)
#    Then relation(single-parentship) get role(single-parent) get constraints contain: @card(3..)
#    Then relation(divorced-parentship) get role(divorced-parent) get constraints contain: @card(3..)
#    Then relation(parentship) get role(parent) get declared annotations do not contain: @card(3..)
#    Then relation(single-parentship) get role(single-parent) get declared annotations contain: @card(3..)
#    Then relation(divorced-parentship) get role(divorced-parent) get declared annotations do not contain: @card(3..)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(parentship) get role(parent) get constraints contain: @card(0..)
#    Then relation(single-parentship) get role(single-parent) get constraints do not contain: @card(0..)
#    Then relation(divorced-parentship) get role(divorced-parent) get constraints do not contain: @card(0..)
#    Then relation(parentship) get role(parent) get declared annotations contain: @card(0..)
#    Then relation(single-parentship) get role(single-parent) get declared annotations do not contain: @card(0..)
#    Then relation(divorced-parentship) get role(divorced-parent) get declared annotations do not contain: @card(0..)
#    Then relation(parentship) get role(parent) get constraints do not contain: @card(3..)
#    Then relation(single-parentship) get role(single-parent) get constraints contain: @card(3..)
#    Then relation(divorced-parentship) get role(divorced-parent) get constraints contain: @card(3..)
#    Then relation(parentship) get role(parent) get declared annotations do not contain: @card(3..)
#    Then relation(single-parentship) get role(single-parent) get declared annotations contain: @card(3..)
#    Then relation(divorced-parentship) get role(divorced-parent) get declared annotations do not contain: @card(3..)
#    Then relation(divorced-parentship) get role(divorced-parent) set annotation: @card(2..); fails
#    Then relation(divorced-parentship) get role(divorced-parent) set annotation: @card(1..); fails
#    Then relation(divorced-parentship) get role(divorced-parent) set annotation: @card(0..); fails
#    Then relation(divorced-parentship) get role(divorced-parent) set annotation: @card(0..6); fails
#    Then relation(divorced-parentship) get role(divorced-parent) set annotation: @card(0..2); fails
#    When relation(divorced-parentship) get role(divorced-parent) set annotation: @card(3..6)
#    Then relation(parentship) get role(parent) get constraints contain: @card(0..)
#    Then relation(single-parentship) get role(single-parent) get constraints do not contain: @card(0..)
#    Then relation(divorced-parentship) get role(divorced-parent) get constraints do not contain: @card(0..)
#    Then relation(parentship) get role(parent) get declared annotations contain: @card(0..)
#    Then relation(single-parentship) get role(single-parent) get declared annotations do not contain: @card(0..)
#    Then relation(divorced-parentship) get role(divorced-parent) get declared annotations do not contain: @card(0..)
#    Then relation(parentship) get role(parent) get constraints do not contain: @card(3..)
#    Then relation(single-parentship) get role(single-parent) get constraints contain: @card(3..)
#    Then relation(divorced-parentship) get role(divorced-parent) get constraints do not contain: @card(3..)
#    Then relation(parentship) get role(parent) get declared annotations do not contain: @card(3..)
#    Then relation(single-parentship) get role(single-parent) get declared annotations contain: @card(3..)
#    Then relation(divorced-parentship) get role(divorced-parent) get declared annotations do not contain: @card(3..)
#    Then relation(parentship) get role(parent) get constraints do not contain: @card(3..6)
#    Then relation(single-parentship) get role(single-parent) get constraints do not contain: @card(3..6)
#    Then relation(divorced-parentship) get role(divorced-parent) get constraints contain: @card(3..6)
#    Then relation(parentship) get role(parent) get declared annotations do not contain: @card(3..6)
#    Then relation(single-parentship) get role(single-parent) get declared annotations do not contain: @card(3..6)
#    Then relation(divorced-parentship) get role(divorced-parent) get declared annotations contain: @card(3..6)
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then relation(parentship) get role(parent) get constraints contain: @card(0..)
#    Then relation(single-parentship) get role(single-parent) get constraints do not contain: @card(0..)
#    Then relation(divorced-parentship) get role(divorced-parent) get constraints do not contain: @card(0..)
#    Then relation(parentship) get role(parent) get declared annotations contain: @card(0..)
#    Then relation(single-parentship) get role(single-parent) get declared annotations do not contain: @card(0..)
#    Then relation(divorced-parentship) get role(divorced-parent) get declared annotations do not contain: @card(0..)
#    Then relation(parentship) get role(parent) get constraints do not contain: @card(3..)
#    Then relation(single-parentship) get role(single-parent) get constraints contain: @card(3..)
#    Then relation(divorced-parentship) get role(divorced-parent) get constraints do not contain: @card(3..)
#    Then relation(parentship) get role(parent) get declared annotations do not contain: @card(3..)
#    Then relation(single-parentship) get role(single-parent) get declared annotations contain: @card(3..)
#    Then relation(divorced-parentship) get role(divorced-parent) get declared annotations do not contain: @card(3..)
#    Then relation(parentship) get role(parent) get constraints do not contain: @card(3..6)
#    Then relation(single-parentship) get role(single-parent) get constraints do not contain: @card(3..6)
#    Then relation(divorced-parentship) get role(divorced-parent) get constraints contain: @card(3..6)
#    Then relation(parentship) get role(parent) get declared annotations do not contain: @card(3..6)
#    Then relation(single-parentship) get role(single-parent) get declared annotations do not contain: @card(3..6)
#    Then relation(divorced-parentship) get role(divorced-parent) get declared annotations contain: @card(3..6)

    # TODO: We (temporarily) don't revalidate cardinality narrowing in schema!
#  Scenario: Default @card annotation for <value-type> value type owns can be specialised only by a subset of arguments
#    When create relation type: parentship
#    When relation(parentship) create role: parent
#    When relation(parentship) get role(parent) get ordering: unordered
#    When relation(parentship) create role: ordered-parent
#    When relation(parentship) get role(ordered-parent) set ordering: ordered
#    When relation(parentship) get role(ordered-parent) get ordering: ordered
#    When create relation type: specialised-parentship
#    When relation(specialised-parentship) set supertype: parentship
#    When relation(specialised-parentship) create role: specialised-parent
#    When relation(specialised-parentship) create role: specialised-ordered-parent
#    When relation(specialised-parentship) get role(specialised-parent) set specialise: parent
#    Then relation(specialised-parentship) get role(specialised-ordered-parent) set specialise: ordered-parent; fails
#    When relation(specialised-parentship) get role(specialised-ordered-parent) set ordering: ordered
#    When relation(specialised-parentship) get role(specialised-ordered-parent) set specialise: ordered-parent
#    Then relation(parentship) get role(parent) get cardinality: @card(1..1)
#    Then relation(parentship) get role(ordered-parent) get cardinality: @card(0..)
#    When relation(specialised-parentship) get role(specialised-parent) set annotation: @card(1..1)
#    When relation(specialised-parentship) get role(specialised-ordered-parent) set annotation: @card(1..1)
#    Then relation(specialised-parentship) get role(specialised-parent) get cardinality: @card(1..1)
#    Then relation(specialised-parentship) get role(specialised-ordered-parent) get cardinality: @card(1..1)
#    Then relation(parentship) get role(parent) get cardinality: @card(1..1)
#    Then relation(parentship) get role(ordered-parent) get cardinality: @card(0..)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(specialised-parentship) get role(specialised-parent) get cardinality: @card(1..1)
#    Then relation(specialised-parentship) get role(specialised-ordered-parent) get cardinality: @card(1..1)
#    Then relation(parentship) get role(parent) get cardinality: @card(1..1)
#    Then relation(parentship) get role(ordered-parent) get cardinality: @card(0..)
#    Then relation(specialised-parentship) get role(specialised-parent) set annotation: @card(0..1); fails
#    When relation(specialised-parentship) get role(specialised-ordered-parent) set annotation: @card(0..1)
#    Then relation(specialised-parentship) get role(specialised-parent) get cardinality: @card(1..1)
#    Then relation(specialised-parentship) get role(specialised-ordered-parent) get cardinality: @card(0..1)
#    Then relation(parentship) get role(parent) get cardinality: @card(1..1)
#    Then relation(parentship) get role(ordered-parent) get cardinality: @card(0..)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(specialised-parentship) get role(specialised-parent) get cardinality: @card(1..1)
#    Then relation(specialised-parentship) get role(specialised-ordered-parent) get cardinality: @card(0..1)
#    Then relation(parentship) get role(parent) get cardinality: @card(1..1)
#    Then relation(parentship) get role(ordered-parent) get cardinality: @card(0..)
#    Then relation(specialised-parentship) get role(specialised-parent) set annotation: @card(0..); fails
#    When relation(specialised-parentship) get role(specialised-ordered-parent) set annotation: @card(0..)
#    Then relation(specialised-parentship) get role(specialised-parent) get cardinality: @card(1..1)
#    Then relation(specialised-parentship) get role(specialised-ordered-parent) get cardinality: @card(0..)
#    Then relation(parentship) get role(parent) get cardinality: @card(1..1)
#    Then relation(parentship) get role(ordered-parent) get cardinality: @card(0..)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(specialised-parentship) get role(specialised-parent) get cardinality: @card(1..1)
#    Then relation(specialised-parentship) get role(specialised-ordered-parent) get cardinality: @card(0..)
#    Then relation(parentship) get role(parent) get cardinality: @card(1..1)
#    Then relation(parentship) get role(ordered-parent) get cardinality: @card(0..)
#    When relation(specialised-parentship) get role(specialised-parent) unset annotation: @card
#    When relation(specialised-parentship) get role(specialised-ordered-parent) unset annotation: @card
#    Then relation(specialised-parentship) get role(specialised-parent) get cardinality: @card(1..1)
#    Then relation(specialised-parentship) get role(specialised-ordered-parent) get cardinality: @card(0..)
#    Then relation(parentship) get role(parent) get cardinality: @card(1..1)
#    Then relation(parentship) get role(ordered-parent) get cardinality: @card(0..)
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then relation(specialised-parentship) get role(specialised-parent) get cardinality: @card(1..1)
#    Then relation(specialised-parentship) get role(specialised-ordered-parent) get cardinality: @card(0..)
#    Then relation(parentship) get role(parent) get cardinality: @card(1..1)
#    Then relation(parentship) get role(ordered-parent) get cardinality: @card(0..)

    # TODO: We (temporarily) don't revalidate cardinality narrowing in schema!
#  Scenario: Relates cannot have card that is not narrowed by other relates narrowing it for different subrelations
#    When create relation type: parentship
#    When relation(parentship) create role: parent
#    Then relation(parentship) get role(parent) get cardinality: @card(1..1)
#    When create relation type: specialised-parentship
#    When relation(specialised-parentship) create role: specialised-parent
#    When relation(specialised-parentship) set supertype: parentship
#    When relation(specialised-parentship) get role(specialised-parent) set specialise: parent
#    Then relation(specialised-parentship) get role(specialised-parent) get cardinality: @card(1..1)
#    When create relation type: specialised-parentship-2
#    When relation(specialised-parentship-2) create role: specialised-parent-2
#    When relation(specialised-parentship-2) set supertype: parentship
#    When relation(specialised-parentship-2) get role(specialised-parent-2) set specialise: parent
#    Then relation(specialised-parentship-2) get role(specialised-parent-2) get cardinality: @card(1..1)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(parentship) get role(parent) get cardinality: @card(1..1)
#    Then relation(specialised-parentship) get role(specialised-parent) get cardinality: @card(1..1)
#    Then relation(specialised-parentship-2) get role(specialised-parent-2) get cardinality: @card(1..1)
#    Then relation(specialised-parentship) get role(specialised-parent) set annotation: @card(1..2); fails
#    Then relation(specialised-parentship-2) get role(specialised-parent-2) set annotation: @card(1..2); fails
#    Then relation(specialised-parentship) get role(specialised-parent) set annotation: @card(0..1); fails
#    Then relation(specialised-parentship-2) get role(specialised-parent-2) set annotation: @card(0..1); fails
#    When relation(parentship) get role(parent) set annotation: @card(0..2)
#    When relation(specialised-parentship) get role(specialised-parent) set annotation: @card(0..1)
#    When relation(specialised-parentship-2) get role(specialised-parent-2) set annotation: @card(1..2)
#    Then relation(parentship) get role(parent) get cardinality: @card(0..2)
#    Then relation(specialised-parentship) get role(specialised-parent) get cardinality: @card(0..1)
#    Then relation(specialised-parentship-2) get role(specialised-parent-2) get cardinality: @card(1..2)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(parentship) get role(parent) get cardinality: @card(0..2)
#    Then relation(specialised-parentship) get role(specialised-parent) get cardinality: @card(0..1)
#    Then relation(specialised-parentship-2) get role(specialised-parent-2) get cardinality: @card(1..2)
#    When relation(specialised-parentship) get role(specialised-parent) set annotation: @card(1..2)
#    Then relation(specialised-parentship) get role(specialised-parent) get cardinality: @card(1..2)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(parentship) get role(parent) get cardinality: @card(0..2)
#    Then relation(specialised-parentship) get role(specialised-parent) get cardinality: @card(1..2)
#    Then relation(specialised-parentship-2) get role(specialised-parent-2) get cardinality: @card(1..2)
#    When relation(specialised-parentship-2) get role(specialised-parent-2) set annotation: @card(2..2)
#    Then relation(specialised-parentship-2) get role(specialised-parent-2) get cardinality: @card(2..2)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(parentship) get role(parent) get cardinality: @card(0..2)
#    Then relation(specialised-parentship) get role(specialised-parent) get cardinality: @card(1..2)
#    Then relation(specialised-parentship-2) get role(specialised-parent-2) get cardinality: @card(2..2)
#    Then relation(parentship) get role(parent) set annotation: @card(0..1); fails
#    Then relation(parentship) get role(parent) set annotation: @card(2..2); fails
#    When relation(parentship) get role(parent) set annotation: @card(0..)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(parentship) get role(parent) get cardinality: @card(0..)
#    Then relation(specialised-parentship) get role(specialised-parent) get cardinality: @card(1..2)
#    Then relation(specialised-parentship-2) get role(specialised-parent-2) get cardinality: @card(2..2)
#    When relation(specialised-parentship-2) get role(specialised-parent-2) set annotation: @card(4..5)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(parentship) get role(parent) get cardinality: @card(0..)
#    Then relation(specialised-parentship) get role(specialised-parent) get cardinality: @card(1..2)
#    Then relation(specialised-parentship-2) get role(specialised-parent-2) get cardinality: @card(4..5)
#    Then relation(parentship) get role(parent) set annotation: @card(0..4); fails
#    Then relation(parentship) get role(parent) set annotation: @card(3..3); fails
#    Then relation(parentship) get role(parent) set annotation: @card(2..5); fails
#    Then relation(parentship) get role(parent) unset annotation: @card; fails
#    When transaction closes
#    When connection open schema transaction for database: typedb
#    When relation(parentship) get role(parent) set annotation: @card(1..5)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(parentship) get role(parent) get cardinality: @card(1..5)
#    Then relation(specialised-parentship) get role(specialised-parent) get cardinality: @card(1..2)
#    Then relation(specialised-parentship-2) get role(specialised-parent-2) get cardinality: @card(4..5)
#    When relation(specialised-parentship) get role(specialised-parent) set annotation: @card(1..1)
#    When relation(specialised-parentship-2) get role(specialised-parent-2) set annotation: @card(1..1)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(parentship) get role(parent) get cardinality: @card(1..5)
#    Then relation(specialised-parentship) get role(specialised-parent) get cardinality: @card(1..1)
#    Then relation(specialised-parentship-2) get role(specialised-parent-2) get cardinality: @card(1..1)
#    When relation(parentship) get role(parent) unset annotation: @card
#    When transaction commits
#    When connection open read transaction for database: typedb
#    Then relation(parentship) get role(parent) get cardinality: @card(1..1)
#    Then relation(specialised-parentship) get role(specialised-parent) get cardinality: @card(1..1)
#    Then relation(specialised-parentship-2) get role(specialised-parent-2) get cardinality: @card(1..1)
#    Then relation(parentship) get role(parent) get constraints do not contain: @card(1..1)
#    Then relation(specialised-parentship) get role(specialised-parent) get constraints contain: @card(1..1)
#    Then relation(specialised-parentship-2) get role(specialised-parent-2) get constraints contain: @card(1..1)

    # TODO: We (temporarily) don't revalidate cardinality narrowing in schema!
#  Scenario: Relates can have multiple specialising relates with narrowing cardinalities and correct min sum
#    When create relation type: relation-to-disturb
#    When relation(relation-to-disturb) create role: disturber
#    When relation(relation-to-disturb) get role(disturber) set annotation: @card(1..1)
#    When create relation type: subtype-to-disturb
#    When relation(subtype-to-disturb) create role: subdisturber
#    When relation(subtype-to-disturb) set supertype: relation-to-disturb
#    When relation(subtype-to-disturb) get role(subdisturber) set specialise: disturber
#    Then relation(subtype-to-disturb) get role(subdisturber) get cardinality: @card(1..1)
#    When create relation type: connection
#    When relation(connection) create role: player
#    When relation(connection) get role(player) set annotation: @card(1..2)
#    Then relation(connection) get role(player) get cardinality: @card(1..2)
#    When create relation type: parentship
#    When relation(parentship) set supertype: connection
#    When relation(parentship) create role: parent
#    When relation(parentship) get role(parent) set specialise: player
#    Then relation(parentship) get role(parent) get cardinality: @card(1..2)
#    When relation(parentship) create role: child
#    When relation(parentship) get role(child) set specialise: player
#    Then relation(parentship) get role(child) get cardinality: @card(1..2)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When relation(parentship) get role(parent) set annotation: @card(1..1)
#    Then relation(parentship) get role(parent) get cardinality: @card(1..1)
#    When relation(parentship) get role(child) set annotation: @card(1..1)
#    Then relation(parentship) get role(child) get cardinality: @card(1..1)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When relation(parentship) create role: cardinality-destroyer
#    # card becomes 1..2
#    When relation(parentship) get role(cardinality-destroyer) set specialise: player; fails
#    When relation(connection) get role(player) set annotation: @card(1..3)
#    When relation(parentship) get role(cardinality-destroyer) set specialise: player
#    Then relation(connection) get role(player) get cardinality: @card(1..3)
#    Then relation(parentship) get role(parent) get cardinality: @card(1..1)
#    Then relation(parentship) get role(child) get cardinality: @card(1..1)
#    Then relation(parentship) get role(cardinality-destroyer) get cardinality: @card(1..3)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When relation(connection) get role(player) set annotation: @card(0..3)
#    Then relation(connection) get role(player) get cardinality: @card(0..3)
#    Then relation(parentship) get role(parent) get cardinality: @card(1..1)
#    Then relation(parentship) get role(child) get cardinality: @card(1..1)
#    Then relation(parentship) get role(cardinality-destroyer) get cardinality: @card(0..3)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(parentship) get role(cardinality-destroyer) set annotation: @card(3..3); fails
#    Then relation(parentship) get role(cardinality-destroyer) set annotation: @card(2..3); fails
#    When relation(parentship) get role(parent) set annotation: @card(0..1)
#    When relation(parentship) get role(cardinality-destroyer) set annotation: @card(2..3)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(connection) get role(player) get cardinality: @card(0..3)
#    Then relation(parentship) get role(parent) get cardinality: @card(0..1)
#    Then relation(parentship) get role(child) get cardinality: @card(1..1)
#    Then relation(parentship) get role(cardinality-destroyer) get cardinality: @card(2..3)
#    Then relation(connection) get role(player) set annotation: @card(0..1); fails
#    When relation(parentship) get role(parent) unset annotation: @card
#    When relation(parentship) get role(child) unset annotation: @card
#    When relation(parentship) get role(cardinality-destroyer) unset annotation: @card
#    When relation(connection) get role(player) set annotation: @card(0..1)
#    Then relation(connection) get role(player) get cardinality: @card(0..1)
#    Then relation(parentship) get role(parent) get cardinality: @card(0..1)
#    Then relation(parentship) get role(child) get cardinality: @card(0..1)
#    Then relation(parentship) get role(cardinality-destroyer) get cardinality: @card(0..1)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When relation(parentship) get role(parent) set annotation: @card(1..1)
#    Then relation(connection) get role(player) get cardinality: @card(0..1)
#    Then relation(parentship) get role(parent) get cardinality: @card(1..1)
#    Then relation(parentship) get role(child) get cardinality: @card(0..1)
#    Then relation(parentship) get role(cardinality-destroyer) get cardinality: @card(0..1)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(parentship) get role(cardinality-destroyer) set annotation: @card(1..1); fails
#    When create relation type: subsubtype-to-disturb
#    When relation(subsubtype-to-disturb) create role: subsubdisturber
#    When relation(subsubtype-to-disturb) set supertype: subtype-to-disturb
#    When relation(subsubtype-to-disturb) get role(subsubdisturber) set specialise: subdisturber
#    Then relation(subsubtype-to-disturb) get role(subsubdisturber) get cardinality: @card(1..1)
#    When transaction commits

    # TODO: We (temporarily) don't revalidate cardinality narrowing in schema!
#  Scenario: Type can have only N/M specialising relates when the root relates has cardinality(M, N) that are inherited
#    When create relation type: connection
#    When relation(connection) create role: player
#    When relation(connection) get role(player) set annotation: @card(1..1)
#    Then relation(connection) get role(player) get cardinality: @card(1..1)
#    When create relation type: family
#    When relation(family) set supertype: connection
#    When relation(family) create role: mother
#    When relation(family) create role: father
#    When relation(family) create role: child
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When relation(family) get role(mother) set specialise: player
#    Then relation(family) get role(mother) get cardinality: @card(1..1)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    # card becomes 1..1
#    When relation(family) get role(father) set specialise: player; fails
#    # card becomes 1..1
#    When relation(family) get role(child) set specialise: player; fails
#    When relation(family) get role(mother) unset specialise
#    When relation(connection) get role(player) set annotation: @card(1..2)
#    Then relation(connection) get role(player) get cardinality: @card(1..2)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When relation(family) get role(mother) set specialise: player
#    Then relation(family) get role(mother) get cardinality: @card(1..2)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When relation(family) get role(father) set specialise: player
#    Then relation(family) get role(father) get cardinality: @card(1..2)
#    # card becomes 1..2
#    Then relation(family) get role(child) set specialise: player; fails
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    # card becomes 1..2
#    Then relation(family) get role(child) set specialise: player; fails
#    When relation(family) get role(mother) unset specialise
#    When relation(family) get role(father) unset specialise
#    When relation(connection) get role(player) set annotation: @card(1..3)
#    Then relation(connection) get role(player) get cardinality: @card(1..3)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When relation(family) get role(father) set specialise: player
#    Then relation(family) get role(father) get cardinality: @card(1..3)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When relation(family) get role(child) set specialise: player
#    Then relation(family) get role(child) get cardinality: @card(1..3)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When relation(family) get role(mother) set specialise: player
#    Then relation(family) get role(mother) get cardinality: @card(1..3)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When relation(connection) get role(player) set annotation: @card(2..3); fails
#    When relation(family) get role(child) unset specialise
#    When relation(connection) get role(player) set annotation: @card(2..3); fails
#    When transaction closes
#    When connection open schema transaction for database: typedb
#    When relation(family) get role(child) unset specialise
#    When relation(family) get role(father) unset specialise
#    When relation(connection) get role(player) set annotation: @card(2..3)
#    Then relation(connection) get role(player) get cardinality: @card(2..3)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    # card becomes 2..3
#    Then relation(family) get role(father) set specialise: player; fails
#    When relation(connection) get role(player) set annotation: @card(2..4)
#    Then relation(connection) get role(player) get cardinality: @card(2..4)
#    When relation(family) get role(father) set specialise: player
#    Then relation(family) get role(father) get cardinality: @card(2..4)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    # card becomes 2..4
#    Then relation(family) get role(child) set specialise: player; fails
#    When relation(connection) get role(player) set annotation: @card(2..6)
#    Then relation(connection) get role(player) get cardinality: @card(2..6)
#    When relation(family) get role(child) set specialise: player
#    Then relation(family) get role(child) get cardinality: @card(2..6)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(connection) get role(player) set annotation: @card(2..5); fails
#    Then relation(connection) get role(player) set annotation: @card(3..8); fails
#    When relation(connection) get role(player) set annotation: @card(3..9)
#    Then relation(connection) get role(player) get cardinality: @card(3..9)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(connection) get role(player) set annotation: @card(1..1); fails
#    When relation(connection) get role(player) set annotation: @card(0..1)
#    Then relation(connection) get role(player) get cardinality: @card(0..1)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When relation(family) get role(child) set annotation: @card(1..1)
#    Then relation(family) get role(child) get cardinality: @card(1..1)
#    Then relation(family) get role(father) get cardinality: @card(0..1)
#    Then relation(family) get role(mother) get cardinality: @card(0..1)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(family) get role(child) get cardinality: @card(1..1)
#    Then relation(family) get role(mother) get cardinality: @card(0..1)
#    Then relation(family) get role(father) set annotation: @card(1..1); fails

    # TODO: We (temporarily) don't revalidate cardinality narrowing in schema!
#  Scenario: Relates cardinality should be checked against specialises' specialises cardinality
#    When create relation type: connection
#    When relation(connection) create role: player
#    When relation(connection) get role(player) set annotation: @card(5..10)
#    Then relation(connection) get role(player) get cardinality: @card(5..10)
#    When create relation type: parentship
#    When relation(parentship) set supertype: connection
#    When relation(parentship) create role: parent
#    When relation(parentship) get role(parent) set specialise: player
#    Then relation(parentship) get role(parent) get cardinality: @card(5..10)
#    When relation(parentship) create role: child
#    When relation(parentship) get role(child) set specialise: player
#    Then relation(parentship) get role(child) get cardinality: @card(5..10)
#    When create relation type: fathership
#    When relation(fathership) set supertype: parentship
#    When relation(fathership) create role: father
#    When relation(fathership) get role(father) set specialise: parent
#    Then relation(fathership) get role(father) get cardinality: @card(5..10)
#    When relation(fathership) create role: father-child
#    When relation(fathership) get role(father-child) set specialise: child
#    Then relation(fathership) get role(father-child) get cardinality: @card(5..10)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When relation(fathership) create role: father-2
#    Then relation(fathership) get role(father-2) get cardinality: @card(1..1)
#    When relation(fathership) create role: father-child-2
#    Then relation(fathership) get role(father-child-2) get cardinality: @card(1..1)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    # card becomes 5..10
#    Then relation(fathership) get role(father-2) set specialise: parent; fails
#    # card becomes 5..10
#    When relation(fathership) get role(father-child-2) set specialise: child; fails
#    When relation(connection) get role(player) set annotation: @card(3..10)
#    Then relation(connection) get role(player) get cardinality: @card(3..10)
#    When relation(fathership) get role(father-2) set specialise: parent
#    Then relation(fathership) get role(father-2) get cardinality: @card(3..10)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When relation(fathership) get role(father-2) set specialise: parent
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    # card becomes 3..10
#    Then relation(fathership) get role(father-child-2) set specialise: child; fails
#    When relation(connection) get role(player) set annotation: @card(3..)
#    Then relation(connection) get role(player) get cardinality: @card(3..)
#    When relation(fathership) get role(father-child-2) set specialise: child
#    Then relation(fathership) get role(father-child-2) get cardinality: @card(3..)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(parentship) get role(parent) unset specialise; fails
#    Then relation(parentship) get role(parent) set annotation: @card(0..); fails
#    When relation(parentship) get role(parent) set annotation: @card(3..)
#    When relation(parentship) get role(parent) unset specialise
#    When relation(parentship) get role(parent) set annotation: @card(0..)
#    Then relation(parentship) get role(child) unset specialise; fails
#    Then relation(parentship) get role(child) set annotation: @card(0..); fails
#    When relation(parentship) get role(child) set annotation: @card(3..)
#    When relation(parentship) get role(child) unset specialise
#    When relation(parentship) get role(child) set annotation: @card(0..)
#    When relation(connection) get role(player) set annotation: @card(1..1)
#    Then relation(connection) get role(player) get cardinality: @card(1..1)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When relation(fathership) get role(father-2) unset specialise
#    When relation(parentship) get role(parent) unset annotation: @card
#    When relation(parentship) get role(parent) set specialise: player
#    Then relation(parentship) get role(parent) get supertype: connection:player
#    Then relation(fathership) get role(father) get supertype: parentship:parent
#    Then relation(fathership) get role(father) get cardinality: @card(1..1)
#    Then relation(fathership) get role(father-2) get supertype does not exist
#    Then relation(parentship) get role(child) get supertype does not exist
#    Then relation(fathership) get role(father-child) get supertype: parentship:child
#    Then relation(fathership) get role(father-child-2) get supertype: parentship:child
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    # card becomes 1..1
#    Then relation(parentship) get role(parent) get supertype: connection:player
#    Then relation(fathership) get role(father) get supertype: parentship:parent
#    Then relation(fathership) get role(father) get cardinality: @card(1..1)
#    When relation(fathership) get role(father-2) set specialise: parent; fails
#    When relation(connection) get role(player) set annotation: @card(2..5)
#    When relation(fathership) get role(father-2) set specialise: parent
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When relation(fathership) get role(father-child-2) unset specialise
#    When relation(parentship) get role(child) unset annotation: @card
#    Then relation(fathership) get role(father-child) get supertype: parentship:child
#    Then relation(fathership) get role(father-child-2) get supertype does not exist
#    Then relation(parentship) get role(child) set specialise: player; fails
#    Then transaction closes
#    When connection open schema transaction for database: typedb
#    When relation(fathership) get role(father-child-2) unset specialise
#    When relation(parentship) get role(child) unset annotation: @card
#    Then relation(fathership) get role(father-child) get supertype: parentship:child
#    Then relation(fathership) get role(father-child-2) get supertype does not exist
#    Then relation(parentship) get role(child) set specialise: player; fails
#    When relation(connection) get role(player) set annotation: @card(2..6)
#    When relation(parentship) get role(child) set specialise: player
#    Then relation(parentship) get role(child) get supertype: connection:player
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(fathership) get role(father-child-2) set specialise: child; fails
#    When create relation type: mothership
#    When relation(mothership) set supertype: parentship
#    When relation(mothership) create role: mother
#    When relation(mothership) get role(mother) set specialise: parent
#    Then relation(mothership) get role(mother) get cardinality: @card(2..6)
#    When relation(mothership) create role: mother-child
#    When relation(mothership) get role(mother-child) set specialise: child
#    Then relation(mothership) get role(mother-child) get cardinality: @card(2..6)
#    When create relation type: mothership-with-three-children
#    When relation(mothership-with-three-children) set supertype: mothership
#    When relation(mothership-with-three-children) create role: child-1
#    When relation(mothership-with-three-children) get role(child-1) set specialise: mother-child
#    Then relation(mothership-with-three-children) get role(child-1) get cardinality: @card(2..6)
#    When relation(mothership-with-three-children) create role: child-2
#    When relation(mothership-with-three-children) get role(child-2) set specialise: mother-child
#    Then relation(mothership-with-three-children) get role(child-2) get cardinality: @card(2..6)
#    When relation(mothership-with-three-children) create role: child-3
#    When relation(mothership-with-three-children) get role(child-3) set specialise: mother-child
#    Then relation(mothership-with-three-children) get role(child-3) get cardinality: @card(2..6)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When relation(mothership-with-three-children) create role: three-children-mother
#    # card becomes 2..6
#    When relation(mothership-with-three-children) get role(three-children-mother) set specialise: mother; fails
#    Then relation(parentship) get role(parent) unset specialise; fails
#    When relation(parentship) get role(parent) set annotation: @card(2..6)
#    When relation(parentship) get role(parent) unset specialise
#    When relation(mothership-with-three-children) get role(three-children-mother) set specialise: mother
#    Then relation(mothership-with-three-children) get role(three-children-mother) get cardinality: @card(2..6)
#    When transaction commits

  Scenario: Relates default cardinality is permissively validated in multiple inheritance
    When create relation type: connection
    When relation(connection) create role: player
    Then relation(connection) get role(player) get cardinality: @card(0..1)
    When create relation type: parentship
    When relation(parentship) set supertype: connection
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set specialise: player
    Then relation(parentship) get role(parent) get cardinality: @card(0..1)
    When transaction commits
    When connection open schema transaction for database: typedb
    When create relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) create role: father
    When relation(fathership) get role(father) set specialise: parent
    Then relation(fathership) get role(father) get cardinality: @card(0..1)
    When transaction commits
    When connection open schema transaction for database: typedb
    When relation(fathership) create role: father-2
    When relation(fathership) get role(father-2) set specialise: parent
    Then relation(fathership) get role(father-2) get cardinality: @card(0..1)
    Then transaction commits

    # TODO: We (temporarily) don't revalidate cardinality narrowing in schema!
#  Scenario: Relates set and unset specialise revalidate cardinality between affected siblings
#    When create relation type: connection
#    When relation(connection) create role: player
#    Then relation(connection) get role(player) get cardinality: @card(1..1)
#    When create relation type: parentship
#    When relation(parentship) set supertype: connection
#    When relation(parentship) create role: parent
#    When relation(parentship) create role: child
#    Then relation(parentship) get role(parent) get cardinality: @card(1..1)
#    Then relation(parentship) get role(child) get cardinality: @card(1..1)
#    When create relation type: fathership
#    When relation(fathership) set supertype: parentship
#    When relation(fathership) create role: father
#    When relation(fathership) create role: father-2
#    Then relation(fathership) get role(father) get cardinality: @card(1..1)
#    Then relation(fathership) get role(father-2) get cardinality: @card(1..1)
#    When relation(parentship) get role(parent) set specialise: player
#    Then relation(parentship) get role(child) set specialise: player; fails
#    Then relation(connection) get role(player) set annotation: @card(1..2)
#    When relation(parentship) get role(child) set specialise: player
#    When relation(fathership) get role(father) set specialise: parent
#    When relation(fathership) get role(father-2) set specialise: parent
#    Then relation(fathership) get role(father) get cardinality: @card(1..2)
#    Then relation(fathership) get role(father-2) get cardinality: @card(1..2)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    When relation(connection) create role: bad-player
#    Then relation(connection) get role(bad-player) get cardinality: @card(1..1)
#    Then relation(parentship) get role(parent) set specialise: bad-player; fails
#    When relation(connection) get role(bad-player) set annotation: @card(1..1)
#    Then relation(connection) get role(bad-player) get cardinality: @card(1..1)
#    Then relation(parentship) get role(parent) set specialise: bad-player; fails
#    When relation(connection) get role(bad-player) set annotation: @card(0..1)
#    Then relation(connection) get role(bad-player) get cardinality: @card(0..1)
#    When relation(parentship) get role(parent) set specialise: bad-player
#    Then relation(fathership) get role(father) get cardinality: @card(0..1)
#    Then relation(fathership) get role(father-2) get cardinality: @card(0..1)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(parentship) get role(parent) unset specialise; fails
#    When relation(fathership) delete role: father-2
#    When relation(parentship) get role(parent) unset specialise
#    Then relation(fathership) get role(father) get cardinality: @card(1..1)
#    Then transaction commits

    # TODO: We (temporarily) don't revalidate cardinality narrowing in schema!
#  Scenario: Relates unset annotation @card revalidates cardinality between affected siblings
#    When create relation type: connection
#    When relation(connection) create role: player
#    Then relation(connection) get role(player) get cardinality: @card(1..1)
#    When create relation type: parentship
#    When relation(parentship) set supertype: connection
#    When relation(parentship) create role: parent
#    When relation(parentship) create role: child
#    Then relation(parentship) get role(parent) get cardinality: @card(1..1)
#    Then relation(parentship) get role(child) get cardinality: @card(1..1)
#    When create relation type: fathership
#    When relation(fathership) set supertype: parentship
#    When relation(fathership) create role: father
#    When relation(fathership) create role: father-2
#    Then relation(fathership) get role(father) get cardinality: @card(1..1)
#    Then relation(fathership) get role(father-2) get cardinality: @card(1..1)
#    When relation(parentship) get role(parent) set specialise: player
#    Then relation(parentship) get role(child) set specialise: player; fails
#    Then relation(connection) get role(player) set annotation: @card(1..2)
#    When relation(parentship) get role(child) set specialise: player
#    When relation(fathership) get role(father) set specialise: parent
#    When relation(fathership) get role(father-2) set specialise: parent
#    Then relation(fathership) get role(father) get cardinality: @card(1..2)
#    Then relation(fathership) get role(father-2) get cardinality: @card(1..2)
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(connection) get role(player) unset annotation: @card; fails
#    When relation(parentship) get role(child) unset specialise
#    Then relation(connection) get role(player) unset annotation: @card; fails
#    When relation(fathership) get role(father-2) unset specialise
#    When relation(connection) get role(player) unset annotation: @card
#    Then relation(parentship) get role(parent) get cardinality: @card(1..1)
#    Then relation(fathership) get role(father) get cardinality: @card(1..1)
#    Then transaction commits

########################
# relates @annotations combinations:
# @abstract, @distinct, @card
# Right now only for lists as there are no combinations for scalar roles!
########################

  Scenario Outline: Roles can set @<annotation-1> and @<annotation-2> together and unset it
    When create relation type: parentship
    When relation(parentship) set annotation: @abstract
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set annotation: @<annotation-1>
    When relation(parentship) get role(parent) set annotation: @<annotation-2>
    Then relation(parentship) get role(parent) get constraints contain: @<annotation-1>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation-1>
    Then relation(parentship) get role(parent) get constraints contain: @<annotation-2>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation-2>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @<annotation-1>
    Then relation(parentship) get role(parent) get constraint categories contain: @<annotation-category-1>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation-1>
    Then relation(parentship) get role(parent) get constraints contain: @<annotation-2>
    Then relation(parentship) get role(parent) get constraint categories contain: @<annotation-category-2>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation-2>
    When relation(parentship) get role(parent) unset annotation: @<annotation-category-1>
    Then relation(parentship) get role(parent) get constraints do not contain: @<annotation-1>
    Then relation(parentship) get role(parent) get constraint categories do not contain: @<annotation-category-1>
    Then relation(parentship) get role(parent) get declared annotations do not contain: @<annotation-1>
    Then relation(parentship) get role(parent) get constraints contain: @<annotation-2>
    Then relation(parentship) get role(parent) get constraint categories contain: @<annotation-category-2>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation-2>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints do not contain: @<annotation-1>
    Then relation(parentship) get role(parent) get declared annotations do not contain: @<annotation-1>
    Then relation(parentship) get role(parent) get constraints contain: @<annotation-2>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation-2>
    When relation(parentship) get role(parent) set annotation: @<annotation-1>
    When relation(parentship) get role(parent) unset annotation: @<annotation-category-2>
    Then relation(parentship) get role(parent) get constraints do not contain: @<annotation-2>
    Then relation(parentship) get role(parent) get declared annotations do not contain: @<annotation-2>
    Then relation(parentship) get role(parent) get constraints contain: @<annotation-1>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation-1>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints do not contain: @<annotation-2>
    Then relation(parentship) get role(parent) get declared annotations do not contain: @<annotation-2>
    Then relation(parentship) get role(parent) get constraints contain: @<annotation-1>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation-1>
    When relation(parentship) get role(parent) unset annotation: @<annotation-category-1>
    Then relation(parentship) get role(parent) get declared annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get declared annotations is empty
    Examples:
      | annotation-1 | annotation-2 | annotation-category-1 | annotation-category-2 |
      | abstract     | card(1..1)   | abstract              | card                  |

  Scenario Outline: Ordered roles can set @<annotation-1> and @<annotation-2> together and unset it
    When create relation type: parentship
    When relation(parentship) set annotation: @abstract
    When relation(parentship) create role: parent
    When relation(parentship) get role(parent) set ordering: ordered
    When relation(parentship) get role(parent) set annotation: @<annotation-1>
    When relation(parentship) get role(parent) set annotation: @<annotation-2>
    Then relation(parentship) get role(parent) get constraints contain: @<annotation-1>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation-1>
    Then relation(parentship) get role(parent) get constraints contain: @<annotation-2>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation-2>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints contain: @<annotation-1>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation-1>
    Then relation(parentship) get role(parent) get constraints contain: @<annotation-2>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation-2>
    When relation(parentship) get role(parent) unset annotation: @<annotation-category-1>
    Then relation(parentship) get role(parent) get constraints do not contain: @<annotation-1>
    Then relation(parentship) get role(parent) get declared annotations do not contain: @<annotation-1>
    Then relation(parentship) get role(parent) get constraints contain: @<annotation-2>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation-2>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints do not contain: @<annotation-1>
    Then relation(parentship) get role(parent) get constraints contain: @<annotation-2>
    Then relation(parentship) get role(parent) get declared annotations do not contain: @<annotation-1>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation-2>
    When relation(parentship) get role(parent) set annotation: @<annotation-1>
    When relation(parentship) get role(parent) unset annotation: @<annotation-category-2>
    Then relation(parentship) get role(parent) get constraints do not contain: @<annotation-2>
    Then relation(parentship) get role(parent) get constraints contain: @<annotation-1>
    Then relation(parentship) get role(parent) get declared annotations do not contain: @<annotation-2>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation-1>
    When transaction commits
    When connection open schema transaction for database: typedb
    Then relation(parentship) get role(parent) get constraints do not contain: @<annotation-2>
    Then relation(parentship) get role(parent) get constraints contain: @<annotation-1>
    Then relation(parentship) get role(parent) get declared annotations do not contain: @<annotation-2>
    Then relation(parentship) get role(parent) get declared annotations contain: @<annotation-1>
    When relation(parentship) get role(parent) unset annotation: @<annotation-category-1>
    Then relation(parentship) get role(parent) get declared annotations is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then relation(parentship) get role(parent) get declared annotations is empty
    Examples:
      | annotation-1 | annotation-2 | annotation-category-1 | annotation-category-2 |
      | abstract     | distinct     | abstract              | distinct              |
      | abstract     | card(0..1)   | abstract              | card                  |
      | distinct     | card(0..1)   | distinct              | card                  |

      # Uncomment and add Examples when they appear!
#  Scenario Outline: Roles lists cannot set @<annotation-1> and @<annotation-2> together and unset it
#    When create relation type: parentship
#    When relation(parentship) set annotation: @abstract
#    When relation(parentship) create role: parent
#    When relation(parentship) get role(parent) set ordering: ordered
#    When relation(parentship) get role(parent) set annotation: @<annotation-1>
#    Then relation(parentship) get role(parent) set annotation: @<annotation-2>; fails
#    When transaction closes
#    When connection open schema transaction for database: typedb
#    When create relation type: parentship
#    When relation(parentship) create role: parent
#    When relation(parentship) get role(parent) set ordering: ordered
#    Then relation(parentship) get role(parent) set annotation: @<annotation-2>
#    When relation(parentship) get role(parent) set annotation: @<annotation-1>; fails
#    When transaction commits
#    When connection open schema transaction for database: typedb
#    Then relation(parentship) get role(parent) get constraints contain: @<annotation-2>
#    Then relation(parentship) get role(parent) get constraints do not contain: @<annotation-1>
#    Examples:
#      | annotation-1 | annotation-2 |
