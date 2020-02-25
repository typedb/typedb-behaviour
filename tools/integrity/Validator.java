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
import grakn.verification.tools.integrity.schema.Has;
import grakn.verification.tools.integrity.schema.Sub;
import grakn.verification.tools.integrity.schema.TransitiveSub;
import grakn.verification.tools.integrity.schema.Types;
import graql.lang.Graql;
import graql.lang.query.GraqlGet;

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
        TransitiveSub transitiveSub = createAndValidateTransitiveSubWithoutIdentity(sub);
        Types entities = createEntityTypes(transitiveSub);
        Types relations = createRelationTypes(transitiveSub);
        Types attributes = createAttributeTypes(transitiveSub);

        Has has = createAndValidateHas(types, attributes);
        Has key = createAndValidateKey(types, attributes, has);


        return false;
    }


    Types createAndValidateTypes() {
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

    Sub createAndValidateSub(Types types) {
        Sub sub = new Sub();

        try (GraknClient.Transaction tx = session.transaction().read()) {
            for (Type child : types) {
                for (Type parent : types) {
                    GraqlGet query = Graql.parse(String.format("match $child type %s; $parent type %s; $child sub! $parent; get;", child, parent)).asGet();
                    boolean trueInGrakn = ask(tx, query);
                    if (trueInGrakn) {
                        sub.add(new Pair<>(child, parent));
                    }
                }
            }
            sub.validate();
            return sub;
        }
    }

    TransitiveSub createAndValidateTransitiveSubWithoutIdentity(Sub sub) {
        TransitiveSub transitiveSub = new TransitiveSub();

        for (Pair<Type, Type> subEntry : sub) {
            // don't include (x,x) in the transitive sub closure
            if (subEntry.first() != subEntry.second()) {
                transitiveSub.add(subEntry);
            }
        }

        // note: inefficient!
        // computes transitive closure, updating into `updatedTransitiveSub` from `transitiveSub`
        TransitiveSub updatedTransitiveSub = transitiveSub.shallowCopy();
        boolean changed = true;
        while (changed) {
            transitiveSub = updatedTransitiveSub.shallowCopy();
            changed = false;
            for (Pair<Type, Type> sub1 : transitiveSub) {
                for (Pair<Type, Type> sub2 : transitiveSub) {
                    if (sub1.second() == sub2.first()) {
                        Pair<Type, Type> transitiveSubEntry = new Pair<>(sub1.first(), sub2.second());
                        if (!transitiveSub.contains(transitiveSubEntry)) {
                            updatedTransitiveSub.add(transitiveSubEntry);
                            changed = true;
                        }
                    }
                }
            }
        }

        updatedTransitiveSub.validate();
        return updatedTransitiveSub;
    }

    Types createEntityTypes(TransitiveSub transitiveSub) {
        Types entityTypes = new Types();
        for (Pair<Type, Type> sub : transitiveSub) {
            if (sub.second().label().equals("entity")) {
                entityTypes.add(sub.first());
            }
        }
        return entityTypes;
    }

    Types createRelationTypes(TransitiveSub transitiveSub) {
        Types entityTypes = new Types();
        for (Pair<Type, Type> sub : transitiveSub) {
            if (sub.second().label().equals("relation")) {
                entityTypes.add(sub.first());
            }
        }
        return entityTypes;
    }

    Types createAttributeTypes(TransitiveSub transitiveSub) {
        Types entityTypes = new Types();
        for (Pair<Type, Type> sub : transitiveSub) {
            if (sub.second().label().equals("attribute")) {
                entityTypes.add(sub.first());
            }
        }
        return entityTypes;
    }

    Has createAndValidateHas(Types types, Types attributes) {
        Has has = new Has();

        try (GraknClient.Transaction tx = session.transaction().read()) {
            for (Type type : types) {
                for (Type attribute : attributes) {
                    GraqlGet query = Graql.parse(String.format("match $owner type %s; $owner has %s; get;", type, attribute)).asGet();
                    boolean trueInGrakn = ask(tx, query);
                    if (trueInGrakn) {
                        has.add(new Pair<>(type, attribute));
                    }
                }
            }
        }
        has.validate();
        return has;
    }

    Has createAndValidateKey(Types types, Types attributes, Has has) {
        Has key = new Has();

        try (GraknClient.Transaction tx = session.transaction().read()) {
            for (Type type : types) {
                for (Type attribute : attributes) {
                    GraqlGet query = Graql.parse(String.format("match $owner type %s; $owner key %s; get;", type, attribute)).asGet();
                    boolean trueInGrakn = ask(tx, query);
                    if (trueInGrakn) {
                        key.add(new Pair<>(type, attribute));
                    }
                }
            }
        }

        key.validate();

        // also validate key is a subset of has
        for (Pair<Type, Type> keyship : key) {
            if (!has.contains(keyship)) {
                throw IntegrityException.keyshipNotSubsetOfOwnership(keyship.first(), keyship.second());
            }
        }

        return key;
    }


    private boolean ask(GraknClient.Transaction tx, GraqlGet query) {
        List<ConceptMap> answer = tx.execute(query);
        return answer.size() == 1;
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
