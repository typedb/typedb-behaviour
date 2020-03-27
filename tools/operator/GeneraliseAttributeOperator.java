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
import grakn.verification.tools.operator.range.Range;
import grakn.verification.tools.operator.range.Ranges;
import graql.lang.Graql;
import graql.lang.pattern.Pattern;
import graql.lang.property.HasAttributeProperty;
import graql.lang.property.IsaProperty;
import graql.lang.property.ValueProperty;
import graql.lang.property.VarProperty;
import graql.lang.statement.Statement;
import graql.lang.statement.Variable;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;

//TODO: this assumes there is no stray value properties (not attached to HasAttributeProperty)
//TODO: we currently only convert Number attributes
public class GeneraliseAttributeOperator implements Operator{

    @Override
    public Stream<Pattern> apply(Pattern src, TypeContext ctx) {
        List<Set<Statement>> transformedStatements = src.statements().stream()
                .map(this::transformStatement)
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

    private Set<Statement> transformStatement(Statement src){
        Variable var = src.var();
        Set<HasAttributeProperty> attributes = src.getProperties(HasAttributeProperty.class).collect(Collectors.toSet());
        if (attributes.isEmpty()) return Sets.newHashSet(src);

        Set<HasAttributeProperty> transformedProps = attributes.stream()
                .map(this::transformAttributeProperty)
                .collect(Collectors.toSet());

        Set<Statement> transformedStatements = Sets.newHashSet(src);
        transformedProps.stream()
                .map(o -> {
                    LinkedHashSet<VarProperty> properties = new LinkedHashSet<>(src.properties());
                    properties.removeAll(attributes);
                    properties.addAll(transformedProps);
                    return Statement.create(var, properties);
                })
                .forEach(transformedStatements::add);

        return transformedStatements;
    }

    private HasAttributeProperty transformAttributeProperty(HasAttributeProperty src){
        LinkedHashSet<VarProperty> properties = src.attribute().properties().stream()
                .filter(p -> !(p instanceof ValueProperty))
                .collect(Collectors.toCollection(LinkedHashSet::new));
        Range range = src.attribute().getProperties(ValueProperty.class)
                .map(Ranges::create)
                .filter(Objects::nonNull)
                .reduce(Range::merge)
                .orElse(null);
        if (range == null) return src;

        properties.addAll(range.generalise().toProperties());

        Statement attribute = src.attribute();
        String type = attribute.getProperty(IsaProperty.class).orElse(null).type().getType().orElse(null);
        return new HasAttributeProperty(type, Statement.create(attribute.var(), properties));
    }

}
