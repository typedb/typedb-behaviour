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
