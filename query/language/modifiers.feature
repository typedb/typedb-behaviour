# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

Feature: TypeQL Query Modifiers

  Background: Open connection and create a simple extensible schema
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection reset database: typedb
    Given connection open schema transaction for database: typedb

    Given typeql schema query
      """
      define
      entity person,
        plays friendship:friend,
        plays employment:employee,
        owns name,
        owns age,
        owns ref @key,
        owns email;
      entity company,
        plays employment:employer,
        owns name,
        owns ref @key;
      relation friendship,
        relates friend,
        owns ref @key;
      relation employment,
        relates employee,
        relates employer,
        owns ref @key;
      attribute name @independent, value string;
      attribute age, value long;
      attribute ref, value long;
      attribute email, value string;
      """
    Given transaction commits

  # ------------- read queries -------------

  ########
  # SORT #
  ########

  Scenario Outline: the answers of a match can be sorted by an attribute of type '<type>'
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute <attr> @independent, value <type>;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $a <val1> isa <attr>;
      $b <val2> isa <attr>;
      $c <val3> isa <attr>;
      $d <val4> isa <attr>;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa <attr>;
      sort $x asc;
      """
    Then order of answer concepts is
      | x                  |
      | attr:<attr>:<val4> |
      | attr:<attr>:<val2> |
      | attr:<attr>:<val3> |
      | attr:<attr>:<val1> |

    Examples:
      | attr          | type     | val4       | val2             | val3             | val1       |
      | colour        | string   | "blue"     | "green"          | "red"            | "yellow"   |
      | score         | long     | -38        | -4               | 18               | 152        |
      | correlation   | double   | -29.7      | -0.9             | 0.01             | 100.0      |
#      | date-of-birth | datetime | 1970-01-01 | 1999-12-31T23:00 | 1999-12-31T23:01 | 2020-02-29 |


  Scenario: sort order can be ascending or descending
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d isa person, has name "Brenda", has ref 3;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has name $y;
      sort $y asc;
      """
    Then order of answer concepts is
      | x         | y                    |
      | key:ref:3 | attr:name:Brenda     |
      | key:ref:2 | attr:name:Frederick  |
      | key:ref:0 | attr:name:Gary       |
      | key:ref:1 | attr:name:Jemima     |
    When get answers of typeql read query
      """
      match $x isa person, has name $y;
      sort $y desc;
      """
    Then order of answer concepts is
      | x         | y                    |
      | key:ref:1 | attr:name:Jemima     |
      | key:ref:0 | attr:name:Gary       |
      | key:ref:2 | attr:name:Frederick  |
      | key:ref:3 | attr:name:Brenda     |


  Scenario: the default sort order is ascending
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d isa person, has name "Brenda", has ref 3;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has name $y;
      sort $y;
      """
    Then order of answer concepts is
      | x         | y                    |
      | key:ref:3 | attr:name:Brenda     |
      | key:ref:2 | attr:name:Frederick  |
      | key:ref:0 | attr:name:Gary       |
      | key:ref:1 | attr:name:Jemima     |


  Scenario: Sorting on value variables is supported
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $a isa person, has age 18, has ref 0;
      $b isa person, has age 14, has ref 1;
      $c isa person, has age 20, has ref 2;
      $d isa person, has age 16, has ref 3;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $x isa person, has age $a;
        $to20 = 20 - $a;
      sort
        $to20 desc;
      """
    Then order of answer concepts is
      | x         | to20         |
      | key:ref:1 | value:long:6 |
      | key:ref:3 | value:long:4 |
      | key:ref:0 | value:long:2 |
      | key:ref:2 | value:long:0 |


  Scenario: multiple sort variables may be used to sort ascending
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $a isa person, has name "Gary", has ref 0, has age 15;
      $b isa person, has name "Gary", has ref 1, has age 5;
      $c isa person, has name "Gary", has ref 2, has age 25;
      $d isa person, has name "Brenda", has ref 3, has age 12;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has name $y, has ref $r, has age $a;
      sort $y, $a, $r asc;
      """
    Then order of answer concepts is
      | y                 |  a           | x         |
      | attr:name:Brenda  | attr:age:12  | key:ref:3 |
      | attr:name:Gary    | attr:age:5   | key:ref:1 |
      | attr:name:Gary    | attr:age:15  | key:ref:0 |
      | attr:name:Gary    | attr:age:25  | key:ref:2 |


  Scenario: multiple sort variables may be used to sort ascending or descending
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $a isa person, has name "Gary", has ref 0, has age 15;
      $b isa person, has name "Gary", has ref 1, has age 5;
      $c isa person, has name "Gary", has ref 2, has age 25;
      $d isa person, has name "Brenda", has ref 3, has age 12;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has name $y, has ref $r, has age $a;
      sort $y asc, $a desc, $r desc;
      """
    Then order of answer concepts is
      | y                 |  a           | x         |
      | attr:name:Brenda  | attr:age:12  | key:ref:3 |
      | attr:name:Gary    | attr:age:25  | key:ref:2 |
      | attr:name:Gary    | attr:age:15  | key:ref:0 |
      | attr:name:Gary    | attr:age:5   | key:ref:1 |


  Scenario: a sorted result set can be limited to a specific size
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d isa person, has name "Brenda", has ref 3;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has name $y;
      sort $y asc;
      limit 3;
      """
    Then order of answer concepts is
      | x         | y                    |
      | key:ref:3 | attr:name:Brenda     |
      | key:ref:2 | attr:name:Frederick  |
      | key:ref:0 | attr:name:Gary       |


  Scenario: sorted results can be retrieved starting from a specific offset
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d isa person, has name "Brenda", has ref 3;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has name $y;
      sort $y asc;
      offset 2;
      """
    Then order of answer concepts is
      | x         | y                 |
      | key:ref:0 | attr:name:Gary    |
      | key:ref:1 | attr:name:Jemima  |


  Scenario: 'offset' and 'limit' can be used together to restrict the answer set
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d isa person, has name "Brenda", has ref 3;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has name $y;
      sort $y asc;
      offset 1;
      limit 2;
      """
    Then order of answer concepts is
      | x         | y                    |
      | key:ref:2 | attr:name:Frederick  |
      | key:ref:0 | attr:name:Gary       |


  Scenario: when the answer size is limited to 0, an empty answer set is returned
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d isa person, has name "Brenda", has ref 3;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has name $y;
      sort $y asc;
      limit 0;
      """
    Then answer size is: 0


  Scenario: when the offset is outside the bounds of the matched answer set, an empty answer set is returned
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d isa person, has name "Brenda", has ref 3;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has name $y;
      sort $y asc;
      offset 5;
      """
    Then answer size is: 0


  Scenario: string sorting is case-sensitive
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $a "Bond" isa name;
      $b "James Bond" isa name;
      $c "007" isa name;
      $d "agent" isa name;
      $e "secret agent" isa name;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Then get answers of typeql read query
      """
      match $x isa name;
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
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $a isa person, has age 2, has ref 0;
      $b isa person, has age 6, has ref 1;
      $c isa person, has age 12, has ref 2;
      $d isa person, has age 6, has ref 3;
      $e isa person, has age 2, has ref 4;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has age $y;
      sort $y asc;
      limit 2;
      """
    Then order of answer concepts is
      | x         | y           |
      | key:ref:0 | attr:age:2  |
      | key:ref:4 | attr:age:2  |
    When get answers of typeql read query
      """
      match $x isa person, has age $y;
      sort $y asc;
      offset 2;
      limit 2;
      """
    Then order of answer concepts is
      | x         | y           |
      | key:ref:1 | attr:age:6  |
      | key:ref:3 | attr:age:6  |


  Scenario: when sorting by a variable not contained in the answer set, an error is thrown
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $a isa person, has age 2, has ref 0;
      $b isa person, has age 6, has ref 1;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Then typeql read query; fails
      """
      match
        $x isa person, has age $y;
      select $x;
      sort $y asc;
      limit 2;
      """

  Scenario: when sorting by a variable that may contain incomparable values, an error is thrown
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $a isa person, has age 2, has name "Abby", has ref 0;
      $b isa person, has age 6, has name "Bobby", has ref 1;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Then typeql read query; fails
      """
      match
        $x isa person, has $a;
      sort $a asc;
      """


  Scenario Outline: sorting and query predicates agree for type '<type>'
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute <attr> @independent, value <type>;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $a <pivot> isa <attr>;
      $b <lesser> isa <attr>;
      $c <greater> isa <attr>;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb

    # ascending
    When get answers of typeql read query
      """
      match $x isa <attr>; $x < <pivot>;
      sort $x asc;
      """
    Then order of answer concepts is
      | x                    |
      | attr:<attr>:<lesser> |

    When get answers of typeql read query
      """
      match $x isa <attr>; $x <= <pivot>;
      sort $x asc;
      """
    Then order of answer concepts is
      | x                    |
      | attr:<attr>:<lesser> |
      | attr:<attr>:<pivot>  |

    When get answers of typeql read query
      """
      match $x isa <attr>; $x > <pivot>;
      sort $x asc;
      """
    Then order of answer concepts is
      | x                     |
      | attr:<attr>:<greater> |

    When get answers of typeql read query
      """
      match $x isa <attr>; $x >= <pivot>;
      sort $x asc;
      """
    Then order of answer concepts is
      | x                     |
      | attr:<attr>:<pivot>   |
      | attr:<attr>:<greater> |

    # descending
    When get answers of typeql read query
      """
      match $x isa <attr>; $x < <pivot>;
      sort $x desc;
      """
    Then order of answer concepts is
      | x                    |
      | attr:<attr>:<lesser> |

    When get answers of typeql read query
      """
      match $x isa <attr>; $x <= <pivot>;
      sort $x desc;
      """
    Then order of answer concepts is
      | x                    |
      | attr:<attr>:<pivot>  |
      | attr:<attr>:<lesser> |

    When get answers of typeql read query
      """
      match $x isa <attr>; $x > <pivot>;
      sort $x desc;
      """
    Then order of answer concepts is
      | x                     |
      | attr:<attr>:<greater> |

    When get answers of typeql read query
      """
      match $x isa <attr>; $x >= <pivot>;
      select;
      sort $x desc;
      """
    Then order of answer concepts is
      | x                     |
      | attr:<attr>:<greater> |
      | attr:<attr>:<pivot>   |

    Examples:
      | attr          | type     | pivot      | lesser       | greater          |
      | colour        | string   | "green"    | "blue"       | "red"            |
      | score         | long     | -4         | -38          | 18               |
      | correlation   | double   | -0.9       | -1.2         | 0.01             |
      | date-of-birth | datetime | 1970-02-01 |  1970-01-01  | 1999-12-31T23:01 |


  Scenario Outline: sorting and query predicates produce order ignoring types
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute <firstAttr>, value <firstType>;
      attribute  <secondAttr>, value <secondType>;
      attribute <thirdAttr>, value <thirdType>;
      attribute <fourthAttr>, value <fourthType>;
      entity owner,
        owns <firstAttr>,
        owns <secondAttr>,
        owns <thirdAttr>,
        owns <fourthAttr>,
        owns ref @key;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $first1 isa owner, has <firstAttr> <firstValue1>, has ref 0;
      $first2 isa owner, has <firstAttr> <firstValue2>, has ref 1;
      $second isa owner, has <secondAttr> <secondValue>, has ref 2;
      $third isa owner, has <thirdAttr> <thirdValue>, has ref 3;
      $fourth isa owner, has <fourthAttr> <fourthValuePivot>, has ref 4;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb

    # ascending
    When get answers of typeql read query
      """
      match $o isa owner, has $x;
