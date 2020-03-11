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

import com.google.common.collect.Sets;
import graql.lang.Graql;
import graql.lang.pattern.Pattern;
import graql.lang.property.RelationProperty;
import graql.lang.statement.Statement;

import graql.lang.statement.Variable;
import java.util.Collection;
import java.util.Comparator;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

public class Utils {

    /**
     * Sanitise input pattern:
     * - remove statements without properties
     * - remove statements that are disconnected from the original pattern
     * @param p transformed pattern
     * @param src original Pattern
     * @return
     */
    static Pattern sanitise(Pattern p, Pattern src){
        Set<Variable> toRemove = Sets.difference(rolePlayerVariables(src), rolePlayerVariables(p));
        return Graql.and(
                p.statements().stream()
                        .filter(st -> !st.properties().isEmpty())
                        .filter(s -> !toRemove.contains(s.var()))
                        .collect(Collectors.toList())
        );
    }

    static Set<Variable> rolePlayerVariables(Pattern p){
        return p.statements().stream()
                .flatMap(s -> s.properties().stream())
                .filter(RelationProperty.class::isInstance)
                .map(RelationProperty.class::cast)
                .flatMap(rp -> rp.relationPlayers().stream())
                .map(rp -> rp.getPlayer().var())
                .collect(Collectors.toSet());
    }

    static RelationProperty relationProperty(Collection<RelationProperty.RolePlayer> relationPlayers) {
        if (relationPlayers.isEmpty()) return null;
        Statement var = Graql.var();
        List<RelationProperty.RolePlayer> sortedRPs = relationPlayers.stream()
                .sorted(Comparator.comparing(rp -> rp.getPlayer().var().symbol()))
                .collect(Collectors.toList());
        for (RelationProperty.RolePlayer rp : sortedRPs) {
            Statement rolePattern = rp.getRole().orElse(null);
            var = rolePattern != null ? var.rel(rolePattern, rp.getPlayer()) : var.rel(rp.getPlayer());
        }
        return var.getProperty(RelationProperty.class).orElse(null);
    }
}
