/*
 * GRAKN.AI - THE KNOWLEDGE GRAPH
 * Copyright (C) 2019 Grakn Labs Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 */

package grakn.verification.tools.operator;

import graql.lang.Graql;
import graql.lang.pattern.Pattern;
import graql.lang.property.VarProperty;
import graql.lang.statement.Statement;
import graql.lang.statement.Variable;

import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Introduces the variable fuzzying operator - it fuzzes each variable in the input pattern such that
 * the input and output patterns are alpha-equivalent (we preserve variable bindings).
 *
 * For an input pattern the application of the pattern returns a single pattern with all returned variables randomised.
 *
 */
public class VariableFuzzyingOperator implements Operator{

    private final static int varLength = 3;

    @Override
    public Stream<Pattern> apply(Pattern src, TypeContext ctx) {
        Map<Variable, Variable> varMap = new HashMap<>();
        src.statements().stream().flatMap(s -> s.variables().stream())
                .forEach(v -> {
                    String newVarVal = Graql.var().var().name();
                    Variable newVar = Graql.var(newVarVal.substring(newVarVal.length() - varLength)).var();
                    if (v.isReturned()) newVar = newVar.asReturnedVar();
                    varMap.put(v, newVar);
                });

        Pattern transformed = Graql.and(
                src.statements().stream()
                        .map(s -> transformStatement(s, varMap))
                        .collect(Collectors.toSet())
        );
        return Stream.of(transformed);
    }

    private Statement transformStatement(Statement src, Map<Variable, Variable> vars){
        LinkedHashSet<VarProperty> transformedProperties = src.properties().stream()
                .map(p -> PropertyVariableTransform.transform(p, vars))
                .collect(Collectors.toCollection(LinkedHashSet::new));
        return Statement.create(vars.get(src.var()), transformedProperties);
    }
}