#      sort $x asc;
#      select $o;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:2 |
      | key:ref:1 |
      | key:ref:4 |
      | key:ref:0 |
      | key:ref:3 |

    When get answers of typeql read query
      """
      match $o isa owner, has $x; $x < <fourthValuePivot>;
      sort $x asc;
      select $o;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:2 |
      | key:ref:1 |

    When get answers of typeql read query
      """
      match $o isa owner, has $x; $x <= <fourthValuePivot>;
      sort $x asc;
      select $o;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:2 |
      | key:ref:1 |
      | key:ref:4 |

    When get answers of typeql read query
      """
      match $o isa owner, has $x; $x > <fourthValuePivot>;
      sort $x asc;
      select $o;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:0 |
      | key:ref:3 |

    When get answers of typeql read query
      """
      match $o isa owner, has $x; $x >= <fourthValuePivot>;
      sort $x asc;
      select $o;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:4 |
      | key:ref:0 |
      | key:ref:3 |

    # descending
    When get answers of typeql read query
      """
      match $o isa owner, has $x;
      sort $x desc;
      select $o;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:3 |
      | key:ref:0 |
      | key:ref:4 |
      | key:ref:1 |
      | key:ref:2 |

    When get answers of typeql read query
      """
      match $o isa owner, has $x; $x < <fourthValuePivot>;
      sort $x desc;
      select $o;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:1 |
      | key:ref:2 |

    When get answers of typeql read query
      """
      match $o isa owner, has $x; $x <= <fourthValuePivot>;
      sort $x desc;
      select $o;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:4 |
      | key:ref:1 |
      | key:ref:2 |

    When get answers of typeql read query
      """
      match $o isa owner, has $x; $x > <fourthValuePivot>;
      sort $x desc;
      select $o;
      """
    Then order of answer concepts is
      | x         |
      | key:ref:3 |
      | key:ref:0 |

    When get answers of typeql read query
      """
      match $o isa owner, has $x; $x >= <fourthValuePivot>;
      sort $x desc;
      select $o;
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


  Scenario: Fetch queries can use sort, offset, limit
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has name "Freddy", has email "frederick@gmail.com", has ref 2;
      $d isa person, has name "Brenda", has email "brenda@gmail.com", has ref 3;
      """
    Given transaction commits
    Given connection open read transaction for database: typedb
    When typeql fetch
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
              { "type": { "label": "name", "root": "attribute", "value_type": "string" }, "value": "Frederick" },
              { "type": { "label": "name", "root": "attribute", "value_type": "string" }, "value": "Freddy" }
            ],
            "email": [ { "type": { "label": "email", "root": "attribute", "value_type": "string" }, "value": "frederick@gmail.com" } ]
          },
          "ref": { "type" : { "label": "ref", "root": "attribute", "value_type": "long" }, "value": 2 }
        },
        {
          "person": {
            "type":  { "label": "person", "root": "entity" },
            "name": [ { "type": { "label": "name", "root": "attribute", "value_type": "string" }, "value": "Jemima" } ],
            "email": [ ]
          },
          "ref": { "type" : { "label": "ref", "root": "attribute", "value_type": "long" }, "value" : 1 }
        }
      ]
      """

  # ------------- write queries -------------

  Scenario: Match insert queries can use sort, offset, limit
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d1 isa person, has name "Brenda", has ref 3;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When get answers of typeql write query
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
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d1 isa person, has name "Brenda", has ref 3;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      match
      $x isa person, has ref $r, has name $n;
      sort $r; offset 1; limit 2;
      delete
      has $n of $x;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Then get answers of typeql read query
      """
      match
      $x isa person, has name $n;
      sort $n;
      """
    Then uniquely identify answer concepts
      | x         | n                   |
      | key:ref:3 | attr:name:Brenda    |
      | key:ref:0 | attr:name:Gary      |



  Scenario: Match update queries can use sort, offset, limit
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $a isa person, has name "Gary", has ref 0;
      $b isa person, has name "Jemima", has ref 1;
      $c isa person, has name "Frederick", has ref 2;
      $d1 isa person, has name "Brenda", has ref 3;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      match
      $x isa person, has ref $r, has name $n;
      sort $r; offset 1; limit 2;
      delete
      has $n of $x;
      insert
      $x has email "dummy@gmail.com";
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Then get answers of typeql read query
      """
      match
      $x isa person, has email "dummy@gmail.com";
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:1 |
      | key:ref:2 |


  ##########
  # SELECT #
  ##########

  Scenario: 'select' can be used to restrict the set of variables that appear in an answer set
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x "Lisa" isa name;
      $y 16 isa age;
      $z isa person, has name $x, has age $y, has ref 0;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $z isa person, has name $x, has age $y;
      select $z, $x;
      """
    Then uniquely identify answer concepts
      | z         | x               |
      | key:ref:0 | attr:name:Lisa  |


  Scenario: when a 'select' has unbound variables, an error is thrown
    Given connection open read transaction for database: typedb
    Then typeql read query; fails
      """
      match $x isa person; select $y;
      """


  Scenario: Value variables can be specified in a 'select'
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x "Lisa" isa name;
      $y 16 isa age;
      $z isa person, has name $x, has age $y, has ref 0;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $z isa person, has name $x, has age $y;
        $b = 2017 - $y;
      select $z, $x, $b;
      """
    Then uniquely identify answer concepts
      | z         | x              | b                |
      | key:ref:0 | attr:name:Lisa | value:long:2001  |


  # Guards against regression of #6967
  Scenario: A 'select' filter is applied after negations
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $p1 isa person, has name "Klaus", has ref 0;
      $p2 isa person, has name "Kristina", has ref 1;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $p isa person, has name $n, has ref $r;
        $n == "Klaus";
        not { $p has name "Kristina"; };
      select $n, $r;
      """
    Then uniquely identify answer concepts
      | n               | r               |
      | attr:name:Klaus | attr:ref:0      |

    When get answers of typeql read query
      """
      match
        $p isa person, has name $n, has ref $r;
        $n == "Klaus";
        not { $p has name "Kristina"; };
      select $n, $r;
      sort $r; # The sort triggered the bug
      """
    Then uniquely identify answer concepts
      | n               | r               |
      | attr:name:Klaus | attr:ref:0      |

