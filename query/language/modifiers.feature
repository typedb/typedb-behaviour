#
# Copyright (C) 2022 Vaticle
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

Feature: TypeQL Query Modifiers

  Background: Open connection and create a simple extensible schema
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write

    Given typeql define
      """
      define
      person sub entity,
        plays friendship:friend,
        plays employment:employee,
        owns name,
        owns age,
        owns ref @key,
        owns email;
      company sub entity,
        plays employment:employer,
        owns name,
        owns ref @key;
      friendship sub relation,
        relates friend,
        owns ref @key;
      employment sub relation,
        relates employee,
        relates employer,
        owns ref @key;
      name sub attribute, value string;
      age sub attribute, value long;
      ref sub attribute, value long;
      email sub attribute, value string;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write

  # ------------- read queries -------------

  ########
  # SORT #
  ########

  Scenario Outline: the answers of a match can be sorted by an attribute of type '<type>'
    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Given typeql define
      """
      define
      <attr> sub attribute, value <type>, owns ref @key;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $a <val1> isa <attr>, has ref 0;
      $b <val2> isa <attr>, has ref 1;
      $c <val3> isa <attr>, has ref 2;
      $d <val4> isa <attr>, has ref 3;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x isa <attr>;
      get;
      sort $x asc;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:3 |
      | key:ref:1 |
      | key:ref:2 |
      | key:ref:0 |

    Examples:
      | attr          | type     | val4       | val2             | val3             | val1       |
      | colour        | string   | "blue"     | "green"          | "red"            | "yellow"   |
      | score         | long     | -38        | -4               | 18               | 152        |
      | correlation   | double   | -29.7      | -0.9             | 0.01             | 100.0      |
      | date-of-birth | datetime | 1970-01-01 | 1999-12-31T23:00 | 1999-12-31T23:01 | 2020-02-29 |


  Scenario: sort order can be ascending or descending
    Given typeql insert
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d isa person, has name "Brenda", has ref 3;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x isa person, has name $y;
      get;
      sort $y asc;
      """
    Then order of answer concepts is
      | x         | y                    |
      | key:ref:3 | attr:name:Brenda     |
      | key:ref:2 | attr:name:Frederick  |
      | key:ref:0 | attr:name:Gary       |
      | key:ref:1 | attr:name:Jemima     |
    When get answers of typeql get
      """
      match $x isa person, has name $y;
      get;
      sort $y desc;
      """
    Then order of answer concepts is
      | x         | y                    |
      | key:ref:1 | attr:name:Jemima     |
      | key:ref:0 | attr:name:Gary       |
      | key:ref:2 | attr:name:Frederick  |
      | key:ref:3 | attr:name:Brenda     |


  Scenario: the default sort order is ascending
    Given typeql insert
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d isa person, has name "Brenda", has ref 3;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x isa person, has name $y;
      get;
      sort $y;
      """
    Then order of answer concepts is
      | x         | y                    |
      | key:ref:3 | attr:name:Brenda     |
      | key:ref:2 | attr:name:Frederick  |
      | key:ref:0 | attr:name:Gary       |
      | key:ref:1 | attr:name:Jemima     |


  Scenario: Sorting on value variables is supported
    Given typeql insert
      """
      insert
      $a isa person, has age 18, has ref 0;
      $b isa person, has age 14, has ref 1;
      $c isa person, has age 20, has ref 2;
      $d isa person, has age 16, has ref 3;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match
        $x isa person, has age $a;
        ?to20 = 20 - $a;
      get;
      sort
        ?to20 desc;
      """
    Then order of answer concepts is
      | x         | to20         |
      | key:ref:1 | value:long:6 |
      | key:ref:3 | value:long:4 |
      | key:ref:0 | value:long:2 |
      | key:ref:2 | value:long:0 |


  Scenario: multiple sort variables may be used to sort ascending
    Given typeql insert
      """
      insert
      $a isa person, has name "Gary", has ref 0, has age 15;
      $b isa person, has name "Gary", has ref 1, has age 5;
      $c isa person, has name "Gary", has ref 2, has age 25;
      $d isa person, has name "Brenda", has ref 3, has age 12;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x isa person, has name $y, has ref $r, has age $a;
      get;
      sort $y, $a, $r asc;
      """
    Then order of answer concepts is
      | y                 |  a           | x         |
      | attr:name:Brenda  | attr:age:12  | key:ref:3 |
      | attr:name:Gary    | attr:age:5   | key:ref:1 |
      | attr:name:Gary    | attr:age:15  | key:ref:0 |
      | attr:name:Gary    | attr:age:25  | key:ref:2 |


  Scenario: multiple sort variables may be used to sort ascending or descending
    Given typeql insert
      """
      insert
      $a isa person, has name "Gary", has ref 0, has age 15;
      $b isa person, has name "Gary", has ref 1, has age 5;
      $c isa person, has name "Gary", has ref 2, has age 25;
      $d isa person, has name "Brenda", has ref 3, has age 12;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x isa person, has name $y, has ref $r, has age $a;
      get;
      sort $y asc, $a desc, $r desc;
      """
    Then order of answer concepts is
      | y                 |  a           | x         |
      | attr:name:Brenda  | attr:age:12  | key:ref:3 |
      | attr:name:Gary    | attr:age:25  | key:ref:2 |
      | attr:name:Gary    | attr:age:15  | key:ref:0 |
      | attr:name:Gary    | attr:age:5   | key:ref:1 |


  Scenario: a sorted result set can be limited to a specific size
    Given typeql insert
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d isa person, has name "Brenda", has ref 3;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x isa person, has name $y;
      get;
      sort $y asc;
      limit 3;
      """
    Then order of answer concepts is
      | x         | y                    |
      | key:ref:3 | attr:name:Brenda     |
      | key:ref:2 | attr:name:Frederick  |
      | key:ref:0 | attr:name:Gary       |


  Scenario: sorted results can be retrieved starting from a specific offset
    Given typeql insert
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d isa person, has name "Brenda", has ref 3;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x isa person, has name $y;
      get;
      sort $y asc;
      offset 2;
      """
    Then order of answer concepts is
      | x         | y                 |
      | key:ref:0 | attr:name:Gary    |
      | key:ref:1 | attr:name:Jemima  |


  Scenario: 'offset' and 'limit' can be used together to restrict the answer set
    Given typeql insert
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d isa person, has name "Brenda", has ref 3;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x isa person, has name $y;
      get;
      sort $y asc;
      offset 1;
      limit 2;
      """
    Then order of answer concepts is
      | x         | y                    |
      | key:ref:2 | attr:name:Frederick  |
      | key:ref:0 | attr:name:Gary       |


  Scenario: when the answer size is limited to 0, an empty answer set is returned
    Given typeql insert
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d isa person, has name "Brenda", has ref 3;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x isa person, has name $y;
      get;
      sort $y asc;
      limit 0;
      """
    Then answer size is: 0


  Scenario: when the offset is outside the bounds of the matched answer set, an empty answer set is returned
    Given typeql insert
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d isa person, has name "Brenda", has ref 3;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x isa person, has name $y;
      get;
      sort $y asc;
      offset 5;
      """
    Then answer size is: 0


  Scenario: string sorting is case-sensitive
    Given typeql insert
      """
      insert
      $a "Bond" isa name;
      $b "James Bond" isa name;
      $c "007" isa name;
      $d "agent" isa name;
      $e "secret agent" isa name;
      """
    Given transaction commits

    Given session opens transaction of type: read
    Then get answers of typeql get
      """
      match $x isa name;
      get;
      sort $x asc;
      """
    Then order of answer concepts is
      | x                       |
      | attr:name:007           |
      | attr:name:Bond          |
      | attr:name:James Bond    |
      | attr:name:agent         |
      | attr:name:secret agent  |


  Scenario: sort is able to correctly handle duplicates in the value set
    Given typeql insert
      """
      insert
      $a isa person, has age 2, has ref 0;
      $b isa person, has age 6, has ref 1;
      $c isa person, has age 12, has ref 2;
      $d isa person, has age 6, has ref 3;
      $e isa person, has age 2, has ref 4;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql get
      """
      match $x isa person, has age $y;
      get;
      sort $y asc;
      limit 2;
      """
    Then uniquely identify answer concepts
      | x         | y           |
      | key:ref:0 | attr:age:2  |
      | key:ref:4 | attr:age:2  |
    When get answers of typeql get
      """
      match $x isa person, has age $y;
      get;
      sort $y asc;
      offset 2;
      limit 2;
      """
    Then uniquely identify answer concepts
      | x         | y           |
      | key:ref:1 | attr:age:6  |
      | key:ref:3 | attr:age:6  |


  Scenario: when sorting by a variable not contained in the answer set, an error is thrown
    Given typeql insert
      """
      insert
      $a isa person, has age 2, has ref 0;
      $b isa person, has age 6, has ref 1;
      """
    Given transaction commits

    Given session opens transaction of type: read
    Then typeql get; throws exception
      """
      match
        $x isa person, has age $y;
      get $x;
      sort $y asc;
      limit 2;
      """

  Scenario: when sorting by a variable that may contain incomparable values, an error is thrown
    Given typeql insert
      """
      insert
      $a isa person, has age 2, has name "Abby", has ref 0;
      $b isa person, has age 6, has name "Bobby", has ref 1;
      """
    Given transaction commits

    Given session opens transaction of type: read
    Then typeql get; throws exception
      """
      match
        $x isa person, attribute $a;
      get;
      sort $a asc;
      """


  Scenario Outline: sorting and query predicates agree for type '<type>'
    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Given typeql define
      """
      define
      <attr> sub attribute, value <type>, owns ref @key;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $a <pivot> isa <attr>, has ref 0;
      $b <lesser> isa <attr>, has ref 1;
      $c <greater> isa <attr>, has ref 2;
      """
    Given transaction commits

    Given session opens transaction of type: read

    # ascending
    When get answers of typeql get
      """
      match $x isa <attr>; $x < <pivot>;
      get;
      sort $x asc;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:1 |

    When get answers of typeql get
      """
      match $x isa <attr>; $x <= <pivot>;
      get;
      sort $x asc;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:1 |
      | key:ref:0 |

    When get answers of typeql get
      """
      match $x isa <attr>; $x > <pivot>;
      get;
      sort $x asc;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:2 |

    When get answers of typeql get
      """
      match $x isa <attr>; $x >= <pivot>;
      get;
      sort $x asc;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:0 |
      | key:ref:2 |

    # descending
    When get answers of typeql get
      """
      match $x isa <attr>; $x < <pivot>;
      get;
      sort $x desc;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:1 |

    When get answers of typeql get
      """
      match $x isa <attr>; $x <= <pivot>;
      get;
      sort $x desc;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:0 |
      | key:ref:1 |

    When get answers of typeql get
      """
      match $x isa <attr>; $x > <pivot>;
      get;
      sort $x desc;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:2 |

    When get answers of typeql get
      """
      match $x isa <attr>; $x >= <pivot>;
      get;
      sort $x desc;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:2 |
      | key:ref:0 |

    Examples:
      | attr          | type     | pivot      | lesser       | greater          |
      | colour        | string   | "green"    | "blue"       | "red"            |
      | score         | long     | -4         | -38          | 18               |
      | correlation   | double   | -0.9       | -1.2         | 0.01             |
      | date-of-birth | datetime | 1970-02-01 |  1970-01-01  | 1999-12-31T23:01 |


  Scenario Outline: sorting and query predicates produce order ignoring types
    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Given typeql define
      """
      define
      <firstAttr> sub attribute, value <firstType>, owns ref @key;
      <secondAttr> sub attribute, value <secondType>, owns ref @key;
      <thirdAttr> sub attribute, value <thirdType>, owns ref @key;
      <fourthAttr> sub attribute, value <fourthType>, owns ref @key;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    Given typeql insert
      """
      insert
      $first1 <firstValue1> isa <firstAttr>, has ref 0;
      $first2 <firstValue2> isa <firstAttr>, has ref 1;
      $second <secondValue> isa <secondAttr>, has ref 2;
      $third <thirdValue> isa <thirdAttr>, has ref 3;
      $fourth <fourthValuePivot> isa <fourthAttr>, has ref 4;
      """
    Given transaction commits

    Given session opens transaction of type: read

    # ascending
    When get answers of typeql get
      """
      match $x isa $t; $t owns ref;
      get $x;
      sort $x asc;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:2 |
      | key:ref:1 |
      | key:ref:4 |
      | key:ref:0 |
      | key:ref:3 |

    When get answers of typeql get
      """
      match $x isa $t; $t owns ref; $x < <fourthValuePivot>;
      get $x;
      sort $x asc;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:2 |
      | key:ref:1 |

    When get answers of typeql get
      """
      match $x isa $t; $t owns ref; $x <= <fourthValuePivot>;
      get $x;
      sort $x asc;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:2 |
      | key:ref:1 |
      | key:ref:4 |

    When get answers of typeql get
      """
      match $x isa $t; $t owns ref; $x > <fourthValuePivot>;
      get $x;
      sort $x asc;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:0 |
      | key:ref:3 |

    When get answers of typeql get
      """
      match $x isa $t; $t owns ref; $x >= <fourthValuePivot>;
      get $x;
      sort $x asc;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:4 |
      | key:ref:0 |
      | key:ref:3 |

    # descending
    When get answers of typeql get
      """
      match $x isa $t; $t owns ref;
      get $x;
      sort $x desc;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:3 |
      | key:ref:0 |
      | key:ref:4 |
      | key:ref:1 |
      | key:ref:2 |

    When get answers of typeql get
      """
      match $x isa $t; $t owns ref; $x < <fourthValuePivot>;
      get $x;
      sort $x desc;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:1 |
      | key:ref:2 |

    When get answers of typeql get
      """
      match $x isa $t; $t owns ref; $x <= <fourthValuePivot>;
      get $x;
      sort $x desc;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:4 |
      | key:ref:1 |
      | key:ref:2 |

    When get answers of typeql get
      """
      match $x isa $t; $t owns ref; $x > <fourthValuePivot>;
      get $x;
      sort $x desc;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:3 |
      | key:ref:0 |

    When get answers of typeql get
      """
      match $x isa $t; $t owns ref; $x >= <fourthValuePivot>;
      get $x;
      sort $x desc;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:3 |
      | key:ref:0 |
      | key:ref:4 |

    Examples:
      # NOTE: fourthValuePivot is expected to be the middle of the sort order (pivot)
      | firstAttr   | firstType | firstValue1 | firstValue2 | secondAttr | secondType | secondValue | thirdAttr | thirdType | thirdValue | fourthAttr | fourthType | fourthValuePivot |
      | colour      | string    | "green"     | "blue"      | name       | string     | "alice"     | shape     | string    | "square"   | street     | string     | "carnaby"        |
      | score       | long      | 4           | -38         | quantity   | long       | -50         | area      | long      | 100        | length     | long       | 0                |
      | correlation | double    | 4.1         | -38.999     | quantity   | double     | -101.4      | area      | double    | 110.0555   | length     | double     | 0.5              |
      # mixed double-long data
      | score       | long      | 4           | -38         | quantity   | double     | -55.123     | area      | long      | 100        | length     | double     | 0.5              |
      | dob         | datetime  | 2970-01-01   | 1970-02-01 | start-date | datetime   | 1970-01-01  | end-date  | datetime  | 3100-11-20 | last-date  | datetime   | 2000-08-03       |


  Scenario: Get group variable does not have to match sort variable
    Given typeql insert
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d1 isa person, has name "Brenda", has ref 3;
      $d2 isa person, has name "Brenda", has ref 4;
      """
    Given transaction commits
    Given session opens transaction of type: read
    When get answers of typeql get group
      """
      match $x isa person, has ref $r, has name $n;
      get $r, $n;
      sort $r desc;
      group $n;
      """
    Then answer groups are
      | owner               | r          |
      | attr:name:Brenda    | attr:ref:4 |
      | attr:name:Brenda    | attr:ref:3 |
      | attr:name:Frederick | attr:ref:2 |
      | attr:name:Jemima    | attr:ref:1 |
      | attr:name:Gary      | attr:ref:0 |


  Scenario: Get group queries can use sort, offset, limit
    Given typeql insert
      """
      insert
      $d isa person, has name "Brenda", has ref 3;
      $c isa person, has name "Frederick", has ref 2;
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      """
    Given transaction commits
    Given session opens transaction of type: read
    When get answers of typeql get group
      """
      match $x isa person, has name $y;
      get $x, $y;
      sort $y asc; offset 1; limit 2;
      group $y;
      """
    Then answer groups are
      | owner               | x         |
      | attr:name:Frederick | key:ref:2 |
      | attr:name:Gary      | key:ref:0 |


  Scenario: Fetch queries can use sort, offset, limit
    Given typeql insert
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has name "Freddy", has email "frederick@gmail.com", has ref 2;
      $d isa person, has name "Brenda", has email "brenda@gmail.com", has ref 3;
      """
    Given transaction commits
    Given session opens transaction of type: read
    When get answers of typeql fetch
      """
      match $x isa person, has ref $r;
      fetch
      $x as person: name, email;
      $r as ref;
      sort $r desc; offset 1; limit 2;
      """
    Then fetch answers are
      """
      [
        {
          "person": {
            "type": { "label": "person", "root": "entity" },
            "name": [
              { "type": { "label": "name", "root": "attribute" }, "value": "Frederick", "value_type": "string" },
              { "type": { "label": "name", "root": "attribute" }, "value": "Freddy", "value_type": "string" }
            ],
            "email": [ { "type": { "label": "email", "root": "attribute" }, "value": "frederick@gmail.com", "value_type": "string" } ]
          },
          "ref": { "type" : { "label": "ref", "root": "attribute" }, "value": 2, "value_type": "long" }
        },
        {
          "person": {
            "type":  { "label": "person", "root": "entity" },
            "name": [ { "type": { "label": "name", "root": "attribute" }, "value": "Jemima", "value_type": "string" } ],
            "email": [ ]
          },
          "ref": { "type" : { "label": "ref", "root": "attribute" }, "value" : 1, "value_type": "long" }
        }
      ]
      """

  # ------------- write queries -------------

  Scenario: Match insert queries can use sort, offset, limit
    Given typeql insert
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d1 isa person, has name "Brenda", has ref 3;
      """
    Given transaction commits
    Given session opens transaction of type: write

    When get answers of typeql insert
      """
      match
      $x isa person, has ref $r;
      insert
      $x has email "dummy@gmail.com";
      sort $r; offset 1; limit 2;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:1 |
      | key:ref:2 |


  Scenario: Match delete queries can use sort, offset, limit
    Given typeql insert
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d1 isa person, has name "Brenda", has ref 3;
      """
    Given transaction commits
    Given session opens transaction of type: write

    When typeql delete
      """
      match
      $x isa person, has ref $r, has name $n;
      delete
      $x has $n;
      sort $r; offset 1; limit 2;
      """
    Given transaction commits

    Given session opens transaction of type: read
    Then get answers of typeql get
      """
      match
      $x isa person, has name $n;
      get;
      sort $n;
      """
    Then uniquely identify answer concepts
      | x         | n                   |
      | key:ref:3 | attr:name:Brenda    |
      | key:ref:0 | attr:name:Gary      |



  Scenario: Match update queries can use sort, offset, limit
    Given typeql insert
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d1 isa person, has name "Brenda", has ref 3;
      """
    Given transaction commits
    Given session opens transaction of type: write

    When typeql update
      """
      match
      $x isa person, has ref $r, has name $n;
      delete
      $x has $n;
      insert
      $x has email "dummy@gmail.com";
      sort $r; offset 1; limit 2;
      """
    Given transaction commits

    Given session opens transaction of type: read
    Then get answers of typeql get
      """
      match
      $x isa person, has email "dummy@gmail.com";
      get;
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:1 |
      | key:ref:2 |
