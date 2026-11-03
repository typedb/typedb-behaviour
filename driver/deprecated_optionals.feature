# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# These tests are dedicated to test the required query functionality of TypeDB drivers. The files in this package
# can be used to test any client application which aims to support all the operations presented in this file for the
# complete user experience. The following steps are suitable and strongly recommended for both CORE and CLOUD drivers.
# NOTE: for complete guarantees, all the drivers are also expected to cover the `connection` package.

#noinspection CucumberUndefinedStep
Feature: Driver Query with old optional behaviour

  Background: Open connection, create driver, create database
    Given typedb starts
    Given connection is open: false
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases
    Given connection create database: typedb
    Given connection has database: typedb

  Scenario: Driver processes query given rows correctly
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
          define
            entity person owns name @card(0..), owns age @card(0..);
            attribute name, value string;
            attribute age, value integer;
          """
    Given transaction commits
    
    Given connection open write transaction for database: typedb
    Given get answers of typeql write query
    """
          insert $_ isa person, has name "John";
          insert $_ isa person, has name "Jane";
          """
    Given transaction commits
    
    Given connection open write transaction for database: typedb
    Given set query option include_instance_types to: true
    Given set answers of typeql read query as given rows with order: $p, $age_value
    """
        match
          $p isa person, has name $name;
          {
            $name == "Jane"; try { let $age_value = 38; };
          } or {
            $name == "John"; try { let $age_value = 0; $age_value == 1; };
          };
        sort $name;
        select $p, $age_value;
        """
    When get answers of typeql write query with given rows
    """
        given $p: person, $age_value: integer?;
        match $p isa person, has name $name;
        insert try { $p has age == $age_value; };
        """
        # We don't necessarily guarantee that the rows retain the order
    Then answer get row(0) get concepts size is: 3
    
    Then answer get row(0) get entity(p) get type get label: person
    Then answer get row(0) get attribute(name) get type get label: name
    Then answer get row(0) get attribute(name) get value is: "Jane"
    
    Then answer get row(1) get entity(p) get type get label: person
    Then answer get row(1) get attribute(name) get type get label: name
    Then answer get row(1) get attribute(name) get value is: "John"
    
    Then transaction commits
    
    Given connection open read transaction for database: typedb
    Given set query option include_instance_types to: true
    When get answers of typeql read query
    """
        match $p isa person, has name $name, has age $age;
        """
    Then answer get row(0) get concepts size is: 3
    
    Then answer get row(0) get entity(p) get type get label: person
    Then answer get row(0) get attribute(age) get type get label: age
    Then answer get row(0) get attribute(age) get value is: 38
    Then answer get row(0) get attribute(name) get type get label: name
    Then answer get row(0) get attribute(name) get value is: "Jane"
    
    
  Scenario:: The order of variables in given rows don't matter
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
          define
            entity person owns name @card(0..), owns age @card(0..);
            attribute name, value string;
            attribute age, value integer;
          """
    Given transaction commits
    
    Given connection open write transaction for database: typedb
    Given get answers of typeql write query
    """
          insert $_ isa person, has name "John";
          insert $_ isa person, has name "Jane";
          """
    Given transaction commits
    
    Given connection open write transaction for database: typedb
    Given set query option include_instance_types to: true
    Given set answers of typeql read query as given rows with order: $p, $age_value
    """
        match
          $p isa person, has name $name;
          $name == "Jane"; try { let $age_value = 38; };
        sort $name;
        select $p, $age_value;
        """
    When get answers of typeql write query with given rows
    """
        given $p: person, $age_value: integer?;
        match $p isa person, has name $name;
        insert try { $p has age == $age_value; };
        """
        # We don't necessarily guarantee that the rows retain the order
    Then answer get row(0) get entity(p) get type get label: person
    Then answer get row(0) get attribute(name) get type get label: name
    Then answer get row(0) get attribute(name) get value is: "Jane"
    Given set answers of typeql read query as given rows with order: $p
    """
        match
          $p isa person, has name $name;
          $name == "John";
        sort $name;
        select $p;
        """
    When get answers of typeql write query with given rows
    """
        given $p: person, $age_value: integer?;
        match $p isa person, has name $name;
        insert try { $p has age == $age_value; };
        """
        # We don't necessarily guarantee that the rows retain the order
    Then answer get row(0) get entity(p) get type get label: person
    Then answer get row(0) get attribute(name) get type get label: name
    Then answer get row(0) get attribute(name) get value is: "John"
    
    Then transaction commits
    
    
  Scenario:: In given rows, optional variables may be omitted, required ones may not, undeclared variables are flagged.
    Given connection open read transaction for database: typedb
    When set answers of typeql read query as given rows with order: $x
    """
        match let $x = 5;
        """
    When get answers of typeql read query with given rows
    """
          given $x: integer, $y: integer?;
          match
           let $p = $x * 2;
           try { let $q = $x + $y; };
          """
    
    Then answer get row(0) get value(x) get is: 5
    Then answer get row(0) get value(p) get is: 10
    Then answer get row(0) get variable(y) is empty
    Then answer get row(0) get variable(q) is empty
    
    When set answers of typeql read query as given rows with order: $x
    """
          match let $x = 5;
          """
    Then typeql read query with given rows; fails with a message containing: "The given rows are missing the required variable 'y'"
    """
          given $x: integer, $y: integer;
          match
           let $p = $x * 2;
           let $q = $x + $y;
          """
    
    When set answers of typeql read query as given rows with order: $x, $z
    """
          match let $x = 5; let $z =6;
          """
    Then typeql read query with given rows; fails with a message containing: "The variable 'z' was not declared in the query"
    """
          given $x: integer, $y: integer?;
          match
            let $p = $x;
           try { let $q = $x + $y; };
          """
    
    
  Scenario:: Drivers also accept given rows as maps
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
          define
            entity person owns name @card(0..), owns age @card(0..);
            attribute name, value string;
            attribute age, value integer;
          """
    Given transaction commits
    
    Given connection open write transaction for database: typedb
    Given get answers of typeql write query
    """
          insert $_ isa person, has name "John";
          insert $_ isa person, has name "Jane";
          """
    Given transaction commits
    
    Given connection open write transaction for database: typedb
    Given set query option include_instance_types to: true
    Given set answers of typeql read query as given rows dictionary with variables: $p, $age_value
    """
        match
          $p isa person, has name $name;
          {
            $name == "Jane"; try { let $age_value = 38; };
          } or {
            $name == "John"; try { let $age_value = 0; $age_value == 1; };
          };
        sort $name;
        select $p, $age_value;
        """
    When get answers of typeql write query with given rows
    """
        given $p: person, $age_value: integer?;
        match $p isa person, has name $name;
        insert try { $p has age == $age_value; };
        """
        # We don't necessarily guarantee that the rows retain the order
    Then answer get row(0) get entity(p) get type get label: person
    Then answer get row(0) get attribute(name) get type get label: name
    Then answer get row(0) get attribute(name) get value is: "Jane"
    
    Then answer get row(1) get entity(p) get type get label: person
    Then answer get row(1) get attribute(name) get type get label: name
    Then answer get row(1) get attribute(name) get value is: "John"
    
    Then transaction commits
    
    Given connection open read transaction for database: typedb
    Given set query option include_instance_types to: true
    When get answers of typeql read query
    """
        match $p isa person, has name $name, has age $age;
        """
    
    Then answer get row(0) get entity(p) get type get label: person
    Then answer get row(0) get attribute(age) get type get label: age
    Then answer get row(0) get attribute(age) get value is: 38
    Then answer get row(0) get attribute(name) get type get label: name
    Then answer get row(0) get attribute(name) get value is: "Jane"
    
    When set answers of typeql read query as given rows dictionary with variables: $x
    """
        match let $x = 5;
        """
    When get answers of typeql read query with given rows
    """
          given $x: integer, $y: integer?;
          match
           let $p = $x * 2;
           try { let $q = $x + $y; };
          """
    Then answer get row(0) get value(x) get is: 5
    Then answer get row(0) get value(p) get is: 10
    Then answer get row(0) get variable(y) is empty
    Then answer get row(0) get variable(q) is empty
    
