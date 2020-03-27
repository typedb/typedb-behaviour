/*
* Copyright (C) 2020 Grakn Labs
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

import com.google.common.collect.Sets;
import graql.lang.Graql;
import graql.lang.pattern.Pattern;
import graql.lang.property.IdProperty;
import graql.lang.property.VarProperty;
import graql.lang.statement.Statement;
import graql.lang.statement.Variable;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class IdFuzzyingOperator implements Operator{

    @Override
    public Stream<Pattern> apply(Pattern src, TypeContext ctx) {
        if (!src.statements().stream().flatMap(s -> s.getProperties(IdProperty.class)).findFirst().isPresent()){
            return Stream.of(src);
        }

        List<Set<Statement>> transformedStatements = src.statements().stream()
                .map(p -> transformStatement(p, ctx))
                .collect(Collectors.toList());
        return Sets.cartesianProduct(transformedStatements).stream()
                .map(Graql::and)
                .filter(p -> !p.equals(src))
                .map(p -> Graql.and(
                        p.statements().stream()
                                .filter(st -> !st.properties().isEmpty())
                                .collect(Collectors.toSet())
                        )
                );
    }

    private Set<Statement> transformStatement(Statement src, TypeContext ctx){
        Variable var = src.var();
        Set<IdProperty> ids = src.getProperties(IdProperty.class).collect(Collectors.toSet());
        if (ids.isEmpty()) return Sets.newHashSet(src);

        Set<Statement> transformedStatements = Sets.newHashSet(src);
        ids.stream()
                .map(idProp -> {
                    LinkedHashSet<VarProperty> properties = new LinkedHashSet<>(src.properties());
                    properties.remove(idProp);
                    properties.add(new IdProperty(ctx.instanceId()));
                    return Statement.create(var, properties);
                })
                .forEach(transformedStatements::add);

        return transformedStatements;
    }
}
