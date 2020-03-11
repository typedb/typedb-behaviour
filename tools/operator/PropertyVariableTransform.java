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

import com.google.common.collect.ImmutableMap;
import graql.lang.Graql;
import graql.lang.property.HasAttributeProperty;
import graql.lang.property.IsaProperty;
import graql.lang.property.NeqProperty;
import graql.lang.property.RelationProperty;
import graql.lang.property.ValueProperty;
import graql.lang.property.VarProperty;
import graql.lang.statement.Statement;
import graql.lang.statement.Variable;

import java.util.Map;
import java.util.Set;
import java.util.function.BiFunction;
import java.util.stream.Collectors;

/**
 * Introduces a variable transform for different types of VarProperty. The variables are transformed according to provided mappings.
 */
public class PropertyVariableTransform {

    private final static Map<Class, BiFunction<VarProperty, Map<Variable, Variable>, VarProperty>> transformMap = ImmutableMap.of(
            RelationProperty.class, PropertyVariableTransform::transformRelation,
            HasAttributeProperty.class, PropertyVariableTransform::transformAttribute,
            IsaProperty.class, PropertyVariableTransform::transformIsa,
            ValueProperty.class, PropertyVariableTransform::transformValue,
            NeqProperty.class, PropertyVariableTransform::transformNeq
    );

    static VarProperty transform(VarProperty prop, Map<Variable, Variable> vars){
        BiFunction<VarProperty, Map<Variable, Variable>, VarProperty> func = transformMap.get(prop.getClass());
        if (func == null) return defaultTransform(prop, vars);
        return func.apply(prop, vars);
    }

    static private VarProperty defaultTransform(VarProperty prop, Map<Variable, Variable> vars){
        return prop;
    }

    static private VarProperty transformRelation(VarProperty prop, Map<Variable, Variable> vars){
        RelationProperty relProp = (RelationProperty) prop;

        Set<RelationProperty.RolePlayer> transformedRPs = relProp.relationPlayers().stream().map(rp -> {
            Statement player = rp.getPlayer();
            Variable playerVar = player.var();
            Statement role = rp.getRole().orElse(null);
            Statement transformedRole = role;
            if (role != null) {
                String type = role.getType().orElse(null);
                Variable newRoleVar = vars.get(role.var());
                if (newRoleVar != null) {
                    transformedRole = Graql.var(newRoleVar);
                    if (type != null) transformedRole = transformedRole.type(type);
                }
            }

            Variable newPlayerVar = vars.getOrDefault(playerVar, playerVar);
            Statement transformedPlayer = Graql.var(newPlayerVar);
            return new RelationProperty.RolePlayer(transformedRole, transformedPlayer);
        }).collect(Collectors.toSet());
        return Utils.relationProperty(transformedRPs);
    }

    static private VarProperty transformAttribute(VarProperty prop, Map<Variable, Variable> vars){
        HasAttributeProperty attrProp = (HasAttributeProperty) prop;
        Statement attribute = attrProp.attribute();
        Variable attrVar = attribute.var();
        if (!attrVar.isReturned()) return prop;
        String type = attribute.getProperty(IsaProperty.class).orElse(null)
                .type().getType().orElse(null);

        Variable newAttrVar = vars.getOrDefault(attrVar, attrVar);
        Statement isaStatement = Graql.var(newAttrVar).isa(type);
        return new HasAttributeProperty(type, isaStatement);
    }

    static private VarProperty transformIsa(VarProperty prop, Map<Variable, Variable> vars){
        IsaProperty isaProp = (IsaProperty) prop;
        Statement type = isaProp.type();
        Variable typeVar = type.var();
        if (!typeVar.isReturned()) return prop;

        Statement newStatement = Graql.var(vars.getOrDefault(typeVar, typeVar));
        return new IsaProperty(newStatement);
    }

    static private VarProperty transformValue(VarProperty prop, Map<Variable, Variable> vars){
        ValueProperty valProp = (ValueProperty) prop;
        Statement inner = valProp.operation().innerStatement();
        if(!valProp.operation().hasVariable()) return prop;

        Variable innerVar = inner.var();
        Statement varStatement = Graql.var(vars.getOrDefault(innerVar, innerVar));
        ValueProperty.Operation.Comparison.Variable operation = new ValueProperty.Operation.Comparison.Variable(Graql.Token.Comparator.NEQV, varStatement);
        return new ValueProperty<>(operation);
    }

    static private VarProperty transformNeq(VarProperty prop, Map<Variable, Variable> vars){
        NeqProperty neqProp = (NeqProperty) prop;
        Variable var = neqProp.statement().var();
        return new NeqProperty(Graql.var(vars.getOrDefault(var, var)));
    }
}
