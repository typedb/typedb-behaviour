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

Feature: Concept Relation Type and Role Type

  Background:
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection does not have any keyspace
    Given connection create keyspace: grakn
    Given connection open schema session for keyspace: grakn
    Given session opens transaction of type: write

  Scenario: Relation and role types can be created
    When put relation type: marriage
    When relation(marriage) set relates role: husband
    When relation(marriage) set relates role: wife
    Then relation(marriage) is null: false
    Then relation(marriage) get supertype: relation
    Then relation(marriage) get role(husband) is null: false
    Then relation(marriage) get role(wife) is null: false
    Then relation(marriage) get role(husband) get supertype: relation:role
    Then relation(marriage) get role(wife) get supertype: relation:role
    Then relation(marriage) get related roles contain:
      | husband |
      | wife    |
    When transaction commits
    When session opens transaction of type: read
    Then relation(marriage) is null: false
    Then relation(marriage) get supertype: relation
    Then relation(marriage) get role(husband) is null: false
    Then relation(marriage) get role(wife) is null: false
    Then relation(marriage) get role(husband) get supertype: relation:role
    Then relation(marriage) get role(wife) get supertype: relation:role
    Then relation(marriage) get related roles contain:
      | husband |
      | wife    |

  Scenario: Relation and role types can be deleted
    When put relation type: marriage
    When relation(marriage) set relates role: spouse
    When put relation type: parentship
    When relation(parentship) set relates role: parent
    When relation(parentship) set relates role: child
    When relation(parentship) remove related role: parent
    Then relation(parentship) get related roles do not contain:
      | parent |
    Then relation(relation) get role(role) get subtypes do not contain:
      | parentship:parent |
    When transaction commits
    When session opens transaction of type: write
    When delete relation type: parentship
    Then relation(parentship) is null: true
    Then relation(relation) get role(role) get subtypes do not contain:
      | parentship:parent |
      | parentship:child  |
    When relation(marriage) remove related role: spouse
    Then relation(marriage) get related roles do not contain:
      | spouse |
    When relation(marriage) set relates role: husband
    When relation(marriage) set relates role: wife
    When transaction commits
    When session opens transaction of type: write
    When delete relation type: marriage
    Then relation(marriage) is null: true
    Then relation(relation) get role(role) get subtypes do not contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |
    When transaction commits
    When session opens transaction of type: read
    Then relation(parentship) is null: true
    Then relation(marriage) is null: true
    Then relation(relation) get role(role) get subtypes do not contain:
      | parentship:parent |
      | parentship:child  |
      | marriage:husband  |
      | marriage:wife     |

  Scenario: Relation and role types can change labels
    When put relation type: parentship
    When relation(parentship) set relates role: parent
    When relation(parentship) set relates role: child
    Then relation(parentship) get label: parentship
    Then relation(parentship) get role(parent) get label: parent
    Then relation(parentship) get role(child) get label: child
    When relation(parentship) set label: marriage
    Then relation(parentship) is null: true
    Then relation(marriage) is null: false
    When relation(marriage) get role(parent) set label: husband
    When relation(marriage) get role(child) set label: wife
    Then relation(marriage) get role(parent) is null: true
    Then relation(marriage) get role(child) is null: true
    Then relation(marriage) get label: marriage
    Then relation(marriage) get role(husband) get label: husband
    Then relation(marriage) get role(wife) get label: wife
    When transaction commits
    When session opens transaction of type: write
    Then relation(marriage) get label: marriage
    Then relation(marriage) get role(husband) get label: husband
    Then relation(marriage) get role(wife) get label: wife
    When relation(marriage) set label: employment
    Then relation(marriage) is null: true
    Then relation(employment) is null: false
    When relation(employment) get role(husband) set label: employee
    When relation(employment) get role(wife) set label: employer
    Then relation(employment) get role(husband) is null: true
    Then relation(employment) get role(wife) is null: true
    Then relation(employment) get label: employment
    Then relation(employment) get role(employee) get label: employee
    Then relation(employment) get role(employer) get label: employer
    When transaction commits
    When session opens transaction of type: read
    Then relation(employment) is null: false
    Then relation(employment) get label: employment
    Then relation(employment) get role(employee) get label: employee
    Then relation(employment) get role(employer) get label: employer

  Scenario: Relation and role types can be set to abstract
    When put relation type: marriage
    When relation(marriage) set relates role: husband
    When relation(marriage) set relates role: wife
    When relation(marriage) set abstract: true
    When put relation type: parentship
    When relation(parentship) set relates role: parent
    When relation(parentship) set relates role: child
    Then relation(marriage) is abstract: true
    Then relation(marriage) get role(husband) is abstract: true
    Then relation(marriage) get role(wife) is abstract: true
    Then relation(marriage) fails at creating an instance
    Then relation(parentship) is abstract: false
    Then relation(parentship) get role(parent) is abstract: false
    Then relation(parentship) get role(child) is abstract: false
    When transaction commits
    When session opens transaction of type: write
    Then relation(marriage) is abstract: true
    Then relation(marriage) get role(husband) is abstract: true
    Then relation(marriage) get role(wife) is abstract: true
    Then relation(marriage) fails at creating an instance
    Then relation(parentship) is abstract: false
    Then relation(parentship) get role(parent) is abstract: false
    Then relation(parentship) get role(child) is abstract: false
    Then relation(parentship) set abstract: true
    Then relation(parentship) is abstract: true
    Then relation(parentship) get role(parent) is abstract: true
    Then relation(parentship) get role(child) is abstract: true
    Then relation(parentship) fails at creating an instance
    When transaction commits
    When session opens transaction of type: read
    Then relation(parentship) is abstract: true
    Then relation(parentship) get role(parent) is abstract: true
    Then relation(parentship) get role(child) is abstract: true
    Then relation(parentship) fails at creating an instance

  Scenario: Relation and role types can be subtypes of other relation and role types
    When put relation type: parentship
    When relation(parentship) set relates role: parent
    When relation(parentship) set relates role: child
    When put relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) set relates role: father as parent
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
    When session opens transaction of type: write
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
    When relation(father-son) set relates role: son as child
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
    When session opens transaction of type: read
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

  Scenario: Relation types can inherit related role types
    When put relation type: parentship
    When relation(parentship) set relates role: parent
    When relation(parentship) set relates role: child
    When put relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) set relates role: father as parent
    Then relation(fathership) get related roles contain:
      | fathership:father |
      | parentship:child  |
    When transaction commits
    When session opens transaction of type: write
    When put relation type: mothership
    When relation(mothership) set supertype: parentship
    When relation(mothership) set relates role: mother as parent
    Then relation(mothership) get related roles contain:
      | mothership:mother |
      | parentship:child  |
    When transaction commits
    When session opens transaction of type: read
    Then relation(fathership) get related roles contain:
      | fathership:father |
      | parentship:child  |
    Then relation(mothership) get related roles contain:
      | mothership:mother |
      | parentship:child  |

  Scenario: Relation types can override inherited related role types
    When put relation type: parentship
    When relation(parentship) set relates role: parent
    When relation(parentship) set relates role: child
    When put relation type: fathership
    When relation(fathership) set supertype: parentship
    When relation(fathership) set relates role: father as parent
    Then relation(fathership) get related roles do not contain:
      | parentship:parent |
    When transaction commits
    When session opens transaction of type: write
    When put relation type: mothership
    When relation(mothership) set supertype: parentship
    When relation(mothership) set relates role: mother as parent
    Then relation(mothership) get related roles do not contain:
      | parentship:parent |
    When transaction commits
    When session opens transaction of type: read
    Then relation(fathership) get related roles do not contain:
      | parentship:parent |
    Then relation(mothership) get related roles do not contain:
      | parentship:parent |

  Scenario: Relation types cannot redeclare inherited related role types
    When put relation type: parentship
    When relation(parentship) set relates role: parent
    When relation(parentship) set relates role: child
    When put relation type: fathership
    When relation(fathership) set supertype: parentship
    Then relation(fathership) fails at setting relates role: parent

  Scenario: Relation types cannot override declared related role types
    When put relation type: parentship
    When relation(parentship) set relates role: parent
    Then relation(parentship) fails at setting relates role: father as parent

  Scenario: Relation types can have keys
    When put attribute type: license, with value type: string
    When put relation type: marriage
    When relation(marriage) set relates role: spouse
    When relation(marriage) set key attribute type: license
    Then relation(marriage) get key attribute types contain:
      | license |
    When transaction commits
    When session opens transaction of type: read
    Then relation(marriage) get key attribute types contain:
      | license |

  Scenario: Relation types can remove keys
    When put attribute type: license, with value type: string
    When put attribute type: certificate, with value type: string
    When put relation type: marriage
    When relation(marriage) set relates role: spouse
    When relation(marriage) set key attribute type: license
    When relation(marriage) set key attribute type: certificate
    When relation(marriage) remove key attribute type: license
    Then relation(marriage) get key attribute types do not contain:
      | license |
    When transaction commits
    When session opens transaction of type: write
    When relation(marriage) remove key attribute type: certificate
    Then relation(marriage) get key attribute types do not contain:
      | license     |
      | certificate |

  Scenario: Relation types cannot have keys of attributes that are not keyable
    When put attribute type: is-permanent, with value type: boolean
    When put attribute type: contract-years, with value type: long
    When put attribute type: salary, with value type: double
    When put attribute type: reference, with value type: string
    When put attribute type: start-date, with value type: datetime
    When put relation type: employment
    When relation(employment) set key attribute type: contract-years
    When relation(employment) set key attribute type: reference
    When relation(employment) set key attribute type: start-date
    When relation(employment) fails at setting key attribute type: is-permanent
    When relation(employment) fails at setting key attribute type: salary

  Scenario: Relation types can have attributes
    When put attribute type: date, with value type: datetime
    When put attribute type: religion, with value type: string
    When put relation type: marriage
    When relation(marriage) set relates role: spouse
    When relation(marriage) set has attribute type: date
    When relation(marriage) set has attribute type: religion
    Then relation(marriage) get has attribute types contain:
      | date     |
      | religion |
    When transaction commits
    When session opens transaction of type: read
    Then relation(marriage) get has attribute types contain:
      | date     |
      | religion |

  Scenario: Relation types can remove attributes
    When put attribute type: date, with value type: datetime
    When put attribute type: religion, with value type: string
    When put relation type: marriage
    When relation(marriage) set relates role: spouse
    When relation(marriage) set has attribute type: date
    When relation(marriage) set has attribute type: religion
    When relation(marriage) remove has attribute type: religion
    Then relation(marriage) get has attribute types do not contain:
      | religion |
    When transaction commits
    When session opens transaction of type: write
    When relation(marriage) remove has attribute type: date
    Then relation(marriage) get has attribute types do not contain:
      | date     |
      | religion |

  Scenario: Relation types can have keys and attributes
    When put attribute type: license, with value type: string
    When put attribute type: certificate, with value type: string
    When put attribute type: date, with value type: datetime
    When put attribute type: religion, with value type: string
    When put relation type: marriage
    When relation(marriage) set key attribute type: license
    When relation(marriage) set key attribute type: certificate
    When relation(marriage) set has attribute type: date
    When relation(marriage) set has attribute type: religion
    Then relation(marriage) get key attribute types contain:
      | license     |
      | certificate |
    Then relation(marriage) get has attribute types contain:
      | license     |
      | certificate |
      | date        |
      | religion    |
    When transaction commits
    When session opens transaction of type: read
    Then relation(marriage) get key attribute types contain:
      | license     |
      | certificate |
    Then relation(marriage) get has attribute types contain:
      | license     |
      | certificate |
      | date        |
      | religion    |

  Scenario: Relation types can inherit keys and attributes
    When put attribute type: employment-reference, with value type: string
    When put attribute type: employment-hours, with value type: long
    When put attribute type: contractor-reference, with value type: string
    When put attribute type: contractor-hours, with value type: long
    When put relation type: employment
    When relation(employment) set relates role: employee
    When relation(employment) set relates role: employer
    When relation(employment) set key attribute type: employment-reference
    When relation(employment) set has attribute type: employment-hours
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) set key attribute type: contractor-reference
    When relation(contractor-employment) set has attribute type: contractor-hours
    Then relation(contractor-employment) get key attribute types contain:
      | employment-reference |
      | contractor-reference |
    Then relation(contractor-employment) get has attribute types contain:
      | employment-reference |
      | contractor-reference |
      | employment-hours     |
      | contractor-hours     |
    When transaction commits
    When session opens transaction of type: write
    Then relation(contractor-employment) get key attribute types contain:
      | employment-reference |
      | contractor-reference |
    Then relation(contractor-employment) get has attribute types contain:
      | employment-reference |
      | contractor-reference |
      | employment-hours     |
      | contractor-hours     |
    When put attribute type: parttime-reference, with value type: string
    When put attribute type: parttime-hours, with value type: long
    When put relation type: parttime-employment
    When relation(parttime-employment) set supertype: contractor-employment
    When relation(parttime-employment) set key attribute type: parttime-reference
    When relation(parttime-employment) set has attribute type: parttime-hours
    Then relation(parttime-employment) get key attribute types contain:
      | employment-reference |
      | contractor-reference |
      | parttime-reference   |
    Then relation(parttime-employment) get has attribute types contain:
      | employment-reference |
      | contractor-reference |
      | parttime-reference   |
      | employment-hours     |
      | contractor-hours     |
      | parttime-hours       |
    When transaction commits
    When session opens transaction of type: read
    Then relation(contractor-employment) get key attribute types contain:
      | employment-reference |
      | contractor-reference |
    Then relation(contractor-employment) get has attribute types contain:
      | employment-reference |
      | contractor-reference |
      | employment-hours     |
      | contractor-hours     |
    Then relation(parttime-employment) get key attribute types contain:
      | employment-reference |
      | contractor-reference |
      | parttime-reference   |
    Then relation(parttime-employment) get has attribute types contain:
      | employment-reference |
      | contractor-reference |
      | parttime-reference   |
      | employment-hours     |
      | contractor-hours     |
      | parttime-hours       |

  Scenario: Relation types can inherit keys and attributes that are subtypes of each other
    When put attribute type: employment-reference, with value type: string
    When put attribute type: employment-hours, with value type: long
    When put attribute type: contractor-reference, with value type: string
    When attribute(contractor-reference) set supertype: employment-reference
    When put attribute type: contractor-hours, with value type: long
    When attribute(contractor-hours) set supertype: employment-hours
    When put relation type: employment
    When relation(employment) set relates role: employee
    When relation(employment) set relates role: employer
    When relation(employment) set key attribute type: employment-reference
    When relation(employment) set has attribute type: employment-hours
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) set key attribute type: contractor-reference
    When relation(contractor-employment) set has attribute type: contractor-hours
    Then relation(contractor-employment) get key attribute types contain:
      | employment-reference |
      | contractor-reference |
    Then relation(contractor-employment) get has attribute types contain:
      | employment-reference |
      | contractor-reference |
      | employment-hours     |
      | contractor-hours     |
    When transaction commits
    When session opens transaction of type: write
    Then relation(contractor-employment) get key attribute types contain:
      | employment-reference |
      | contractor-reference |
    Then relation(contractor-employment) get has attribute types contain:
      | employment-reference |
      | contractor-reference |
      | employment-hours     |
      | contractor-hours     |
    When put attribute type: parttime-reference, with value type: string
    When attribute(parttime-reference) set supertype: contractor-reference
    When put attribute type: parttime-hours, with value type: long
    When attribute(parttime-hours) set supertype: contractor-hours
    When put relation type: parttime-employment
    When relation(parttime-employment) set supertype: contractor-employment
    When relation(parttime-employment) set key attribute type: parttime-reference
    When relation(parttime-employment) set has attribute type: parttime-hours
    Then relation(parttime-employment) get key attribute types contain:
      | employment-reference |
      | contractor-reference |
      | parttime-reference   |
    Then relation(parttime-employment) get has attribute types contain:
      | employment-reference |
      | contractor-reference |
      | parttime-reference   |
      | employment-hours     |
      | contractor-hours     |
      | parttime-hours       |
    When transaction commits
    When session opens transaction of type: read
    Then relation(contractor-employment) get key attribute types contain:
      | employment-reference |
      | contractor-reference |
    Then relation(contractor-employment) get has attribute types contain:
      | employment-reference |
      | contractor-reference |
      | employment-hours     |
      | contractor-hours     |
    Then relation(parttime-employment) get key attribute types contain:
      | employment-reference |
      | contractor-reference |
      | parttime-reference   |
    Then relation(parttime-employment) get has attribute types contain:
      | employment-reference |
      | contractor-reference |
      | parttime-reference   |
      | employment-hours     |
      | contractor-hours     |
      | parttime-hours       |

  Scenario: Relation types can override inherited keys and attributes
    When put attribute type: employment-reference, with value type: string
    When put attribute type: employment-hours, with value type: long
    When put attribute type: contractor-reference, with value type: string
    When attribute(contractor-reference) set supertype: employment-reference
    When put attribute type: contractor-hours, with value type: long
    When attribute(contractor-hours) set supertype: employment-hours
    When put relation type: employment
    When relation(employment) set relates role: employee
    When relation(employment) set relates role: employer
    When relation(employment) set key attribute type: employment-reference
    When relation(employment) set has attribute type: employment-hours
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) set key attribute type: contractor-reference as employment-reference
    When relation(contractor-employment) set has attribute type: contractor-hours as employment-hours
    Then relation(contractor-employment) get key attribute types contain:
      | contractor-reference |
    Then relation(contractor-employment) get key attribute types do not contain:
      | employment-reference |
    Then relation(contractor-employment) get has attribute types contain:
      | contractor-reference |
      | contractor-hours     |
    Then relation(contractor-employment) get has attribute types do not contain:
      | employment-reference |
      | employment-hours     |
    When transaction commits
    When session opens transaction of type: write
    Then relation(contractor-employment) get key attribute types contain:
      | contractor-reference |
    Then relation(contractor-employment) get key attribute types do not contain:
      | employment-reference |
    Then relation(contractor-employment) get has attribute types contain:
      | contractor-reference |
      | contractor-hours     |
    Then relation(contractor-employment) get has attribute types do not contain:
      | employment-reference |
      | employment-hours     |
    When put attribute type: parttime-reference, with value type: string
    When attribute(parttime-reference) set supertype: contractor-reference
    When put attribute type: parttime-hours, with value type: long
    When attribute(parttime-hours) set supertype: contractor-hours
    When put relation type: parttime-employment
    When relation(parttime-employment) set supertype: contractor-employment
    When relation(parttime-employment) set key attribute type: parttime-reference as contractor-reference
    When relation(parttime-employment) set has attribute type: parttime-hours as contractor-hours
    Then relation(parttime-employment) get key attribute types contain:
      | parttime-reference |
    Then relation(parttime-employment) get has attribute types contain:
      | parttime-reference |
      | parttime-hours     |
    When transaction commits
    When session opens transaction of type: read
    Then relation(contractor-employment) get key attribute types contain:
      | contractor-reference |
    Then relation(contractor-employment) get key attribute types do not contain:
      | employment-reference |
    Then relation(contractor-employment) get has attribute types contain:
      | contractor-reference |
      | contractor-hours     |
    Then relation(contractor-employment) get has attribute types do not contain:
      | employment-reference |
      | employment-hours     |
    Then relation(parttime-employment) get key attribute types contain:
      | parttime-reference |
    Then relation(parttime-employment) get key attribute types do not contain:
      | employment-reference |
      | contractor-reference |
    Then relation(parttime-employment) get has attribute types contain:
      | parttime-reference |
      | parttime-hours     |
    Then relation(parttime-employment) get key attribute types do not contain:
      | employment-reference |
      | contractor-reference |
      | employment-hours     |
      | contractor-hours     |

  Scenario: Relation types can override inherited attributes as keys
    When put attribute type: employment-reference, with value type: string
    When put attribute type: contractor-reference, with value type: string
    When attribute(contractor-reference) set supertype: employment-reference
    When put relation type: employment
    When relation(employment) set relates role: employer
    When relation(employment) set relates role: employee
    When relation(employment) set has attribute type: employment-reference
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) set key attribute type: contractor-reference as employment-reference
    Then relation(contractor-employment) get key attribute types contain:
      | contractor-reference |
    Then relation(contractor-employment) get key attribute types do not contain:
      | employment-reference |
    Then relation(contractor-employment) get has attribute types contain:
      | contractor-reference |
    Then relation(contractor-employment) get has attribute types do not contain:
      | employment-reference |
    When transaction commits
    When session opens transaction of type: read
    Then relation(contractor-employment) get key attribute types contain:
      | contractor-reference |
    Then relation(contractor-employment) get key attribute types do not contain:
      | employment-reference |
    Then relation(contractor-employment) get has attribute types contain:
      | contractor-reference |
    Then relation(contractor-employment) get has attribute types do not contain:
      | employment-reference |

  Scenario: Relation types cannot redeclare keys as attributes
    When put attribute type: license, with value type: string
    When put relation type: marriage
    When relation(marriage) set relates role: spouse
    When relation(marriage) set key attribute type: license
    Then relation(marriage) fails at setting has attribute type: license

  Scenario: Relation types cannot redeclare attributes as keys
    When put attribute type: date, with value type: datetime
    When put relation type: marriage
    When relation(marriage) set relates role: spouse
    When relation(marriage) set has attribute type: date
    Then relation(marriage) fails at setting key attribute type: date

  Scenario: Relation types cannot redeclare inherited keys and attributes
    When put attribute type: employment-reference, with value type: string
    When put attribute type: employment-hours, with value type: long
    When put relation type: employment
    When relation(employment) set relates role: employee
    When relation(employment) set relates role: employer
    When relation(employment) set key attribute type: employment-reference
    When relation(employment) set has attribute type: employment-hours
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    Then relation(contractor-employment) fails at setting key attribute type: employment-reference
    Then relation(contractor-employment) fails at setting has attribute type: employment-hours

  Scenario: Relation types cannot redeclare inherited/overridden key/has attribute types
    When put attribute type: employment-reference, with value type: string
    When put attribute type: employment-hours, with value type: long
    When put attribute type: contractor-reference, with value type: string
    When attribute(contractor-reference) set supertype: employment-reference
    When put attribute type: contractor-hours, with value type: long
    When attribute(contractor-hours) set supertype: employment-hours
    When put relation type: employment
    When relation(employment) set relates role: employee
    When relation(employment) set key attribute type: employment-reference
    When relation(employment) set has attribute type: employment-hours
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) set key attribute type: contractor-reference as employment-reference
    When relation(contractor-employment) set has attribute type: contractor-hours as employment-hours
    When put relation type: parttime-employment
    When relation(parttime-employment) set supertype: contractor-employment
    Then relation(parttime-employment) fails at setting key attribute type: employment-reference
    Then relation(parttime-employment) fails at setting key attribute type: contractor-reference
    Then relation(parttime-employment) fails at setting has attribute type: employment-hours
    Then relation(parttime-employment) fails at setting has attribute type: contractor-hours

  Scenario: Relation types cannot override declared keys and attributes
    When put attribute type: reference, with value type: string
    When put attribute type: social-security-number, with value type: string
    When attribute(social-security-number) set supertype: reference
    When put attribute type: hours, with value type: long
    When put attribute type: max-hours, with value type: long
    When attribute(max-hours) set supertype: hours
    When put relation type: employment
    When relation(employment) set relates role: employee
    When relation(employment) set relates role: employer
    When relation(employment) set key attribute type: reference
    When relation(employment) set has attribute type: hours
    Then relation(employment) fails at setting key attribute type: social-security-number as reference
    Then relation(employment) fails at setting has attribute type: max-hours as hours

  Scenario: Relation types cannot override inherited keys as attributes
    When put attribute type: employment-reference, with value type: string
    When put attribute type: contractor-reference, with value type: string
    When attribute(contractor-reference) set supertype: employment-reference
    When put relation type: employment
    When relation(employment) set relates role: employer
    When relation(employment) set relates role: employee
    When relation(employment) set key attribute type: employment-reference
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    Then relation(contractor-employment) fails at setting has attribute type: contractor-reference as employment-reference

  Scenario: Relation types cannot override inherited keys and attributes other than with their subtypes
    When put attribute type: employment-reference, with value type: string
    When put attribute type: employment-hours, with value type: long
    When put attribute type: contractor-reference, with value type: string
    When put attribute type: contractor-hours, with value type: long
    When put relation type: employment
    When relation(employment) set relates role: employee
    When relation(employment) set relates role: employer
    When relation(employment) set key attribute type: employment-reference
    When relation(employment) set has attribute type: employment-hours
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    Then relation(contractor-employment) fails at setting key attribute type: contractor-reference as employment-reference
    Then relation(contractor-employment) fails at setting has attribute type: contractor-hours as employment-hours

  Scenario: Relation types can play role types
    When put relation type: locates
    When relation(locates) set relates role: location
    When relation(locates) set relates role: located
    When put relation type: marriage
    When relation(marriage) set relates role: husband
    When relation(marriage) set relates role: wife
    When relation(marriage) set plays role: locates:located
    Then relation(marriage) get playing roles contain:
      | locates:located |
    When transaction commits
    When session opens transaction of type: write
    When put relation type: organises
    When relation(organises) set relates role: organiser
    When relation(organises) set relates role: organised
    When relation(marriage) set plays role: organises:organised
    Then relation(marriage) get playing roles contain:
      | locates:located     |
      | organises:organised |
    When transaction commits
    When session opens transaction of type: read
    Then relation(marriage) get playing roles contain:
      | locates:located     |
      | organises:organised |

  Scenario: Relation types can remove playing role types
    When put relation type: locates
    When relation(locates) set relates role: location
    When relation(locates) set relates role: located
    When put relation type: organises
    When relation(organises) set relates role: organiser
    When relation(organises) set relates role: organised
    When put relation type: marriage
    When relation(marriage) set relates role: husband
    When relation(marriage) set relates role: wife
    When relation(marriage) set plays role: locates:located
    When relation(marriage) set plays role: organises:organised
    When relation(marriage) remove plays role: locates:located
    Then relation(marriage) get playing roles do not contain:
      | locates:located |
    When transaction commits
    When session opens transaction of type: write
    When relation(marriage) remove plays role: organises:organised
    Then relation(marriage) get playing roles do not contain:
      | locates:located     |
      | organises:organised |
    When transaction commits
    When session opens transaction of type: read
    Then relation(marriage) get playing roles do not contain:
      | locates:located     |
      | organises:organised |

  Scenario: Relation types can inherit playing role types
    When put relation type: locates
    When relation(locates) set relates role: locating
    When relation(locates) set relates role: located
    When put relation type: contractor-locates
    When relation(contractor-locates) set relates role: contractor-locating
    When relation(contractor-locates) set relates role: contractor-located
    When put relation type: employment
    When relation(employment) set relates role: employer
    When relation(employment) set relates role: employee
    When relation(employment) set plays role: locates:located
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) set plays role: contractor-locates:contractor-located
    Then relation(contractor-employment) get playing roles contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
    When transaction commits
    When session opens transaction of type: write
    When put relation type: parttime-locates
    When relation(parttime-locates) set relates role: parttime-locating
    When relation(parttime-locates) set relates role: parttime-located
    When put relation type: parttime-employment
    When relation(parttime-employment) set supertype: contractor-employment
    When relation(parttime-employment) set relates role: parttime-employer
    When relation(parttime-employment) set relates role: parttime-employee
    When relation(parttime-employment) set plays role: parttime-locates:parttime-located
    Then relation(parttime-employment) get playing roles contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
      | parttime-locates:parttime-located     |
    When transaction commits
    When session opens transaction of type: read
    Then relation(contractor-employment) get playing roles contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
    Then relation(parttime-employment) get playing roles contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
      | parttime-locates:parttime-located     |

  Scenario: Relation types can inherit playing role types that are subtypes of each other
    When put relation type: locates
    When relation(locates) set relates role: locating
    When relation(locates) set relates role: located
    When put relation type: contractor-locates
    When relation(contractor-locates) set supertype: locates
    When relation(contractor-locates) set relates role: contractor-locating as locating
    When relation(contractor-locates) set relates role: contractor-located as located
    When put relation type: employment
    When relation(employment) set relates role: employer
    When relation(employment) set relates role: employee
    When relation(employment) set plays role: locates:located
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) set plays role: contractor-locates:contractor-located
    Then relation(contractor-employment) get playing roles contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
    When transaction commits
    When session opens transaction of type: write
    When put relation type: parttime-locates
    When relation(parttime-locates) set supertype: contractor-locates
    When relation(parttime-locates) set relates role: parttime-locating as contractor-locating
    When relation(parttime-locates) set relates role: parttime-located as contractor-located
    When put relation type: parttime-employment
    When relation(parttime-employment) set supertype: contractor-employment
    When relation(parttime-employment) set relates role: parttime-employer
    When relation(parttime-employment) set relates role: parttime-employee
    When relation(parttime-employment) set plays role: parttime-locates:parttime-located
    Then relation(parttime-employment) get playing roles contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
      | parttime-locates:parttime-located     |
    When transaction commits
    When session opens transaction of type: read
    Then relation(contractor-employment) get playing roles contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
    Then relation(parttime-employment) get playing roles contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
      | parttime-locates:parttime-located     |

  Scenario: Relation types can override inherited playing role types
    When put relation type: locates
    When relation(locates) set relates role: locating
    When relation(locates) set relates role: located
    When put relation type: contractor-locates
    When relation(contractor-locates) set supertype: locates
    When relation(contractor-locates) set relates role: contractor-locating as locating
    When relation(contractor-locates) set relates role: contractor-located as located
    When put relation type: employment
    When relation(employment) set relates role: employer
    When relation(employment) set relates role: employee
    When relation(employment) set plays role: locates:located
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) set plays role: contractor-locates:contractor-located as located
    Then relation(contractor-employment) get playing roles do not contain:
      | locates:located |
    When transaction commits
    When session opens transaction of type: write
    When put relation type: parttime-locates
    When relation(parttime-locates) set supertype: contractor-locates
    When relation(parttime-locates) set relates role: parttime-locating as contractor-locating
    When relation(parttime-locates) set relates role: parttime-located as contractor-located
    When put relation type: parttime-employment
    When relation(parttime-employment) set supertype: contractor-employment
    When relation(parttime-employment) set relates role: parttime-employer
    When relation(parttime-employment) set relates role: parttime-employee
    When relation(parttime-employment) set plays role: parttime-locates:parttime-located as contractor-located
    Then relation(parttime-employment) get playing roles do not contain:
      | locates:located                       |
      | contractor-locates:contractor-located |
    When transaction commits
    When session opens transaction of type: read
    Then relation(contractor-employment) get playing roles do not contain:
      | locates:located |
    Then relation(parttime-employment) get playing roles do not contain:
      | locates:located                       |
      | contractor-locates:contractor-located |

  Scenario: Relation types cannot redeclare inherited/overridden playing role types
    When put relation type: locates
    When relation(locates) set relates role: located
    When put relation type: contractor-locates
    When relation(contractor-locates) set supertype: locates
    When relation(contractor-locates) set relates role: contractor-located as located
    When put relation type: employment
    When relation(employment) set relates role: employee
    When relation(employment) set plays role: locates:located
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    When relation(contractor-employment) set plays role: contractor-locates:contractor-located as located
    When put relation type: parttime-employment
    When relation(parttime-employment) set supertype: contractor-employment
    Then relation(parttime-employment) fails at setting plays role: locates:located
    Then relation(parttime-employment) fails at setting plays role: contractor-locates:contractor-located

  Scenario: Relation types cannot override declared playing role types
    When put relation type: locates
    When relation(locates) set relates role: locating
    When relation(locates) set relates role: located
    When put relation type: employment-locates
    When relation(employment-locates) set supertype: locates
    When relation(employment-locates) set relates role: employment-locating as locating
    When relation(employment-locates) set relates role: employment-located as located
    When put relation type: employment
    When relation(employment) set relates role: employer
    When relation(employment) set relates role: employee
    When relation(employment) set plays role: locates:located
    Then relation(employment) fails at setting plays role: employment-locates:employment-located as locates:located

  Scenario: Relation types cannot override inherited playing role types other than with their subtypes
    When put relation type: locates
    When relation(locates) set relates role: locating
    When relation(locates) set relates role: located
    When put relation type: contractor-locates
    When relation(contractor-locates) set relates role: contractor-locating
    When relation(contractor-locates) set relates role: contractor-located
    When put relation type: employment
    When relation(employment) set relates role: employer
    When relation(employment) set relates role: employee
    When relation(employment) set plays role: locates:located
    When put relation type: contractor-employment
    When relation(contractor-employment) set supertype: employment
    Then relation(contractor-employment) fails at setting plays role: contractor-locates:contractor-located as locates:located
