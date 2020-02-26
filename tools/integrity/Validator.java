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
import grakn.verification.tools.integrity.schema.Plays;
import grakn.verification.tools.integrity.schema.Relates;
import grakn.verification.tools.integrity.schema.Sub;
import grakn.verification.tools.integrity.schema.TransitiveSub;
import grakn.verification.tools.integrity.schema.Types;
import graql.lang.Graql;
import graql.lang.query.GraqlGet;

import java.util.List;

public class Validator {

    /*
    TODO
    In general, we have the issue of ignoring inherited pairs when trying to build the
    non-transitive sets.
    Transitive sets will be built up later
     */

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
        Types roles = createAndValidateRoles(); // TODO figure out how we want to deal with roles, esp role inheritance
        Sub sub = createAndValidateSub(types);
        TransitiveSub transitiveSub = createAndValidateTransitiveSubWithoutIdentity(sub);

        Types entities = createEntityTypes(transitiveSub);
        Types relations = createRelationTypes(transitiveSub);
        Types attributes = createAttributeTypes(transitiveSub);

        Has has = createAndValidateHas(types, attributes);
        Has key = createAndValidateKey(types, attributes, has);

        Plays plays = createAndValidatePlays(types, roles);
        Relates relates = createAndValidateRelates(relations, roles);
        validatePlaysAndRelatesOverlap(plays, relates);

        Types abstractTypes = createAndValidateAbstractTypes(types);

        return false;
    }


    void validatePlaysAndRelatesOverlap(Plays plays, Relates relates) {
        // every role that is played must be related
        for (Pair<Type, Type> playsRole : plays) {
            boolean found = false;
            for (Pair<Type, Type> relatesRole : relates) {
                if (playsRole.second().equals(relatesRole.second())) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                throw IntegrityException.playedRoleIsNotRelated(playsRole.second(), playsRole.first());
            }
        }

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

    Types createAndValidateRoles() {
        Types roles = new Types();
        try (GraknClient.Transaction tx = session.transaction().read()) {
            List<ConceptMap> answers = tx.execute(Graql.parse("match $x sub role; get;").asGet());
            for (ConceptMap answer : answers) {
                roles.add(new Type(answer.get("x").asSchemaConcept()));
            }
        }
        roles.validate();
        return roles;
    }

    Sub createAndValidateSub(Types types) {
        Sub sub = new Sub();

        try (GraknClient.Transaction tx = session.transaction().read()) {
            for (Type child : types) {
                for (Type parent : types) {
                    // TODO we reject transitive sub using sub! but this is broken
                    GraqlGet query = Graql.parse(String.format("match $child type %s; $parent type %s; $child sub! $parent; child != parent; get;", child, parent)).asGet();
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
            // this is because if we do end up with (x,x) in the transitive closure, then we know there is a loop
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
                    // TODO - how to verify that the `has` is not inherited?
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
                    // TODO - how to verify that the `key` is not inherited?
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


    private Relates createAndValidateRelates(Types relations, Types roles) {
        Relates relates = new Relates();
        try (GraknClient.Transaction tx = session.transaction().read()) {
            for (Type relation : relations) {
                for (Type role : roles) {
                    GraqlGet query = Graql.parse(String.format("match $type type %s; $type relates %s; get;", relation, role)).asGet();
                    boolean trueInGrakn = ask(tx, query);
                    if (trueInGrakn) {
                        relates.add(new Pair<>(relation, role));
                    }
                }
            }
        }
        relates.validate();

        // also validate that every relation has at least one role
        for (Type relation : relations) {
            boolean found = false;
            for (Pair<Type, Type> relatesRole : relates) {
                if (relatesRole.first().equals(relation)) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                throw IntegrityException.relationWithoutRole(relation);
            }
        }
        return relates;
    }

    private Plays createAndValidatePlays(Types types, Types roles) {
        Plays plays = new Plays();
        try (GraknClient.Transaction tx = session.transaction().read()) {
            for (Type relation : types) {
                for (Type role : roles) {
                    GraqlGet query = Graql.parse(String.format("match $type relates %s; $type plays %s; get;", relation, role)).asGet();
                    boolean trueInGrakn = ask(tx, query);
                    if (trueInGrakn) {
                        plays.add(new Pair<>(relation, role));
                    }
                }
            }
        }
        plays.validate();
        return plays;
    }

    private Types createAndValidateAbstractTypes(Types types) {
        Types abstractTypes = new Types();
        try (GraknClient.Transaction tx = session.transaction().read()) {
            for (Type type : types) {
                GraqlGet query = Graql.parse(String.format("match $owner type %s; $type abstract; get;", type)).asGet();
                boolean trueInGrakn = ask(tx, query);
                if (trueInGrakn) {
                    abstractTypes.add(type);
                }
            }
        }
        abstractTypes.validate();
        return abstractTypes;
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
