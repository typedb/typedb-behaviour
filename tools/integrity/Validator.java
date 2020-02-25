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

package grakn.verification.tools.integrity;

import grakn.client.GraknClient;
import grakn.client.answer.ConceptMap;
import grakn.common.util.Pair;
import grakn.verification.tools.integrity.schema.Sub;
import grakn.verification.tools.integrity.schema.SubTrans;
import grakn.verification.tools.integrity.schema.Types;
import graql.lang.Graql;

import java.util.List;

public class Validator {

    public static String META_THING = "thing";
    public static String META_ENTITY = "entity";
    public static String META_RELATION = "relation";
    public static String META_ATTRIBUTE = "attribute";
    public static String META_ROLE = "role";

    private GraknClient.Session session;

    public Validator(GraknClient.Session session) {
        this.session = session;
    }

    public boolean validate() {

        Types types = createAndValidateTypes();
        Sub sub = createAndValidateSub(types);
        SubTrans subTrans = createAndValidateTransitiveSubWithoutIdentity(sub);

        return false;
    }


    private Types createAndValidateTypes() {
        Types types = new Types();
        try (GraknClient.Transaction tx = session.transaction().read()) {
            List<ConceptMap> answers = tx.execute(Graql.parse("match $x sub type; get;").asGet());
            for (ConceptMap answer : answers) {
                types.add(new Type(answer.get("x").asSchemaConcept()));
            }
        }

        types.validate();
        return types;
    }

    private Sub createAndValidateSub(Types types) {
        Sub sub = new Sub();

        try (GraknClient.Transaction tx = session.transaction().read()) {
            for (Type child : types) {
                for (Type parent : types) {
                    List<ConceptMap> answers = tx.execute(
                            Graql.parse(String.format("match $child type \"%s\"; $parent type \"%s\"; $child sub! $parent; get;", child, parent)).asGet());
                    if (answers.size() == 1) {
                        sub.add(new Pair<>(child, parent));
                    }
                }
            }
        }

        sub.validate();
        return sub;
    }

    private SubTrans createAndValidateTransitiveSubWithoutIdentity(Sub sub) {
        SubTrans subTrans = new SubTrans();

        for (Pair<Type, Type> subEntry : sub) {
            // don't include (x,x) in the transitive sub closure
            if (subEntry.first() != subEntry.second()) {
                subTrans.add(subEntry);
            }
        }

        // note: inefficient!
        boolean changed = true;
        while (changed) {
            for (Pair<Type, Type> sub1 : subTrans) {
                for (Pair<Type, Type> sub2 : subTrans) {
                    if (sub1.second() == sub2.first()) {
                        Pair<Type, Type> transitiveSub = new Pair<>(sub1.first(), sub2.second());
                        if (!subTrans.contains(transitiveSub)) {
                            subTrans.add(transitiveSub);
                            changed = true;
                        }
                    }
                }
            }
            changed = false;
        }

        subTrans.validate();
        return null;
    }

    /*

     Outline:

     Goal: given a keyspace, verify basic integrity checks are preserved, building up from very low level structures


     Schema:
       * create sets:
         * Type
         * sub
         * transitive closure of sub, sub_trans
         * Type_attr, subset of type with (t, attribute) in sub_trans -- plus Type_entity and Type_relation
         * has: (Type, Type_attr)
         * key: (Type, Type_attr)
         * plays: (Type, Role)
         * relates: (Type_relation, Role)
         * abstract: Type
       * functions (?)
         * label, datatype, regex

       *The goal is to create and verify these from the simplest building blocks, asking every possible combination at each
       step to create a valid pair for a set. The sets are then created and checked for validity.

       * As we build up the sets, each pair must be confirmed by Grakn, then the resulting relations are checked for logical integrity

     Data:
       * create sets:
         * Instances
         * isa
         * rel
         * has_data
         * key_data
       * functions:
         * id
         * val


      After building these (correct) sets, we use them to perform validation according to the conditions
      of validity for a data and a schema


     */

}
